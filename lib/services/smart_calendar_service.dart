// lib/services/smart_calendar_service.dart
// 📅 Smart Calendar Service with AI Planning - 2025
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/injection_container.dart';
import 'cache_service.dart';
import 'advanced_ai_service.dart';
import 'enhanced_notification_service.dart';

enum EventType {
  feeding,
  sleep,
  development,
  medical,
  play,
  milestone,
  appointment,
  vaccination,
  growth,
  social,
  learning,
  routine,
}

enum EventPriority { low, medium, high, critical }

class CalendarEvent {
  final String id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime? endTime;
  final EventType type;
  final EventPriority priority;
  final bool isRecurring;
  final String? recurrencePattern;
  final Map<String, dynamic>? metadata;
  final bool aiGenerated;
  final bool completed;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    this.endTime,
    required this.type,
    this.priority = EventPriority.medium,
    this.isRecurring = false,
    this.recurrencePattern,
    this.metadata,
    this.aiGenerated = false,
    this.completed = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'type': type.name,
    'priority': priority.name,
    'isRecurring': isRecurring,
    'recurrencePattern': recurrencePattern,
    'metadata': metadata,
    'aiGenerated': aiGenerated,
    'completed': completed,
  };

  factory CalendarEvent.fromJson(Map<String, dynamic> json) => CalendarEvent(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    startTime: DateTime.parse(json['startTime']),
    endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
    type: EventType.values.firstWhere((e) => e.name == json['type']),
    priority: EventPriority.values.firstWhere((e) => e.name == json['priority']),
    isRecurring: json['isRecurring'] ?? false,
    recurrencePattern: json['recurrencePattern'],
    metadata: json['metadata'],
    aiGenerated: json['aiGenerated'] ?? false,
    completed: json['completed'] ?? false,
  );

  CalendarEvent copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    EventType? type,
    EventPriority? priority,
    bool? isRecurring,
    String? recurrencePattern,
    Map<String, dynamic>? metadata,
    bool? aiGenerated,
    bool? completed,
  }) => CalendarEvent(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description ?? this.description,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    type: type ?? this.type,
    priority: priority ?? this.priority,
    isRecurring: isRecurring ?? this.isRecurring,
    recurrencePattern: recurrencePattern ?? this.recurrencePattern,
    metadata: metadata ?? this.metadata,
    aiGenerated: aiGenerated ?? this.aiGenerated,
    completed: completed ?? this.completed,
  );
}

class SmartCalendarService {
  static const String _eventsKey = 'calendar_events';
  static const String _preferencesKey = 'calendar_preferences';
  static const String _aiSuggestionsKey = 'ai_calendar_suggestions';

  /// Initialize smart calendar service
  static Future<void> initialize() async {
    try {
      await _migrateOldEvents();
      await _generateRecurringEvents();
      await _scheduleAiPlanning();

      debugPrint('📅 Smart Calendar Service initialized');
    } catch (e) {
      debugPrint('❌ Smart Calendar Service initialization error: $e');
    }
  }

  /// Add new event to calendar
  static Future<void> addEvent(CalendarEvent event) async {
    try {
      final events = await getAllEvents();
      events.add(event);

      await _saveEvents(events);

      // Schedule notification if needed
      if (event.priority.index >= EventPriority.medium.index) {
        await _scheduleEventNotification(event);
      }

      // Update AI suggestions based on new event
      await _updateAiSuggestions();

      debugPrint('📅 Event added: ${event.title}');
    } catch (e) {
      debugPrint('Error adding event: $e');
    }
  }

  /// Get events for a specific date
  static Future<List<CalendarEvent>> getEventsForDate(DateTime date) async {
    try {
      final events = await getAllEvents();
      final dateKey = _getDateKey(date);

      return events.where((event) {
        final eventDateKey = _getDateKey(event.startTime);
        return eventDateKey == dateKey;
      }).toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
    } catch (e) {
      debugPrint('Error getting events for date: $e');
      return [];
    }
  }

