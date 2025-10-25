// lib/services/cache_service.dart
import 'firebase_service.dart';

/// Сервис кэширования для оптимизации производительности
class CacheService {
  // Singleton pattern
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  static final Map<String, dynamic> _cache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheTimeout = Duration(minutes: 5);

  /// Кэш активного ребенка
  static ChildProfile? _activeChild;
  static DateTime? _activeChildTimestamp;

  /// Кэш пользовательского профиля
  static UserProfile? _userProfile;
  static DateTime? _userProfileTimestamp;

  /// Получить активного ребенка из кэша
  static ChildProfile? getCachedActiveChild() {
    if (_activeChild != null && _activeChildTimestamp != null) {
      if (DateTime.now().difference(_activeChildTimestamp!) < _cacheTimeout) {
        return _activeChild;
      }
    }
    return null;
  }

  /// Сохранить активного ребенка в кэш
  static void cacheActiveChild(ChildProfile? child) {
    _activeChild = child;
    _activeChildTimestamp = DateTime.now();
  }

  /// Получить профиль пользователя из кэша
  static UserProfile? getCachedUserProfile() {
    if (_userProfile != null && _userProfileTimestamp != null) {
      if (DateTime.now().difference(_userProfileTimestamp!) < _cacheTimeout) {
        return _userProfile;
      }
    }
    return null;
  }

  /// Сохранить профиль пользователя в кэш
  static void cacheUserProfile(UserProfile? profile) {
    _userProfile = profile;
    _userProfileTimestamp = DateTime.now();
  }

  /// Универсальный метод кэширования (статический, для обратной совместимости)
  static T? getSync<T>(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp != null && DateTime.now().difference(timestamp) < _cacheTimeout) {
      return _cache[key] as T?;
    }
    return null;
  }

  /// Универсальное сохранение в кэш (статическое, для обратной совместимости)
  static void setSync<T>(String key, T value, {Duration? duration}) {
    _cache[key] = value;
    _cacheTimestamps[key] = DateTime.now();
  }

  /// Асинхронный метод получения из кэша (instance method)
  Future<T?> get<T>(String key) async {
    final timestamp = _cacheTimestamps[key];
    if (timestamp != null && DateTime.now().difference(timestamp) < _cacheTimeout) {
      return _cache[key] as T?;
    }
    return null;
  }

  /// Асинхронное сохранение в кэш (instance method)
  Future<void> set<T>(String key, T value, {Duration? duration}) async {
    _cache[key] = value;
    _cacheTimestamps[key] = DateTime.now();
  }

  /// Очистить весь кэш
  static void clearAll() {
    _cache.clear();
    _cacheTimestamps.clear();
    _activeChild = null;
    _activeChildTimestamp = null;
    _userProfile = null;
    _userProfileTimestamp = null;
  }

  /// Очистить кэш по ключу
  static void clear(String key) {
    _cache.remove(key);
    _cacheTimestamps.remove(key);
  }

  /// Проверить, есть ли валидный кэш по ключу
  static bool hasValidCache(String key) {
    final timestamp = _cacheTimestamps[key];
    return timestamp != null && DateTime.now().difference(timestamp) < _cacheTimeout;
  }

  // ===== AI КЭШИРОВАНИЕ =====

  /// Получить кэшированную историю
  static String? getCachedStory(String prompt) {
    return getSync<String>('story_$prompt');
  }

  /// Сохранить историю в кэш
  static void cacheStory(String prompt, String story) {
    setSync<String>('story_$prompt', story);
  }

  /// Получить кэшированный совет
  static String? getCachedAdvice(String question) {
    return getSync<String>('advice_$question');
  }

  /// Сохранить совет в кэш
  static void cacheAdvice(String question, String advice) {
    setSync<String>('advice_$question', advice);
  }

  /// Очистить AI кэш
  static void clearAICache() {
    final aiKeys = _cache.keys.where((key) => 
      key.startsWith('story_') || key.startsWith('advice_')
    ).toList();
    
    for (final key in aiKeys) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }
}