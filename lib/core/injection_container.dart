// lib/core/injection_container.dart
// 🏗️ Production-Ready Dependency Injection - Flutter 2025 Best Practices
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../services/translation_service.dart';
import '../services/advanced_ai_service.dart';
import '../services/global_community_service.dart';
import '../services/cache_service.dart';
import '../services/enhanced_notification_service.dart';
import '../services/voice_service.dart';
import '../services/smart_calendar_service.dart';
import '../services/backup_service.dart';

final GetIt sl = GetIt.instance;

Future<void> initializeDependencies() async {
  // 🔧 Core dependencies with production optimizations
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);

  // 🌐 HTTP client with production-ready configuration
  sl.registerLazySingleton<Dio>(() {
    final dio = Dio();
    dio.options = BaseOptions(
      connectTimeout: kDebugMode
        ? const Duration(seconds: 10)
        : const Duration(seconds: 5),
      receiveTimeout: kDebugMode
        ? const Duration(seconds: 30)
        : const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'MasterParenthood/2.0',
        'Accept': 'application/json',
      },
    );

    // Add interceptors for production
    if (!kDebugMode) {
      dio.interceptors.add(LogInterceptor(
        requestBody: false,
        responseBody: false,
        logPrint: (obj) => debugPrint(obj.toString()),
      ));
    }

    return dio;
  });

  // 💾 Cache service with production settings
  sl.registerLazySingleton<CacheService>(() => CacheService());

  // 🌍 Translation service with dependency injection
  sl.registerLazySingleton<TranslationService>(
    () => TranslationService(
      httpClient: sl<Dio>(),
      cacheService: sl<CacheService>(),
    ),
  );

  // 🤖 Advanced AI service with dependency injection
  sl.registerLazySingleton<AdvancedAIService>(
    () => AdvancedAIService(
      httpClient: sl<Dio>(),
      cacheService: sl<CacheService>(),
    ),
  );

  // 👥 Global community service with dependency injection
  sl.registerLazySingleton<GlobalCommunityService>(
    () => GlobalCommunityService(),
  );

  // 🔔 Enhanced notification service
  sl.registerLazySingleton<EnhancedNotificationService>(
    () => EnhancedNotificationService(),
  );

  // 🎙️ Voice service
  sl.registerLazySingleton<VoiceService>(
    () => VoiceService(),
  );

  // 📅 Smart calendar service
  sl.registerLazySingleton<SmartCalendarService>(
    () => SmartCalendarService(),
  );

  // 💾 Backup service
  sl.registerLazySingleton<BackupService>(
    () => BackupService(),
  );
}

/// 🧹 Clean up all resources when app is disposed (Production-ready cleanup)
Future<void> disposeDependencies() async {
  try {
    // Close HTTP clients gracefully
    if (sl.isRegistered<Dio>()) {
      sl<Dio>().close(force: true);
    }

    // Dispose services safely
    // Note: Only dispose services that have dispose methods
    // Most services are singletons and will be cleaned up on app close

    // Reset GetIt completely
    await sl.reset();
  } catch (e) {
    debugPrint('Error during dependency disposal: $e');
  }
}

/// 🔍 Check if dependencies are properly initialized
bool get isDependenciesInitialized {
  return sl.isRegistered<Dio>() &&
         sl.isRegistered<CacheService>() &&
         sl.isRegistered<TranslationService>() &&
         sl.isRegistered<AdvancedAIService>() &&
         sl.isRegistered<GlobalCommunityService>() &&
         sl.isRegistered<EnhancedNotificationService>() &&
         sl.isRegistered<VoiceService>() &&
         sl.isRegistered<SmartCalendarService>() &&
         sl.isRegistered<BackupService>();
}

/// 🔄 Re-initialize dependencies if needed (useful for hot reload)
Future<void> reinitializeDependencies() async {
  if (sl.isRegistered<Dio>()) {
    await disposeDependencies();
  }
  await initializeDependencies();
}