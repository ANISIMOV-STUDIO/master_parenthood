// lib/services/translation_service.dart
// 🌍 Real-time Translation Service for Global Parenting Community
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TranslationService {
  static const String _googleTranslateApiKey = String.fromEnvironment(
    'GOOGLE_TRANSLATE_API_KEY',
    defaultValue: '',
  );
  static const String _translateApiUrl = 'https://translation.googleapis.com/language/translate/v2';
  static const String _detectApiUrl = 'https://translation.googleapis.com/language/translate/v2/detect';

  static bool get hasApiKey => _googleTranslateApiKey.isNotEmpty;

  // 🌍 Auto-detect and translate message for global community
  static Future<Map<String, dynamic>> translateMessage({
    required String message,
    required String targetLanguage,
    String? sourceLanguage,
    bool autoDetect = true,
  }) async {
    try {
      String detectedLanguage = sourceLanguage ?? 'auto';

      // Auto-detect source language if not provided
      if (autoDetect && sourceLanguage == null) {
        detectedLanguage = await _detectLanguage(message);
      }

      // Skip translation if source and target are the same
      if (detectedLanguage == targetLanguage) {
        return {
          'originalText': message,
          'translatedText': message,
          'sourceLanguage': detectedLanguage,
          'targetLanguage': targetLanguage,
          'confidence': 1.0,
          'cached': false,
        };
      }

      // Check cache first
      final cacheKey = '${message.hashCode}_${detectedLanguage}_$targetLanguage';
      final cachedTranslation = await _getCachedTranslation(cacheKey);
      if (cachedTranslation != null) {
        return {
          'originalText': message,
          'translatedText': cachedTranslation,
          'sourceLanguage': detectedLanguage,
          'targetLanguage': targetLanguage,
          'confidence': 0.95,
          'cached': true,
        };
      }

      // Perform translation
      final translatedText = await _performTranslation(
        text: message,
        sourceLanguage: detectedLanguage,
        targetLanguage: targetLanguage,
      );

      // Cache the result
      await _cacheTranslation(cacheKey, translatedText);

      return {
        'originalText': message,
        'translatedText': translatedText,
        'sourceLanguage': detectedLanguage,
        'targetLanguage': targetLanguage,
        'confidence': 0.9,
        'cached': false,
      };

    } catch (e) {
      debugPrint('Translation error: $e');
      return _getFallbackTranslation(message, targetLanguage);
    }
  }

  // 💬 Translate entire conversation thread
  static Future<List<Map<String, dynamic>>> translateConversation({
    required List<Map<String, dynamic>> messages,
    required String targetLanguage,
    required String userId,
  }) async {
    List<Map<String, dynamic>> translatedMessages = [];

    for (Map<String, dynamic> message in messages) {
      final originalText = message['text'] ?? '';
      final senderId = message['senderId'] ?? '';
      final senderLanguage = message['language'] ?? 'auto';

      // Skip translation for user's own messages
      if (senderId == userId) {
        translatedMessages.add({
          ...message,
          'translatedText': originalText,
          'isTranslated': false,
        });
        continue;
      }

      // Translate message
      final translation = await translateMessage(
        message: originalText,
        targetLanguage: targetLanguage,
        sourceLanguage: senderLanguage != 'auto' ? senderLanguage : null,
      );

      translatedMessages.add({
        ...message,
        'translatedText': translation['translatedText'],
        'originalText': translation['originalText'],
        'sourceLanguage': translation['sourceLanguage'],
        'isTranslated': translation['originalText'] != translation['translatedText'],
        'confidence': translation['confidence'],
      });
    }

    return translatedMessages;
  }

  // 🗣️ Real-time language detection for voice messages
  static Future<String> detectLanguage(String text) async {
    return await _detectLanguage(text);
  }

  // 🌐 Get supported languages with native names
  static Map<String, Map<String, String>> getSupportedLanguages() {
    return {
      'en': {'name': 'English', 'nativeName': 'English', 'flag': '🇺🇸'},
      'es': {'name': 'Spanish', 'nativeName': 'Español', 'flag': '🇪🇸'},
      'fr': {'name': 'French', 'nativeName': 'Français', 'flag': '🇫🇷'},
      'de': {'name': 'German', 'nativeName': 'Deutsch', 'flag': '🇩🇪'},
      'it': {'name': 'Italian', 'nativeName': 'Italiano', 'flag': '🇮🇹'},
      'pt': {'name': 'Portuguese', 'nativeName': 'Português', 'flag': '🇵🇹'},
      'ru': {'name': 'Russian', 'nativeName': 'Русский', 'flag': '🇷🇺'},
      'zh': {'name': 'Chinese', 'nativeName': '中文', 'flag': '🇨🇳'},
      'ja': {'name': 'Japanese', 'nativeName': '日本語', 'flag': '🇯🇵'},
      'ko': {'name': 'Korean', 'nativeName': '한국어', 'flag': '🇰🇷'},
      'ar': {'name': 'Arabic', 'nativeName': 'العربية', 'flag': '🇸🇦'},
      'hi': {'name': 'Hindi', 'nativeName': 'हिंदी', 'flag': '🇮🇳'},
      'tr': {'name': 'Turkish', 'nativeName': 'Türkçe', 'flag': '🇹🇷'},
      'pl': {'name': 'Polish', 'nativeName': 'Polski', 'flag': '🇵🇱'},
      'nl': {'name': 'Dutch', 'nativeName': 'Nederlands', 'flag': '🇳🇱'},
      'sv': {'name': 'Swedish', 'nativeName': 'Svenska', 'flag': '🇸🇪'},
      'da': {'name': 'Danish', 'nativeName': 'Dansk', 'flag': '🇩🇰'},
      'no': {'name': 'Norwegian', 'nativeName': 'Norsk', 'flag': '🇳🇴'},
      'fi': {'name': 'Finnish', 'nativeName': 'Suomi', 'flag': '🇫🇮'},
      'cs': {'name': 'Czech', 'nativeName': 'Čeština', 'flag': '🇨🇿'},
      'hu': {'name': 'Hungarian', 'nativeName': 'Magyar', 'flag': '🇭🇺'},
      'ro': {'name': 'Romanian', 'nativeName': 'Română', 'flag': '🇷🇴'},
      'bg': {'name': 'Bulgarian', 'nativeName': 'Български', 'flag': '🇧🇬'},
      'hr': {'name': 'Croatian', 'nativeName': 'Hrvatski', 'flag': '🇭🇷'},
      'sk': {'name': 'Slovak', 'nativeName': 'Slovenčina', 'flag': '🇸🇰'},
      'sl': {'name': 'Slovenian', 'nativeName': 'Slovenščina', 'flag': '🇸🇮'},
      'et': {'name': 'Estonian', 'nativeName': 'Eesti', 'flag': '🇪🇪'},
      'lv': {'name': 'Latvian', 'nativeName': 'Latviešu', 'flag': '🇱🇻'},
      'lt': {'name': 'Lithuanian', 'nativeName': 'Lietuvių', 'flag': '🇱🇹'},
      'th': {'name': 'Thai', 'nativeName': 'ไทย', 'flag': '🇹🇭'},
      'vi': {'name': 'Vietnamese', 'nativeName': 'Tiếng Việt', 'flag': '🇻🇳'},
      'id': {'name': 'Indonesian', 'nativeName': 'Bahasa Indonesia', 'flag': '🇮🇩'},
      'ms': {'name': 'Malay', 'nativeName': 'Bahasa Melayu', 'flag': '🇲🇾'},
      'tl': {'name': 'Filipino', 'nativeName': 'Filipino', 'flag': '🇵🇭'},
      'sw': {'name': 'Swahili', 'nativeName': 'Kiswahili', 'flag': '🇰🇪'},
      'he': {'name': 'Hebrew', 'nativeName': 'עברית', 'flag': '🇮🇱'},
      'fa': {'name': 'Persian', 'nativeName': 'فارسی', 'flag': '🇮🇷'},
      'ur': {'name': 'Urdu', 'nativeName': 'اردو', 'flag': '🇵🇰'},
      'bn': {'name': 'Bengali', 'nativeName': 'বাংলা', 'flag': '🇧🇩'},
      'ta': {'name': 'Tamil', 'nativeName': 'தமிழ்', 'flag': '🇮🇳'},
      'te': {'name': 'Telugu', 'nativeName': 'తెలుగు', 'flag': '🇮🇳'},
      'ml': {'name': 'Malayalam', 'nativeName': 'മലയാളം', 'flag': '🇮🇳'},
      'kn': {'name': 'Kannada', 'nativeName': 'ಕನ್ನಡ', 'flag': '🇮🇳'},
      'gu': {'name': 'Gujarati', 'nativeName': 'ગુજરાતી', 'flag': '🇮🇳'},
      'pa': {'name': 'Punjabi', 'nativeName': 'ਪੰਜਾਬੀ', 'flag': '🇮🇳'},
    };
  }

  // 📊 Translation quality assessment
  static Future<Map<String, dynamic>> assessTranslationQuality({
    required String originalText,
    required String translatedText,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    try {
      // Simple quality metrics
      final lengthRatio = translatedText.length / originalText.length;
      final wordCountRatio = translatedText.split(' ').length / originalText.split(' ').length;

      // Quality score based on various factors
      double qualityScore = 0.8; // Base score

      // Adjust based on length similarity
      if (lengthRatio > 0.5 && lengthRatio < 2.0) {
        qualityScore += 0.1;
      }

      // Adjust based on word count similarity
      if (wordCountRatio > 0.6 && wordCountRatio < 1.5) {
        qualityScore += 0.1;
      }

      // Detect common translation issues
      List<String> issues = [];
      if (translatedText.isEmpty) {
        issues.add('Empty translation');
        qualityScore -= 0.5;
      }
      if (translatedText == originalText && sourceLanguage != targetLanguage) {
        issues.add('Untranslated text');
        qualityScore -= 0.3;
      }

      return {
        'qualityScore': qualityScore.clamp(0.0, 1.0),
        'lengthRatio': lengthRatio,
        'wordCountRatio': wordCountRatio,
        'issues': issues,
        'recommendation': qualityScore > 0.7 ? 'Good translation' : 'Review recommended',
      };

    } catch (e) {
      return {
        'qualityScore': 0.5,
        'lengthRatio': 1.0,
        'wordCountRatio': 1.0,
        'issues': ['Quality assessment failed'],
        'recommendation': 'Manual review needed',
      };
    }
  }

  // 🚀 Batch translation for community posts
  static Future<List<Map<String, dynamic>>> batchTranslate({
    required List<String> texts,
    required String targetLanguage,
    String sourceLanguage = 'auto',
  }) async {
    List<Map<String, dynamic>> results = [];

    for (String text in texts) {
      final result = await translateMessage(
        message: text,
        targetLanguage: targetLanguage,
        sourceLanguage: sourceLanguage != 'auto' ? sourceLanguage : null,
      );
      results.add(result);

      // Small delay to avoid rate limiting
      await Future.delayed(const Duration(milliseconds: 100));
    }

    return results;
  }

  // =============== PRIVATE HELPER METHODS ===============

  static Future<String> _detectLanguage(String text) async {
    if (!hasApiKey) {
      return _guessLanguageFromText(text);
    }

    try {
      final response = await http.post(
        Uri.parse('$_detectApiUrl?key=$_googleTranslateApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'q': text,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final detections = data['data']['detections'][0];
        return detections[0]['language'];
      }
      return _guessLanguageFromText(text);
    } catch (e) {
      debugPrint('Language detection error: $e');
      return _guessLanguageFromText(text);
    }
  }

  static Future<String> _performTranslation({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    if (!hasApiKey) {
      return _getFallbackTranslationText(text, targetLanguage);
    }

    try {
      final response = await http.post(
        Uri.parse('$_translateApiUrl?key=$_googleTranslateApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'q': text,
          'source': sourceLanguage == 'auto' ? null : sourceLanguage,
          'target': targetLanguage,
          'format': 'text',
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']['translations'][0]['translatedText'];
      }
      return _getFallbackTranslationText(text, targetLanguage);
    } catch (e) {
      debugPrint('Translation API error: $e');
      return _getFallbackTranslationText(text, targetLanguage);
    }
  }

  static String _guessLanguageFromText(String text) {
    // Simple language detection based on character patterns
    if (RegExp(r'[а-яё]', caseSensitive: false).hasMatch(text)) return 'ru';
    if (RegExp(r'[中文]').hasMatch(text)) return 'zh';
    if (RegExp(r'[ひらがなカタカナ]').hasMatch(text)) return 'ja';
    if (RegExp(r'[한국어]').hasMatch(text)) return 'ko';
    if (RegExp(r'[العربية]').hasMatch(text)) return 'ar';
    if (RegExp(r'[àáâãäåçèéêëìíîïñòóôõöùúûüýÿ]', caseSensitive: false).hasMatch(text)) {
      // Could be French, Spanish, Portuguese, etc.
      if (text.contains('ção') || text.contains('ão')) return 'pt';
      if (text.contains('tion') || text.contains('ment')) return 'fr';
      if (text.contains('ción') || text.contains('dad')) return 'es';
    }
    if (RegExp(r'[äöüß]', caseSensitive: false).hasMatch(text)) return 'de';
    if (RegExp(r'[åæø]', caseSensitive: false).hasMatch(text)) return 'da';

    return 'en'; // Default to English
  }

  static Future<String?> _getCachedTranslation(String cacheKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('translation_$cacheKey');
    } catch (e) {
      return null;
    }
  }

  static Future<void> _cacheTranslation(String cacheKey, String translation) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('translation_$cacheKey', translation);
    } catch (e) {
      debugPrint('Cache error: $e');
    }
  }

  static String _getFallbackTranslationText(String text, String targetLanguage) {
    // Simple fallback translations for common phrases
    final fallbacks = {
      'Hello': {
        'es': 'Hola',
        'fr': 'Bonjour',
        'de': 'Hallo',
        'ru': 'Привет',
        'zh': '你好',
        'ja': 'こんにちは',
        'ko': '안녕하세요',
        'ar': 'مرحبا',
        'hi': 'नमस्ते',
      },
      'Thank you': {
        'es': 'Gracias',
        'fr': 'Merci',
        'de': 'Danke',
        'ru': 'Спасибо',
        'zh': '谢谢',
        'ja': 'ありがとう',
        'ko': '감사합니다',
        'ar': 'شكرا',
        'hi': 'धन्यवाद',
      },
      'Good morning': {
        'es': 'Buenos días',
        'fr': 'Bonjour',
        'de': 'Guten Morgen',
        'ru': 'Доброе утро',
        'zh': '早上好',
        'ja': 'おはよう',
        'ko': '좋은 아침',
        'ar': 'صباح الخير',
        'hi': 'सुप्रभात',
      },
    };

    for (String phrase in fallbacks.keys) {
      if (text.toLowerCase().contains(phrase.toLowerCase())) {
        return fallbacks[phrase]?[targetLanguage] ?? text;
      }
    }

    return text; // Return original if no fallback available
  }

  static Map<String, dynamic> _getFallbackTranslation(String message, String targetLanguage) {
    return {
      'originalText': message,
      'translatedText': _getFallbackTranslationText(message, targetLanguage),
      'sourceLanguage': 'auto',
      'targetLanguage': targetLanguage,
      'confidence': 0.3,
      'cached': false,
      'error': 'Translation service unavailable',
    };
  }
}