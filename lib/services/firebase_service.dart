// lib/services/firebase_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'dart:io';
import 'package:flutter/foundation.dart'; // Added for debugPrint

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Getters
  static User? get currentUser => _auth.currentUser;
  static bool get isAuthenticated => currentUser != null;
  static String? get currentUserEmail => currentUser?.email;
  static String? get currentUserName => currentUser?.displayName;
  static String? get currentUserId => currentUser?.uid;

  // Stream для отслеживания состояния авторизации
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ===== АВТОРИЗАЦИЯ =====

  // Email/Password авторизация
  static Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _ensureUserProfile(credential.user);
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Email/Password регистрация
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
        await credential.user!.updateDisplayName(parentName);

        await _createUserProfile(
          user: credential.user!,
          additionalData: {'parentName': parentName},
        );
      }

      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Google авторизация
  static Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      await _ensureUserProfile(userCredential.user);

      return userCredential.user;
    } catch (e) {
      throw Exception('Ошибка входа через Google: $e');
    }
  }

  // Facebook авторизация
  static Future<User?> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status == LoginStatus.success) {
        final OAuthCredential credential =
        FacebookAuthProvider.credential(result.accessToken!.token);

        final userCredential = await _auth.signInWithCredential(credential);
        await _ensureUserProfile(userCredential.user);

        return userCredential.user;
      } else if (result.status == LoginStatus.cancelled) {
        return null;
      } else {
        throw Exception('Ошибка входа через Facebook: ${result.message}');
      }
    } catch (e) {
      throw Exception('Ошибка входа через Facebook: $e');
    }
  }

  // VK авторизация (через Custom Auth)
  static Future<User?> signInWithVK({
    required String vkUserId,
    required String vkAccessToken,
    required String vkEmail,
  }) async {
    try {
      // Для VK нужно использовать custom token через Firebase Functions
      // Это требует настройки серверной части
      final customToken = await _getVKCustomToken(
        userId: vkUserId,
        accessToken: vkAccessToken,
        email: vkEmail,
      );

      final userCredential = await _auth.signInWithCustomToken(customToken);
      await _ensureUserProfile(userCredential.user);

      return userCredential.user;
    } catch (e) {
      throw Exception('Ошибка входа через VK: $e');
    }
  }

  // Яндекс авторизация (через Custom Auth)
  static Future<User?> signInWithYandex({
    required String accessToken,
    required String userId,
  }) async {
    try {
      // Для Яндекс также нужен custom token через Firebase Functions
      final customToken = await _getYandexCustomToken(
        userId: userId,
        accessToken: accessToken,
      );

      final userCredential = await _auth.signInWithCustomToken(customToken);
      await _ensureUserProfile(userCredential.user);

      return userCredential.user;
    } catch (e) {
      throw Exception('Ошибка входа через Яндекс: $e');
    }
  }

  // Выход
  static Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    await FacebookAuth.instance.logOut();
  }

  // Сброс пароля
  static Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ===== УПРАВЛЕНИЕ ПРОФИЛЕМ =====

  // Создание профиля пользователя
  static Future<void> _createUserProfile({
    required User user,
    Map<String, dynamic>? additionalData,
  }) async {
    final userDoc = _firestore.collection('users').doc(user.uid);
    final docSnapshot = await userDoc.get();

    if (!docSnapshot.exists) {
      final userData = {
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName ?? additionalData?['parentName'] ?? 'Родитель',
        'photoURL': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'level': 1,
        'xp': 0,
        'subscription': 'free',
        'provider': user.providerData.first.providerId,
        ...?additionalData,
        'activeChildId': null, // Added activeChildId field
      };

      await userDoc.set(userData);
    }
  }

  // Проверка и создание профиля при необходимости
  static Future<void> _ensureUserProfile(User? user) async {
    if (user != null) {
      await _createUserProfile(user: user);
      await _updateLastLogin(user.uid);
    }
  }

  // Обновление времени последнего входа
  static Future<void> _updateLastLogin(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'lastLogin': FieldValue.serverTimestamp(),
    });
  }

  // Получение профиля пользователя
  static Future<UserProfile?> getUserProfile() async {
    if (!isAuthenticated) return null;

    final doc = await _firestore.collection('users').doc(currentUserId!).get();
    if (doc.exists) {
      return UserProfile.fromFirestore(doc);
    }
    return null;
  }

  // Stream профиля пользователя
  static Stream<UserProfile?> getUserProfileStream() {
    if (!isAuthenticated) return Stream.value(null);

    return _firestore
        .collection('users')
        .doc(currentUserId!)
        .snapshots()
        .map((doc) => doc.exists ? UserProfile.fromFirestore(doc) : null);
  }

  // ===== УПРАВЛЕНИЕ ДЕТЬМИ =====

  // Добавление ребенка
  static Future<String> addChild({
    required String name,
    required DateTime birthDate,
    required String gender,
    double? height,
    double? weight,
  }) async {
    if (!isAuthenticated) throw Exception('Пользователь не авторизован');

    final childRef = _firestore
        .collection('users')
        .doc(currentUserId!)
        .collection('children')
        .doc();

    final childData = {
      'id': childRef.id,
      'name': name,
      'birthDate': Timestamp.fromDate(birthDate),
      'gender': gender,
      'height': height ?? 0,
      'weight': weight ?? 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'petName': 'Питомец',
      'petType': '🦄',
      'petStats': {
        'happiness': 50,
        'energy': 50,
        'knowledge': 50,
      },
      'milestones': {},
    };

    await childRef.set(childData);

    // Обновляем активного ребенка
    await _firestore.collection('users').doc(currentUserId!).update({
      'activeChildId': childRef.id,
    });

    return childRef.id;
  }

  // Обновление данных ребенка
  static Future<void> updateChild({
    required String childId,
    required Map<String, dynamic> data,
  }) async {
    if (!isAuthenticated) throw Exception('Пользователь не авторизован');

    await _firestore
        .collection('users')
        .doc(currentUserId!)
        .collection('children')
        .doc(childId)
        .update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Получение данных ребенка
  static Future<ChildProfile?> getChild(String childId) async {
    if (!isAuthenticated) return null;

    final doc = await _firestore
        .collection('users')
        .doc(currentUserId!)
        .collection('children')
        .doc(childId)
        .get();

    if (doc.exists) {
      return ChildProfile.fromFirestore(doc.data()!, doc.id);
    }
    return null;
  }

  // Stream всех детей
  static Stream<List<ChildProfile>> getChildrenStream() {
    if (!isAuthenticated) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(currentUserId!)
        .collection('children')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ChildProfile.fromFirestore(doc.data(), doc.id))
        .toList());
  }

  // ===== ДОСТИЖЕНИЯ И XP =====

  // Добавление XP
  static Future<void> addXP(int amount) async {
    if (!isAuthenticated) return;

    final userRef = _firestore.collection('users').doc(currentUserId!);

    await _firestore.runTransaction((transaction) async {
      final userDoc = await transaction.get(userRef);
      if (!userDoc.exists) return;

      final currentXP = userDoc.data()?['xp'] ?? 0;
      final currentLevel = userDoc.data()?['level'] ?? 1;

      final newXP = currentXP + amount;
      final newLevel = _calculateLevel(newXP);

      transaction.update(userRef, {
        'xp': newXP,
        'level': newLevel,
      });

      // Если новый уровень, создаем уведомление
      if (newLevel > currentLevel) {
        await _createLevelUpNotification(newLevel);
      }
    });
  }

  // Расчет уровня по XP
  static int _calculateLevel(int xp) {
    // Простая формула: каждый уровень требует 1000 XP
    return (xp / 1000).floor() + 1;
  }

  // Обновление достижения
  static Future<void> updateAchievement({
    required String achievementId,
    required bool unlocked,
    int? progress,
  }) async {
    if (!isAuthenticated) return;

    await _firestore
        .collection('users')
        .doc(currentUserId!)
        .collection('achievements')
        .doc(achievementId)
        .set({
      'unlocked': unlocked,
      'progress': progress ?? 100,
      'unlockedAt': unlocked ? FieldValue.serverTimestamp() : null,
    }, SetOptions(merge: true));

    // Добавляем XP за разблокировку достижения
    if (unlocked) {
      await addXP(100);
    }
  }

  // ===== СКАЗКИ =====

  // Сохранение сказки
  static Future<void> saveStory({
    required String childId,
    required String story,
    required String theme,
    String? imageUrl,
  }) async {
    if (!isAuthenticated) return;

    await _firestore
        .collection('users')
        .doc(currentUserId!)
        .collection('stories')
        .add({
      'childId': childId,
      'story': story,
      'theme': theme,
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'isFavorite': false,
    });

    // Добавляем XP за создание сказки
    await addXP(50);
  }

  // Stream историй
  static Stream<List<StoryData>> getStoriesStream(String childId) {
    if (!isAuthenticated) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(currentUserId!)
        .collection('stories')
        .where('childId', isEqualTo: childId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => StoryData.fromFirestore(doc))
        .toList());
  }

  // ===== ФАЙЛОВОЕ ХРАНИЛИЩЕ =====

  // Загрузка изображения
  static Future<String?> uploadImage({
    required File file,
    required String path,
  }) async {
    if (!isAuthenticated) return null;

    try {
      final ref = _storage.ref().child('users/$currentUserId/$path');
      final uploadTask = await ref.putFile(file);
      final url = await uploadTask.ref.getDownloadURL();
      return url;
    } catch (e) {
      debugPrint('Ошибка загрузки изображения: $e'); // Changed print to debugPrint
      return null;
    }
  }

  // Загрузка аватара пользователя
  static Future<String?> uploadUserAvatar(File file) async {
    final url = await uploadImage(
      file: file,
      path: 'avatar/${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    if (url != null) {
      await currentUser?.updatePhotoURL(url);
      await _firestore.collection('users').doc(currentUserId!).update({
        'photoURL': url,
      });
    }

    return url;
  }

  // Загрузка фото ребенка
  static Future<String?> uploadChildPhoto({
    required File file,
    required String childId,
  }) async {
    final url = await uploadImage(
      file: file,
      path: 'children/$childId/${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    if (url != null) {
      await updateChild(
        childId: childId,
        data: {'photoURL': url},
      );
    }

    return url;
  }

  // ===== УВЕДОМЛЕНИЯ =====

  static Future<void> _createLevelUpNotification(int newLevel) async {
    await _firestore
        .collection('users')
        .doc(currentUserId!)
        .collection('notifications')
        .add({
      'type': 'level_up',
      'title': 'Новый уровень!',
      'message': 'Поздравляем! Вы достигли $newLevel уровня!',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ===== ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ =====

  // Получение custom token для VK (требует настройки Firebase Functions)
  static Future<String> _getVKCustomToken({
    required String userId,
    required String accessToken,
    required String email,
  }) async {
    // TODO: Вызов вашей Firebase Function для генерации custom token
    // Пример:
    // final response = await http.post(
    //   Uri.parse('https://your-project.cloudfunctions.net/createVKCustomToken'),
    //   headers: {'Content-Type': 'application/json'},
    //   body: jsonEncode({
    //     'userId': userId,
    //     'accessToken': accessToken,
    //     'email': email,
    //   }),
    // );
    // final data = jsonDecode(response.body);
    // return data['customToken'];

    throw UnimplementedError('Требуется настройка Firebase Functions для VK авторизации');
  }

  // Получение custom token для Яндекс
  static Future<String> _getYandexCustomToken({
    required String userId,
    required String accessToken,
  }) async {
    // TODO: Вызов вашей Firebase Function
    // Пример:
    // final response = await http.post(
    //   Uri.parse('https://your-project.cloudfunctions.net/createYandexCustomToken'),
    //   headers: {'Content-Type': 'application/json'},
    //   body: jsonEncode({
    //     'userId': userId,
    //     'accessToken': accessToken,
    //   }),
    // );
    // final data = jsonDecode(response.body);
    // return data['customToken'];

    throw UnimplementedError('Требуется настройка Firebase Functions для Яндекс авторизации');
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
      case 'user-disabled':
        return 'Пользователь заблокирован';
      case 'too-many-requests':
        return 'Слишком много попыток. Попробуйте позже';
      default:
        return 'Произошла ошибка: ${e.message}';
    }
  }
}

// ===== МОДЕЛИ ДАННЫХ =====

// Профиль пользователя
class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final String? photoURL;
  final int level;
  final int xp;
  final String subscription;
  final DateTime createdAt;
  final DateTime lastLogin;
  final String provider;
  final String? activeChildId; // Added activeChildId field

  UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL,
    required this.level,
    required this.xp,
    required this.subscription,
    required this.createdAt,
    required this.lastLogin,
    required this.provider,
    this.activeChildId, // Added activeChildId to constructor
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? 'Родитель',
      photoURL: data['photoURL'],
      level: data['level'] ?? 1,
      xp: data['xp'] ?? 0,
      subscription: data['subscription'] ?? 'free',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLogin: (data['lastLogin'] as Timestamp?)?.toDate() ?? DateTime.now(),
      provider: data['provider'] ?? 'email',
      activeChildId: data['activeChildId'], // Read activeChildId from data
    );
  }

  int get xpForNextLevel => level * 1000;
  int get xpProgress => xp % 1000;
  double get levelProgress => xpProgress / 1000;
}

