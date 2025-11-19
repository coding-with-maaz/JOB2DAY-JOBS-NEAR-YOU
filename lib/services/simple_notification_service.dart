import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';
import 'notification_navigation.dart';

// Top-level function for background message handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  Logger.info('SimpleNotificationService: Background message received: ${message.messageId}');
  
  // Show notification even when app is in background
  await SimpleNotificationService.instance._showNotification(message);
}

class SimpleNotificationService {
  static final SimpleNotificationService instance = SimpleNotificationService._internal();
  SimpleNotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  String? _deviceToken;
  bool _isInitialized = false;

  // Getters
  String? get deviceToken => _deviceToken;
  bool get isInitialized => _isInitialized;

  /// Initialize Firebase messaging
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      Logger.info('SimpleNotificationService: Initializing...');

      // Initialize Firebase
      await Firebase.initializeApp();

      // Set background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Request notification permissions
      await _requestPermissions();

      // Get device token
      await _getDeviceToken();

      // Set up message handlers
      _setupMessageHandlers();

      _isInitialized = true;
      Logger.info('SimpleNotificationService: Initialized successfully');
    } catch (e) {
      Logger.error('SimpleNotificationService: Initialization failed: $e');
    }
  }

  /// Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    Logger.info('SimpleNotificationService: Local notifications initialized');
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      Logger.info('SimpleNotificationService: User granted notification permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      Logger.info('SimpleNotificationService: User granted provisional notification permission');
    } else {
      Logger.warning('SimpleNotificationService: User declined notification permission');
    }
  }

  /// Get device token for push notifications
  Future<void> _getDeviceToken() async {
    try {
      _deviceToken = await _firebaseMessaging.getToken();
      if (_deviceToken != null) {
        Logger.info('SimpleNotificationService: Device token: $_deviceToken');
        
        // Save token to local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('device_token', _deviceToken!);
        
        // Log token for easy copying to Firebase Console
        Logger.info('SimpleNotificationService: Copy this token to Firebase Console: $_deviceToken');
      }
    } catch (e) {
      Logger.error('SimpleNotificationService: Failed to get device token: $e');
    }

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      _deviceToken = newToken;
      Logger.info('SimpleNotificationService: Token refreshed: $newToken');
      _saveToken(newToken);
    });
  }

  /// Save token to local storage
  Future<void> _saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('device_token', token);
      Logger.info('SimpleNotificationService: Token saved locally: $token');
    } catch (e) {
      Logger.error('SimpleNotificationService: Failed to save token: $e');
    }
  }

  /// Set up message handlers for different app states
  void _setupMessageHandlers() {
    // Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      Logger.info('SimpleNotificationService: Foreground message received: ${message.messageId}');
      _showNotification(message);
    });

    // App opened from notification (background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      Logger.info('SimpleNotificationService: App opened from notification: ${message.messageId}');
      _handleNotificationTap(message);
    });

    // Check if app was opened from notification (killed state)
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        Logger.info('SimpleNotificationService: App opened from killed state: ${message.messageId}');
        _handleNotificationTap(message);
      }
    });
  }

  /// Show local notification
  Future<void> _showNotification(RemoteMessage message) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'job_notifications',
        'Job Notifications',
        channelDescription: 'Notifications for new jobs and updates',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF1976D2),
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        styleInformation: BigTextStyleInformation(''),
      );

      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      final title = message.notification?.title ?? message.data['title'] ?? 'New Job';
      final body = message.notification?.body ?? message.data['body'] ?? 'Check out this new opportunity!';
      final payload = json.encode(message.data);

      await _localNotifications.show(
        message.hashCode,
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );

      Logger.info('SimpleNotificationService: Local notification shown - Title: $title');
    } catch (e) {
      Logger.error('SimpleNotificationService: Failed to show notification: $e');
    }
  }

  /// Handle local notification tap
  void _onNotificationTapped(NotificationResponse response) {
    try {
      if (response.payload != null) {
        final data = json.decode(response.payload!);
        final message = RemoteMessage(data: data);
        _handleNotificationTap(message);
      }
    } catch (e) {
      Logger.error('SimpleNotificationService: Error handling local notification tap: $e');
    }
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    try {
      final data = message.data;
      final jobId = data['job_id'];
      final jobSlug = data['job_slug'];
      final notificationType = data['type'] ?? 'job';

      Logger.info('SimpleNotificationService: Handling notification tap - Type: $notificationType, Job ID: $jobId, Job Slug: $jobSlug');

      // Navigate based on notification type
      switch (notificationType) {
        case 'job':
          if (jobSlug != null) {
            NotificationNavigation.navigateToJobDetails(jobSlug);
          }
          break;
        case 'category':
          final categorySlug = data['category_slug'];
          if (categorySlug != null) {
            NotificationNavigation.navigateToCategoryJobs(categorySlug);
          }
          break;
        case 'country':
          final countrySlug = data['country_slug'];
          if (countrySlug != null) {
            NotificationNavigation.navigateToCountryJobs(countrySlug);
          }
          break;
        default:
          Logger.info('SimpleNotificationService: Unknown notification type: $notificationType');
      }
    } catch (e) {
      Logger.error('SimpleNotificationService: Error handling notification tap: $e');
    }
  }

  /// Subscribe to topics
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      Logger.info('SimpleNotificationService: Subscribed to topic: $topic');
    } catch (e) {
      Logger.error('SimpleNotificationService: Failed to subscribe to topic $topic: $e');
    }
  }

  /// Unsubscribe from topics
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      Logger.info('SimpleNotificationService: Unsubscribed from topic: $topic');
    } catch (e) {
      Logger.error('SimpleNotificationService: Failed to unsubscribe from topic $topic: $e');
    }
  }

  /// Get stored device token
  Future<String?> getStoredToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('device_token');
    } catch (e) {
      Logger.error('SimpleNotificationService: Failed to get stored token: $e');
      return null;
    }
  }

  /// Clear stored device token
  Future<void> clearStoredToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('device_token');
      Logger.info('SimpleNotificationService: Stored token cleared');
    } catch (e) {
      Logger.error('SimpleNotificationService: Failed to clear stored token: $e');
    }
  }

  /// Get notification settings
  Future<NotificationSettings> getNotificationSettings() async {
    return await _firebaseMessaging.getNotificationSettings();
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final settings = await getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
           settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// Disable notifications
  Future<void> disableNotifications() async {
    try {
      await _firebaseMessaging.deleteToken();
      await clearStoredToken();
      Logger.info('SimpleNotificationService: Notifications disabled');
    } catch (e) {
      Logger.error('SimpleNotificationService: Failed to disable notifications: $e');
    }
  }

  /// Test local notification (for debugging)
  Future<void> testLocalNotification() async {
    try {
      final testMessage = RemoteMessage(
        data: {
          'title': 'Test Notification',
          'body': 'This is a test notification from the app',
          'type': 'test',
        },
      );
      
      await _showNotification(testMessage);
      Logger.info('SimpleNotificationService: Test notification sent successfully');
    } catch (e) {
      Logger.error('SimpleNotificationService: Failed to send test notification: $e');
      rethrow;
    }
  }
} 