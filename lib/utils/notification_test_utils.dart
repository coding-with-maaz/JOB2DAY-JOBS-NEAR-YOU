import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import '../utils/logger.dart';

class NotificationTestUtils {
  /// Test notification payloads for different scenarios
  static const Map<String, Map<String, dynamic>> testPayloads = {
    'new_job': {
      'notification': {
        'title': 'New Job Available! 🚀',
        'body': 'Software Developer position at TechCorp - Apply now!',
      },
      'data': {
        'type': 'job',
        'job_id': '12345',
        'job_slug': 'software-developer-techcorp-12345',
        'title': 'Software Developer',
        'company': 'TechCorp',
        'location': 'New York, NY',
      },
    },
    'job_update': {
      'notification': {
        'title': 'Job Status Updated 📝',
        'body': 'Your application for Senior Developer has been reviewed',
      },
      'data': {
        'type': 'job',
        'job_id': '67890',
        'job_slug': 'senior-developer-company-67890',
        'title': 'Senior Developer',
        'company': 'Company Inc',
        'status': 'reviewed',
      },
    },
    'category_jobs': {
      'notification': {
        'title': 'New Jobs in Technology 💻',
        'body': '5 new technology jobs available in your area',
      },
      'data': {
        'type': 'category',
        'category_slug': 'technology-123',
        'category_name': 'Technology',
        'job_count': '5',
      },
    },
    'country_jobs': {
      'notification': {
        'title': 'Jobs in Pakistan 🇵🇰',
        'body': '12 new job opportunities available in Pakistan',
      },
      'data': {
        'type': 'country',
        'country_slug': 'pakistan-1751186119823',
        'country_name': 'Pakistan',
        'job_count': '12',
      },
    },
    'urgent_job': {
      'notification': {
        'title': 'URGENT: Immediate Hiring! ⚡',
        'body': 'Urgent requirement for React Developer - Apply immediately',
      },
      'data': {
        'type': 'job',
        'job_id': '99999',
        'job_slug': 'urgent-react-developer-99999',
        'title': 'React Developer',
        'company': 'StartupXYZ',
        'urgency': 'high',
        'priority': 'urgent',
      },
    },
  };

  /// Send test notification to device
  static Future<bool> sendTestNotification({
    required String deviceToken,
    required String notificationType,
    String? customTitle,
    String? customBody,
  }) async {
    try {
      final payload = testPayloads[notificationType];
      if (payload == null) {
        Logger.error('NotificationTestUtils: Unknown notification type: $notificationType');
        return false;
      }

      // Create notification payload
      final notificationPayload = {
        'to': deviceToken,
        'priority': 'high',
        'notification': {
          'title': customTitle ?? payload['notification']['title'],
          'body': customBody ?? payload['notification']['body'],
        },
        'data': payload['data'],
      };

      Logger.info('NotificationTestUtils: Sending test notification: $notificationType');
      Logger.info('NotificationTestUtils: Payload: ${json.encode(notificationPayload)}');

      // TODO: Replace with your Firebase Cloud Messaging server key
      // You need to get this from Firebase Console > Project Settings > Cloud Messaging
      const String serverKey = 'YOUR_FIREBASE_SERVER_KEY_HERE';
      
      if (serverKey == 'YOUR_FIREBASE_SERVER_KEY_HERE') {
        Logger.warning('NotificationTestUtils: Please set your Firebase server key');
        return false;
      }

      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: json.encode(notificationPayload),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == 1) {
          Logger.info('NotificationTestUtils: Test notification sent successfully');
          return true;
        } else {
          Logger.error('NotificationTestUtils: Failed to send notification: ${response.body}');
          return false;
        }
      } else {
        Logger.error('NotificationTestUtils: HTTP error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      Logger.error('NotificationTestUtils: Error sending test notification: $e');
      return false;
    }
  }

  /// Test notification handling (simulated)
  static Future<void> testNotificationHandling({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Create a mock RemoteMessage for testing
      final mockMessage = RemoteMessage(
        notification: RemoteNotification(
          title: title,
          body: body,
        ),
        data: data ?? {},
      );

      Logger.info('NotificationTestUtils: Simulating notification handling');
      Logger.info('NotificationTestUtils: Title: $title');
      Logger.info('NotificationTestUtils: Body: $body');
      Logger.info('NotificationTestUtils: Data: $data');
      
      Logger.info('NotificationTestUtils: Notification handling test completed');
    } catch (e) {
      Logger.error('NotificationTestUtils: Error testing notification handling: $e');
    }
  }

  /// Get available test notification types
  static List<String> getAvailableTestTypes() {
    return testPayloads.keys.toList();
  }

  /// Get test payload for a specific type
  static Map<String, dynamic>? getTestPayload(String type) {
    return testPayloads[type];
  }

  /// Validate device token format
  static bool isValidDeviceToken(String token) {
    // Basic validation for FCM device token
    return token.isNotEmpty && token.length > 100;
  }

  /// Generate test notification summary
  static String generateTestSummary() {
    final summary = StringBuffer();
    summary.writeln('=== Notification Test Summary ===');
    summary.writeln('Available test types:');
    
    for (final type in testPayloads.keys) {
      final payload = testPayloads[type]!;
      final notification = payload['notification'] as Map<String, dynamic>;
      summary.writeln('• $type: ${notification['title']}');
    }
    
    summary.writeln('\nTo test notifications:');
    summary.writeln('1. Get your device token from NotificationSettingsPage');
    summary.writeln('2. Set your Firebase server key in notification_test_utils.dart');
    summary.writeln('3. Use sendTestNotification() method');
    summary.writeln('4. Check logs for delivery status');
    summary.writeln('\nNote: Local notifications are disabled due to compatibility issues.');
    summary.writeln('Use Firebase Cloud Messaging for testing notifications.');
    
    return summary.toString();
  }
} 