import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../../utils/logger.dart';
import '../dynamic_ad_config.dart';

class InterstitialAdManager {
  static InterstitialAd? _interstitialAd;
  static bool _isLoading = false;
  static DateTime? _lastShowTime;
  static int _showCount = 0;
  static DateTime? _appOpenCooldownUntil;

  /// Initialize interstitial ads
  static Future<void> initialize() async {
    Logger.info('InterstitialAdManager: Initializing...');
    
    // Check if dynamic config is available
    if (!DynamicAdConfig.isAvailable) {
      Logger.info('InterstitialAdManager: Dynamic config not available, not initializing');
      return;
    }

    // Check if interstitial ads are enabled
    if (!DynamicAdConfig.isEnabled('interstitial')) {
      Logger.info('InterstitialAdManager: Interstitial ads disabled in dynamic config');
      return;
    }

    // Check if we have a valid ad unit ID
    final adUnitId = DynamicAdConfig.getAdUnitId('interstitial');
    if (adUnitId.isEmpty) {
      Logger.info('InterstitialAdManager: No dynamic interstitial ad unit ID available');
      return;
    }

    Logger.info('InterstitialAdManager: Initialized with dynamic config');
  }

  /// Load interstitial ad
  static Future<void> loadAd() async {
    // Don't load if dynamic config is not available
    if (!DynamicAdConfig.isAvailable) {
      Logger.info('InterstitialAdManager: Not loading - dynamic config not available');
      return;
    }

    // Don't load if interstitial ads are disabled
    if (!DynamicAdConfig.isEnabled('interstitial')) {
      Logger.info('InterstitialAdManager: Not loading - interstitial ads disabled');
      return;
    }

    // Don't load if no ad unit ID is available
    final adUnitId = DynamicAdConfig.getAdUnitId('interstitial');
    if (adUnitId.isEmpty) {
      Logger.info('InterstitialAdManager: Not loading - no ad unit ID available');
      return;
    }

    if (_isLoading) {
      Logger.info('InterstitialAdManager: Already loading, skipping');
      return;
    }

    _isLoading = true;
    Logger.info('InterstitialAdManager: Loading interstitial ad with dynamic ID: $adUnitId');

    try {
      await InterstitialAd.load(
        adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            Logger.info('InterstitialAdManager: Ad loaded successfully');
          _interstitialAd = ad;
            _isLoading = false;
            
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                Logger.info('InterstitialAdManager: Ad dismissed');
                ad.dispose();
                _interstitialAd = null;
                _lastShowTime = DateTime.now();
                _showCount++;
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                Logger.error('InterstitialAdManager: Ad failed to show: ${error.message}');
                ad.dispose();
                _interstitialAd = null;
                _isLoading = false;
              },
              onAdShowedFullScreenContent: (ad) {
                Logger.info('InterstitialAdManager: Ad showed full screen');
                // Notify AppOpenAdManager that interstitial was shown
              },
            );
          },
          onAdFailedToLoad: (error) {
            Logger.error('InterstitialAdManager: Ad failed to load: ${error.message}');
            _interstitialAd = null;
            _isLoading = false;
        },
      ),
    );
    } catch (e) {
      Logger.error('InterstitialAdManager: Error loading ad: $e');
      _isLoading = false;
    }
  }

  /// Show interstitial ad
  static Future<bool> showAd() async {
    // Don't show if in App Open cooldown
    if (isInAppOpenCooldown) {
      Logger.info('InterstitialAdManager: Not showing - in App Open cooldown');
      return false;
    }

    // Don't show if dynamic config is not available
    if (!DynamicAdConfig.isAvailable) {
      Logger.info('InterstitialAdManager: Not showing - dynamic config not available');
      return false;
    }

    // Don't show if interstitial ads are disabled
    if (!DynamicAdConfig.isEnabled('interstitial')) {
      Logger.info('InterstitialAdManager: Not showing - interstitial ads disabled');
      return false;
    }

    // Don't show if no ad unit ID is available
    if (DynamicAdConfig.getAdUnitId('interstitial').isEmpty) {
      Logger.info('InterstitialAdManager: Not showing - no ad unit ID available');
      return false;
    }

    if (_interstitialAd == null) {
      Logger.info('InterstitialAdManager: No ad available, loading new one');
      await loadAd();
      return false;
    }

    // Check minimum interval
    final minInterval = DynamicAdConfig.getInterstitialMinInterval();
    if (_lastShowTime != null) {
      final timeSinceLastShow = DateTime.now().difference(_lastShowTime!);
      if (timeSinceLastShow.inSeconds < minInterval) {
        Logger.info('InterstitialAdManager: Not showing - minimum interval not met');
        return false;
      }
    }

    // Check max ads per session
    final maxAdsPerSession = DynamicAdConfig.getMaxAdsPerSession();
    if (_showCount >= maxAdsPerSession) {
      Logger.info('InterstitialAdManager: Not showing - max ads per session reached');
      return false;
    }

    try {
      Logger.info('InterstitialAdManager: Showing interstitial ad');
      
      // Set cooldown for app open ads to prevent conflicts
      setAppOpenCooldown(const Duration(seconds: 20));
      
      await _interstitialAd!.show();
      return true;
    } catch (e) {
      Logger.error('InterstitialAdManager: Error showing ad: $e');
      _interstitialAd?.dispose();
      _interstitialAd = null;
      return false;
    }
  }

  /// Show interstitial ad on specific page type
  static Future<bool> showAdOnPage(String pageType) async {
    // Don't show if in App Open cooldown
    if (isInAppOpenCooldown) {
      Logger.info('InterstitialAdManager: Not showing on $pageType - in App Open cooldown');
      return false;
    }

    // Don't show if dynamic config is not available
    if (!DynamicAdConfig.isAvailable) {
      Logger.info('InterstitialAdManager: Not showing on $pageType - dynamic config not available');
      return false;
    }

    // Check if should show on this page type
    if (!DynamicAdConfig.shouldShowInterstitialOn(pageType)) {
      Logger.info('InterstitialAdManager: Not showing on $pageType - disabled for this page');
      return false;
    }

    return await showAd();
  }

  /// Check if ad is ready to show
  static bool get isAdReady {
    if (!DynamicAdConfig.isAvailable) return false;
    if (!DynamicAdConfig.isEnabled('interstitial')) return false;
    if (DynamicAdConfig.getAdUnitId('interstitial').isEmpty) return false;
    return _interstitialAd != null;
  }

  /// Get current show count
  static int get showCount => _showCount;

  /// Reset show count
  static void resetShowCount() {
    _showCount = 0;
    Logger.info('InterstitialAdManager: Show count reset');
  }

  /// Dispose current ad
  static void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isLoading = false;
    Logger.info('InterstitialAdManager: Disposed');
  }

  static void setAppOpenCooldown([Duration duration = const Duration(seconds: 10)]) {
    _appOpenCooldownUntil = DateTime.now().add(duration);
  }
  static bool get isInAppOpenCooldown {
    if (_appOpenCooldownUntil == null) return false;
    return DateTime.now().isBefore(_appOpenCooldownUntil!);
  }
} 