// Профиль ребенка
class ChildProfile {
  final String id;
  final String name;
  final DateTime birthDate;
  final String gender;
  final double height;
  final double weight;
  final String? photoURL;
  final String petName;
  final String petType;
  final Map<String, int> petStats;
  final Map<String, dynamic> milestones;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChildProfile({
    required this.id,
    required this.name,
    required this.birthDate,
    required this.gender,
    required this.height,
    required this.weight,
    this.photoURL,
    required this.petName,
    required this.petType,
    required this.petStats,
    required this.milestones,
    required this.createdAt,
    required this.updatedAt,
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
      gender: data['gender'] ?? 'male',
      height: (data['height'] ?? 0).toDouble(),
      weight: (data['weight'] ?? 0).toDouble(),
      photoURL: data['photoURL'],
      petName: data['petName'] ?? 'Питомец',
      petType: data['petType'] ?? '🦄',
      petStats: Map<String, int>.from(data['petStats'] ?? {
        'happiness': 50,
        'energy': 50,
        'knowledge': 50,
      }),
      milestones: data['milestones'] ?? {},
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'birthDate': Timestamp.fromDate(birthDate),
      'gender': gender,
      'height': height,
      'weight': weight,
      'photoURL': photoURL,
      'petName': petName,
      'petType': petType,
      'petStats': petStats,
      'milestones': milestones,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

// Данные сказки
class StoryData {
  final String id;
  final String childId;
  final String story;
  final String theme;
  final String? imageUrl;
  final bool isFavorite;
  final DateTime createdAt;

  StoryData({
    required this.id,
    required this.childId,
    required this.story,
    required this.theme,
    this.imageUrl,
    required this.isFavorite,
    required this.createdAt,
  });

  factory StoryData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StoryData(
      id: doc.id,
      childId: data['childId'] ?? '',
      story: data['story'] ?? '',
      theme: data['theme'] ?? '',
      imageUrl: data['imageUrl'],
      isFavorite: data['isFavorite'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}