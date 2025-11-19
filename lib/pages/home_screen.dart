import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'search_results_page.dart';
import 'resume_maker_page.dart';
import 'settings_page.dart';
import 'today_jobs_page.dart';
import 'categories_page.dart';
import 'countries_page.dart';
import 'jobs_page.dart';
import '../widgets/google_ads/banner_ads/banner_ad_widget.dart';
import '../widgets/network_aware_widget.dart';
import '../widgets/new_feature_badge.dart';
import '../widgets/google_ads/interstitial_ads/interstitial_ad_manager.dart';
import '../utils/logger.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/styled_exit_dialog.dart';
import '../services/review_service.dart';
import '../services/navigation_visit_service.dart';
import 'ads_test_page.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _isLoading = false;

  Future<void> requestReview() async {
    final _inAppReview = InAppReview.instance;
    if (await _inAppReview.isAvailable()) {
      _inAppReview.requestReview();
    } else {
      // Fallback: open the Play Store page directly
      _inAppReview.openStoreListing(
        appStoreId: 'com.maazkhan07.jobsinquwait', // JOB2DAY app ID
      );
    }
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('hasRated', true);
  }

  Future<bool> _onBackPressed() async {
    // Check if we should show review prompt using the service
    final shouldShow = await ReviewService().shouldShowReviewPrompt();
    Logger.info('HomeScreen: Should show review prompt: $shouldShow');
    
    if (!shouldShow) {
      Logger.info('HomeScreen: Not showing review prompt, exiting directly');
      return true;
    }
    
    // Mark that we showed the prompt
    await ReviewService().markReviewPromptShown();
    Logger.info('HomeScreen: Showing styled exit dialog');
    
    final result = await showStyledExitDialog(context);
    Logger.info('HomeScreen: Exit dialog result: $result');
    return result ?? false;
  }

  @override
  void initState() {
    super.initState();
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool showNewBadge = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.8),
            color.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              if (showNewBadge)
                Positioned(
                  top: 8,
                  right: 8,
                  child: NewFeatureBadge(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToAllJobs() async {
    // Track visit and show ad if conditions are met (after 3 visits)
    await NavigationVisitService().trackVisitAndShowAd('AllJobs');
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SearchResultsPage(initialQuery: ''),
      ),
    );
  }

  void _navigateToAllCategories() async {
    // Track visit and show ad if conditions are met (after 3 visits)
    await NavigationVisitService().trackVisitAndShowAd('Categories');
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CategoriesPage(),
      ),
    );
  }

  void _navigateToAllCountries() async {
    // Track visit and show ad if conditions are met (after 3 visits)
    await NavigationVisitService().trackVisitAndShowAd('Countries');
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CountriesPage(),
      ),
    );
  }

  void _navigateToTodayJobs() async {
    // Track visit and show ad if conditions are met (after 3 visits)
    await NavigationVisitService().trackVisitAndShowAd('TodayJobs');
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TodayJobsPage(),
      ),
    );
  }

    void _navigateToResumeMaker() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ResumeMakerPage(),
      ),
    );
  }

    void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SettingsPage(),
      ),
    );
  }

  void _navigateToJobsPage() async {
    // Track visit and show ad if conditions are met (after 3 visits)
    await NavigationVisitService().trackVisitAndShowAd('JobsPage');
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const JobsPage(),
      ),
    );
  }


  Widget _buildSectionHeader(String title, String subtitle, VoidCallback onViewAll) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF3C3C43),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onViewAll,
            child: const Text(
              'View All',
              style: TextStyle(
                color: Color(0xFF6A11CB),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: NetworkAwareWidget(
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
          child: Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF6A11CB),
                    Color(0xFF2575FC),
                    Color(0xFF6D5BFF),
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'JOB2DAY',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          Row(
                            children: [
                              // Temporary test button for review dialog
                              IconButton(
                                icon: const Icon(
                                  Icons.star,
                                  color: Colors.white,
                                ),
                                onPressed: () async {
                                  // Check current review stats
                                  final stats = await ReviewService().getReviewStats();
                                  Logger.info('Test: Review stats: $stats');
                                  
                                  // Force show review prompt for testing
                                  await ReviewService().forceShowReviewPrompt();
                                  
                                  // Check stats again
                                  final newStats = await ReviewService().getReviewStats();
                                  Logger.info('Test: New review stats: $newStats');
                                  
                                  if (mounted) {
                                    final result = await showStyledExitDialog(context);
                                    Logger.info('Test: Exit dialog result: $result');
                                  }
                                },
                              ),
                              // Ads test page button
                              // IconButton(
                              //   icon: const Icon(
                              //     Icons.bug_report,
                              //     color: Colors.white,
                              //   ),
                              //   onPressed: () {
                              //     Navigator.push(
                              //       context,
                              //       MaterialPageRoute(builder: (_) => const AdsTestPage()),
                              //     );
                              //   },
                              // ),
                              IconButton(
                                icon: const Icon(
                                  Icons.settings,
                                  color: Colors.white,
                                ),
                                onPressed: _navigateToSettings,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Main Content
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Action Cards Grid
                              GridView.count(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 1.2,
                                children: [
                                  _buildActionCard(
                                    icon: Icons.search,
                                    title: 'Find Jobs',
                                    subtitle: 'Browse available positions',
                                    color: const Color(0xFF6A11CB),
                                    onTap: _navigateToAllJobs,
                                  ),
                                  _buildActionCard(
                                    icon: Icons.today,
                                    title: 'Today Jobs',
                                    subtitle: 'Latest job postings',
                                    color: const Color(0xFFFF6B35),
                                    onTap: _navigateToTodayJobs,
                                    showNewBadge: true,
                                  ),
                                  _buildActionCard(
                                    icon: Icons.public,
                                    title: 'Countries',
                                    subtitle: 'Jobs by location',
                                    color: const Color(0xFF6D5BFF),
                                    onTap: _navigateToAllCountries,
                                  ),
                                  _buildActionCard(
                                    icon: Icons.description,
                                    title: 'Resume Maker',
                                    subtitle: 'Create your resume',
                                    color: const Color(0xFF4CAF50),
                                    onTap: _navigateToResumeMaker,
                                    showNewBadge: true,
                                  ),
                                  // _buildActionCard(
                                  //   icon: Icons.category,
                                  //   title: 'Categories',
                                  //   subtitle: 'Explore by job type',
                                  //   color: const Color(0xFF2575FC),
                                  //   onTap: _navigateToAllCategories,
                                  // ),
                                  _buildActionCard(
                                    icon: Icons.work,
                                    title: 'All Jobs',
                                    subtitle: 'Browse all job listings',
                                    color: const Color(0xFF6A11CB),
                                    onTap: _navigateToJobsPage,
                                  ),

                                ],
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                BannerAdWidget(
                  collapsible: true,
                  collapsiblePlacement: 'bottom',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}