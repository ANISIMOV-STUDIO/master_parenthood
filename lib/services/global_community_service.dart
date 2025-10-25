// lib/services/global_community_service.dart
// 🌍 Global Community Service with Weekly Topics & Multilingual Support
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'translation_service.dart';
import 'advanced_ai_service.dart';

class GlobalCommunityService {
  static const String _apiKey = String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');
  static const String _chatApiUrl = 'https://api.openai.com/v1/chat/completions';

  static bool get hasApiKey => _apiKey.isNotEmpty;

  // 📅 Generate weekly topics for global community discussions
  static Future<Map<String, dynamic>> generateWeeklyTopic({
    required String language,
    String? region,
    List<String>? previousTopics,
  }) async {
    try {
      final currentWeek = _getCurrentWeekNumber();
      final cacheKey = 'weekly_topic_${currentWeek}_$language';

      // Check if we already have this week's topic
      final cachedTopic = await _getCachedWeeklyTopic(cacheKey);
      if (cachedTopic != null) {
        return cachedTopic;
      }

      Map<String, dynamic> topic;

      if (hasApiKey) {
        topic = await _generateAIWeeklyTopic(language, region, previousTopics);
      } else {
        topic = _getPresetWeeklyTopic(currentWeek, language);
      }

      // Cache the topic for the week
      await _cacheWeeklyTopic(cacheKey, topic);

      return topic;
    } catch (e) {
      debugPrint('Error generating weekly topic: $e');
      return _getPresetWeeklyTopic(_getCurrentWeekNumber(), language);
    }
  }

  // 💬 Create multilingual community post
  static Future<Map<String, dynamic>> createCommunityPost({
    required String userId,
    required String userName,
    required String content,
    required String userLanguage,
    required String topicId,
    List<String>? mediaUrls,
    Map<String, String>? metadata,
  }) async {
    try {
      final postId = 'post_${DateTime.now().millisecondsSinceEpoch}';

      // Detect language if not specified
      // TODO: Re-enable translation service after fixing dependency injection
      final detectedLanguage = userLanguage; // await TranslationService.detectLanguage(content);

      final post = {
        'id': postId,
        'userId': userId,
        'userName': userName,
        'content': content,
        'originalLanguage': detectedLanguage,
        'userLanguage': userLanguage,
        'topicId': topicId,
        'mediaUrls': mediaUrls ?? [],
        'metadata': metadata ?? {},
        'timestamp': DateTime.now().toIso8601String(),
        'likes': 0,
        'replies': 0,
        'translations': <String, String>{}, // Will be populated on demand
        'isModerated': false,
        'moderationScore': await _calculateModerationScore(content),
      };

      // Store the post (in real app, this would go to Firebase/database)
      await _storeCommunityPost(post);

      return {
        'success': true,
        'post': post,
        'message': 'Post created successfully',
      };
    } catch (e) {
      debugPrint('Error creating community post: $e');
      return {
        'success': false,
        'error': 'Failed to create post',
      };
    }
  }

  // 📖 Get community posts with real-time translation
  static Future<List<Map<String, dynamic>>> getCommunityPosts({
    required String userLanguage,
    required String userId,
    String? topicId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      // Get posts from storage (mock implementation)
      final allPosts = await _getCommunityPosts(topicId);

      List<Map<String, dynamic>> translatedPosts = [];

      for (Map<String, dynamic> post in allPosts.skip(offset).take(limit)) {
        final originalContent = post['content'] as String;
        final originalLanguage = post['originalLanguage'] as String;

        // Check if translation is needed
        String translatedContent = originalContent;
        bool isTranslated = false;

        if (originalLanguage != userLanguage) {
          // Check if translation already exists
          if (post['translations'][userLanguage] != null) {
            translatedContent = post['translations'][userLanguage];
            isTranslated = true;
          } else {
            // Perform translation
            // TODO: Re-enable translation service after fixing dependency injection
            // final translation = await TranslationService.translateMessage(
            //   message: originalContent,
            //   targetLanguage: userLanguage,
            //   sourceLanguage: originalLanguage,
            // );
            // translatedContent = translation['translatedText'];
            // isTranslated = translation['originalText'] != translation['translatedText'];

            // Temporary: use original content without translation
            translatedContent = originalContent;
            isTranslated = false;

            // Cache translation in post
            post['translations'][userLanguage] = translatedContent;
            await _updatePostTranslation(post['id'], userLanguage, translatedContent);
          }
        }

        translatedPosts.add({
          ...post,
          'displayContent': translatedContent,
          'originalContent': originalContent,
          'isTranslated': isTranslated,
          'translatedTo': userLanguage,
          'userCanLike': post['userId'] != userId,
          'timeAgo': _getTimeAgo(DateTime.parse(post['timestamp'])),
        });
      }

      return translatedPosts;
    } catch (e) {
      debugPrint('Error getting community posts: $e');
      return [];
    }
  }

