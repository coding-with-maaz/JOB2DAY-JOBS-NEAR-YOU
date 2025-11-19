import 'package:flutter/material.dart';
import 'dynamic_ad_widget.dart';
import 'ad_refresh_service.dart';
import 'rewarded_ads/rewarded_ad_manager.dart';
import 'interstitial_ads/interstitial_ad_manager.dart';
import '../../utils/logger.dart';

/// Example usage of dynamic ads in different scenarios
class DynamicAdsUsageExample {
  
  /// Example 1: Using SmartAdWidget for automatic ad selection
  static Widget buildHomePageWithAds() {
    return Scaffold(
      body: Column(
        children: [
          // Main content
          Expanded(
            child: ListView(
              children: [
                // Your app content here
                const Text('Home Page Content'),
              ],
            ),
          ),
          // Smart ad widget automatically chooses the best ad type
          const SmartAdWidget(context: 'home'),
        ],
      ),
    );
  }

  /// Example 2: Using DynamicAdWidget with specific configuration
  static Widget buildJobListWithNativeAds() {
    return Scaffold(
      body: ListView.builder(
        itemCount: 20, // Your job list
        itemBuilder: (context, index) {
          // Show native ad every 5th item
          if (index > 0 && index % 5 == 0) {
            return const DynamicAdWidget(
              position: 'job_list',
              adType: 'native',
            );
          }
          
          // Your job item widget
          return const Card(
            child: ListTile(
              title: Text('Job Title'),
              subtitle: Text('Job Description'),
            ),
          );
        },
      ),
    );
  }

  /// Example 3: Using banner ads with specific position
  static Widget buildPageWithTopBanner() {
    return Scaffold(
      body: Column(
        children: [
          // Top banner ad
          const DynamicAdWidget(
            position: 'top',
            adType: 'banner',
          ),
          // Main content
          Expanded(
            child: const Center(
              child: Text('Page Content'),
            ),
          ),
        ],
      ),
    );
  }

  /// Example 4: Showing interstitial ads on page navigation
  static Future<void> navigateToJobDetail(BuildContext context, String jobId) async {
    // Show interstitial ad before navigation
    await AdRefreshService.instance.showInterstitialOnPage('JobView');
    
    // Navigate to job detail page
    Navigator.pushNamed(context, '/job-details', arguments: {'jobId': jobId});
  }

  /// Example 5: Using rewarded ads
  static Future<void> showRewardedAdForPremiumJobs() async {
    final success = await RewardedAdManager.showAd(
      onUserEarnedReward: (ad, reward) {
        // Handle reward - give user premium job access
        Logger.info('User earned premium job access! Reward:  [38;5;2m${reward.amount} ${reward.type} [0m');
        // Update user's premium status
        // _updateUserPremiumStatus();
      },
      onAdClosed: () {
        Logger.info('Rewarded ad was closed');
      },
      onAdFailedToShow: () {
        Logger.info('Rewarded ad failed to show');
      },
    );
    
    if (!success) {
      Logger.info('Rewarded ad not available');
    }
  }

  /// Example 6: Checking ad configuration status
  static void logAdConfigurationStatus() {
    final status = AdRefreshService.instance.getConfigurationStatus();
    Logger.info('Ad Configuration Status: $status');
  }

  /// Example 7: Force refresh ad configuration
  static Future<void> refreshAdConfiguration() async {
    await AdRefreshService.instance.forceRefreshConfig();
    Logger.info('Ad configuration refreshed');
  }

  /// Example 8: Custom ad widget with fallback
  static Widget buildCustomAdWithFallback() {
    return const DynamicAdWidget(
      position: 'custom',
      adType: 'custom',
      customConfig: {
        'backgroundColor': '#f0f0f0',
        'textColor': '#333333',
        'showIcon': true,
      },
    );
  }

  /// Example 9: Conditional ad display based on user preferences
  static Widget buildConditionalAdWidget({required bool userPrefersAds}) {
    if (!userPrefersAds) {
      return const SizedBox.shrink();
    }
    
    return const SmartAdWidget(context: 'home');
  }

  /// Example 10: Ad placement in different contexts
  static Widget buildContextualAds() {
    return Scaffold(
      appBar: AppBar(title: const Text('Contextual Ads')),
      body: Column(
        children: [
          // Search results context
          const SmartAdWidget(context: 'search_results'),
          
          Expanded(
            child: ListView(
              children: [
                // Category context
                const SmartAdWidget(context: 'category'),
                
                // Job list context
                const SmartAdWidget(context: 'job_list'),
              ],
            ),
          ),
          
          // Bottom banner
          const SmartAdWidget(context: 'home'),
        ],
      ),
    );
  }
}

/// Example widget showing how to integrate ads in a real page
class ExampleJobDetailPage extends StatefulWidget {
  final String jobId;
  
  const ExampleJobDetailPage({super.key, required this.jobId});

  @override
  State<ExampleJobDetailPage> createState() => _ExampleJobDetailPageState();
}

class _ExampleJobDetailPageState extends State<ExampleJobDetailPage> {
  @override
  void initState() {
    super.initState();
    // Show interstitial ad when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await AdRefreshService.instance.showInterstitialOnPage('JobView');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Job Details')),
      body: Column(
        children: [
          // Job content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const Text('Job Title'),
                  const Text('Job Description'),
                  // More job content...
                ],
              ),
            ),
          ),
          // Bottom banner ad
          const SmartAdWidget(context: 'job_detail'),
        ],
      ),
    );
  }
} 