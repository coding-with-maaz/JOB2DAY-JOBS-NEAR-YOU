import 'package:flutter/material.dart';
import '../widgets/google_ads/dynamic_ad_config.dart';
import '../widgets/google_ads/ad_refresh_service.dart';
import '../widgets/google_ads/rewarded_ads/rewarded_ad_manager.dart';
import '../widgets/google_ads/rewarded_ads/rewarded_interstitial_ad_manager.dart';
import '../utils/logger.dart';
import '../services/first_launch_service.dart';
// import '../widgets/google_ads/app_open_ads/app_open_ad_manager.dart';

class AdsTestPage extends StatefulWidget {
  const AdsTestPage({super.key});

  @override
  State<AdsTestPage> createState() => _AdsTestPageState();
}

class _AdsTestPageState extends State<AdsTestPage> {
  Map<String, dynamic> _status = {};
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    setState(() => _busy = true);
    try {
      final status = AdRefreshService.instance.getConfigurationStatus();
      setState(() => _status = status);
    } catch (e) {
      Logger.error('AdsTestPage: Failed to get status: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get status: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forceRefreshConfig() async {
    setState(() => _busy = true);
    try {
      await AdRefreshService.instance.forceRefreshConfig();
      await _refreshStatus();
    } catch (e) {
      Logger.error('AdsTestPage: Failed to refresh config: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to refresh config: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _preloadRewarded() async {
    await RewardedAdManager.loadAd();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preloaded Rewarded Ad (if enabled & configured)')),
    );
  }

  Future<void> _preloadRewardedInterstitial() async {
    await RewardedInterstitialAdManager.preloadAd();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preloaded Rewarded Interstitial (if enabled & configured)')),
    );
  }

  Future<void> _showRewarded() async {
    final ok = await RewardedAdManager.showAd(
      onUserEarnedReward: (ad, reward) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reward earned: ${reward.amount} ${reward.type}')),
        );
      },
      onAdClosed: () {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rewarded closed')),
        );
      },
      onAdFailedToShow: () {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to show Rewarded')),
        );
      },
    );
    Logger.info('AdsTestPage: Show rewarded result: $ok');
  }

  Future<void> _showRewardedInterstitial() async {
    final ok = await RewardedInterstitialAdManager.showAd(
      onUserEarnedReward: (ad) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reward (interstitial) earned')),
        );
      },
      onAdClosed: () {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rewarded Interstitial closed')),
        );
      },
      onAdFailedToShow: () {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to show Rewarded Interstitial')),
        );
      },
    );
    Logger.info('AdsTestPage: Show rewarded interstitial result: $ok');
  }

  Widget _buildStatusTile(String title, String value) {
    return ListTile(
      dense: true,
      title: Text(title),
      trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildTestSection() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Test Controls',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await FirstLaunchService.resetForTesting();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('First launch status reset! Restart app to test.')),
                  );
                }
              },
              child: const Text('Reset First Launch Status'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                final status = await FirstLaunchService.instance.getFirstLaunchStatus();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('First Launch: ${status['is_first_launch']}, Ad Shown: ${status['first_launch_ad_shown']}'),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              },
              child: const Text('Check First Launch Status'),
            ),
            const SizedBox(height: 8),
            // ElevatedButton(
            //   onPressed: () {
            //     AppOpenAdManager.instance.showOnFirstOpen();
            //   },
            //   child: const Text('Test App Open Ad'),
            // ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ads = _status['ads'] as Map<String, dynamic>?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ads Test'),
        actions: [
          IconButton(
            onPressed: _busy ? null : _refreshStatus,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Configuration', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildStatusTile('Environment', (_status['environment'] ?? '').toString()),
                  _buildStatusTile('Available', (_status['isAvailable'] ?? false).toString()),
                  _buildStatusTile('API OK', (_status['apiConnectionSuccessful'] ?? false).toString()),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _busy ? null : _forceRefreshConfig,
                    icon: const Icon(Icons.cloud_sync),
                    label: const Text('Force Refresh Config'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Rewarded', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildStatusTile('Enabled', (ads?['rewarded']?['enabled'] ?? false).toString()),
                  _buildStatusTile('Unit ID', (ads?['rewarded']?['adUnitId'] ?? '').toString()),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: _preloadRewarded,
                        child: const Text('Preload'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _showRewarded,
                        child: const Text('Show'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Rewarded Interstitial', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildStatusTile('Enabled', (ads?['rewardedInterstitial']?['enabled'] ?? false).toString()),
                  _buildStatusTile('Unit ID', (ads?['rewardedInterstitial']?['adUnitId'] ?? '').toString()),
                  _buildStatusTile('Min Interval', (ads?['rewardedInterstitial']?['minInterval'] ?? '').toString()),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: _preloadRewardedInterstitial,
                        child: const Text('Preload'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _showRewardedInterstitial,
                        child: const Text('Show'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Dynamic Debug: ${DynamicAdConfig.getDebugInfo()}'),
          _buildTestSection(),
        ],
      ),
    );
  }
} 