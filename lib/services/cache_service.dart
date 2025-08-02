// lib/services/cache_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class CacheService {
  static const String _storiesCacheKey = 'cached_stories';
  static const String _adviceCacheKey = 'cached_advice';
  static const int _maxCachedItems = 50;
  
  // Кэширование сгенерированной сказки
  static Future<void> cacheStory({
    required String childName,
    required String theme,
    required String story,
    required String language,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _generateCacheKey(childName, theme, language);
      
      // Получаем существующий кэш
      final existingCacheJson = prefs.getString(_storiesCacheKey);
      Map<String, dynamic> cache = {};
      
      if (existingCacheJson != null) {
        cache = Map<String, dynamic>.from(jsonDecode(existingCacheJson));
      }
      
      // Добавляем новую сказку
      cache[cacheKey] = {
        'story': story,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'childName': childName,
        'theme': theme,
        'language': language,
      };
      
      // Ограничиваем размер кэша
      if (cache.length > _maxCachedItems) {
        // Удаляем самые старые записи
        final sortedEntries = cache.entries.toList()
          ..sort((a, b) => (a.value['timestamp'] as int)
              .compareTo(b.value['timestamp'] as int));
        
        while (cache.length > _maxCachedItems) {
          cache.remove(sortedEntries.first.key);
          sortedEntries.removeAt(0);
        }
      }
      
      await prefs.setString(_storiesCacheKey, jsonEncode(cache));
    } catch (e) {
      debugPrint('Error caching story: $e');
    }
  }
  
  // Получение сказки из кэша
  static Future<String?> getCachedStory({
    required String childName,
    required String theme,
    required String language,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheJson = prefs.getString(_storiesCacheKey);
      
      if (cacheJson == null) return null;
      
      final cache = Map<String, dynamic>.from(jsonDecode(cacheJson));
      final cacheKey = _generateCacheKey(childName, theme, language);
      
      if (cache.containsKey(cacheKey)) {
        final cachedData = cache[cacheKey];
        
        // Проверяем актуальность кэша (7 дней)
        final timestamp = cachedData['timestamp'] as int;
        final age = DateTime.now().millisecondsSinceEpoch - timestamp;
        final maxAge = 7 * 24 * 60 * 60 * 1000; // 7 дней в миллисекундах
        
        if (age > maxAge) {
          // Кэш устарел, удаляем
          cache.remove(cacheKey);
          await prefs.setString(_storiesCacheKey, jsonEncode(cache));
          return null;
        }
        
        return cachedData['story'] as String;
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting cached story: $e');
      return null;
    }
  }
  
  // Кэширование совета
  static Future<void> cacheAdvice({
    required String topic,
    required String childAge,
    required String advice,
    required String language,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _generateAdviceCacheKey(topic, childAge, language);
      
      // Получаем существующий кэш
      final existingCacheJson = prefs.getString(_adviceCacheKey);
      Map<String, dynamic> cache = {};
      
      if (existingCacheJson != null) {
        cache = Map<String, dynamic>.from(jsonDecode(existingCacheJson));
      }
      
      // Добавляем новый совет
      cache[cacheKey] = {
        'advice': advice,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'topic': topic,
        'childAge': childAge,
        'language': language,
      };
      
      // Ограничиваем размер кэша
      if (cache.length > _maxCachedItems) {
        final sortedEntries = cache.entries.toList()
          ..sort((a, b) => (a.value['timestamp'] as int)
              .compareTo(b.value['timestamp'] as int));
        
        while (cache.length > _maxCachedItems) {
          cache.remove(sortedEntries.first.key);
          sortedEntries.removeAt(0);
        }
      }
      
      await prefs.setString(_adviceCacheKey, jsonEncode(cache));
    } catch (e) {
      debugPrint('Error caching advice: $e');
    }
  }
  
  // Получение совета из кэша
  static Future<String?> getCachedAdvice({
    required String topic,
    required String childAge,
    required String language,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheJson = prefs.getString(_adviceCacheKey);
      
      if (cacheJson == null) return null;
      
      final cache = Map<String, dynamic>.from(jsonDecode(cacheJson));
      final cacheKey = _generateAdviceCacheKey(topic, childAge, language);
      
      if (cache.containsKey(cacheKey)) {
        final cachedData = cache[cacheKey];
        
        // Проверяем актуальность кэша (3 дня для советов)
        final timestamp = cachedData['timestamp'] as int;
        final age = DateTime.now().millisecondsSinceEpoch - timestamp;
        final maxAge = 3 * 24 * 60 * 60 * 1000; // 3 дня в миллисекундах
        
        if (age > maxAge) {
          cache.remove(cacheKey);
          await prefs.setString(_adviceCacheKey, jsonEncode(cache));
          return null;
        }
        
        return cachedData['advice'] as String;
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting cached advice: $e');
      return null;
    }
  }
  
  // Очистка всего кэша
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storiesCacheKey);
      await prefs.remove(_adviceCacheKey);
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }
  
  // Генерация ключа кэша для сказки
  static String _generateCacheKey(String childName, String theme, String language) {
    final normalizedTheme = theme.toLowerCase().trim();
    return 'story_${childName}_${normalizedTheme}_$language';
  }
  
  // Генерация ключа кэша для совета
  static String _generateAdviceCacheKey(String topic, String childAge, String language) {
    final normalizedTopic = topic.toLowerCase().trim();
    return 'advice_${normalizedTopic}_${childAge}_$language';
  }
}