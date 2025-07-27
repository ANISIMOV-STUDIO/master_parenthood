// lib/services/firebase_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Получить текущего пользователя
  static User? get currentUser => _auth.currentUser;

  // Проверка авторизации
  static bool get isAuthenticated => currentUser != null;

  // Регистрация с email и паролем
  static Future<User?> registerWithEmail({
    required String email,
    required String password,
    required String parentName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Создаем профиль пользователя
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'email': email,
          'parentName': parentName,
          'createdAt': FieldValue.serverTimestamp(),
          'level': 1,
          'xp': 0,
          'subscription': 'free',
        });

        // Обновляем displayName
        await credential.user!.updateDisplayName(parentName);
      }

      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Вход с email и паролем
  static Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Выход
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  // Сброс пароля
  static Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Сохранение данных ребенка
  static Future<void> saveChildData({
    required String childId,
    required Map<String, dynamic> data,
  }) async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .collection('children')
        .doc(childId)
        .set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Получение данных ребенка
  static Future<Map<String, dynamic>?> getChildData(String childId) async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    final doc = await _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .collection('children')
        .doc(childId)
        .get();

    return doc.data();
  }

  // Получение всех детей пользователя
  static Stream<List<Map<String, dynamic>>> getChildrenStream() {
    if (!isAuthenticated) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .collection('children')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => {
      'id': doc.id,
      ...doc.data(),
    })
        .toList());
  }

  // Сохранение прогресса достижения
  static Future<void> updateAchievement({
    required String achievementId,
    required bool unlocked,
    int? progress,
  }) async {
    if (!isAuthenticated) return;

    await _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .collection('achievements')
        .doc(achievementId)
        .set({
      'unlocked': unlocked,
      'progress': progress ?? 100,
      'unlockedAt': unlocked ? FieldValue.serverTimestamp() : null,
    }, SetOptions(merge: true));
  }

  // Обновление XP пользователя
  static Future<void> addXP(int amount) async {
    if (!isAuthenticated) return;

    await _firestore.collection('users').doc(currentUser!.uid).update({
      'xp': FieldValue.increment(amount),
    });
  }

  // Сохранение сгенерированной сказки
  static Future<void> saveStory({
    required String childId,
    required String story,
    required String theme,
  }) async {
    if (!isAuthenticated) return;

    await _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .collection('stories')
        .add({
      'childId': childId,
      'story': story,
      'theme': theme,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Получение истории сказок
  static Stream<List<Map<String, dynamic>>> getStoriesStream(String childId) {
    if (!isAuthenticated) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .collection('stories')
        .where('childId', isEqualTo: childId)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => {
      'id': doc.id,
      ...doc.data(),
    })
        .toList());
  }

  // Обработка ошибок аутентификации
  static String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Пользователь не найден';
      case 'wrong-password':
        return 'Неверный пароль';
      case 'email-already-in-use':
        return 'Email уже используется';
      case 'invalid-email':
        return 'Неверный формат email';
      case 'weak-password':
        return 'Слишком простой пароль';
      case 'network-request-failed':
        return 'Ошибка сети';
      default:
        return 'Произошла ошибка: ${e.message}';
    }
  }
}

// Модель пользователя
class UserProfile {
  final String uid;
  final String email;
  final String parentName;
  final int level;
  final int xp;
  final String subscription;
  final DateTime createdAt;

  UserProfile({
    required this.uid,
    required this.email,
    required this.parentName,
    required this.level,
    required this.xp,
    required this.subscription,
    required this.createdAt,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: doc.id,
      email: data['email'] ?? '',
      parentName: data['parentName'] ?? '',
      level: data['level'] ?? 1,
      xp: data['xp'] ?? 0,
      subscription: data['subscription'] ?? 'free',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

// Модель ребенка
class ChildProfile {
  final String id;
  final String name;
  final DateTime birthDate;
  final double height;
  final double weight;
  final String petName;
  final String petType;
  final Map<String, int> petStats;
  final Map<String, dynamic> milestones;

  ChildProfile({
    required this.id,
    required this.name,
    required this.birthDate,
    required this.height,
    required this.weight,
    required this.petName,
    required this.petType,
    required this.petStats,
    required this.milestones,
  });

  int get ageInMonths {
    final now = DateTime.now();
    final months = (now.year - birthDate.year) * 12 + now.month - birthDate.month;
    return months;
  }

  String get ageFormatted {
    final months = ageInMonths;
    final years = months ~/ 12;
    final remainingMonths = months % 12;

    if (years > 0) {
      return '$years г. $remainingMonths мес.';
    } else {
      return '$remainingMonths мес.';
    }
  }

  factory ChildProfile.fromFirestore(Map<String, dynamic> data, String id) {
    return ChildProfile(
      id: id,
      name: data['name'] ?? '',
      birthDate: (data['birthDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      height: (data['height'] ?? 0).toDouble(),
      weight: (data['weight'] ?? 0).toDouble(),
      petName: data['petName'] ?? 'Питомец',
      petType: data['petType'] ?? '🦄',
      petStats: Map<String, int>.from(data['petStats'] ?? {
        'happiness': 50,
        'energy': 50,
        'knowledge': 50,
      }),
      milestones: data['milestones'] ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'birthDate': Timestamp.fromDate(birthDate),
      'height': height,
      'weight': weight,
      'petName': petName,
      'petType': petType,
      'petStats': petStats,
      'milestones': milestones,
    };
  }
}