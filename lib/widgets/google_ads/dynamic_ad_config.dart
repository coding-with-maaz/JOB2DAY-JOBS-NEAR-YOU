import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/logger.dart';
import 'ad_config.dart';

/// Dynamic Ad Configuration that fetches settings from remote API
/// Only shows ads when dynamic configuration is available
class DynamicAdConfig {
  static const String _apiUrl = 'https://backend.harpaljob.com/api/ads-config';
  // static const String _apiUrl = 'http://10.0.2.2:5000/api/ads-config';
  static const String _cacheKey = 'ads_config_cache';
  static const Duration _cacheExpiry = Duration(hours: 1);
  
  static Map<String, dynamic>? _config;
  static DateTime? _lastFetch;
  static bool _isInitialized = false;
  static bool _apiConnectionSuccessful = false;

  /// Initialize the dynamic ad configuration
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      Logger.info('DynamicAdConfig: Starting initialization...');
      
      // Try to load from cache first
      await _loadFromCache();
      
      // Fetch fresh data from API
      await fetchFromApi();
      
      _isInitialized = true;
      Logger.info('DynamicAdConfig: Initialized successfully');
      Logger.info('DynamicAdConfig: API Connection: $_apiConnectionSuccessful');
      Logger.info('DynamicAdConfig: Current config: $_config');
    } catch (e) {
      Logger.error('DynamicAdConfig: Initialization failed: $e');
      // Don't set fallback config - only use dynamic
      _config = null;
      _apiConnectionSuccessful = false;
    }
  }

  /// Fetch configuration from API
  static Future<void> fetchFromApi() async {
    try {
      final environment = _getEnvironment();
      final url = '$_apiUrl?environment=$environment';
      Logger.info('DynamicAdConfig: Fetching from API: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      Logger.info('DynamicAdConfig: API Response Status: ${response.statusCode}');
      Logger.info('DynamicAdConfig: API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Parse ad type fields if they are JSON strings
        for (final key in ['banner', 'interstitial', 'rewarded', 'rewardedInterstitial', 'native', 'appOpen', 'splash', 'custom']) {
          if (data[key] is String) {
            data[key] = json.decode(data[key]);
          }
        }
        _config = data;
        _lastFetch = DateTime.now();
        _apiConnectionSuccessful = true;
        
        // Cache the configuration
        await _saveToCache(data);
        
        Logger.info('DynamicAdConfig: Fetched from API successfully');
        Logger.info('DynamicAdConfig: Parsed config: $_config');
      } else {
        Logger.warning('DynamicAdConfig: API returned status ${response.statusCode}');
        Logger.warning('DynamicAdConfig: Response body: ${response.body}');
        _apiConnectionSuccessful = false;
        throw Exception('API returned status ${response.statusCode}');
      }
    } catch (e) {
      Logger.error('DynamicAdConfig: Failed to fetch from API: $e');
      _apiConnectionSuccessful = false;
      // Don't use fallback - keep config as null
      _config = null;
    }
  }

  /// Load configuration from cache
  static Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cacheKey);
      final cachedTime = prefs.getString('${_cacheKey}_time');
      
      if (cachedData != null && cachedTime != null) {
        final cacheTime = DateTime.parse(cachedTime);
        if (DateTime.now().difference(cacheTime) < _cacheExpiry) {
          final data = json.decode(cachedData);
                  // Parse ad type fields if they are JSON strings
        for (final key in ['banner', 'interstitial', 'rewarded', 'rewardedInterstitial', 'native', 'appOpen', 'splash', 'custom']) {
          if (data[key] is String) {
            data[key] = json.decode(data[key]);
          }
        }
          _config = data;
          _lastFetch = cacheTime;
          _apiConnectionSuccessful = true; // Assume cache means previous success
          Logger.info('DynamicAdConfig: Loaded from cache');
          Logger.info('DynamicAdConfig: Cached config: $_config');
          return;
        } else {
          Logger.info('DynamicAdConfig: Cache expired, will fetch fresh data');
        }
      } else {
        Logger.info('DynamicAdConfig: No cache found, will fetch fresh data');
      }
    } catch (e) {
      Logger.error('DynamicAdConfig: Failed to load from cache: $e');
    }
  }

  /// Save configuration to cache
  static Future<void> _saveToCache(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, json.encode(data));
      await prefs.setString('${_cacheKey}_time', DateTime.now().toIso8601String());
      Logger.info('DynamicAdConfig: Saved to cache successfully');
    } catch (e) {
      Logger.error('DynamicAdConfig: Failed to save to cache: $e');
    }
  }

  /// Get current environment
  static String _getEnvironment() {
    return AdConfig.isProduction ? 'production' : 'test';
  }

  /// Check if ad type is enabled - only if dynamic configuration is available
  static bool isEnabled(String adType) {
    if (!_apiConnectionSuccessful || _config == null) {
      Logger.info('DynamicAdConfig: isEnabled($adType) = false (no dynamic config)');
      return false;
    }
    
    final enabled = _config?[adType]?['enabled'] ?? false;
    Logger.info('DynamicAdConfig: isEnabled($adType) = $enabled');
    return enabled;
  }

  /// Get ad unit ID for ad type - only if dynamic config is available
  static String getAdUnitId(String adType) {
    if (!_apiConnectionSuccessful || _config == null) {
      Logger.info('DynamicAdConfig: getAdUnitId($adType) = "" (no dynamic config)');
      return '';
    }
    
    String adUnitId = _config?[adType]?['adUnitId'] ?? '';
    
    // Handle platform-specific app open ad unit IDs
    if (adType == 'appOpen' && adUnitId.isNotEmpty) {
      // Check if the backend provides platform-specific IDs
      final androidId = _config?[adType]?['androidAdUnitId'];
      final iosId = _config?[adType]?['iosAdUnitId'];
      
      if (Platform.isAndroid && androidId != null && androidId.isNotEmpty) {
        adUnitId = androidId;
        Logger.info('DynamicAdConfig: Using Android app open ad unit ID: $adUnitId');
      } else if (Platform.isIOS && iosId != null && iosId.isNotEmpty) {
        adUnitId = iosId;
        Logger.info('DynamicAdConfig: Using iOS app open ad unit ID: $adUnitId');
      } else {
        // Use the default ad unit ID if platform-specific ones are not provided
        Logger.info('DynamicAdConfig: Using default app open ad unit ID: $adUnitId');
      }
    }
    
    Logger.info('DynamicAdConfig: getAdUnitId($adType) = $adUnitId');
    return adUnitId;
  }

  /// Get ad configuration for ad type
  static Map<String, dynamic>? getAdConfig(String adType) {
    return _config?[adType];
  }

  /// Get global settings
  static Map<String, dynamic>? getGlobalSettings() {
    return _config?['globalSettings'];
  }

  /// Get environment
  static String get environment => _config?['environment'] ?? _getEnvironment();

  /// Check if test mode is enabled
  static bool get isTestMode {
    // First check static configuration
    if (!AdConfig.isProduction) {
      return true; // If static config says we're not in production, we're in test mode
    }
    // Then check dynamic config
    return _config?['globalSettings']?['testMode'] ?? false;
  }

  /// Check if debug mode is enabled
  static bool get isDebugMode => _config?['globalSettings']?['debugMode'] ?? false;

  /// Get last fetch time
  static DateTime? get lastFetch => _lastFetch;

  /// Check if API connection was successful
  static bool get apiConnectionSuccessful => _apiConnectionSuccessful;

  /// Force refresh configuration
  static Future<void> refresh() async {
    Logger.info('DynamicAdConfig: Force refreshing configuration...');
    await fetchFromApi();
  }

  /// Get all configuration
  static Map<String, dynamic>? get config => _config;

  /// Check if configuration is available
  static bool get isAvailable => _config != null && _apiConnectionSuccessful;

  /// Get specific ad type settings with type safety
  static T? getSetting<T>(String adType, String setting, [T? defaultValue]) {
    if (!isAvailable) return defaultValue;
    final value = _config?[adType]?[setting];
    if (value is T) return value;
    return defaultValue;
  }

  /// Check if interstitial should show on specific page
  static bool shouldShowInterstitialOn(String pageType) {
    if (!isAvailable) return false;
    final shouldShow = _config?['interstitial']?['showOn$pageType'] ?? false;
    Logger.info('DynamicAdConfig: shouldShowInterstitialOn($pageType) = $shouldShow');
    Logger.info('DynamicAdConfig: Available interstitial settings: ${_config?['interstitial']}');
    return shouldShow;
  }

  /// Get interstitial minimum interval
  static int getInterstitialMinInterval() {
    return _config?['interstitial']?['minInterval'] ?? 60;
  }

  /// Get banner position
  static String getBannerPosition() {
    return _config?['banner']?['position'] ?? 'bottom';
  }

  /// Get banner refresh interval
  static int getBannerRefreshInterval() {
    return _config?['banner']?['refreshInterval'] ?? 60;
  }

  /// Get app open max shows per day
  static int getAppOpenMaxShowsPerDay() {
    return _config?['appOpen']?['maxShowsPerDay'] ?? 3;
  }

  /// Get max ads per session
  static int getMaxAdsPerSession() {
    return _config?['globalSettings']?['maxAdsPerSession'] ?? 10;
  }

  /// Get cooldown period
  static int getCooldownPeriod() {
    return _config?['globalSettings']?['cooldownPeriod'] ?? 60;
  }

  /// Get rewarded interstitial minimum interval
  static int getRewardedInterstitialMinInterval() {
    return _config?['rewardedInterstitial']?['minInterval'] ?? 300;
  }

  /// Get rewarded interstitial max shows per session
  static int getRewardedInterstitialMaxShowsPerSession() {
    return _config?['rewardedInterstitial']?['maxShowsPerSession'] ?? 5;
  }

  /// Debug method to print current configuration
  static void debugPrintConfig() {
    Logger.info('=== DynamicAdConfig Debug Info ===');
    Logger.info('Is Available: $isAvailable');
    Logger.info('API Connection Successful: $_apiConnectionSuccessful');
    Logger.info('Environment: $environment');
    Logger.info('Last Fetch: $lastFetch');
    Logger.info('Is Test Mode: $isTestMode');
    Logger.info('Is Debug Mode: $isDebugMode');
    Logger.info('Full Config: $_config');
    Logger.info('=== End Debug Info ===');
  }

  /// Simple debug method to check if using dynamic or static config
  static String getDebugInfo() {
    if (!isAvailable) {
      return 'NO ADS - Dynamic configuration not available';
    }
    
    final bannerId = getAdUnitId('banner');
    final isUsingDynamic = bannerId.isNotEmpty;
    
    return isUsingDynamic 
        ? 'Using DYNAMIC configuration from API'
        : 'NO ADS - Dynamic config available but no ad unit IDs';
  }

  /// Check if a specific ad unit ID is from dynamic config
  static bool isUsingDynamicAdUnitId(String adType) {
    if (!isAvailable) return false;
    
    final dynamicId = getAdUnitId(adType);
    return dynamicId.isNotEmpty;
  }

  /// Test API connection
  static Future<bool> testApiConnection() async {
    try {
      final environment = _getEnvironment();
      final url = '$_apiUrl?environment=$environment';
      Logger.info('DynamicAdConfig: Testing API connection: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      Logger.info('DynamicAdConfig: Test API Response Status: ${response.statusCode}');
      Logger.info('DynamicAdConfig: Test API Response Body: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      Logger.error('DynamicAdConfig: API connection test failed: $e');
      return false;
    }
  }
} 