import 'package:flutter/material.dart';
import 'dynamic_ad_config.dart';
import 'banner_ads/banner_ad_widget.dart';
import 'native_ads/native_ad_widget.dart';

/// Dynamic Ad Widget that automatically shows the appropriate ad type
/// based on remote configuration
class DynamicAdWidget extends StatelessWidget {
  final String? position; // 'top', 'bottom', 'job_list', etc.
  final String? adType; // Force specific ad type if needed
  final Map<String, dynamic>? customConfig;
  
  const DynamicAdWidget({
    Key? key,
    this.position,
    this.adType,
    this.customConfig,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // If specific ad type is requested, show that
    if (adType != null) {
      return _buildAdByType(adType!);
    }

    // Determine ad type based on position
    final adTypeToShow = _determineAdType();
    
    return _buildAdByType(adTypeToShow);
  }

  String _determineAdType() {
    if (position == null) return 'banner';
    
    switch (position!.toLowerCase()) {
      case 'top':
      case 'bottom':
        return 'banner';
      case 'job_list':
      case 'company_list':
      case 'category_list':
        return 'native';
      case 'custom':
        return 'custom';
      default:
        return 'banner';
    }
  }

  Widget _buildAdByType(String adType) {
    switch (adType) {
      case 'banner':
        if (DynamicAdConfig.isEnabled('banner')) {
          return const BannerAdWidget();
        }
        break;
        
      case 'native':
        if (DynamicAdConfig.isEnabled('native')) {
          return const NativeAdWidget();
        }
        break;
        
      case 'custom':
        if (DynamicAdConfig.isEnabled('custom')) {
          return _buildCustomAd();
        }
        break;
        
      default:
        // Fallback to banner
        if (DynamicAdConfig.isEnabled('banner')) {
          return const BannerAdWidget();
        }
    }
    
    // Return empty widget if no ads are enabled
    return const SizedBox.shrink();
  }

  Widget _buildCustomAd() {
    final customConfig = DynamicAdConfig.getAdConfig('custom');
    if (customConfig == null) return const SizedBox.shrink();
    
    // Implement custom ad logic based on configuration
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: const Row(
        children: [
          Icon(Icons.ads_click, color: Colors.blue),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Custom Advertisement',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

/// Smart Ad Widget that shows ads based on context and configuration
class SmartAdWidget extends StatelessWidget {
  final String context; // 'home', 'job_list', 'job_detail', 'category', etc.
  final Map<String, dynamic>? options;
  
  const SmartAdWidget({
    Key? key,
    required this.context,
    this.options,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final adConfig = _getAdConfigForContext();
    
    if (adConfig == null) return const SizedBox.shrink();
    
    return DynamicAdWidget(
      position: adConfig['position'],
      adType: adConfig['type'],
      customConfig: adConfig['customConfig'],
    );
  }

  Map<String, dynamic>? _getAdConfigForContext() {
    switch (context.toLowerCase()) {
      case 'home':
        return {
          'position': 'bottom',
          'type': 'banner',
        };
        
      case 'job_list':
        if (DynamicAdConfig.isEnabled('native')) {
          return {
            'position': 'job_list',
            'type': 'native',
          };
        }
        break;
        
      case 'job_detail':
        if (DynamicAdConfig.isEnabled('banner')) {
          return {
            'position': 'bottom',
            'type': 'banner',
          };
        }
        break;
        
      case 'category':
        if (DynamicAdConfig.isEnabled('native')) {
          return {
            'position': 'category_list',
            'type': 'native',
          };
        }
        break;
        
      case 'search_results':
        if (DynamicAdConfig.isEnabled('banner')) {
          return {
            'position': 'bottom',
            'type': 'banner',
          };
        }
        break;
    }
    
    // Default fallback
    if (DynamicAdConfig.isEnabled('banner')) {
      return {
        'position': 'bottom',
        'type': 'banner',
      };
    }
    
    return null;
  }
} 