import 'package:flutter/material.dart';
import 'dynamic_ad_config.dart';
import 'ad_config.dart';

/// Debug widget to show current ad configuration status
class AdConfigDebugWidget extends StatefulWidget {
  const AdConfigDebugWidget({Key? key}) : super(key: key);

  @override
  State<AdConfigDebugWidget> createState() => _AdConfigDebugWidgetState();
}

class _AdConfigDebugWidgetState extends State<AdConfigDebugWidget> {
  Map<String, dynamic> _configStatus = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadConfigStatus();
  }

  Future<void> _loadConfigStatus() async {
    setState(() {
      _isLoading = true;
    });

    // Get configuration status
    final status = {
      'dynamicConfig': {
        'isAvailable': DynamicAdConfig.isAvailable,
        'environment': DynamicAdConfig.environment,
        'lastFetch': DynamicAdConfig.lastFetch?.toIso8601String(),
        'isTestMode': DynamicAdConfig.isTestMode,
        'isDebugMode': DynamicAdConfig.isDebugMode,
      },
      'adConfig': {
        'isProduction': AdConfig.isProduction,
        'isTestMode': AdConfig.isTestMode,
        'environmentInfo': AdConfig.environmentInfo,
        'isDynamicConfigAvailable': AdConfig.isDynamicConfigAvailable,
        'configurationSource': AdConfig.getConfigurationSource(),
      },
      'adUnitIds': {
        'banner': {
          'dynamic': DynamicAdConfig.getAdUnitId('banner'),
          'static': AdConfig.bannerAdUnitId,
          'enabled': DynamicAdConfig.isEnabled('banner'),
        },
        'interstitial': {
          'dynamic': DynamicAdConfig.getAdUnitId('interstitial'),
          'static': AdConfig.interstitialAdUnitId,
          'enabled': DynamicAdConfig.isEnabled('interstitial'),
        },
        'native': {
          'dynamic': DynamicAdConfig.getAdUnitId('native'),
          'static': AdConfig.nativeAdUnitId,
          'enabled': DynamicAdConfig.isEnabled('native'),
        },
        'rewarded': {
          'dynamic': DynamicAdConfig.getAdUnitId('rewarded'),
          'static': AdConfig.rewardedAdUnitId,
          'enabled': DynamicAdConfig.isEnabled('rewarded'),
        },
      },
      'fullConfig': DynamicAdConfig.config,
    };

    setState(() {
      _configStatus = status;
      _isLoading = false;
    });
  }

  Future<void> _refreshConfig() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await DynamicAdConfig.refresh();
      await _loadConfigStatus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuration refreshed successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to refresh: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ad Configuration Debug'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshConfig,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection('Dynamic Configuration', _configStatus['dynamicConfig'] ?? {}),
                  const SizedBox(height: 16),
                  _buildSection('Static Configuration', _configStatus['adConfig'] ?? {}),
                  const SizedBox(height: 16),
                  _buildAdUnitIdsSection(),
                  const SizedBox(height: 16),
                  _buildFullConfigSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildSection(String title, Map<String, dynamic> data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...data.entries.map((entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(
                      '${entry.key}:',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${entry.value}',
                      style: TextStyle(
                        color: _getValueColor(entry.value),
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildAdUnitIdsSection() {
    final adUnitIds = _configStatus['adUnitIds'] ?? {};
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ad Unit IDs',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...adUnitIds.entries.map((adType) => _buildAdTypeCard(adType.key, adType.value)),
          ],
        ),
      ),
    );
  }

  Widget _buildAdTypeCard(String adType, Map<String, dynamic> data) {
    final isEnabled = data['enabled'] ?? false;
    final dynamicId = data['dynamic'] ?? '';
    final staticId = data['static'] ?? '';
    final isUsingDynamic = dynamicId.isNotEmpty;

    return Card(
      color: isEnabled ? Colors.green[50] : Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  adType.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isEnabled ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isEnabled ? 'ENABLED' : 'DISABLED',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isUsingDynamic ? Colors.blue : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isUsingDynamic ? 'DYNAMIC' : 'STATIC',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (isUsingDynamic) ...[
              Text('Dynamic ID: $dynamicId'),
              Text(
                'Static ID: $staticId',
                style: const TextStyle(color: Colors.grey),
              ),
            ] else ...[
              Text('Static ID: $staticId'),
              Text(
                'Dynamic ID: (empty)',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFullConfigSection() {
    final fullConfig = _configStatus['fullConfig'];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Full Configuration',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                fullConfig != null ? fullConfig.toString() : 'No configuration available',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getValueColor(dynamic value) {
    if (value == null) return Colors.grey;
    if (value is bool) return value ? Colors.green : Colors.red;
    if (value is String) {
      if (value.isEmpty) return Colors.orange;
      if (value.contains('test') || value.contains('TEST')) return Colors.blue;
      if (value.contains('production') || value.contains('PRODUCTION')) return Colors.green;
    }
    return Colors.black;
  }
} 