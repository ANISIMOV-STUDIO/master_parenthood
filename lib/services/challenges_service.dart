// lib/services/challenges_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
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
            'Используйте мягкие предметы',
            'Помогайте преодолевать препятствия',
            'Празднуйте каждый успех'
          ],
          'xpReward': 70,
        },
      ],
      'creative': [
        {
          'title': 'Рисование пальчиками',
          'description': 'Создайте картину используя пальчиковые краски',
          'tips': [
            'Используйте безопасные краски',
            'Защитите поверхность клеенкой',
            'Сохраните первый шедевр'
          ],
          'xpReward': 80,
        },
      ],
      'social': [
        {
          'title': 'Привет и пока',
          'description': 'Научите малыша махать ручкой при встрече и прощании',
          'tips': [
            'Показывайте пример',
            'Практикуйтесь с игрушками',
            'Хвалите за попытки'
          ],
          'xpReward': 50,
        },
      ],
    },
    '2-3': {
      'physical': [
        {
          'title': 'Прыжки как зайчик',
          'description': 'Научите ребенка прыгать на двух ногах',
          'tips': [
            'Начните с прыжков на месте',
            'Держите за руки для поддержки',
            'Считайте прыжки вместе'
          ],
          'xpReward': 60,
        },
        {
          'title': 'Мяч - мой друг',
          'description': 'Поиграйте в катание и ловлю мяча',
          'tips': [
            'Используйте мягкий мяч среднего размера',
            'Сядьте на пол напротив друг друга',
            'Постепенно увеличивайте расстояние'
          ],
          'xpReward': 50,
        },
      ],
      'creative': [
        {
          'title': 'Пластилиновый мир',
          'description': 'Слепите вместе простые фигурки из пластилина',
          'tips': [
            'Начните с шариков и колбасок',
            'Покажите как делать отпечатки',
            'Создайте простых животных'
          ],
          'xpReward': 70,
        },
        {
          'title': 'Музыкальный оркестр',
          'description': 'Создайте музыку с помощью подручных предметов',
          'tips': [
            'Используйте ложки, кастрюли, коробки',
            'Покажите разные ритмы',
            'Пойте песенки вместе'
          ],
          'xpReward': 60,
        },
      ],
      'cognitive': [
        {
          'title': 'Сортировка по цветам',
          'description': 'Отсортируйте игрушки или предметы по цветам',
          'tips': [
            'Начните с 2-3 основных цветов',
            'Используйте яркие предметы',
            'Называйте цвета во время игры'
          ],
          'xpReward': 80,
        },
        {
          'title': 'Найди пару',
          'description': 'Поиграйте в поиск одинаковых предметов',
          'tips': [
            'Используйте носки, варежки, игрушки',
            'Начните с 3-4 пар',
            'Усложняйте постепенно'
          ],
          'xpReward': 70,
        },
      ],
      'emotional': [
        {
          'title': 'Эмоции в зеркале',
          'description': 'Изучайте эмоции перед зеркалом',
          'tips': [
            'Показывайте радость, грусть, удивление',
            'Попросите повторить',
            'Обсудите когда мы чувствуем эти эмоции'
          ],
          'xpReward': 60,
        },
      ],
      'social': [
        {
          'title': 'Пожалуйста и спасибо',
          'description': 'Практикуйте вежливые слова в игровой форме',
          'tips': [
            'Используйте игрушки для ролевых игр',
            'Показывайте пример',
            'Хвалите за использование вежливых слов'
          ],
          'xpReward': 50,
        },
      ],
    },
    '3-5': {
      'physical': [
        {
          'title': 'Йога для детей',
          'description': 'Выполните 5 простых поз йоги вместе',
          'tips': [
            'Поза кошки, собаки, дерева',
            'Держите позы 10-15 секунд',
            'Придумайте истории для каждой позы'
          ],
          'xpReward': 80,
        },
      ],
      'creative': [
        {
          'title': 'Театр теней',
          'description': 'Создайте представление с тенями на стене',
          'tips': [
            'Используйте фонарик или лампу',
            'Покажите как делать животных руками',
            'Придумайте простую историю'
          ],
          'xpReward': 90,
        },
      ],
      'cognitive': [
        {
          'title': 'Счет до 10',
          'description': 'Посчитайте разные предметы в доме',
          'tips': [
            'Считайте ступеньки, игрушки, пальчики',
            'Используйте счет в повседневной жизни',
            'Играйте в магазин'
          ],
          'xpReward': 70,
        },
      ],
    },
  };

  // Недельные челленджи
  static final List<Map<String, dynamic>> _weeklyChallengeTemplates = [
    {
      'title': 'Неделя без мультиков перед сном',
      'description': 'Замените вечерние мультики на чтение книг',
      'category': 'emotional',
      'xpReward': 500,
      'targetCount': 7,
    },
    {
      'title': 'Ежедневная зарядка',
      'description': 'Делайте утреннюю зарядку каждый день',
      'category': 'physical',
      'xpReward': 400,
      'targetCount': 7,
    },
    {
      'title': 'Творческая неделя',
      'description': 'Каждый день создавайте что-то новое',
      'category': 'creative',
      'xpReward': 450,
      'targetCount': 7,
    },
  ];

  // Получить челленджи для возраста ребенка
  static String _getAgeGroup(int ageInMonths) {
    if (ageInMonths < 12) return '0-1';
    if (ageInMonths < 24) return '1-2';
    if (ageInMonths < 36) return '2-3';
    if (ageInMonths < 60) return '3-5';
    return '3-5'; // Для старших используем те же челленджи
  }

  // Генерация ежедневных челленджей
  static Future<void> generateDailyChallenges(String? childId) async {
    if (!FirebaseService.isAuthenticated) return;

    try {
      // Получаем данные ребенка
      ChildProfile? child;
      if (childId != null) {
        child = await FirebaseService.getChild(childId);
      } else {
        child = await FirebaseService.getActiveChild();
      }

      if (child == null) return;

      final ageGroup = _getAgeGroup(child.ageInMonths);
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
            'createdAt': FieldValue.serverTimestamp(),
            'dateStr': todayStr,
          });
        }
      }

      await batch.commit();
    } catch (e) {
      print('Error generating challenges: $e');
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
        'isCompleted': false,
        'createdAt': FieldValue.serverTimestamp(),
        'weekStart': Timestamp.fromDate(weekStart),
      });
    } catch (e) {
      print('Error generating weekly challenge: $e');
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
  final List<String>? tips;
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
      tips: data['tips'] != null ? List<String>.from(data['tips']) : null,
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