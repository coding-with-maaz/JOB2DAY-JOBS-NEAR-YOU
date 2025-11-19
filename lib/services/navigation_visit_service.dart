import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';
import '../widgets/google_ads/interstitial_ads/interstitial_ad_manager.dart';

class NavigationVisitService {
  static final NavigationVisitService _instance = NavigationVisitService._internal();
  factory NavigationVisitService() => _instance;
  NavigationVisitService._internal();

  // SharedPreferences keys for each page type
  static const String _allJobsVisitCountKey = 'all_jobs_visit_count';
  static const String _todayJobsVisitCountKey = 'today_jobs_visit_count';
  static const String _countriesVisitCountKey = 'countries_visit_count';
  static const String _categoriesVisitCountKey = 'categories_visit_count';
  static const String _jobsPageVisitCountKey = 'jobs_page_visit_count';
  
  static const String _allJobsLastVisitKey = 'all_jobs_last_visit';
  static const String _todayJobsLastVisitKey = 'today_jobs_last_visit';
  static const String _countriesLastVisitKey = 'countries_last_visit';
  static const String _categoriesLastVisitKey = 'categories_last_visit';
  static const String _jobsPageLastVisitKey = 'jobs_page_last_visit';
  
  static const String _allJobsLastAdKey = 'all_jobs_last_ad';
  static const String _todayJobsLastAdKey = 'today_jobs_last_ad';
  static const String _countriesLastAdKey = 'countries_last_ad';
  static const String _categoriesLastAdKey = 'categories_last_ad';
  static const String _jobsPageLastAdKey = 'jobs_page_last_ad';

  // Global app session tracking
  static const String _appSessionCountKey = 'app_session_count';
  static const String _lastAppSessionKey = 'last_app_session';
  static const String _firstSessionAdShownKey = 'first_session_ad_shown';

  // Configuration - Improved for better UX
  static const int _requiredVisits = 3;
  static const Duration _minIntervalBetweenAds = Duration(minutes: 2); // Increased from 5 to 8 minutes
  static const Duration _visitResetInterval = Duration(hours: 24);
  static const Duration _sessionCooldown = Duration(minutes: 15); // Cooldown between session ads
  static const int _maxAdsPerDay = 8; // Limit total ads per day
  static const String _dailyAdCountKey = 'daily_ad_count';
  static const String _lastAdDateKey = 'last_ad_date';

  /// Track visit to a specific page and show ad if conditions are met
  /// Enhanced with better user experience handling
  Future<void> trackVisitAndShowAd(String pageType) async {
    try {
      final now = DateTime.now();
      
      // Check daily ad limit first
      if (!await _canShowAdToday()) {
        Logger.info('NavigationVisitService: Daily ad limit reached for $pageType');
        return;
      }

      final visitCount = await _getVisitCount(pageType);
      final lastVisitTime = await _getLastVisitTime(pageType);
      final lastAdTime = await _getLastAdTime(pageType);
      
      // Reset visit count if 24 hours have passed since last visit
      if (lastVisitTime != null && now.difference(lastVisitTime).inHours >= 24) {
        await _resetVisitCount(pageType);
        Logger.info('NavigationVisitService: Reset visit count for $pageType after 24 hours');
      }
      
      // Increment visit count
      final newVisitCount = visitCount + 1;
      await _setVisitCount(pageType, newVisitCount);
      await _setLastVisitTime(pageType, now);
      
      Logger.info('NavigationVisitService: Visit count for $pageType: $newVisitCount');
      
      // Check if we should show ad
      if (newVisitCount >= _requiredVisits) {
        if (await _canShowAd(lastAdTime)) {
          Logger.info('NavigationVisitService: Showing interstitial ad for $pageType after $newVisitCount visits');
          
          final success = await InterstitialAdManager.showAdOnPage(pageType);
          
          if (success) {
            // Reset visit count after showing ad
            await _resetVisitCount(pageType);
            await _setLastAdTime(pageType, now);
            await _incrementDailyAdCount();
            Logger.info('NavigationVisitService: Ad shown successfully for $pageType, visit count reset');
          } else {
            Logger.info('NavigationVisitService: Failed to show ad for $pageType');
          }
        } else {
          Logger.info('NavigationVisitService: Cannot show ad for $pageType - interval not met');
        }
      }
    } catch (e) {
      Logger.error('NavigationVisitService: Error tracking visit for $pageType: $e');
    }
  }

