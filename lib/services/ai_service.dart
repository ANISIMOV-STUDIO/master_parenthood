// lib/services/ai_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class AIService {
  // Для продакшена используйте Firebase Remote Config или переменные окружения
  // Временно можно установить ключ здесь для тестирования
  static const String _apiKey = const String.fromEnvironment(
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
            },
          ],
          'max_tokens': 300,
          'temperature': 0.8,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        debugPrint('OpenAI API error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to generate story: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error generating story: $e');
      return _getFallbackStory(childName, theme, language);
    }
  }

  // Генерация родительских советов
  static Future<String> getParentingAdvice({
    required String topic,
    required String childAge,
    required String language,
  }) async {
    if (!hasApiKey) {
      debugPrint('⚠️ OpenAI API key not configured');
      return _getFallbackAdvice(topic, language);
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
              'content': 'You are an experienced child development expert and parenting coach. '
                  'Provide evidence-based, practical, and empathetic advice for parents. '
                  'Keep responses concise (under 150 words) and actionable. '
                  'Consider child age when giving advice. '
                  'Respond in $language language.',
            },
            {
              'role': 'user',
              'content': 'My child is $childAge old. I need advice about: $topic',
            },
          ],
          'max_tokens': 300,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        debugPrint('OpenAI API error: ${response.statusCode}');
        throw Exception('Failed to get advice: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting advice: $e');
      return _getFallbackAdvice(topic, language);
    }
  }

  // Анализ развития ребенка
  static Future<Map<String, dynamic>> analyzeDevelopment({
    required Map<String, dynamic> childData,
    required String language,
  }) async {
    if (!hasApiKey) {
      debugPrint('⚠️ OpenAI API key not configured');
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
              'content': 'You are a pediatric development specialist. '
                  'Analyze child development data and provide insights. '
                  'Focus on milestones, areas of strength, and gentle suggestions for improvement. '
                  'Be encouraging and positive. '
                  'Return response as JSON with keys: summary, strengths, suggestions. '
                  'Respond in $language language.',
            },
            {
              'role': 'user',
              'content': 'Analyze this child development data: ${jsonEncode(childData)}',
            },
          ],
          'max_tokens': 400,
          'temperature': 0.6,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];

        // Пытаемся распарсить JSON из ответа
        try {
          return jsonDecode(content);
        } catch (e) {
          return {
            'summary': content,
            'strengths': ['Развивается согласно возрасту'],
            'suggestions': ['Продолжайте в том же духе!'],
          };
        }
      } else {
        throw Exception('Failed to analyze development');
      }
    } catch (e) {
      debugPrint('Error analyzing development: $e');
      return _getFallbackAnalysis(language);
    }
  }

  // Резервные ответы на случай отсутствия API ключа или ошибки
  static String _getFallbackStory(String childName, String theme, String language) {
    final stories = {
      'ru': 'Жил-был маленький $childName, который очень любил $theme. '
          'Однажды $childName отправился в волшебное путешествие. '
          'По дороге $childName встретил добрых друзей, которые помогли найти сокровище - '
          'настоящую дружбу и радость. И все жили долго и счастливо!',
      'en': 'Once upon a time, there was little $childName who loved $theme. '
          'One day, $childName went on a magical adventure. '
          'Along the way, $childName met kind friends who helped find the greatest treasure - '
          'true friendship and joy. And they all lived happily ever after!',
      'es': 'Había una vez un pequeño $childName que amaba $theme. '
          'Un día, $childName emprendió una aventura mágica. '
          'En el camino, $childName conoció amigos amables que ayudaron a encontrar el tesoro más grande: '
          '¡la verdadera amistad y alegría! Y todos vivieron felices para siempre.',
      'fr': 'Il était une fois un petit $childName qui aimait $theme. '
          'Un jour, $childName est parti pour une aventure magique. '
          'En chemin, $childName a rencontré des amis gentils qui ont aidé à trouver le plus grand trésor - '
          'la vraie amitié et la joie. Et ils vécurent heureux pour toujours!',
      'de': 'Es war einmal ein kleiner $childName, der $theme liebte. '
          'Eines Tages ging $childName auf ein magisches Abenteuer. '
          'Auf dem Weg traf $childName freundliche Freunde, die halfen, den größten Schatz zu finden - '
          'wahre Freundschaft und Freude. Und sie lebten glücklich bis ans Ende ihrer Tage!',
    };

    return stories[language] ?? stories['en']!;
  }

  static String _getFallbackAdvice(String topic, String language) {
    final advice = {
      'ru': 'Каждый ребенок развивается в своем темпе. '
          'Важно создать безопасную и любящую среду, где ребенок может исследовать мир. '
          'Будьте терпеливы, последовательны и помните - ваша любовь и поддержка самое важное!',
      'en': 'Every child develops at their own pace. '
          'It\'s important to create a safe and loving environment where your child can explore. '
          'Be patient, consistent, and remember - your love and support matter most!',
      'es': 'Cada niño se desarrolla a su propio ritmo. '
          'Es importante crear un ambiente seguro y amoroso donde su hijo pueda explorar. '
          '¡Sea paciente, consistente y recuerde - su amor y apoyo son lo más importante!',
      'fr': 'Chaque enfant se développe à son propre rythme. '
          'Il est important de créer un environnement sûr et aimant où votre enfant peut explorer. '
          'Soyez patient, cohérent et rappelez-vous - votre amour et votre soutien comptent le plus!',
      'de': 'Jedes Kind entwickelt sich in seinem eigenen Tempo. '
          'Es ist wichtig, eine sichere und liebevolle Umgebung zu schaffen, in der Ihr Kind erkunden kann. '
          'Seien Sie geduldig, konsequent und denken Sie daran - Ihre Liebe und Unterstützung sind am wichtigsten!',
    };

    return advice[language] ?? advice['en']!;
  }

  static Map<String, dynamic> _getFallbackAnalysis(String language) {
    final analysis = {
      'ru': {
        'summary': 'Ваш ребенок развивается хорошо и соответствует возрастным нормам.',
        'strengths': [
          'Хорошее физическое развитие',
          'Активное познание мира',
          'Развитие речевых навыков'
        ],
        'suggestions': [
          'Продолжайте читать книги вместе',
          'Поощряйте самостоятельность',
          'Играйте в развивающие игры'
        ],
      },
      'en': {
        'summary': 'Your child is developing well and meeting age-appropriate milestones.',
        'strengths': [
          'Good physical development',
          'Active world exploration',
          'Language skill development'
        ],
        'suggestions': [
          'Continue reading books together',
          'Encourage independence',
          'Play educational games'
        ],
      },
      'es': {
        'summary': 'Su hijo se está desarrollando bien y cumple con los hitos apropiados para su edad.',
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
}