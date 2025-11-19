# Dynamic Ads Management System

This system allows you to dynamically control ad settings in your Flutter app without requiring app updates. It fetches configuration from a remote API and provides fallback to local settings.

## Features

- **Remote Configuration**: Fetch ad settings from API
- **Caching**: Local cache with configurable expiry
- **Fallback**: Graceful fallback to local configuration
- **Multiple Ad Types**: Banner, Interstitial, Native, Rewarded, App Open ads
- **Smart Placement**: Context-aware ad placement
- **Session Management**: Track ad shows per session
- **Cooldown Periods**: Prevent ad spam
- **Automatic Refresh**: Periodic configuration updates

## Quick Start

### 1. Initialize the System

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize dynamic ad configuration
  await DynamicAdConfig.initialize();
  
  // Initialize MobileAds
  MobileAds.instance.initialize();
  
  // Initialize ad refresh service
  await AdRefreshService.instance.initialize();
  
  runApp(MyApp());
}
```

### 2. Use Smart Ad Widgets

   ```dart
// Automatic ad selection based on context
SmartAdWidget(context: 'home')

// Specific ad type and position
DynamicAdWidget(
  position: 'bottom',
  adType: 'banner',
)
```

### 3. Show Interstitial Ads

   ```dart
// Show on specific page types
AdRefreshService.instance.showInterstitialOnPage('JobView');

// Or use the manager directly
final manager = InterstitialAdManager();
manager.showAdOnPage('CategoryView');
```

## API Configuration

The system expects the following API endpoint structure:

```json
{
  "environment": "production",
  "banner": {
    "enabled": true,
    "adUnitId": "ca-app-pub-xxx/xxx",
    "position": "bottom",
    "refreshInterval": 60
  },
  "interstitial": {
    "enabled": true,
    "adUnitId": "ca-app-pub-xxx/xxx",
    "showOnJobView": true,
    "showOnCategoryView": false,
    "minInterval": 300
  },
  "native": {
    "enabled": true,
    "adUnitId": "ca-app-pub-xxx/xxx",
    "position": "job_list",
    "style": "default"
  },
  "rewarded": {
    "enabled": false,
    "adUnitId": "ca-app-pub-xxx/xxx",
    "rewardType": "premium_jobs",
    "rewardAmount": 1
  },
  "appOpen": {
    "enabled": true,
    "adUnitId": "ca-app-pub-xxx/xxx",
    "showOnResume": true,
    "maxShowsPerDay": 3
  },
  "globalSettings": {
    "testMode": false,
    "debugMode": false,
    "maxAdsPerSession": 10,
    "cooldownPeriod": 60
  }
}
```

## Widgets

### SmartAdWidget

Automatically selects the best ad type based on context:

```dart
SmartAdWidget(context: 'home')           // Banner at bottom
SmartAdWidget(context: 'job_list')       // Native in list
SmartAdWidget(context: 'job_detail')     // Banner at bottom
SmartAdWidget(context: 'search_results') // Banner at bottom
```

### DynamicAdWidget

Manual control over ad type and position:

```dart
DynamicAdWidget(
  position: 'top',      // 'top', 'bottom', 'job_list', etc.
  adType: 'banner',     // 'banner', 'native', 'custom'
  customConfig: {},     // Custom configuration
)
```

## Ad Managers

### InterstitialAdManager

```dart
final manager = InterstitialAdManager();

// Load ad
manager.loadAd();

// Show ad
manager.showAd();

// Show on specific page
manager.showAdOnPage('JobView');

// Check if can show
if (manager.canShowAd) {
  manager.showAd();
}
```

### RewardedAdManager

```dart
final manager = RewardedAdManager();

// Load ad
manager.loadAd();

// Show ad with reward callback
manager.showAd(
      onRewarded: () {
    // Handle reward
        print('User earned reward!');
      },
    );

// Get reward info
final rewardInfo = manager.getRewardInfo();
```

### AppOpenAdManager

```dart
final manager = AppOpenAdManager.instance;

// Load ad
manager.loadAd();

// Show if available
manager.showAdIfAvailable();

// Check if can show
if (manager.canShowAd) {
  manager.showAd();
}
```

## Configuration Methods

### DynamicAdConfig

```dart
// Check if ad type is enabled
bool isEnabled = DynamicAdConfig.isEnabled('banner');

// Get ad unit ID
String adUnitId = DynamicAdConfig.getAdUnitId('interstitial');

// Get specific setting
String position = DynamicAdConfig.getSetting<String>('banner', 'position', 'bottom');

