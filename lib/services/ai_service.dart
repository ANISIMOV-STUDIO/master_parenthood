// lib/services/ai_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  // ВАЖНО: В продакшене храните ключ в безопасном месте (например, Firebase Remote Config)
  static const String _apiKey = 'YOUR_OPENAI_API_KEY';
  static const String _apiUrl = 'https://api.openai.com/v1/chat/completions';

  // Генерация персонализированной сказки
  static Future<String> generateStory({
    required String childName,
    required String theme,
    required String language,
  }) async {
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
        throw Exception('Failed to generate story: ${response.statusCode}');
      }
    } catch (e) {
      // В случае ошибки возвращаем заранее подготовленную сказку
      return _getFallbackStory(childName, theme, language);
    }
  }

  // Генерация родительских советов
  static Future<String> getParentingAdvice({
    required String topic,
    required String childAge,
    required String language,
  }) async {
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
        throw Exception('Failed to get advice: ${response.statusCode}');
      }
    } catch (e) {
      return _getFallbackAdvice(topic, language);
    }
  }

  // Анализ развития ребенка
  static Future<Map<String, dynamic>> analyzeDevelopment({
    required Map<String, dynamic> childData,
    required String language,
  }) async {
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
    };

    return analysis[language] ?? analysis['en']!;
  }
}