  /// Show ad on first session of the day (improved UX)
  Future<void> showFirstSessionAd() async {
    try {
      final now = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      
      // Check if we can show first session ad
      final lastSessionTime = prefs.getString(_lastAppSessionKey);
      final firstSessionAdShown = prefs.getBool(_firstSessionAdShownKey) ?? false;
      
      if (lastSessionTime != null) {
        final lastSession = DateTime.parse(lastSessionTime);
        final isNewDay = now.year != lastSession.year || 
                        now.month != lastSession.month || 
                        now.day != lastSession.day;
        
        // Reset first session ad flag for new day
        if (isNewDay) {
          await prefs.setBool(_firstSessionAdShownKey, false);
        }
      }
      
      // Check if first session ad already shown today
      final canShowFirstSessionAd = prefs.getBool(_firstSessionAdShownKey) ?? false;
      if (canShowFirstSessionAd) {
        Logger.info('NavigationVisitService: First session ad already shown today');
        return;
      }
      
      // Check daily ad limit
      if (!await _canShowAdToday()) {
        Logger.info('NavigationVisitService: Daily ad limit reached for first session ad');
        return;
      }
      
      // Check session cooldown
      if (lastSessionTime != null) {
        final lastSession = DateTime.parse(lastSessionTime);
        final timeSinceLastSession = now.difference(lastSession);
        if (timeSinceLastSession < _sessionCooldown) {
          Logger.info('NavigationVisitService: Session cooldown active, skipping first session ad');
          return;
        }
      }
      
      Logger.info('NavigationVisitService: Showing first session ad');
      
      final success = await InterstitialAdManager.showAd();
      
      if (success) {
        await prefs.setBool(_firstSessionAdShownKey, true);
        await prefs.setString(_lastAppSessionKey, now.toIso8601String());
        await _incrementDailyAdCount();
        Logger.info('NavigationVisitService: First session ad shown successfully');
      } else {
        Logger.info('NavigationVisitService: Failed to show first session ad');
      }
      
    } catch (e) {
      Logger.error('NavigationVisitService: Error showing first session ad: $e');
    }
  }

  /// Check if enough time has passed since last ad
  Future<bool> _canShowAd(DateTime? lastAdTime) async {
    if (lastAdTime == null) return true;
    
    final timeSinceLastAd = DateTime.now().difference(lastAdTime);
    final canShow = timeSinceLastAd >= _minIntervalBetweenAds;
    
    Logger.info('NavigationVisitService: Can show ad: $canShow (${timeSinceLastAd.inMinutes} minutes since last ad)');
    return canShow;
  }

  /// Check if we can show ads today (daily limit)
  Future<bool> _canShowAdToday() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    
    // Check if it's a new day
    final lastAdDateString = prefs.getString(_lastAdDateKey);
    if (lastAdDateString != null) {
      final lastAdDate = DateTime.parse(lastAdDateString);
      final isNewDay = now.year != lastAdDate.year || 
                      now.month != lastAdDate.month || 
                      now.day != lastAdDate.day;
      
      if (isNewDay) {
        // Reset daily count for new day
        await prefs.setInt(_dailyAdCountKey, 0);
        await prefs.setString(_lastAdDateKey, now.toIso8601String());
      }
    } else {
      // First time, set today's date
      await prefs.setString(_lastAdDateKey, now.toIso8601String());
    }
    
    final dailyAdCount = prefs.getInt(_dailyAdCountKey) ?? 0;
    final canShow = dailyAdCount < _maxAdsPerDay;
    
