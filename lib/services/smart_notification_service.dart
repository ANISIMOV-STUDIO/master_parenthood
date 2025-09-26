// lib/services/smart_notification_service.dart
// 🔔 Smart Notification Service with ML predictions
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_service.dart';

class SmartNotificationService {
  static const String _userPatternKey = 'user_interaction_patterns';
  static const String _notificationHistoryKey = 'notification_history';

  // 🤖 Smart notification timing based on user patterns
  static Future<Map<String, dynamic>> calculateOptimalNotificationTime({
    required String notificationType,
    required String userId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final patternsJson = prefs.getString('${_userPatternKey}_$userId') ?? '{}';
      final patterns = jsonDecode(patternsJson) as Map<String, dynamic>;

      // Analyze user's interaction history
      final interactionTimes = patterns[notificationType] as List<dynamic>? ?? [];

      if (interactionTimes.isEmpty) {
        // Default optimal times for different notification types
        return _getDefaultOptimalTime(notificationType);
      }

      // Calculate optimal time based on historical data
      final optimalHour = _calculateOptimalHour(interactionTimes);
      final confidence = _calculateConfidence(interactionTimes);

      return {
        'optimalHour': optimalHour,
        'confidence': confidence,
        'reasoning': _generateReasoning(notificationType, optimalHour, confidence),
        'alternativeTimes': _generateAlternativeTimes(optimalHour),
      };
    } catch (e) {
      debugPrint('Error calculating optimal notification time: $e');
      return _getDefaultOptimalTime(notificationType);
    }
  }

  // 📊 Personalized notification content based on child's development
  static Future<Map<String, dynamic>> generatePersonalizedNotification({
    required String childId,
    required String notificationType,
    required Map<String, dynamic> childData,
    required String language,
  }) async {
    try {
      final ageInMonths = _calculateAgeInMonths(childData['birthDate']);
      final developmentStage = _getDevelopmentStage(ageInMonths);

      // Get personalized content based on multiple factors
      final content = await _generateSmartContent(
        notificationType: notificationType,
        childData: childData,
        developmentStage: developmentStage,
        language: language,
      );

      // Add contextual actions
      final actions = _generateContextualActions(notificationType, childData);

      return {
        'title': content['title'],
        'body': content['body'],
        'emoji': content['emoji'],
        'priority': _calculatePriority(notificationType, childData),
        'actions': actions,
        'deepLink': _generateDeepLink(notificationType, childId),
        'personalizedTip': content['tip'],
      };
    } catch (e) {
      debugPrint('Error generating personalized notification: $e');
      return _getDefaultNotification(notificationType, language);
    }
  }

  // 🎯 Smart frequency management to prevent notification fatigue
  static Future<bool> shouldSendNotification({
    required String userId,
    required String notificationType,
    required int currentHour,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString('${_notificationHistoryKey}_$userId') ?? '{}';
      final history = jsonDecode(historyJson) as Map<String, dynamic>;

      final today = DateTime.now().toIso8601String().split('T')[0];
      final todayHistory = history[today] as Map<String, dynamic>? ?? {};

      // Check daily limits
      final dailyCount = todayHistory.length;
      if (dailyCount >= _getDailyLimit(notificationType)) {
        return false;
      }

      // Check time-based restrictions
      if (!_isValidTimeForNotification(currentHour, notificationType)) {
        return false;
      }

      // Check user engagement patterns
      final engagementScore = await _calculateEngagementScore(userId, notificationType);
      if (engagementScore < 0.3) { // Low engagement threshold
        return false;
      }

      // ML-based prediction: will user engage with this notification?
      final predictionScore = await _predictUserEngagement(
        userId: userId,
        notificationType: notificationType,
        currentHour: currentHour,
        recentHistory: todayHistory,
      );

      return predictionScore > 0.6; // 60% confidence threshold
    } catch (e) {
      debugPrint('Error in smart notification decision: $e');
      return true; // Default to sending if error
    }
  }

