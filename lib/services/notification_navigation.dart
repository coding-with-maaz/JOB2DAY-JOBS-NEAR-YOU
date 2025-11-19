import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/country.dart';
import '../pages/category_jobs_page.dart';
import '../pages/country_jobs_page.dart';
import '../utils/logger.dart';

class NotificationNavigation {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  /// Navigate to job details page
  static void navigateToJobDetails(String jobSlug) {
    try {
      Logger.info('NotificationNavigation: Navigating to job details: $jobSlug');
      
      navigatorKey.currentState?.pushNamed(
        '/job-details',
        arguments: {'jobSlug': jobSlug},
      );
    } catch (e) {
      Logger.error('NotificationNavigation: Error navigating to job details: $e');
    }
  }

  /// Navigate to category jobs page
  static void navigateToCategoryJobs(String categorySlug) {
    try {
      Logger.info('NotificationNavigation: Navigating to category jobs: $categorySlug');
      
      // Create a Category object from the slug
      final category = Category(
        id: 0, // We don't have the ID from notification, using 0 as placeholder
        name: _extractCategoryNameFromSlug(categorySlug),
        slug: categorySlug,
        description: '',
        isActive: true,
        jobCount: 0,
      );
      
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => CategoryJobsPage(category: category),
        ),
      );
    } catch (e) {
      Logger.error('NotificationNavigation: Error navigating to category jobs: $e');
    }
  }

  /// Navigate to country jobs page
  static void navigateToCountryJobs(String countrySlug) {
    try {
      Logger.info('NotificationNavigation: Navigating to country jobs: $countrySlug');
      
      // Create a Country object from the slug
      final country = Country(
        name: _extractCountryNameFromSlug(countrySlug),
        slug: countrySlug,
        jobCount: 0,
      );
      
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => CountryJobsPage(country: country),
        ),
      );
    } catch (e) {
      Logger.error('NotificationNavigation: Error navigating to country jobs: $e');
    }
  }

  /// Navigate to home page
  static void navigateToHome() {
    try {
      Logger.info('NotificationNavigation: Navigating to home');
      
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/',
        (route) => false,
      );
    } catch (e) {
      Logger.error('NotificationNavigation: Error navigating to home: $e');
    }
  }

  /// Navigate to jobs page
  static void navigateToJobs() {
    try {
      Logger.info('NotificationNavigation: Navigating to jobs');
      
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/jobs',
        (route) => false,
      );
    } catch (e) {
      Logger.error('NotificationNavigation: Error navigating to jobs: $e');
    }
  }

  /// Extract category name from slug
  static String _extractCategoryNameFromSlug(String slug) {
    // Convert slug to readable name
    // e.g., "technology-123" -> "Technology"
    final parts = slug.split('-');
    if (parts.isNotEmpty) {
      final name = parts[0];
      return name[0].toUpperCase() + name.substring(1);
    }
    return 'Category';
  }

  /// Extract country name from slug
  static String _extractCountryNameFromSlug(String slug) {
    // Convert slug to readable name
    // e.g., "pakistan-1751186119823" -> "Pakistan"
    final parts = slug.split('-');
    if (parts.isNotEmpty) {
      final name = parts[0];
      return name[0].toUpperCase() + name.substring(1);
    }
    return 'Country';
  }
} 