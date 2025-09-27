// lib/core/theme/app_theme.dart
// 🎨 Master Parenthood - Material 3 Expressive Design System 2025

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // 🌈 Family-focused Color Palette (Material 3 Expressive)
  static const Color _seedColor = Color(0xFF6B73FF); // Calming purple-blue

  // Primary Colors - Warm and nurturing
  static const Color primaryColor = Color(0xFF6B73FF);     // Gentle purple-blue
  static const Color primaryLight = Color(0xFF9FA8FF);     // Light variant
  static const Color primaryDark = Color(0xFF3740B3);      // Dark variant

  // Secondary Colors - Soft and caring
  static const Color secondaryColor = Color(0xFFFF9F7A);   // Warm peach
  static const Color secondaryLight = Color(0xFFFFB19F);   // Light peach
  static const Color secondaryDark = Color(0xFFE6824E);    // Deep peach

  // Tertiary Colors - Playful accents
  static const Color tertiaryColor = Color(0xFF7FDBFF);    // Soft cyan
  static const Color tertiaryLight = Color(0xFFA6E8FF);    // Light cyan
  static const Color tertiaryDark = Color(0xFF4FCEFF);     // Vibrant cyan

  // Semantic Colors for parenting app
  static const Color successColor = Color(0xFF4CAF50);     // Growth/positive
  static const Color warningColor = Color(0xFFFFC107);     // Attention needed
  static const Color errorColor = Color(0xFFE57373);       // Gentle error
  static const Color infoColor = Color(0xFF42A5F5);        // Information

  // Neutral Colors
  static const Color surfaceColor = Color(0xFFFEFBFF);     // Warm white
  static const Color backgroundLight = Color(0xFFFCFCFF);  // Pure white
  static const Color backgroundDark = Color(0xFF1C1B1F);   // Dark surface

  // Text Colors
  static const Color textPrimary = Color(0xFF1C1B1F);      // Main text
  static const Color textSecondary = Color(0xFF49454F);    // Secondary text
  static const Color textTertiary = Color(0xFF79747E);     // Hint text

  // Special Colors for App Features
  static const Color feedingColor = Color(0xFF81C784);     // Light green
  static const Color sleepColor = Color(0xFF9C27B0);       // Purple
  static const Color developmentColor = Color(0xFFFF9800); // Orange
  static const Color healthColor = Color(0xFFE91E63);      // Pink
  static const Color communityColor = Color(0xFF2196F3);   // Blue
  static const Color voiceColor = Color(0xFF00BCD4);       // Cyan

  // 🎨 Light Theme Configuration
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: tertiaryColor,
      surface: surfaceColor,
      background: backgroundLight,
      error: errorColor,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,

      // 📱 App Bar Theme - Modern and clean
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),

      // 🎯 Button Themes - Expressive and engaging
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: primaryColor.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          minimumSize: const Size(120, 48),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: secondaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        ),
      ),

      // 📄 Card Theme - Soft and welcoming
      cardTheme: CardTheme(
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(8),
      ),

      // 🎵 Input Decoration - Friendly and approachable
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: errorColor, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      // 🔔 Dialog Theme - Warm and engaging
      dialogTheme: DialogTheme(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: colorScheme.surface,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),

      // 📊 Chip Theme - Playful and functional
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceVariant,
        selectedColor: primaryColor.withOpacity(0.2),
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // 🎨 Typography - Clear and friendly
      textTheme: _buildTextTheme(colorScheme),

      // 🏠 Bottom Navigation - Modern and accessible
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: colorScheme.surface,
        selectedItemColor: primaryColor,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        elevation: 8,
        selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
      ),

      // 📱 Tab Bar Theme
      tabBarTheme: TabBarTheme(
        labelColor: primaryColor,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: primaryColor, width: 3),
          insets: const EdgeInsets.symmetric(horizontal: 16),
        ),
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 14),
      ),

      // 🎯 Floating Action Button - Prominent and friendly
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: secondaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // 🔄 Progress Indicator Theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: colorScheme.surfaceVariant,
        circularTrackColor: colorScheme.surfaceVariant,
      ),

      // 🎨 Divider Theme
      dividerTheme: DividerThemeData(
        color: colorScheme.outline.withOpacity(0.2),
        thickness: 1,
        space: 1,
      ),
    );
  }

  // 🌙 Dark Theme Configuration
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
      primary: primaryLight,
      secondary: secondaryLight,
      tertiary: tertiaryLight,
      surface: const Color(0xFF1C1B1F),
      background: backgroundDark,
      error: errorColor,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,

      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryLight,
          foregroundColor: Colors.black,
          elevation: 2,
          shadowColor: primaryLight.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          minimumSize: const Size(120, 48),
        ),
      ),

      cardTheme: CardTheme(
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(8),
      ),

      textTheme: _buildTextTheme(colorScheme),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: colorScheme.surface,
        selectedItemColor: primaryLight,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        elevation: 8,
        selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
      ),
    );
  }

  // 📝 Typography System - Material 3 Expressive
  static TextTheme _buildTextTheme(ColorScheme colorScheme) {
    return TextTheme(
      // Display styles - Hero content
      displayLarge: TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        color: colorScheme.onSurface,
      ),
      displayMedium: TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: colorScheme.onSurface,
      ),
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: colorScheme.onSurface,
      ),

      // Headline styles - Section headers
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: colorScheme.onSurface,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: colorScheme.onSurface,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: colorScheme.onSurface,
      ),

      // Title styles - Card headers, app bar titles
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        color: colorScheme.onSurface,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        color: colorScheme.onSurface,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: colorScheme.onSurface,
      ),

      // Body styles - Main content
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        color: colorScheme.onSurface,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: colorScheme.onSurface,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: colorScheme.onSurface,
      ),

      // Label styles - Buttons, tabs, labels
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: colorScheme.onSurface,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: colorScheme.onSurface,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: colorScheme.onSurface,
      ),
    );
  }

  // 🎨 Feature-specific Color Getters
  static Color getFeatureColor(String feature) {
    switch (feature.toLowerCase()) {
      case 'feeding':
        return feedingColor;
      case 'sleep':
        return sleepColor;
      case 'development':
        return developmentColor;
      case 'health':
        return healthColor;
      case 'community':
        return communityColor;
      case 'voice':
        return voiceColor;
      default:
        return primaryColor;
    }
  }

  // 🎯 Gradient Definitions for Beautiful Backgrounds
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, primaryColor],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondaryLight, secondaryColor],
  );

  static const LinearGradient tertiaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [tertiaryLight, tertiaryColor],
  );

  // 🌈 Warm Welcome Gradient for Onboarding
  static const LinearGradient warmWelcomeGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFEFBFF),
      Color(0xFFF8F5FF),
      Color(0xFFF0EBFF),
    ],
  );

  // 📱 Dynamic Theme Extensions
  static ThemeData getThemeForFeature(String feature, {bool isDark = false}) {
    final baseTheme = isDark ? darkTheme : lightTheme;
    final featureColor = getFeatureColor(feature);

    return baseTheme.copyWith(
      primaryColor: featureColor,
      floatingActionButtonTheme: baseTheme.floatingActionButtonTheme?.copyWith(
        backgroundColor: featureColor,
      ),
      appBarTheme: baseTheme.appBarTheme?.copyWith(
        backgroundColor: featureColor.withOpacity(0.1),
      ),
    );
  }
}