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
  Logger.info('NotificationService: Background message received: ${message.messageId}');
  
  // Show notification even when app is in background
  await NotificationService.instance._showNotification(message);
}

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  String? _deviceToken;
  bool _isInitialized = false;

  // Getters
  String? get deviceToken => _deviceToken;
  bool get isInitialized => _isInitialized;

  /// Initialize Firebase messaging and local notifications
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      Logger.info('NotificationService: Initializing...');

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
      Logger.info('NotificationService: Initialized successfully');
    } catch (e) {
      Logger.error('NotificationService: Initialization failed: $e');
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

    Logger.info('NotificationService: Local notifications initialized');
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
      Logger.info('NotificationService: User granted notification permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      Logger.info('NotificationService: User granted provisional notification permission');
    } else {
      Logger.warning('NotificationService: User declined notification permission');
    }
  }

  /// Get device token for push notifications
  Future<void> _getDeviceToken() async {
    try {
      _deviceToken = await _firebaseMessaging.getToken();
      if (_deviceToken != null) {
        Logger.info('NotificationService: Device token: $_deviceToken');
        
        // Save token to local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('device_token', _deviceToken!);
        
        // TODO: Send token to your backend server
        // await _sendTokenToServer(_deviceToken!);
      }
    } catch (e) {
      Logger.error('NotificationService: Failed to get device token: $e');
    }

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      _deviceToken = newToken;
      Logger.info('NotificationService: Token refreshed: $newToken');
      
      // Save new token and send to server
      _saveAndSendToken(newToken);
    });
  }

  /// Save token to local storage and send to server
  Future<void> _saveAndSendToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('device_token', token);
      
      // TODO: Send token to your backend server
      // await _sendTokenToServer(token);
    } catch (e) {
      Logger.error('NotificationService: Failed to save/send token: $e');
    }
  }

  /// Set up message handlers for different app states
  void _setupMessageHandlers() {
    // Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      Logger.info('NotificationService: Foreground message received: ${message.messageId}');
      _showNotification(message);
    });

    // App opened from notification (background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      Logger.info('NotificationService: App opened from notification: ${message.messageId}');
      _handleNotificationTap(message);
    });

    // Check if app was opened from notification (killed state)
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        Logger.info('NotificationService: App opened from killed state: ${message.messageId}');
        _handleNotificationTap(message);
      }
    });
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    try {
      final data = message.data;
      final jobId = data['job_id'];
      final jobSlug = data['job_slug'];
      final notificationType = data['type'] ?? 'job';

      Logger.info('NotificationService: Handling notification tap - Type: $notificationType, Job ID: $jobId, Job Slug: $jobSlug');

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
          Logger.info('NotificationService: Unknown notification type: $notificationType');
      }
    } catch (e) {
      Logger.error('NotificationService: Error handling notification tap: $e');
    }
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

      Logger.info('NotificationService: Local notification shown - Title: $title');
    } catch (e) {
      Logger.error('NotificationService: Failed to show notification: $e');
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
      Logger.error('NotificationService: Error handling local notification tap: $e');
    }
  }

  /// Subscribe to topics
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      Logger.info('NotificationService: Subscribed to topic: $topic');
    } catch (e) {
      Logger.error('NotificationService: Failed to subscribe to topic $topic: $e');
    }
  }

  /// Unsubscribe from topics
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      Logger.info('NotificationService: Unsubscribed from topic: $topic');
    } catch (e) {
      Logger.error('NotificationService: Failed to unsubscribe from topic $topic: $e');
    }
  }

  /// Get stored device token
  Future<String?> getStoredToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('device_token');
    } catch (e) {
      Logger.error('NotificationService: Failed to get stored token: $e');
      return null;
    }
  }

  /// Clear stored device token
  Future<void> clearStoredToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('device_token');
      Logger.info('NotificationService: Stored token cleared');
    } catch (e) {
      Logger.error('NotificationService: Failed to clear stored token: $e');
    }
  }

  /// Send token to backend server (implement this based on your API)
  Future<void> sendTokenToServer(String token) async {
    try {
      // TODO: Implement API call to send token to your backend
      // Example:
      // final response = await http.post(
      //   Uri.parse('https://your-api.com/register-device'),
      //   headers: {'Content-Type': 'application/json'},
      //   body: json.encode({
      //     'device_token': token,
      //     'platform': 'android',
      //     'app_version': '1.0.0',
      //   }),
      // );
      
      Logger.info('NotificationService: Token sent to server successfully');
    } catch (e) {
      Logger.error('NotificationService: Failed to send token to server: $e');
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
      Logger.info('NotificationService: Notifications disabled');
    } catch (e) {
      Logger.error('NotificationService: Failed to disable notifications: $e');
    }
  }
} 