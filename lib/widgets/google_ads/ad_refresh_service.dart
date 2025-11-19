import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dynamic_ad_config.dart';
import 'interstitial_ads/interstitial_ad_manager.dart';
import '../../utils/logger.dart';
import 'rewarded_ads/rewarded_ad_manager.dart';
import 'rewarded_ads/rewarded_interstitial_ad_manager.dart';

/// Service to manage ad configuration refresh and ad reloading
class AdRefreshService {
  static final AdRefreshService instance = AdRefreshService._internal();
  AdRefreshService._internal();

  Timer? _refreshTimer;
  Timer? _configRefreshTimer;
  bool _isInitialized = false;

  /// Initialize the refresh service
  Future<void> initialize() async {
    if (_isInitialized) return;

    Logger.info('AdRefreshService: Initializing...');
    
    // Initialize ad managers
    await InterstitialAdManager.initialize();
    await RewardedAdManager.initialize();
    await RewardedInterstitialAdManager.initialize();
    
    // Load initial ads
    await _loadAllAds();
    
    // Set up periodic configuration refresh (every 30 minutes)
    _configRefreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _refreshConfiguration();
    });
    
    // Set up periodic ad refresh (every 5 minutes)
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _refreshAds();
    });
    
    _isInitialized = true;
    Logger.info('AdRefreshService: Initialized successfully');
  }

  /// Load all ads based on current configuration
  Future<void> _loadAllAds() async {
    try {
      // Load interstitial ad if enabled
      if (DynamicAdConfig.isEnabled('interstitial')) {
        await InterstitialAdManager.loadAd();
      }

      // Load rewarded ad if enabled and ad unit available
      if (DynamicAdConfig.isEnabled('rewarded') && DynamicAdConfig.getAdUnitId('rewarded').isNotEmpty) {
        await RewardedAdManager.loadAd();
      }

      // Load rewarded interstitial ad if enabled or in test mode
      final shouldLoadRewardedInterstitial =
          DynamicAdConfig.isTestMode || DynamicAdConfig.isEnabled('rewardedInterstitial');
      if (shouldLoadRewardedInterstitial && DynamicAdConfig.getAdUnitId('rewardedInterstitial').isNotEmpty) {
        await RewardedInterstitialAdManager.loadAd();
      }

      Logger.info('AdRefreshService: Loaded ads based on configuration');
    } catch (e) {
      Logger.error('AdRefreshService: Failed to load ads: $e');
    }
  }

  /// Refresh configuration from API
  Future<void> _refreshConfiguration() async {
    try {
      Logger.info('AdRefreshService: Refreshing configuration...');
      await DynamicAdConfig.refresh();
      
      // Reload ads if configuration changed
      await _loadAllAds();
      
      Logger.info('AdRefreshService: Configuration refreshed successfully');
    } catch (e) {
      Logger.error('AdRefreshService: Failed to refresh configuration: $e');
    }
  }

  /// Refresh ads
  Future<void> _refreshAds() async {
    try {
      Logger.info('AdRefreshService: Refreshing ads...');
      await _loadAllAds();
    } catch (e) {
      Logger.error('AdRefreshService: Failed to refresh ads: $e');
    }
  }

  /// Force refresh configuration
  Future<void> forceRefreshConfig() async {
    await _refreshConfiguration();
  }

  /// Force refresh ads
  Future<void> forceRefreshAds() async {
    await _refreshAds();
  }

  /// Show interstitial ad on specific page
  Future<bool> showInterstitialOnPage(String pageType) async {
    return await InterstitialAdManager.showAdOnPage(pageType);
  }

  /// Get current configuration status
  Map<String, dynamic> getConfigurationStatus() {
    return {
      'environment': DynamicAdConfig.environment,
      'lastFetch': DynamicAdConfig.lastFetch?.toIso8601String(),
      'isAvailable': DynamicAdConfig.isAvailable,
      'apiConnectionSuccessful': DynamicAdConfig.apiConnectionSuccessful,
      'ads': {
        'banner': {
          'enabled': DynamicAdConfig.isEnabled('banner'),
          'position': DynamicAdConfig.getBannerPosition(),
          'refreshInterval': DynamicAdConfig.getBannerRefreshInterval(),
        },
        'interstitial': {
          'enabled': DynamicAdConfig.isEnabled('interstitial'),
          'showOnJobView': DynamicAdConfig.shouldShowInterstitialOn('JobView'),
          'showOnCategoryView': DynamicAdConfig.shouldShowInterstitialOn('CategoryView'),
          'minInterval': DynamicAdConfig.getInterstitialMinInterval(),
        },
        'rewarded': {
          'enabled': DynamicAdConfig.isEnabled('rewarded'),
          'adUnitId': DynamicAdConfig.getAdUnitId('rewarded'),
        },
        'rewardedInterstitial': {
          'enabled': DynamicAdConfig.isTestMode || DynamicAdConfig.isEnabled('rewardedInterstitial'),
          'adUnitId': DynamicAdConfig.getAdUnitId('rewardedInterstitial'),
          'minInterval': DynamicAdConfig.getRewardedInterstitialMinInterval(),
          'maxShowsPerSession': DynamicAdConfig.getRewardedInterstitialMaxShowsPerSession(),
        },
        'native': {
          'enabled': DynamicAdConfig.isEnabled('native'),
          'position': DynamicAdConfig.getSetting<String>('native', 'position'),
        },
        'appOpen': {
          'enabled': DynamicAdConfig.isEnabled('appOpen'),
          'maxShowsPerDay': DynamicAdConfig.getAppOpenMaxShowsPerDay(),
        },
      },
      'globalSettings': {
        'testMode': DynamicAdConfig.isTestMode,
        'debugMode': DynamicAdConfig.isDebugMode,
        'maxAdsPerSession': DynamicAdConfig.getMaxAdsPerSession(),
        'cooldownPeriod': DynamicAdConfig.getCooldownPeriod(),
      },
    };
  }

  /// Dispose resources
  void dispose() {
    Logger.info('AdRefreshService: Disposing...');
    _refreshTimer?.cancel();
    _configRefreshTimer?.cancel();
    InterstitialAdManager.dispose();
    RewardedAdManager.dispose();
    RewardedInterstitialAdManager.dispose();
    _isInitialized = false;
  }
} 