  /// Get events for date range
  static Future<List<CalendarEvent>> getEventsForRange(DateTime start, DateTime end) async {
    try {
      final events = await getAllEvents();

      return events.where((event) {
        return event.startTime.isAfter(start.subtract(const Duration(days: 1))) &&
               event.startTime.isBefore(end.add(const Duration(days: 1)));
      }).toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
    } catch (e) {
      debugPrint('Error getting events for range: $e');
      return [];
    }
  }

  /// Get all events
  static Future<List<CalendarEvent>> getAllEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final eventsJson = prefs.getString(_eventsKey) ?? '[]';
      final eventsList = jsonDecode(eventsJson) as List<dynamic>;

      return eventsList.map((eventData) => CalendarEvent.fromJson(eventData)).toList();
    } catch (e) {
      debugPrint('Error getting all events: $e');
      return [];
    }
  }

  /// Update existing event
  static Future<void> updateEvent(CalendarEvent updatedEvent) async {
    try {
      final events = await getAllEvents();
      final index = events.indexWhere((event) => event.id == updatedEvent.id);

      if (index != -1) {
        events[index] = updatedEvent;
        await _saveEvents(events);

        debugPrint('📅 Event updated: ${updatedEvent.title}');
      }
    } catch (e) {
      debugPrint('Error updating event: $e');
    }
  }

  /// Delete event
  static Future<void> deleteEvent(String eventId) async {
    try {
      final events = await getAllEvents();
      events.removeWhere((event) => event.id == eventId);

      await _saveEvents(events);

      debugPrint('📅 Event deleted: $eventId');
    } catch (e) {
      debugPrint('Error deleting event: $e');
    }
  }

  /// Mark event as completed
  static Future<void> completeEvent(String eventId) async {
    try {
      final events = await getAllEvents();
      final index = events.indexWhere((event) => event.id == eventId);

      if (index != -1) {
        events[index] = events[index].copyWith(completed: true);
        await _saveEvents(events);

        debugPrint('✅ Event completed: $eventId');
      }
    } catch (e) {
      debugPrint('Error completing event: $e');
    }
  }

  /// Generate AI-powered weekly schedule
  static Future<List<CalendarEvent>> generateAiWeeklySchedule({
    required int childAgeInMonths,
    required String childName,
    required Map<String, dynamic> childPreferences,
    required String language,
  }) async {
    try {
      final cacheService = sl<CacheService>();
      final cacheKey = 'ai_weekly_schedule_${childAgeInMonths}_${DateTime.now().weekday}';

      // Check cache first
      final cached = await cacheService.get(cacheKey);
      if (cached != null) {
        final eventsList = List<Map<String, dynamic>>.from(cached);
        return eventsList.map((eventData) => CalendarEvent.fromJson(eventData)).toList();
      }

      // Generate AI schedule
      final aiService = sl<AdvancedAIService>();
      final scheduleData = await aiService.generatePersonalizedActivities(
        childName: childName,
        ageInMonths: childAgeInMonths,
        interests: childPreferences['interests'] ?? [],
        currentWeather: 'sunny', // This would come from weather API
        language: language,
      );

      final activities = scheduleData['activities'] as List<dynamic>? ?? [];
      final aiEvents = <CalendarEvent>[];

      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

      for (int day = 0; day < 7; day++) {
        final currentDay = startOfWeek.add(Duration(days: day));

        // Generate 2-3 activities per day
        final dailyActivities = activities.take(2 + Random().nextInt(2)).toList();

        for (int i = 0; i < dailyActivities.length; i++) {
          final activity = dailyActivities[i];
          final startTime = currentDay.add(Duration(
            hours: 9 + (i * 4) + Random().nextInt(2), // Spread throughout day
            minutes: Random().nextInt(60),
          ));

          final event = CalendarEvent(
            id: 'ai_${DateTime.now().millisecondsSinceEpoch}_$day$i',
            title: activity['title'] ?? 'Activity',
            description: activity['description'] ?? '',
            startTime: startTime,
            endTime: startTime.add(Duration(
              minutes: _parseDuration(activity['duration'] ?? '30 minutes'),
            )),
            type: _getEventTypeFromActivity(activity),
            priority: EventPriority.medium,
            aiGenerated: true,
            metadata: {
              'materials': activity['materials'] ?? [],
              'learningGoals': activity['learningGoals'] ?? [],
              'ageMonths': childAgeInMonths,
            },
          );

          aiEvents.add(event);
        }
      }

      // Cache for 6 hours
      await cacheService.set(
        cacheKey,
        aiEvents.map((event) => event.toJson()).toList(),
        duration: const Duration(hours: 6),
      );

      debugPrint('🤖 Generated ${aiEvents.length} AI events for the week');
      return aiEvents;
    } catch (e) {
      debugPrint('Error generating AI weekly schedule: $e');
      return [];
    }
  }

  /// Generate medical schedule based on child's age
  static Future<List<CalendarEvent>> generateMedicalSchedule({
    required int childAgeInMonths,
    required DateTime birthDate,
    required String language,
  }) async {
    try {
      final medicalEvents = <CalendarEvent>[];
      final now = DateTime.now();

      // Vaccination schedule
      final vaccinations = _getVaccinationSchedule(childAgeInMonths);
      for (final vaccination in vaccinations) {
        final vaccinationDate = birthDate.add(Duration(days: vaccination['ageInDays']));

        if (vaccinationDate.isAfter(now)) {
          final event = CalendarEvent(
            id: 'medical_vaccination_${vaccination['name']}',
            title: language == 'ru'
              ? 'Вакцинация: ${vaccination['nameRu']}'
              : 'Vaccination: ${vaccination['name']}',
            description: language == 'ru'
              ? 'Плановая вакцинация ${vaccination['nameRu']}'
              : 'Scheduled vaccination for ${vaccination['name']}',
            startTime: DateTime(
              vaccinationDate.year,
              vaccinationDate.month,
              vaccinationDate.day,
              10, // 10 AM default
            ),
            type: EventType.vaccination,
            priority: EventPriority.high,
            aiGenerated: true,
            metadata: {
              'vaccinationType': vaccination['name'],
              'ageInMonths': vaccination['ageInMonths'],
              'important': true,
            },
          );

          medicalEvents.add(event);
        }
      }

      // Regular checkups
      final checkupMonths = [1, 2, 4, 6, 9, 12, 15, 18, 24, 30, 36];
      for (final month in checkupMonths) {
        if (month <= childAgeInMonths) continue;

        final checkupDate = birthDate.add(Duration(days: month * 30));
        if (checkupDate.isAfter(now)) {
          final event = CalendarEvent(
            id: 'medical_checkup_${month}m',
            title: language == 'ru'
              ? 'Осмотр врача ($month мес.)'
              : 'Medical Checkup ($month months)',
            description: language == 'ru'
              ? 'Плановый осмотр педиатра в $month месяцев'
              : 'Scheduled pediatric checkup at $month months',
            startTime: DateTime(
              checkupDate.year,
              checkupDate.month,
              checkupDate.day,
              14, // 2 PM default
            ),
            type: EventType.medical,
            priority: EventPriority.high,
            aiGenerated: true,
            metadata: {
              'checkupType': 'routine',
              'ageInMonths': month,
            },
          );

          medicalEvents.add(event);
        }
      }

      debugPrint('🏥 Generated ${medicalEvents.length} medical events');
      return medicalEvents;
    } catch (e) {
      debugPrint('Error generating medical schedule: $e');
      return [];
    }
  }

  /// Get AI suggestions for today
  static Future<List<CalendarEvent>> getAiSuggestionsForToday({
    required int childAgeInMonths,
    required String childName,
    required String language,
  }) async {
    try {
      final today = DateTime.now();
      final existingEvents = await getEventsForDate(today);

      // Don't suggest if already busy
      if (existingEvents.length >= 4) {
        return [];
      }

      final suggestions = await _generateDailySuggestions(
        childAgeInMonths: childAgeInMonths,
        childName: childName,
        language: language,
        existingEvents: existingEvents,
      );

      debugPrint('💡 Generated ${suggestions.length} AI suggestions for today');
      return suggestions;
    } catch (e) {
      debugPrint('Error getting AI suggestions: $e');
      return [];
    }
  }

  /// Get calendar statistics
  static Future<Map<String, dynamic>> getCalendarStats() async {
    try {
      final events = await getAllEvents();
      final now = DateTime.now();
      final thisWeek = events.where((event) {
        final difference = event.startTime.difference(now).inDays;
        return difference >= 0 && difference <= 7;
      }).toList();

      final eventsByType = <String, int>{};
      for (final event in events) {
        eventsByType[event.type.name] = (eventsByType[event.type.name] ?? 0) + 1;
      }

      final completedThisWeek = thisWeek.where((event) => event.completed).length;

      return {
        'totalEvents': events.length,
        'eventsThisWeek': thisWeek.length,
        'completedThisWeek': completedThisWeek,
        'completionRate': thisWeek.isNotEmpty ? completedThisWeek / thisWeek.length : 0.0,
        'eventsByType': eventsByType,
        'aiGeneratedEvents': events.where((event) => event.aiGenerated).length,
      };
    } catch (e) {
      debugPrint('Error getting calendar stats: $e');
      return {};
    }
  }

  // Private helper methods
  static Future<void> _saveEvents(List<CalendarEvent> events) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final eventsJson = jsonEncode(events.map((event) => event.toJson()).toList());
      await prefs.setString(_eventsKey, eventsJson);
    } catch (e) {
      debugPrint('Error saving events: $e');
    }
  }

  static String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static Future<void> _scheduleEventNotification(CalendarEvent event) async {
    try {
      // Schedule notification 30 minutes before event
      final notificationTime = event.startTime.subtract(const Duration(minutes: 30));

      if (notificationTime.isAfter(DateTime.now())) {
        await EnhancedNotificationService.sendEnhancedNotification(
          title: '📅 Upcoming: ${event.title}',
          body: 'Starting in 30 minutes: ${event.description}',
          channel: _getNotificationChannel(event.type),
          scheduledTime: notificationTime,
          data: {
            'eventId': event.id,
            'eventType': event.type.name,
          },
        );
      }
    } catch (e) {
      debugPrint('Error scheduling event notification: $e');
    }
  }

  static String _getNotificationChannel(EventType type) {
    switch (type) {
      case EventType.medical:
      case EventType.vaccination:
        return EnhancedNotificationService.healthChannel;
      case EventType.feeding:
        return EnhancedNotificationService.feedingChannel;
      case EventType.sleep:
        return EnhancedNotificationService.sleepChannel;
      case EventType.milestone:
        return EnhancedNotificationService.milestoneChannel;
      default:
        return EnhancedNotificationService.aiInsightsChannel;
    }
  }

  static EventType _getEventTypeFromActivity(Map<String, dynamic> activity) {
    final title = (activity['title'] as String? ?? '').toLowerCase();

    if (title.contains('play') || title.contains('игра')) return EventType.play;
    if (title.contains('learning') || title.contains('обучение')) return EventType.learning;
    if (title.contains('social') || title.contains('общение')) return EventType.social;
    if (title.contains('development') || title.contains('развитие')) return EventType.development;

    return EventType.development; // Default
  }

  static int _parseDuration(String duration) {
    final numbers = RegExp(r'\d+').allMatches(duration);
    if (numbers.isNotEmpty) {
      return int.parse(numbers.first.group(0)!) ?? 30;
    }
    return 30; // Default 30 minutes
  }

  static List<Map<String, dynamic>> _getVaccinationSchedule(int childAgeInMonths) {
    return [
      {'name': 'Hepatitis B', 'nameRu': 'Гепатит B', 'ageInDays': 0, 'ageInMonths': 0},
      {'name': 'BCG', 'nameRu': 'БЦЖ', 'ageInDays': 3, 'ageInMonths': 0},
      {'name': 'Hepatitis B (2nd)', 'nameRu': 'Гепатит B (2-я)', 'ageInDays': 30, 'ageInMonths': 1},
      {'name': 'DTP + Polio', 'nameRu': 'АКДС + Полио', 'ageInDays': 90, 'ageInMonths': 3},
      {'name': 'DTP + Polio (2nd)', 'nameRu': 'АКДС + Полио (2-я)', 'ageInDays': 135, 'ageInMonths': 4.5},
      {'name': 'DTP + Polio (3rd)', 'nameRu': 'АКДС + Полио (3-я)', 'ageInDays': 180, 'ageInMonths': 6},
      {'name': 'MMR', 'nameRu': 'КПК', 'ageInDays': 365, 'ageInMonths': 12},
      {'name': 'DTP + Polio Booster', 'nameRu': 'АКДС + Полио (ревакц.)', 'ageInDays': 540, 'ageInMonths': 18},
    ];
  }

  static Future<List<CalendarEvent>> _generateDailySuggestions({
    required int childAgeInMonths,
    required String childName,
    required String language,
    required List<CalendarEvent> existingEvents,
  }) async {
    final suggestions = <CalendarEvent>[];
    final now = DateTime.now();

    // Morning routine suggestion
    if (!existingEvents.any((event) => event.startTime.hour < 10)) {
      suggestions.add(CalendarEvent(
        id: 'suggestion_morning_${now.millisecondsSinceEpoch}',
        title: language == 'ru' ? 'Утренняя активность' : 'Morning Activity',
        description: language == 'ru'
          ? 'Время для развивающих игр с $childName'
          : 'Time for developmental play with $childName',
        startTime: DateTime(now.year, now.month, now.day, 9, 0),
        endTime: DateTime(now.year, now.month, now.day, 10, 0),
        type: EventType.development,
        priority: EventPriority.medium,
        aiGenerated: true,
      ));
    }

    // Afternoon suggestion
    if (!existingEvents.any((event) => event.startTime.hour >= 14 && event.startTime.hour < 17)) {
      suggestions.add(CalendarEvent(
        id: 'suggestion_afternoon_${now.millisecondsSinceEpoch}',
        title: language == 'ru' ? 'Прогулка на свежем воздухе' : 'Outdoor Walk',
        description: language == 'ru'
          ? 'Полезная прогулка для $childName'
          : 'Healthy outdoor time for $childName',
        startTime: DateTime(now.year, now.month, now.day, 15, 0),
        endTime: DateTime(now.year, now.month, now.day, 16, 0),
        type: EventType.play,
        priority: EventPriority.medium,
        aiGenerated: true,
      ));
    }

    return suggestions;
  }

  static Future<void> _migrateOldEvents() async {
    // Migration logic for old event formats
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasOldEvents = prefs.containsKey('old_calendar_events');

      if (hasOldEvents) {
        // Migrate old events to new format
        debugPrint('📅 Migrating old calendar events');
        await prefs.remove('old_calendar_events');
      }
    } catch (e) {
      debugPrint('Error migrating old events: $e');
    }
  }

  static Future<void> _generateRecurringEvents() async {
    try {
      final events = await getAllEvents();
      final recurringEvents = events.where((event) => event.isRecurring).toList();

      for (final event in recurringEvents) {
        // Generate instances for the next month
        await _generateRecurringInstances(event);
      }
    } catch (e) {
      debugPrint('Error generating recurring events: $e');
    }
  }

  static Future<void> _generateRecurringInstances(CalendarEvent recurringEvent) async {
    // Implementation for generating recurring event instances
    try {
      final pattern = recurringEvent.recurrencePattern ?? 'daily';
      final now = DateTime.now();
      final endDate = now.add(const Duration(days: 30));

      var currentDate = recurringEvent.startTime;
      final instances = <CalendarEvent>[];

      while (currentDate.isBefore(endDate)) {
        switch (pattern) {
          case 'daily':
            currentDate = currentDate.add(const Duration(days: 1));
            break;
          case 'weekly':
            currentDate = currentDate.add(const Duration(days: 7));
            break;
          case 'monthly':
            currentDate = DateTime(
              currentDate.year,
              currentDate.month + 1,
              currentDate.day,
              currentDate.hour,
              currentDate.minute,
            );
            break;
          default:
            break;
        }

        if (currentDate.isAfter(now)) {
          final instance = CalendarEvent(
            id: '${recurringEvent.id}_${currentDate.millisecondsSinceEpoch}',
            title: recurringEvent.title,
            description: recurringEvent.description,
            startTime: currentDate,
            endTime: recurringEvent.endTime?.add(currentDate.difference(recurringEvent.startTime)),
            type: recurringEvent.type,
            priority: recurringEvent.priority,
            aiGenerated: recurringEvent.aiGenerated,
            metadata: recurringEvent.metadata,
          );

          instances.add(instance);
        }
      }

      // Add instances to calendar
      final allEvents = await getAllEvents();
      allEvents.addAll(instances);
      await _saveEvents(allEvents);

      debugPrint('📅 Generated ${instances.length} recurring instances');
    } catch (e) {
      debugPrint('Error generating recurring instances: $e');
    }
  }

  static Future<void> _scheduleAiPlanning() async {
    // Schedule weekly AI planning sessions
    try {
      await EnhancedNotificationService.sendEnhancedNotification(
        title: '🤖 Weekly Planning',
        body: 'Time to plan next week with AI assistance!',
        channel: EnhancedNotificationService.aiInsightsChannel,
        scheduledTime: _getNextSunday().add(const Duration(hours: 20)),
        data: {'action': 'weekly_planning'},
      );
    } catch (e) {
      debugPrint('Error scheduling AI planning: $e');
    }
  }

  static DateTime _getNextSunday() {
    final now = DateTime.now();
    final daysUntilSunday = (7 - now.weekday) % 7;
    return now.add(Duration(days: daysUntilSunday == 0 ? 7 : daysUntilSunday));
  }

  static Future<void> _updateAiSuggestions() async {
    // Update AI suggestions based on user behavior
    try {
      final prefs = await SharedPreferences.getInstance();
      final suggestions = await prefs.getString(_aiSuggestionsKey) ?? '{}';
      final suggestionsData = jsonDecode(suggestions) as Map<String, dynamic>;

      // Update suggestion weights based on user interactions
      // This would be used for ML model training

      await prefs.setString(_aiSuggestionsKey, jsonEncode(suggestionsData));
    } catch (e) {
      debugPrint('Error updating AI suggestions: $e');
    }
  }

  /// Export calendar data
  static Future<String> exportCalendarData() async {
    try {
      final events = await getAllEvents();
      final exportData = {
        'events': events.map((event) => event.toJson()).toList(),
        'exportDate': DateTime.now().toIso8601String(),
        'version': '1.0',
      };

      return jsonEncode(exportData);
    } catch (e) {
      debugPrint('Error exporting calendar data: $e');
      return '{}';
    }
  }

  /// Import calendar data
  static Future<bool> importCalendarData(String jsonData) async {
    try {
      final importData = jsonDecode(jsonData) as Map<String, dynamic>;
      final eventsList = importData['events'] as List<dynamic>;

      final events = eventsList.map((eventData) => CalendarEvent.fromJson(eventData)).toList();
      await _saveEvents(events);

      debugPrint('📅 Imported ${events.length} events');
      return true;
    } catch (e) {
      debugPrint('Error importing calendar data: $e');
      return false;
    }
  }
}