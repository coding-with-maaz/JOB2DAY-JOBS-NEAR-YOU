import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_review/in_app_review.dart';
import '../utils/logger.dart';

class ReviewService {
  static final ReviewService _instance = ReviewService._internal();
  factory ReviewService() => _instance;
  ReviewService._internal();

  static const String _hasRatedKey = 'hasRated';
  static const String _appOpenCountKey = 'appOpenCount';
  static const String _lastReviewPromptKey = 'lastReviewPrompt';
  static const String _positiveActionCountKey = 'positiveActionCount';
  
  // Minimum requirements before showing review prompt
  static const int _minAppOpens = 3;
  static const int _minPositiveActions = 5;
  static const int _minDaysSinceLastPrompt = 30;

  /// Check if user should be prompted for review
  Future<bool> shouldShowReviewPrompt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Don't show if user has already rated
      final hasRated = prefs.getBool(_hasRatedKey) ?? false;
      if (hasRated) return false;
      
      // Check app open count
      final appOpenCount = prefs.getInt(_appOpenCountKey) ?? 0;
      if (appOpenCount < _minAppOpens) return false;
      
      // Check positive actions (job applications, resume creation, etc.)
      final positiveActions = prefs.getInt(_positiveActionCountKey) ?? 0;
      if (positiveActions < _minPositiveActions) return false;
      
      // Check if enough time has passed since last prompt
      final lastPromptTime = prefs.getInt(_lastReviewPromptKey) ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final daysSinceLastPrompt = (currentTime - lastPromptTime) / (1000 * 60 * 60 * 24);
      
      if (daysSinceLastPrompt < _minDaysSinceLastPrompt) return false;
      
      return true;
    } catch (e) {
      Logger.error('ReviewService: Error checking review prompt conditions: $e');
      return false;
    }
  }

  /// Increment app open count
  Future<void> incrementAppOpenCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentCount = prefs.getInt(_appOpenCountKey) ?? 0;
      await prefs.setInt(_appOpenCountKey, currentCount + 1);
      Logger.info('ReviewService: App open count incremented to ${currentCount + 1}');
    } catch (e) {
      Logger.error('ReviewService: Error incrementing app open count: $e');
    }
  }

  /// Increment positive action count (job applications, resume creation, etc.)
  Future<void> incrementPositiveAction() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentCount = prefs.getInt(_positiveActionCountKey) ?? 0;
      await prefs.setInt(_positiveActionCountKey, currentCount + 1);
      Logger.info('ReviewService: Positive action count incremented to ${currentCount + 1}');
    } catch (e) {
      Logger.error('ReviewService: Error incrementing positive action count: $e');
    }
  }

  /// Mark that review prompt was shown
  Future<void> markReviewPromptShown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt(_lastReviewPromptKey, currentTime);
      Logger.info('ReviewService: Review prompt marked as shown');
    } catch (e) {
      Logger.error('ReviewService: Error marking review prompt shown: $e');
    }
  }

  /// Mark that user has rated the app
  Future<void> markAsRated() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hasRatedKey, true);
      Logger.info('ReviewService: User marked as rated');
    } catch (e) {
      Logger.error('ReviewService: Error marking user as rated: $e');
    }
  }

  /// Request review using in-app review
  Future<void> requestReview() async {
    try {
      final _inAppReview = InAppReview.instance;
      
      if (await _inAppReview.isAvailable()) {
        await _inAppReview.requestReview();
        Logger.info('ReviewService: In-app review requested successfully');
      } else {
        // Fallback: open the Play Store page directly
        await _inAppReview.openStoreListing(
          appStoreId: 'com.maazkhan07.jobsinquwait', // JOB2DAY app ID
        );
        Logger.info('ReviewService: Play Store listing opened as fallback');
      }
      
      // Mark as rated after successful review request
      await markAsRated();
    } catch (e) {
      Logger.error('ReviewService: Error requesting review: $e');
      rethrow;
    }
  }

  /// Reset review data (for testing or user preference)
  Future<void> resetReviewData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_hasRatedKey);
      await prefs.remove(_appOpenCountKey);
      await prefs.remove(_lastReviewPromptKey);
      await prefs.remove(_positiveActionCountKey);
      Logger.info('ReviewService: Review data reset');
    } catch (e) {
      Logger.error('ReviewService: Error resetting review data: $e');
    }
  }

  /// Get review statistics
  Future<Map<String, dynamic>> getReviewStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'hasRated': prefs.getBool(_hasRatedKey) ?? false,
        'appOpenCount': prefs.getInt(_appOpenCountKey) ?? 0,
        'positiveActionCount': prefs.getInt(_positiveActionCountKey) ?? 0,
        'lastReviewPrompt': prefs.getInt(_lastReviewPromptKey) ?? 0,
        'shouldShowPrompt': await shouldShowReviewPrompt(),
      };
    } catch (e) {
      Logger.error('ReviewService: Error getting review stats: $e');
      return {};
    }
  }

  /// Force show review prompt (for testing or manual triggers)
  Future<void> forceShowReviewPrompt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hasRatedKey, false);
      await prefs.setInt(_appOpenCountKey, _minAppOpens);
      await prefs.setInt(_positiveActionCountKey, _minPositiveActions);
      await prefs.remove(_lastReviewPromptKey);
      Logger.info('ReviewService: Review prompt conditions forced');
    } catch (e) {
      Logger.error('ReviewService: Error forcing review prompt: $e');
    }
  }
} 