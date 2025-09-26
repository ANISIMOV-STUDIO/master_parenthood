// lib/services/advanced_ai_service.dart
// 🚀 Refactored Advanced AI Service - Flutter 2025 Best Practices
import 'dart:convert';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'cache_service.dart';

class AdvancedAIService {
  final Dio _httpClient;
  final CacheService _cacheService;
  final Map<String, Timer> _debounceTimers = {};
  final Map<String, CancelToken> _activeCancellationTokens = {};

  static const String _apiKey = String.fromEnvironment(
    'OPENAI_API_KEY',
    defaultValue: '',
  );

  AdvancedAIService({
    required Dio httpClient,
    required CacheService cacheService,
  }) : _httpClient = httpClient,
       _cacheService = cacheService;

  bool get hasApiKey => _apiKey.isNotEmpty;

  /// 🤖 Real-time Behavioral Analysis AI with proper resource management
  Future<Map<String, dynamic>> analyzeBehavior({
    required String childName,
    required int ageInMonths,
    required List<String> recentBehaviors,
    required String language,
  }) async {
    try {
      if (childName.trim().isEmpty) {
        throw ArgumentError('Child name cannot be empty');
      }
      if (ageInMonths < 0 || ageInMonths > 216) { // 0-18 years
        throw ArgumentError('Invalid age in months');
      }
      if (recentBehaviors.isEmpty) {
        throw ArgumentError('Recent behaviors list cannot be empty');
      }

      final cacheKey = 'behavior_analysis_${childName}_${ageInMonths}_${recentBehaviors.join('_').hashCode}';

      // Check cache first
      final cachedResult = await _getCachedResult(cacheKey);
      if (cachedResult != null) {
        return cachedResult;
      }

      if (!hasApiKey) {
        return _getFallbackBehaviorAnalysis(language);
      }

      // Create cancellation token for this request
      final cancelToken = CancelToken();
      _activeCancellationTokens[cacheKey] = cancelToken;

      try {
        final response = await _httpClient.post(
          'https://api.openai.com/v1/chat/completions',
          data: _buildBehaviorAnalysisRequest(childName, ageInMonths, recentBehaviors, language),
          options: Options(
            headers: {
              'Authorization': 'Bearer $_apiKey',
              'Content-Type': 'application/json',
            },
            sendTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 60),
          ),
          cancelToken: cancelToken,
        );

        if (response.statusCode == 200) {
          final result = _parseBehaviorAnalysisResponse(response.data);

          // Cache successful result
          await _cacheResult(cacheKey, result);

          return result;
        } else {
          throw DioException(
            requestOptions: response.requestOptions,
            response: response,
            message: 'OpenAI API returned ${response.statusCode}',
          );
        }
      } finally {
        _activeCancellationTokens.remove(cacheKey);
      }
    } catch (e) {
      debugPrint('Behavior analysis error: $e');
      return _createErrorResult('behavior_analysis', e);
    }
  }

  /// 🔮 Predictive insights with proper error handling
  Future<Map<String, dynamic>> generatePredictiveInsights({
    required String childName,
    required int ageInMonths,
    required Map<String, dynamic> developmentData,
    required String language,
  }) async {
    try {
      final cacheKey = 'predictive_insights_${childName}_${ageInMonths}_${developmentData.hashCode}';

      final cachedResult = await _getCachedResult(cacheKey);
      if (cachedResult != null) {
        return cachedResult;
      }

      if (!hasApiKey) {
        return _getFallbackPredictiveInsights(language);
      }

      final cancelToken = CancelToken();
      _activeCancellationTokens[cacheKey] = cancelToken;

      try {
        final response = await _httpClient.post(
          'https://api.openai.com/v1/chat/completions',
          data: _buildPredictiveInsightsRequest(childName, ageInMonths, developmentData, language),
          options: Options(
            headers: {
              'Authorization': 'Bearer $_apiKey',
              'Content-Type': 'application/json',
            },
            sendTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 60),
          ),
          cancelToken: cancelToken,
        );

        if (response.statusCode == 200) {
          final result = _parsePredictiveInsightsResponse(response.data);
          await _cacheResult(cacheKey, result);
          return result;
        } else {
          throw DioException(
            requestOptions: response.requestOptions,
            response: response,
            message: 'OpenAI API returned ${response.statusCode}',
          );
        }
      } finally {
        _activeCancellationTokens.remove(cacheKey);
      }
    } catch (e) {
      debugPrint('Predictive insights error: $e');
      return _createErrorResult('predictive_insights', e);
    }
  }

  /// 🎯 Generate personalized activities with resource management
  Future<Map<String, dynamic>> generatePersonalizedActivities({
    required String childName,
    required int ageInMonths,
    required List<String> interests,
    required String currentWeather,
    required String language,
  }) async {
    try {
      final cacheKey = 'personalized_activities_${childName}_${ageInMonths}_${interests.join('_').hashCode}_$currentWeather';

      final cachedResult = await _getCachedResult(cacheKey);
      if (cachedResult != null) {
        return cachedResult;
      }

      if (!hasApiKey) {
        return _getFallbackPersonalizedActivities(ageInMonths, language);
      }

      final cancelToken = CancelToken();
      _activeCancellationTokens[cacheKey] = cancelToken;

      try {
        final response = await _httpClient.post(
          'https://api.openai.com/v1/chat/completions',
          data: _buildPersonalizedActivitiesRequest(childName, ageInMonths, interests, currentWeather, language),
          options: Options(
            headers: {
              'Authorization': 'Bearer $_apiKey',
              'Content-Type': 'application/json',
            },
            sendTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 60),
          ),
          cancelToken: cancelToken,
        );

        if (response.statusCode == 200) {
          final result = _parsePersonalizedActivitiesResponse(response.data);
          await _cacheResult(cacheKey, result, duration: const Duration(hours: 4)); // Shorter cache for activities
          return result;
        } else {
          throw DioException(
            requestOptions: response.requestOptions,
            response: response,
            message: 'OpenAI API returned ${response.statusCode}',
          );
        }
      } finally {
        _activeCancellationTokens.remove(cacheKey);
      }
    } catch (e) {
      debugPrint('Personalized activities error: $e');
      return _createErrorResult('personalized_activities', e);
    }
  }

  // 🏗️ Helper methods for building requests
  Map<String, dynamic> _buildBehaviorAnalysisRequest(
    String childName, int ageInMonths, List<String> behaviors, String language) {
    return {
      'model': 'gpt-4o-mini',
      'messages': [
        {
          'role': 'system',
          'content': 'You are an advanced child behavioral analyst AI. '
              'Analyze child behavior patterns and provide actionable insights. '
              'Focus on positive reinforcement and developmental appropriateness. '
              'Return JSON with structure: {"analysis": "string", "triggers": ["string"], '
              '"strategies": ["string"], "alerts": ["string"], "positivePatterns": ["string"]}. '
              'Respond in $language language.',
        },
        {
          'role': 'user',
          'content': 'Analyze behavior patterns for $childName (${ageInMonths} months old). '
              'Recent behaviors: ${behaviors.join(", ")}. '
              'Provide comprehensive analysis with actionable strategies.',
        }
      ],
      'max_tokens': 1000,
      'temperature': 0.7,
    };
  }

  Map<String, dynamic> _buildPredictiveInsightsRequest(
    String childName, int ageInMonths, Map<String, dynamic> developmentData, String language) {
    return {
      'model': 'gpt-4o-mini',
      'messages': [
        {
          'role': 'system',
          'content': 'You are a child development prediction AI. '
              'Analyze current development data and predict future milestones. '
              'Return JSON with structure: {"nextMilestones": ["string"], "timeline": "string", '
              '"recommendations": ["string"], "riskFactors": ["string"], "strengths": ["string"]}. '
              'Respond in $language language.',
        },
        {
          'role': 'user',
          'content': 'Predict development insights for $childName (${ageInMonths} months old). '
              'Current development data: ${jsonEncode(developmentData)}. '
              'Provide timeline predictions and recommendations.',
        }
      ],
      'max_tokens': 1000,
      'temperature': 0.6,
    };
  }

  Map<String, dynamic> _buildPersonalizedActivitiesRequest(
    String childName, int ageInMonths, List<String> interests, String weather, String language) {
    return {
      'model': 'gpt-4o-mini',
      'messages': [
        {
          'role': 'system',
          'content': 'You are a personalized activity generator for children. '
              'Create age-appropriate, engaging activities based on interests and weather. '
              'Return JSON with structure: {"activities": [{"title": "string", "description": "string", '
              '"duration": "string", "materials": ["string"], "learningGoals": ["string"]}], '
              '"safetyTips": ["string"]}. '
              'Respond in $language language.',
        },
        {
          'role': 'user',
          'content': 'Generate personalized activities for $childName (${ageInMonths} months old). '
              'Interests: ${interests.join(", ")}. Current weather: $weather. '
              'Provide 3-5 engaging, safe activities.',
        }
      ],
      'max_tokens': 1200,
      'temperature': 0.8,
    };
  }

  // 🔄 Response parsing methods
  Map<String, dynamic> _parseBehaviorAnalysisResponse(Map<String, dynamic> responseData) {
    try {
      final content = responseData['choices'][0]['message']['content'];
      final parsedContent = jsonDecode(content);

      return {
        'type': 'behavior_analysis',
        'analysis': parsedContent['analysis'] ?? 'No analysis available',
        'triggers': List<String>.from(parsedContent['triggers'] ?? []),
        'strategies': List<String>.from(parsedContent['strategies'] ?? []),
        'alerts': List<String>.from(parsedContent['alerts'] ?? []),
        'positivePatterns': List<String>.from(parsedContent['positivePatterns'] ?? []),
        'confidence': 0.9,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
    } catch (e) {
      debugPrint('Failed to parse behavior analysis response: $e');
      return _createErrorResult('behavior_analysis', e);
    }
  }

  Map<String, dynamic> _parsePredictiveInsightsResponse(Map<String, dynamic> responseData) {
    try {
      final content = responseData['choices'][0]['message']['content'];
      final parsedContent = jsonDecode(content);

      return {
        'type': 'predictive_insights',
        'nextMilestones': List<String>.from(parsedContent['nextMilestones'] ?? []),
        'timeline': parsedContent['timeline'] ?? 'No timeline available',
        'recommendations': List<String>.from(parsedContent['recommendations'] ?? []),
        'riskFactors': List<String>.from(parsedContent['riskFactors'] ?? []),
        'strengths': List<String>.from(parsedContent['strengths'] ?? []),
        'confidence': 0.85,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
    } catch (e) {
      debugPrint('Failed to parse predictive insights response: $e');
      return _createErrorResult('predictive_insights', e);
    }
  }

  Map<String, dynamic> _parsePersonalizedActivitiesResponse(Map<String, dynamic> responseData) {
    try {
      final content = responseData['choices'][0]['message']['content'];
      final parsedContent = jsonDecode(content);

      return {
        'type': 'personalized_activities',
        'activities': List<Map<String, dynamic>>.from(parsedContent['activities'] ?? []),
        'safetyTips': List<String>.from(parsedContent['safetyTips'] ?? []),
        'confidence': 0.9,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
    } catch (e) {
      debugPrint('Failed to parse personalized activities response: $e');
      return _createErrorResult('personalized_activities', e);
    }
  }

  // 💾 Cache management methods
  Future<Map<String, dynamic>?> _getCachedResult(String cacheKey) async {
    try {
      final cached = await _cacheService.get('ai_$cacheKey');
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

  Future<void> _cacheResult(String cacheKey, Map<String, dynamic> result, {Duration? duration}) async {
    try {
      await _cacheService.set(
        'ai_$cacheKey',
        result,
        duration: duration ?? const Duration(days: 1),
      );
    } catch (e) {
      debugPrint('Cache storage error: $e');
    }
  }

  // 🚫 Fallback methods
  Map<String, dynamic> _getFallbackBehaviorAnalysis(String language) {
    return {
      'type': 'behavior_analysis',
      'analysis': language == 'ru' ? 'Анализ поведения недоступен без API ключа' : 'Behavior analysis unavailable without API key',
      'triggers': <String>[],
      'strategies': <String>[],
      'alerts': <String>[],
      'positivePatterns': <String>[],
      'confidence': 0.0,
      'fallback': true,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  Map<String, dynamic> _getFallbackPredictiveInsights(String language) {
    return {
      'type': 'predictive_insights',
      'nextMilestones': <String>[],
      'timeline': language == 'ru' ? 'Прогнозы недоступны без API ключа' : 'Predictions unavailable without API key',
      'recommendations': <String>[],
      'riskFactors': <String>[],
      'strengths': <String>[],
      'confidence': 0.0,
      'fallback': true,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  Map<String, dynamic> _getFallbackPersonalizedActivities(int ageInMonths, String language) {
    final isRussian = language == 'ru';
    final activities = _getBasicActivitiesForAge(ageInMonths, isRussian);

    return {
      'type': 'personalized_activities',
      'activities': activities,
      'safetyTips': isRussian
        ? ['Всегда присматривайте за ребенком', 'Убедитесь в безопасности материалов']
        : ['Always supervise your child', 'Ensure materials are safe'],
      'confidence': 0.5,
      'fallback': true,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  List<Map<String, dynamic>> _getBasicActivitiesForAge(int ageInMonths, bool isRussian) {
    if (ageInMonths <= 12) {
      return isRussian ? [
        {'title': 'Пение песенок', 'description': 'Пойте простые мелодии', 'duration': '10-15 минут'},
      ] : [
        {'title': 'Singing songs', 'description': 'Sing simple melodies', 'duration': '10-15 minutes'},
      ];
    } else if (ageInMonths <= 36) {
      return isRussian ? [
        {'title': 'Рисование пальчиками', 'description': 'Творческая деятельность', 'duration': '20-30 минут'},
      ] : [
        {'title': 'Finger painting', 'description': 'Creative activity', 'duration': '20-30 minutes'},
      ];
    } else {
      return isRussian ? [
        {'title': 'Простые головоломки', 'description': 'Развитие логики', 'duration': '30-45 минут'},
      ] : [
        {'title': 'Simple puzzles', 'description': 'Logic development', 'duration': '30-45 minutes'},
      ];
    }
  }

  Map<String, dynamic> _createErrorResult(String type, Object error) {
    return {
      'type': type,
      'error': error.toString(),
      'confidence': 0.0,
      'fallback': true,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// 🧹 Proper resource cleanup
  void dispose() {
    // Cancel all active requests
    for (final cancelToken in _activeCancellationTokens.values) {
      if (!cancelToken.isCancelled) {
        cancelToken.cancel('Service disposed');
      }
    }
    _activeCancellationTokens.clear();

    // Cancel all debounce timers
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();

    debugPrint('AdvancedAIService disposed');
  }

  /// 🚫 Cancel specific request
  void cancelRequest(String requestId) {
    final cancelToken = _activeCancellationTokens[requestId];
    if (cancelToken != null && !cancelToken.isCancelled) {
      cancelToken.cancel('Request cancelled by user');
      _activeCancellationTokens.remove(requestId);
    }
  }
}