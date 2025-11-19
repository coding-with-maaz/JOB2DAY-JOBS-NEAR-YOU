import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import '../utils/app_colors.dart';
import '../utils/logger.dart';
import '../utils/app_info.dart';
import '../services/simple_notification_service.dart';
import '../services/first_launch_service.dart';
import '../widgets/google_ads/banner_ads/banner_ad_widget.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _jobAlertsEnabled = true;
  bool _autoRefreshEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  String _appVersion = AppInfo.version;
  String _buildNumber = AppInfo.buildNumber;
  bool _isLoading = false;
  String _cacheSize = '0 MB';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await AppInfo.initialize();
    await _loadSettings();
    await _calculateCacheSize();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
        _jobAlertsEnabled = prefs.getBool('job_alerts_enabled') ?? true;
        _autoRefreshEnabled = prefs.getBool('auto_refresh_enabled') ?? true;
        _soundEnabled = prefs.getBool('sound_enabled') ?? true;
        _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
      });
    } catch (e) {
      Logger.error('SettingsPage: Error loading settings: $e');
      _showErrorSnackBar('Failed to load settings');
    }
  }

  Future<void> _saveNotificationSettings(bool value) async {
    try {
      setState(() => _isLoading = true);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', value);
      
      if (value) {
        // Initialize notifications if enabled
        await SimpleNotificationService.instance.initialize();
        _showSuccessSnackBar('Notifications enabled');
      } else {
        // Disable notifications
        await SimpleNotificationService.instance.disableNotifications();
        _showSuccessSnackBar('Notifications disabled');
      }
      
      setState(() {
        _notificationsEnabled = value;
        _isLoading = false;
      });
    } catch (e) {
      Logger.error('SettingsPage: Error saving notification settings: $e');
      _showErrorSnackBar('Failed to update notification settings');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveJobAlertsSettings(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('job_alerts_enabled', value);
      
      if (value && _notificationsEnabled) {
        // Subscribe to job alerts topic
        await SimpleNotificationService.instance.subscribeToTopic('job_alerts');
        _showSuccessSnackBar('Job alerts enabled');
      } else {
        // Unsubscribe from job alerts topic
        await SimpleNotificationService.instance.unsubscribeFromTopic('job_alerts');
        _showSuccessSnackBar('Job alerts disabled');
      }
      
      setState(() {
        _jobAlertsEnabled = value;
      });
    } catch (e) {
      Logger.error('SettingsPage: Error saving job alerts settings: $e');
      _showErrorSnackBar('Failed to update job alerts settings');
    }
  }



  Future<void> _saveAutoRefreshSettings(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('auto_refresh_enabled', value);
      
      setState(() {
        _autoRefreshEnabled = value;
      });
      
      _showSuccessSnackBar(value ? 'Auto refresh enabled' : 'Auto refresh disabled');
    } catch (e) {
      Logger.error('SettingsPage: Error saving auto refresh settings: $e');
      _showErrorSnackBar('Failed to update auto refresh settings');
    }
  }

  Future<void> _saveSoundSettings(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('sound_enabled', value);
      
      setState(() {
        _soundEnabled = value;
      });
      
      _showSuccessSnackBar(value ? 'Sound enabled' : 'Sound disabled');
    } catch (e) {
      Logger.error('SettingsPage: Error saving sound settings: $e');
      _showErrorSnackBar('Failed to update sound settings');
    }
  }

  Future<void> _saveVibrationSettings(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('vibration_enabled', value);
      
      setState(() {
        _vibrationEnabled = value;
      });
      
      _showSuccessSnackBar(value ? 'Vibration enabled' : 'Vibration disabled');
    } catch (e) {
      Logger.error('SettingsPage: Error saving vibration settings: $e');
      _showErrorSnackBar('Failed to update vibration settings');
    }
  }

  Future<void> _calculateCacheSize() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final appDir = await getApplicationDocumentsDirectory();
      
      double totalSize = 0;
      
      // Calculate cache directory size
      if (await cacheDir.exists()) {
        totalSize += await _getDirectorySize(cacheDir);
      }
      
      // Calculate app documents directory size
      if (await appDir.exists()) {
        totalSize += await _getDirectorySize(appDir);
      }
      
      setState(() {
        _cacheSize = _formatBytes(totalSize);
      });
    } catch (e) {
      Logger.error('SettingsPage: Error calculating cache size: $e');
      setState(() {
        _cacheSize = 'Unknown';
      });
    }
  }

  Future<double> _getDirectorySize(Directory dir) async {
    double size = 0;
    try {
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          size += await entity.length();
        }
      }
    } catch (e) {
      Logger.error('SettingsPage: Error calculating directory size: $e');
    }
    return size;
  }

  String _formatBytes(double bytes) {
    if (bytes < 1024) return '${bytes.toStringAsFixed(1)} B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showErrorSnackBar('Could not open link');
      }
    } catch (e) {
      Logger.error('SettingsPage: Error launching URL: $e');
      _showErrorSnackBar('Failed to open link');
    }
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: Text('Are you sure you want to clear the app cache? This will free up $_cacheSize of storage space.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        setState(() => _isLoading = true);
        
        // Clear cached network images
        await CachedNetworkImage.evictFromCache('');
        
        // Clear temporary directory
        final cacheDir = await getTemporaryDirectory();
        if (await cacheDir.exists()) {
          await cacheDir.delete(recursive: true);
        }
        
        // Clear application documents directory (except settings)
        final appDir = await getApplicationDocumentsDirectory();
        if (await appDir.exists()) {
          final files = appDir.listSync();
          for (final file in files) {
            if (file is File && !file.path.contains('shared_preferences')) {
              await file.delete();
            }
          }
        }
        
        // Recalculate cache size
        await _calculateCacheSize();
        
        setState(() => _isLoading = false);
        _showSuccessSnackBar('Cache cleared successfully');
      } catch (e) {
        Logger.error('SettingsPage: Error clearing cache: $e');
        setState(() => _isLoading = false);
        _showErrorSnackBar('Failed to clear cache');
      }
    }
  }

  Future<void> _resetSettings() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text('Are you sure you want to reset all settings to default? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        setState(() => _isLoading = true);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        
        // Reset notification settings
        await SimpleNotificationService.instance.disableNotifications();
        
        // Reload settings
        await _loadSettings();
        
        setState(() => _isLoading = false);
        _showSuccessSnackBar('Settings reset successfully');
      } catch (e) {
        Logger.error('SettingsPage: Error resetting settings: $e');
        setState(() => _isLoading = false);
        _showErrorSnackBar('Failed to reset settings');
      }
    }
  }

  Future<void> _resetFirstLaunch() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset First Launch'),
        content: const Text('This will reset the first launch status, allowing you to see the first launch app open ad again. This is useful for testing purposes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        setState(() => _isLoading = true);
        
        // Reset first launch status
        await FirstLaunchService.instance.resetFirstLaunchStatus();
        
        setState(() => _isLoading = false);
        _showSuccessSnackBar('First launch status reset successfully');
      } catch (e) {
        Logger.error('SettingsPage: Error resetting first launch status: $e');
        setState(() => _isLoading = false);
        _showErrorSnackBar('Failed to reset first launch status');
      }
    }
  }



  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (iconColor ?? AppColors.primary).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: iconColor ?? AppColors.primary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          fontFamily: 'Poppins',
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (iconColor ?? AppColors.primary).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: iconColor ?? AppColors.primary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          fontFamily: 'Poppins',
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: _isLoading ? null : onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Notifications Section
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Text(
                    'Notifications',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Column(
                    children: [
                      _buildSwitchTile(
                        icon: Icons.notifications,
                        title: 'Push Notifications',
                        subtitle: 'Receive job alerts and updates',
                        value: _notificationsEnabled,
                        onChanged: _saveNotificationSettings,
                        iconColor: AppColors.info,
                      ),
                      Divider(height: 1, color: AppColors.borderLight),
                      _buildSwitchTile(
                        icon: Icons.work,
                        title: 'Job Alerts',
                        subtitle: 'Get notified about new job postings',
                        value: _jobAlertsEnabled,
                        onChanged: _saveJobAlertsSettings,
                        iconColor: AppColors.success,
                      ),
                      Divider(height: 1, color: AppColors.borderLight),
                      _buildSwitchTile(
                        icon: Icons.volume_up,
                        title: 'Sound',
                        subtitle: 'Play sound for notifications',
                        value: _soundEnabled,
                        onChanged: _saveSoundSettings,
                        iconColor: AppColors.primary,
                      ),
                      Divider(height: 1, color: AppColors.borderLight),
                      _buildSwitchTile(
                        icon: Icons.vibration,
                        title: 'Vibration',
                        subtitle: 'Vibrate for notifications',
                        value: _vibrationEnabled,
                        onChanged: _saveVibrationSettings,
                        iconColor: AppColors.warning,
                      ),

                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // App Settings Section
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  child: Text(
                    'App Settings',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Column(
                    children: [

                      _buildSwitchTile(
                        icon: Icons.refresh,
                        title: 'Auto Refresh',
                        subtitle: 'Automatically refresh job listings',
                        value: _autoRefreshEnabled,
                        onChanged: _saveAutoRefreshSettings,
                        iconColor: AppColors.primary,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // About Section
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  child: Text(
                    'About',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Column(
                    children: [
                      _buildSettingTile(
                        icon: Icons.info,
                        title: 'About',
                        subtitle: 'App version $_appVersion ($_buildNumber)',
                        onTap: () => _showAboutDialog(),
                        iconColor: AppColors.success,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Data Management Section
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  child: Text(
                    'Data Management',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Column(
                    children: [
                      _buildSettingTile(
                        icon: Icons.clear_all,
                        title: 'Clear Cache',
                        subtitle: 'Clear app cache and temporary data ($_cacheSize)',
                        onTap: _clearCache,
                        iconColor: AppColors.warning,
                      ),
                      Divider(height: 1, color: AppColors.borderLight),
                      _buildSettingTile(
                        icon: Icons.delete_forever,
                        title: 'Reset Settings',
                        subtitle: 'Reset all app settings to default',
                        onTap: _resetSettings,
                        iconColor: AppColors.error,
                      ),
                      Divider(height: 1, color: AppColors.borderLight),
                      _buildSettingTile(
                        icon: Icons.refresh,
                        title: 'Reset First Launch',
                        subtitle: 'Reset first launch status for testing',
                        onTap: _resetFirstLaunch,
                        iconColor: AppColors.info,
                      ),
                    ],
                  ),
                ),
                

                
                const SizedBox(height: 40),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BannerAdWidget(
            collapsible: true,
            collapsiblePlacement: 'bottom',
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About JOB2DAY'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: $_appVersion ($_buildNumber)'),
            const SizedBox(height: 8),
            const Text('A comprehensive job search application that helps you find your dream job.'),
            const SizedBox(height: 16),
            const Text('Features:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('• Browse thousands of job listings'),
            const Text('• Create professional resumes'),
            const Text('• Get job alerts and notifications'),
            const Text('• Search by location and category'),
            const Text('• Real-time job updates'),
            const SizedBox(height: 16),
            const Text('© 2024 JOB2DAY. All rights reserved.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
