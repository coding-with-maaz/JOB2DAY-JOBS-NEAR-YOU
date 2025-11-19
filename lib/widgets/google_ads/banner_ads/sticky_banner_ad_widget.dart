import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../../utils/logger.dart';
import '../dynamic_ad_config.dart';

class StickyBannerAdWidget extends StatefulWidget {
  const StickyBannerAdWidget({Key? key}) : super(key: key);

  @override
  State<StickyBannerAdWidget> createState() => _StickyBannerAdWidgetState();
}

class _StickyBannerAdWidgetState extends State<StickyBannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadStickyBanner();
  }

  void _loadStickyBanner() async {
    // Check if dynamic config is available and banner ads are enabled
    if (!DynamicAdConfig.isAvailable) {
      Logger.info('StickyBannerAdWidget: Dynamic config not available, not showing ad');
      return;
    }

    if (!DynamicAdConfig.isEnabled('banner')) {
      Logger.info('StickyBannerAdWidget: Banner ads disabled in dynamic config');
      return;
    }

    final dynamicAdUnitId = DynamicAdConfig.getAdUnitId('banner');
    if (dynamicAdUnitId.isEmpty) {
      Logger.info('StickyBannerAdWidget: No dynamic banner ad unit ID available');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // For sticky bottom banner, we use a standard banner size
    final AdSize size = AdSize.banner;

    try {
      Logger.info('StickyBannerAdWidget: Loading sticky banner ad with dynamic ID: $dynamicAdUnitId');
      
      _bannerAd = BannerAd(
        size: size,
        adUnitId: dynamicAdUnitId,
        listener: BannerAdListener(
          onAdLoaded: (Ad ad) {
            Logger.info('StickyBannerAdWidget: Ad loaded successfully');
            setState(() {
              _isAdLoaded = true;
              _isLoading = false;
            });
          },
          onAdFailedToLoad: (Ad ad, LoadAdError error) {
            Logger.error('StickyBannerAdWidget: Ad failed to load: ${error.message}');
            setState(() {
              _isAdLoaded = false;
              _isLoading = false;
              _errorMessage = error.message;
            });
            ad.dispose();
          },
        ),
        request: const AdRequest(),
      )..load();
    } catch (e) {
      Logger.error('StickyBannerAdWidget: Error loading ad: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Don't show anything if dynamic config is not available
    if (!DynamicAdConfig.isAvailable) {
      Logger.info('StickyBannerAdWidget: Not rendering - dynamic config not available');
      return const SizedBox.shrink();
    }

    // Don't show anything if banner ads are disabled
    if (!DynamicAdConfig.isEnabled('banner')) {
      Logger.info('StickyBannerAdWidget: Not rendering - banner ads disabled');
      return const SizedBox.shrink();
    }

    // Don't show anything if no ad unit ID is available
    if (DynamicAdConfig.getAdUnitId('banner').isEmpty) {
      Logger.info('StickyBannerAdWidget: Not rendering - no ad unit ID available');
      return const SizedBox.shrink();
    }

    if (_isLoading) {
      return const SizedBox.shrink(); // Don't show loading indicator for sticky banner
    }

    if (_errorMessage != null) {
      Logger.info('StickyBannerAdWidget: Not rendering due to error: $_errorMessage');
      return const SizedBox.shrink();
    }

    if (_isAdLoaded && _bannerAd != null) {
      Logger.info('StickyBannerAdWidget: Rendering sticky banner ad');
      return Container(
        width: double.infinity,
        height: _bannerAd!.size.height.toDouble(),
        color: Colors.white,
        child: AdWidget(ad: _bannerAd!),
      );
    } else {
      Logger.info('StickyBannerAdWidget: Not rendering - ad not loaded');
      return const SizedBox.shrink();
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }
} 