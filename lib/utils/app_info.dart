import 'package:package_info_plus/package_info_plus.dart';

class AppInfo {
  static String _version = '1.0.0';
  static String _buildNumber = '45';
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _version = packageInfo.version;
      _buildNumber = packageInfo.buildNumber;
      _isInitialized = true;
    } catch (e) {
      // Use default values if package info fails
      _version = '1.0.0';
      _buildNumber = '45';
    }
  }

  static String get version => _version;
  static String get buildNumber => _buildNumber;
  static String get fullVersion => '$_version ($_buildNumber)';
} 