  // 🗣️ Create voice message post with transcription
  static Future<Map<String, dynamic>> createVoicePost({
    required String userId,
    required String userName,
    required String audioPath,
    required String userLanguage,
    required String topicId,
  }) async {
    try {
      // In a real implementation, this would transcribe the audio
      final transcription = await _transcribeAudio(audioPath, userLanguage);

      final post = await createCommunityPost(
        userId: userId,
        userName: userName,
        content: transcription,
        userLanguage: userLanguage,
        topicId: topicId,
        metadata: {
          'type': 'voice',
          'audioPath': audioPath,
          'transcription': transcription,
        },
      );

      return post;
    } catch (e) {
      debugPrint('Error creating voice post: $e');
      return {
        'success': false,
        'error': 'Failed to create voice post',
      };
    }
  }

  // 👍 Interact with community posts
  static Future<Map<String, dynamic>> interactWithPost({
    required String postId,
    required String userId,
    required String action, // 'like', 'unlike', 'reply', 'report'
    String? replyContent,
    String? userLanguage,
  }) async {
    try {
      final post = await _getPostById(postId);
      if (post == null) {
        return {'success': false, 'error': 'Post not found'};
      }

      switch (action) {
        case 'like':
          await _addLikeToPost(postId, userId);
          return {'success': true, 'message': 'Post liked'};

        case 'unlike':
          await _removeLikeFromPost(postId, userId);
          return {'success': true, 'message': 'Like removed'};

        case 'reply':
          if (replyContent == null || userLanguage == null) {
            return {'success': false, 'error': 'Reply content and language required'};
          }

          final reply = await _createReply(
            postId: postId,
            userId: userId,
            content: replyContent,
            userLanguage: userLanguage,
          );

          return {'success': true, 'reply': reply};

        case 'report':
          await _reportPost(postId, userId);
          return {'success': true, 'message': 'Post reported for review'};

        default:
          return {'success': false, 'error': 'Unknown action'};
      }
    } catch (e) {
      debugPrint('Error interacting with post: $e');
      return {'success': false, 'error': 'Interaction failed'};
    }
  }

  // 🔍 Search community posts across languages
  static Future<List<Map<String, dynamic>>> searchCommunityPosts({
    required String query,
    required String userLanguage,
    required String userId,
    List<String>? languages,
    String? topicId,
  }) async {
    try {
      // Translate query to multiple languages for broader search
      final translatedQueries = <String, String>{};

      if (languages != null) {
        for (String language in languages) {
          if (language != userLanguage) {
            // TODO: Re-enable translation service after fixing dependency injection
            // final translation = await TranslationService.translateMessage(
            //   message: query,
            //   targetLanguage: language,
            //   sourceLanguage: userLanguage,
            // );
            // translatedQueries[language] = translation['translatedText'];

            // Temporary: use original query without translation
            translatedQueries[language] = query;
          }
        }
      }

      // Search posts using original and translated queries
      final results = await _searchPosts(query, translatedQueries, topicId);

      // Translate results to user's language
      final translatedResults = await getCommunityPosts(
        userLanguage: userLanguage,
        userId: userId,
        topicId: topicId,
        limit: results.length,
      );

      return translatedResults
          .where((post) => _postMatchesSearch(post, query, translatedQueries))
          .toList();

    } catch (e) {
      debugPrint('Error searching community posts: $e');
      return [];
    }
  }

