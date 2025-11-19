/// Ad Configuration for Google Mobile Ads
/// 
/// This file contains all ad unit IDs for both test and production environments.
/// The configuration can be overridden by the dynamic configuration system.
/// To switch to production, change the `isProduction` flag to true and update
/// the production ad unit IDs below.

import 'dynamic_ad_config.dart';

class AdConfig {
  // Set this to true for production, false for testing
  static const bool isProduction = false;

  // Test Ad Unit IDs (Google's official test IDs)
  static const String _testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  static const String _testRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
  static const String _testNativeAdUnitId = 'ca-app-pub-3940256099942544/2247696110';

  // Production Ad Unit IDs (Replace with your actual ad unit IDs)
  static const String _productionBannerAdUnitId = 'YOUR_PRODUCTION_BANNER_AD_UNIT_ID';
  static const String _productionInterstitialAdUnitId = 'YOUR_PRODUCTION_INTERSTITIAL_AD_UNIT_ID';
  static const String _productionRewardedAdUnitId = 'YOUR_PRODUCTION_REWARDED_AD_UNIT_ID';
  static const String _productionNativeAdUnitId = 'YOUR_PRODUCTION_NATIVE_AD_UNIT_ID';

  // App ID (Replace with your actual app ID)
  static const String _testAppId = 'ca-app-pub-3940256099942544~3347511713'; // Android test app ID
  static const String _productionAppId = 'YOUR_PRODUCTION_APP_ID';

  // Getters for ad unit IDs with dynamic fallback
  static String get bannerAdUnitId {
    // Try dynamic config first, fallback to static
    final dynamicId = DynamicAdConfig.getAdUnitId('banner');
    if (dynamicId.isNotEmpty) return dynamicId;
    
    return isProduction ? _productionBannerAdUnitId : _testBannerAdUnitId;
  }

  static String get interstitialAdUnitId {
    // Try dynamic config first, fallback to static
    final dynamicId = DynamicAdConfig.getAdUnitId('interstitial');
    if (dynamicId.isNotEmpty) return dynamicId;
    
    return isProduction ? _productionInterstitialAdUnitId : _testInterstitialAdUnitId;
  }

  static String get rewardedAdUnitId {
    // Try dynamic config first, fallback to static
    final dynamicId = DynamicAdConfig.getAdUnitId('rewarded');
    if (dynamicId.isNotEmpty) return dynamicId;
    
    return isProduction ? _productionRewardedAdUnitId : _testRewardedAdUnitId;
  }

  static String get nativeAdUnitId {
    // Try dynamic config first, fallback to static
    final dynamicId = DynamicAdConfig.getAdUnitId('native');
    if (dynamicId.isNotEmpty) return dynamicId;
    
    return isProduction ? _productionNativeAdUnitId : _testNativeAdUnitId;
  }

  static String get appId {
    // For now, app ID remains static as it's typically not changed dynamically
    return isProduction ? _productionAppId : _testAppId;
  }

  // Helper method to check if we're in test mode
  static bool get isTestMode {
    // Try dynamic config first, fallback to static
    if (DynamicAdConfig.isAvailable) {
      return DynamicAdConfig.isTestMode;
    }
    return !isProduction;
  }

  // Helper method to get environment info
  static String get environmentInfo {
    // Try dynamic config first, fallback to static
    if (DynamicAdConfig.isAvailable) {
      return DynamicAdConfig.environment.toUpperCase();
    }
    return isProduction ? 'PRODUCTION' : 'TEST';
  }

  // Helper method to check if dynamic config is available
  static bool get isDynamicConfigAvailable => DynamicAdConfig.isAvailable;

  // Helper method to get dynamic config status
  static Map<String, dynamic> get dynamicConfigStatus {
    if (!DynamicAdConfig.isAvailable) {
      return {
        'available': false,
        'message': 'Dynamic configuration not available',
        'usingStatic': true,
      };
    }

    return {
      'available': true,
      'environment': DynamicAdConfig.environment,
      'lastFetch': DynamicAdConfig.lastFetch?.toIso8601String(),
      'usingStatic': false,
      'ads': {
        'banner': {
          'enabled': DynamicAdConfig.isEnabled('banner'),
          'adUnitId': DynamicAdConfig.getAdUnitId('banner'),
        },
        'interstitial': {
          'enabled': DynamicAdConfig.isEnabled('interstitial'),
          'adUnitId': DynamicAdConfig.getAdUnitId('interstitial'),
        },
        'native': {
          'enabled': DynamicAdConfig.isEnabled('native'),
          'adUnitId': DynamicAdConfig.getAdUnitId('native'),
        },
        'rewarded': {
          'enabled': DynamicAdConfig.isEnabled('rewarded'),
          'adUnitId': DynamicAdConfig.getAdUnitId('rewarded'),
        },
      },
    };
  }

  // Method to force refresh dynamic configuration
  static Future<void> refreshDynamicConfig() async {
    await DynamicAdConfig.refresh();
  }

  // Method to get current ad unit ID for a specific ad type
  static String getAdUnitIdForType(String adType) {
    // Try dynamic config first, fallback to static
    final dynamicId = DynamicAdConfig.getAdUnitId(adType);
    if (dynamicId.isNotEmpty) return dynamicId;

    // Fallback to static configuration
    switch (adType.toLowerCase()) {
      case 'banner':
        return isProduction ? _productionBannerAdUnitId : _testBannerAdUnitId;
      case 'interstitial':
        return isProduction ? _productionInterstitialAdUnitId : _testInterstitialAdUnitId;
      case 'rewarded':
        return isProduction ? _productionRewardedAdUnitId : _testRewardedAdUnitId;
      case 'native':
        return isProduction ? _productionNativeAdUnitId : _testNativeAdUnitId;
      default:
        return '';
    }
  }

  // Method to check if a specific ad type is enabled
  static bool isAdTypeEnabled(String adType) {
    // Try dynamic config first, fallback to static (all enabled by default)
    if (DynamicAdConfig.isAvailable) {
      return DynamicAdConfig.isEnabled(adType);
    }
    return true; // Default to enabled for static config
  }

  // Method to get all current ad unit IDs
  static Map<String, String> getAllAdUnitIds() {
    return {
      'banner': bannerAdUnitId,
      'interstitial': interstitialAdUnitId,
      'rewarded': rewardedAdUnitId,
      'native': nativeAdUnitId,
    };
  }

  // Method to get configuration source info
  static String getConfigurationSource() {
    if (DynamicAdConfig.isAvailable) {
      return 'Dynamic (${DynamicAdConfig.environment})';
    }
    return 'Static (${isProduction ? 'Production' : 'Test'})';
  }

  // Method to validate ad unit IDs
  static Map<String, bool> validateAdUnitIds() {
    final ids = getAllAdUnitIds();
    final validation = <String, bool>{};

    for (final entry in ids.entries) {
      final adUnitId = entry.value;
      validation[entry.key] = adUnitId.isNotEmpty && 
                              adUnitId != 'YOUR_PRODUCTION_${entry.key.toUpperCase()}_AD_UNIT_ID';
    }

    return validation;
  }

  // Method to get configuration summary
  static Map<String, dynamic> getConfigurationSummary() {
    return {
      'source': getConfigurationSource(),
      'environment': environmentInfo,
      'testMode': isTestMode,
      'dynamicAvailable': isDynamicConfigAvailable,
      'adUnitIds': getAllAdUnitIds(),
      'validation': validateAdUnitIds(),
      'dynamicStatus': dynamicConfigStatus,
    };
  }
} 