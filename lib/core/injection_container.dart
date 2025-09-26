// lib/core/injection_container.dart
// 🏗️ Dependency Injection Configuration - Flutter 2025 Best Practices
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/translation_service.dart';
import '../services/advanced_ai_service.dart';
import '../services/global_community_service.dart';
import '../services/cache_service.dart';

final GetIt sl = GetIt.instance;

Future<void> initializeDependencies() async {
  // Core dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);

  // HTTP client with proper configuration
  sl.registerLazySingleton<Dio>(() {
    final dio = Dio();
    dio.options = BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    );
    return dio;
  });

  // Cache service
  sl.registerLazySingleton<CacheService>(() => CacheService());

  // Translation service with dependency injection
  sl.registerLazySingleton<TranslationService>(
    () => TranslationService(
      httpClient: sl<Dio>(),
      cacheService: sl<CacheService>(),
    ),
  );

  // Advanced AI service with dependency injection
  sl.registerLazySingleton<AdvancedAIService>(
    () => AdvancedAIService(
      httpClient: sl<Dio>(),
      cacheService: sl<CacheService>(),
    ),
  );

  // Global community service with dependency injection
  sl.registerLazySingleton<GlobalCommunityService>(
    () => GlobalCommunityService(
      httpClient: sl<Dio>(),
      translationService: sl<TranslationService>(),
      cacheService: sl<CacheService>(),
    ),
  );
}

/// Clean up all resources when app is disposed
Future<void> disposeDependencies() async {
  // Close HTTP clients
  await sl<Dio>().close(force: true);

  // Dispose services
  sl<TranslationService>().dispose();
  sl<AdvancedAIService>().dispose();
  sl<GlobalCommunityService>().dispose();
  sl<CacheService>().dispose();

  // Reset GetIt
  await sl.reset();
}