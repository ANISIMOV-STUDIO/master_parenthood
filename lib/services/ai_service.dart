// lib/services/ai_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'cache_service.dart';

class AIService {
  // Для продакшена используйте Firebase Remote Config или переменные окружения
  // Временно можно установить ключ здесь для тестирования
  static const String _apiKey = String.fromEnvironment(
    'OPENAI_API_KEY',
    defaultValue: '', // Установите ваш ключ здесь или через --dart-define
  );

  static const String _apiUrl = 'https://api.openai.com/v1/chat/completions';

  // Проверка наличия API ключа
  static bool get hasApiKey => _apiKey.isNotEmpty;

  // Генерация персонализированной сказки
  static Future<String> generateStory({
    required String childName,
    required String theme,
    required String language,
  }) async {
    // Проверяем кэш
    final cachedStory = await CacheService.getCachedStory(
      childName: childName,
      theme: theme,
      language: language,
    );
    
    if (cachedStory != null) {
      debugPrint('📦 Story loaded from cache');
      return cachedStory;
    }
    
    if (!hasApiKey) {
      debugPrint('⚠️ OpenAI API key not configured');
      return _getFallbackStory(childName, theme, language);
    }

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a creative children\'s story writer. '
                  'Create short, engaging, and age-appropriate stories for 2-3 year old children. '
                  'Stories should be positive, educational, and fun. '
                  'Use simple language and include the child\'s name throughout the story. '
                  'Keep stories under 150 words. '
                  'Respond in $language language.',
            },
            {
              'role': 'user',
              'content': 'Create a bedtime story for a child named $childName about $theme.',
            }
          ],
          'temperature': 0.8,
          'max_tokens': 200,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Connection timeout. Please check your internet connection.');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final story = data['choices'][0]['message']['content'];
        
        // Сохраняем в кэш
        await CacheService.cacheStory(
          childName: childName,
          theme: theme,
          story: story,
          language: language,
        );
        
        return story;
      } else if (response.statusCode == 401) {
        throw Exception('Invalid API key');
      } else if (response.statusCode == 429) {
        throw Exception('Rate limit exceeded. Please try again later.');
      } else if (response.statusCode >= 500) {
        throw Exception('Server error. Please try again later.');
      } else {
        throw Exception('Failed to generate story: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      debugPrint('Network error: $e');
      throw Exception('Network error. Please check your internet connection.');
    } catch (e) {
      debugPrint('Error generating story: $e');
      if (e.toString().contains('Failed host lookup') || 
          e.toString().contains('SocketException')) {
        throw Exception('No internet connection. Please check your connection and try again.');
      }
      rethrow;
    }
  }

  // Получение советов по воспитанию
  static Future<String> getParentingAdvice({
    required String topic,
    required String childAge,
    required String language,
  }) async {
    // Проверяем кэш
    final cachedAdvice = await CacheService.getCachedAdvice(
      topic: topic,
      childAge: childAge,
      language: language,
    );
    
    if (cachedAdvice != null) {
      debugPrint('📦 Advice loaded from cache');
      return cachedAdvice;
    }
    
    if (!hasApiKey) {
      return _getFallbackAdvice(topic, childAge, language);
    }

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a professional child development expert and parenting counselor. '
                  'Provide practical, evidence-based advice that is supportive and non-judgmental. '
                  'Keep responses concise (2-3 paragraphs) and actionable. '
                  'Consider child\'s age when giving advice. '
                  'Respond in $language language.',
            },
            {
              'role': 'user',
              'content': 'I have a $childAge old child. I need advice about: $topic',
            }
          ],
          'temperature': 0.7,
          'max_tokens': 250,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Connection timeout. Please check your internet connection.');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final advice = data['choices'][0]['message']['content'];
        
        // Сохраняем в кэш
        await CacheService.cacheAdvice(
          topic: topic,
          childAge: childAge,
          advice: advice,
          language: language,
        );
        
        return advice;
      } else if (response.statusCode == 401) {
        throw Exception('Invalid API key');
      } else if (response.statusCode == 429) {
        throw Exception('Rate limit exceeded. Please try again later.');
      } else if (response.statusCode >= 500) {
        throw Exception('Server error. Please try again later.');
      } else {
        throw Exception('Failed to get advice: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      debugPrint('Network error: $e');
      throw Exception('Network error. Please check your internet connection.');
    } catch (e) {
      debugPrint('Error getting parenting advice: $e');
      if (e.toString().contains('Failed host lookup') || 
          e.toString().contains('SocketException')) {
        throw Exception('No internet connection. Please check your connection and try again.');
      }
      rethrow;
    }
  }

  // Получение развивающих советов
  static Future<Map<String, dynamic>> getDevelopmentAnalysis({
    required String childName,
    required int ageInMonths,
    required String language,
  }) async {
    if (!hasApiKey) {
      return _getFallbackAnalysis(language);
    }

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a child development expert. '
                  'Provide brief, practical analysis and suggestions for parents. '
                  'Focus on age-appropriate activities and milestones. '
                  'Be encouraging and supportive. '
                  'Respond in $language language as JSON with structure: '
                  '{"summary": "string", "strengths": ["string"], "suggestions": ["string"]}',
            },
            {
              'role': 'user',
              'content': 'Provide development analysis for $childName who is $ageInMonths months old.',
            }
          ],
          'temperature': 0.7,
          'max_tokens': 300,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Connection timeout. Please check your internet connection.');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        return jsonDecode(content);
      } else if (response.statusCode == 401) {
        throw Exception('Invalid API key');
      } else if (response.statusCode == 429) {
        throw Exception('Rate limit exceeded. Please try again later.');
      } else if (response.statusCode >= 500) {
        throw Exception('Server error. Please try again later.');
      } else {
        throw Exception('Failed to get analysis: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      debugPrint('Network error: $e');
      return _getFallbackAnalysis(language);
    } catch (e) {
      debugPrint('Error getting development analysis: $e');
      if (e.toString().contains('Failed host lookup') || 
          e.toString().contains('SocketException')) {
        return _getFallbackAnalysis(language);
      }
      return _getFallbackAnalysis(language);
    }
  }

  // Генерация активности для темы дня
  static Future<String> generateTopicActivity({
    required String topic,
    required String ageGroup,
    required String language,
  }) async {
    if (!hasApiKey) {
      return _getFallbackTopicActivity(topic, ageGroup, language);
    }

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a child development expert specializing in age-appropriate activities. '
                  'Create practical, engaging, and safe activities for children. '
                  'Activities should be easy to do at home with common materials. '
                  'Keep suggestions concise (2-3 sentences) and action-oriented. '
                  'Respond in $language language.',
            },
            {
              'role': 'user',
              'content': 'Create an activity for children aged $ageGroup related to "$topic". '
                  'The activity should help develop this skill or explore this topic.',
            }
          ],
          'temperature': 0.8,
          'max_tokens': 150,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Connection timeout. Please check your internet connection.');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].trim();
      } else if (response.statusCode == 401) {
        throw Exception('Invalid API key');
      } else if (response.statusCode == 429) {
        throw Exception('Rate limit exceeded. Please try again later.');
      } else if (response.statusCode >= 500) {
        throw Exception('Server error. Please try again later.');
      } else {
        throw Exception('Failed to generate activity: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      debugPrint('Network error: $e');
      return _getFallbackTopicActivity(topic, ageGroup, language);
    } catch (e) {
      debugPrint('Error generating topic activity: $e');
      if (e.toString().contains('Failed host lookup') || 
          e.toString().contains('SocketException')) {
        return _getFallbackTopicActivity(topic, ageGroup, language);
      }
      return _getFallbackTopicActivity(topic, ageGroup, language);
    }
  }

  // ===== ЗАПАСНЫЕ ВАРИАНТЫ (FALLBACK) =====

  // Запасная сказка
  static String _getFallbackStory(String childName, String theme, String language) {
    final stories = {
      'en': 'Once upon a time, $childName went on a magical adventure about $theme. '
          'They discovered wonderful things and made new friends. '
          'After a day full of joy and learning, $childName returned home '
          'happy and ready for sweet dreams. The end.',
      'ru': 'Жил-был малыш по имени $childName. Однажды $childName отправился '
          'в волшебное путешествие, где узнал много интересного про $theme. '
          'По пути встретил новых друзей и увидел удивительные вещи. '
          'Вечером $childName вернулся домой счастливый и довольный. '
          'И снились ему только хорошие сны.',
      'es': 'Había una vez un niño llamado $childName que fue a una aventura mágica sobre $theme. '
          'Descubrió cosas maravillosas e hizo nuevos amigos. '
          'Después de un día lleno de alegría, $childName volvió a casa '
          'feliz y listo para dulces sueños.',
      'fr': 'Il était une fois $childName qui partit dans une aventure magique sur $theme. '
          'Il découvrit des choses merveilleuses et se fit de nouveaux amis. '
          'Après une journée pleine de joie, $childName rentra à la maison '
          'heureux et prêt pour de doux rêves.',
      'de': 'Es war einmal $childName, der auf ein magisches Abenteuer über $theme ging. '
          'Er entdeckte wunderbare Dinge und fand neue Freunde. '
          'Nach einem Tag voller Freude kehrte $childName glücklich nach Hause zurück '
          'und war bereit für süße Träume.',
    };

    return stories[language] ?? stories['en']!;
  }

  // Запасные советы
  static String _getFallbackAdvice(String topic, String childAge, String language) {
    final advice = {
      'en': 'Every child develops at their own pace. For a $childAge old child, '
          'it\'s important to be patient and supportive. Regarding "$topic", '
          'try to create a positive environment, establish routines, '
          'and celebrate small achievements. If you have concerns, '
          'consult with your pediatrician.',
      'ru': 'Каждый ребенок развивается в своем темпе. Для ребенка возраста $childAge '
          'важно проявлять терпение и поддержку. Касательно темы "$topic", '
          'старайтесь создавать позитивную атмосферу, устанавливать режим дня '
          'и отмечать даже маленькие достижения. При беспокойстве '
          'обратитесь к педиатру.',
    };

    return advice[language] ?? advice['en']!;
  }

  // Запасные варианты анализа
  static Map<String, dynamic> _getFallbackAnalysis(String language) {
    final analysis = {
      'en': {
        'summary': 'Your child is developing well and reaching age-appropriate milestones.',
        'strengths': [
          'Good physical development',
          'Active exploration of the world',
          'Language skills developing'
        ],
        'suggestions': [
          'Continue reading books together',
          'Encourage independence',
          'Play educational games'
        ],
      },
      'ru': {
        'summary': 'Ваш ребенок хорошо развивается и достигает соответствующих возрасту вех.',
        'strengths': [
          'Хорошее физическое развитие',
          'Активное исследование мира',
          'Развитие речевых навыков'
        ],
        'suggestions': [
          'Продолжайте читать книги вместе',
          'Поощряйте самостоятельность',
          'Играйте в развивающие игры'
        ],
      },
      'es': {
        'summary': 'Su hijo se está desarrollando bien y alcanzando hitos apropiados para su edad.',
        'strengths': [
          'Buen desarrollo físico',
          'Exploración activa del mundo',
          'Desarrollo de habilidades lingüísticas'
        ],
        'suggestions': [
          'Continúe leyendo libros juntos',
          'Fomente la independencia',
          'Juegue juegos educativos'
        ],
      },
      'fr': {
        'summary': 'Votre enfant se développe bien et atteint les étapes appropriées à son âge.',
        'strengths': [
          'Bon développement physique',
          'Exploration active du monde',
          'Développement des compétences linguistiques'
        ],
        'suggestions': [
          'Continuez à lire des livres ensemble',
          'Encouragez l\'indépendance',
          'Jouez à des jeux éducatifs'
        ],
      },
      'de': {
        'summary': 'Ihr Kind entwickelt sich gut und erreicht altersgerechte Meilensteine.',
        'strengths': [
          'Gute körperliche Entwicklung',
          'Aktive Welterkundung',
          'Sprachentwicklung'
        ],
        'suggestions': [
          'Lesen Sie weiterhin gemeinsam Bücher',
          'Fördern Sie die Unabhängigkeit',
          'Spielen Sie Lernspiele'
        ],
      },
    };

    return analysis[language] ?? analysis['en']!;
  }

  // Запасные варианты активностей для темы дня
  static String _getFallbackTopicActivity(String topic, String ageGroup, String language) {
    final activities = {
      'ru': {
        'default': 'Организуйте игру, связанную с темой "$topic". Используйте игрушки, книги или простые материалы, чтобы исследовать эту тему вместе с ребенком. Адаптируйте сложность под возраст $ageGroup.',
        'emotional': 'Поговорите с ребенком о чувствах, используя примеры из повседневной жизни. Покажите, как выражать эмоции словами и помогите ребенку понять свои чувства.',
        'social': 'Организуйте ролевую игру, где ребенок может практиковать социальные навыки. Используйте куклы или мягкие игрушки для разыгрывания различных ситуаций.',
        'cognitive': 'Создайте простую игру-головоломку или задание на сортировку. Используйте предметы разных цветов, форм или размеров для развития логического мышления.',
        'physical': 'Организуйте активную игру с движениями - прыжки, танцы или полосу препятствий из подушек. Это поможет развить координацию и моторику.',
        'creative': 'Предложите ребенку творческое занятие - рисование пальчиками, лепку из пластилина или создание поделки из природных материалов.',
      },
      'en': {
        'default': 'Organize a play activity related to "$topic". Use toys, books, or simple materials to explore this theme together. Adapt the complexity for age $ageGroup.',
        'emotional': 'Talk with your child about feelings using everyday examples. Show how to express emotions with words and help them understand their feelings.',
        'social': 'Set up role-play games where your child can practice social skills. Use dolls or stuffed animals to act out different situations.',
        'cognitive': 'Create a simple puzzle game or sorting activity. Use objects of different colors, shapes, or sizes to develop logical thinking.',
        'physical': 'Organize active play with movements - jumping, dancing, or an obstacle course with pillows. This helps develop coordination and motor skills.',
        'creative': 'Offer creative activities - finger painting, clay modeling, or making crafts from natural materials.',
      },
    };

    // Определяем категорию по ключевым словам в теме
    String category = 'default';
    final topicLower = topic.toLowerCase();

    if (topicLower.contains('эмоц') || topicLower.contains('чувств') || topicLower.contains('emotion') || topicLower.contains('feeling')) {
      category = 'emotional';
    } else if (topicLower.contains('друз') || topicLower.contains('общен') || topicLower.contains('social') || topicLower.contains('friend')) {
      category = 'social';
    } else if (topicLower.contains('логик') || topicLower.contains('мышлен') || topicLower.contains('logic') || topicLower.contains('think')) {
      category = 'cognitive';
    } else if (topicLower.contains('движен') || topicLower.contains('физич') || topicLower.contains('physical') || topicLower.contains('move')) {
      category = 'physical';
    } else if (topicLower.contains('творч') || topicLower.contains('рисов') || topicLower.contains('creative') || topicLower.contains('art')) {
      category = 'creative';
    }

    final langActivities = activities[language] ?? activities['en']!;
    return langActivities[category] ?? langActivities['default']!;
  }
}