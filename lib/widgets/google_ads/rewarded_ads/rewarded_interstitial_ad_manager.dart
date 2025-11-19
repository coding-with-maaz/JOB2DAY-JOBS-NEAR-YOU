import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../../utils/logger.dart';
import '../dynamic_ad_config.dart';
import '../interstitial_ads/interstitial_ad_manager.dart';

class RewardedInterstitialAdManager {
  static RewardedInterstitialAd? _rewardedInterstitialAd;
  static bool _isLoading = false;
  static DateTime? _lastShowTime;
  static int _showCount = 0;
  static int _loadRetryCount = 0;
  static const int _maxRetries = 3;

  /// Initialize rewarded interstitial ads
  static Future<void> initialize() async {
    Logger.info('RewardedInterstitialAdManager: Initializing...');
    
    // Check if dynamic config is available
    if (!DynamicAdConfig.isAvailable) {
      Logger.info('RewardedInterstitialAdManager: Dynamic config not available, not initializing');
      return;
    }

    // For test mode, always allow rewarded interstitial ads regardless of dynamic config
    if (DynamicAdConfig.isTestMode) {
      Logger.info('RewardedInterstitialAdManager: Test mode - allowing rewarded interstitial ads');
    } else {
      // Check if rewarded interstitial ads are enabled (only in production)
      if (!DynamicAdConfig.isEnabled('rewardedInterstitial')) {
        Logger.info('RewardedInterstitialAdManager: Rewarded interstitial ads disabled in dynamic config');
        return;
      }
    }

    // Check if we have a valid ad unit ID
    final adUnitId = _adUnitId;
    if (adUnitId.isEmpty) {
      Logger.info('RewardedInterstitialAdManager: No dynamic rewarded interstitial ad unit ID available');
      return;
    }

    Logger.info('RewardedInterstitialAdManager: Initialized with dynamic config');
  }

