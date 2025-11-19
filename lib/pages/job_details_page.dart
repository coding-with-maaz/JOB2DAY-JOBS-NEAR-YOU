import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/job.dart';
import '../services/job_service.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../widgets/loading_indicator.dart';
import 'package:photo_view/photo_view.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/network_aware_widget.dart';
import '../widgets/google_ads/interstitial_ads/interstitial_ad_manager.dart';
import '../utils/logger.dart';
import 'package:flutter/services.dart';
import '../widgets/google_ads/rewarded_ads/rewarded_ad_manager.dart';
import '../widgets/google_ads/native_ads/native_ad_widget.dart';
import '../widgets/google_ads/banner_ads/banner_ad_widget.dart';
import '../services/review_service.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

// 🎯 COMPREHENSIVE ADS IMPLEMENTATION
// This page includes multiple strategic ad placements for maximum monetization:
// 
// REWARDED ADS:
// 1. Job Application Success - Rewarded ad after successful application submission
// 2. Visit Tracking - Rewarded ad after 3 visits (with 5-minute interval, resets after reward)
// 
// INTERSTITIAL ADS:
// 3. Visit Tracking - Interstitial ad after 4 visits (with 5-minute interval, resets after ad)
// 
// BANNER ADS:
// 4. Bottom Banner - Banner ad at the bottom of the page
// 
// VISIT TRACKING SYSTEM:
// - Tracks user visits to job details page
// - Shows rewarded ad after 3 visits (with 5-minute interval, resets after reward)
// - Shows interstitial ad after 4 visits (with 5-minute interval, resets after ad)
// - 5-minute cooldown between ads of the same type
// - Visit counts reset after ads are shown
// - 24-hour auto-reset for inactivity
// - Visual progress indicators with countdown timers for both ad types
// 
// All ads use dynamic configuration and respect user experience with proper timing and cooldowns.

// Design system colors
const primaryColor = Colors.deepPurple;
const backgroundColor = Color(0xFFFFF7F4);
const textPrimaryColor = Color(0xFF1A1A1A);
const textSecondaryColor = Color(0xFF3C3C43);
const activeTabColor = Color(0xFFFCEEEE);
const inactiveTabColor = Color(0xFFB0B0B0);

final ButtonStyle unifiedButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: primaryColor,
  foregroundColor: Colors.white,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
  elevation: 2,
);

final TextStyle unifiedHeaderStyle = TextStyle(
  fontWeight: FontWeight.bold,
  color: textPrimaryColor,
  fontSize: 24,
  letterSpacing: 0.5,
  fontFamily: 'Poppins',
);

final TextStyle unifiedBodyStyle = TextStyle(
  color: textSecondaryColor,
  fontSize: 16,
  fontWeight: FontWeight.w500,
  fontFamily: 'Poppins',
);

// Add more design system styles for form fields, snackbars, etc.
final InputDecoration unifiedInputDecoration = InputDecoration(
  filled: true,
  fillColor: Colors.white,
  labelStyle: TextStyle(color: textSecondaryColor, fontFamily: 'Poppins'),
  hintStyle: TextStyle(color: textSecondaryColor.withOpacity(0.7), fontFamily: 'Poppins'),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: activeTabColor, width: 1),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: activeTabColor, width: 1),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: primaryColor, width: 2),
  ),
  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
);

final BoxDecoration unifiedBottomSheetDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 24,
      offset: const Offset(0, -4),
    ),
  ],
);

