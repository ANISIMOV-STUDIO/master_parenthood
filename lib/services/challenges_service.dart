// lib/services/challenges_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'firebase_service.dart';

class ChallengesService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Предопределенные челленджи по категориям и возрастам
  static final Map<String, Map<String, List<Map<String, dynamic>>>> _challengeTemplates = {
    '0-1': {
      'physical': [
        {
          'title': 'Время на животике',
          'description': 'Проведите 15 минут игр на животике с малышом',
          'tips': [
            'Используйте яркие игрушки для привлечения внимания',
            'Начните с коротких сессий по 3-5 минут',
            'Лучшее время - через час после кормления'
          ],
          'xpReward': 50,
        },
        {
          'title': 'Массаж для малыша',
          'description': 'Сделайте легкий массаж ручек и ножек перед сном',
          'tips': [
            'Используйте детское масло',
            'Делайте мягкие круговые движения',
            'Следите за реакцией малыша'
          ],
          'xpReward': 40,
        },
      ],
      'cognitive': [
        {
          'title': 'Контрастные картинки',
          'description': 'Покажите малышу черно-белые контрастные изображения',
          'tips': [
            'Держите картинки на расстоянии 20-30 см',
            'Меняйте картинки каждые 20-30 секунд',
            'Наблюдайте за реакцией глаз малыша'
          ],
          'xpReward': 30,
        },
      ],
    },
    '1-2': {
      'physical': [
        {
          'title': 'Танцевальная вечеринка',
          'description': 'Устройте 10-минутную танцевальную вечеринку с малышом',
          'tips': [
            'Выберите веселую детскую музыку',
            'Покажите простые движения',
            'Хвалите за попытки повторить'
          ],
          'xpReward': 60,
        },
        {
          'title': 'Полоса препятствий',
          'description': 'Создайте простую полосу препятствий из подушек',
          'tips': [
            'Используйте мягкие подушки и одеяла',
            'Покажите как преодолевать препятствия',
            'Страхуйте малыша'
          ],
          'xpReward': 70,
        },
      ],
    },
  };

  // Недельные челленджи
  static final List<Map<String, dynamic>> _weeklyChallengeTemplates = [
    {
      'title': 'Неделя активности',
      'description': 'Проводите активные игры каждый день',
      'category': 'physical',
      'targetCount': 7,
      'xpReward': 500,
    },
    {
      'title': 'Неделя творчества',
      'description': 'Каждый день создавайте что-то новое',
      'category': 'creative',
      'targetCount': 7,
      'xpReward': 500,
    },
  ];

  // Генерация ежедневных челленджей
  static Future<void> generateDailyChallenges(String? childId) async {
    if (!FirebaseService.isAuthenticated) return;

    try {
      final child = childId != null
          ? await FirebaseService.getChild(childId)
          : await FirebaseService.getActiveChild();

      if (child == null) return;

      // Определяем возрастную группу
      String ageGroup;
      if (child.ageInMonths < 12) {
        ageGroup = '0-1';
      } else if (child.ageInMonths < 24) {
        ageGroup = '1-2';
      } else if (child.ageInMonths < 36) {
        ageGroup = '2-3';
      } else {
        ageGroup = '3+';
      }

      final templates = _challengeTemplates[ageGroup] ?? {};

      // Создаем коллекцию челленджей на сегодня
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final batch = _firestore.batch();

      // Выбираем по одному челленджу из каждой категории
      for (final category in templates.keys) {
        final categoryTemplates = templates[category]!;
        if (categoryTemplates.isNotEmpty) {
          // Случайный выбор челленджа из категории
          final randomIndex = DateTime.now().millisecondsSinceEpoch % categoryTemplates.length;
          final template = categoryTemplates[randomIndex];

          final challengeRef = _firestore
              .collection('users')
              .doc(FirebaseService.currentUserId!)
              .collection('challenges')
              .doc();

          batch.set(challengeRef, {
            'id': challengeRef.id,
            'childId': child.id,
            'title': template['title'],
            'description': template['description'],
            'category': category,
            'type': 'daily',
            'xpReward': template['xpReward'],
            'tips': template['tips'],
            'isCompleted': false,
            'completedCount': 0,
            'createdAt': FieldValue.serverTimestamp(),
            'dateStr': todayStr,
          });
        }
      }

      await batch.commit();
    } catch (e) {
      if (kDebugMode) {
        print('Error generating challenges: $e');
      }
    }
  }

  // Генерация недельного челленджа
  static Future<void> generateWeeklyChallenge(String? childId) async {
    if (!FirebaseService.isAuthenticated) return;

    try {
      final child = childId != null
          ? await FirebaseService.getChild(childId)
          : await FirebaseService.getActiveChild();

      if (child == null) return;

      // Выбираем случайный недельный челлендж
      final randomIndex = DateTime.now().millisecondsSinceEpoch % _weeklyChallengeTemplates.length;
      final template = _weeklyChallengeTemplates[randomIndex];

      final weekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));

      await _firestore
          .collection('users')
          .doc(FirebaseService.currentUserId!)
          .collection('challenges')
          .add({
        'childId': child.id,
        'title': template['title'],
        'description': template['description'],
        'category': template['category'],
        'type': 'weekly',
        'xpReward': template['xpReward'],
        'targetCount': template['targetCount'],
        'progress': 0,
        'completedCount': 0,
        'isCompleted': false,
        'createdAt': FieldValue.serverTimestamp(),
        'weekStart': Timestamp.fromDate(weekStart),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error generating weekly challenge: $e');
      }
    }
  }

  // Stream ежедневных челленджей
  static Stream<List<Challenge>> getDailyChallengesStream({String? childId}) {
    if (!FirebaseService.isAuthenticated) return Stream.value([]);

    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    var query = _firestore
        .collection('users')
        .doc(FirebaseService.currentUserId!)
        .collection('challenges')
        .where('type', isEqualTo: 'daily')
        .where('dateStr', isEqualTo: todayStr);

    if (childId != null) {
      query = query.where('childId', isEqualTo: childId);
    }

    return query
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Challenge.fromFirestore(doc.data(), doc.id))
        .toList());
  }

  // Stream недельных челленджей
  static Stream<List<Challenge>> getWeeklyChallengesStream({String? childId}) {
    if (!FirebaseService.isAuthenticated) return Stream.value([]);

    final weekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));

    var query = _firestore
        .collection('users')
        .doc(FirebaseService.currentUserId!)
        .collection('challenges')
        .where('type', isEqualTo: 'weekly')
        .where('weekStart', isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart));

    if (childId != null) {
      query = query.where('childId', isEqualTo: childId);
    }

    return query
        .orderBy('weekStart', descending: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Challenge.fromFirestore(doc.data(), doc.id))
        .toList());
  }

  // Stream выполненных челленджей
  static Stream<List<Challenge>> getCompletedChallengesStream({String? childId}) {
    if (!FirebaseService.isAuthenticated) return Stream.value([]);

    var query = _firestore
        .collection('users')
        .doc(FirebaseService.currentUserId!)
        .collection('challenges')
        .where('isCompleted', isEqualTo: true);

    if (childId != null) {
      query = query.where('childId', isEqualTo: childId);
    }

    return query
        .orderBy('completedAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Challenge.fromFirestore(doc.data(), doc.id))
        .toList());
  }

  // Выполнить челлендж
  static Future<void> completeChallenge(String challengeId) async {
    if (!FirebaseService.isAuthenticated) return;

    final challengeRef = _firestore
        .collection('users')
        .doc(FirebaseService.currentUserId!)
        .collection('challenges')
        .doc(challengeId);

    final challengeDoc = await challengeRef.get();
    if (!challengeDoc.exists) return;

    final challengeData = challengeDoc.data()!;
    final xpReward = challengeData['xpReward'] ?? 50;
    final completedCount = (challengeData['completedCount'] ?? 0) + 1;

    // Обновляем челлендж
    await challengeRef.update({
      'isCompleted': true,
      'completedAt': FieldValue.serverTimestamp(),
      'completedCount': completedCount,
    });

    // Добавляем XP
    await FirebaseService.addXP(xpReward);

    // Для недельных челленджей увеличиваем прогресс
    if (challengeData['type'] == 'weekly') {
      final progress = (challengeData['progress'] ?? 0) + 1;
      final targetCount = challengeData['targetCount'] ?? 7;

      await challengeRef.update({
        'progress': progress,
        'isCompleted': progress >= targetCount,
      });
    }
  }

  // Оценить челлендж
  static Future<void> rateChallenge(String challengeId, int rating, String? note) async {
    if (!FirebaseService.isAuthenticated) return;

    await _firestore
        .collection('users')
        .doc(FirebaseService.currentUserId!)
        .collection('challenges')
        .doc(challengeId)
        .update({
      'rating': rating,
      'note': note,
    });
  }

  // Количество выполненных сегодня
  static Stream<int> getCompletedTodayStream() {
    if (!FirebaseService.isAuthenticated) return Stream.value(0);

    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);

    return _firestore
        .collection('users')
        .doc(FirebaseService.currentUserId!)
        .collection('challenges')
        .where('isCompleted', isEqualTo: true)
        .where('completedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}

// Модель челленджа
class Challenge {
  final String id;
  final String childId;
  final String title;
  final String description;
  final String category;
  final String type;
  final int xpReward;
  final List<String>? tips;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? completedAt;
  final int? progress;
  final int? targetCount;
  final int completedCount;
  final int? rating;
  final String? note;

  Challenge({
    required this.id,
    required this.childId,
    required this.title,
    required this.description,
    required this.category,
    required this.type,
    required this.xpReward,
    this.tips,
    required this.isCompleted,
    required this.createdAt,
    this.completedAt,
    this.progress,
    this.targetCount,
    required this.completedCount,
    this.rating,
    this.note,
  });

  factory Challenge.fromFirestore(Map<String, dynamic> data, String id) {
    return Challenge(
      id: id,
      childId: data['childId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'general',
      type: data['type'] ?? 'daily',
      xpReward: data['xpReward'] ?? 50,
      tips: data['tips'] != null ? List<String>.from(data['tips']) : null,
      isCompleted: data['isCompleted'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: data['completedAt'] != null ? (data['completedAt'] as Timestamp).toDate() : null,
      progress: data['progress'],
      targetCount: data['targetCount'],
      completedCount: data['completedCount'] ?? 0,
      rating: data['rating'],
      note: data['note'],
    );
  }
}