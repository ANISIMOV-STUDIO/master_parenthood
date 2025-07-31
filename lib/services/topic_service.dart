// lib/services/topic_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'firebase_service.dart';
import 'dart:math';

class TopicService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Предопределенные темы по категориям
  static final List<Map<String, dynamic>> _topicTemplates = [
    // Эмоциональное развитие
    {
      'title': 'Как научить ребенка управлять эмоциями',
      'category': 'emotional',
      'whyImportant': 'Умение распознавать и управлять своими эмоциями - основа эмоционального интеллекта. Дети, которые понимают свои чувства, легче справляются со стрессом и строят здоровые отношения.',
      'discussionPoints': [
        'Назовите эмоции вместе с ребенком: радость, грусть, злость, страх',
        'Покажите, что все эмоции нормальны и важны',
        'Научите простым способам успокоиться: глубокое дыхание, счет до 10',
        'Используйте книги и мультфильмы для обсуждения чувств героев',
      ],
      'activities': {
        '0-1': ['Играйте в "ку-ку" для развития эмоциональной связи', 'Копируйте мимику малыша'],
        '1-2': ['Рисуйте смайлики с разными эмоциями', 'Играйте в "покажи эмоцию"'],
        '2-3': ['Создайте "коробку спокойствия" с любимыми игрушками', 'Читайте книги про эмоции'],
        '3-5': ['Ведите дневник эмоций с наклейками', 'Играйте в театр с разными персонажами'],
      },
    },
    {
      'title': 'Важность объятий и физического контакта',
      'category': 'emotional',
      'whyImportant': 'Объятия снижают уровень стресса, укрепляют иммунитет и создают чувство безопасности. Физический контакт способствует выработке окситоцина - гормона привязанности и счастья.',
      'discussionPoints': [
        'Обнимайте ребенка минимум 8 раз в день',
        'Спрашивайте разрешение на объятия у старших детей',
        'Создайте ритуалы с объятиями: утренние, перед сном',
        'Учите ребенка уважать личные границы других',
      ],
      'activities': {
        '0-1': ['Массаж для малыша перед сном', 'Контакт "кожа к коже" во время кормления'],
        '1-2': ['Игра "обнимашки с игрушками"', 'Танцы с малышом на руках'],
        '2-3': ['Семейные обнимашки утром', 'Игра "сэндвич из объятий"'],
        '3-5': ['Придумайте секретное рукопожатие', 'Йога в паре с элементами объятий'],
      },
    },
    // Социальные навыки
    {
      'title': 'Учимся делиться и играть вместе',
      'category': 'social',
      'whyImportant': 'Умение делиться и сотрудничать - основа социальных навыков. Эти навыки помогут ребенку заводить друзей, работать в команде и решать конфликты мирным путем.',
      'discussionPoints': [
        'Объясните, что делиться - это не отдавать навсегда',
        'Покажите пример, делясь своими вещами',
        'Хвалите за каждую попытку поделиться',
        'Учите просить разрешения брать чужие вещи',
      ],
      'activities': {
        '0-1': ['Катайте мячик друг другу', 'Играйте в "дай-возьми" с игрушками'],
        '1-2': ['Стройте башню по очереди', 'Кормите кукол вместе'],
        '2-3': ['Играйте в магазин с обменом', 'Рисуйте одну картину вдвоем'],
        '3-5': ['Настольные игры с очередностью ходов', 'Готовьте вместе, распределяя задачи'],
      },
    },
    {
      'title': 'Вежливые слова и хорошие манеры',
      'category': 'social',
      'whyImportant': 'Вежливость открывает двери и сердца. Дети с хорошими манерами легче адаптируются в обществе, вызывают симпатию окружающих и учатся уважать других.',
      'discussionPoints': [
        'Всегда используйте вежливые слова сами',
        'Объясните, почему важно говорить "спасибо" и "пожалуйста"',
        'Играйте в ролевые игры с вежливым общением',
        'Не заставляйте, а мягко напоминайте',
      ],
      'activities': {
        '0-1': ['Машите "привет" и "пока"', 'Говорите "спасибо" за малыша'],
        '1-2': ['Игра в гостей с куклами', 'Учите говорить "пожалуйста" жестами'],
        '2-3': ['Театр вежливости с игрушками', 'Практикуйтесь в магазине'],
        '3-5': ['Пишите благодарственные открытки', 'Учите правила поведения за столом'],
      },
    },
    // Познавательное развитие
    {
      'title': 'Развиваем любознательность',
      'category': 'cognitive',
      'whyImportant': 'Любознательность - двигатель обучения. Дети, которые задают вопросы и исследуют мир, лучше учатся, развивают критическое мышление и творческие способности.',
      'discussionPoints': [
        'Отвечайте на все вопросы "почему?"',
        'Если не знаете ответ, ищите вместе',
        'Задавайте встречные вопросы для размышления',
        'Создавайте возможности для исследований',
      ],
      'activities': {
        '0-1': ['Исследуйте разные текстуры', 'Прячьте и находите игрушки'],
        '1-2': ['Сортируйте предметы по свойствам', 'Играйте с водой и песком'],
        '2-3': ['Проводите простые эксперименты', 'Собирайте коллекции природных материалов'],
        '3-5': ['Ведите дневник наблюдений', 'Создайте домашнюю лабораторию'],
      },
    },
    {
      'title': 'Учимся считать в повседневной жизни',
      'category': 'cognitive',
      'whyImportant': 'Математика окружает нас повсюду. Раннее знакомство со счетом через игру и повседневные дела создает прочную основу для дальнейшего обучения.',
      'discussionPoints': [
        'Считайте все вокруг: ступеньки, игрушки, ложки',
        'Используйте пальчики для счета',
        'Играйте с числами во время еды и прогулок',
        'Показывайте цифры в окружающем мире',
      ],
      'activities': {
        '0-1': ['Считайте пальчики и ножки', 'Пойте песенки со счетом'],
        '1-2': ['Считайте игрушки в коробке', 'Играйте "один-много"'],
        '2-3': ['Накрывайте на стол, считая приборы', 'Играйте в магазин с монетками'],
        '3-5': ['Готовьте по рецепту с измерениями', 'Играйте в настольные игры с кубиками'],
      },
    },
    // Физическое развитие
    {
      'title': 'Важность активных игр на свежем воздухе',
      'category': 'physical',
      'whyImportant': 'Движение на свежем воздухе укрепляет иммунитет, развивает координацию, улучшает сон и настроение. Солнечный свет необходим для выработки витамина D.',
      'discussionPoints': [
        'Гуляйте минимум 2 часа в день',
        'Одевайтесь по погоде, а не по календарю',
        'Позволяйте бегать, прыгать и лазать',
        'Исследуйте природу вместе',
      ],
      'activities': {
        '0-1': ['Выкладывайте на травку для изучения', 'Катайте коляску по разным поверхностям'],
        '1-2': ['Собирайте листья и камешки', 'Играйте в догонялки'],
        '2-3': ['Прыгайте по лужам в резиновых сапогах', 'Катайтесь с горки'],
        '3-5': ['Устройте поиск сокровищ', 'Играйте в классики и резиночку'],
      },
    },
    {
      'title': 'Развиваем мелкую моторику',
      'category': 'physical',
      'whyImportant': 'Мелкая моторика напрямую связана с развитием речи и мышления. Ловкие пальчики - это будущие успехи в письме, рисовании и самообслуживании.',
      'discussionPoints': [
        'Давайте возможность все трогать и исследовать',
        'Не спешите помогать - пусть пробует сам',
        'Используйте разные материалы и текстуры',
        'Хвалите за каждое достижение',
      ],
      'activities': {
        '0-1': ['Давайте погремушки разных форм', 'Играйте в ладушки'],
        '1-2': ['Рвите бумагу и лепите из теста', 'Нанизывайте крупные бусины'],
        '2-3': ['Лепите из пластилина', 'Застегивайте пуговицы и молнии'],
        '3-5': ['Вырезайте ножницами', 'Вышивайте по картону'],
      },
    },
    // Творческое развитие
    {
      'title': 'Рисуем вместе: от каракулей к шедеврам',
      'category': 'creative',
      'whyImportant': 'Рисование развивает воображение, мелкую моторику и эмоциональное выражение. Через рисунок дети учатся передавать свои мысли и чувства.',
      'discussionPoints': [
        'Не критикуйте рисунки - хвалите процесс',
        'Спрашивайте, что нарисовано, а не угадывайте',
        'Рисуйте вместе, но не исправляйте',
        'Сохраняйте все рисунки в папку',
      ],
      'activities': {
        '0-1': ['Рисуйте пальчиковыми красками', 'Оставляйте отпечатки ладошек'],
        '1-2': ['Рисуйте мелками на асфальте', 'Используйте штампы и губки'],
        '2-3': ['Рисуйте истории в картинках', 'Раскрашивайте большие раскраски'],
        '3-5': ['Создавайте комиксы', 'Рисуйте с натуры'],
      },
    },
    {
      'title': 'Музыка и танцы для развития',
      'category': 'creative',
      'whyImportant': 'Музыка развивает слух, чувство ритма, память и координацию. Танцы помогают выражать эмоции, развивают пластику и уверенность в себе.',
      'discussionPoints': [
        'Включайте разную музыку: классику, детские песни, народную',
        'Танцуйте вместе без стеснения',
        'Создавайте музыку из подручных средств',
        'Пойте песни и колыбельные',
      ],
      'activities': {
        '0-1': ['Пойте колыбельные', 'Танцуйте с малышом на руках'],
        '1-2': ['Играйте на кастрюлях и ложках', 'Танцуйте под разные ритмы'],
        '2-3': ['Устройте домашний концерт', 'Играйте в музыкальные игры'],
        '3-5': ['Сочиняйте песни', 'Ставьте музыкальные спектакли'],
      },
    },
  ];

  // Получить тему дня
  static Future<DailyTopic?> getTodayTopic() async {
    try {
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final doc = await _firestore
          .collection('daily_topics')
          .doc(todayStr)
          .get();

      if (doc.exists) {
        return DailyTopic.fromFirestore(doc.data()!, doc.id);
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting today topic: $e');
      }
      return null;
    }
  }

  // Генерация темы дня
  static Future<void> generateTodayTopic() async {
    try {
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // Проверяем, есть ли уже тема на сегодня
      final existingDoc = await _firestore
          .collection('daily_topics')
          .doc(todayStr)
          .get();

      if (existingDoc.exists) return;

      // Выбираем случайную тему
      final random = Random();
      final template = _topicTemplates[random.nextInt(_topicTemplates.length)];

      // Создаем тему дня
      await _firestore
          .collection('daily_topics')
          .doc(todayStr)
          .set({
        'title': template['title'],
        'category': template['category'],
        'whyImportant': template['whyImportant'],
        'discussionPoints': template['discussionPoints'],
        'activities': template['activities'],
        'date': Timestamp.fromDate(today),
        'createdAt': FieldValue.serverTimestamp(),
        'participantsCount': 0,
        'commentsCount': 0,
        'likesCount': 0,
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error generating today topic: $e');
      }
    }
  }

  // Добавить комментарий
  static Future<void> addComment({
    required String topicId,
    required String text,
  }) async {
    if (!FirebaseService.isAuthenticated) return;

    final user = FirebaseService.currentUser!;

    await _firestore
        .collection('daily_topics')
        .doc(topicId)
        .collection('comments')
        .add({
      'userId': user.uid,
      'userName': user.displayName ?? 'Родитель',
      'userPhotoUrl': user.photoURL,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Увеличиваем счетчик комментариев
    await _firestore
        .collection('daily_topics')
        .doc(topicId)
        .update({
      'commentsCount': FieldValue.increment(1),
      'participantsCount': FieldValue.increment(1),
    });
  }

  // Удалить комментарий
  static Future<void> deleteComment(String commentId) async {
    if (!FirebaseService.isAuthenticated) return;

    // Находим комментарий для получения topicId
    final querySnapshot = await _firestore
        .collectionGroup('comments')
        .where(FieldPath.documentId, isEqualTo: commentId)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) return;

    final commentDoc = querySnapshot.docs.first;
    final topicId = commentDoc.reference.parent.parent!.id;

    // Проверяем, что это комментарий текущего пользователя
    if (commentDoc.data()['userId'] != FirebaseService.currentUserId) return;

    // Удаляем комментарий
    await commentDoc.reference.delete();

    // Уменьшаем счетчик
    await _firestore
        .collection('daily_topics')
        .doc(topicId)
        .update({
      'commentsCount': FieldValue.increment(-1),
    });
  }

  // Поток комментариев
  static Stream<List<TopicComment>> getCommentsStream(String topicId) {
    return _firestore
        .collection('daily_topics')
        .doc(topicId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => TopicComment.fromFirestore(doc.data(), doc.id))
        .toList());
  }

  // Сохранить сгенерированную активность
  static Future<void> saveGeneratedActivity({
    required String topicId,
    required String activity,
  }) async {
    if (!FirebaseService.isAuthenticated) return;

    await _firestore
        .collection('daily_topics')
        .doc(topicId)
        .collection('generated_activities')
        .add({
      'userId': FirebaseService.currentUserId,
      'activity': activity,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Поставить лайк теме
  static Future<void> toggleLike(String topicId) async {
    if (!FirebaseService.isAuthenticated) return;

    final userId = FirebaseService.currentUserId!;
    final likeRef = _firestore
        .collection('daily_topics')
        .doc(topicId)
        .collection('likes')
        .doc(userId);

    final likeDoc = await likeRef.get();

    if (likeDoc.exists) {
      // Удаляем лайк
      await likeRef.delete();
      await _firestore
          .collection('daily_topics')
          .doc(topicId)
          .update({
        'likesCount': FieldValue.increment(-1),
      });
    } else {
      // Добавляем лайк
      await likeRef.set({
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await _firestore
          .collection('daily_topics')
          .doc(topicId)
          .update({
        'likesCount': FieldValue.increment(1),
      });
    }
  }
}

// Модель темы дня
class DailyTopic {
  final String id;
  final String title;
  final String category;
  final String whyImportant;
  final List<String> discussionPoints;
  final Map<String, List<String>> activities;
  final DateTime date;
  final int participantsCount;
  final int commentsCount;
  final int likesCount;

  DailyTopic({
    required this.id,
    required this.title,
    required this.category,
    required this.whyImportant,
    required this.discussionPoints,
    required this.activities,
    required this.date,
    required this.participantsCount,
    required this.commentsCount,
    required this.likesCount,
  });

  factory DailyTopic.fromFirestore(Map<String, dynamic> data, String id) {
    return DailyTopic(
      id: id,
      title: data['title'] ?? '',
      category: data['category'] ?? 'general',
      whyImportant: data['whyImportant'] ?? '',
      discussionPoints: List<String>.from(data['discussionPoints'] ?? []),
      activities: Map<String, List<String>>.from(
        (data['activities'] ?? {}).map((key, value) => MapEntry(
          key,
          List<String>.from(value),
        )),
      ),
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      participantsCount: data['participantsCount'] ?? 0,
      commentsCount: data['commentsCount'] ?? 0,
      likesCount: data['likesCount'] ?? 0,
    );
  }
}

// Модель комментария
class TopicComment {
  final String id;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String text;
  final DateTime createdAt;

  TopicComment({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.text,
    required this.createdAt,
  });

  factory TopicComment.fromFirestore(Map<String, dynamic> data, String id) {
    return TopicComment(
      id: id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Аноним',
      userPhotoUrl: data['userPhotoUrl'],
      text: data['text'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}