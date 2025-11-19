import 'package:flutter/material.dart';

/// App Color Constants
/// This file contains all the color definitions used throughout the app
/// to ensure consistency and easy maintenance.
class AppColors {
  // Primary Colors
  static const Color primary = Colors.deepPurple;
  static const Color primaryLight = Color(0xFF9C27B0);
  static const Color primaryLighter = Color(0xFFBA68C8);
  
  // Background Colors
  static const Color background = Color(0xFFFFF7F4); // Soft blush background
  static const Color surface = Colors.white;
  static const Color cardBackground = Colors.white;
  
  // Text Colors
  static const Color textPrimary = Color(0xFF1A1A1A); // Dark charcoal for headings
  static const Color textSecondary = Color(0xFF3C3C43); // Medium gray for body text
  static const Color textTertiary = Color(0xFFB0B0B0); // Medium gray for inactive elements
  
  // Bottom Navigation Colors
  static const Color bottomNavBackground = Color(0xFFFFF7F4);
  static const Color bottomNavBorder = Color(0xFFE5E5E5);
  static const Color bottomNavShadow = Color(0xFFB0B0B0);
  static const Color activeTabBackground = Color(0xFFFCEEEE); // Light pink/red for active tabs
  static const Color activeTabShadow = Color(0xFFFCEEEE);
  static const Color splashColor = Color(0xFFFCEEEE);
  
  // Interactive Colors
  static const Color activeText = Colors.black;
  static const Color inactiveText = Color(0xFFB0B0B0);
  static const Color activeIcon = Colors.black;
  static const Color inactiveIcon = Color(0xFFB0B0B0);
  
  // Border Colors
  static const Color borderLight = Color(0xFFE5E5E5);
  static const Color borderMedium = Color(0xFFB0B0B0);
  
  // Shadow Colors
  static const Color shadowLight = Color(0xFFB0B0B0);
  static const Color shadowMedium = Colors.black;
  
  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
  
  // Gradient Colors
  static const List<Color> primaryGradient = [
    Colors.deepPurple,
    Color(0xFF9C27B0),
    Color(0xFFBA68C8),
  ];
  
  static const List<Color> backgroundGradient = [
    Colors.white,
    Color(0xFFF5F5F5),
  ];
  
  // Opacity Values
  static const double opacity10 = 0.1;
  static const double opacity18 = 0.18;
  static const double opacity25 = 0.25;
  static const double opacity40 = 0.4;
  
  // Container Sizes for Bottom Navigation
  static const double activeTabSize = 48.0;
  static const double inactiveTabSize = 40.0;
  static const double activeIconSize = 30.0;
  static const double inactiveIconSize = 24.0;
  
  // Animation Duration
  static const Duration animationDuration = Duration(milliseconds: 250);
  
  // Border Radius
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  static const double borderRadiusExtraLarge = 20.0;
  
  // Shadow Properties
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0xFFB0B0B0),
      blurRadius: 8,
      offset: Offset(0, 2),
      spreadRadius: 1,
    ),
  ];
  
  static const List<BoxShadow> bottomNavShadowList = [
    BoxShadow(
      color: Color(0xFFB0B0B0),
      blurRadius: 20,
      offset: Offset(0, -4),
      spreadRadius: 2,
    ),
  ];
  
  static const List<BoxShadow> activeTabShadowList = [
    BoxShadow(
      color: Color(0xFFFCEEEE),
      blurRadius: 8,
      offset: Offset(0, 2),
      spreadRadius: 1,
    ),
  ];
} 