  // 📈 Track user interaction for ML learning
  static Future<void> trackNotificationInteraction({
    required String userId,
    required String notificationType,
    required String action, // 'opened', 'dismissed', 'clicked_action'
    required DateTime timestamp,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Update interaction patterns
      final patternsJson = prefs.getString('${_userPatternKey}_$userId') ?? '{}';
      final patterns = jsonDecode(patternsJson) as Map<String, dynamic>;

      final typePatterns = patterns[notificationType] as List<dynamic>? ?? [];
      typePatterns.add({
        'action': action,
        'timestamp': timestamp.toIso8601String(),
        'hour': timestamp.hour,
        'dayOfWeek': timestamp.weekday,
      });

      // Keep only last 50 interactions per type
      if (typePatterns.length > 50) {
        typePatterns.removeRange(0, typePatterns.length - 50);
      }

      patterns[notificationType] = typePatterns;
      await prefs.setString('${_userPatternKey}_$userId', jsonEncode(patterns));

      // Update notification history
      final historyJson = prefs.getString('${_notificationHistoryKey}_$userId') ?? '{}';
      final history = jsonDecode(historyJson) as Map<String, dynamic>;

      final dateKey = timestamp.toIso8601String().split('T')[0];
      final dayHistory = history[dateKey] as Map<String, dynamic>? ?? {};

      dayHistory[timestamp.toIso8601String()] = {
        'type': notificationType,
        'action': action,
      };

      history[dateKey] = dayHistory;
      await prefs.setString('${_notificationHistoryKey}_$userId', jsonEncode(history));

    } catch (e) {
      debugPrint('Error tracking notification interaction: $e');
    }
  }

  // 🎨 Dynamic notification styling based on content and urgency
  static Map<String, dynamic> generateNotificationStyle({
    required String notificationType,
    required int priority,
    required String childName,
  }) {
    final styles = {
      'milestone_reminder': {
        'color': '#4CAF50',
        'icon': 'celebration',
        'sound': 'gentle_chime',
        'vibration': [0, 300, 100, 300],
      },
      'feeding_reminder': {
        'color': '#FF9800',
        'icon': 'restaurant',
        'sound': 'soft_bell',
        'vibration': [0, 200],
      },
      'sleep_time': {
        'color': '#3F51B5',
        'icon': 'bedtime',
        'sound': 'lullaby_short',
        'vibration': [0, 100, 50, 100],
      },
      'development_tip': {
        'color': '#9C27B0',
        'icon': 'psychology',
        'sound': 'notification',
        'vibration': [0, 150],
      },
      'health_alert': {
        'color': '#F44336',
        'icon': 'health_and_safety',
        'sound': 'urgent_notification',
        'vibration': [0, 500, 100, 500, 100, 500],
      },
    };

    final baseStyle = styles[notificationType] ?? styles['development_tip']!;

    // Adjust based on priority
    if (priority > 7) {
      baseStyle['sound'] = 'urgent_notification';
      baseStyle['vibration'] = [0, 500, 100, 500];
    } else if (priority < 3) {
      baseStyle['sound'] = 'gentle_chime';
      baseStyle['vibration'] = [0, 100];
    }

    return baseStyle;
  }

  // ============= PRIVATE HELPER METHODS =============

  static Map<String, dynamic> _getDefaultOptimalTime(String notificationType) {
    final defaultTimes = {
      'feeding_reminder': {'optimalHour': 8, 'confidence': 0.5},
      'sleep_time': {'optimalHour': 20, 'confidence': 0.7},
      'milestone_reminder': {'optimalHour': 10, 'confidence': 0.6},
      'development_tip': {'optimalHour': 14, 'confidence': 0.5},
      'health_alert': {'optimalHour': 9, 'confidence': 0.8},
    };

    return defaultTimes[notificationType] ?? {'optimalHour': 12, 'confidence': 0.5};
  }

  static int _calculateOptimalHour(List<dynamic> interactionTimes) {
    final hours = interactionTimes
        .map((interaction) => interaction['hour'] as int)
        .toList();

    if (hours.isEmpty) return 12;

    // Calculate weighted average with recent interactions having more weight
    double totalWeight = 0;
    double weightedSum = 0;

    for (int i = 0; i < hours.length; i++) {
      final weight = (i + 1) / hours.length; // More recent = higher weight
      totalWeight += weight;
      weightedSum += hours[i] * weight;
    }

    return (weightedSum / totalWeight).round();
  }

  static double _calculateConfidence(List<dynamic> interactionTimes) {
    if (interactionTimes.length < 3) return 0.3;
    if (interactionTimes.length < 10) return 0.6;
    if (interactionTimes.length < 20) return 0.8;
    return 0.9;
  }