  // 📊 Get community statistics
  static Future<Map<String, dynamic>> getCommunityStats({
    String? topicId,
    String? language,
  }) async {
    try {
      final posts = await _getCommunityPosts(topicId);

      final stats = {
        'totalPosts': posts.length,
        'totalUsers': posts.map((p) => p['userId']).toSet().length,
        'languageDistribution': <String, int>{},
        'topContributors': <String, int>{},
        'averagePostsPerWeek': 0.0,
        'mostActiveHours': <int, int>{},
      };

      // Calculate language distribution
      final langDist = stats['languageDistribution'] as Map<String, int>;
      for (final post in posts) {
        final lang = post['originalLanguage'] as String;
        langDist[lang] = (langDist[lang] ?? 0) + 1;
      }

      // Calculate top contributors
      final topContrib = stats['topContributors'] as Map<String, int>;
      for (final post in posts) {
        final userName = post['userName'] as String;
        topContrib[userName] = (topContrib[userName] ?? 0) + 1;
      }

      // Calculate activity by hour
      final activeHours = stats['mostActiveHours'] as Map<int, int>;
      for (final post in posts) {
        final timestamp = DateTime.parse(post['timestamp']);
        final hour = timestamp.hour;
        activeHours[hour] = (activeHours[hour] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      debugPrint('Error getting community stats: $e');
      return {};
    }
  }

  // ============= PRIVATE HELPER METHODS =============

  static Future<Map<String, dynamic>> _generateAIWeeklyTopic(
    String language,
    String? region,
    List<String>? previousTopics
  ) async {
    try {
      final response = await http.post(
        Uri.parse(_chatApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a global parenting community manager. '
                  'Create engaging weekly discussion topics for international parents. '
                  'Consider cultural diversity and universal parenting experiences. '
                  'Return JSON: {"title": "string", "description": "string", '
                  '"questions": ["string"], "activities": ["string"], "culturalNote": "string"}. '
                  'Respond in $language language.',
            },
            {
              'role': 'user',
              'content': 'Generate a weekly topic for international parents. '
                  '${region != null ? "Focus on $region region. " : ""}'
                  '${previousTopics != null ? "Avoid these recent topics: ${previousTopics.join(", ")}. " : ""}'
                  'Make it engaging and culturally inclusive.',
            }
          ],
          'temperature': 0.8,
          'max_tokens': 400,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        final topic = jsonDecode(content);

        return {
          ...topic,
          'id': 'topic_${_getCurrentWeekNumber()}',
          'week': _getCurrentWeekNumber(),
          'startDate': _getWeekStartDate().toIso8601String(),
          'endDate': _getWeekEndDate().toIso8601String(),
          'language': language,
          'region': region,
          'isActive': true,
        };
      }
      return _getPresetWeeklyTopic(_getCurrentWeekNumber(), language);
    } catch (e) {
      debugPrint('Error generating AI weekly topic: $e');
      return _getPresetWeeklyTopic(_getCurrentWeekNumber(), language);
    }
  }

  static Map<String, dynamic> _getPresetWeeklyTopic(int weekNumber, String language) {
    final topics = {
      'en': [
        {
          'title': 'Cultural Lullabies Around the World',
          'description': 'Share and discover lullabies from your culture! How do parents worldwide help their children sleep?',
          'questions': [
            'What lullabies did your parents sing to you?',
            'Are there special bedtime rituals in your culture?',
            'How do you adapt traditional songs for modern times?'
          ],
          'activities': [
            'Record yourself singing a lullaby',
            'Share the meaning behind your favorite lullaby',
            'Learn a lullaby from another culture'
          ],
          'culturalNote': 'Music transcends language barriers and connects us all as parents.'
        },
        {
          'title': 'First Foods and Family Traditions',
          'description': 'Exploring how different cultures introduce solid foods to babies.',
          'questions': [
            'What was your baby\'s first solid food?',
            'Are there traditional first foods in your culture?',
            'How do you handle picky eating across cultures?'
          ],
          'activities': [
            'Share a photo of a traditional baby food',
            'Exchange recipes with parents from other countries',
            'Create a multicultural meal for your family'
          ],
          'culturalNote': 'Food is love in every language and culture.'
        },
      ],
      'ru': [
        {
          'title': 'Колыбельные мира: Традиции и современность',
          'description': 'Делимся колыбельными из разных культур! Как родители по всему миру укладывают детей спать?',
          'questions': [
            'Какие колыбельные пели вам ваши родители?',
            'Есть ли особые ритуалы отхода ко сну в вашей культуре?',
            'Как вы адаптируете традиционные песни для современности?'
          ],
          'activities': [
            'Запишите, как вы поете колыбельную',
            'Поделитесь смыслом любимой колыбельной',
            'Выучите колыбельную из другой культуры'
          ],
          'culturalNote': 'Музыка преодолевает языковые барьеры и объединяет всех родителей.'
        },
      ],
      'es': [
        {
          'title': 'Canciones de cuna del mundo',
          'description': '¡Compartamos canciones de cuna de nuestras culturas! ¿Cómo ayudan los padres de todo el mundo a dormir a sus hijos?',
          'questions': [
            '¿Qué canciones de cuna te cantaban tus padres?',
            '¿Hay rituales especiales para dormir en tu cultura?',
            '¿Cómo adaptas las canciones tradicionales a los tiempos modernos?'
          ],
          'activities': [
            'Grábate cantando una canción de cuna',
            'Comparte el significado de tu canción de cuna favorita',
            'Aprende una canción de cuna de otra cultura'
          ],
          'culturalNote': 'La música trasciende las barreras del idioma y nos conecta como padres.'
        },
      ],
    };

    final langTopics = topics[language] ?? topics['en']!;
    final topicIndex = (weekNumber - 1) % langTopics.length;
    final topic = langTopics[topicIndex];

    return {
      ...topic,
      'id': 'topic_$weekNumber',
      'week': weekNumber,
      'startDate': _getWeekStartDate().toIso8601String(),
      'endDate': _getWeekEndDate().toIso8601String(),
      'language': language,
      'isActive': true,
    };
  }

  static int _getCurrentWeekNumber() {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final daysDifference = now.difference(startOfYear).inDays;
    return ((daysDifference / 7).floor() + 1).clamp(1, 52);
  }

  static DateTime _getWeekStartDate() {
    final now = DateTime.now();
    final weekday = now.weekday;
    return now.subtract(Duration(days: weekday - 1));
  }

  static DateTime _getWeekEndDate() {
    final start = _getWeekStartDate();
    return start.add(const Duration(days: 6));
  }

  static Future<Map<String, dynamic>?> _getCachedWeeklyTopic(String cacheKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(cacheKey);
      if (cachedJson != null) {
        return json.decode(cachedJson) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<void> _cacheWeeklyTopic(String cacheKey, Map<String, dynamic> topic) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(cacheKey, jsonEncode(topic));
    } catch (e) {
      debugPrint('Cache error: $e');
    }
  }

  static Future<double> _calculateModerationScore(String content) async {
    // Simple content moderation scoring
    final lowercaseContent = content.toLowerCase();

    double score = 1.0; // Start with perfect score

    // Check for potentially problematic content
    final problematicWords = ['spam', 'hate', 'inappropriate'];
    for (String word in problematicWords) {
      if (lowercaseContent.contains(word)) {
        score -= 0.3;
      }
    }

    // Check length (very short posts might be spam)
    if (content.length < 10) {
      score -= 0.2;
    }

    // Check for excessive caps
    final capsCount = content.split('').where((c) => c == c.toUpperCase()).length;
    if (capsCount > content.length * 0.5) {
      score -= 0.1;
    }

    return score.clamp(0.0, 1.0);
  }

  static Future<void> _storeCommunityPost(Map<String, dynamic> post) async {
    // Mock implementation - in real app, store in database
    final prefs = await SharedPreferences.getInstance();
    final postsJson = prefs.getString('community_posts') ?? '[]';
    final posts = jsonDecode(postsJson) as List<dynamic>;
    posts.add(post);
    await prefs.setString('community_posts', jsonEncode(posts));
  }

  static Future<List<Map<String, dynamic>>> _getCommunityPosts(String? topicId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final postsJson = prefs.getString('community_posts') ?? '[]';
      final posts = jsonDecode(postsJson) as List<dynamic>;

      List<Map<String, dynamic>> result = posts.cast<Map<String, dynamic>>();

      if (topicId != null) {
        result = result.where((post) => post['topicId'] == topicId).toList();
      }

      // Sort by timestamp (newest first)
      result.sort((a, b) => DateTime.parse(b['timestamp']).compareTo(DateTime.parse(a['timestamp'])));

      return result;
    } catch (e) {
      return [];
    }
  }