// Check page-specific settings
bool shouldShow = DynamicAdConfig.shouldShowInterstitialOn('JobView');

// Get global settings
int maxAds = DynamicAdConfig.getMaxAdsPerSession();
int cooldown = DynamicAdConfig.getCooldownPeriod();

// Force refresh
await DynamicAdConfig.refresh();
```

### AdRefreshService

```dart
final service = AdRefreshService.instance;

// Get configuration status
Map<String, dynamic> status = service.getConfigurationStatus();

// Force refresh
await service.forceRefreshConfig();
await service.forceRefreshAds();

// Show ads
service.showInterstitialOnPage('JobView');
service.showRewardedAd(onRewarded: () {});
```

## Usage Examples

### Home Page with Banner

```dart
Scaffold(
  body: Column(
    children: [
      Expanded(child: HomeContent()),
      SmartAdWidget(context: 'home'),
    ],
  ),
)
```

### Job List with Native Ads

```dart
ListView.builder(
  itemCount: jobs.length,
  itemBuilder: (context, index) {
    if (index > 0 && index % 5 == 0) {
      return DynamicAdWidget(
        position: 'job_list',
        adType: 'native',
      );
    }
    return JobCard(job: jobs[index]);
  },
)
```

### Job Detail with Interstitial

```dart
class JobDetailPage extends StatefulWidget {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AdRefreshService.instance.showInterstitialOnPage('JobView');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(child: JobContent()),
          SmartAdWidget(context: 'job_detail'),
        ],
      ),
    );
  }
}
```

## Configuration Options

### Banner Ads
- `enabled`: Enable/disable banner ads
- `adUnitId`: Google AdMob banner ad unit ID
- `position`: `top` or `bottom`
- `refreshInterval`: Refresh interval in seconds

### Interstitial Ads
- `enabled`: Enable/disable interstitial ads
- `adUnitId`: Google AdMob interstitial ad unit ID
- `showOnJobView`: Show on job detail pages
- `showOnCategoryView`: Show on category pages
- `minInterval`: Minimum interval between shows (seconds)

### Native Ads
- `enabled`: Enable/disable native ads
- `adUnitId`: Google AdMob native ad unit ID
- `position`: `job_list`, `company_list`, `category_list`
- `style`: `default` or `custom`

### Rewarded Ads
- `enabled`: Enable/disable rewarded ads
- `adUnitId`: Google AdMob rewarded ad unit ID
- `rewardType`: `premium_jobs`, `boost_profile`, `remove_ads`
- `rewardAmount`: Number of rewards given

### App Open Ads
- `enabled`: Enable/disable app open ads
- `adUnitId`: Google AdMob app open ad unit ID
- `showOnResume`: Show when app resumes
- `maxShowsPerDay`: Maximum shows per day

### Global Settings
- `testMode`: Enable test mode
- `debugMode`: Enable debug logging
- `maxAdsPerSession`: Maximum ads per session
- `cooldownPeriod`: Cooldown period between ads (seconds)

## Best Practices

1. **Always check if ads are enabled** before showing them
2. **Use SmartAdWidget** for automatic ad selection
3. **Respect cooldown periods** to avoid ad spam
4. **Handle ad failures gracefully** with fallbacks
5. **Monitor ad performance** and adjust settings accordingly
6. **Test with different configurations** before deploying
7. **Use appropriate ad types** for different contexts
8. **Cache configuration** to reduce API calls
9. **Log ad events** for analytics
10. **Allow instant disabling** of problematic ad types

## Error Handling

The system includes comprehensive error handling:

- **API failures**: Fallback to cached or default configuration
- **Ad load failures**: Automatic retry mechanisms
- **Network issues**: Graceful degradation
- **Invalid configuration**: Safe defaults

## Debugging

Enable debug mode to see detailed logs:

```dart
// Check if debug mode is enabled
bool isDebug = DynamicAdConfig.isDebugMode;

// Get configuration status
Map<String, dynamic> status = AdRefreshService.instance.getConfigurationStatus();
print('Ad Status: $status');
```

## Migration from Static Ads

To migrate from static ad configuration:

1. Replace `AdConfig` imports with `DynamicAdConfig`
2. Update ad widgets to use dynamic configuration
3. Add SmartAdWidget where appropriate
4. Initialize the dynamic system in main()
5. Test with different remote configurations

## API Endpoints

The system uses these API endpoints:

- `GET /ads-config` - Get current configuration
- `GET /ads-config?environment=test` - Get test configuration
- `PUT /admin/ads-config` - Update configuration (admin only)

See the full API documentation in `DYNAMIC_AD_API.md`. 