  static String _generateReasoning(String notificationType, int optimalHour, double confidence) {
    if (confidence > 0.8) {
      return 'Based on your interaction history, you\'re most responsive at ${optimalHour}:00';
    } else if (confidence > 0.5) {
      return 'You tend to engage with ${notificationType} notifications around ${optimalHour}:00';
    } else {
      return 'Optimal time estimated based on general patterns for ${notificationType}';
    }
  }

  static List<int> _generateAlternativeTimes(int optimalHour) {
    return [
      (optimalHour - 2).clamp(6, 22),
      (optimalHour + 2).clamp(6, 22),
      (optimalHour - 4).clamp(6, 22),
    ];
  }

  static int _calculateAgeInMonths(String birthDate) {
    final birth = DateTime.parse(birthDate);
    final now = DateTime.now();
    return ((now.difference(birth).inDays) / 30).round();
  }

  static String _getDevelopmentStage(int ageInMonths) {
    if (ageInMonths < 6) return 'infant';
    if (ageInMonths < 12) return 'mobile_infant';
    if (ageInMonths < 24) return 'toddler_early';
    if (ageInMonths < 36) return 'toddler_late';
    return 'preschooler';
  }

  static Future<Map<String, dynamic>> _generateSmartContent({
    required String notificationType,
    required Map<String, dynamic> childData,
    required String developmentStage,
    required String language,
  }) async {
    final childName = childData['name'] ?? 'your child';

    final contentTemplates = {
      'en': {
        'feeding_reminder': {
          'title': '🍎 Feeding Time for $childName',
          'body': 'Time for a nutritious meal! $childName might be getting hungry.',
          'emoji': '🍎',
          'tip': 'Try introducing new textures appropriate for ${_getDevelopmentStage(_calculateAgeInMonths(childData['birthDate']))} stage',
        },
        'sleep_time': {
          'title': '😴 Bedtime for $childName',
          'body': 'Creating a calm bedtime routine helps $childName sleep better.',
          'emoji': '🌙',
          'tip': 'Consistent bedtime routines improve sleep quality by 40%',
        },
        'milestone_reminder': {
          'title': '🎉 Milestone Check for $childName',
          'body': 'Time to celebrate $childName\'s amazing progress!',
          'emoji': '🎉',
          'tip': 'Every child develops at their own pace - celebrate the small wins!',
        },
        'development_tip': {
          'title': '💡 Daily Tip for $childName',
          'body': 'Here\'s a personalized development activity for $childName today.',
          'emoji': '🧠',
          'tip': 'Short, frequent activities are more effective than long sessions',
        },
      },
      'ru': {
        'feeding_reminder': {
          'title': '🍎 Время кормления для $childName',
          'body': 'Время для питательной еды! $childName может проголодаться.',
          'emoji': '🍎',
          'tip': 'Попробуйте новые текстуры, подходящие для стадии ${_getDevelopmentStage(_calculateAgeInMonths(childData['birthDate']))}',
        },
        'sleep_time': {
          'title': '😴 Время сна для $childName',
          'body': 'Спокойный ритуал перед сном поможет $childName лучше спать.',
          'emoji': '🌙',
          'tip': 'Постоянные ритуалы перед сном улучшают качество сна на 40%',
        },
        'milestone_reminder': {
          'title': '🎉 Проверка этапов для $childName',
          'body': 'Время отпраздновать удивительный прогресс $childName!',
          'emoji': '🎉',
          'tip': 'Каждый ребенок развивается в своем темпе - празднуйте маленькие победы!',
        },
        'development_tip': {
          'title': '💡 Ежедневный совет для $childName',
          'body': 'Вот персонализированная развивающая активность для $childName на сегодня.',
          'emoji': '🧠',
          'tip': 'Короткие, частые активности эффективнее длинных сессий',
        },
      },
    };

    final langContent = contentTemplates[language] ?? contentTemplates['en']!;
    return langContent[notificationType] ?? langContent['development_tip']!;
  }