    Logger.info('NavigationVisitService: Daily ad count: $dailyAdCount/$_maxAdsPerDay, can show: $canShow');
    return canShow;
  }

  /// Increment daily ad count
  Future<void> _incrementDailyAdCount() async {
    final prefs = await SharedPreferences.getInstance();
    final currentCount = prefs.getInt(_dailyAdCountKey) ?? 0;
    await prefs.setInt(_dailyAdCountKey, currentCount + 1);
    Logger.info('NavigationVisitService: Daily ad count incremented to ${currentCount + 1}');
  }

  /// Get visit count for a page type
  Future<int> _getVisitCount(String pageType) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getVisitCountKey(pageType);
    return prefs.getInt(key) ?? 0;
  }

  /// Set visit count for a page type
  Future<void> _setVisitCount(String pageType, int count) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getVisitCountKey(pageType);
    await prefs.setInt(key, count);
  }

  /// Reset visit count for a page type
  Future<void> _resetVisitCount(String pageType) async {
    await _setVisitCount(pageType, 0);
  }

  /// Get last visit time for a page type
  Future<DateTime?> _getLastVisitTime(String pageType) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getLastVisitKey(pageType);
    final timeString = prefs.getString(key);
    return timeString != null ? DateTime.parse(timeString) : null;
  }

  /// Set last visit time for a page type
  Future<void> _setLastVisitTime(String pageType, DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getLastVisitKey(pageType);
    await prefs.setString(key, time.toIso8601String());
  }

  /// Get last ad time for a page type
  Future<DateTime?> _getLastAdTime(String pageType) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getLastAdKey(pageType);
    final timeString = prefs.getString(key);
    return timeString != null ? DateTime.parse(timeString) : null;
  }

  /// Set last ad time for a page type
  Future<void> _setLastAdTime(String pageType, DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getLastAdKey(pageType);
    await prefs.setString(key, time.toIso8601String());
  }

  /// Get SharedPreferences key for visit count
  String _getVisitCountKey(String pageType) {
    switch (pageType) {
      case 'AllJobs':
        return _allJobsVisitCountKey;
      case 'TodayJobs':
        return _todayJobsVisitCountKey;
      case 'Countries':
        return _countriesVisitCountKey;
      case 'Categories':
        return _categoriesVisitCountKey;
      case 'JobsPage':
        return _jobsPageVisitCountKey;
      default:
        return '${pageType.toLowerCase()}_visit_count';
    }
  }

  /// Get SharedPreferences key for last visit time
  String _getLastVisitKey(String pageType) {
    switch (pageType) {
      case 'AllJobs':
        return _allJobsLastVisitKey;
      case 'TodayJobs':
        return _todayJobsLastVisitKey;
      case 'Countries':
        return _countriesLastVisitKey;
      case 'Categories':
        return _categoriesLastVisitKey;
      case 'JobsPage':
        return _jobsPageLastVisitKey;
      default:
        return '${pageType.toLowerCase()}_last_visit';
    }
  }

  /// Get SharedPreferences key for last ad time
  String _getLastAdKey(String pageType) {
    switch (pageType) {
      case 'AllJobs':
        return _allJobsLastAdKey;
      case 'TodayJobs':
        return _todayJobsLastAdKey;
      case 'Countries':
        return _countriesLastAdKey;
      case 'Categories':
        return _categoriesLastAdKey;
      case 'JobsPage':
        return _jobsPageLastAdKey;
      default:
        return '${pageType.toLowerCase()}_last_ad';
    }
  }

  /// Get visit statistics for debugging
  Future<Map<String, dynamic>> getVisitStats(String pageType) async {
    try {
      final visitCount = await _getVisitCount(pageType);
      final lastVisitTime = await _getLastVisitTime(pageType);
      final lastAdTime = await _getLastAdTime(pageType);
      final canShowToday = await _canShowAdToday();
      
      return {
        'pageType': pageType,
        'visitCount': visitCount,
        'lastVisitTime': lastVisitTime?.toIso8601String(),
        'lastAdTime': lastAdTime?.toIso8601String(),
        'canShowAd': await _canShowAd(lastAdTime),
        'canShowToday': canShowToday,
        'requiredVisits': _requiredVisits,
        'visitsUntilAd': _requiredVisits - visitCount,
        'minIntervalMinutes': _minIntervalBetweenAds.inMinutes,
        'sessionCooldownMinutes': _sessionCooldown.inMinutes,
        'maxAdsPerDay': _maxAdsPerDay,
      };
    } catch (e) {
      Logger.error('NavigationVisitService: Error getting visit stats for $pageType: $e');
      return {};
    }
  }

  /// Reset all visit data (for testing)
  Future<void> resetAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Reset all page-specific data
      final pageTypes = ['AllJobs', 'TodayJobs', 'Countries', 'Categories', 'JobsPage'];
      
      for (final pageType in pageTypes) {
        await prefs.remove(_getVisitCountKey(pageType));
        await prefs.remove(_getLastVisitKey(pageType));
        await prefs.remove(_getLastAdKey(pageType));
      }
      
      // Reset global session data
      await prefs.remove(_appSessionCountKey);
      await prefs.remove(_lastAppSessionKey);
      await prefs.remove(_firstSessionAdShownKey);
      await prefs.remove(_dailyAdCountKey);
      await prefs.remove(_lastAdDateKey);
      
      Logger.info('NavigationVisitService: All visit data reset');
    } catch (e) {
      Logger.error('NavigationVisitService: Error resetting data: $e');
    }
  }

  /// Get comprehensive ad statistics
  Future<Map<String, dynamic>> getAdStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      
      final dailyAdCount = prefs.getInt(_dailyAdCountKey) ?? 0;
      final lastAdDateString = prefs.getString(_lastAdDateKey);
      final firstSessionAdShown = prefs.getBool(_firstSessionAdShownKey) ?? false;
      final lastSessionString = prefs.getString(_lastAppSessionKey);
      
      DateTime? lastAdDate;
      DateTime? lastSession;
      
      if (lastAdDateString != null) {
        lastAdDate = DateTime.parse(lastAdDateString);
      }
      
      if (lastSessionString != null) {
        lastSession = DateTime.parse(lastSessionString);
      }
      
      return {
        'dailyAdCount': dailyAdCount,
        'maxAdsPerDay': _maxAdsPerDay,
        'adsRemainingToday': _maxAdsPerDay - dailyAdCount,
        'lastAdDate': lastAdDate?.toIso8601String(),
        'firstSessionAdShown': firstSessionAdShown,
        'lastSession': lastSession?.toIso8601String(),
        'sessionCooldownMinutes': _sessionCooldown.inMinutes,
        'minIntervalMinutes': _minIntervalBetweenAds.inMinutes,
        'requiredVisits': _requiredVisits,
        'visitResetHours': _visitResetInterval.inHours,
      };
    } catch (e) {
      Logger.error('NavigationVisitService: Error getting ad statistics: $e');
      return {};
    }
  }
} 