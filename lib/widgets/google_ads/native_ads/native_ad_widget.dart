import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' show NativeTemplateStyle, TemplateType, NativeTemplateTextStyle, NativeTemplateFontStyle;
import '../../../utils/logger.dart';
import '../dynamic_ad_config.dart';

class NativeAdWidget extends StatefulWidget {
  final String? adUnitId;
  final VoidCallback? onAdLoaded;
  final VoidCallback? onAdFailedToLoad;
  final VoidCallback? onAdOpened;
  final VoidCallback? onAdClosed;
  final VoidCallback? onAdImpression;

  const NativeAdWidget({
    Key? key,
    this.adUnitId,
    this.onAdLoaded,
    this.onAdFailedToLoad,
    this.onAdOpened,
    this.onAdClosed,
    this.onAdImpression,
  }) : super(key: key);

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  Future<void> _loadAd() async {
    // Check if dynamic config is available and native ads are enabled
    if (!DynamicAdConfig.isAvailable) {
      Logger.info('NativeAdWidget: Dynamic config not available, not showing ad');
      return;
    }

    if (!DynamicAdConfig.isEnabled('native')) {
      Logger.info('NativeAdWidget: Native ads disabled in dynamic config');
      return;
    }

    final dynamicAdUnitId = DynamicAdConfig.getAdUnitId('native');
    if (dynamicAdUnitId.isEmpty) {
      Logger.info('NativeAdWidget: No dynamic native ad unit ID available');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      Logger.info('NativeAdWidget: Loading native ad with dynamic ID: $dynamicAdUnitId');
      _nativeAd = NativeAd(
        adUnitId: dynamicAdUnitId,
        factoryId: 'listTile',
        request: const AdRequest(),
        nativeTemplateStyle: NativeTemplateStyle(
          templateType: TemplateType.medium,
          // Example style customization (edit as needed):
          mainBackgroundColor: Colors.white,
          cornerRadius: 12.0,
          callToActionTextStyle: NativeTemplateTextStyle(
            textColor: Colors.white,
            backgroundColor: Colors.deepPurple,
            style: NativeTemplateFontStyle.bold,
            size: 16.0,
          ),
          primaryTextStyle: NativeTemplateTextStyle(
            textColor: Colors.black,
            backgroundColor: Colors.transparent,
            style: NativeTemplateFontStyle.normal,
            size: 16.0,
          ),
          secondaryTextStyle: NativeTemplateTextStyle(
            textColor: Colors.grey,
            backgroundColor: Colors.transparent,
            style: NativeTemplateFontStyle.italic,
            size: 14.0,
          ),
        ),
        listener: NativeAdListener(
          onAdLoaded: (ad) {
            Logger.info('NativeAdWidget: Ad loaded successfully');
            setState(() {
              _isLoaded = true;
              _isLoading = false;
            });
            widget.onAdLoaded?.call();
          },
          onAdFailedToLoad: (ad, error) {
            Logger.error('NativeAdWidget: Ad failed to load: ${error.message}');
            setState(() {
              _isLoaded = false;
              _isLoading = false;
              _errorMessage = error.message;
            });
            widget.onAdFailedToLoad?.call();
            ad.dispose();
          },
          onAdOpened: (ad) {
            Logger.info('NativeAdWidget: Ad opened');
            widget.onAdOpened?.call();
          },
          onAdClosed: (ad) {
            Logger.info('NativeAdWidget: Ad closed');
            widget.onAdClosed?.call();
          },
          onAdImpression: (ad) {
            Logger.info('NativeAdWidget: Ad impression recorded');
            widget.onAdImpression?.call();
          },
        ),
      );
      await _nativeAd!.load();
    } catch (e) {
      Logger.error('NativeAdWidget: Error loading ad: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      widget.onAdFailedToLoad?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Don't show anything if dynamic config is not available
    if (!DynamicAdConfig.isAvailable) {
      Logger.info('NativeAdWidget: Not rendering - dynamic config not available');
      return const SizedBox.shrink();
    }

    // Don't show anything if native ads are disabled
    if (!DynamicAdConfig.isEnabled('native')) {
      Logger.info('NativeAdWidget: Not rendering - native ads disabled');
      return const SizedBox.shrink();
    }

    // Don't show anything if no ad unit ID is available
    if (DynamicAdConfig.getAdUnitId('native').isEmpty) {
      Logger.info('NativeAdWidget: Not rendering - no ad unit ID available');
      return const SizedBox.shrink();
    }

    if (_isLoading) {
      return ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 320,
          minHeight: 320,
          maxWidth: 400,
          maxHeight: 400,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      Logger.info('NativeAdWidget: Not rendering due to error: $_errorMessage');
      return const SizedBox.shrink();
    }

    if (!_isLoaded || _nativeAd == null) {
      Logger.info('NativeAdWidget: Not rendering - ad not loaded');
      return const SizedBox.shrink();
    }

    Logger.info('NativeAdWidget: Rendering native ad');
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: 320,
        minHeight: 320,
        maxWidth: 400,
        maxHeight: 400,
      ),
      child: AdWidget(ad: _nativeAd!),
    );
  }
} 