import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../../utils/logger.dart';
import '../dynamic_ad_config.dart';
import '../interstitial_ads/interstitial_ad_manager.dart';
import 'dart:io';

class RewardedAdManager {
  static RewardedAd? _rewardedAd;
  static bool _isLoading = false;
  static DateTime? _lastShowTime;
  static int _showCount = 0;

  /// Initialize rewarded ads
  static Future<void> initialize() async {
    Logger.info('RewardedAdManager: Initializing...');
    
    // Check if dynamic config is available
    if (!DynamicAdConfig.isAvailable) {
      Logger.info('RewardedAdManager: Dynamic config not available, not initializing');
      return;
    }

    // Check if rewarded ads are enabled
    if (!DynamicAdConfig.isEnabled('rewarded')) {
      Logger.info('RewardedAdManager: Rewarded ads disabled in dynamic config');
      return;
    }

    // Check if we have a valid ad unit ID
    final adUnitId = DynamicAdConfig.getAdUnitId('rewarded');
    if (adUnitId.isEmpty) {
      Logger.info('RewardedAdManager: No dynamic rewarded ad unit ID available');
      return;
    }

    Logger.info('RewardedAdManager: Initialized with dynamic config');
  }

  /// Load rewarded ad
  static Future<void> loadAd() async {
    // Don't load if dynamic config is not available
    if (!DynamicAdConfig.isAvailable) {
      Logger.info('RewardedAdManager: Not loading - dynamic config not available');
      return;
    }

    // Don't load if rewarded ads are disabled
    if (!DynamicAdConfig.isEnabled('rewarded')) {
      Logger.info('RewardedAdManager: Not loading - rewarded ads disabled');
      return;
    }

    // Use test ad unit in development, otherwise use dynamic config
    final String adUnitId =
        (DynamicAdConfig.getAdUnitId('rewarded').isEmpty || !bool.fromEnvironment('dart.vm.product'))
            ? (Platform.isAndroid
                ? 'ca-app-pub-3940256099942544/5224354917'
                : 'ca-app-pub-3940256099942544/1712485313')
            : DynamicAdConfig.getAdUnitId('rewarded');

    if (adUnitId.isEmpty) {
      Logger.info('RewardedAdManager: Not loading - no ad unit ID available');
      return;
    }

    if (_isLoading) {
      Logger.info('RewardedAdManager: Already loading, skipping');
      return;
    }

    _isLoading = true;
    Logger.info('RewardedAdManager: Loading rewarded ad with ID: $adUnitId');

    try {
      await RewardedAd.load(
        adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            Logger.info('RewardedAdManager: Ad loaded successfully');
          _rewardedAd = ad;
            _isLoading = false;
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdShowedFullScreenContent: (ad) {
                Logger.info('RewardedAdManager: Ad showed full screen');
              },
              onAdImpression: (ad) {
                Logger.info('RewardedAdManager: Ad impression');
              },
              onAdClicked: (ad) {
                Logger.info('RewardedAdManager: Ad clicked');
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                Logger.error('RewardedAdManager: Ad failed to show: ${error.message}');
                ad.dispose();
                _rewardedAd = null;
                _isLoading = false;
              },
              onAdDismissedFullScreenContent: (ad) {
                Logger.info('RewardedAdManager: Ad dismissed');
                ad.dispose();
                _rewardedAd = null;
                _lastShowTime = DateTime.now();
                _showCount++;
              },
            );
        },
          onAdFailedToLoad: (error) {
            Logger.error('RewardedAdManager: Ad failed to load: ${error.message}');
            _rewardedAd = null;
            _isLoading = false;
        },
      ),
    );
    } catch (e) {
      Logger.error('RewardedAdManager: Error loading ad: $e');
      _isLoading = false;
    }
  }

  /// Show rewarded ad
  static Future<bool> showAd({
    required Function(AdWithoutView, RewardItem) onUserEarnedReward,
    required VoidCallback onAdClosed,
    required VoidCallback onAdFailedToShow,
  }) async {
    // Don't show if dynamic config is not available
    if (!DynamicAdConfig.isAvailable) {
      Logger.info('RewardedAdManager: Not showing - dynamic config not available');
      onAdFailedToShow();
      return false;
    }

    // Don't show if rewarded ads are disabled
    if (!DynamicAdConfig.isEnabled('rewarded')) {
      Logger.info('RewardedAdManager: Not showing - rewarded ads disabled');
      onAdFailedToShow();
      return false;
    }

    // Don't show if no ad unit ID is available
    if (DynamicAdConfig.getAdUnitId('rewarded').isEmpty) {
      Logger.info('RewardedAdManager: Not showing - no ad unit ID available');
      onAdFailedToShow();
      return false;
    }

    if (_rewardedAd == null) {
      Logger.info('RewardedAdManager: No ad available, loading new one');
      await loadAd();
      onAdFailedToShow();
      return false;
    }

    // Check cooldown period
    final cooldownPeriod = DynamicAdConfig.getCooldownPeriod();
    if (_lastShowTime != null) {
      final timeSinceLastShow = DateTime.now().difference(_lastShowTime!);
      if (timeSinceLastShow.inSeconds < cooldownPeriod) {
        Logger.info('RewardedAdManager: Not showing - cooldown period not met');
        onAdFailedToShow();
        return false;
      }
    }

    try {
      Logger.info('RewardedAdManager: Showing rewarded ad');
      
      // Set cooldown for app open ads to prevent conflicts
      InterstitialAdManager.setAppOpenCooldown(const Duration(seconds: 20));
      
      // Set up reward callback (already set in loadAd, but safe to re-set)
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          Logger.info('RewardedAdManager: Ad showed full screen');
        },
        onAdImpression: (ad) {
          Logger.info('RewardedAdManager: Ad impression');
        },
        onAdClicked: (ad) {
          Logger.info('RewardedAdManager: Ad clicked');
      },
        onAdFailedToShowFullScreenContent: (ad, error) {
          Logger.error('RewardedAdManager: Ad failed to show: ${error.message}');
          onAdFailedToShow();
        ad.dispose();
          _rewardedAd = null;
          _isLoading = false;
        },
        onAdDismissedFullScreenContent: (ad) {
          Logger.info('RewardedAdManager: Ad dismissed');
          onAdClosed();
          ad.dispose();
          _rewardedAd = null;
          _lastShowTime = DateTime.now();
          _showCount++;
        },
      );

      await _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          Logger.info('RewardedAdManager: User earned reward: ${reward.amount} ${reward.type}');
          onUserEarnedReward(ad, reward);
        },
      );
      return true;
    } catch (e) {
      Logger.error('RewardedAdManager: Error showing ad: $e');
      onAdFailedToShow();
      _rewardedAd?.dispose();
      _rewardedAd = null;
      return false;
    }
  }

  /// Check if ad is ready to show
  static bool get isAdReady {
    if (!DynamicAdConfig.isAvailable) return false;
    if (!DynamicAdConfig.isEnabled('rewarded')) return false;
    if (DynamicAdConfig.getAdUnitId('rewarded').isEmpty) return false;
    return _rewardedAd != null;
  }

  /// Get current show count
  static int get showCount => _showCount;

  /// Reset show count
  static void resetShowCount() {
    _showCount = 0;
    Logger.info('RewardedAdManager: Show count reset');
    }

  /// Dispose current ad
  static void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isLoading = false;
    Logger.info('RewardedAdManager: Disposed');
  }
} 