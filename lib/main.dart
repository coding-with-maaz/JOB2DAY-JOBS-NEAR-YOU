import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/onboarding_screen.dart';
import 'pages/home_screen.dart';
import 'pages/job_details_page.dart';
import 'widgets/google_ads/dynamic_ad_config.dart';
import 'widgets/google_ads/ad_refresh_service.dart';
import 'services/simple_notification_service.dart';
import 'services/notification_navigation.dart';
import 'utils/logger.dart';
import 'package:flutter/services.dart';
import 'widgets/google_ads/app_open_ads/app_open_ad_manager.dart';
import 'utils/app_info.dart';
import 'services/review_service.dart';
import 'services/first_launch_service.dart';
import 'services/navigation_visit_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // Transparent status bar
      statusBarIconBrightness: Brightness.light, // Light icons for dark backgrounds
      statusBarBrightness: Brightness.dark, // For iOS
      systemNavigationBarColor: Color(0xFFFFF7F4), // Match bottom navigation background
      systemNavigationBarIconBrightness: Brightness.dark, // Dark navigation icons
    ),
  );
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    Logger.info('Firebase initialized successfully');
  } catch (e) {
    Logger.error('Firebase initialization failed: $e');
    // Continue without Firebase
  }
  
  // Initialize Google Mobile Ads
  try {
    await MobileAds.instance.initialize();
    Logger.info('Google Mobile Ads initialized successfully');
  } catch (e) {
    Logger.error('Google Mobile Ads initialization failed: $e');
    // Continue without ads
  }
  
  Logger.info('=== App Starting ===');
  
  // Test API connection with timeout
  try {
    Logger.info('Testing API connection...');
    final apiTestResult = await DynamicAdConfig.testApiConnection()
        .timeout(const Duration(seconds: 10));
    Logger.info('API Connection Test Result: $apiTestResult');
  } catch (e) {
    Logger.error('API connection test failed: $e');
    // Continue without API connection
  }
  
  // Initialize dynamic ad configuration with timeout
  try {
    await DynamicAdConfig.initialize()
        .timeout(const Duration(seconds: 15));
  } catch (e) {
    Logger.error('Dynamic ad config initialization failed: $e');
    // Continue without dynamic ads
  }
  
  // Initialize ad refresh service with timeout
  try {
    await AdRefreshService.instance.initialize()
        .timeout(const Duration(seconds: 10));
  } catch (e) {
    Logger.error('Ad refresh service initialization failed: $e');
    // Continue without ad refresh
  }

  // Initialize App Open Ad Manager with timeout
  try {
    AppOpenAdManager.instance.initialize();
    AppOpenAdManager.instance.loadAd();
    
    // Show app open ad after a longer delay to ensure proper loading
    await Future.delayed(const Duration(milliseconds: 4000));
    
    // Check if we can show the app open ad before attempting
    if (AppOpenAdManager.instance.canShowAppOpenAd) {
      AppOpenAdManager.instance.forceShowImmediate();
    } else {
      Logger.info('Main: Cannot show app open ad - conditions not met');
    }
  } catch (e) {
    Logger.error('App open ad manager initialization failed: $e');
    // Continue without app open ads
  }

  // Initialize app info with timeout
  try {
    await AppInfo.initialize()
        .timeout(const Duration(seconds: 5));
  } catch (e) {
    Logger.error('App info initialization failed: $e');
    // Continue without app info
  }
  
  // Initialize simple notification service with timeout
  try {
    await SimpleNotificationService.instance.initialize()
        .timeout(const Duration(seconds: 10));
  } catch (e) {
    Logger.error('Notification service initialization failed: $e');
    // Continue without notifications
  }
  
  // Initialize review service and increment app open count with timeout
  try {
    await ReviewService().incrementAppOpenCount()
        .timeout(const Duration(seconds: 5));
  } catch (e) {
    Logger.error('Review service initialization failed: $e');
    // Continue without review service
  }
  
  Logger.info('=== App Started ===');

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool _hasBeenBackgrounded = false;

  @override
  void initState() {
    super.initState();
    print('MyApp: initState called');
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    print('MyApp: dispose called');
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('MyApp: App lifecycle state changed to: $state');
    if (state == AppLifecycleState.paused) {
      print('MyApp: App paused');
      _hasBeenBackgrounded = true;
    } else if (state == AppLifecycleState.resumed && _hasBeenBackgrounded) {
      print('MyApp: App resumed from background');
      // Show app open ad when app resumes from background
      _showAppOpenAdOnResume();
    }
  }

  void _showAppOpenAdOnResume() {
    try {
      // Add a small delay to ensure the app is fully resumed
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          AppOpenAdManager.instance.showAdIfAvailable();
        }
      });
    } catch (e) {
      Logger.error('Failed to show app open ad on resume: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JOB2DAY',
      navigatorKey: NotificationNavigation.navigatorKey,
      theme: ThemeData(
        // New color scheme based on deepPurple
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
          background: const Color(0xFFFFF7F4), // Soft blush background
        ),
        // Custom text theme
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: Color(0xFF1A1A1A), // Dark charcoal for headings
            fontWeight: FontWeight.bold,
            fontSize: 26,
            fontFamily: 'Poppins',
          ),
          headlineMedium: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.bold,
            fontSize: 22,
            fontFamily: 'Poppins',
          ),
          headlineSmall: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
            fontFamily: 'Poppins',
          ),
          bodyLarge: TextStyle(
            color: Color(0xFF3C3C43), // Medium gray for body text
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
          bodyMedium: TextStyle(
            color: Color(0xFF3C3C43),
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          bodySmall: TextStyle(
            color: Color(0xFF3C3C43),
            fontWeight: FontWeight.w400,
            fontSize: 12,
          ),
        ),
        // App bar theme
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFFF7F4), // Match status bar background
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.bold,
            fontSize: 26,
            fontFamily: 'Poppins',
          ),
          iconTheme: IconThemeData(
            color: Color(0xFF1A1A1A),
          ),
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
        ),
        // Scaffold theme
        scaffoldBackgroundColor: const Color(0xFFFFF7F4), // Soft blush background
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      routes: {
        '/job-details': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return JobDetailsPage(jobSlug: args['jobSlug'] as String);
        },
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _showAppOpenAdImmediately();
    _checkOnboardingStatus();
  }

  void _showAppOpenAdImmediately() {
    // Show app open ad after splash screen appears with delay to avoid conflicts
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) {
        try {
          // Check if we can show the app open ad before attempting
          if (AppOpenAdManager.instance.canShowAppOpenAd) {
            AppOpenAdManager.instance.forceShowImmediate();
          } else {
            Logger.info('SplashScreen: Cannot show app open ad - conditions not met');
          }
        } catch (e) {
          Logger.error('Failed to show immediate app open ad: $e');
        }
      }
    });
  }

  Future<void> _checkOnboardingStatus() async {
    Logger.info('SplashScreen: Starting onboarding status check');
    
    // Show app open ad immediately on first launch, before any delay
    Logger.info('SplashScreen: Attempting to show first launch ad');
    await FirstLaunchService.instance.showFirstLaunchAd();
    Logger.info('SplashScreen: First launch ad process completed');
    
    // Show first session ad for better user experience
    Logger.info('SplashScreen: Attempting to show first session ad');
    await NavigationVisitService().showFirstSessionAd();
    Logger.info('SplashScreen: First session ad process completed');
    
    // Add a small delay for splash screen effect
    Logger.info('SplashScreen: Starting splash screen delay');
    await Future.delayed(const Duration(seconds: 1)); // Reduced delay since we're showing ad immediately
    Logger.info('SplashScreen: Splash screen delay completed');
    
    if (!mounted) {
      Logger.info('SplashScreen: Widget not mounted after delay, returning');
      return;
    }
    
    final prefs = await SharedPreferences.getInstance();
    final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
    Logger.info('SplashScreen: Onboarding completed: $onboardingCompleted');
    
    if (!mounted) {
      Logger.info('SplashScreen: Widget not mounted after prefs check, returning');
      return;
    }
    
    if (onboardingCompleted) {
      Logger.info('SplashScreen: Navigating to HomeScreen');
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    } else {
      Logger.info('SplashScreen: Navigating to OnboardingScreen');
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const OnboardingScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo/Icon
              Icon(
                Icons.work,
                size: 80,
                color: Colors.white,
              ),
              SizedBox(height: 24),
              // App Name
              Text(
                'JOB2DAY',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              SizedBox(height: 16),
              // Tagline
              Text(
                'Find Your Dream Job',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                  fontFamily: 'Poppins',
                ),
              ),
              SizedBox(height: 40),
              // Loading indicator
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
