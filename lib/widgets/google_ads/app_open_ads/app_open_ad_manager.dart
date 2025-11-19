import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../dynamic_ad_config.dart';
import '../interstitial_ads/interstitial_ad_manager.dart';
import '../../../utils/logger.dart';
import 'dart:io';
import 'dart:async';

class AppOpenAdManager with WidgetsBindingObserver {
  static final AppOpenAdManager instance = AppOpenAdManager._internal();
  AppOpenAdManager._internal();

  // Use test ad unit in development, otherwise use dynamic config
  String get adUnitId {
    // Get ad unit ID from dynamic config
    final dynamicId = DynamicAdConfig.getAdUnitId('appOpen');
    
    // Check if the dynamic ID is valid
    if (dynamicId.isNotEmpty && _isValidAppOpenAdUnitId(dynamicId)) {
      return dynamicId;
    }
    
    // Fallback to test ads - use the correct app open test ad unit ID
    return Platform.isAndroid
        ? 'ca-app-pub-3940256099942544/9257395921'  // Android app open test ad
        : 'ca-app-pub-3940256099942544/5575463023'; // iOS app open test ad
  }

  // Helper method to validate app open ad unit ID
  bool _isValidAppOpenAdUnitId(String adUnitId) {
    // App open ads have specific format and should not be the same as splash ads
    if (adUnitId.contains('3419835294')) {
      // This is a splash ad unit ID, not an app open ad unit ID
      Logger.warning('AppOpenAdManager: Dynamic config provided splash ad unit ID instead of app open ad unit ID');
      return false;
    }
    
    // Check if it's a valid Google test app open ad unit ID
    if (adUnitId.contains('9257395921') || adUnitId.contains('5575463023')) {
      return true;
    }
    
    // For production, we'll assume it's valid if it's not empty and not the splash ad ID
    return adUnitId.isNotEmpty && !adUnitId.contains('3419835294');
  }

  AppOpenAd? _appOpenAd;
  bool _isLoading = false;
  bool _isShowing = false;
  int _showsToday = 0;
  DateTime? _lastShowDate;
  bool _initialized = false;
  DateTime? _appOpenLoadTime;
  final Duration maxCacheDuration = const Duration(hours: 4);
  bool _isFirstLaunchAdShown = false;

