// lib/services/platform_firebase_service.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PlatformFirebaseService {
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
    // На Web используем мок-сервис
    if (kIsWeb) {
      return null;
    }

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
    // На Web используем мок-сервис
    if (kIsWeb) {
      return null;
    }

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
    if (kIsWeb) return;
    await _auth.signOut();
  }

  // Сброс пароля
  static Future<void> resetPassword(String email) async {
    if (kIsWeb) return;
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Сохранение данных ребенка
  static Future<void> saveChildData({
    required String childId,
    required Map<String, dynamic> data,
  }) async {
    if (kIsWeb) return;
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
    if (kIsWeb) return null;
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
    if (kIsWeb) {
      return Stream.value([]);
    }
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
    if (kIsWeb) return;
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
    if (kIsWeb) return;
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
    if (kIsWeb) return;
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
    if (kIsWeb) {
      return Stream.value([]);
    }
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