  static List<Map<String, String>> _generateContextualActions(String notificationType, Map<String, dynamic> childData) {
    final baseActions = {
      'feeding_reminder': [
        {'action': 'log_feeding', 'title': 'Log Feeding'},
        {'action': 'set_reminder', 'title': 'Remind Later'},
      ],
      'sleep_time': [
        {'action': 'start_bedtime', 'title': 'Start Routine'},
        {'action': 'delay_bedtime', 'title': 'Delay 30 min'},
      ],
      'milestone_reminder': [
        {'action': 'log_milestone', 'title': 'Log Progress'},
        {'action': 'view_tips', 'title': 'Get Tips'},
      ],
      'development_tip': [
        {'action': 'try_activity', 'title': 'Try Now'},
        {'action': 'save_for_later', 'title': 'Save for Later'},
      ],
    };

    return baseActions[notificationType] ?? [];
  }

  static int _calculatePriority(String notificationType, Map<String, dynamic> childData) {
    final basePriorities = {
      'health_alert': 10,
      'feeding_reminder': 7,
      'sleep_time': 6,
      'milestone_reminder': 5,
      'development_tip': 3,
    };

    return basePriorities[notificationType] ?? 5;
  }

  static String _generateDeepLink(String notificationType, String childId) {
    return 'masterparenthood://notification/$notificationType?childId=$childId';
  }

  static Map<String, dynamic> _getDefaultNotification(String notificationType, String language) {
    return {
      'title': 'Master Parenthood',
      'body': 'You have a new notification',
      'emoji': '📱',
      'priority': 5,
      'actions': [],
      'deepLink': 'masterparenthood://home',
      'personalizedTip': 'Check the app for more details',
    };
  }

  static int _getDailyLimit(String notificationType) {
    final limits = {
      'feeding_reminder': 6,
      'sleep_time': 2,
      'milestone_reminder': 1,
      'development_tip': 3,
      'health_alert': 5,
    };

    return limits[notificationType] ?? 3;
  }

  static bool _isValidTimeForNotification(int hour, String notificationType) {
    // General quiet hours: 22:00 - 7:00
    if (hour < 7 || hour > 22) {
      return notificationType == 'health_alert'; // Only health alerts allowed during quiet hours
    }

    // Type-specific time restrictions
    switch (notificationType) {
      case 'sleep_time':
        return hour >= 18 && hour <= 22;
      case 'feeding_reminder':
        return hour >= 6 && hour <= 21;
      case 'development_tip':
        return hour >= 9 && hour <= 20;
      default:
        return true;
    }
  }

  static Future<double> _calculateEngagementScore(String userId, String notificationType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final patternsJson = prefs.getString('${_userPatternKey}_$userId') ?? '{}';
      final patterns = jsonDecode(patternsJson) as Map<String, dynamic>;

      final typeInteractions = patterns[notificationType] as List<dynamic>? ?? [];
      if (typeInteractions.isEmpty) return 0.5; // Neutral score for new users

      final recentInteractions = typeInteractions.take(20).toList();
      final engagementActions = recentInteractions
          .where((interaction) => interaction['action'] == 'opened' || interaction['action'] == 'clicked_action')
          .length;

      return (engagementActions / recentInteractions.length).clamp(0.0, 1.0);
    } catch (e) {
      return 0.5;
    }
  }

  static Future<double> _predictUserEngagement({
    required String userId,
    required String notificationType,
    required int currentHour,
    required Map<String, dynamic> recentHistory,
  }) async {
    // Simple ML prediction based on multiple factors
    double score = 0.5; // Base score

    // Factor 1: Time of day preference
    final optimalTime = await calculateOptimalNotificationTime(
      notificationType: notificationType,
      userId: userId,
    );
    final hourDifference = (currentHour - (optimalTime['optimalHour'] as int)).abs();
    final timeScore = (1.0 - (hourDifference / 12.0)).clamp(0.0, 1.0);
    score += timeScore * 0.3;

    // Factor 2: Recent notification frequency
    final todayCount = recentHistory.length;
    final frequencyScore = todayCount < 3 ? 1.0 : (1.0 - ((todayCount - 3) / 10.0)).clamp(0.0, 1.0);
    score += frequencyScore * 0.2;

    // Factor 3: User engagement history
    final engagementScore = await _calculateEngagementScore(userId, notificationType);
    score += engagementScore * 0.3;

    // Factor 4: Day of week patterns (weekdays vs weekends)
    final isWeekend = DateTime.now().weekday > 5;
    final dayScore = notificationType == 'development_tip'
        ? (isWeekend ? 0.8 : 1.0) // Development tips better on weekdays
        : 1.0;
    score += dayScore * 0.2;

    return score.clamp(0.0, 1.0);
  }
}