  static Future<String> _transcribeAudio(String audioPath, String language) async {
    // Mock transcription - in real app, use Whisper API or similar
    await Future.delayed(const Duration(seconds: 1));
    return 'Voice message transcription would appear here in multiple languages.';
  }

  static String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }

  static Future<Map<String, dynamic>?> _getPostById(String postId) async {
    final posts = await _getCommunityPosts(null);
    try {
      return posts.firstWhere((post) => post['id'] == postId);
    } catch (e) {
      return null;
    }
  }

  static Future<void> _addLikeToPost(String postId, String userId) async {
    // Mock implementation - update like count
  }

  static Future<void> _removeLikeFromPost(String postId, String userId) async {
    // Mock implementation - remove like
  }

  static Future<Map<String, dynamic>> _createReply(
      {required String postId, required String userId, required String content, required String userLanguage}) async {
    return {
      'id': 'reply_${DateTime.now().millisecondsSinceEpoch}',
      'postId': postId,
      'userId': userId,
      'content': content,
      'language': userLanguage,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  static Future<void> _reportPost(String postId, String userId) async {
    // Mock implementation - report post for moderation
  }

  static Future<void> _updatePostTranslation(String postId, String language, String translation) async {
    // Mock implementation - update post with translation
  }

  static Future<List<Map<String, dynamic>>> _searchPosts(
      String query, Map<String, String> translatedQueries, String? topicId) async {
    final posts = await _getCommunityPosts(topicId);
    return posts
        .where((post) =>
            post['content'].toString().toLowerCase().contains(query.toLowerCase()) ||
            translatedQueries.values.any((tq) =>
                post['content'].toString().toLowerCase().contains(tq.toLowerCase())))
        .toList();
  }

  static bool _postMatchesSearch(Map<String, dynamic> post, String query, Map<String, String> translatedQueries) {
    final content = (post['displayContent'] ?? post['content']).toString().toLowerCase();
    return content.contains(query.toLowerCase()) ||
           translatedQueries.values.any((tq) => content.contains(tq.toLowerCase()));
  }
}