// Helper for pill style (top-level)
Widget buildPill(String text, {Color? bgColor, Color? borderColor, Color? textColor, double fontSize = 14, EdgeInsetsGeometry? margin}) {
  return Container(
    margin: margin ?? const EdgeInsets.only(right: 8, bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: bgColor ?? activeTabColor,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: borderColor ?? activeTabColor.withOpacity(0.7), width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Text(
      text,
      style: TextStyle(
        color: textColor ?? primaryColor,
        fontWeight: FontWeight.bold,
        fontFamily: 'Poppins',
        fontSize: fontSize,
      ),
    ),
  );
}

class JobDetailsPage extends StatefulWidget {
  final String jobSlug;

  const JobDetailsPage({
    super.key,
    required this.jobSlug,
  });

  @override
  State<JobDetailsPage> createState() => _JobDetailsPageState();
}

class _JobDetailsPageState extends State<JobDetailsPage> {
  final JobService _jobService = JobService();
  
  Job? _job;
  bool _isLoading = true;
  String? _error;
  bool _isSaved = false;
  final ScrollController _scrollController = ScrollController();
  
  // Interval and visit tracking for rewarded ads
  static const String _visitCountKey = 'job_details_visit_count';
  static const String _lastVisitTimeKey = 'job_details_last_visit_time';
  static const String _lastRewardedAdTimeKey = 'job_details_last_rewarded_ad_time';
  static const int _requiredVisits = 3;
  static const Duration _minIntervalBetweenAds = Duration(minutes: 5);
  static const Duration _visitResetInterval = Duration(hours: 24);
  int _visitCount = 0;
  DateTime? _lastVisitTime;
  DateTime? _lastRewardedAdTime;

  // Interval and visit tracking for interstitial ads
  static const String _interstitialVisitCountKey = 'job_details_interstitial_visit_count';
  static const String _lastInterstitialVisitTimeKey = 'job_details_last_interstitial_visit_time';
  static const String _lastInterstitialAdTimeKey = 'job_details_last_interstitial_ad_time';
  static const int _requiredInterstitialVisits = 4;
  static const Duration _minIntervalBetweenInterstitialAds = Duration(minutes: 5);
  int _interstitialVisitCount = 0;
  DateTime? _lastInterstitialVisitTime;
  DateTime? _lastInterstitialAdTime;

  @override
  void initState() {
    super.initState();
    _loadJob();
    _loadVisitData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }



  // Load visit data from SharedPreferences
  Future<void> _loadVisitData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load rewarded ad visit data
      _visitCount = prefs.getInt(_visitCountKey) ?? 0;
      final lastVisitTimeString = prefs.getString(_lastVisitTimeKey);
      final lastRewardedAdTimeString = prefs.getString(_lastRewardedAdTimeKey);
      
      if (lastVisitTimeString != null) {
        _lastVisitTime = DateTime.parse(lastVisitTimeString);
      }
      
      if (lastRewardedAdTimeString != null) {
        _lastRewardedAdTime = DateTime.parse(lastRewardedAdTimeString);
      }
      
      // Load interstitial ad visit data
      _interstitialVisitCount = prefs.getInt(_interstitialVisitCountKey) ?? 0;
      final lastInterstitialVisitTimeString = prefs.getString(_lastInterstitialVisitTimeKey);
      final lastInterstitialAdTimeString = prefs.getString(_lastInterstitialAdTimeKey);
      
      if (lastInterstitialVisitTimeString != null) {
        _lastInterstitialVisitTime = DateTime.parse(lastInterstitialVisitTimeString);
      }
      
      if (lastInterstitialAdTimeString != null) {
        _lastInterstitialAdTime = DateTime.parse(lastInterstitialAdTimeString);
      }
      
      Logger.info('JobDetailsPage: Loaded visit data - rewarded count: $_visitCount, interstitial count: $_interstitialVisitCount');
    } catch (e) {
      Logger.error('JobDetailsPage: Error loading visit data: $e');
    }
  }

  // Save visit data to SharedPreferences
  Future<void> _saveVisitData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save rewarded ad visit data
      await prefs.setInt(_visitCountKey, _visitCount);
      if (_lastVisitTime != null) {
        await prefs.setString(_lastVisitTimeKey, _lastVisitTime!.toIso8601String());
      } else {
        // Clear the stored last visit time when resetting
        await prefs.remove(_lastVisitTimeKey);
      }
      
      if (_lastRewardedAdTime != null) {
        await prefs.setString(_lastRewardedAdTimeKey, _lastRewardedAdTime!.toIso8601String());
      }
      
      // Save interstitial ad visit data
      await prefs.setInt(_interstitialVisitCountKey, _interstitialVisitCount);
      if (_lastInterstitialVisitTime != null) {
        await prefs.setString(_lastInterstitialVisitTimeKey, _lastInterstitialVisitTime!.toIso8601String());
      } else {
        // Clear the stored last visit time when resetting
        await prefs.remove(_lastInterstitialVisitTimeKey);
      }
      
      if (_lastInterstitialAdTime != null) {
        await prefs.setString(_lastInterstitialAdTimeKey, _lastInterstitialAdTime!.toIso8601String());
      }
      
      Logger.info('JobDetailsPage: Saved visit data - rewarded count: $_visitCount, interstitial count: $_interstitialVisitCount');
    } catch (e) {
      Logger.error('JobDetailsPage: Error saving visit data: $e');
    }
  }

  // Increment visit count and check if rewarded ad should be shown
  Future<void> _incrementVisitCount() async {
    final now = DateTime.now();
    
    // Reset rewarded visit count if 24 hours have passed since last visit
    if (_lastVisitTime != null && now.difference(_lastVisitTime!).inHours >= 24) {
      _visitCount = 0;
      Logger.info('JobDetailsPage: Reset rewarded visit count after 24 hours');
    }
    
    // Reset interstitial visit count if 24 hours have passed since last visit
    if (_lastInterstitialVisitTime != null && now.difference(_lastInterstitialVisitTime!).inHours >= 24) {
      _interstitialVisitCount = 0;
      Logger.info('JobDetailsPage: Reset interstitial visit count after 24 hours');
    }
    
    _visitCount++;
    _interstitialVisitCount++;
    _lastVisitTime = now;
    _lastInterstitialVisitTime = now;
    
    Logger.info('JobDetailsPage: Visit counts incremented - rewarded: $_visitCount, interstitial: $_interstitialVisitCount');
    
    // Save the updated visit data
    await _saveVisitData();
    
    // Check if we should show the rewarded ad
    if (_visitCount >= _requiredVisits) {
      _checkAndShowVisitRewardedAd();
    }
    
    // Check if we should show the interstitial ad
    if (_interstitialVisitCount >= _requiredInterstitialVisits) {
      _checkAndShowVisitInterstitialAd();
    }
  }

  // Check if enough time has passed since last rewarded ad
  bool _canShowRewardedAd() {
    if (_lastRewardedAdTime == null) return true;
    
    final timeSinceLastAd = DateTime.now().difference(_lastRewardedAdTime!);
    final canShow = timeSinceLastAd >= _minIntervalBetweenAds;
    
    Logger.info('JobDetailsPage: Can show rewarded ad: $canShow (${timeSinceLastAd.inMinutes} minutes since last ad)');
    return canShow;
  }

  // Check if enough time has passed since last interstitial ad
  bool _canShowInterstitialAd() {
    if (_lastInterstitialAdTime == null) return true;
    
    final timeSinceLastAd = DateTime.now().difference(_lastInterstitialAdTime!);
    final canShow = timeSinceLastAd >= _minIntervalBetweenInterstitialAds;
    
    Logger.info('JobDetailsPage: Can show interstitial ad: $canShow (${timeSinceLastAd.inMinutes} minutes since last ad)');
    return canShow;
  }

  // Get formatted time until next reward is available
  String _getTimeUntilNextReward() {
    if (_lastRewardedAdTime == null) return '';
    
    final timeSinceLastAd = DateTime.now().difference(_lastRewardedAdTime!);
    final timeRemaining = _minIntervalBetweenAds - timeSinceLastAd;
    
    if (timeRemaining.isNegative) return '';
    
    final minutes = timeRemaining.inMinutes;
    final seconds = timeRemaining.inSeconds % 60;
    
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  // Get formatted time until next interstitial ad is available
  String _getTimeUntilNextInterstitialAd() {
    if (_lastInterstitialAdTime == null) return '';
    
    final timeSinceLastAd = DateTime.now().difference(_lastInterstitialAdTime!);
    final timeRemaining = _minIntervalBetweenInterstitialAds - timeSinceLastAd;
    
    if (timeRemaining.isNegative) return '';
    
    final minutes = timeRemaining.inMinutes;
    final seconds = timeRemaining.inSeconds % 60;
    
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  // Show rewarded ad for visiting job details page multiple times
  // This method resets the visit count to 0 after showing the ad,
  // allowing users to earn rewards again after 3 more visits
  void _checkAndShowVisitRewardedAd() {
    if (!_canShowRewardedAd()) {
      Logger.info('JobDetailsPage: Skipping visit rewarded ad - interval not met');
      return;
    }
    
    Logger.info('JobDetailsPage: Showing visit rewarded ad for $_visitCount visits');
    
    RewardedAdManager.showAd(
      onUserEarnedReward: (ad, reward) {
        _lastRewardedAdTime = DateTime.now();
        
        // Reset visit count after showing rewarded ad so user can earn again
        // This allows the cycle to repeat: 3 visits → reward → reset → 3 visits → reward
        _visitCount = 0;
        _lastVisitTime = null; // Clear last visit time to start fresh
        _saveVisitData();
        
        // Update UI to reflect the reset
        setState(() {});
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 You earned ${reward.amount} ${reward.type} for visiting this job $_requiredVisits times!'),
            backgroundColor: Colors.deepPurple,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
      onAdClosed: () {
        Logger.info('JobDetailsPage: Visit rewarded ad closed');
      },
      onAdFailedToShow: () {
        Logger.info('JobDetailsPage: Visit rewarded ad failed to show');
      },
    );
  }

  // Show interstitial ad for visiting job details page multiple times
  // This method resets the visit count to 0 after showing the ad,
  // Visit tracking interstitial ads removed for better user experience
  void _checkAndShowVisitInterstitialAd() {
    // Interstitial ads on visit tracking removed - too frequent and irritating
    Logger.info('JobDetailsPage: Visit interstitial ads disabled for better UX');
  }



  void _showCompanyDetails() async {
    _showCompanyDetailsDialog();
  }

  void _showCompanyDetailsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('About ${_job?.companyName ?? 'Company'}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_job?.logoUrl != null) ...[
              Center(
                child: Image.network(
                  _job!.logoUrl!,
                  height: 60,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.business,
                    size: 60,
                    color: primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text('Company: ${_job?.companyName ?? 'Not specified'}'),
            const SizedBox(height: 8),
            Text('Industry: ${_job?.industry ?? 'Not specified'}'),
            const SizedBox(height: 8),
            Text('Location: ${_job?.location ?? 'Not specified'}'),
            const SizedBox(height: 8),
            Text('Job Type: ${_job?.jobType ?? 'Not specified'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }



  Future<void> _loadJob() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final job = await _jobService.getJobBySlug(widget.jobSlug);
      
      if (!mounted) return;
      
      setState(() {
        _job = job;
        _isLoading = false;
      });
      
      // Increment visit count after job is successfully loaded
      _incrementVisitCount();
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading job details: $e'),
            backgroundColor: primaryColor,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadJob,
              textColor: Colors.white,
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _toggleSave() async {
    setState(() {
      _isSaved = !_isSaved;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isSaved ? 'Job saved to favorites' : 'Job removed from favorites'),
        backgroundColor: _isSaved ? primaryColor : Colors.grey,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareJob() async {
    if (_job != null) {
      Share.share(
        'Check out this job opportunity: ${_job!.title} at ${_job!.companyName}\n\n'
        'Location: ${_job!.location}\n'
        'Job Type: ${_job!.jobType}\n'
        'Salary: ${_job!.salary}\n\n'
        'Apply now!',
      );
    }
  }

  void _showApplicationForm() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: unifiedBottomSheetDecoration,
        child: _MockApplyForm(
          onApplicationSubmitted: () {
            // Application submitted - success ad will be shown in the form
          },
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open the application link'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: primaryColor.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon, 
              size: 20, 
              color: primaryColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: unifiedBodyStyle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: unifiedHeaderStyle.copyWith(fontSize: 18, color: primaryColor),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: primaryColor.withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: content,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use design system colors
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: NetworkAwareWidget(
        child: Scaffold(
          backgroundColor: backgroundColor,
          body: _isLoading
              ? const Center(child: LoadingIndicator(size: 40))
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: primaryColor,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading job details',
                            style: unifiedHeaderStyle,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _error!,
                            style: unifiedBodyStyle,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _loadJob,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                            style: unifiedButtonStyle,
                          ),
                        ],
                      ),
                    )
                  : _job == null
                      ? const Center(child: Text('Job not found'))
                      : CustomScrollView(
                          controller: _scrollController,
                          slivers: [
                            // Modern Hero Section (App Bar with Job Info)
                            SliverAppBar(
                              pinned: true,
                              backgroundColor: Colors.transparent,
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              leading: Container(
                                margin: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ),
                              title: _job != null
                                  ? Text(
                                      _job!.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Poppins',
                                        shadows: [
                                          Shadow(
                                            offset: Offset(1, 1),
                                            blurRadius: 2,
                                            color: Color.fromARGB(128, 0, 0, 0),
                                          ),
                                        ],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  : null,
                              actions: [
                                IconButton(
                                  icon: const Icon(Icons.share, color: Colors.white),
                                  onPressed: _shareJob,
                                ),
                              ],
                              flexibleSpace: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.deepPurple,
                                      Color(0xFF9C27B0),
                                      Color(0xFFBA68C8),
                                    ],
                                    stops: [0.0, 0.6, 1.0],
                                  ),
                                ),
                              ),
                            ),
                            // Job Details Content
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Key Information
                                    _buildSection(
                                      'Key Information',
                                      Column(
                                        children: [
                                          // Company name with clickable details
                                          GestureDetector(
                                            onTap: _showCompanyDetails,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                              margin: const EdgeInsets.only(bottom: 8),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: primaryColor.withOpacity(0.1),
                                                  width: 1,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: primaryColor.withOpacity(0.05),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: primaryColor.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Icon(
                                                      Icons.business,
                                                      size: 20,
                                                      color: primaryColor,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  Expanded(
                                                    child: Text(
                                                      _job!.companyName ?? 'Not specified',
                                                      style: unifiedBodyStyle.copyWith(
                                                        color: primaryColor,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                  Icon(
                                                    Icons.info_outline,
                                                    color: primaryColor.withOpacity(0.7),
                                                    size: 20,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          _buildInfoRow(
                                            Icons.location_on_outlined,
                                            _job!.location ?? 'Not specified',
                                          ),
                                          _buildInfoRow(
                                            Icons.work_outline,
                                            _job!.jobType ?? 'Not specified',
                                          ),
                                          _buildInfoRow(
                                            Icons.attach_money,
                                            _job!.salary ?? 'Not specified',
                                          ),
                                          _buildInfoRow(
                                            Icons.schedule,
                                            _job!.experience ?? 'Not specified',
                                          ),
                                          _buildInfoRow(
                                            Icons.school,
                                            _job!.qualification ?? 'Not specified',
                                          ),
                                          _buildInfoRow(
                                            Icons.business,
                                            _job!.industry ?? 'Not specified',
                                          ),
                                          _buildInfoRow(
                                            Icons.people,
                                            '${_job!.vacancy ?? 1} positions',
                                          ),
                                          _buildInfoRow(
                                            Icons.calendar_today,
                                            _job!.applyBefore != null
                                                ? timeago.format(_job!.applyBefore)
                                                : 'Not specified',
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Description
                                    _buildSection(
                                      'Description',
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Html(
                                            data: _job!.description ?? 'No description available',
                                            style: {
                                              'body': Style(
                                                fontSize: FontSize(16),
                                                lineHeight: LineHeight(1.5),
                                                color: textSecondaryColor,
                                                fontFamily: 'Poppins',
                                              ),
                                              'p': Style(
                                                margin: Margins.only(bottom: 16),
                                                color: textSecondaryColor,
                                                fontFamily: 'Poppins',
                                              ),
                                              'h1': Style(
                                                fontSize: FontSize(24),
                                                fontWeight: FontWeight.bold,
                                                margin: Margins.only(bottom: 16),
                                                color: textPrimaryColor,
                                                fontFamily: 'Poppins',
                                              ),
                                              'h2': Style(
                                                fontSize: FontSize(20),
                                                fontWeight: FontWeight.bold,
                                                margin: Margins.only(bottom: 16),
                                                color: textPrimaryColor,
                                                fontFamily: 'Poppins',
                                              ),
                                              'h3': Style(
                                                fontSize: FontSize(18),
                                                fontWeight: FontWeight.bold,
                                                margin: Margins.only(bottom: 16),
                                                color: textPrimaryColor,
                                                fontFamily: 'Poppins',
                                              ),
                                              'ul': Style(
                                                margin: Margins.only(bottom: 16),
                                              ),
                                              'ol': Style(
                                                margin: Margins.only(bottom: 16),
                                              ),
                                              'li': Style(
                                                margin: Margins.only(bottom: 8),
                                              ),
                                            },
                                            onLinkTap: (url, _, __) {
                                              if (url != null) {
                                                _launchUrl(url);
                                              }
                                            },
                                          ),
                                          if (_job!.description.contains('<img') ?? false)
                                            ..._extractImages(_job!.description).map((imageUrl) => Padding(
                                              padding: const EdgeInsets.only(bottom: 16),
                                              child: GestureDetector(
                                                onTap: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) => ZoomableImage(
                                                        imageUrl: imageUrl,
                                                        title: 'View Job Image',
                                                      ),
                                                    ),
                                                  );
                                                },
                                                child: Stack(
                                                  children: [
                                                    ClipRRect(
                                                      borderRadius: BorderRadius.circular(8),
                                                      child: Image.network(
                                                        imageUrl,
                                                        width: MediaQuery.of(context).size.width - 32,
                                                        height: 200,
                                                        fit: BoxFit.cover,
                                                        loadingBuilder: (context, child, loadingProgress) {
                                                          if (loadingProgress == null) return child;
                                                          return Container(
                                                            width: MediaQuery.of(context).size.width - 32,
                                                            height: 200,
                                                            color: Colors.grey[200],
                                                            child: const LoadingIndicator(size: 30),
                                                          );
                                                        },
                                                        errorBuilder: (context, error, stackTrace) {
                                                          return Container(
                                                            width: MediaQuery.of(context).size.width - 32,
                                                            height: 200,
                                                            decoration: BoxDecoration(
                                                              color: Colors.grey[200],
                                                              borderRadius: BorderRadius.circular(8),
                                                            ),
                                                            child: Column(
                                                              mainAxisAlignment: MainAxisAlignment.center,
                                                              children: [
                                                                Icon(Icons.broken_image, size: 48, color: Colors.grey[400]),
                                                                const SizedBox(height: 8),
                                                                Text(
                                                                  'Failed to load image',
                                                                  style: TextStyle(
                                                                    color: Colors.grey[600],
                                                                    fontSize: 14,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                    Positioned(
                                                      bottom: 8,
                                                      right: 8,
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                        decoration: BoxDecoration(
                                                          color: Colors.black.withOpacity(0.7),
                                                          borderRadius: BorderRadius.circular(16),
                                                        ),
                                                        child: const Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            Icon(
                                                              Icons.zoom_in,
                                                              color: Colors.white,
                                                              size: 16,
                                                            ),
                                                            SizedBox(width: 4),
                                                            Text(
                                                              'View Image',
                                                              style: TextStyle(
                                                                color: Colors.white,
                                                                fontSize: 12,
                                                                fontWeight: FontWeight.w500,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            )),
                                          // Native Ad after description
                                          // const SizedBox(height: 16),
                                          // const NativeAdWidget(),
                                        ],
                                      ),
                                    ),
                                    // Skills
                                    if (_job!.skills.isNotEmpty)
                                      _buildSection(
                                        'Required Skills',
                                        Wrap(
                                          spacing: 0,
                                          runSpacing: 0,
                                          children: _job!.skills.map((skill) => buildPill(skill)).toList(),
                                        ),
                                      ),
                                    // Tags
                                    if (_job!.tags.isNotEmpty) ...[
                                      const SizedBox(height: 16),
                                      Text(
                                        'Tags',
                                        style: unifiedHeaderStyle.copyWith(fontSize: 18, color: primaryColor),
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 0,
                                        runSpacing: 0,
                                        children: _job!.tags.split(',').map((tag) {
                                          final trimmedTag = tag.trim();
                                          if (trimmedTag.isEmpty) return const SizedBox.shrink();
                                          return buildPill(trimmedTag, bgColor: activeTabColor, borderColor: activeTabColor.withOpacity(0.7), textColor: primaryColor, fontSize: 13);
                                        }).toList(),
                                      ),
                                    ],
                                    const SizedBox(height: 32),
                                    // Apply Button
                                    Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: primaryColor.withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        onPressed: _showApplicationForm,
                                        style: unifiedButtonStyle,
                                        child: const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.send, size: 20),
                                            SizedBox(width: 8),
                                            Text(
                                              'Apply Now',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
          bottomNavigationBar: BannerAdWidget(
            collapsible: true,
            collapsiblePlacement: 'bottom',
          ),
        ),
      ),
    );
  }

  List<String> _extractImages(String html) {
    final List<String> images = [];
    final RegExp imgRegex = RegExp(r'<img[^>]+src="([^">]+)"');
    final matches = imgRegex.allMatches(html);
    
    for (final match in matches) {
      if (match.groupCount >= 1) {
        final String? src = match.group(1);
        if (src != null) {
          images.add(src);
        }
      }
    }
    
    return images;
  }


}

// Mock Apply Form Widget
class _MockApplyForm extends StatefulWidget {
  final VoidCallback? onApplicationSubmitted;
  const _MockApplyForm({super.key, this.onApplicationSubmitted});

  @override
  State<_MockApplyForm> createState() => _MockApplyFormState();
}

class _MockApplyFormState extends State<_MockApplyForm> with SingleTickerProviderStateMixin {
  bool _isSubmitting = false;
  bool _showSuccess = false;
  late AnimationController _animationController;
  
  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  final _resumeUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    _resumeUrlController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return 'Resume URL is required';
    }
    final urlRegex = RegExp(
      r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$',
      caseSensitive: false,
    );
    if (!urlRegex.hasMatch(value)) {
      return 'Please enter a valid URL';
    }
    return null;
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 1200));
    
    // Increment positive action for job application
    await ReviewService().incrementPositiveAction();
    
    setState(() {
      _isSubmitting = false;
      _showSuccess = true;
    });
    
    _animationController.forward();
    await Future.delayed(const Duration(milliseconds: 1200));
    
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Application submitted successfully!'),
          backgroundColor: primaryColor,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      // Show rewarded ad after successful submission
      RewardedAdManager.showAd(
        onUserEarnedReward: (ad, reward) {
          if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('🎉 You earned ${reward.amount} ${reward.type} for successfully applying to this job!'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          }
        },
        onAdClosed: () {
          Logger.info('JobDetailsPage: Application success rewarded ad closed');
        },
        onAdFailedToShow: () {
          Logger.info('JobDetailsPage: Application success rewarded ad failed to show');
        },
      );
      // Show rewarded ad dialog after successful submission
      if (widget.onApplicationSubmitted != null) {
        widget.onApplicationSubmitted!();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use design system colors
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _showSuccess
            ? Center(
                key: const ValueKey('success'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ScaleTransition(
                        scale: CurvedAnimation(
                          parent: _animationController,
                          curve: Curves.elasticOut,
                        ),
                        child: Icon(Icons.check_circle, color: primaryColor, size: 72),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Submitted Successfully!',
                        style: unifiedHeaderStyle.copyWith(fontSize: 22, color: primaryColor),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your application has been sent. We will contact you if you are shortlisted.',
                        style: unifiedBodyStyle.copyWith(fontSize: 15, color: textSecondaryColor),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            : AbsorbPointer(
                absorbing: _isSubmitting,
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Text(
                        'Apply for this Job',
                        style: unifiedHeaderStyle.copyWith(fontSize: 20, color: primaryColor),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: unifiedInputDecoration.copyWith(
                          labelText: 'Full Name *',
                          hintText: 'Enter your full name',
                        ),
                        style: unifiedBodyStyle,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: unifiedInputDecoration.copyWith(
                          labelText: 'Email *',
                          hintText: 'Enter your email address',
                        ),
                        style: unifiedBodyStyle,
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _messageController,
                        decoration: unifiedInputDecoration.copyWith(
                          labelText: 'Message *',
                          hintText: 'Tell us why you\'re a good fit for this role',
                        ),
                        style: unifiedBodyStyle,
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Message is required';
                          }
                          if (value.length < 50) {
                            return 'Please write at least 50 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _resumeUrlController,
                        decoration: unifiedInputDecoration.copyWith(
                          labelText: 'Resume URL *',
                          hintText: 'Enter the URL to your resume (e.g., LinkedIn, personal website)',
                          prefixIcon: const Icon(Icons.link, color: primaryColor),
                        ),
                        style: unifiedBodyStyle,
                        keyboardType: TextInputType.url,
                        validator: _validateUrl,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submit,
                          style: unifiedButtonStyle,
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text(
                                  'Submit Application',
                                  style: TextStyle(fontSize: 16, fontFamily: 'Poppins'),
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '* Required fields',
                        style: unifiedBodyStyle.copyWith(fontSize: 13, color: inactiveTabColor),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class ZoomableImage extends StatelessWidget {
  final String imageUrl;
  final String? title;

  const ZoomableImage({
    super.key,
    required this.imageUrl,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: title != null
            ? Text(
                title!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Poppins',
                ),
              )
            : null,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          PhotoView(
            imageProvider: NetworkImage(imageUrl),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            loadingBuilder: (context, event) => const Center(
              child: LoadingIndicator(size: 30),
            ),
            errorBuilder: (context, error, stackTrace) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, size: 48, color: Colors.grey),
                  const SizedBox(height: 8),
                  Text(
                    'Failed to load image',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (title != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  title!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'Poppins',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
} 