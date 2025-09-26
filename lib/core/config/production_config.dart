// lib/core/config/production_config.dart
// 🏭 Production Configuration - Optimized for Performance & Security

import 'package:flutter/foundation.dart';

class ProductionConfig {
  // 🛡️ Security settings
  static const bool debugMode = kDebugMode;
  static const bool enableVerboseLogging = kDebugMode;
  static const bool enableNetworkLogging = kDebugMode;
  static const bool enableCrashReporting = !kDebugMode;

  // ⚡ Performance settings
  static const Duration apiTimeout = Duration(seconds: 15);
  static const Duration cacheTimeout = Duration(hours: 6);
  static const Duration backgroundSyncInterval = Duration(hours: 2);
  static const int maxRetries = 3;
  static const int maxConcurrentRequests = 5;

  // 💾 Cache settings
  static const int maxCacheSize = 50 * 1024 * 1024; // 50MB
  static const Duration cacheTTL = Duration(days: 7);
  static const int maxCacheEntries = 1000;

  // 🔔 Notification settings
  static const int maxDailyNotifications = 8;
  static const Duration notificationCooldown = Duration(hours: 1);
  static const List<int> allowedNotificationHours = [8, 10, 12, 14, 16, 18, 19, 20];

  // 🎙️ Voice settings
  static const Duration maxVoiceRecordingLength = Duration(minutes: 2);
  static const Duration voiceCommandTimeout = Duration(seconds: 5);
  static const double voiceConfidenceThreshold = 0.7;

  // 📱 App settings
  static const String appVersion = '2.0.0';
  static const String apiVersion = 'v1';
  static const String userAgent = 'MasterParenthood/$appVersion';

  // 🌐 API endpoints
  static const String baseApiUrl = kDebugMode
    ? 'http://localhost:3000/api'
    : 'https://api.masterparenthood.com';

  // 🔐 Security headers
  static const Map<String, String> securityHeaders = {
    'X-Content-Type-Options': 'nosniff',
    'X-Frame-Options': 'DENY',
    'X-XSS-Protection': '1; mode=block',
    'Referrer-Policy': 'strict-origin-when-cross-origin',
  };

  // 📊 Analytics settings
  static const bool enableAnalytics = !kDebugMode;
  static const bool enablePerformanceMonitoring = !kDebugMode;
  static const Duration analyticsFlushInterval = Duration(minutes: 5);

  // 🔄 Backup settings
  static const Duration autoBackupInterval = Duration(hours: 6);
  static const int maxBackupRetention = 30; // days
  static const bool enableCloudBackup = true;
  static const int maxBackupSize = 100 * 1024 * 1024; // 100MB

  // 🌍 Localization settings
  static const List<String> supportedLanguages = [
    'en', 'ru', 'es', 'fr', 'de', 'it', 'pt', 'ja', 'ko', 'zh',
    'ar', 'hi', 'tr', 'pl', 'nl', 'sv', 'da', 'no', 'fi', 'cs',
  ];

  // 🎨 UI settings
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration debounceDelay = Duration(milliseconds: 500);
  static const int maxListItems = 50; // for pagination

  // 📱 Device-specific optimizations
  static bool get isLowEndDevice {
    // This would typically check device specs
    return false; // Implement based on actual device capabilities
  }

  static Duration get adaptiveTimeout {
    return isLowEndDevice
      ? const Duration(seconds: 30)
      : const Duration(seconds: 15);
  }

  static int get adaptiveCacheSize {
    return isLowEndDevice
      ? 25 * 1024 * 1024  // 25MB for low-end devices
      : 50 * 1024 * 1024; // 50MB for normal devices
  }

  // 🔍 Feature flags
  static const bool enableVoiceFeatures = true;
  static const bool enableAIFeatures = true;
  static const bool enableCommunityFeatures = true;
  static const bool enableBackupFeatures = true;
  static const bool enableNotificationFeatures = true;
  static const bool enableCalendarFeatures = true;

  // 🚨 Error handling
  static const int maxErrorRetries = 3;
  static const Duration errorRetryDelay = Duration(seconds: 2);
  static const bool enableAutomaticErrorReporting = !kDebugMode;

  // 🔒 Privacy settings
  static const bool enableDataCollection = !kDebugMode;
  static const bool enableCrashlytics = !kDebugMode;
  static const Duration dataRetentionPeriod = Duration(days: 365);

  // 📈 Performance monitoring
  static const bool enableFrameRateMonitoring = kDebugMode;
  static const bool enableMemoryMonitoring = kDebugMode;
  static const bool enableNetworkMonitoring = kDebugMode;

  // Validate configuration on app start
  static void validateConfig() {
    assert(apiTimeout.inSeconds > 0, 'API timeout must be positive');
    assert(maxRetries > 0, 'Max retries must be positive');
    assert(maxCacheSize > 0, 'Cache size must be positive');
    assert(supportedLanguages.isNotEmpty, 'Must support at least one language');

    if (kDebugMode) {
      print('✅ Production configuration validated successfully');
      print('🔧 Debug mode: $debugMode');
      print('⚡ API timeout: ${apiTimeout.inSeconds}s');
      print('💾 Cache size: ${(maxCacheSize / 1024 / 1024).toStringAsFixed(1)}MB');
      print('🌍 Supported languages: ${supportedLanguages.length}');
    }
  }
}

// 🏭 Environment-specific configurations
class EnvironmentConfig {
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: kDebugMode ? 'development' : 'production',
  );

  static bool get isDevelopment => environment == 'development';
  static bool get isProduction => environment == 'production';
  static bool get isTesting => environment == 'testing';

  // API Keys (use environment variables in production)
  static String get openAIApiKey => const String.fromEnvironment(
    'OPENAI_API_KEY',
    defaultValue: '',
  );

  static String get googleTranslateApiKey => const String.fromEnvironment(
    'GOOGLE_TRANSLATE_API_KEY',
    defaultValue: '',
  );

  static String get firebaseApiKey => const String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: '',
  );

  // Validate environment
  static void validateEnvironment() {
    if (isProduction) {
      assert(openAIApiKey.isNotEmpty, 'OpenAI API key required in production');
      assert(googleTranslateApiKey.isNotEmpty, 'Google Translate API key required');
      assert(firebaseApiKey.isNotEmpty, 'Firebase API key required');
    }

    if (kDebugMode) {
      print('🌍 Environment: $environment');
      print('🔑 API keys configured: ${_getConfiguredKeys()}');
    }
  }

  static String _getConfiguredKeys() {
    final keys = <String>[];
    if (openAIApiKey.isNotEmpty) keys.add('OpenAI');
    if (googleTranslateApiKey.isNotEmpty) keys.add('Google Translate');
    if (firebaseApiKey.isNotEmpty) keys.add('Firebase');
    return keys.join(', ');
  }
}