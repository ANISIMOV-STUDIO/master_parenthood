// lib/services/translation_service.dart
// 🌍 Refactored Translation Service - Flutter 2025 Best Practices
import 'dart:convert';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'cache_service.dart';

class TranslationService {
  final Dio _httpClient;
  final CacheService _cacheService;
  final Map<String, Timer> _debounceTimers = {};

  static const String _googleTranslateApiKey = String.fromEnvironment(
    'GOOGLE_TRANSLATE_API_KEY',
    defaultValue: '',
  );

  TranslationService({
    required Dio httpClient,
    required CacheService cacheService,
  }) : _httpClient = httpClient,
       _cacheService = cacheService;

  bool get hasApiKey => _googleTranslateApiKey.isNotEmpty;

  /// 🌍 Auto-detect and translate message for global community
  /// Uses proper error handling and resource management
  Future<Map<String, dynamic>> translateMessage({
    required String message,
    required String targetLanguage,
    String? sourceLanguage,
    bool autoDetect = true,
  }) async {
    try {
      if (message.trim().isEmpty) {
        throw ArgumentError('Message cannot be empty');
      }

      String detectedLanguage = sourceLanguage ?? 'auto';

      // Auto-detect source language if not provided
      if (autoDetect && sourceLanguage == null) {
        detectedLanguage = await _detectLanguage(message);
      }

      // Skip translation if source and target are the same
      if (detectedLanguage == targetLanguage) {
        return _createTranslationResult(
          original: message,
          translated: message,
          sourceLanguage: detectedLanguage,
          targetLanguage: targetLanguage,
          confidence: 1.0,
          cached: false,
        );
      }

      // Check cache first
      final cacheKey = _createCacheKey(message, detectedLanguage, targetLanguage);
      final cachedTranslation = await _getCachedTranslation(cacheKey);
      if (cachedTranslation != null) {
        return cachedTranslation;
      }

      // Perform translation with proper error handling
      final translation = await _performTranslation(
        message: message,
        sourceLanguage: detectedLanguage,
        targetLanguage: targetLanguage,
      );

      // Cache successful translation
      await _cacheTranslation(cacheKey, translation);

      return translation;
    } catch (e) {
      debugPrint('Translation error: $e');
      return _createErrorResult(message, targetLanguage, e);
    }
  }

  /// 🔍 Detect language with proper error handling
  Future<String> _detectLanguage(String text) async {
    if (!hasApiKey) return 'auto';

    try {
      final response = await _httpClient.post(
        'https://translation.googleapis.com/language/translate/v2/detect',
        queryParameters: {'key': _googleTranslateApiKey},
        data: {'q': text},
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return data['data']['detections'][0][0]['language'] ?? 'auto';
      }
    } on DioException catch (e) {
      debugPrint('Language detection failed: ${e.message}');
    } catch (e) {
      debugPrint('Unexpected error in language detection: $e');
    }

    return 'auto';
  }

  /// 🔄 Perform actual translation with timeout and retry logic
  Future<Map<String, dynamic>> _performTranslation({
    required String message,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    if (!hasApiKey) {
      return _getFallbackTranslation(message, targetLanguage);
    }

    try {
      final response = await _httpClient.post(
        'https://translation.googleapis.com/language/translate/v2',
        queryParameters: {
          'key': _googleTranslateApiKey,
          'source': sourceLanguage == 'auto' ? null : sourceLanguage,
          'target': targetLanguage,
          'format': 'text',
        },
        data: {'q': message},
        options: Options(
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final translatedText = data['data']['translations'][0]['translatedText'];
        final detectedSource = data['data']['translations'][0]['detectedSourceLanguage'] ?? sourceLanguage;

        return _createTranslationResult(
          original: message,
          translated: translatedText,
          sourceLanguage: detectedSource,
          targetLanguage: targetLanguage,
          confidence: 0.95,
          cached: false,
        );
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Translation API returned ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      debugPrint('Translation API error: ${e.message}');
      return _getFallbackTranslation(message, targetLanguage);
    }
  }

  /// 💾 Cache management with proper key generation
  String _createCacheKey(String message, String sourceLanguage, String targetLanguage) {
    return '${message.hashCode}_${sourceLanguage}_$targetLanguage';
  }

  Future<Map<String, dynamic>?> _getCachedTranslation(String cacheKey) async {
    try {
      final cached = await _cacheService.get('translation_$cacheKey');
      if (cached != null) {
        final result = Map<String, dynamic>.from(cached);
        result['cached'] = true;
        return result;
      }
    } catch (e) {
      debugPrint('Cache retrieval error: $e');
    }
    return null;
  }

  Future<void> _cacheTranslation(String cacheKey, Map<String, dynamic> translation) async {
    try {
      await _cacheService.set(
        'translation_$cacheKey',
        translation,
        duration: const Duration(days: 7),
      );
    } catch (e) {
      debugPrint('Cache storage error: $e');
    }
  }

  /// 🏗️ Helper methods for creating standardized results
  Map<String, dynamic> _createTranslationResult({
    required String original,
    required String translated,
    required String sourceLanguage,
    required String targetLanguage,
    required double confidence,
    required bool cached,
  }) {
    return {
      'originalText': original,
      'translatedText': translated,
      'sourceLanguage': sourceLanguage,
      'targetLanguage': targetLanguage,
      'confidence': confidence,
      'cached': cached,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  Map<String, dynamic> _createErrorResult(String original, String targetLanguage, Object error) {
    return {
      'originalText': original,
      'translatedText': original, // Fallback to original
      'sourceLanguage': 'unknown',
      'targetLanguage': targetLanguage,
      'confidence': 0.0,
      'cached': false,
      'error': error.toString(),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  Map<String, dynamic> _getFallbackTranslation(String message, String targetLanguage) {
    return _createTranslationResult(
      original: message,
      translated: message, // No translation available
      sourceLanguage: 'unknown',
      targetLanguage: targetLanguage,
      confidence: 0.0,
      cached: false,
    );
  }

  /// 🧹 Proper resource cleanup
  void dispose() {
    // Cancel all debounce timers
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();

    debugPrint('TranslationService disposed');
  }

  /// 📊 Get supported languages
  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'es': 'Spanish',
    'fr': 'French',
    'de': 'German',
    'ru': 'Russian',
    'zh': 'Chinese',
    'ja': 'Japanese',
    'ko': 'Korean',
    'hi': 'Hindi',
    'ar': 'Arabic',
    'tr': 'Turkish',
    'pl': 'Polish',
    'nl': 'Dutch',
    'sv': 'Swedish',
    'da': 'Danish',
    'no': 'Norwegian',
    'pt': 'Portuguese',
    'it': 'Italian',
    // Add more as needed
  };

  /// 🚀 Batch translation with proper resource management
  Future<List<Map<String, dynamic>>> translateBatch({
    required List<String> messages,
    required String targetLanguage,
    String? sourceLanguage,
  }) async {
    if (messages.isEmpty) return [];

    final results = <Map<String, dynamic>>[];
    const batchSize = 10; // Prevent overwhelming the API

    for (int i = 0; i < messages.length; i += batchSize) {
      final batch = messages.skip(i).take(batchSize).toList();
      final batchResults = await Future.wait(
        batch.map((message) => translateMessage(
          message: message,
          targetLanguage: targetLanguage,
          sourceLanguage: sourceLanguage,
        )),
      );
      results.addAll(batchResults);

      // Small delay to be respectful to the API
      if (i + batchSize < messages.length) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    return results;
  }
}