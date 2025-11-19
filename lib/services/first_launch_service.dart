import 'package:shared_preferences/shared_preferences.dart';
// import '../widgets/google_ads/app_open_ads/app_open_ad_manager.dart';
import '../utils/logger.dart';

class FirstLaunchService {
  static final FirstLaunchService instance = FirstLaunchService._internal();
  FirstLaunchService._internal();

  static const String _firstLaunchKey = 'is_first_launch';
  static const String _firstLaunchAdShownKey = 'first_launch_ad_shown';

  /// Check if this is the first launch of the app
  Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirst = prefs.getBool(_firstLaunchKey) ?? true;
    Logger.info('FirstLaunchService: isFirstLaunch() = $isFirst');
    return isFirst;
  }

  /// Check if the first launch ad has already been shown
  Future<bool> hasFirstLaunchAdBeenShown() async {
    final prefs = await SharedPreferences.getInstance();
    final adShown = prefs.getBool(_firstLaunchAdShownKey) ?? false;
    Logger.info('FirstLaunchService: hasFirstLaunchAdBeenShown() = $adShown');
    return adShown;
  }

  /// Mark that this is no longer the first launch
  Future<void> markFirstLaunchComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstLaunchKey, false);
    Logger.info('FirstLaunchService: First launch marked as complete');
  }

  /// Mark that the first launch ad has been shown
  Future<void> markFirstLaunchAdShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstLaunchAdShownKey, true);
    Logger.info('FirstLaunchService: First launch ad marked as shown');
  }

  /// Show app open ad on first launch - simplified to show directly
  Future<void> showFirstLaunchAd() async {
    try {
      Logger.info('FirstLaunchService: showFirstLaunchAd() called');
      
      final isFirst = await isFirstLaunch();
      final adAlreadyShown = await hasFirstLaunchAdBeenShown();

      Logger.info('FirstLaunchService: isFirst = $isFirst, adAlreadyShown = $adAlreadyShown');

      if (!isFirst || adAlreadyShown) {
        Logger.info('FirstLaunchService: Not first launch or ad already shown - skipping ad');
        return;
      }

      // Mark that this is no longer the first launch
      await markFirstLaunchComplete();

      Logger.info('FirstLaunchService: Showing app open ad on first launch');

      // Show app open ad directly
      // AppOpenAdManager.instance.showOnFirstOpen();

      // Mark that the ad has been shown
      await markFirstLaunchAdShown();
      Logger.info('FirstLaunchService: First launch ad process completed');
      
    } catch (e) {
      Logger.error('FirstLaunchService: Error showing first launch ad: $e');
      // Even if there's an error, mark first launch as complete to avoid infinite loops
      await markFirstLaunchComplete();
    }
  }

  /// Reset first launch status (useful for testing)
  Future<void> resetFirstLaunchStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_firstLaunchKey);
    await prefs.remove(_firstLaunchAdShownKey);
    Logger.info('FirstLaunchService: First launch status reset');
  }

  /// Reset first launch status for testing (static method for easy access)
  static Future<void> resetForTesting() async {
    await instance.resetFirstLaunchStatus();
  }

  /// Get first launch status for debugging
  Future<Map<String, dynamic>> getFirstLaunchStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final status = {
      'is_first_launch': prefs.getBool(_firstLaunchKey) ?? true,
      'first_launch_ad_shown': prefs.getBool(_firstLaunchAdShownKey) ?? false,
    };
    Logger.info('FirstLaunchService: getFirstLaunchStatus() = $status');
    return status;
  }
} 