  void initialize() {
    if (_initialized) return;
    WidgetsBinding.instance.addObserver(this);
    _initialized = true;
    _resetDailyCountIfNeeded();
    
    // Load multiple ads to ensure availability
    loadAd();
    
    // Preload another ad after a short delay
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (_initialized && _appOpenAd == null) {
        loadAd();
      }
    });
    
    // Additional preload for immediate display
    Future.delayed(const Duration(milliseconds: 5000), () {
      if (_initialized && _appOpenAd == null) {
        loadAd();
      }
    });
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _appOpenAd?.dispose();
    _appOpenAd = null;
    _isLoading = false;
    _isShowing = false;
    _initialized = false;
    _appOpenLoadTime = null;
  }

  void _resetDailyCountIfNeeded() {
    final now = DateTime.now();
    if (_lastShowDate == null ||
        now.year != _lastShowDate!.year ||
        now.month != _lastShowDate!.month ||
        now.day != _lastShowDate!.day) {
      _showsToday = 0;
      _lastShowDate = now;
    }
  }

  int get _maxShowsPerDay => DynamicAdConfig.getAppOpenMaxShowsPerDay();

  bool get _canShowAd {
    // Simplified logic for regular ads - more permissive for immediate display
    if (adUnitId.isEmpty || _isShowing) {
      Logger.info('AppOpenAdManager: Regular ad - Cannot show: adUnitId.isEmpty=${adUnitId.isEmpty}, _isShowing=$_isShowing');
      return false;
    }
    
    // Check daily limit
    if (_showsToday >= _maxShowsPerDay) {
      Logger.info('AppOpenAdManager: Regular ad - Daily limit reached: $_showsToday/$_maxShowsPerDay');
      return false;
    }
    
    // Check if interstitial is in cooldown or ready to avoid conflicts
    if (InterstitialAdManager.isInAppOpenCooldown || InterstitialAdManager.isAdReady) {
      Logger.info('AppOpenAdManager: Regular ad - Interstitial in cooldown or ready, skipping app open');
      return false;
    }
    
    // Check if any other ads are currently showing
    if (_isAnyOtherAdShowing()) {
      Logger.info('AppOpenAdManager: Regular ad - Other ads are showing, skipping app open');
      return false;
    }
    
    // If dynamic config is available, check if app open ads are enabled
    if (DynamicAdConfig.isAvailable) {
      final isEnabled = DynamicAdConfig.isEnabled('appOpen');
      Logger.info('AppOpenAdManager: Regular ad - Dynamic config available, enabled: $isEnabled');
      return isEnabled;
    }
    
    // If dynamic config is not available, allow ads anyway
    Logger.info('AppOpenAdManager: Regular ad - Dynamic config not available, allowing ad');
    return true;
  }

  bool get isAdAvailable => _appOpenAd != null;

  // Method to check if we can show first launch ad - simplified
  bool get _canShowFirstLaunchAd {
    // For first launch ads, only check if not already shown and not currently showing
    if (_isFirstLaunchAdShown || _isShowing) {
      Logger.info('AppOpenAdManager: First launch ad - Cannot show: _isFirstLaunchAdShown=$_isFirstLaunchAdShown, _isShowing=$_isShowing');
      return false;
    }
    
    // Check if we have a valid ad unit ID
    if (adUnitId.isEmpty) {
      Logger.info('AppOpenAdManager: First launch ad - No ad unit ID available');
      return false;
    }
    
    Logger.info('AppOpenAdManager: First launch ad - Can show ad');
    return true;
  }

  void loadAd({VoidCallback? onLoaded}) {
    if (_isLoading || _appOpenAd != null) return;
    if (adUnitId.isEmpty) return;
    
    _isLoading = true;
    Logger.info('AppOpenAdManager: Loading App Open Ad...');
    Logger.info('AppOpenAdManager: Ad Unit ID: $adUnitId');
    Logger.info('AppOpenAdManager: Dynamic Config Available: ${DynamicAdConfig.isAvailable}');
    
    AppOpenAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          Logger.info('AppOpenAdManager: App Open Ad loaded successfully');
          _appOpenAd = ad;
          _isLoading = false;
          _appOpenLoadTime = DateTime.now();
          onLoaded?.call(); // <== callback if passed
        },
        onAdFailedToLoad: (error) {
          Logger.error('AppOpenAdManager: Failed to load: ${error.message}');
          _isLoading = false;
          _appOpenAd = null;
          _appOpenLoadTime = null;
          
          // More aggressive retry for immediate app open ads
          Future.delayed(const Duration(milliseconds: 1000), () {
            if (!_isLoading && _appOpenAd == null) {
              Logger.info('AppOpenAdManager: Retrying to load app open ad...');
              loadAd(onLoaded: onLoaded);
            }
          });
        },
      ),
    );
  }

  void showAdIfAvailable() {
    _resetDailyCountIfNeeded();
    if (!isAdAvailable) {
      Logger.info('AppOpenAdManager: Tried to show ad before available.');
      loadAd();
      return;
    }
    if (_isShowing) {
      Logger.info('AppOpenAdManager: Tried to show ad while already showing an ad.');
      return;
    }
    if (_appOpenLoadTime == null || DateTime.now().subtract(maxCacheDuration).isAfter(_appOpenLoadTime!)) {
      Logger.info('AppOpenAdManager: Maximum cache duration exceeded. Loading another ad.');
      _appOpenAd!.dispose();
      _appOpenAd = null;
      loadAd();
      return;
    }
    _isShowing = true;
    
    // Set cooldown for interstitial ads to prevent conflicts
    InterstitialAdManager.setAppOpenCooldown(const Duration(seconds: 15));
    
    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        Logger.info('AppOpenAdManager: App Open Ad showed');
        _isShowing = true;
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        Logger.error('AppOpenAdManager: Failed to show: ${error.message}');
        _isShowing = false;
        ad.dispose();
        _appOpenAd = null;
        _appOpenLoadTime = null;
        loadAd();
      },
      onAdDismissedFullScreenContent: (ad) {
        Logger.info('AppOpenAdManager: App Open Ad dismissed');
        _isShowing = false;
        ad.dispose();
        _appOpenAd = null;
        _appOpenLoadTime = null;
        _showsToday++;
        _lastShowDate = DateTime.now();
        
        // Mark first launch ad as shown if this was the first launch ad
        if (!_isFirstLaunchAdShown) {
          _isFirstLaunchAdShown = true;
          Logger.info('AppOpenAdManager: First launch ad shown successfully');
        }
        
        loadAd();
      },
    );
    _appOpenAd!.show();
  }

  // Show on first open - simplified for immediate display
  void showOnFirstOpen() {
    Logger.info('AppOpenAdManager: showOnFirstOpen called');
    Logger.info('AppOpenAdManager: _canShowFirstLaunchAd: $_canShowFirstLaunchAd');
    Logger.info('AppOpenAdManager: isAdAvailable: $isAdAvailable');
    Logger.info('AppOpenAdManager: adUnitId: $adUnitId');
    
    if (_canShowFirstLaunchAd) {
      Logger.info('AppOpenAdManager: Showing first launch app open ad');
      
      // If ad is available, show it immediately
      if (isAdAvailable) {
        showAdIfAvailable();
      } else {
        // If ad is not available, load it first then show
        Logger.info('AppOpenAdManager: Ad not available, loading first');
        loadAd(onLoaded: () {
          Logger.info('AppOpenAdManager: Ad loaded, now showing');
          showAdIfAvailable();
        });
      }
    } else {
      Logger.info('AppOpenAdManager: Cannot show first launch ad - conditions not met');
    }
  }

  // Force show app open ad immediately - bypasses some restrictions for initial app open
  bool forceShowImmediate() {
    Logger.info('AppOpenAdManager: forceShowImmediate called');
    
    if (adUnitId.isEmpty) {
      Logger.warning('AppOpenAdManager: Cannot force show - no ad unit ID');
      return false;
    }
    
    if (_isShowing) {
      Logger.info('AppOpenAdManager: Cannot force show - ad already showing');
      return false;
    }
    
    // Check if interstitial is in cooldown to avoid conflicts
    if (InterstitialAdManager.isInAppOpenCooldown) {
      Logger.info('AppOpenAdManager: Cannot force show - interstitial in cooldown');
      _waitForCooldownAndShow();
      return false;
    }
    
    // Check if any other ads are currently showing
    if (_isAnyOtherAdShowing()) {
      Logger.info('AppOpenAdManager: Cannot force show - other ads are showing');
      return false;
    }
    
    // If we reach here, we can proceed with showing the ad
    return _proceedWithForceShow();
  }

  bool _proceedWithForceShow() {
    
    // Force load and show ad immediately
    if (isAdAvailable) {
      Logger.info('AppOpenAdManager: Force showing available ad');
      _forceShowAd();
      return true;
    } else {
      Logger.info('AppOpenAdManager: Force loading and showing ad');
      _forceLoadAndShow();
      return true;
    }
  }

  // Wait for cooldown to expire then show ad
  void _waitForCooldownAndShow() {
    Logger.info('AppOpenAdManager: Waiting for cooldown to expire...');
    
    // Check every second if cooldown has expired
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!InterstitialAdManager.isInAppOpenCooldown && !_isShowing) {
        timer.cancel();
        Logger.info('AppOpenAdManager: Cooldown expired, now showing ad');
        forceShowImmediate();
      }
    });
  }

  // Check if any other ads are currently showing
  bool _isAnyOtherAdShowing() {
    // Check if interstitial is ready (which means it might be showing)
    if (InterstitialAdManager.isAdReady) {
      Logger.info('AppOpenAdManager: Other ad check - Interstitial ad is ready');
      return true;
    }
    
    // Check if interstitial is in cooldown
    if (InterstitialAdManager.isInAppOpenCooldown) {
      Logger.info('AppOpenAdManager: Other ad check - Interstitial in cooldown');
      return true;
    }
    
    // Add more checks for other ad types if needed
    return false;
  }

  // Comprehensive check if app open ad can be shown
  bool get canShowAppOpenAd {
    if (!_initialized) {
      Logger.info('AppOpenAdManager: Cannot show - not initialized');
      return false;
    }
    
    if (_isShowing) {
      Logger.info('AppOpenAdManager: Cannot show - already showing');
      return false;
    }
    
    if (adUnitId.isEmpty) {
      Logger.info('AppOpenAdManager: Cannot show - no ad unit ID');
      return false;
    }
    
    if (_showsToday >= _maxShowsPerDay) {
      Logger.info('AppOpenAdManager: Cannot show - daily limit reached');
      return false;
    }
    
    if (InterstitialAdManager.isInAppOpenCooldown) {
      Logger.info('AppOpenAdManager: Cannot show - interstitial in cooldown');
      return false;
    }
    
    if (InterstitialAdManager.isAdReady) {
      Logger.info('AppOpenAdManager: Cannot show - interstitial ready');
      return false;
    }
    
    Logger.info('AppOpenAdManager: Can show app open ad - all checks passed');
    return true;
  }

  // Check if any ads are currently blocking app open ads
  bool get isBlockedByOtherAds {
    if (InterstitialAdManager.isInAppOpenCooldown) {
      Logger.info('AppOpenAdManager: Blocked by interstitial cooldown');
      return true;
    }
    
    if (InterstitialAdManager.isAdReady) {
      Logger.info('AppOpenAdManager: Blocked by interstitial ready');
      return true;
    }
    
    return false;
  }

  // Get status information for debugging
  Map<String, dynamic> get status {
    return {
      'initialized': _initialized,
      'isShowing': _isShowing,
      'isLoading': _isLoading,
      'isAdAvailable': isAdAvailable,
      'adUnitId': adUnitId,
      'showsToday': _showsToday,
      'maxShowsPerDay': _maxShowsPerDay,
      'isBlockedByOtherAds': isBlockedByOtherAds,
      'interstitialCooldown': InterstitialAdManager.isInAppOpenCooldown,
      'interstitialReady': InterstitialAdManager.isAdReady,
    };
  }

  void _forceLoadAndShow() {
    _isLoading = true;
    Logger.info('AppOpenAdManager: Force loading app open ad...');
    
    AppOpenAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          Logger.info('AppOpenAdManager: Force load successful, now showing');
          _appOpenAd = ad;
          _isLoading = false;
          _appOpenLoadTime = DateTime.now();
          _forceShowAd();
        },
        onAdFailedToLoad: (error) {
          Logger.error('AppOpenAdManager: Force load failed: ${error.message}');
          _isLoading = false;
          _appOpenAd = null;
          _appOpenLoadTime = null;
          
          // Retry force load after delay
          Future.delayed(const Duration(milliseconds: 2000), () {
            if (!_isLoading && _appOpenAd == null) {
              Logger.info('AppOpenAdManager: Retrying force load...');
              _forceLoadAndShow();
            }
          });
        },
      ),
    );
  }

  void _forceShowAd() {
    if (_appOpenAd == null) return;
    
    _isShowing = true;
    
    // Set cooldown for interstitial ads to prevent conflicts
    InterstitialAdManager.setAppOpenCooldown(const Duration(seconds: 15));
    
    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        Logger.info('AppOpenAdManager: Force App Open Ad showed');
        _isShowing = true;
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        Logger.error('AppOpenAdManager: Force ad failed to show: ${error.message}');
        _isShowing = false;
        ad.dispose();
        _appOpenAd = null;
        _appOpenLoadTime = null;
        loadAd();
      },
      onAdDismissedFullScreenContent: (ad) {
        Logger.info('AppOpenAdManager: Force App Open Ad dismissed');
        _isShowing = false;
        ad.dispose();
        _appOpenAd = null;
        _appOpenLoadTime = null;
        _showsToday++;
        _lastShowDate = DateTime.now();
        loadAd();
      },
    );
    _appOpenAd!.show();
  }

  // Show on resume
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final appOpenConfig = DynamicAdConfig.getAdConfig('appOpen');
      final showOnResume = appOpenConfig == null || appOpenConfig['showOnResume'] == null || appOpenConfig['showOnResume'] == true;
      if (showOnResume) {
        // Add delay to avoid conflicts with other ads
        Future.delayed(const Duration(milliseconds: 2000), () {
          if (_initialized && !_isShowing && _canShowAd) {
            Logger.info('AppOpenAdManager: Resume check passed, showing ad');
        showAdIfAvailable();
          } else {
            Logger.info('AppOpenAdManager: Resume check failed - cannot show ad');
          }
        });
      }
    }
  }
} 