  /// Load rewarded interstitial ad
  static Future<void> loadAd() async {
    // Don't load if dynamic config is not available
    if (!DynamicAdConfig.isAvailable) {
      Logger.info('RewardedInterstitialAdManager: Not loading - dynamic config not available');
      return;
    }

    // For test mode, always allow rewarded interstitial ads regardless of dynamic config
    if (!DynamicAdConfig.isTestMode) {
      // Don't load if rewarded interstitial ads are disabled (only in production)
      if (!DynamicAdConfig.isEnabled('rewardedInterstitial')) {
        Logger.info('RewardedInterstitialAdManager: Not loading - rewarded interstitial ads disabled');
        return;
      }
    }

    // Don't load if no ad unit ID is available
    final adUnitId = _adUnitId;
    if (adUnitId.isEmpty) {
      Logger.info('RewardedInterstitialAdManager: Not loading - no ad unit ID available');
      return;
    }

    if (_isLoading) {
      Logger.info('RewardedInterstitialAdManager: Already loading, skipping');
      return;
    }

    _isLoading = true;
    Logger.info('RewardedInterstitialAdManager: Loading rewarded interstitial ad with dynamic ID: $adUnitId (attempt ${_loadRetryCount + 1})');

    try {
      await RewardedInterstitialAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            Logger.info('RewardedInterstitialAdManager: Ad loaded successfully');
            _rewardedInterstitialAd = ad;
            _isLoading = false;
            _loadRetryCount = 0; // Reset retry count on success
            
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                Logger.info('RewardedInterstitialAdManager: Ad dismissed');
                ad.dispose();
                _rewardedInterstitialAd = null;
                _lastShowTime = DateTime.now();
                _showCount++;
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                Logger.error('RewardedInterstitialAdManager: Ad failed to show: ${error.message}');
                ad.dispose();
                _rewardedInterstitialAd = null;
                _isLoading = false;
              },
              onAdShowedFullScreenContent: (ad) {
                Logger.info('RewardedInterstitialAdManager: Ad showed full screen');
              },
              onAdImpression: (ad) {
                Logger.info('RewardedInterstitialAdManager: Ad impression recorded');
              },
              onAdClicked: (ad) {
                Logger.info('RewardedInterstitialAdManager: Ad clicked');
              },
            );
          },
          onAdFailedToLoad: (error) {
            Logger.error('RewardedInterstitialAdManager: Ad failed to load: ${error.message}');
            _rewardedInterstitialAd = null;
            _isLoading = false;
            
            // Retry logic for test mode
            if (DynamicAdConfig.isTestMode && _loadRetryCount < _maxRetries) {
              _loadRetryCount++;
              Logger.info('RewardedInterstitialAdManager: Retrying ad load (${_loadRetryCount}/${_maxRetries})');
              Future.delayed(const Duration(seconds: 2), () {
                loadAd();
              });
            } else {
              _loadRetryCount = 0; // Reset retry count
              Logger.info('RewardedInterstitialAdManager: Max retries reached or not in test mode');
            }
          },
        ),
      );
    } catch (e) {
      Logger.error('RewardedInterstitialAdManager: Error loading ad: $e');
      _isLoading = false;
      
      // Retry logic for test mode
      if (DynamicAdConfig.isTestMode && _loadRetryCount < _maxRetries) {
        _loadRetryCount++;
        Logger.info('RewardedInterstitialAdManager: Retrying ad load after error (${_loadRetryCount}/${_maxRetries})');
        Future.delayed(const Duration(seconds: 2), () {
          loadAd();
        });
      } else {
        _loadRetryCount = 0; // Reset retry count
      }
    }
  }

  /// Show rewarded interstitial ad
  static Future<bool> showAd({
    required Function(AdWithoutView) onUserEarnedReward,
    required VoidCallback onAdClosed,
    required VoidCallback onAdFailedToShow,
  }) async {
    // Debug logging
    Logger.info('RewardedInterstitialAdManager: showAd called');
    Logger.info('RewardedInterstitialAdManager: DynamicAdConfig.isAvailable = ${DynamicAdConfig.isAvailable}');
    Logger.info('RewardedInterstitialAdManager: DynamicAdConfig.isTestMode = ${DynamicAdConfig.isTestMode}');
    Logger.info('RewardedInterstitialAdManager: DynamicAdConfig.isEnabled(rewardedInterstitial) = ${DynamicAdConfig.isEnabled('rewardedInterstitial')}');
    
    // Don't show if dynamic config is not available
    if (!DynamicAdConfig.isAvailable) {
      Logger.info('RewardedInterstitialAdManager: Not showing - dynamic config not available');
      onAdFailedToShow();
      return false;
    }

    // For test mode, always allow rewarded interstitial ads regardless of dynamic config
    if (!DynamicAdConfig.isTestMode) {
      Logger.info('RewardedInterstitialAdManager: Not in test mode, checking if enabled');
      // Don't show if rewarded interstitial ads are disabled (only in production)
      if (!DynamicAdConfig.isEnabled('rewardedInterstitial')) {
        Logger.info('RewardedInterstitialAdManager: Not showing - rewarded interstitial ads disabled');
        onAdFailedToShow();
        return false;
      }
    } else {
      Logger.info('RewardedInterstitialAdManager: In test mode, bypassing enabled check');
    }

    // Don't show if no ad unit ID is available
    final adUnitId = _adUnitId;
    Logger.info('RewardedInterstitialAdManager: Using ad unit ID: $adUnitId');
    if (adUnitId.isEmpty) {
      Logger.info('RewardedInterstitialAdManager: Not showing - no ad unit ID available');
      onAdFailedToShow();
      return false;
    }

    if (_rewardedInterstitialAd == null) {
      Logger.info('RewardedInterstitialAdManager: No ad available, loading new one');
      await loadAd();
      
      // In test mode, if ad still not available after loading, simulate success
      if (DynamicAdConfig.isTestMode && _rewardedInterstitialAd == null) {
        Logger.info('RewardedInterstitialAdManager: Test mode - simulating successful ad experience');
        await Future.delayed(const Duration(seconds: 2)); // Simulate ad loading time
        // For test mode, simulate success by calling callbacks
        onAdClosed();
        _lastShowTime = DateTime.now();
        _showCount++;
        return true;
      }
      
      onAdFailedToShow();
      return false;
    }

    // Check cooldown period
    final cooldownPeriod = DynamicAdConfig.getCooldownPeriod();
    if (_lastShowTime != null) {
      final timeSinceLastShow = DateTime.now().difference(_lastShowTime!);
      if (timeSinceLastShow.inSeconds < cooldownPeriod) {
        Logger.info('RewardedInterstitialAdManager: Not showing - cooldown period not met');
        onAdFailedToShow();
        return false;
      }
    }

    try {
      Logger.info('RewardedInterstitialAdManager: Showing rewarded interstitial ad');
      
      // Set up reward callback
      _rewardedInterstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          Logger.info('RewardedInterstitialAdManager: Ad dismissed');
          onAdClosed();
          ad.dispose();
          _rewardedInterstitialAd = null;
          _lastShowTime = DateTime.now();
          _showCount++;
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          Logger.error('RewardedInterstitialAdManager: Ad failed to show: ${error.message}');
          
          // In test mode, simulate success even if ad fails to show
          if (DynamicAdConfig.isTestMode) {
            Logger.info('RewardedInterstitialAdManager: Test mode - simulating successful ad experience after failure');
            onUserEarnedReward(ad);
            onAdClosed();
            _lastShowTime = DateTime.now();
            _showCount++;
          } else {
            onAdFailedToShow();
          }
          
          ad.dispose();
          _rewardedInterstitialAd = null;
          _isLoading = false;
        },
        onAdShowedFullScreenContent: (ad) {
          Logger.info('RewardedInterstitialAdManager: Ad showed full screen');
        },
        onAdImpression: (ad) {
          Logger.info('RewardedInterstitialAdManager: Ad impression recorded');
        },
        onAdClicked: (ad) {
          Logger.info('RewardedInterstitialAdManager: Ad clicked');
        },
      );

      // Set cooldown for app open ads to prevent conflicts
      InterstitialAdManager.setAppOpenCooldown(const Duration(seconds: 20));

      await _rewardedInterstitialAd!.show(
        onUserEarnedReward: (ad, reward) {
          Logger.info('RewardedInterstitialAdManager: User earned reward: ${reward.amount} ${reward.type}');
          onUserEarnedReward(ad);
        },
      );
      
      return true;
    } catch (e) {
      Logger.error('RewardedInterstitialAdManager: Error showing ad: $e');
      
      // In test mode, simulate success even if there's an error
      if (DynamicAdConfig.isTestMode) {
        Logger.info('RewardedInterstitialAdManager: Test mode - simulating successful ad experience after error');
        onAdClosed();
        _lastShowTime = DateTime.now();
        _showCount++;
        return true;
      }
      
      onAdFailedToShow();
      _rewardedInterstitialAd?.dispose();
      _rewardedInterstitialAd = null;
      return false;
    }
  }

  /// Check if ad is ready to show
  static bool get isAdReady {
    if (!DynamicAdConfig.isAvailable) return false;
    
    // For test mode, always allow rewarded interstitial ads regardless of dynamic config
    if (!DynamicAdConfig.isTestMode) {
      if (!DynamicAdConfig.isEnabled('rewardedInterstitial')) return false;
    }
    
    final adUnitId = _adUnitId;
    if (adUnitId.isEmpty) return false;
    return _rewardedInterstitialAd != null && !_isLoading;
  }

  /// Get loading status
  static bool get isLoading => _isLoading;

  /// Get show count
  static int get showCount => _showCount;

  /// Get last show time
  static DateTime? get lastShowTime => _lastShowTime;

  /// Preload ad for better user experience
  static Future<void> preloadAd() async {
    if (!isAdReady && !_isLoading) {
      await loadAd();
    }
  }

  /// Dispose current ad
  static void dispose() {
    _rewardedInterstitialAd?.dispose();
    _rewardedInterstitialAd = null;
    _isLoading = false;
  }

  static String get _adUnitId {
    if (DynamicAdConfig.isTestMode) {
      // Test ad unit IDs from Google
      if (defaultTargetPlatform == TargetPlatform.android) {
        return 'ca-app-pub-3940256099942544/5354046379';
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        return 'ca-app-pub-3940256099942544/6978759866';
      }
    }
    return DynamicAdConfig.getAdUnitId('rewardedInterstitial');
  }
} 