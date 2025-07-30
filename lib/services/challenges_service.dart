// lib/services/challenges_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'firebase_service.dart';

class ChallengesService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Предустановленные челленджи по категориям
  static final Map<String, List<Map<String, dynamic>>> _challengeTemplates = {
    'physical': [
      {
        'title': 'Утренняя зарядка',
        'description': 'Сделайте вместе с ребенком 5-минутную утреннюю зарядку',
        'tips': 'Включите веселую музыку и превратите упражнения в игру',
        'xpReward': 50,
      },
      {
        'title': 'Прогулка на свежем воздухе',
        'description': 'Погуляйте с ребенком не менее 30 минут',
        'tips': 'Можно покормить птиц или поиграть в подвижные игры',
        'xpReward': 60,
      },
      {
        'title': 'Танцевальная вечеринка',
        'description': 'Устройте домашнюю дискотеку и потанцуйте вместе',
        'tips': 'Пусть ребенок выберет любимые песни',
        'xpReward': 40,
      },
    ],
    'cognitive': [
      {
        'title': 'Загадки и головоломки',
        'description': 'Решите вместе 3-5 загадок или простых головоломок',
        'tips': 'Подберите загадки по возрасту ребенка',
        'xpReward': 50,
      },
      {
        'title': 'Счет предметов',
        'description': 'Посчитайте вместе игрушки, книги или другие предметы',
        'tips': 'Сделайте счет частью игры или уборки',
        'xpReward': 40,
      },
      {
        'title': 'Изучаем формы',
        'description': 'Найдите вокруг предметы разных геометрических форм',
        'tips': 'Превратите поиск в увлекательную игру',
        'xpReward': 45,
      },
    ],
    'social': [
      {
        'title': 'Вежливые слова',
        'description': 'Практикуйте использование вежливых слов весь день',
        'tips': 'Хвалите ребенка за каждое "спасибо" и "пожалуйста"',
        'xpReward': 40,
      },
      {
        'title': 'Помощь по дому',
        'description': 'Попросите ребенка помочь с простым домашним делом',
        'tips': 'Выберите задание по возрасту и обязательно похвалите',
        'xpReward': 50,
      },
      {
        'title': 'Звонок бабушке',
        'description': 'Позвоните родственникам и поговорите с ними',
        'tips': 'Помогите ребенку рассказать о своем дне',
        'xpReward': 45,
      },
    ],
    'creative': [
      {
        'title': 'Рисование',
        'description': 'Нарисуйте вместе картину на свободную тему',
        'tips': 'Не критикуйте, хвалите за старание и креативность',
        'xpReward': 50,
      },
      {
        'title': 'Лепка из пластилина',
        'description': 'Слепите вместе фигурку животного или человека',
        'tips': 'Можно использовать тесто для лепки или соленое тесто',
        'xpReward': 55,
      },
      {
        'title': 'Придумываем историю',
        'description': 'Сочините вместе короткую сказку или историю',
        'tips': 'Пусть ребенок выберет главного героя',
        'xpReward': 60,
      },
    ],
    'emotional': [
      {
        'title': 'Дневник эмоций',
        'description': 'Поговорите о чувствах и эмоциях дня',
        'tips': 'Используйте картинки эмоций для помощи',
        'xpReward': 45,
      },
      {
        'title': 'Обнимашки',
        'description': 'Обнимите ребенка не менее 5 раз за день',
        'tips': 'Объятия помогают чувствовать себя любимым и защищенным',
        'xpReward': 40,
      },
      {
        'title': 'Комплименты',
        'description': 'Скажите ребенку 3 искренних комплимента',
        'tips': 'Хвалите за старание, а не только за результат',
        'xpReward': 40,
      },
    ],
  };

  // Недельные челленджи
  static final List<Map<String, dynamic>> _weeklyTemplates = [
    {
      'title': 'Неделя без гаджетов',
      'description': 'Проводите вечера без телевизора и планшета',
      'category': 'social',
      'targetCount': 7,
      'xpReward': 200,
    },
    {
      'title': 'Книжный марафон',
      'description': 'Читайте вместе книги каждый день перед сном',
      'category': 'cognitive',
      'targetCount': 7,
      'xpReward': 250,
    },
    {
      'title': 'Здоровое питание',
      'description': 'Каждый день ешьте фрукты и овощи',
      'category': 'physical',
      'targetCount': 7,
      'xpReward': 180,
    },
    {
      'title': 'Творческая неделя',
      'description': 'Каждый день создавайте что-то новое',
      'category': 'creative',
      'targetCount': 7,
      'xpReward': 220,
    },
  ];

  // Генерация ежедневных челленджей
  static Future<void> generateDailyChallenges(String? childId) async {
    if (!FirebaseService.isAuthenticated) return;

    final activeChildId = childId ?? (await FirebaseService.getActiveChild())?.id;
    if (activeChildId == null) return;

    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    // Проверяем, есть ли уже челленджи на сегодня
    final existingChallenges = await _firestore
        .collection('users')
        .doc(FirebaseService.currentUserId!)
        .collection('challenges')
        .where('childId', isEqualTo: activeChildId)
        .where('type', isEqualTo: 'daily')
        .where('dateStr', isEqualTo: todayStr)
        .get();

    if (existingChallenges.docs.isNotEmpty) {
      debugPrint('Челленджи на сегодня уже созданы');
      return;
    }

    // Выбираем по одному челленджу из каждой категории
    final batch = _firestore.batch();
    final categories = ['physical', 'cognitive', 'social', 'creative', 'emotional'];

    for (final category in categories) {
      final templates = _challengeTemplates[category]!;
      final randomTemplate = templates[DateTime.now().millisecondsSinceEpoch % templates.length];

      final challengeRef = _firestore
          .collection('users')
          .doc(FirebaseService.currentUserId!)
          .collection('challenges')
          .doc();

      batch.set(challengeRef, {
        ...randomTemplate,
        'id': challengeRef.id,
        'childId': activeChildId,
        'category': category,
        'type': 'daily',
        'dateStr': todayStr,
        'isCompleted': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
    debugPrint('Сгенерировано 5 ежедневных челленджей');
  }

  // Генерация недельного челленджа
  static Future<void> generateWeeklyChallenge(String? childId) async {
    if (!FirebaseService.isAuthenticated) return;

    final activeChildId = childId ?? (await FirebaseService.getActiveChild())?.id;
    if (activeChildId == null) return;

    final weekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));

    // Выбираем случайный недельный челлендж
    final randomTemplate = _weeklyTemplates[DateTime.now().millisecondsSinceEpoch % _weeklyTemplates.length];

    await _firestore
        .collection('users')
        .doc(FirebaseService.currentUserId!)
        .collection('challenges')
        .add({
      ...randomTemplate,
      'childId': activeChildId,
      'type': 'weekly',
      'weekStart': Timestamp.fromDate(weekStart),
      'isCompleted': false,
      'progress': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
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

    // Обновляем челлендж
    await challengeRef.update({
      'isCompleted': true,
      'completedAt': FieldValue.serverTimestamp(),
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
  final String? tips;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? completedAt;
  final int? progress;
  final int? targetCount;
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
      tips: data['tips'],
      isCompleted: data['isCompleted'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      progress: data['progress'],
      targetCount: data['targetCount'],
      rating: data['rating'],
      note: data['note'],
    );
  }
}