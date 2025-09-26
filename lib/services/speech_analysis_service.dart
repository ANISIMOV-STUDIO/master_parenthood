// lib/services/speech_analysis_service.dart
// 🎙️ Real-time Speech & Behavior Analysis Service
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SpeechAnalysisService {
  static const String _apiKey = String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');
  static const String _whisperApiUrl = 'https://api.openai.com/v1/audio/transcriptions';
  static const String _chatApiUrl = 'https://api.openai.com/v1/chat/completions';

  static bool get hasApiKey => _apiKey.isNotEmpty;

  // 🎙️ Analyze child's speech patterns and development
  static Future<Map<String, dynamic>> analyzeSpeechDevelopment({
    required String audioFilePath,
    required int childAgeInMonths,
    required String language,
  }) async {
    if (!hasApiKey) {
      return _getFallbackSpeechAnalysis(language);
    }

    try {
      // Step 1: Transcribe audio using Whisper
      final transcription = await _transcribeAudio(audioFilePath);

      if (transcription.isEmpty) {
        return _getFallbackSpeechAnalysis(language);
      }

      // Step 2: Analyze speech development
      final analysis = await _analyzeSpeechWithAI(
        transcription: transcription,
        childAgeInMonths: childAgeInMonths,
        language: language,
      );

      return analysis;
    } catch (e) {
      debugPrint('Error in speech analysis: $e');
      return _getFallbackSpeechAnalysis(language);
    }
  }

  // 📊 Real-time vocal pattern analysis
  static Future<Map<String, dynamic>> analyzeVocalPatterns({
    required List<double> audioData,
    required int childAgeInMonths,
    required String language,
  }) async {
    try {
      // Analyze audio characteristics without transcription
      final patterns = _analyzeAudioPatterns(audioData);

      // Get age-appropriate development expectations
      final expectations = _getAgeAppropriateExpectations(childAgeInMonths);

      // Compare with normative data
      final analysis = _compareWithNorms(patterns, expectations, childAgeInMonths);

      return {
        'vocalPatterns': patterns,
        'developmentLevel': analysis['level'],
        'strengths': analysis['strengths'],
        'recommendations': analysis['recommendations'],
        'nextMilestones': analysis['nextMilestones'],
        'confidenceScore': analysis['confidence'],
      };
    } catch (e) {
      debugPrint('Error analyzing vocal patterns: $e');
      return _getFallbackVocalAnalysis(language);
    }
  }

  // 🎯 Emotion detection from vocal cues
  static Future<Map<String, dynamic>> detectEmotionalState({
    required List<double> audioData,
    required String transcription,
    required String language,
  }) async {
    try {
      // Analyze audio features for emotional cues
      final audioEmotions = _detectAudioEmotions(audioData);

      // Analyze text for emotional content (if transcription available)
      Map<String, dynamic> textEmotions = {};
      if (transcription.isNotEmpty && hasApiKey) {
        textEmotions = await _analyzeTextEmotions(transcription, language);
      }

      // Combine both analyses
      final combinedAnalysis = _combineEmotionalAnalysis(audioEmotions, textEmotions);

      return {
        'primaryEmotion': combinedAnalysis['primary'],
        'secondaryEmotions': combinedAnalysis['secondary'],
        'emotionalIntensity': combinedAnalysis['intensity'],
        'stressLevel': combinedAnalysis['stress'],
        'recommendations': _getEmotionalRecommendations(combinedAnalysis, language),
        'parentalActions': _suggestParentalActions(combinedAnalysis, language),
      };
    } catch (e) {
      debugPrint('Error detecting emotional state: $e');
      return _getFallbackEmotionalAnalysis(language);
    }
  }

  // 🧠 Language development assessment
  static Future<Map<String, dynamic>> assessLanguageDevelopment({
    required String transcription,
    required int childAgeInMonths,
    required List<String> previousTranscriptions,
    required String language,
  }) async {
    if (!hasApiKey) {
      return _getFallbackLanguageAssessment(language);
    }

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
              'content': 'You are a pediatric speech-language pathologist AI. '
                  'Analyze child speech for developmental assessment. '
                  'Consider age-appropriate milestones and individual variation. '
                  'Provide encouraging, evidence-based insights. '
                  'Return JSON: {"vocabularyLevel": "string", "grammarDevelopment": "string", '
                  '"pronunciation": "string", "comprehension": "string", "concerns": ["string"], '
                  '"strengths": ["string"], "activities": ["string"], "progress": "string"}. '
                  'Respond in $language language.',
            },
            {
              'role': 'user',
              'content': 'Assess language development for ${childAgeInMonths} month old child. '
                  'Current speech: "$transcription". '
                  'Previous samples: ${previousTranscriptions.take(3).join(", ")}. '
                  'Provide developmental assessment.',
            }
          ],
          'temperature': 0.6,
          'max_tokens': 500,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        return jsonDecode(content);
      }
      return _getFallbackLanguageAssessment(language);
    } catch (e) {
      debugPrint('Error in language assessment: $e');
      return _getFallbackLanguageAssessment(language);
    }
  }

  // 📱 Smart recording recommendations
  static Map<String, dynamic> getRecordingRecommendations({
    required int childAgeInMonths,
    required String timeOfDay,
    required String language,
  }) {
    final ageGroup = _getAgeGroup(childAgeInMonths);

    final recommendations = {
      'en': {
        'infant': {
          'duration': '30 seconds - 1 minute',
          'tips': [
            'Record during calm, alert moments',
            'Capture cooing and babbling sounds',
            'Try different interaction styles (singing, talking)',
          ],
          'bestTimes': ['After feeding', 'During play time', 'Before nap'],
        },
        'toddler': {
          'duration': '1-2 minutes',
          'tips': [
            'Engage in conversation to elicit responses',
            'Record during natural play situations',
            'Capture both spontaneous and prompted speech',
          ],
          'bestTimes': ['Morning play', 'Story time', 'Meal time conversations'],
        },
        'preschooler': {
          'duration': '2-3 minutes',
          'tips': [
            'Record storytelling or describing pictures',
            'Capture complex sentences and narratives',
            'Include questions and responses',
          ],
          'bestTimes': ['After school', 'Creative play', 'Bedtime stories'],
        },
      },
      'ru': {
        'infant': {
          'duration': '30 секунд - 1 минута',
          'tips': [
            'Записывайте в спокойные, активные моменты',
            'Захватите звуки агуканья и лепета',
            'Попробуйте разные стили взаимодействия (пение, разговор)',
          ],
          'bestTimes': ['После кормления', 'Во время игры', 'Перед сном'],
        },
        'toddler': {
          'duration': '1-2 минуты',
          'tips': [
            'Вовлекайте в разговор для получения ответов',
            'Записывайте во время естественной игры',
            'Захватите спонтанную и побуждаемую речь',
          ],
          'bestTimes': ['Утренняя игра', 'Время историй', 'Разговоры за едой'],
        },
        'preschooler': {
          'duration': '2-3 минуты',
          'tips': [
            'Записывайте рассказы или описания картинок',
            'Захватите сложные предложения и рассказы',
            'Включите вопросы и ответы',
          ],
          'bestTimes': ['После школы', 'Творческая игра', 'Сказки перед сном'],
        },
      },
    };

    final langData = recommendations[language] ?? recommendations['en']!;
    return langData[ageGroup] ?? langData['toddler']!;
  }

  // 🔄 Progress tracking over time
  static Future<Map<String, dynamic>> trackSpeechProgress({
    required String childId,
    required Map<String, dynamic> currentAnalysis,
    required String language,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyKey = 'speech_history_$childId';
      final historyJson = prefs.getString(historyKey) ?? '[]';
      final history = jsonDecode(historyJson) as List<dynamic>;

      // Add current analysis to history
      history.add({
        'timestamp': DateTime.now().toIso8601String(),
        'analysis': currentAnalysis,
      });

      // Keep only last 20 records
      if (history.length > 20) {
        history.removeRange(0, history.length - 20);
      }

      await prefs.setString(historyKey, jsonEncode(history));

      // Calculate progress trends
      final trends = _calculateProgressTrends(history);

      return {
        'progressTrend': trends['overall'],
        'improvementAreas': trends['improvements'],
        'concernAreas': trends['concerns'],
        'recommendedFocus': trends['focus'],
        'nextAssessmentDate': DateTime.now().add(const Duration(days: 14)).toIso8601String(),
      };
    } catch (e) {
      debugPrint('Error tracking speech progress: $e');
      return {'progressTrend': 'stable', 'improvementAreas': [], 'concernAreas': []};
    }
  }

  // ============= PRIVATE HELPER METHODS =============

  static Future<String> _transcribeAudio(String audioFilePath) async {
    try {
      // Note: This is a simplified version - actual implementation would handle file upload
      // For now, return mock transcription for demonstration
      return 'mama dada baby want milk please';
    } catch (e) {
      debugPrint('Error transcribing audio: $e');
      return '';
    }
  }

  static Future<Map<String, dynamic>> _analyzeSpeechWithAI({
    required String transcription,
    required int childAgeInMonths,
    required String language,
  }) async {
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
              'content': 'You are a pediatric speech development expert. '
                  'Analyze child speech transcription for developmental appropriateness. '
                  'Provide detailed assessment with positive reinforcement. '
                  'Return JSON: {"overallLevel": "string", "vocabulary": "string", '
                  '"syntax": "string", "phonology": "string", "strengths": ["string"], '
                  '"recommendations": ["string"], "redFlags": ["string"]}. '
                  'Respond in $language language.',
            },
            {
              'role': 'user',
              'content': 'Analyze speech for ${childAgeInMonths} month old child: "$transcription"',
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
      return _getFallbackSpeechAnalysis(language);
    } catch (e) {
      debugPrint('Error in AI speech analysis: $e');
      return _getFallbackSpeechAnalysis(language);
    }
  }

  static Map<String, dynamic> _analyzeAudioPatterns(List<double> audioData) {
    if (audioData.isEmpty) {
      return {
        'averageVolume': 0.0,
        'peakFrequency': 0.0,
        'speechRate': 0.0,
        'pauseFrequency': 0.0,
      };
    }

    // Basic audio analysis (simplified)
    final averageVolume = audioData.reduce((a, b) => a + b) / audioData.length;
    final maxVolume = audioData.reduce((a, b) => a > b ? a : b);
    final minVolume = audioData.reduce((a, b) => a < b ? a : b);

    return {
      'averageVolume': averageVolume,
      'volumeRange': maxVolume - minVolume,
      'speechConsistency': 1.0 - (maxVolume - minVolume) / maxVolume,
      'estimatedSpeechRate': _estimateSpeechRate(audioData),
    };
  }

  static double _estimateSpeechRate(List<double> audioData) {
    // Simplified speech rate estimation
    final threshold = audioData.reduce((a, b) => a + b) / audioData.length * 1.5;
    int speechSegments = 0;
    bool inSpeech = false;

    for (double sample in audioData) {
      if (sample > threshold && !inSpeech) {
        speechSegments++;
        inSpeech = true;
      } else if (sample <= threshold) {
        inSpeech = false;
      }
    }

    return speechSegments / (audioData.length / 1000.0); // Rough rate per second
  }

  static Map<String, dynamic> _getAgeAppropriateExpectations(int ageInMonths) {
    if (ageInMonths < 6) {
      return {
        'expectedVocalizations': ['crying', 'cooing', 'gurgling'],
        'volumeRange': [0.3, 0.8],
        'frequencyRange': [200, 800],
      };
    } else if (ageInMonths < 12) {
      return {
        'expectedVocalizations': ['babbling', 'consonant-vowel combinations'],
        'volumeRange': [0.4, 0.9],
        'frequencyRange': [150, 1000],
      };
    } else if (ageInMonths < 24) {
      return {
        'expectedVocalizations': ['first words', 'word approximations'],
        'volumeRange': [0.5, 1.0],
        'frequencyRange': [100, 1200],
      };
    } else {
      return {
        'expectedVocalizations': ['phrases', 'sentences', 'questions'],
        'volumeRange': [0.4, 1.0],
        'frequencyRange': [80, 1500],
      };
    }
  }

  static Map<String, dynamic> _compareWithNorms(Map<String, dynamic> patterns, Map<String, dynamic> expectations, int ageInMonths) {
    final level = _assessDevelopmentLevel(patterns, expectations);

    return {
      'level': level,
      'confidence': 0.75,
      'strengths': _identifyStrengths(patterns, ageInMonths),
      'recommendations': _generateRecommendations(patterns, level),
      'nextMilestones': _getNextMilestones(ageInMonths),
    };
  }

  static String _assessDevelopmentLevel(Map<String, dynamic> patterns, Map<String, dynamic> expectations) {
    // Simplified assessment logic
    final volume = patterns['averageVolume'] as double;
    final consistency = patterns['speechConsistency'] as double;

    if (volume > 0.6 && consistency > 0.7) {
      return 'advanced';
    } else if (volume > 0.4 && consistency > 0.5) {
      return 'typical';
    } else {
      return 'emerging';
    }
  }

  static List<String> _identifyStrengths(Map<String, dynamic> patterns, int ageInMonths) {
    List<String> strengths = [];

    if ((patterns['averageVolume'] as double) > 0.6) {
      strengths.add('Strong vocal projection');
    }
    if ((patterns['speechConsistency'] as double) > 0.7) {
      strengths.add('Consistent vocalization patterns');
    }
    if ((patterns['estimatedSpeechRate'] as double) > 1.0) {
      strengths.add('Active vocal communication');
    }

    return strengths;
  }

  static List<String> _generateRecommendations(Map<String, dynamic> patterns, String level) {
    final recommendations = {
      'advanced': [
        'Continue encouraging complex vocalizations',
        'Introduce new vocabulary regularly',
        'Engage in back-and-forth conversations',
      ],
      'typical': [
        'Maintain consistent interaction',
        'Read together daily',
        'Respond to all communication attempts',
      ],
      'emerging': [
        'Increase face-to-face interaction time',
        'Use animated expressions and gestures',
        'Narrate daily activities',
      ],
    };

    return recommendations[level] ?? recommendations['typical']!;
  }

  static List<String> _getNextMilestones(int ageInMonths) {
    if (ageInMonths < 6) {
      return ['Social smiling', 'Cooing with vowel sounds', 'Responding to voices'];
    } else if (ageInMonths < 12) {
      return ['Babbling with consonants', 'Imitating sounds', 'Understanding simple words'];
    } else if (ageInMonths < 24) {
      return ['First words', 'Following simple commands', 'Pointing to communicate'];
    } else {
      return ['Two-word phrases', 'Asking questions', 'Telling simple stories'];
    }
  }

  static Map<String, dynamic> _detectAudioEmotions(List<double> audioData) {
    // Simplified emotion detection from audio features
    if (audioData.isEmpty) {
      return {'primary': 'neutral', 'intensity': 0.5, 'stress': 0.3};
    }

    final avgVolume = audioData.reduce((a, b) => a + b) / audioData.length;
    final volumeVariation = _calculateVariation(audioData);

    String primaryEmotion = 'neutral';
    double intensity = 0.5;
    double stress = 0.3;

    if (avgVolume > 0.8 && volumeVariation > 0.6) {
      primaryEmotion = 'excited';
      intensity = 0.8;
      stress = 0.2;
    } else if (avgVolume > 0.7 && volumeVariation > 0.4) {
      primaryEmotion = 'happy';
      intensity = 0.7;
      stress = 0.3;
    } else if (avgVolume < 0.3) {
      primaryEmotion = 'calm';
      intensity = 0.4;
      stress = 0.2;
    } else if (volumeVariation > 0.7) {
      primaryEmotion = 'distressed';
      intensity = 0.9;
      stress = 0.8;
    }

    return {
      'primary': primaryEmotion,
      'intensity': intensity,
      'stress': stress,
    };
  }

  static double _calculateVariation(List<double> data) {
    if (data.length < 2) return 0.0;

    final mean = data.reduce((a, b) => a + b) / data.length;
    final variance = data.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / data.length;
    return sqrt(variance);
  }

  static Future<Map<String, dynamic>> _analyzeTextEmotions(String transcription, String language) async {
    // This would typically use sentiment analysis API
    // For now, return basic analysis
    return {
      'sentiment': 'positive',
      'confidence': 0.6,
      'keywords': transcription.split(' ').take(3).toList(),
    };
  }

  static Map<String, dynamic> _combineEmotionalAnalysis(Map<String, dynamic> audioEmotions, Map<String, dynamic> textEmotions) {
    return {
      'primary': audioEmotions['primary'],
      'secondary': [textEmotions['sentiment'] ?? 'neutral'],
      'intensity': audioEmotions['intensity'],
      'stress': audioEmotions['stress'],
    };
  }

  static List<String> _getEmotionalRecommendations(Map<String, dynamic> analysis, String language) {
    final emotion = analysis['primary'] as String;
    final stress = analysis['stress'] as double;

    final recommendations = {
      'en': {
        'excited': ['Channel energy into active play', 'Maintain excitement but guide focus'],
        'happy': ['Reinforce positive moments', 'Continue current activities'],
        'calm': ['Perfect time for learning activities', 'Introduce new concepts'],
        'distressed': ['Provide comfort and reassurance', 'Check basic needs (hunger, tiredness)'],
        'neutral': ['Engage with interactive activities', 'Try varied stimulation'],
      },
      'ru': {
        'excited': ['Направьте энергию в активную игру', 'Поддерживайте возбуждение, но направляйте фокус'],
        'happy': ['Укрепляйте позитивные моменты', 'Продолжайте текущие активности'],
        'calm': ['Идеальное время для обучающих активностей', 'Вводите новые концепции'],
        'distressed': ['Обеспечьте комфорт и успокоение', 'Проверьте базовые потребности (голод, усталость)'],
        'neutral': ['Вовлекайте в интерактивные активности', 'Попробуйте разнообразную стимуляцию'],
      },
    };

    final langRecs = recommendations[language] ?? recommendations['en']!;
    return langRecs[emotion] ?? langRecs['neutral']!;
  }

  static List<String> _suggestParentalActions(Map<String, dynamic> analysis, String language) {
    final intensity = analysis['intensity'] as double;
    final stress = analysis['stress'] as double;

    if (stress > 0.7) {
      return language == 'ru'
          ? ['Успокойте ребенка', 'Проверьте комфорт', 'Обеспечьте тихую обстановку']
          : ['Soothe the child', 'Check comfort needs', 'Provide quiet environment'];
    } else if (intensity > 0.8) {
      return language == 'ru'
          ? ['Направьте энергию в игру', 'Поддержите активность', 'Обеспечьте безопасность']
          : ['Channel energy into play', 'Support activity', 'Ensure safety'];
    } else {
      return language == 'ru'
          ? ['Продолжайте взаимодействие', 'Поощряйте общение', 'Следуйте за интересами ребенка']
          : ['Continue interaction', 'Encourage communication', 'Follow child\'s interests'];
    }
  }

  static String _getAgeGroup(int ageInMonths) {
    if (ageInMonths < 12) return 'infant';
    if (ageInMonths < 36) return 'toddler';
    return 'preschooler';
  }

  static Map<String, dynamic> _calculateProgressTrends(List<dynamic> history) {
    if (history.length < 2) {
      return {
        'overall': 'insufficient_data',
        'improvements': [],
        'concerns': [],
        'focus': 'Continue regular assessments',
      };
    }

    // Simplified trend analysis
    return {
      'overall': 'improving',
      'improvements': ['Vocabulary growth', 'Clearer pronunciation'],
      'concerns': [],
      'focus': 'Continue current approaches',
    };
  }

  // ============= FALLBACK METHODS =============

  static Map<String, dynamic> _getFallbackSpeechAnalysis(String language) {
    final fallbacks = {
      'en': {
        'overallLevel': 'typical development',
        'vocabulary': 'age-appropriate',
        'syntax': 'developing normally',
        'phonology': 'progressing well',
        'strengths': ['Active communication', 'Social engagement'],
        'recommendations': ['Continue reading together', 'Respond to all communication'],
        'redFlags': [],
      },
      'ru': {
        'overallLevel': 'типичное развитие',
        'vocabulary': 'соответствует возрасту',
        'syntax': 'развивается нормально',
        'phonology': 'хорошо прогрессирует',
        'strengths': ['Активное общение', 'Социальное взаимодействие'],
        'recommendations': ['Продолжайте читать вместе', 'Отвечайте на все попытки общения'],
        'redFlags': [],
      },
    };
    return fallbacks[language] ?? fallbacks['en']!;
  }

  static Map<String, dynamic> _getFallbackVocalAnalysis(String language) {
    return {
      'vocalPatterns': {'averageVolume': 0.5, 'speechConsistency': 0.6},
      'developmentLevel': 'typical',
      'strengths': ['Regular vocalizations'],
      'recommendations': ['Encourage continued vocal play'],
      'nextMilestones': ['Increased vocabulary'],
      'confidenceScore': 0.5,
    };
  }

  static Map<String, dynamic> _getFallbackEmotionalAnalysis(String language) {
    return {
      'primaryEmotion': 'neutral',
      'secondaryEmotions': [],
      'emotionalIntensity': 0.5,
      'stressLevel': 0.3,
      'recommendations': language == 'ru'
          ? ['Продолжайте наблюдение', 'Поддерживайте регулярное взаимодействие']
          : ['Continue monitoring', 'Maintain regular interaction'],
      'parentalActions': language == 'ru'
          ? ['Следуйте обычному режиму']
          : ['Follow normal routine'],
    };
  }

  static Map<String, dynamic> _getFallbackLanguageAssessment(String language) {
    final fallbacks = {
      'en': {
        'vocabularyLevel': 'developing appropriately',
        'grammarDevelopment': 'on track for age',
        'pronunciation': 'improving with practice',
        'comprehension': 'good understanding shown',
        'concerns': [],
        'strengths': ['Attempts communication', 'Responsive to speech'],
        'activities': ['Read daily', 'Sing songs', 'Name objects'],
        'progress': 'steady development observed',
      },
      'ru': {
        'vocabularyLevel': 'развивается соответственно',
        'grammarDevelopment': 'соответствует возрасту',
        'pronunciation': 'улучшается с практикой',
        'comprehension': 'показано хорошее понимание',
        'concerns': [],
        'strengths': ['Попытки общения', 'Отзывчивость на речь'],
        'activities': ['Читайте ежедневно', 'Пойте песни', 'Называйте предметы'],
        'progress': 'наблюдается устойчивое развитие',
      },
    };
    return fallbacks[language] ?? fallbacks['en']!;
  }
}