// lib/services/firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'dart:io';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  // ===== АВТОРИЗАЦИЯ =====

  static User? get currentUser => _auth.currentUser;
  static String? get currentUserId => _auth.currentUser?.uid;
  static bool get isAuthenticated => _auth.currentUser != null;

  // Stream состояния авторизации
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Регистрация через email (алиас для совместимости)
  static Future<User?> registerWithEmail({
    required String email,
    required String password,
    required String parentName,
  }) async {
    return signUpWithEmail(
      email: email,
      password: password,
      displayName: parentName,
    );
  }

  // Регистрация через email
  static Future<User?> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await credential.user!.updateDisplayName(displayName);
        await _createUserProfile(credential.user!);
      }

      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Вход через email
  static Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await _updateLastLogin(credential.user!.uid);
      }

      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Вход через Google
  static Future<User?> signInWithGoogle() async {
    try {
      // Запускаем процесс входа через Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return null; // Пользователь отменил вход
      }

      // Получаем детали авторизации
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Создаем учетные данные
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Входим в Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        // Проверяем, существует ли профиль
        final doc = await _firestore.collection('users').doc(userCredential.user!.uid).get();

        if (!doc.exists) {
          await _createUserProfile(userCredential.user!);
        } else {
          await _updateLastLogin(userCredential.user!.uid);
        }
      }

      return userCredential.user;
    } catch (e) {
      if (kDebugMode) {
        print('Error signing in with Google: $e');
      }
      throw Exception('Ошибка входа через Google');
    }
  }



  // Сброс пароля
  static Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Выход
  static Future<void> signOut() async {
    await _googleSignIn.signOut();

    await _auth.signOut();
  }

  // ===== ПРОФИЛИ =====

  // Создание профиля пользователя
  static Future<void> _createUserProfile(User user) async {
    final profile = {
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName ?? 'Родитель',
      'photoURL': user.photoURL,
      'level': 1,
      'xp': 0,
      'subscription': 'free',
      'createdAt': FieldValue.serverTimestamp(),
      'lastLogin': FieldValue.serverTimestamp(),
      'provider': user.providerData.isNotEmpty ? user.providerData.first.providerId : 'email',
    };

    await _firestore.collection('users').doc(user.uid).set(profile);
  }

  // Обновление времени последнего входа
  static Future<void> _updateLastLogin(String uid) async {
    await _firestore.collection('users').doc(uid).update({
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

  // ===== ДЕТИ =====

  // Добавление ребенка
  static Future<String> addChild({
    required String name,
    required DateTime birthDate,
    required String gender,
    required double height,
    required double weight,
    String petName = 'Единорог',
    String petType = '🦄',
  }) async {
    if (!isAuthenticated) throw Exception('Не авторизован');

    final childRef = await _firestore
        .collection('users')
        .doc(currentUserId!)
        .collection('children')
        .add({
      'name': name,
      'birthDate': Timestamp.fromDate(birthDate),
      'gender': gender,
      'height': height,
      'weight': weight,
      'petName': petName,
      'petType': petType,
      'petStats': {
        'happiness': 50,
        'energy': 50,
        'knowledge': 50,
      },
      'milestones': {},
      'vocabularySize': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Устанавливаем как активного ребенка
    await setActiveChild(childRef.id);

    return childRef.id;
  }

  // Обновление профиля ребенка
  static Future<void> updateChild({
    required String childId,
    required Map<String, dynamic> data,
  }) async {
    if (!isAuthenticated) return;

    data['updatedAt'] = FieldValue.serverTimestamp();

    await _firestore
        .collection('users')
        .doc(currentUserId!)
        .collection('children')
        .doc(childId)
        .update(data);
  }

  // Установка активного ребенка
  static Future<void> setActiveChild(String childId) async {
    if (!isAuthenticated) return;

    await _firestore.collection('users').doc(currentUserId!).update({
      'activeChildId': childId,
    });
  }

  // Получение активного ребенка
  static Future<ChildProfile?> getActiveChild() async {
    if (!isAuthenticated) return null;

    final userDoc = await _firestore.collection('users').doc(currentUserId!).get();
    final activeChildId = userDoc.data()?['activeChildId'];

    if (activeChildId != null) {
      return getChild(activeChildId);
    }

    // Если нет активного, берем первого
    final children = await _firestore
        .collection('users')
        .doc(currentUserId!)
        .collection('children')
        .limit(1)
        .get();

    if (children.docs.isNotEmpty) {
      final firstChild = ChildProfile.fromFirestore(
        children.docs.first.data(),
        children.docs.first.id,
      );
      await setActiveChild(firstChild.id);
      return firstChild;
    }

    return null;
  }

  // Получение ребенка по ID
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

  // Загрузка фото ребенка
  static Future<String?> uploadChildPhoto({
    required File file,
    required String childId,
  }) async {
    if (!isAuthenticated) return null;

    try {
      // Проверка существования файла
      if (!await file.exists()) {
        throw Exception('File does not exist');
      }

      // Проверка размера файла
      final fileSizeInBytes = await file.length();
      final fileSizeInMB = fileSizeInBytes / (1024 * 1024);
      
      if (fileSizeInMB > 5) {
        throw Exception('File size exceeds 5MB limit');
      }

      final ref = _storage
          .ref()
          .child('users')
          .child(currentUserId!)
          .child('children')
          .child(childId)
          .child('photo_${DateTime.now().millisecondsSinceEpoch}.jpg');

      // Загружаем с метаданными
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedBy': currentUserId!,
          'childId': childId,
        },
      );

      await ref.putFile(file, metadata);
      final url = await ref.getDownloadURL();

      // Обновляем профиль ребенка
      await _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('children')
          .doc(childId)
          .update({
            'photoURL': url,
            'photoUpdatedAt': FieldValue.serverTimestamp(),
          });

      return url;
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading photo: $e');
      }
      rethrow;
    }
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
      final newLevel = (newXP ~/ 1000) + 1;

      transaction.update(userRef, {
        'xp': newXP,
        'level': newLevel,
      });
    });
  }

  // Stream достижений
  static Stream<List<Achievement>> getAchievementsStream() {
    if (!isAuthenticated) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(currentUserId!)
        .collection('achievements')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Achievement.fromFirestore(doc.data(), doc.id))
        .toList());
  }

  // ===== СКАЗКИ =====

  // Сохранение сказки
  static Future<String> saveStory({
    required String childId,
    required String story,
    required String theme,
    String? imageUrl,
  }) async {
    if (!isAuthenticated) throw Exception('Не авторизован');

    final storyRef = await _firestore
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

    return storyRef.id;
  }

  // Переключение избранного статуса сказки
  static Future<void> toggleStoryFavorite(String storyId) async {
    if (!isAuthenticated) return;

    final storyRef = _firestore
        .collection('users')
        .doc(currentUserId!)
        .collection('stories')
        .doc(storyId);

    final storyDoc = await storyRef.get();
    if (storyDoc.exists) {
      final currentFavorite = storyDoc.data()?['isFavorite'] ?? false;
      await storyRef.update({'isFavorite': !currentFavorite});
    }
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

  // Получение избранных сказок
  static Stream<List<StoryData>> getFavoriteStoriesStream() {
    if (!isAuthenticated) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(currentUserId!)
        .collection('stories')
        .where('isFavorite', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => StoryData.fromFirestore(doc))
        .toList());
  }

  // ===== ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ =====

  // Обработка ошибок авторизации
  static String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Слишком слабый пароль';
      case 'email-already-in-use':
        return 'Email уже используется';
      case 'invalid-email':
        return 'Неверный формат email';
      case 'user-not-found':
        return 'Пользователь не найден';
      case 'wrong-password':
        return 'Неверный пароль';
      case 'user-disabled':
        return 'Аккаунт заблокирован';
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
  final String? activeChildId;

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
    this.activeChildId,
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
      activeChildId: data['activeChildId'],
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
  final int vocabularySize;
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
    required this.vocabularySize,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChildProfile.fromFirestore(Map<String, dynamic> data, String id) {
    return ChildProfile(
      id: id,
      name: data['name'] ?? '',
      birthDate: (data['birthDate'] as Timestamp).toDate(),
      gender: data['gender'] ?? 'male',
      height: (data['height'] ?? 0).toDouble(),
      weight: (data['weight'] ?? 0).toDouble(),
      photoURL: data['photoURL'],
      petName: data['petName'] ?? 'Единорог',
      petType: data['petType'] ?? '🦄',
      petStats: Map<String, int>.from(data['petStats'] ?? {
        'happiness': 50,
        'energy': 50,
        'knowledge': 50,
      }),
      milestones: data['milestones'] ?? {},
      vocabularySize: data['vocabularySize'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  int get ageInMonths {
    final now = DateTime.now();
    final months = (now.year - birthDate.year) * 12 + now.month - birthDate.month;
    
    // Корректировка, если день рождения еще не наступил в текущем месяце
    if (now.day < birthDate.day) {
      return months - 1;
    }
    
    return months;
  }

  int get ageInDays {
    final now = DateTime.now();
    final difference = now.difference(birthDate);
    return difference.inDays;
  }

  int get ageInYears {
    return ageInMonths ~/ 12;
  }

  String get ageFormatted {
    final days = ageInDays;
    final months = ageInMonths;
    final years = months ~/ 12;
    final remainingMonths = months % 12;

    // Для новорожденных (меньше недели)
    if (days < 7) {
      if (days == 0) {
        return 'Сегодня родился';
      } else if (days == 1) {
        return '1 день';
      } else if (days >= 2 && days <= 4) {
        return '$days дня';
      } else {
        return '$days дней';
      }
    }
    // Для детей младше месяца
    else if (days < 30) {
      final weeks = days ~/ 7;
      if (weeks == 1) {
        return '1 неделя';
      } else {
        return '$weeks недели';
      }
    }
    // Для детей младше года
    else if (years == 0) {
      if (remainingMonths == 1) {
        return '1 месяц';
      } else if (remainingMonths >= 2 && remainingMonths <= 4) {
        return '$remainingMonths месяца';
      } else {
        return '$remainingMonths месяцев';
      }
    }
    // Для детей старше года
    else {
      String yearStr;
      if (years == 1) {
        yearStr = '1 год';
      } else if (years >= 2 && years <= 4) {
        yearStr = '$years года';
      } else {
        yearStr = '$years лет';
      }
      
      if (remainingMonths == 0) {
        return yearStr;
      } else if (remainingMonths == 1) {
        return '$yearStr 1 мес.';
      } else {
        return '$yearStr $remainingMonths мес.';
      }
    }
  }
  
  // Краткий формат возраста для UI
  String get ageFormattedShort {
    final months = ageInMonths;
    final years = months ~/ 12;
    
    if (years == 0) {
      return '$months мес.';
    } else if (years == 1) {
      return '1 год';
    } else if (years >= 2 && years <= 4) {
      return '$years года';
    } else {
      return '$years лет';
    }
  }
}

// Достижение
class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final bool unlocked;
  final DateTime? unlockedAt;
  final int progress;
  final int maxProgress;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.unlocked,
    this.unlockedAt,
    required this.progress,
    required this.maxProgress,
  });

  factory Achievement.fromFirestore(Map<String, dynamic> data, String id) {
    return Achievement(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      icon: data['icon'] ?? '🏆',
      unlocked: data['unlocked'] ?? false,
      unlockedAt: data['unlockedAt'] != null
          ? (data['unlockedAt'] as Timestamp).toDate()
          : null,
      progress: data['progress'] ?? 0,
      maxProgress: data['maxProgress'] ?? 1,
    );
  }
}

// История
class StoryData {
  final String id;
  final String childId;
  final String theme;
  final String story;
  final String? imageUrl;
  final bool isFavorite;
  final DateTime createdAt;

  StoryData({
    required this.id,
    required this.childId,
    required this.theme,
    required this.story,
    this.imageUrl,
    required this.isFavorite,
    required this.createdAt,
  });

  factory StoryData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StoryData(
      id: doc.id,
      childId: data['childId'] ?? '',
      theme: data['theme'] ?? '',
      story: data['story'] ?? '',
      imageUrl: data['imageUrl'],
      isFavorite: data['isFavorite'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}