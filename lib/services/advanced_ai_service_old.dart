// lib/services/advanced_ai_service.dart
// 🚀 Advanced AI Service with 2025 trending features
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'cache_service.dart';

class AdvancedAIService {
  static const String _apiKey = String.fromEnvironment(
    'OPENAI_API_KEY',
    defaultValue: '',
  );
  static const String _apiUrl = 'https://api.openai.com/v1/chat/completions';
  static const String _imageApiUrl = 'https://api.openai.com/v1/images/generations';

  static bool get hasApiKey => _apiKey.isNotEmpty;

  // 🤖 Real-time Behavioral Analysis AI
  static Future<Map<String, dynamic>> analyzeBehavior({
    required String childName,
    required int ageInMonths,
    required List<String> recentBehaviors,
    required String language,
  }) async {
    final cacheKey = 'behavior_analysis_${childName}_${ageInMonths}_${recentBehaviors.join('_')}';

    if (!hasApiKey) {
      return _getFallbackBehaviorAnalysis(language);
    }

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
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
              'content': 'Analyze behavior for $childName (${ageInMonths} months old). '
                  'Recent behaviors: ${recentBehaviors.join(", ")}. '
                  'Provide real-time insights and strategies.',
            }
          ],
          'temperature': 0.7,
          'max_tokens': 400,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        return jsonDecode(content);
      }
      return _getFallbackBehaviorAnalysis(language);
    } catch (e) {
      debugPrint('Error in behavior analysis: $e');
      return _getFallbackBehaviorAnalysis(language);
    }
  }

  // 🎯 Predictive Development Insights
  static Future<Map<String, dynamic>> predictDevelopment({
    required String childName,
    required Map<String, dynamic> currentMilestones,
    required int ageInMonths,
    required String language,
  }) async {
    if (!hasApiKey) {
      return _getFallbackPredictiveAnalysis(language);
    }

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a predictive child development AI expert. '
                  'Analyze current milestones and predict future development paths. '
                  'Provide evidence-based insights and recommendations. '
                  'Return JSON: {"nextMilestones": ["string"], "timeframe": "string", '
                  '"recommendations": ["string"], "watchFor": ["string"], "strengths": ["string"]}. '
                  'Respond in $language language.',
            },
            {
              'role': 'user',
              'content': 'Predict development for $childName (${ageInMonths} months). '
                  'Current milestones: ${jsonEncode(currentMilestones)}. '
                  'What should parents expect and prepare for?',
            }
          ],
          'temperature': 0.6,
          'max_tokens': 450,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        return jsonDecode(content);
      }
      return _getFallbackPredictiveAnalysis(language);
    } catch (e) {
      debugPrint('Error in predictive analysis: $e');
      return _getFallbackPredictiveAnalysis(language);
    }
  }

  // 🎨 AI-Generated Visual Content
  static Future<Map<String, dynamic>> generateVisualContent({
    required String contentType, // 'coloring_page', 'educational_poster', 'story_illustration'
    required String theme,
    required String ageGroup,
    required String language,
  }) async {
    if (!hasApiKey) {
      return _getFallbackVisualContent(contentType, theme, language);
    }

    try {
      // Generate description for image
      final descriptionResponse = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a children\'s content creator. Create detailed, safe, '
                  'age-appropriate image descriptions for AI generation. '
                  'Focus on simple, colorful, educational content. '
                  'Avoid complex details, text, or potentially harmful elements.',
            },
            {
              'role': 'user',
              'content': 'Create image description for $contentType about "$theme" '
                  'for children aged $ageGroup. Make it simple, colorful, and engaging.',
            }
          ],
          'temperature': 0.8,
          'max_tokens': 200,
        }),
      ).timeout(const Duration(seconds: 30));

      if (descriptionResponse.statusCode == 200) {
        final descData = jsonDecode(descriptionResponse.body);
        final imageDescription = descData['choices'][0]['message']['content'];

        // Generate actual image
        final imageResponse = await http.post(
          Uri.parse(_imageApiUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiKey',
          },
          body: jsonEncode({
            'model': 'dall-e-3',
            'prompt': imageDescription,
            'n': 1,
            'size': '1024x1024',
            'quality': 'standard',
          }),
        ).timeout(const Duration(seconds: 60));

        if (imageResponse.statusCode == 200) {
          final imageData = jsonDecode(imageResponse.body);
          return {
            'success': true,
            'imageUrl': imageData['data'][0]['url'],
            'description': imageDescription,
            'type': contentType,
            'theme': theme,
          };
        }
      }
      return _getFallbackVisualContent(contentType, theme, language);
    } catch (e) {
      debugPrint('Error generating visual content: $e');
      return _getFallbackVisualContent(contentType, theme, language);
    }
  }

  // 💬 Smart Parenting Chat with Context
  static Future<String> chatWithAI({
    required String message,
    required List<Map<String, String>> conversationHistory,
    required Map<String, dynamic> childContext,
    required String language,
  }) async {
    if (!hasApiKey) {
      return _getFallbackChatResponse(message, language);
    }

    try {
      // Build conversation with context
      List<Map<String, String>> messages = [
        {
          'role': 'system',
          'content': 'You are an AI parenting assistant with deep context about the child. '
              'Child context: ${jsonEncode(childContext)}. '
              'Provide personalized, contextual advice. Be empathetic, practical, and supportive. '
              'Remember previous conversation context. Respond in $language language.',
        },
      ];

      // Add conversation history (last 5 messages for context)
      messages.addAll(conversationHistory.take(5));
      messages.add({'role': 'user', 'content': message});

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 300,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      }
      return _getFallbackChatResponse(message, language);
    } catch (e) {
      debugPrint('Error in AI chat: $e');
      return _getFallbackChatResponse(message, language);
    }
  }

  // 📊 Mood & Emotion Analysis
  static Future<Map<String, dynamic>> analyzeMoodAndEmotions({
    required String childName,
    required List<String> moodEntries,
    required List<String> behaviorNotes,
    required String language,
  }) async {
    if (!hasApiKey) {
      return _getFallbackMoodAnalysis(language);
    }

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a child psychology AI specialist. '
                  'Analyze mood patterns and emotional development. '
                  'Provide supportive insights and practical strategies. '
                  'Return JSON: {"moodPattern": "string", "emotionalDevelopment": "string", '
                  '"concerns": ["string"], "strategies": ["string"], "positives": ["string"]}. '
                  'Respond in $language language.',
            },
            {
              'role': 'user',
              'content': 'Analyze mood and emotions for $childName. '
                  'Recent moods: ${moodEntries.join(", ")}. '
                  'Behavior notes: ${behaviorNotes.join(", ")}.',
            }
          ],
          'temperature': 0.6,
          'max_tokens': 400,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        return jsonDecode(content);
      }
      return _getFallbackMoodAnalysis(language);
    } catch (e) {
      debugPrint('Error in mood analysis: $e');
      return _getFallbackMoodAnalysis(language);
    }
  }

  // 🎯 Personalized Learning Activities Generator
  static Future<Map<String, dynamic>> generatePersonalizedActivities({
    required String childName,
    required int ageInMonths,
    required List<String> interests,
    required List<String> skills,
    required String language,
  }) async {
    if (!hasApiKey) {
      return _getFallbackActivities(language);
    }

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a personalized learning activity creator for children. '
                  'Design activities based on child\'s interests, skills, and age. '
                  'Make activities practical, safe, and engaging. '
                  'Return JSON: {"activities": [{"name": "string", "description": "string", '
                  '"materials": ["string"], "duration": "string", "skills": ["string"]}]}. '
                  'Respond in $language language.',
            },
            {
              'role': 'user',
              'content': 'Create personalized activities for $childName (${ageInMonths} months). '
                  'Interests: ${interests.join(", ")}. Current skills: ${skills.join(", ")}. '
                  'Generate 3-5 tailored activities.',
            }
          ],
          'temperature': 0.8,
          'max_tokens': 500,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        return jsonDecode(content);
      }
      return _getFallbackActivities(language);
    } catch (e) {
      debugPrint('Error generating activities: $e');
      return _getFallbackActivities(language);
    }
  }

  // ============= FALLBACK METHODS =============

  static Map<String, dynamic> _getFallbackBehaviorAnalysis(String language) {
    final fallbacks = {
      'en': {
        'analysis': 'Your child is showing normal developmental behaviors for their age.',
        'triggers': ['Hunger', 'Tiredness', 'Overstimulation'],
        'strategies': ['Maintain routine', 'Positive reinforcement', 'Calm environment'],
        'alerts': [],
        'positivePatterns': ['Active exploration', 'Social engagement']
      },
      'ru': {
        'analysis': 'Ваш ребенок демонстрирует нормальное поведение для своего возраста.',
        'triggers': ['Голод', 'Усталость', 'Перевозбуждение'],
        'strategies': ['Поддерживайте режим', 'Позитивное подкрепление', 'Спокойная обстановка'],
        'alerts': [],
        'positivePatterns': ['Активное исследование', 'Социальное взаимодействие']
      },
    };
    return fallbacks[language] ?? fallbacks['en']!;
  }

  static Map<String, dynamic> _getFallbackPredictiveAnalysis(String language) {
    final fallbacks = {
      'en': {
        'nextMilestones': ['Walking improvement', 'Vocabulary expansion', 'Independence'],
        'timeframe': 'Next 2-3 months',
        'recommendations': ['Read daily', 'Encourage exploration', 'Practice patience'],
        'watchFor': ['Regression in skills', 'Communication difficulties'],
        'strengths': ['Curiosity', 'Physical development', 'Social skills']
      },
      'ru': {
        'nextMilestones': ['Улучшение ходьбы', 'Расширение словаря', 'Самостоятельность'],
        'timeframe': 'Следующие 2-3 месяца',
        'recommendations': ['Читайте ежедневно', 'Поощряйте исследования', 'Практикуйте терпение'],
        'watchFor': ['Регресс навыков', 'Трудности общения'],
        'strengths': ['Любознательность', 'Физическое развитие', 'Социальные навыки']
      },
    };
    return fallbacks[language] ?? fallbacks['en']!;
  }

  static Map<String, dynamic> _getFallbackVisualContent(String contentType, String theme, String language) {
    return {
      'success': false,
      'message': language == 'ru'
        ? 'Создание визуального контента недоступно без API ключа'
        : 'Visual content creation unavailable without API key',
      'type': contentType,
      'theme': theme,
    };
  }

  static String _getFallbackChatResponse(String message, String language) {
    final responses = {
      'en': 'I understand your concern. Every child develops at their own pace. '
          'Consider establishing routines and celebrating small achievements. '
          'If you have specific concerns, consult with your pediatrician.',
      'ru': 'Понимаю ваше беспокойство. Каждый ребенок развивается в своем темпе. '
          'Рассмотрите возможность установления режима и празднования маленьких достижений. '
          'При конкретных проблемах обратитесь к педиатру.',
    };
    return responses[language] ?? responses['en']!;
  }

  static Map<String, dynamic> _getFallbackMoodAnalysis(String language) {
    final fallbacks = {
      'en': {
        'moodPattern': 'Normal emotional fluctuations for age',
        'emotionalDevelopment': 'Healthy emotional growth',
        'concerns': [],
        'strategies': ['Validate emotions', 'Teach coping skills', 'Maintain routine'],
        'positives': ['Emotional expression', 'Seeking comfort', 'Social awareness']
      },
      'ru': {
        'moodPattern': 'Нормальные эмоциональные колебания для возраста',
        'emotionalDevelopment': 'Здоровое эмоциональное развитие',
        'concerns': [],
        'strategies': ['Подтверждайте эмоции', 'Обучайте навыкам преодоления', 'Поддерживайте режим'],
        'positives': ['Выражение эмоций', 'Поиск утешения', 'Социальное осознание']
      },
    };
    return fallbacks[language] ?? fallbacks['en']!;
  }

  static Map<String, dynamic> _getFallbackActivities(String language) {
    final fallbacks = {
      'en': {
        'activities': [
          {
            'name': 'Sensory Play',
            'description': 'Explore different textures and materials',
            'materials': ['Rice', 'Water', 'Fabric pieces'],
            'duration': '15-20 minutes',
            'skills': ['Sensory development', 'Fine motor skills']
          },
          {
            'name': 'Color Sorting',
            'description': 'Sort objects by color',
            'materials': ['Colored toys', 'Containers'],
            'duration': '10-15 minutes',
            'skills': ['Cognitive development', 'Color recognition']
          }
        ]
      },
      'ru': {
        'activities': [
          {
            'name': 'Сенсорная игра',
            'description': 'Исследование различных текстур и материалов',
            'materials': ['Рис', 'Вода', 'Кусочки ткани'],
            'duration': '15-20 минут',
            'skills': ['Сенсорное развитие', 'Мелкая моторика']
          },
          {
            'name': 'Сортировка по цветам',
            'description': 'Сортировка предметов по цвету',
            'materials': ['Цветные игрушки', 'Контейнеры'],
            'duration': '10-15 минут',
            'skills': ['Когнитивное развитие', 'Распознавание цветов']
          }
        ]
      },
    };
    return fallbacks[language] ?? fallbacks['en']!;
  }
}