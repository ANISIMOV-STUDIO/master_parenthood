// lib/services/firebase_service.dart
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';

import 'dart:io';
import '../data/who_growth_standards.dart';

// Модели данных для дневника
enum DiaryEntryType { milestone, development, daily }

class DiaryEntry {
  final String id;
  final String childId;
  final String title;
  final String content;
  final DateTime date;
  final DiaryEntryType type;
  final List<String> photos;

  DiaryEntry({
    required this.id,
    required this.childId,
    required this.title,
    required this.content,
    required this.date,
    required this.type,
    required this.photos,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'childId': childId,
      'title': title,
      'content': content,
      'date': Timestamp.fromDate(date),
      'type': type.name,
      'photos': photos,
    };
  }

  static DiaryEntry fromJson(Map<String, dynamic> json) {
    return DiaryEntry(
      id: json['id'] ?? '',
      childId: json['childId'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      date: (json['date'] as Timestamp).toDate(),
      type: DiaryEntryType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => DiaryEntryType.daily,
      ),
      photos: List<String>.from(json['photos'] ?? []),
    );
  }
}

// Модели данных для трекера активностей
enum ActivityType { sleep, feeding, walk, play }
enum Mood { excited, happy, calm, sad, crying }

class Activity {
  final String id;
  final String childId;
  final ActivityType type;
  final DateTime startTime;
  final DateTime? endTime;
  final String notes;
  final Mood mood;

  Activity({
    required this.id,
    required this.childId,
    required this.type,
    required this.startTime,
    this.endTime,
    required this.notes,
    required this.mood,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'childId': childId,
      'type': type.name,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'notes': notes,
      'mood': mood.name,
    };
  }

  static Activity fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] ?? '',
      childId: json['childId'] ?? '',
      type: ActivityType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ActivityType.feeding,
      ),
      startTime: (json['startTime'] as Timestamp).toDate(),
      endTime: json['endTime'] != null 
          ? (json['endTime'] as Timestamp).toDate() 
          : null,
      notes: json['notes'] ?? '',
      mood: Mood.values.firstWhere(
        (e) => e.name == json['mood'],
        orElse: () => Mood.happy,
      ),
    );
  }
}

// Модель для измерений роста/веса
class GrowthMeasurement {
  final String id;
  final String childId;
  final DateTime date;
  final double height;
  final double weight;
  final String notes;

  GrowthMeasurement({
    required this.id,
    required this.childId,
    required this.date,
    required this.height,
    required this.weight,
    required this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'childId': childId,
      'date': Timestamp.fromDate(date),
      'height': height,
      'weight': weight,
      'notes': notes,
    };
  }

  static GrowthMeasurement fromJson(Map<String, dynamic> json) {
    return GrowthMeasurement(
      id: json['id'] ?? '',
      childId: json['childId'] ?? '',
      date: (json['date'] as Timestamp).toDate(),
      height: (json['height'] ?? 0.0).toDouble(),
      weight: (json['weight'] ?? 0.0).toDouble(),
      notes: json['notes'] ?? '',
    );
  }
}

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

    return FirebaseFirestore.instance
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

    return FirebaseFirestore.instance
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
      await FirebaseFirestore.instance
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

    return FirebaseFirestore.instance
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

    return FirebaseFirestore.instance
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

    return FirebaseFirestore.instance
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

  // ===== ДНЕВНИК РАЗВИТИЯ =====

  // Создать запись в дневнике
  static Future<String> createDiaryEntry(DiaryEntry entry) async {
    try {
      final docRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseService.currentUserId)
          .collection('diary_entries')
          .add(entry.toJson());
      
      return docRef.id;
    } catch (e) {
      throw Exception('Ошибка создания записи: ${e.toString()}');
    }
  }

  // Получить записи дневника для ребенка
  static Stream<List<DiaryEntry>> getDiaryEntriesStream(String childId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseService.currentUserId)
        .collection('diary_entries')
        .where('childId', isEqualTo: childId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DiaryEntry.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Получить все записи дневника
  static Stream<List<DiaryEntry>> getAllDiaryEntriesStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseService.currentUserId)
        .collection('diary_entries')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DiaryEntry.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Обновить запись дневника
  static Future<void> updateDiaryEntry(DiaryEntry entry) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseService.currentUserId)
          .collection('diary_entries')
          .doc(entry.id)
          .update(entry.toJson());
    } catch (e) {
      throw Exception('Ошибка обновления записи: ${e.toString()}');
    }
  }

  // Удалить запись дневника
  static Future<void> deleteDiaryEntry(String entryId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseService.currentUserId)
          .collection('diary_entries')
          .doc(entryId)
          .delete();
    } catch (e) {
      throw Exception('Ошибка удаления записи: ${e.toString()}');
    }
  }

  // ===== ТРЕКЕР АКТИВНОСТЕЙ =====

  // Создать активность
  static Future<String> createActivity(Activity activity) async {
    try {
      final docRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseService.currentUserId)
          .collection('activities')
          .add(activity.toJson());
      
      return docRef.id;
    } catch (e) {
      throw Exception('Ошибка создания активности: ${e.toString()}');
    }
  }

  // Получить активности для ребенка за определенную дату
  static Stream<List<Activity>> getActivitiesStream(String childId, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    
    return FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseService.currentUserId)
        .collection('activities')
        .where('childId', isEqualTo: childId)
        .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .orderBy('startTime', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Activity.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Получить все активности для ребенка
  static Stream<List<Activity>> getAllActivitiesStream(String childId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseService.currentUserId)
        .collection('activities')
        .where('childId', isEqualTo: childId)
        .orderBy('startTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Activity.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Обновить активность
  static Future<void> updateActivity(Activity activity) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseService.currentUserId)
          .collection('activities')
          .doc(activity.id)
          .update(activity.toJson());
    } catch (e) {
      throw Exception('Ошибка обновления активности: ${e.toString()}');
    }
  }

  // Удалить активность
  static Future<void> deleteActivity(String activityId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseService.currentUserId)
          .collection('activities')
          .doc(activityId)
          .delete();
    } catch (e) {
      throw Exception('Ошибка удаления активности: ${e.toString()}');
    }
  }

  // ===== ИЗМЕРЕНИЯ РОСТА И ВЕСА =====

  // Добавить измерение
  static Future<String> addGrowthMeasurement(GrowthMeasurement measurement) async {
    try {
      final docRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseService.currentUserId)
          .collection('growth_measurements')
          .add(measurement.toJson());
      
      // Обновляем текущие показатели в профиле ребенка
      await updateChildProfile(measurement.childId, {
        'height': measurement.height,
        'weight': measurement.weight,
      });
      
      return docRef.id;
    } catch (e) {
      throw Exception('Ошибка добавления измерения: ${e.toString()}');
    }
  }

  // Получить измерения для ребенка
  static Stream<List<GrowthMeasurement>> getGrowthMeasurementsStream(String childId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseService.currentUserId)
        .collection('growth_measurements')
        .where('childId', isEqualTo: childId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GrowthMeasurement.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Обновить измерение
  static Future<void> updateGrowthMeasurement(GrowthMeasurement measurement) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseService.currentUserId)
          .collection('growth_measurements')
          .doc(measurement.id)
          .update(measurement.toJson());
    } catch (e) {
      throw Exception('Ошибка обновления измерения: ${e.toString()}');
    }
  }

  // Удалить измерение
  static Future<void> deleteGrowthMeasurement(String measurementId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseService.currentUserId)
          .collection('growth_measurements')
          .doc(measurementId)
          .delete();
    } catch (e) {
      throw Exception('Ошибка удаления измерения: ${e.toString()}');
    }
  }

  // ===== ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ =====

  // Обновить профиль ребенка (расширенный метод)
  static Future<void> updateChildProfile(String childId, Map<String, dynamic> data) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseService.currentUserId)
          .collection('children')
          .doc(childId)
          .update({
            ...data,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Ошибка обновления профиля: ${e.toString()}');
    }
  }

  // ===== МЕДИЦИНСКИЕ МЕТОДЫ =====

  // ===== ПРИВИВКИ =====

  // Создать прививку
  static Future<String> createVaccination(Vaccination vaccination) async {
    try {
      final docRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseService.currentUserId)
          .collection('vaccinations')
          .add(vaccination.toJson());
      
      return docRef.id;
    } catch (e) {
      throw Exception('Ошибка создания прививки: ${e.toString()}');
    }
  }

  // Получить прививки для ребенка
  static Stream<List<Vaccination>> getVaccinationsStream(String childId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseService.currentUserId)
        .collection('vaccinations')
        .where('childId', isEqualTo: childId)
        .orderBy('scheduledDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Vaccination.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Получить просроченные прививки
  static Stream<List<Vaccination>> getOverdueVaccinationsStream(String childId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseService.currentUserId)
        .collection('vaccinations')
        .where('childId', isEqualTo: childId)
        .where('status', isEqualTo: VaccinationStatus.scheduled.name)
        .where('scheduledDate', isLessThan: Timestamp.now())
        .orderBy('scheduledDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Vaccination.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Получить предстоящие прививки (в течение 30 дней)
  static Stream<List<Vaccination>> getUpcomingVaccinationsStream(String childId) {
    final now = DateTime.now();
    final futureDate = now.add(const Duration(days: 30));
    
    return FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseService.currentUserId)
        .collection('vaccinations')
        .where('childId', isEqualTo: childId)
        .where('status', isEqualTo: VaccinationStatus.scheduled.name)
        .where('scheduledDate', isGreaterThan: Timestamp.now())
        .where('scheduledDate', isLessThan: Timestamp.fromDate(futureDate))
        .orderBy('scheduledDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Vaccination.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Обновить прививку
  static Future<void> updateVaccination(Vaccination vaccination) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseService.currentUserId)
          .collection('vaccinations')
          .doc(vaccination.id)
          .update(vaccination.toJson());
    } catch (e) {
      throw Exception('Ошибка обновления прививки: ${e.toString()}');
    }
  }

  // Отметить прививку как выполненную
  static Future<void> markVaccinationCompleted(
    String vaccinationId, 
    DateTime actualDate,
    {String? doctorName, String? clinic, String? reaction, String? batchNumber}
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseService.currentUserId)
          .collection('vaccinations')
          .doc(vaccinationId)
          .update({
            'status': VaccinationStatus.completed.name,
            'actualDate': Timestamp.fromDate(actualDate),
            'doctorName': doctorName,
            'clinic': clinic,
            'reaction': reaction,
            'batchNumber': batchNumber,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Ошибка отметки прививки: ${e.toString()}');
    }
  }

  // Создать календарь прививок для ребенка
  static Future<void> generateVaccinationSchedule(String childId, DateTime birthDate) async {
    try {
      final ageInMonths = DateTime.now().difference(birthDate).inDays ~/ 30;
      final scheduleTemplates = VaccinationSchedule.getScheduleForAge(ageInMonths);
      
      for (final template in scheduleTemplates) {
        final scheduledDate = birthDate.add(Duration(days: template.recommendedAgeMonths * 30));
        
        final vaccination = Vaccination(
          id: '', // будет установлен при создании
          childId: childId,
          type: template.type,
          name: template.name,
          scheduledDate: scheduledDate,
          status: VaccinationStatus.scheduled,
          attachments: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        await createVaccination(vaccination);
      }
    } catch (e) {
      throw Exception('Ошибка создания календаря прививок: ${e.toString()}');
    }
  }

  // Удалить прививку
  static Future<void> deleteVaccination(String vaccinationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseService.currentUserId)
          .collection('vaccinations')
          .doc(vaccinationId)
          .delete();
    } catch (e) {
      throw Exception('Ошибка удаления прививки: ${e.toString()}');
    }
  }

  // ===== МЕДИЦИНСКИЕ ЗАПИСИ =====

  // Создать медицинскую запись
  static Future<String> createMedicalRecord(MedicalRecord record) async {
    try {
      final docRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseService.currentUserId)
          .collection('medical_records')
          .add(record.toJson());
      
      return docRef.id;
    } catch (e) {
      throw Exception('Ошибка создания медицинской записи: ${e.toString()}');
    }
  }

  // Получить медицинские записи для ребенка
  static Stream<List<MedicalRecord>> getMedicalRecordsStream(String childId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseService.currentUserId)
        .collection('medical_records')
        .where('childId', isEqualTo: childId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MedicalRecord.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Получить медицинские записи по типу
  static Stream<List<MedicalRecord>> getMedicalRecordsByTypeStream(
    String childId, 
    MedicalRecordType type
  ) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseService.currentUserId)
        .collection('medical_records')
        .where('childId', isEqualTo: childId)
        .where('type', isEqualTo: type.name)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MedicalRecord.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Поиск медицинских записей
  static Future<List<MedicalRecord>> searchMedicalRecords(
    String childId, 
    String searchQuery
  ) async {
    try {
      final query = searchQuery.toLowerCase();
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseService.currentUserId)
          .collection('medical_records')
          .where('childId', isEqualTo: childId)
          .get();

      return snapshot.docs
          .map((doc) => MedicalRecord.fromJson({...doc.data(), 'id': doc.id}))
          .where((record) =>
              record.title.toLowerCase().contains(query) ||
              record.description.toLowerCase().contains(query) ||
              record.diagnosis?.toLowerCase().contains(query) == true ||
              record.symptoms.any((symptom) => symptom.toLowerCase().contains(query)))
          .toList();
    } catch (e) {
      throw Exception('Ошибка поиска записей: ${e.toString()}');
    }
  }

  // Обновить медицинскую запись
  static Future<void> updateMedicalRecord(MedicalRecord record) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseService.currentUserId)
          .collection('medical_records')
          .doc(record.id)
          .update(record.toJson());
    } catch (e) {
      throw Exception('Ошибка обновления медицинской записи: ${e.toString()}');
    }
  }

  // Удалить медицинскую запись
  static Future<void> deleteMedicalRecord(String recordId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseService.currentUserId)
          .collection('medical_records')
          .doc(recordId)
          .delete();
    } catch (e) {
      throw Exception('Ошибка удаления медицинской записи: ${e.toString()}');
    }
  }

  // Получить активные назначения/рецепты
  static Future<List<Prescription>> getActivePrescriptions(String childId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseService.currentUserId)
          .collection('medical_records')
          .where('childId', isEqualTo: childId)
          .get();

      final activePrescriptions = <Prescription>[];
      
      for (final doc in snapshot.docs) {
        final record = MedicalRecord.fromJson({...doc.data(), 'id': doc.id});
        activePrescriptions.addAll(
          record.prescriptions.where((prescription) => 
            !prescription.isCompleted && 
            (prescription.endDate == null || prescription.endDate!.isAfter(DateTime.now()))
          )
        );
      }
      
      return activePrescriptions;
    } catch (e) {
      throw Exception('Ошибка получения назначений: ${e.toString()}');
    }
  }

  // Получить медицинскую сводку для экспорта
  static Future<Map<String, dynamic>> getMedicalSummary(
    String childId, 
    {DateTime? fromDate, DateTime? toDate}
  ) async {
    try {
      final from = fromDate ?? DateTime.now().subtract(const Duration(days: 365));
      final to = toDate ?? DateTime.now();

      // Получаем записи за период
      final recordsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseService.currentUserId)
          .collection('medical_records')
          .where('childId', isEqualTo: childId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(to))
          .orderBy('date', descending: true)
          .get();

      // Получаем прививки за период
      final vaccinationsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseService.currentUserId)
          .collection('vaccinations')
          .where('childId', isEqualTo: childId)
          .where('actualDate', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
          .where('actualDate', isLessThanOrEqualTo: Timestamp.fromDate(to))
          .orderBy('actualDate', descending: true)
          .get();

      final records = recordsSnapshot.docs
          .map((doc) => MedicalRecord.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      final vaccinations = vaccinationsSnapshot.docs
          .map((doc) => Vaccination.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      return {
        'period': '${from.day}.${from.month}.${from.year} - ${to.day}.${to.month}.${to.year}',
        'totalRecords': records.length,
        'totalVaccinations': vaccinations.length,
        'records': records.map((r) => r.toJson()).toList(),
        'vaccinations': vaccinations.map((v) => v.toJson()).toList(),
        'recordsByType': _groupRecordsByType(records),
        'activePrescriptions': await getActivePrescriptions(childId),
        'generatedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw Exception('Ошибка создания медицинской сводки: ${e.toString()}');
    }
  }

  // Вспомогательный метод группировки записей по типу
  static Map<String, int> _groupRecordsByType(List<MedicalRecord> records) {
    final grouped = <String, int>{};
    for (final record in records) {
      final type = record.typeDisplayName;
      grouped[type] = (grouped[type] ?? 0) + 1;
    }
    return grouped;
  }

  // Загрузка медицинского документа (фото справки, анализа и т.д.)
  static Future<String?> uploadMedicalDocument({
    required File file,
    required String childId,
    required String documentType, // 'vaccination', 'medical_record'
    required String documentId,
  }) async {
    if (!isAuthenticated) return null;

    try {
      // Проверка файла
      if (!await file.exists()) {
        throw Exception('Файл не существует');
      }

      final fileSizeInBytes = await file.length();
      final fileSizeInMB = fileSizeInBytes / (1024 * 1024);
      
      if (fileSizeInMB > 10) {
        throw Exception('Размер файла превышает 10MB');
      }

      final ref = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(currentUserId!)
          .child('children')
          .child(childId)
          .child('medical')
          .child(documentType)
          .child(documentId)
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      // Загружаем с метаданными
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedBy': currentUserId!,
          'childId': childId,
          'documentType': documentType,
          'documentId': documentId,
        },
      );

      await ref.putFile(file, metadata);
      final url = await ref.getDownloadURL();

      return url;
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка загрузки медицинского документа: $e');
      }
      rethrow;
    }
  }

  // ===== МЕТОДЫ ПИТАНИЯ =====

  // ===== ПРОДУКТЫ ПИТАНИЯ =====

  // Создать продукт питания
  static Future<String> createFoodItem(FoodItem foodItem) async {
    try {
      final docRef = await FirebaseFirestore.instance
          .collection('food_items')
          .add(foodItem.toJson());
      
      return docRef.id;
    } catch (e) {
      throw Exception('Ошибка создания продукта: ${e.toString()}');
    }
  }

  // Получить все продукты питания
  static Stream<List<FoodItem>> getFoodItemsStream() {
    return FirebaseFirestore.instance
        .collection('food_items')
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FoodItem.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Найти продукты по названию
  static Future<List<FoodItem>> searchFoodItems(String query) async {
    try {
      // Поиск по названию (начинается с)
      final snapshot = await FirebaseFirestore.instance
          .collection('food_items')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      return snapshot.docs
          .map((doc) => FoodItem.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('Ошибка поиска продуктов: ${e.toString()}');
    }
  }

  // ===== ЗАПИСИ ПИТАНИЯ =====

  // Создать запись о питании
  static Future<String> createNutritionEntry(NutritionEntry entry) async {
    try {
      final docRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseService.currentUserId)
          .collection('nutrition_entries')
          .add(entry.toJson());
      
      return docRef.id;
    } catch (e) {
      throw Exception('Ошибка создания записи питания: ${e.toString()}');
    }
  }

  // Получить записи питания для ребенка
  static Stream<List<NutritionEntry>> getNutritionEntriesStream(String childId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseService.currentUserId)
        .collection('nutrition_entries')
        .where('childId', isEqualTo: childId)
        .orderBy('mealTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NutritionEntry.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Получить записи питания за день
  static Future<List<NutritionEntry>> getNutritionEntriesForDay(
    String childId, 
    DateTime date
  ) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseService.currentUserId)
          .collection('nutrition_entries')
          .where('childId', isEqualTo: childId)
          .where('mealTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('mealTime', isLessThan: Timestamp.fromDate(endOfDay))
          .orderBy('mealTime')
          .get();

      return snapshot.docs
          .map((doc) => NutritionEntry.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('Ошибка получения записей за день: ${e.toString()}');
    }
  }

  // ===== РЕЦЕПТЫ =====

  // Получить рецепты для возраста
  static Future<List<Recipe>> getRecipesForAge(int ageMonths) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('recipes')
          .where('minAgeMonths', isLessThanOrEqualTo: ageMonths)
          .orderBy('minAgeMonths')
          .orderBy('rating', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Recipe.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('Ошибка получения рецептов для возраста: ${e.toString()}');
    }
  }

  // Поиск рецептов
  static Future<List<Recipe>> searchRecipes(String query) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('recipes')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      return snapshot.docs
          .map((doc) => Recipe.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('Ошибка поиска рецептов: ${e.toString()}');
    }
  }

  // ===== АЛЛЕРГИИ =====

  // Создать информацию об аллергии
  static Future<String> createAllergyInfo(AllergyInfo allergyInfo) async {
    try {
      final docRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseService.currentUserId)
          .collection('allergies')
          .add(allergyInfo.toJson());
      
      return docRef.id;
    } catch (e) {
      throw Exception('Ошибка создания информации об аллергии: ${e.toString()}');
    }
  }

  // Получить экстренные аллергии
  static Future<List<AllergyInfo>> getEmergencyAllergies(String childId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseService.currentUserId)
          .collection('allergies')
          .where('childId', isEqualTo: childId)
          .where('isActive', isEqualTo: true)
          .where('reactionType', whereIn: [
            AllergyReactionType.severe.name,
            AllergyReactionType.anaphylaxis.name
          ])
          .get();

      return snapshot.docs
          .map((doc) => AllergyInfo.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('Ошибка получения экстренных аллергий: ${e.toString()}');
    }
  }

  // Деактивировать аллергию
  static Future<void> deactivateAllergy(String allergyId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseService.currentUserId)
          .collection('allergies')
          .doc(allergyId)
          .update({
            'isActive': false,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Ошибка деактивации аллергии: ${e.toString()}');
    }
  }

  // Получить аллергии ребенка
  static Stream<List<AllergyInfo>> getAllergiesStream(String childId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseService.currentUserId)
        .collection('allergies')
        .where('childId', isEqualTo: childId)
        .where('isActive', isEqualTo: true)
        .orderBy('firstReactionDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AllergyInfo.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // ===== ЦЕЛИ ПИТАНИЯ =====

  // Получить текущие цели питания
  static Future<NutritionGoals?> getCurrentNutritionGoals(String childId) async {
    try {
      final now = DateTime.now();
      
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseService.currentUserId)
          .collection('nutrition_goals')
          .where('childId', isEqualTo: childId)
          .where('validFrom', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .orderBy('validFrom', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        final goals = NutritionGoals.fromJson({...data, 'id': snapshot.docs.first.id});
        
        // Проверяем что цели все еще актуальны
        if (goals.validUntil == null || goals.validUntil!.isAfter(now)) {
          return goals;
        }
      }
      
      return null;
    } catch (e) {
      throw Exception('Ошибка получения целей питания: ${e.toString()}');
    }
  }

  // Создать стандартные цели питания для возраста
  static Future<String> createStandardNutritionGoals(String childId, int ageMonths) async {
    try {
      final goals = NutritionGoals.createStandardGoals(childId, ageMonths);
      final docRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseService.currentUserId)
          .collection('nutrition_goals')
          .add(goals.toJson());
      
      return docRef.id;
    } catch (e) {
      throw Exception('Ошибка создания стандартных целей: ${e.toString()}');
    }
  }

  // ===== АНАЛИЗ ПИТАНИЯ =====

  // Создать анализ питания за день
  static Future<DailyNutritionAnalysis> generateDailyNutritionAnalysis(
    String childId, 
    DateTime date
  ) async {
    try {
      // Получаем записи питания за день
      final nutritionEntries = await getNutritionEntriesForDay(childId, date);
      
      // Получаем текущие цели
      final goals = await getCurrentNutritionGoals(childId);
      if (goals == null) {
        throw Exception('Цели питания не установлены');
      }

      // Рассчитываем фактическое потребление
      double totalCalories = 0;
      double totalProtein = 0;
      double totalFats = 0;
      double totalCarbs = 0;
      double totalFiber = 0;
      double totalVitaminA = 0;
      double totalVitaminC = 0;
      double totalVitaminD = 0;
      double totalCalcium = 0;
      double totalIron = 0;
      double totalWater = 0;

      // Подсчитываем статистику приемов пищи
      int totalMeals = nutritionEntries.length;
      int mealsFinished = nutritionEntries.where((e) => e.wasFinished).length;
      double averageAppetite = totalMeals > 0 
          ? nutritionEntries.map((e) => e.appetite).reduce((a, b) => a + b) / totalMeals 
          : 0;

      final mealDistribution = <MealType, int>{};
      for (final entry in nutritionEntries) {
        mealDistribution[entry.mealType] = (mealDistribution[entry.mealType] ?? 0) + 1;
      }

      // Здесь нужно получать информацию о продуктах и считать нутриенты
      // Пока используем упрощенные расчеты
      for (final entry in nutritionEntries) {
        // Приблизительные расчеты (в реальном приложении нужно получать данные из FoodItem)
        totalCalories += entry.amount * 0.5; // Примерное значение
        totalProtein += entry.amount * 0.05;
        totalFats += entry.amount * 0.03;
        totalCarbs += entry.amount * 0.1;
        
        if (entry.unit == MeasurementUnit.milliliters) {
          totalWater += entry.amount;
        }
      }

      // Рассчитываем процент выполнения целей
      final goalCompletion = <String, double>{
        'calories': (totalCalories / goals.targetCalories * 100).clamp(0, 150),
        'protein': (totalProtein / goals.targetProtein * 100).clamp(0, 150),
        'fats': (totalFats / goals.targetFats * 100).clamp(0, 150),
        'carbs': (totalCarbs / goals.targetCarbs * 100).clamp(0, 150),
        'fiber': (totalFiber / goals.targetFiber * 100).clamp(0, 150),
        'vitaminA': (totalVitaminA / goals.targetVitaminA * 100).clamp(0, 150),
        'vitaminC': (totalVitaminC / goals.targetVitaminC * 100).clamp(0, 150),
        'vitaminD': (totalVitaminD / goals.targetVitaminD * 100).clamp(0, 150),
        'calcium': (totalCalcium / goals.targetCalcium * 100).clamp(0, 150),
        'iron': (totalIron / goals.targetIron * 100).clamp(0, 150),
        'water': (totalWater / goals.targetWater * 100).clamp(0, 150),
      };

      // Генерируем достижения и проблемы
      final achievements = <String>[];
      final concerns = <String>[];
      final recommendations = <String>[];

      if (goalCompletion['calories']! >= 80 && goalCompletion['calories']! <= 120) {
        achievements.add('Отличный баланс калорий');
      } else if (goalCompletion['calories']! < 70) {
        concerns.add('Недостаток калорий');
        recommendations.add('Увеличьте порции или добавьте полезные перекусы');
      }

      if (goalCompletion['protein']! >= 80) {
        achievements.add('Достаточно белка для роста');
      } else {
        concerns.add('Недостаток белка');
        recommendations.add('Добавьте мясо, рыбу, яйца или молочные продукты');
      }

      if (goalCompletion['vitaminC']! >= 100) {
        achievements.add('Отличное потребление витамина C');
      } else {
        recommendations.add('Добавьте больше фруктов и овощей');
      }

      if (mealsFinished == totalMeals && totalMeals > 0) {
        achievements.add('Отличный аппетит - съел все порции!');
      }

      if (averageAppetite >= 4) {
        achievements.add('Хороший аппетит');
      } else if (averageAppetite <= 2) {
        concerns.add('Плохой аппетит');
        recommendations.add('Попробуйте изменить подачу блюд или время кормления');
      }

      // Рассчитываем общий балл
      double overallScore = 70; // Базовый балл

      // Балл за баланс нутриентов
      final avgCompletion = goalCompletion.values.reduce((a, b) => a + b) / goalCompletion.length;
      if (avgCompletion >= 80 && avgCompletion <= 120) {
        overallScore += 20;
      } else if (avgCompletion >= 60) {
        overallScore += 10;
      }

      // Балл за аппетит
      if (averageAppetite >= 4) {
        overallScore += 10;
      } else if (averageAppetite >= 3) {
        overallScore += 5;
      }

      // Балл за завершенность приемов пищи
      final finishedPercentage = totalMeals > 0 ? (mealsFinished / totalMeals) * 100 : 0;
      if (finishedPercentage >= 80) {
        overallScore += 10;
      }

      overallScore = overallScore.clamp(0, 100);

      // Создаем анализ
      final analysis = DailyNutritionAnalysis(
        id: '',
        childId: childId,
        analysisDate: date,
        nutritionEntries: nutritionEntries,
        goals: goals,
        actualCalories: totalCalories,
        actualProtein: totalProtein,
        actualFats: totalFats,
        actualCarbs: totalCarbs,
        actualFiber: totalFiber,
        actualVitaminA: totalVitaminA,
        actualVitaminC: totalVitaminC,
        actualVitaminD: totalVitaminD,
        actualCalcium: totalCalcium,
        actualIron: totalIron,
        actualWater: totalWater,
        goalCompletion: goalCompletion,
        overallScore: overallScore,
        achievements: achievements,
        concerns: concerns,
        recommendations: recommendations,
        totalMeals: totalMeals,
        averageAppetite: averageAppetite,
        mealsFinished: mealsFinished,
        mealDistribution: mealDistribution,
        createdAt: DateTime.now(),
      );

      // Сохраняем анализ
      await _saveDailyNutritionAnalysis(analysis);

      return analysis;
    } catch (e) {
      throw Exception('Ошибка создания анализа питания: ${e.toString()}');
    }
  }

  // Сохранить анализ питания
  static Future<String> _saveDailyNutritionAnalysis(DailyNutritionAnalysis analysis) async {
    try {
      final docRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseService.currentUserId)
          .collection('nutrition_analyses')
          .add(analysis.toJson());
      
      return docRef.id;
    } catch (e) {
      throw Exception('Ошибка сохранения анализа питания: ${e.toString()}');
    }
  }

  // Получить анализы питания
  static Stream<List<DailyNutritionAnalysis>> getNutritionAnalysesStream(String childId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseService.currentUserId)
        .collection('nutrition_analyses')
        .where('childId', isEqualTo: childId)
        .orderBy('analysisDate', descending: true)
        .limit(30)
        .snapshots()
        .asyncMap((snapshot) async {
          final analyses = <DailyNutritionAnalysis>[];
          
          for (final doc in snapshot.docs) {
            final data = doc.data();
            // Здесь нужно получить связанные данные (entries, goals)
            // Пока создаем упрощенный анализ
            final analysis = DailyNutritionAnalysis.fromJson(
              {...data, 'id': doc.id},
              nutritionEntries: [], // Заглушка
              goals: NutritionGoals.createStandardGoals(childId, 12), // Заглушка
            );
            analyses.add(analysis);
          }
          
          return analyses;
        });
  }

  // Получить статистику питания за период
  static Future<Map<String, dynamic>> getNutritionStats(
    String childId, 
    DateTime startDate, 
    DateTime endDate
  ) async {
    try {
      final startTimestamp = Timestamp.fromDate(startDate);
      final endTimestamp = Timestamp.fromDate(endDate.add(const Duration(days: 1)));

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseService.currentUserId)
          .collection('nutrition_entries')
          .where('childId', isEqualTo: childId)
          .where('mealTime', isGreaterThanOrEqualTo: startTimestamp)
          .where('mealTime', isLessThan: endTimestamp)
          .get();

      final entries = snapshot.docs
          .map((doc) => NutritionEntry.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      // Рассчитываем статистику
      final totalEntries = entries.length;
      final finishedMeals = entries.where((e) => e.wasFinished).length;
      final avgAppetite = totalEntries > 0 
          ? entries.map((e) => e.appetite).reduce((a, b) => a + b) / totalEntries 
          : 0;

      // Статистика по типам приема пищи
      final mealTypeStats = <String, int>{};
      for (final entry in entries) {
        final key = entry.mealType.name;
        mealTypeStats[key] = (mealTypeStats[key] ?? 0) + 1;
      }

      // Любимые продукты
      final foodStats = <String, int>{};
      for (final entry in entries) {
        foodStats[entry.foodName] = (foodStats[entry.foodName] ?? 0) + 1;
      }

      final favoriteFood = foodStats.isNotEmpty 
          ? foodStats.entries.reduce((a, b) => a.value > b.value ? a : b).key
          : 'Нет данных';

      return {
        'totalEntries': totalEntries,
        'finishedMeals': finishedMeals,
        'finishedPercentage': totalEntries > 0 ? (finishedMeals / totalEntries) * 100 : 0,
        'averageAppetite': avgAppetite,
        'mealTypeStats': mealTypeStats,
        'favoriteFood': favoriteFood,
        'uniqueFoods': foodStats.keys.length,
      };
    } catch (e) {
      throw Exception('Ошибка получения статистики питания: ${e.toString()}');
    }
  }

  // Удалить запись питания
  static Future<void> deleteNutritionEntry(String entryId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseService.currentUserId)
          .collection('nutrition_entries')
          .doc(entryId)
          .delete();
    } catch (e) {
      throw Exception('Ошибка удаления записи питания: ${e.toString()}');
    }
  }

  // ===== МЕТОДЫ СНА =====

  // Создать запись о сне
  static Future<String> createSleepEntry(SleepEntry sleepEntry) async {
    try {
      final docRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseService.currentUserId)
          .collection('sleep_entries')
          .add(sleepEntry.toJson());
      
      return docRef.id;
    } catch (e) {
      throw Exception('Ошибка создания записи сна: ${e.toString()}');
    }
  }

  // Получить записи сна для ребенка
  static Stream<List<SleepEntry>> getSleepEntriesStream(String childId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseService.currentUserId)
        .collection('sleep_entries')
        .where('childId', isEqualTo: childId)
        .orderBy('date', descending: true)
        .limit(30)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SleepEntry.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Получить записи сна за период
  static Future<List<SleepEntry>> getSleepEntriesForPeriod(
    String childId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseService.currentUserId)
          .collection('sleep_entries')
          .where('childId', isEqualTo: childId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date')
          .get();

      return snapshot.docs
          .map((doc) => SleepEntry.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('Ошибка получения записей сна за период: ${e.toString()}');
    }
  }

  // Получить последнюю запись сна
  static Future<SleepEntry?> getLatestSleepEntry(String childId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseService.currentUserId)
          .collection('sleep_entries')
          .where('childId', isEqualTo: childId)
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return SleepEntry.fromJson({...snapshot.docs.first.data(), 'id': snapshot.docs.first.id});
      }
      return null;
    } catch (e) {
      throw Exception('Ошибка получения последней записи сна: ${e.toString()}');
    }
  }

  // Обновить запись сна
  static Future<void> updateSleepEntry(SleepEntry sleepEntry) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseService.currentUserId)
          .collection('sleep_entries')
          .doc(sleepEntry.id)
          .update(sleepEntry.toJson());
    } catch (e) {
      throw Exception('Ошибка обновления записи сна: ${e.toString()}');
    }
  }

  // Удалить запись сна
  static Future<void> deleteSleepEntry(String entryId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseService.currentUserId)
          .collection('sleep_entries')
          .doc(entryId)
          .delete();
    } catch (e) {
      throw Exception('Ошибка удаления записи сна: ${e.toString()}');
    }
  }

  // Добавить дневной сон к записи
  static Future<void> addNapToSleepEntry(String entryId, Nap nap) async {
    try {
      final entryRef = FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseService.currentUserId)
          .collection('sleep_entries')
          .doc(entryId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final entryDoc = await transaction.get(entryRef);
        
        if (entryDoc.exists) {
          final data = entryDoc.data()!;
          final currentNaps = List<Map<String, dynamic>>.from(data['naps'] ?? []);
          currentNaps.add(nap.toJson());
          
          transaction.update(entryRef, {
            'naps': currentNaps,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      throw Exception('Ошибка добавления дневного сна: ${e.toString()}');
    }
  }

  // Добавить ночное пробуждение к записи
  static Future<void> addInterruptionToSleepEntry(String entryId, SleepInterruption interruption) async {
    try {
      final entryRef = FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseService.currentUserId)
          .collection('sleep_entries')
          .doc(entryId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final entryDoc = await transaction.get(entryRef);
        
        if (entryDoc.exists) {
          final data = entryDoc.data()!;
          final currentInterruptions = List<Map<String, dynamic>>.from(data['interruptions'] ?? []);
          currentInterruptions.add(interruption.toJson());
          
          transaction.update(entryRef, {
            'interruptions': currentInterruptions,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      throw Exception('Ошибка добавления ночного пробуждения: ${e.toString()}');
    }
  }

  // ===== АНАЛИЗ СНА =====

  // Создать анализ сна за период
  static Future<SleepAnalysis> generateSleepAnalysis(
    String childId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // Получаем записи сна за период
      final sleepEntries = await getSleepEntriesForPeriod(childId, startDate, endDate);
      
      if (sleepEntries.isEmpty) {
        throw Exception('Нет данных о сне за выбранный период');
      }

      // Фильтруем полные записи
      final completeEntries = sleepEntries.where((e) => e.isCompleteEntry).toList();
      
      if (completeEntries.isEmpty) {
        throw Exception('Нет полных записей о сне за период');
      }

      // Рассчитываем статистику
      final totalNightSleep = completeEntries.fold<Duration>(
        Duration.zero,
        (sum, entry) => sum + entry.actualSleepTime,
      );
      final averageNightSleep = Duration(
        milliseconds: totalNightSleep.inMilliseconds ~/ completeEntries.length,
      );

      final totalDaytimeSleep = completeEntries.fold<Duration>(
        Duration.zero,
        (sum, entry) => sum + entry.totalNapTime,
      );
      final averageDaytimeSleep = Duration(
        milliseconds: totalDaytimeSleep.inMilliseconds ~/ completeEntries.length,
      );

      final averageTotalSleep = Duration(
        milliseconds: (totalNightSleep.inMilliseconds + totalDaytimeSleep.inMilliseconds) ~/ completeEntries.length,
      );

      // Средние времена укладывания и пробуждения
      double avgBedtime = 0;
      double avgWakeup = 0;
      double avgTimeToSleep = 0;
      double avgWakings = 0;
      double avgQuality = 0;

      for (final entry in completeEntries) {
        if (entry.bedtime != null) {
          avgBedtime += entry.bedtime!.hour * 60 + entry.bedtime!.minute;
        }
        if (entry.wakeupTime != null) {
          avgWakeup += entry.wakeupTime!.hour * 60 + entry.wakeupTime!.minute;
        }
        if (entry.timeToFallAsleep != null) {
          avgTimeToSleep += entry.timeToFallAsleep!.inMinutes;
        }
        avgWakings += entry.nightWakings;
        avgQuality += entry.quality.scoreValue;
      }

      avgBedtime /= completeEntries.length;
      avgWakeup /= completeEntries.length;
      avgTimeToSleep /= completeEntries.length;
      avgWakings /= completeEntries.length;
      avgQuality /= completeEntries.length;

      // Анализ трендов
      final sleepTimeTrend = _analyzeSleepTimeTrend(completeEntries);
      final qualityTrend = _analyzeSleepQualityTrend(completeEntries);
      final bedtimeTrend = _analyzeBedtimeTrend(completeEntries);

      // Генерируем инсайты и рекомендации
      final insights = _generateSleepInsights(completeEntries, averageNightSleep, avgQuality, avgWakings);
      final recommendations = _generateSleepRecommendations(
        averageNightSleep, 
        avgTimeToSleep, 
        avgWakings, 
        avgQuality,
        completeEntries,
      );

      // Анализ факторов влияния
      final commonFactors = _analyzeCommonSleepFactors(completeEntries);

      // Создаем анализ
      final analysis = SleepAnalysis(
        id: '',
        childId: childId,
        startDate: startDate,
        endDate: endDate,
        sleepEntries: completeEntries,
        averageNightSleep: averageNightSleep,
        averageDaytimeSleep: averageDaytimeSleep,
        averageTotalSleep: averageTotalSleep,
        averageBedtime: avgBedtime,
        averageWakeupTime: avgWakeup,
        averageTimeToFallAsleep: avgTimeToSleep,
        averageNightWakings: avgWakings,
        averageSleepQuality: avgQuality,
        sleepTimeTrend: sleepTimeTrend,
        qualityTrend: qualityTrend,
        bedtimeTrend: bedtimeTrend,
        sleepPatterns: _analyzeSleepPatterns(completeEntries),
        insights: insights,
        recommendations: recommendations,
        commonFactors: commonFactors,
        createdAt: DateTime.now(),
      );

      // Сохраняем анализ
      await _saveSleepAnalysis(analysis);

      return analysis;
    } catch (e) {
      throw Exception('Ошибка создания анализа сна: ${e.toString()}');
    }
  }

  // Вспомогательные методы анализа
  static SleepTrend _analyzeSleepTimeTrend(List<SleepEntry> entries) {
    if (entries.length < 3) return SleepTrend.stable;
    
    final recent = entries.take(entries.length ~/ 2).toList();
    final older = entries.skip(entries.length ~/ 2).toList();
    
    final recentAvg = recent.fold<Duration>(Duration.zero, (sum, e) => sum + e.actualSleepTime).inMinutes / recent.length;
    final olderAvg = older.fold<Duration>(Duration.zero, (sum, e) => sum + e.actualSleepTime).inMinutes / older.length;
    
    final diff = recentAvg - olderAvg;
    
    if (diff > 30) return SleepTrend.improving;
    if (diff < -30) return SleepTrend.declining;
    return SleepTrend.stable;
  }

  static SleepTrend _analyzeSleepQualityTrend(List<SleepEntry> entries) {
    if (entries.length < 3) return SleepTrend.stable;
    
    final recent = entries.take(entries.length ~/ 2).toList();
    final older = entries.skip(entries.length ~/ 2).toList();
    
    final recentAvg = recent.fold<double>(0, (sum, e) => sum + e.quality.scoreValue) / recent.length;
    final olderAvg = older.fold<double>(0, (sum, e) => sum + e.quality.scoreValue) / older.length;
    
    final diff = recentAvg - olderAvg;
    
    if (diff > 0.5) return SleepTrend.improving;
    if (diff < -0.5) return SleepTrend.declining;
    return SleepTrend.stable;
  }

  static SleepTrend _analyzeBedtimeTrend(List<SleepEntry> entries) {
    if (entries.length < 3) return SleepTrend.stable;
    
    final bedtimes = entries
        .where((e) => e.bedtime != null)
        .map((e) => e.bedtime!.hour * 60 + e.bedtime!.minute)
        .toList();
    
    if (bedtimes.length < 3) return SleepTrend.stable;
    
    // Рассчитываем вариацию времени укладывания
    final avg = bedtimes.fold<double>(0, (sum, t) => sum + t) / bedtimes.length;
    final variance = bedtimes.fold<double>(0, (sum, t) => sum + (t - avg) * (t - avg)) / bedtimes.length;
    
    if (variance > 900) return SleepTrend.inconsistent; // > 30 мин разброс
    return SleepTrend.stable;
  }

  static Map<String, dynamic> _analyzeSleepPatterns(List<SleepEntry> entries) {
    final patterns = <String, dynamic>{};
    
    // Анализ дней недели
    final weekdayStats = <int, List<Duration>>{};
    for (final entry in entries) {
      final weekday = entry.date.weekday;
      weekdayStats.putIfAbsent(weekday, () => []).add(entry.actualSleepTime);
    }
    
    final weekdayAverages = <String, double>{};
    weekdayStats.forEach((day, durations) {
      final avg = durations.fold<Duration>(Duration.zero, (sum, d) => sum + d).inMinutes / durations.length;
      weekdayAverages['day_$day'] = avg;
    });
    
    patterns['weekday_averages'] = weekdayAverages;
    
    // Лучший и худший дни
    if (weekdayAverages.isNotEmpty) {
      final sortedDays = weekdayAverages.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      patterns['best_sleep_day'] = sortedDays.first.key;
      patterns['worst_sleep_day'] = sortedDays.last.key;
    }
    
    return patterns;
  }

  static List<String> _generateSleepInsights(
    List<SleepEntry> entries,
    Duration avgSleep,
    double avgQuality,
    double avgWakings,
  ) {
    final insights = <String>[];
    
    // Анализ продолжительности сна
    final avgHours = avgSleep.inHours;
    if (avgHours >= 11) {
      insights.add('Отличная продолжительность сна - ${avgHours}ч в среднем');
    } else if (avgHours >= 9) {
      insights.add('Хорошая продолжительность сна - ${avgHours}ч в среднем');
    } else {
      insights.add('Недостаточная продолжительность сна - только ${avgHours}ч');
    }
    
    // Анализ качества
    if (avgQuality >= 4) {
      insights.add('Высокое качество сна - оценка ${avgQuality.toStringAsFixed(1)}/5');
    } else if (avgQuality >= 3) {
      insights.add('Нормальное качество сна - оценка ${avgQuality.toStringAsFixed(1)}/5');
    } else {
      insights.add('Низкое качество сна - оценка ${avgQuality.toStringAsFixed(1)}/5');
    }
    
    // Анализ ночных пробуждений
    if (avgWakings <= 1) {
      insights.add('Хороший непрерывный сон - ${avgWakings.toStringAsFixed(1)} пробуждений за ночь');
    } else if (avgWakings <= 2) {
      insights.add('Умеренные ночные пробуждения - ${avgWakings.toStringAsFixed(1)} раз за ночь');
    } else {
      insights.add('Частые ночные пробуждения - ${avgWakings.toStringAsFixed(1)} раз за ночь');
    }
    
    // Анализ регулярности
    final bedtimeVariation = _calculateBedtimeVariation(entries);
    if (bedtimeVariation < 30) {
      insights.add('Регулярный режим сна - разброс менее 30 минут');
    } else {
      insights.add('Нерегулярный режим сна - разброс ${bedtimeVariation.toInt()} минут');
    }
    
    return insights;
  }

  static List<String> _generateSleepRecommendations(
    Duration avgSleep,
    double avgTimeToSleep,
    double avgWakings,
    double avgQuality,
    List<SleepEntry> entries,
  ) {
    final recommendations = <String>[];
    
    // Рекомендации по продолжительности
    if (avgSleep.inHours < 10) {
      recommendations.add('Увеличьте время сна до 10-12 часов в сутки');
      recommendations.add('Рассмотрите более раннее время укладывания');
    }
    
    // Рекомендации по засыпанию
    if (avgTimeToSleep > 30) {
      recommendations.add('Создайте успокаивающий ритуал перед сном');
      recommendations.add('Уменьшите активность за час до укладывания');
    }
    
    // Рекомендации по ночным пробуждениям
    if (avgWakings > 2) {
      recommendations.add('Проверьте комфорт в спальне (температура, влажность)');
      recommendations.add('Рассмотрите возможные причины пробуждений');
    }
    
    // Рекомендации по качеству
    if (avgQuality < 3.5) {
      recommendations.add('Проанализируйте факторы, влияющие на качество сна');
      recommendations.add('Обратитесь к педиатру если проблемы со сном продолжаются');
    }
    
    // Рекомендации по регулярности
    final bedtimeVariation = _calculateBedtimeVariation(entries);
    if (bedtimeVariation > 30) {
      recommendations.add('Придерживайтесь постоянного времени укладывания');
      recommendations.add('Создайте четкий распорядок дня');
    }
    
    return recommendations;
  }

  static Map<String, int> _analyzeCommonSleepFactors(List<SleepEntry> entries) {
    final factors = <String, int>{};
    
    for (final entry in entries) {
      entry.factors.forEach((key, value) {
        if (value == true || (value is String && value.isNotEmpty)) {
          factors[key] = (factors[key] ?? 0) + 1;
        }
      });
    }
    
    return factors;
  }

  static double _calculateBedtimeVariation(List<SleepEntry> entries) {
    final bedtimes = entries
        .where((e) => e.bedtime != null)
        .map((e) => e.bedtime!.hour * 60 + e.bedtime!.minute)
        .toList();
    
    if (bedtimes.length < 2) return 0;
    
    final avg = bedtimes.fold<double>(0, (sum, t) => sum + t) / bedtimes.length;
    final variance = bedtimes.fold<double>(0, (sum, t) => sum + (t - avg) * (t - avg)) / bedtimes.length;
    
    return sqrt(variance);
  }

  // Сохранить анализ сна
  static Future<String> _saveSleepAnalysis(SleepAnalysis analysis) async {
    try {
      final docRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseService.currentUserId)
          .collection('sleep_analyses')
          .add(analysis.toJson());
      
      return docRef.id;
    } catch (e) {
      throw Exception('Ошибка сохранения анализа сна: ${e.toString()}');
    }
  }

  // Получить анализы сна
  static Stream<List<SleepAnalysis>> getSleepAnalysesStream(String childId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseService.currentUserId)
        .collection('sleep_analyses')
        .where('childId', isEqualTo: childId)
        .orderBy('startDate', descending: true)
        .limit(10)
        .snapshots()
        .asyncMap((snapshot) async {
          final analyses = <SleepAnalysis>[];
          
          for (final doc in snapshot.docs) {
            final data = doc.data();
            // Для упрощения передаем пустые записи сна
            final analysis = SleepAnalysis.fromJson(
              {...data, 'id': doc.id},
              [], // sleepEntries будут загружены отдельно при необходимости
            );
            analyses.add(analysis);
          }
          
          return analyses;
        });
  }

  // Получить статистику сна за период
  static Future<Map<String, dynamic>> getSleepStats(
    String childId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final entries = await getSleepEntriesForPeriod(childId, startDate, endDate);
      final completeEntries = entries.where((e) => e.isCompleteEntry).toList();
      
      if (completeEntries.isEmpty) {
        return {
          'totalEntries': 0,
          'completeEntries': 0,
          'averageSleepTime': 0,
          'averageQuality': 0,
          'averageWakings': 0,
          'totalNaps': 0,
        };
      }

      final totalSleep = completeEntries.fold<Duration>(
        Duration.zero,
        (sum, entry) => sum + entry.actualSleepTime,
      );
      
      final totalNaps = entries.fold<int>(0, (sum, entry) => sum + entry.naps.length);
      final totalWakings = completeEntries.fold<int>(0, (sum, entry) => sum + entry.nightWakings);
      final totalQuality = completeEntries.fold<int>(0, (sum, entry) => sum + entry.quality.scoreValue);

      return {
        'totalEntries': entries.length,
        'completeEntries': completeEntries.length,
        'averageSleepTime': totalSleep.inMinutes ~/ completeEntries.length,
        'averageQuality': totalQuality / completeEntries.length,
        'averageWakings': totalWakings / completeEntries.length,
        'totalNaps': totalNaps,
        'bestSleepTime': completeEntries.map((e) => e.actualSleepTime.inMinutes).reduce((a, b) => a > b ? a : b),
        'worstSleepTime': completeEntries.map((e) => e.actualSleepTime.inMinutes).reduce((a, b) => a < b ? a : b),
      };
    } catch (e) {
      throw Exception('Ошибка получения статистики сна: ${e.toString()}');
    }
  }

  // ===== МЕТОДЫ РАННЕГО РАЗВИТИЯ =====

  // ===== РАЗВИВАЮЩИЕ АКТИВНОСТИ =====

  // Создать развивающую активность
  static Future<String> createDevelopmentActivity(DevelopmentActivity activity) async {
    try {
      final docRef = await FirebaseFirestore.instance
          .collection('development_activities')
          .add(activity.toJson());
      
      return docRef.id;
    } catch (e) {
      throw Exception('Ошибка создания активности: ${e.toString()}');
    }
  }

  // Получить все развивающие активности
  static Stream<List<DevelopmentActivity>> getDevelopmentActivitiesStream() {
    return FirebaseFirestore.instance
        .collection('development_activities')
        .orderBy('area')
        .orderBy('difficulty')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DevelopmentActivity.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Получить активности по области развития
  static Future<List<DevelopmentActivity>> getActivitiesByArea(DevelopmentArea area) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('development_activities')
          .where('area', isEqualTo: area.name)
          .orderBy('difficulty')
          .get();

      return snapshot.docs
          .map((doc) => DevelopmentActivity.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('Ошибка получения активностей по области: ${e.toString()}');
    }
  }

  // Получить активности для возраста ребенка
  static Future<List<DevelopmentActivity>> getActivitiesForAge(int ageMonths) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('development_activities')
          .get();

      final activities = snapshot.docs
          .map((doc) => DevelopmentActivity.fromJson({...doc.data(), 'id': doc.id}))
          .where((activity) => activity.isAgeAppropriate(ageMonths))
          .toList();

      // Сортируем по рейтингу и области развития
      activities.sort((a, b) {
        final ratingComparison = b.rating.compareTo(a.rating);
        if (ratingComparison != 0) return ratingComparison;
        return a.area.name.compareTo(b.area.name);
      });

      return activities;
    } catch (e) {
      throw Exception('Ошибка получения активностей для возраста: ${e.toString()}');
    }
  }

  // Поиск активностей
  static Future<List<DevelopmentActivity>> searchActivities(String searchQuery) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('development_activities')
          .get();

      final query = searchQuery.toLowerCase();
      final activities = snapshot.docs
          .map((doc) => DevelopmentActivity.fromJson({...doc.data(), 'id': doc.id}))
          .where((activity) =>
              activity.title.toLowerCase().contains(query) ||
              activity.description.toLowerCase().contains(query) ||
              activity.tags.any((tag) => tag.toLowerCase().contains(query)))
          .toList();

      return activities;
    } catch (e) {
      throw Exception('Ошибка поиска активностей: ${e.toString()}');
    }
  }

  // Получить рекомендуемые активности для ребенка
  static Future<List<DevelopmentActivity>> getRecommendedActivities(String childId) async {
    try {
      // Получаем профиль ребенка для определения возраста
      final child = await getChild(childId);
      if (child == null) {
        throw Exception('Ребенок не найден');
      }

      final ageMonths = DateTime.now().difference(child.birthDate).inDays ~/ 30;

      // Получаем активности для возраста
      final ageAppropriateActivities = await getActivitiesForAge(ageMonths);

      // Получаем прогресс развития для определения слабых областей
      final progressSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseService.currentUserId)
          .collection('development_progress')
          .where('childId', isEqualTo: childId)
          .orderBy('assessmentDate', descending: true)
          .limit(1)
          .get();

      DevelopmentArea? focusArea;
      if (progressSnapshot.docs.isNotEmpty) {
        final latestProgress = DevelopmentProgress.fromJson({
          ...progressSnapshot.docs.first.data(),
          'id': progressSnapshot.docs.first.id
        });
        
        // Находим область с наименьшим прогрессом
        focusArea = latestProgress.area;
      }

      // Приоритизируем активности из нужной области
      if (focusArea != null) {
        ageAppropriateActivities.sort((a, b) {
          if (a.area == focusArea && b.area != focusArea) return -1;
          if (a.area != focusArea && b.area == focusArea) return 1;
          return b.rating.compareTo(a.rating);
        });
      }

      return ageAppropriateActivities.take(10).toList();
    } catch (e) {
      throw Exception('Ошибка получения рекомендаций: ${e.toString()}');
    }
  }

  // Получить популярные активности
  static Future<List<DevelopmentActivity>> getPopularActivities() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('development_activities')
          .orderBy('rating', descending: true)
          .orderBy('timesCompleted', descending: true)
          .limit(20)
          .get();

      return snapshot.docs
          .map((doc) => DevelopmentActivity.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('Ошибка получения популярных активностей: ${e.toString()}');
    }
  }

  // Отметить активность как избранную
  static Future<void> toggleActivityFavorite(String activityId, bool isFavorite) async {
    try {
      await FirebaseFirestore.instance
          .collection('development_activities')
          .doc(activityId)
          .update({
            'isFavorite': isFavorite,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Ошибка обновления избранного: ${e.toString()}');
    }
  }

  // ===== ВЫПОЛНЕНИЕ АКТИВНОСТЕЙ =====

  // Создать запись о выполнении активности
  static Future<String> createActivityCompletion(ActivityCompletion completion) async {
    try {
      // Создаем запись о выполнении
      final docRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseService.currentUserId)
          .collection('activity_completions')
          .add(completion.toJson());

      // Обновляем статистику активности
      await _updateActivityStats(completion.activityId, completion);

      return docRef.id;
    } catch (e) {
      throw Exception('Ошибка записи выполнения активности: ${e.toString()}');
    }
  }

  // Получить записи выполнения активностей
  static Stream<List<ActivityCompletion>> getActivityCompletionsStream(String childId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseService.currentUserId)
        .collection('activity_completions')
        .where('childId', isEqualTo: childId)
        .orderBy('completionDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ActivityCompletion.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Получить статистику выполнения активностей
  static Future<Map<String, dynamic>> getActivityStats(String childId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseService.currentUserId)
          .collection('activity_completions')
          .where('childId', isEqualTo: childId)
          .get();

      final completions = snapshot.docs
          .map((doc) => ActivityCompletion.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      // Статистика по областям развития
      final areaStats = <String, int>{};
      final areaRatings = <String, List<double>>{};
      int totalCompletions = completions.length;
      int completedActivities = completions.where((c) => c.wasCompleted).length;

      for (final completion in completions) {
        // Получаем активность для определения области
        final activitySnapshot = await FirebaseFirestore.instance
            .collection('development_activities')
            .doc(completion.activityId)
            .get();

        if (activitySnapshot.exists) {
          final activity = DevelopmentActivity.fromJson({
            ...activitySnapshot.data()!,
            'id': activitySnapshot.id
          });

          final areaName = activity.area.displayName;
          areaStats[areaName] = (areaStats[areaName] ?? 0) + 1;
          areaRatings.putIfAbsent(areaName, () => []).add(completion.averageRating);
        }
      }

      // Средние рейтинги по областям
      final areaAverageRatings = <String, double>{};
      areaRatings.forEach((area, ratings) {
        areaAverageRatings[area] = ratings.reduce((a, b) => a + b) / ratings.length;
      });

      final totalMinutes = completions
          .fold<int>(0, (sum, c) => sum + c.actualDurationMinutes);

      return {
        'totalCompletions': totalCompletions,
        'completedActivities': completedActivities,
        'completionRate': totalCompletions > 0 ? (completedActivities / totalCompletions * 100).round() : 0,
        'areaStats': areaStats,
        'areaAverageRatings': areaAverageRatings,
        'totalMinutesSpent': totalMinutes,
        'averageSessionLength': totalCompletions > 0 ? (totalMinutes / totalCompletions).round() : 0,
        'mostActiveArea': areaStats.isNotEmpty 
            ? areaStats.entries.reduce((a, b) => a.value > b.value ? a : b).key
            : 'Нет данных',
        'favoriteArea': areaAverageRatings.isNotEmpty
            ? areaAverageRatings.entries.reduce((a, b) => a.value > b.value ? a : b).key
            : 'Нет данных',
      };
    } catch (e) {
      throw Exception('Ошибка получения статистики: ${e.toString()}');
    }
  }

  // Обновить статистику активности
  static Future<void> _updateActivityStats(String activityId, ActivityCompletion completion) async {
    try {
      final activityRef = FirebaseFirestore.instance
          .collection('development_activities')
          .doc(activityId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final activitySnapshot = await transaction.get(activityRef);
        
        if (activitySnapshot.exists) {
          final currentRating = activitySnapshot.data()!['rating'] ?? 0.0;
          final currentTimes = activitySnapshot.data()!['timesCompleted'] ?? 0;
          
          // Пересчитываем средний рейтинг
          final newTimes = currentTimes + 1;
          final newRating = ((currentRating * currentTimes) + completion.averageRating) / newTimes;
          
          transaction.update(activityRef, {
            'rating': newRating,
            'timesCompleted': newTimes,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      // Не критичная ошибка, логируем и продолжаем
      print('Ошибка обновления статистики активности: $e');
    }
  }

  // ===== ПРОГРЕСС РАЗВИТИЯ =====

  // Создать оценку прогресса развития
  static Future<String> createDevelopmentProgress(DevelopmentProgress progress) async {
    try {
      final docRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseService.currentUserId)
          .collection('development_progress')
          .add(progress.toJson());
      
      return docRef.id;
    } catch (e) {
      throw Exception('Ошибка создания прогресса развития: ${e.toString()}');
    }
  }

  // Получить прогресс развития ребенка
  static Stream<List<DevelopmentProgress>> getDevelopmentProgressStream(String childId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseService.currentUserId)
        .collection('development_progress')
        .where('childId', isEqualTo: childId)
        .orderBy('assessmentDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DevelopmentProgress.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Получить последний прогресс по области развития
  static Future<DevelopmentProgress?> getLatestProgressByArea(String childId, DevelopmentArea area) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseService.currentUserId)
          .collection('development_progress')
          .where('childId', isEqualTo: childId)
          .where('area', isEqualTo: area.name)
          .orderBy('assessmentDate', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return DevelopmentProgress.fromJson({
          ...snapshot.docs.first.data(),
          'id': snapshot.docs.first.id
        });
      }

      return null;
    } catch (e) {
      throw Exception('Ошибка получения прогресса: ${e.toString()}');
    }
  }

  // Сгенерировать общий отчет о развитии
  static Future<Map<String, dynamic>> generateDevelopmentReport(String childId) async {
    try {
      final child = await getChild(childId);
      if (child == null) {
        throw Exception('Ребенок не найден');
      }

      final ageMonths = DateTime.now().difference(child.birthDate).inDays ~/ 30;

      // Получаем последний прогресс по всем областям
      final progressByArea = <DevelopmentArea, DevelopmentProgress?>{};
      for (final area in DevelopmentArea.values) {
        progressByArea[area] = await getLatestProgressByArea(childId, area);
      }

      // Статистика активностей за последний месяц
      final monthAgo = DateTime.now().subtract(const Duration(days: 30));
      final recentCompletions = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseService.currentUserId)
          .collection('activity_completions')
          .where('childId', isEqualTo: childId)
          .where('completionDate', isGreaterThan: Timestamp.fromDate(monthAgo))
          .get();

      final completions = recentCompletions.docs
          .map((doc) => ActivityCompletion.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      // Анализ сильных и слабых сторон
      final areaScores = <String, double>{};
      final recommendations = <String>[];

      progressByArea.forEach((area, progress) {
        if (progress != null) {
          areaScores[area.displayName] = progress.progressScore;
          
          if (progress.progressScore < 60) {
            recommendations.add('Больше внимания ${area.displayName.toLowerCase()}');
          }
        }
      });

      // Находим самую развитую и наименее развитую области
      String? strongestArea;
      String? weakestArea;
      
      if (areaScores.isNotEmpty) {
        strongestArea = areaScores.entries.reduce((a, b) => a.value > b.value ? a : b).key;
        weakestArea = areaScores.entries.reduce((a, b) => a.value < b.value ? a : b).key;
      }

      return {
        'childAge': ageMonths,
        'assessmentDate': DateTime.now().toIso8601String(),
        'areaScores': areaScores,
        'strongestArea': strongestArea,
        'weakestArea': weakestArea,
        'recentActivitiesCount': completions.length,
        'averageRating': completions.isNotEmpty 
            ? completions.map((c) => c.averageRating).reduce((a, b) => a + b) / completions.length
            : 0.0,
        'recommendations': recommendations,
        'totalActivities': await _getTotalActivitiesForAge(ageMonths),
        'completedActivities': completions.where((c) => c.wasCompleted).length,
      };
    } catch (e) {
      throw Exception('Ошибка генерации отчета: ${e.toString()}');
    }
  }

  // Получить общее количество активностей для возраста
  static Future<int> _getTotalActivitiesForAge(int ageMonths) async {
    try {
      final activities = await getActivitiesForAge(ageMonths);
      return activities.length;
    } catch (e) {
      return 0;
    }
  }

  // Создать стандартные развивающие активности
  static Future<void> createDefaultDevelopmentActivities() async {
    try {
      final defaultActivities = [
        // Познавательное развитие
        DevelopmentActivity(
          id: '',
          title: 'Сортировка по цветам',
          description: 'Учим ребенка различать и сортировать предметы по цветам',
          area: DevelopmentArea.cognitive,
          difficulty: ActivityDifficulty.easy,
          ageRange: AgeRange(minMonths: 18, maxMonths: 36),
          durationMinutes: 15,
          materials: ['Цветные кубики', 'Корзинки разных цветов'],
          steps: [
            ActivityStep(
              stepNumber: 1,
              instruction: 'Приготовьте кубики трех основных цветов',
              estimatedMinutes: 2,
            ),
            ActivityStep(
              stepNumber: 2,
              instruction: 'Покажите ребенку, как класть кубики в корзинки того же цвета',
              estimatedMinutes: 5,
              tip: 'Начните с одного цвета',
            ),
            ActivityStep(
              stepNumber: 3,
              instruction: 'Пусть ребенок попробует сам сортировать',
              estimatedMinutes: 8,
            ),
          ],
          tips: ['Хвалите за каждый правильный выбор', 'Не торопите ребенка'],
          benefits: ['Развитие цветовосприятия', 'Логическое мышление', 'Мелкая моторика'],
          variations: ['Сортировка по размеру', 'Сортировка по форме'],
          imageUrls: [],
          tags: ['цвета', 'сортировка', 'логика'],
          isIndoor: true,
          requiresAdult: true,
          rating: 4.5,
          timesCompleted: 0,
          isFavorite: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),

        // Моторное развитие
        DevelopmentActivity(
          id: '',
          title: 'Рисование пальчиками',
          description: 'Развитие мелкой моторики через творческое рисование',
          area: DevelopmentArea.cognitive,
          difficulty: ActivityDifficulty.easy,
          ageRange: AgeRange(minMonths: 12, maxMonths: 24),
          durationMinutes: 20,
          materials: ['Пальчиковые краски', 'Большой лист бумаги', 'Влажные салфетки'],
          steps: [
            ActivityStep(
              stepNumber: 1,
              instruction: 'Подготовьте рабочее место и краски',
              estimatedMinutes: 3,
            ),
            ActivityStep(
              stepNumber: 2,
              instruction: 'Покажите ребенку, как макать пальчик в краску',
              estimatedMinutes: 2,
            ),
            ActivityStep(
              stepNumber: 3,
              instruction: 'Дайте ребенку свободно рисовать',
              estimatedMinutes: 15,
              tip: 'Пусть экспериментирует с цветами',
            ),
          ],
          tips: ['Защитите одежду', 'Не ограничивайте творчество'],
          benefits: ['Мелкая моторика', 'Творческое мышление', 'Тактильные ощущения'],
          variations: ['Рисование кисточкой', 'Отпечатки ладошек'],
          imageUrls: [],
          tags: ['рисование', 'моторика', 'творчество'],
          isIndoor: true,
          requiresAdult: true,
          rating: 4.8,
          timesCompleted: 0,
          isFavorite: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),

        // Речевое развитие
        DevelopmentActivity(
          id: '',
          title: 'Чтение с картинками',
          description: 'Развитие речи и словарного запаса через чтение книг',
          area: DevelopmentArea.language,
          difficulty: ActivityDifficulty.easy,
          ageRange: AgeRange(minMonths: 6, maxMonths: 36),
          durationMinutes: 10,
          materials: ['Книжки с яркими картинками', 'Удобное место для чтения'],
          steps: [
            ActivityStep(
              stepNumber: 1,
              instruction: 'Выберите книжку с яркими картинками',
              estimatedMinutes: 1,
            ),
            ActivityStep(
              stepNumber: 2,
              instruction: 'Читайте медленно, показывая на картинки',
              estimatedMinutes: 7,
              tip: 'Меняйте интонацию для разных персонажей',
            ),
            ActivityStep(
              stepNumber: 3,
              instruction: 'Задавайте вопросы о картинках',
              estimatedMinutes: 2,
            ),
          ],
          tips: ['Читайте эмоционально', 'Повторяйте любимые книги'],
          benefits: ['Развитие речи', 'Пополнение словаря', 'Любовь к чтению'],
          variations: ['Пение песенок', 'Рассказывание сказок'],
          imageUrls: [],
          tags: ['чтение', 'речь', 'книги'],
          isIndoor: true,
          requiresAdult: true,
          rating: 4.9,
          timesCompleted: 0,
          isFavorite: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      for (final activity in defaultActivities) {
        await createDevelopmentActivity(activity);
      }
    } catch (e) {
      throw Exception('Ошибка создания стандартных активностей: ${e.toString()}');
    }
  }

  // ===== МЕТОДЫ ЭКСТРЕННЫХ СИТУАЦИЙ =====

  // ===== ЭКСТРЕННЫЕ КОНТАКТЫ =====

  // Создать экстренный контакт
  static Future<String> createEmergencyContact(EmergencyContact contact) async {
    try {
      final docRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseService.currentUserId)
          .collection('emergency_contacts')
          .add(contact.toJson());
      
      return docRef.id;
    } catch (e) {
      throw Exception('Ошибка создания экстренного контакта: ${e.toString()}');
    }
  }

  // Получить экстренные контакты
  static Stream<List<EmergencyContact>> getEmergencyContactsStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseService.currentUserId)
        .collection('emergency_contacts')
        .where('isActive', isEqualTo: true)
        .orderBy('priority')
        .orderBy('type')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EmergencyContact.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Получить контакты по типу экстренной ситуации
  static Future<List<EmergencyContact>> getContactsByType(EmergencyType type) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseService.currentUserId)
          .collection('emergency_contacts')
          .where('isActive', isEqualTo: true)
          .where('type', isEqualTo: type.name)
          .orderBy('priority')
          .get();

      return snapshot.docs
          .map((doc) => EmergencyContact.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('Ошибка получения контактов по типу: ${e.toString()}');
    }
  }

  // Получить доступные сейчас контакты
  static Future<List<EmergencyContact>> getAvailableNowContacts() async {
    try {
      final allContacts = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseService.currentUserId)
          .collection('emergency_contacts')
          .where('isActive', isEqualTo: true)
          .orderBy('priority')
          .get();

      final contacts = allContacts.docs
          .map((doc) => EmergencyContact.fromJson({...doc.data(), 'id': doc.id}))
          .where((contact) => contact.isAvailableNow)
          .toList();

      return contacts;
    } catch (e) {
      throw Exception('Ошибка получения доступных контактов: ${e.toString()}');
    }
  }

  // Обновить экстренный контакт
  static Future<void> updateEmergencyContact(EmergencyContact contact) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseService.currentUserId)
          .collection('emergency_contacts')
          .doc(contact.id)
          .update(contact.toJson());
    } catch (e) {
      throw Exception('Ошибка обновления контакта: ${e.toString()}');
    }
  }

  // Удалить экстренный контакт
  static Future<void> deleteEmergencyContact(String contactId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseService.currentUserId)
          .collection('emergency_contacts')
          .doc(contactId)
          .delete();
    } catch (e) {
      throw Exception('Ошибка удаления контакта: ${e.toString()}');
    }
  }

  // Создать стандартные экстренные контакты (для России)
  static Future<void> createDefaultEmergencyContacts(String city) async {
    try {
      final defaultContacts = [
        EmergencyContact(
          id: '',
          name: 'Скорая помощь',
          phone: '103',
          description: 'Экстренная медицинская помощь',
          type: EmergencyType.other,
          isActive: true,
          isAvailable24h: true,
          country: 'RU',
          city: city,
          priority: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        EmergencyContact(
          id: '',
          name: 'Служба экстренного реагирования',
          phone: '112',
          description: 'Единый номер экстренных служб',
          type: EmergencyType.other,
          isActive: true,
          isAvailable24h: true,
          country: 'RU',
          city: city,
          priority: 2,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        EmergencyContact(
          id: '',
          name: 'Пожарная служба',
          phone: '101',
          description: 'Помощь при ожогах и пожарах',
          type: EmergencyType.burns,
          isActive: true,
          isAvailable24h: true,
          country: 'RU',
          city: city,
          priority: 3,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        EmergencyContact(
          id: '',
          name: 'Полиция',
          phone: '102',
          description: 'Экстренная помощь при травмах',
          type: EmergencyType.injury,
          isActive: true,
          isAvailable24h: true,
          country: 'RU',
          city: city,
          priority: 4,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        EmergencyContact(
          id: '',
          name: 'Справочная отравлений',
          phone: '8 (495) 628-16-87',
          description: 'Консультации при отравлениях',
          type: EmergencyType.poisoning,
          isActive: true,
          isAvailable24h: true,
          country: 'RU',
          city: city,
          priority: 5,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      for (final contact in defaultContacts) {
        await createEmergencyContact(contact);
      }
    } catch (e) {
      throw Exception('Ошибка создания стандартных контактов: ${e.toString()}');
    }
  }

  // ===== ИНСТРУКЦИИ ПЕРВОЙ ПОМОЩИ =====

  // Создать инструкцию первой помощи
  static Future<String> createFirstAidGuide(FirstAidGuide guide) async {
    try {
      final docRef = await FirebaseFirestore.instance
          .collection('first_aid_guides')
          .add(guide.toJson());
      
      return docRef.id;
    } catch (e) {
      throw Exception('Ошибка создания инструкции: ${e.toString()}');
    }
  }

  // Получить инструкции первой помощи
  static Stream<List<FirstAidGuide>> getFirstAidGuidesStream() {
    return FirebaseFirestore.instance
        .collection('first_aid_guides')
        .orderBy('type')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FirstAidGuide.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Получить инструкцию по типу экстренной ситуации
  static Future<List<FirstAidGuide>> getFirstAidGuidesByType(EmergencyType type) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('first_aid_guides')
          .where('type', isEqualTo: type.name)
          .get();

      return snapshot.docs
          .map((doc) => FirstAidGuide.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('Ошибка получения инструкций: ${e.toString()}');
    }
  }

  // Получить инструкции для возраста ребенка
  static Future<List<FirstAidGuide>> getFirstAidGuidesForAge(int ageMonths) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('first_aid_guides')
          .get();

      final guides = snapshot.docs
          .map((doc) => FirstAidGuide.fromJson({...doc.data(), 'id': doc.id}))
          .where((guide) => guide.ageRange.isApplicableForAge(ageMonths))
          .toList();

      return guides;
    } catch (e) {
      throw Exception('Ошибка получения инструкций для возраста: ${e.toString()}');
    }
  }

  // ===== ЗАПИСИ ЭКСТРЕННЫХ СЛУЧАЕВ =====

  // Создать запись экстренного случая
  static Future<String> createEmergencyRecord(EmergencyRecord record) async {
    try {
      final docRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseService.currentUserId)
          .collection('emergency_records')
          .add(record.toJson());
      
      return docRef.id;
    } catch (e) {
      throw Exception('Ошибка создания записи экстренного случая: ${e.toString()}');
    }
  }

  // Получить записи экстренных случаев
  static Stream<List<EmergencyRecord>> getEmergencyRecordsStream(String childId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseService.currentUserId)
        .collection('emergency_records')
        .where('childId', isEqualTo: childId)
        .orderBy('incidentDateTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EmergencyRecord.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Получить записи по типу экстренной ситуации
  static Future<List<EmergencyRecord>> getEmergencyRecordsByType(
    String childId, 
    EmergencyType type
  ) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseService.currentUserId)
          .collection('emergency_records')
          .where('childId', isEqualTo: childId)
          .where('type', isEqualTo: type.name)
          .orderBy('incidentDateTime', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => EmergencyRecord.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('Ошибка получения записей по типу: ${e.toString()}');
    }
  }

  // Обновить запись экстренного случая
  static Future<void> updateEmergencyRecord(EmergencyRecord record) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseService.currentUserId)
          .collection('emergency_records')
          .doc(record.id)
          .update(record.toJson());
    } catch (e) {
      throw Exception('Ошибка обновления записи: ${e.toString()}');
    }
  }

  // Удалить запись экстренного случая
  static Future<void> deleteEmergencyRecord(String recordId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseService.currentUserId)
          .collection('emergency_records')
          .doc(recordId)
          .delete();
    } catch (e) {
      throw Exception('Ошибка удаления записи: ${e.toString()}');
    }
  }

  // Получить статистику экстренных случаев
  static Future<Map<String, dynamic>> getEmergencyStats(String childId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseService.currentUserId)
          .collection('emergency_records')
          .where('childId', isEqualTo: childId)
          .get();

      final records = snapshot.docs
          .map((doc) => EmergencyRecord.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      // Статистика по типам
      final typeStats = <String, int>{};
      for (final record in records) {
        typeStats[record.type.displayName] = (typeStats[record.type.displayName] ?? 0) + 1;
      }

      // Статистика по месяцам
      final monthlyStats = <String, int>{};
      for (final record in records) {
        final monthKey = '${record.incidentDateTime.year}-${record.incidentDateTime.month.toString().padLeft(2, '0')}';
        monthlyStats[monthKey] = (monthlyStats[monthKey] ?? 0) + 1;
      }

      final hospitalizations = records.where((r) => r.wasHospitalized).length;
      final withMedicalContact = records.where((r) => r.contactsCalled.isNotEmpty).length;

      return {
        'totalRecords': records.length,
        'hospitalizations': hospitalizations,
        'withMedicalContact': withMedicalContact,
        'typeStats': typeStats,
        'monthlyStats': monthlyStats,
        'mostCommonType': typeStats.isNotEmpty 
            ? typeStats.entries.reduce((a, b) => a.value > b.value ? a : b).key
            : 'Нет данных',
        'lastIncident': records.isNotEmpty 
            ? records.first.formattedIncidentDate 
            : 'Нет записей',
      };
    } catch (e) {
      throw Exception('Ошибка получения статистики: ${e.toString()}');
    }
  }

  // Создать стандартные инструкции первой помощи
  static Future<void> createDefaultFirstAidGuides() async {
    try {
      final defaultGuides = [
        // Инструкция при удушье
        FirstAidGuide(
          id: '',
          type: EmergencyType.choking,
          title: 'Первая помощь при удушье у детей',
          shortDescription: 'Экстренные действия для освобождения дыхательных путей',
          steps: [
            FirstAidStep(
              stepNumber: 1,
              instruction: 'Проверьте рот ребенка - уберите видимые предметы пальцем',
              estimatedSeconds: 10,
              isCritical: true,
              tip: 'НЕ засовывайте палец слишком глубоко',
            ),
            FirstAidStep(
              stepNumber: 2,
              instruction: 'Поверните ребенка лицом вниз, поддерживая голову',
              estimatedSeconds: 5,
              isCritical: true,
            ),
            FirstAidStep(
              stepNumber: 3,
              instruction: 'Сделайте 5 ударов между лопатками основанием ладони',
              estimatedSeconds: 15,
              isCritical: true,
              tip: 'Удары должны быть резкими, но не слишком сильными',
            ),
            FirstAidStep(
              stepNumber: 4,
              instruction: 'Если не помогло - переверните ребенка и сделайте 5 толчков в грудь',
              estimatedSeconds: 15,
              isCritical: true,
            ),
            FirstAidStep(
              stepNumber: 5,
              instruction: 'НЕМЕДЛЕННО вызовите скорую помощь!',
              estimatedSeconds: 10,
              isCritical: true,
            ),
          ],
          warningsSigns: [
            'Ребенок не может дышать или кашлять',
            'Лицо становится синим',
            'Ребенок теряет сознание',
            'Хватается за горло',
          ],
          doList: [
            'Сохраняйте спокойствие',
            'Действуйте быстро но аккуратно',
            'Вызовите скорую немедленно',
            'Продолжайте попытки до приезда скорой',
          ],
          dontList: [
            'НЕ переворачивайте ребенка вверх ногами',
            'НЕ засовывайте пальцы глубоко в рот',
            'НЕ давайте воду',
            'НЕ оставляйте ребенка одного',
          ],
          imageUrls: [],
          ageRange: AgeRange(minMonths: 0, maxMonths: 72),
          isVerifiedByDoctor: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),

        // Инструкция при высокой температуре
        FirstAidGuide(
          id: '',
          type: EmergencyType.fever,
          title: 'Первая помощь при высокой температуре',
          shortDescription: 'Действия при температуре выше 38.5°C у ребенка',
          steps: [
            FirstAidStep(
              stepNumber: 1,
              instruction: 'Измерьте температуру точно (ректально или в ухе)',
              estimatedSeconds: 30,
              isCritical: false,
            ),
            FirstAidStep(
              stepNumber: 2,
              instruction: 'Разденьте ребенка до нижнего белья',
              estimatedSeconds: 60,
              isCritical: false,
              tip: 'Перегрев опасен при температуре',
            ),
            FirstAidStep(
              stepNumber: 3,
              instruction: 'Дайте жаропонижающее согласно весу ребенка',
              estimatedSeconds: 120,
              isCritical: true,
              tip: 'Парацетамол или ибупрофен по инструкции',
            ),
            FirstAidStep(
              stepNumber: 4,
              instruction: 'Обтирайте тело влажной тканью (не ледяной водой)',
              estimatedSeconds: 300,
              isCritical: false,
            ),
            FirstAidStep(
              stepNumber: 5,
              instruction: 'Вызовите врача, если температура выше 39°C или у малыша до 3 месяцев',
              estimatedSeconds: 60,
              isCritical: true,
            ),
          ],
          warningsSigns: [
            'Температура выше 40°C',
            'Судороги',
            'Затрудненное дыхание',
            'Ребенок не реагирует',
            'Сыпь на теле',
          ],
          doList: [
            'Давайте больше жидкости',
            'Проветривайте комнату',
            'Следите за состоянием ребенка',
            'Записывайте показания температуры',
          ],
          dontList: [
            'НЕ кутайте ребенка',
            'НЕ обтирайте спиртом',
            'НЕ давайте аспирин детям',
            'НЕ купайте в холодной воде',
          ],
          imageUrls: [],
          ageRange: AgeRange(minMonths: 0, maxMonths: 72),
          isVerifiedByDoctor: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      for (final guide in defaultGuides) {
        await createFirstAidGuide(guide);
      }
    } catch (e) {
      throw Exception('Ошибка создания стандартных инструкций: ${e.toString()}');
    }
  }

  // ===== МЕТОДЫ ФИЗИЧЕСКОГО РАЗВИТИЯ =====

  // ===== ДЕТАЛЬНЫЕ ИЗМЕРЕНИЯ РОСТА =====

  // Создать детальное измерение
  static Future<String> createDetailedGrowthMeasurement(DetailedGrowthMeasurement measurement) async {
    try {
      final docRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseService.currentUserId)
          .collection('detailed_growth_measurements')
          .add(measurement.toJson());
      
      return docRef.id;
    } catch (e) {
      throw Exception('Ошибка создания измерения: ${e.toString()}');
    }
  }

  // Получить детальные измерения для ребенка
  static Stream<List<DetailedGrowthMeasurement>> getDetailedGrowthMeasurementsStream(String childId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseService.currentUserId)
        .collection('detailed_growth_measurements')
        .where('childId', isEqualTo: childId)
        .orderBy('measurementDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DetailedGrowthMeasurement.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Получить измерения по типу
  static Stream<List<DetailedGrowthMeasurement>> getDetailedGrowthMeasurementsByTypeStream(
    String childId, 
    GrowthMeasurementType type
  ) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseService.currentUserId)
        .collection('detailed_growth_measurements')
        .where('childId', isEqualTo: childId)
        .where('type', isEqualTo: type.name)
        .orderBy('measurementDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DetailedGrowthMeasurement.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Получить последние измерения для всех типов
  static Future<Map<GrowthMeasurementType, DetailedGrowthMeasurement>> getLatestMeasurements(String childId) async {
    try {
      final result = <GrowthMeasurementType, DetailedGrowthMeasurement>{};
      
      for (final type in GrowthMeasurementType.values) {
        if (type == GrowthMeasurementType.other) continue;
        
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseService.currentUserId)
            .collection('detailed_growth_measurements')
            .where('childId', isEqualTo: childId)
            .where('type', isEqualTo: type.name)
            .orderBy('measurementDate', descending: true)
            .limit(1)
            .get();
        
        if (snapshot.docs.isNotEmpty) {
          final measurement = DetailedGrowthMeasurement.fromJson({
            ...snapshot.docs.first.data(),
            'id': snapshot.docs.first.id
          });
          result[type] = measurement;
        }
      }
      
      return result;
    } catch (e) {
      throw Exception('Ошибка получения последних измерений: ${e.toString()}');
    }
  }

  // Обновить детальное измерение
  static Future<void> updateDetailedGrowthMeasurement(DetailedGrowthMeasurement measurement) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseService.currentUserId)
          .collection('detailed_growth_measurements')
          .doc(measurement.id)
          .update(measurement.toJson());
    } catch (e) {
      throw Exception('Ошибка обновления измерения: ${e.toString()}');
    }
  }

  // Удалить детальное измерение
  static Future<void> deleteDetailedGrowthMeasurement(String measurementId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseService.currentUserId)
          .collection('detailed_growth_measurements')
          .doc(measurementId)
          .delete();
    } catch (e) {
      throw Exception('Ошибка удаления измерения: ${e.toString()}');
    }
  }

  // ===== ВЕХИ ФИЗИЧЕСКОГО РАЗВИТИЯ =====

  // Создать веху развития
  static Future<String> createPhysicalMilestone(PhysicalMilestone milestone) async {
    try {
      final docRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseService.currentUserId)
          .collection('physical_milestones')
          .add(milestone.toJson());
      
      return docRef.id;
    } catch (e) {
      throw Exception('Ошибка создания вехи развития: ${e.toString()}');
    }
  }

  // Получить вехи развития для ребенка
  static Stream<List<PhysicalMilestone>> getPhysicalMilestonesStream(String childId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseService.currentUserId)
        .collection('physical_milestones')
        .where('childId', isEqualTo: childId)
        .orderBy('typicalAgeMonths', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PhysicalMilestone.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Получить вехи по области развития
  static Stream<List<PhysicalMilestone>> getPhysicalMilestonesByAreaStream(
    String childId, 
    DevelopmentArea area
  ) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseService.currentUserId)
        .collection('physical_milestones')
        .where('childId', isEqualTo: childId)
        .where('area', isEqualTo: area.name)
        .orderBy('typicalAgeMonths', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PhysicalMilestone.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Получить достигнутые вехи
  static Stream<List<PhysicalMilestone>> getAchievedMilestonesStream(String childId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseService.currentUserId)
        .collection('physical_milestones')
        .where('childId', isEqualTo: childId)
        .where('status', isEqualTo: MilestoneStatus.achieved.name)
        .orderBy('achievedDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PhysicalMilestone.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Получить просроченные вехи
  static Future<List<PhysicalMilestone>> getOverdueMilestones(String childId, DateTime birthDate) async {
    try {
      final currentAgeMonths = DateTime.now().difference(birthDate).inDays ~/ 30;
      
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseService.currentUserId)
          .collection('physical_milestones')
          .where('childId', isEqualTo: childId)
          .where('status', whereIn: [MilestoneStatus.notAchieved.name, MilestoneStatus.inProgress.name])
          .get();

      return snapshot.docs
          .map((doc) => PhysicalMilestone.fromJson({...doc.data(), 'id': doc.id}))
          .where((milestone) => currentAgeMonths > milestone.maxAgeMonths)
          .toList();
    } catch (e) {
      throw Exception('Ошибка получения просроченных вех: ${e.toString()}');
    }
  }

  // Отметить веху как достигнутую
  static Future<void> markMilestoneAchieved(
    String milestoneId, 
    DateTime achievedDate,
    {String? observedBy, String? notes}
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseService.currentUserId)
          .collection('physical_milestones')
          .doc(milestoneId)
          .update({
            'status': MilestoneStatus.achieved.name,
            'achievedDate': Timestamp.fromDate(achievedDate),
            'observedBy': observedBy,
            'notes': notes,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Ошибка отметки вехи: ${e.toString()}');
    }
  }

  // Обновить веху развития
  static Future<void> updatePhysicalMilestone(PhysicalMilestone milestone) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseService.currentUserId)
          .collection('physical_milestones')
          .doc(milestone.id)
          .update(milestone.toJson());
    } catch (e) {
      throw Exception('Ошибка обновления вехи развития: ${e.toString()}');
    }
  }

  // Удалить веху развития
  static Future<void> deletePhysicalMilestone(String milestoneId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseService.currentUserId)
          .collection('physical_milestones')
          .doc(milestoneId)
          .delete();
    } catch (e) {
      throw Exception('Ошибка удаления вехи развития: ${e.toString()}');
    }
  }

  // ===== АНАЛИЗ ФИЗИЧЕСКОГО РАЗВИТИЯ =====

  // Создать анализ физического развития на основе ВОЗ данных
  static Future<GrowthAnalysis> generateGrowthAnalysis(String childId, DateTime birthDate) async {
    try {
      final currentAgeMonths = DateTime.now().difference(birthDate).inDays ~/ 30;
      final child = await getChild(childId);
      
      if (child == null) {
        throw Exception('Профиль ребенка не найден');
      }
      
      // Получаем последние измерения
      final latestMeasurements = await getLatestMeasurements(childId);
      
      // Получаем исторические данные для анализа трендов
      final heightHistory = await getDetailedGrowthMeasurementsByTypeStream(
        childId, 
        GrowthMeasurementType.height
      ).first;
      
      final weightHistory = await getDetailedGrowthMeasurementsByTypeStream(
        childId, 
        GrowthMeasurementType.weight
      ).first;
      
      // Анализируем текущие центили
      final currentPercentiles = <GrowthMeasurementType, double>{};
      final recommendations = <String>[];
      final concerns = <String>[];
      
      // Импортируем WHO данные для анализа
      
      // Анализ роста
      if (latestMeasurements.containsKey(GrowthMeasurementType.height)) {
        final heightMeasurement = latestMeasurements[GrowthMeasurementType.height]!;
        final heightPercentile = _calculatePercentileFromWHO(
          heightMeasurement.value,
          currentAgeMonths,
          child.gender,
          GrowthMeasurementType.height,
        );
        currentPercentiles[GrowthMeasurementType.height] = heightPercentile;
        
        if (heightPercentile < 3) {
          concerns.add('Рост значительно ниже нормы');
          recommendations.add('Рекомендуется консультация педиатра по поводу роста');
        } else if (heightPercentile > 97) {
          recommendations.add('Высокий рост - обычно вариант нормы');
        }
      }
      
      // Анализ веса
      if (latestMeasurements.containsKey(GrowthMeasurementType.weight)) {
        final weightMeasurement = latestMeasurements[GrowthMeasurementType.weight]!;
        final weightPercentile = _calculatePercentileFromWHO(
          weightMeasurement.value,
          currentAgeMonths,
          child.gender,
          GrowthMeasurementType.weight,
        );
        currentPercentiles[GrowthMeasurementType.weight] = weightPercentile;
        
        if (weightPercentile < 3) {
          concerns.add('Вес значительно ниже нормы');
          recommendations.add('Обратитесь к педиатру для оценки питания');
        } else if (weightPercentile > 97) {
          concerns.add('Вес значительно выше нормы');
          recommendations.add('Рекомендуется консультация по питанию');
        }
      }
      
      // Анализ трендов роста
      final growthTrends = <GrowthMeasurementType, String>{};
      
      if (heightHistory.length >= 2) {
        final trend = _analyzeGrowthTrend(heightHistory);
        growthTrends[GrowthMeasurementType.height] = trend;
        
        if (trend == 'decreasing') {
          concerns.add('Замедление роста');
          recommendations.add('Рекомендуется дополнительное наблюдение');
        }
      }
      
      if (weightHistory.length >= 2) {
        final trend = _analyzeGrowthTrend(weightHistory);
        growthTrends[GrowthMeasurementType.weight] = trend;
        
        if (trend == 'decreasing') {
          concerns.add('Потеря веса');
          recommendations.add('Срочно обратитесь к врачу');
        }
      }
      
      // Общие рекомендации
      if (recommendations.isEmpty && concerns.isEmpty) {
        recommendations.addAll([
          'Физическое развитие в норме',
          'Продолжайте регулярные измерения',
          'Обеспечивайте сбалансированное питание',
          'Поддерживайте физическую активность',
        ]);
      }
      
      // Рассчитываем общий балл развития
      double overallScore = 70; // Базовый балл
      
      // Корректируем балл на основе центилей
      for (final percentile in currentPercentiles.values) {
        if (percentile >= 15 && percentile <= 85) {
          overallScore += 10; // В норме
        } else if (percentile < 3 || percentile > 97) {
          overallScore -= 20; // Крайние значения
        } else {
          overallScore -= 5; // Незначительные отклонения
        }
      }
      
      // Корректируем балл на основе трендов
      for (final trend in growthTrends.values) {
        if (trend == 'increasing') {
          overallScore += 5;
        } else if (trend == 'decreasing') {
          overallScore -= 15;
        }
      }
      
      // Ограничиваем балл от 0 до 100
      overallScore = overallScore.clamp(0, 100);
      
      return GrowthAnalysis(
        childId: childId,
        analysisDate: DateTime.now(),
        currentAgeMonths: currentAgeMonths,
        recentMeasurements: latestMeasurements.values.toList(),
        currentPercentiles: currentPercentiles,
        growthTrends: growthTrends,
        recommendations: recommendations,
        concerns: concerns,
        overallGrowthScore: overallScore,
      );
    } catch (e) {
      throw Exception('Ошибка создания анализа развития: ${e.toString()}');
    }
  }

  // Вспомогательный метод для расчета центиля через WHO данные
  static double _calculatePercentileFromWHO(
    double value,
    int ageMonths,
    String gender,
    GrowthMeasurementType type,
  ) {
    return WHOGrowthStandards.getPercentileForValue(
      value: value,
      ageMonths: ageMonths,
      gender: gender,
      measurementType: type,
    ).toDouble();
  }

  // Анализ тренда роста
  static String _analyzeGrowthTrend(List<DetailedGrowthMeasurement> measurements) {
    if (measurements.length < 2) return 'stable';
    
    // Сортируем по дате
    measurements.sort((a, b) => a.measurementDate.compareTo(b.measurementDate));
    
    final recent = measurements.take(3).toList();
    if (recent.length < 2) return 'stable';
    
    double trend = 0;
    for (int i = 1; i < recent.length; i++) {
      trend += recent[i].value - recent[i - 1].value;
    }
    
    if (trend > 0) return 'increasing';
    if (trend < 0) return 'decreasing';
    return 'stable';
  }

  // Создать стандартные вехи развития для ребенка
  static Future<void> generateStandardMilestones(String childId) async {
    try {
      final standardMilestones = _getStandardMilestones(childId);
      
      for (final milestone in standardMilestones) {
        await createPhysicalMilestone(milestone);
      }
    } catch (e) {
      throw Exception('Ошибка создания стандартных вех: ${e.toString()}');
    }
  }

  // Получить список стандартных вех развития
  static List<PhysicalMilestone> _getStandardMilestones(String childId) {
    final now = DateTime.now();
    
    return [
      // Крупная моторика
      PhysicalMilestone(
        id: '',
        childId: childId,
        title: 'Держит голову',
        description: 'Ребенок может удерживать голову в вертикальном положении',
        area: DevelopmentArea.motor,
        typicalAgeMonths: 2,
        minAgeMonths: 1,
        maxAgeMonths: 4,
        status: MilestoneStatus.notAchieved,
        photos: [],
        createdAt: now,
        updatedAt: now,
      ),
      PhysicalMilestone(
        id: '',
        childId: childId,
        title: 'Переворачивается',
        description: 'Ребенок может переворачиваться с живота на спину и обратно',
        area: DevelopmentArea.motor,
        typicalAgeMonths: 4,
        minAgeMonths: 3,
        maxAgeMonths: 6,
        status: MilestoneStatus.notAchieved,
        photos: [],
        createdAt: now,
        updatedAt: now,
      ),
      PhysicalMilestone(
        id: '',
        childId: childId,
        title: 'Сидит без поддержки',
        description: 'Ребенок может сидеть самостоятельно без поддержки',
        area: DevelopmentArea.motor,
        typicalAgeMonths: 6,
        minAgeMonths: 5,
        maxAgeMonths: 8,
        status: MilestoneStatus.notAchieved,
        photos: [],
        createdAt: now,
        updatedAt: now,
      ),
      PhysicalMilestone(
        id: '',
        childId: childId,
        title: 'Ползает на четвереньках',
        description: 'Ребенок ползает на руках и коленях',
        area: DevelopmentArea.motor,
        typicalAgeMonths: 8,
        minAgeMonths: 6,
        maxAgeMonths: 10,
        status: MilestoneStatus.notAchieved,
        photos: [],
        createdAt: now,
        updatedAt: now,
      ),
      PhysicalMilestone(
        id: '',
        childId: childId,
        title: 'Стоит с поддержкой',
        description: 'Ребенок может стоять, держась за опору',
        area: DevelopmentArea.motor,
        typicalAgeMonths: 9,
        minAgeMonths: 7,
        maxAgeMonths: 12,
        status: MilestoneStatus.notAchieved,
        photos: [],
        createdAt: now,
        updatedAt: now,
      ),
      PhysicalMilestone(
        id: '',
        childId: childId,
        title: 'Ходит самостоятельно',
        description: 'Ребенок делает первые самостоятельные шаги',
        area: DevelopmentArea.motor,
        typicalAgeMonths: 12,
        minAgeMonths: 9,
        maxAgeMonths: 18,
        status: MilestoneStatus.notAchieved,
        photos: [],
        createdAt: now,
        updatedAt: now,
      ),
      
      // Мелкая моторика
      PhysicalMilestone(
        id: '',
        childId: childId,
        title: 'Хватает предметы',
        description: 'Ребенок может схватить предмет всей рукой',
        area: DevelopmentArea.motor,
        typicalAgeMonths: 4,
        minAgeMonths: 3,
        maxAgeMonths: 6,
        status: MilestoneStatus.notAchieved,
        photos: [],
        createdAt: now,
        updatedAt: now,
      ),
      PhysicalMilestone(
        id: '',
        childId: childId,
        title: 'Перекладывает предметы',
        description: 'Ребенок может переложить предмет из одной руки в другую',
        area: DevelopmentArea.motor,
        typicalAgeMonths: 7,
        minAgeMonths: 5,
        maxAgeMonths: 9,
        status: MilestoneStatus.notAchieved,
        photos: [],
        createdAt: now,
        updatedAt: now,
      ),
      PhysicalMilestone(
        id: '',
        childId: childId,
        title: 'Пинцетный захват',
        description: 'Ребенок может взять мелкий предмет большим и указательным пальцами',
        area: DevelopmentArea.motor,
        typicalAgeMonths: 9,
        minAgeMonths: 7,
        maxAgeMonths: 12,
        status: MilestoneStatus.notAchieved,
        photos: [],
        createdAt: now,
        updatedAt: now,
      ),
      
      // Речь и язык
      PhysicalMilestone(
        id: '',
        childId: childId,
        title: 'Первые звуки',
        description: 'Ребенок произносит первые звуки и слоги',
        area: DevelopmentArea.language,
        typicalAgeMonths: 3,
        minAgeMonths: 2,
        maxAgeMonths: 5,
        status: MilestoneStatus.notAchieved,
        photos: [],
        createdAt: now,
        updatedAt: now,
      ),
      PhysicalMilestone(
        id: '',
        childId: childId,
        title: 'Первые слова',
        description: 'Ребенок произносит первые осмысленные слова',
        area: DevelopmentArea.language,
        typicalAgeMonths: 12,
        minAgeMonths: 8,
        maxAgeMonths: 15,
        status: MilestoneStatus.notAchieved,
        photos: [],
        createdAt: now,
        updatedAt: now,
      ),
      
      // Социальное развитие
      PhysicalMilestone(
        id: '',
        childId: childId,
        title: 'Социальная улыбка',
        description: 'Ребенок улыбается в ответ на общение',
        area: DevelopmentArea.social,
        typicalAgeMonths: 2,
        minAgeMonths: 1,
        maxAgeMonths: 3,
        status: MilestoneStatus.notAchieved,
        photos: [],
        createdAt: now,
        updatedAt: now,
      ),
      PhysicalMilestone(
        id: '',
        childId: childId,
        title: 'Узнает близких',
        description: 'Ребенок узнает и по-разному реагирует на знакомых и незнакомых людей',
        area: DevelopmentArea.social,
        typicalAgeMonths: 6,
        minAgeMonths: 4,
        maxAgeMonths: 8,
        status: MilestoneStatus.notAchieved,
        photos: [],
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  // ==================== СОЦИАЛЬНЫЕ ВЕХИ ====================
  
  // Создать социальную веху
  Future<void> createSocialMilestone(SocialMilestone milestone) async {
    try {
      final docRef = _firestore.collection('social_milestones').doc();
      final newMilestone = SocialMilestone(
        id: docRef.id,
        childId: milestone.childId,
        title: milestone.title,
        description: milestone.description,
        type: milestone.type,
        socialArea: milestone.socialArea,
        emotionalArea: milestone.emotionalArea,
        typicalAgeMonths: milestone.typicalAgeMonths,
        acceptableRangeStart: milestone.acceptableRangeStart,
        acceptableRangeEnd: milestone.acceptableRangeEnd,
        currentLevel: milestone.currentLevel,
        achievedDate: milestone.achievedDate,
        lastObservedDate: milestone.lastObservedDate,
        observationNotes: milestone.observationNotes,
        supportingActivities: milestone.supportingActivities,
        isDelayed: milestone.isDelayed,
        requiresAttention: milestone.requiresAttention,
        createdAt: milestone.createdAt,
        updatedAt: DateTime.now(),
      );
      
      await docRef.set(newMilestone.toJson());
    } catch (e) {
      throw Exception('Ошибка создания социальной вехи: ${e.toString()}');
    }
  }
  
  // Получить поток социальных вех ребенка
  Stream<List<SocialMilestone>> getSocialMilestonesStream(String childId) {
    return _firestore
        .collection('social_milestones')
        .where('childId', isEqualTo: childId)
        .orderBy('typicalAgeMonths')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SocialMilestone.fromJson(doc.data()))
            .toList());
  }
  
  // Получить социальные вехи по типу
  Stream<List<SocialMilestone>> getSocialMilestonesByType(String childId, MilestoneType type) {
    return _firestore
        .collection('social_milestones')
        .where('childId', isEqualTo: childId)
        .where('type', isEqualTo: type.name)
        .orderBy('typicalAgeMonths')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SocialMilestone.fromJson(doc.data()))
            .toList());
  }
  
  // Получить социальные вехи по области
  Stream<List<SocialMilestone>> getSocialMilestonesByArea(String childId, {SocialArea? socialArea, EmotionalArea? emotionalArea}) {
    Query query = _firestore
        .collection('social_milestones')
        .where('childId', isEqualTo: childId);
    
    if (socialArea != null) {
      query = query.where('socialArea', isEqualTo: socialArea.name);
    }
    if (emotionalArea != null) {
      query = query.where('emotionalArea', isEqualTo: emotionalArea.name);
    }
    
    return query
        .orderBy('typicalAgeMonths')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .where((doc) => doc.data() != null)
            .map((doc) => SocialMilestone.fromJson(doc.data()! as Map<String, dynamic>))
            .toList());
  }
  
  // Получить достигнутые социальные вехи
  Stream<List<SocialMilestone>> getAchievedSocialMilestones(String childId) {
    return _firestore
        .collection('social_milestones')
        .where('childId', isEqualTo: childId)
        .where('currentLevel', whereIn: [AchievementLevel.achieved.name, AchievementLevel.mastered.name])
        .orderBy('achievedDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SocialMilestone.fromJson(doc.data()))
            .toList());
  }
  
  // Получить задержанные социальные вехи
  Future<List<SocialMilestone>> getDelayedSocialMilestones(String childId) async {
    try {
      final snapshot = await _firestore
          .collection('social_milestones')
          .where('childId', isEqualTo: childId)
          .where('isDelayed', isEqualTo: true)
          .orderBy('typicalAgeMonths')
          .get();
      
      return snapshot.docs
          .map((doc) => SocialMilestone.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Ошибка получения задержанных вех: ${e.toString()}');
    }
  }
  
  // Обновить уровень достижения социальной вехи
  Future<void> updateSocialMilestoneLevel(String milestoneId, AchievementLevel newLevel, {String? notes}) async {
    try {
      final updateData = <String, dynamic>{
        'currentLevel': newLevel.name,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (newLevel == AchievementLevel.achieved || newLevel == AchievementLevel.mastered) {
        updateData['achievedDate'] = FieldValue.serverTimestamp();
      }
      
      if (notes != null && notes.isNotEmpty) {
        updateData['observationNotes'] = FieldValue.arrayUnion([notes]);
        updateData['lastObservedDate'] = FieldValue.serverTimestamp();
      }
      
      await _firestore
          .collection('social_milestones')
          .doc(milestoneId)
          .update(updateData);
    } catch (e) {
      throw Exception('Ошибка обновления уровня вехи: ${e.toString()}');
    }
  }
  
  // Добавить наблюдение поведения
  Future<void> createBehaviorObservation(BehaviorObservation observation) async {
    try {
      final docRef = _firestore.collection('behavior_observations').doc();
      final newObservation = BehaviorObservation(
        id: docRef.id,
        childId: observation.childId,
        milestoneId: observation.milestoneId,
        observationDate: observation.observationDate,
        behavior: observation.behavior,
        context: observation.context,
        observedLevel: observation.observedLevel,
        triggers: observation.triggers,
        supportingFactors: observation.supportingFactors,
        observerNotes: observation.observerNotes,
        photoUrls: observation.photoUrls,
        createdAt: DateTime.now(),
      );
      
      await docRef.set(newObservation.toJson());
      
      // Обновить последнюю дату наблюдения в вехе
      await _firestore
          .collection('social_milestones')
          .doc(observation.milestoneId)
          .update({
            'lastObservedDate': FieldValue.serverTimestamp(),
            'observationNotes': FieldValue.arrayUnion([observation.observerNotes])
          });
    } catch (e) {
      throw Exception('Ошибка создания наблюдения: ${e.toString()}');
    }
  }
  
  // Получить наблюдения поведения для вехи
  Stream<List<BehaviorObservation>> getBehaviorObservationsStream(String milestoneId) {
    return _firestore
        .collection('behavior_observations')
        .where('milestoneId', isEqualTo: milestoneId)
        .orderBy('observationDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BehaviorObservation.fromJson(doc.data()))
            .toList());
  }
  
  // Получить все наблюдения ребенка
  Stream<List<BehaviorObservation>> getChildBehaviorObservationsStream(String childId) {
    return _firestore
        .collection('behavior_observations')
        .where('childId', isEqualTo: childId)
        .orderBy('observationDate', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BehaviorObservation.fromJson(doc.data()))
            .toList());
  }
  
  // Генерировать анализ социального развития
  Future<SocialDevelopmentProgress> generateSocialDevelopmentAnalysis(String childId) async {
    try {
      final milestonesSnapshot = await _firestore
          .collection('social_milestones')
          .where('childId', isEqualTo: childId)
          .get();
      
      final milestones = milestonesSnapshot.docs
          .map((doc) => SocialMilestone.fromJson(doc.data()))
          .toList();
      
      if (milestones.isEmpty) {
        throw Exception('Нет данных для анализа');
      }
      
      // Анализ по социальным областям
      final socialAreaScores = <SocialArea, double>{};
      for (final area in SocialArea.values) {
        final areaMilestones = milestones.where((m) => m.socialArea == area).toList();
        if (areaMilestones.isNotEmpty) {
          final achievedCount = areaMilestones.where((m) => 
            m.currentLevel == AchievementLevel.achieved || 
            m.currentLevel == AchievementLevel.mastered
          ).length;
          socialAreaScores[area] = (achievedCount / areaMilestones.length) * 100;
        }
      }
      
      // Анализ по эмоциональным областям
      final emotionalAreaScores = <EmotionalArea, double>{};
      for (final area in EmotionalArea.values) {
        final areaMilestones = milestones.where((m) => m.emotionalArea == area).toList();
        if (areaMilestones.isNotEmpty) {
          final achievedCount = areaMilestones.where((m) => 
            m.currentLevel == AchievementLevel.achieved || 
            m.currentLevel == AchievementLevel.mastered
          ).length;
          emotionalAreaScores[area] = (achievedCount / areaMilestones.length) * 100;
        }
      }
      
      // Общие показатели
      final totalMilestones = milestones.length;
      final achievedMilestones = milestones.where((m) => 
        m.currentLevel == AchievementLevel.achieved || 
        m.currentLevel == AchievementLevel.mastered
      ).length;
      final delayedMilestones = milestones.where((m) => m.isDelayed).length;
      
      final overallSocialScore = socialAreaScores.values.isNotEmpty 
        ? socialAreaScores.values.reduce((a, b) => a + b) / socialAreaScores.length
        : 0.0;
      final overallEmotionalScore = emotionalAreaScores.values.isNotEmpty
        ? emotionalAreaScores.values.reduce((a, b) => a + b) / emotionalAreaScores.length
        : 0.0;
      
      // Определение сильных сторон и областей для развития
      final strengths = <String>[];
      final areasForDevelopment = <String>[];
      
      socialAreaScores.forEach((area, score) {
        if (score >= 80) {
          strengths.add(_getSocialAreaDisplayName(area));
        } else if (score < 50) {
          areasForDevelopment.add(_getSocialAreaDisplayName(area));
        }
      });
      
      emotionalAreaScores.forEach((area, score) {
        if (score >= 80) {
          strengths.add(_getEmotionalAreaDisplayName(area));
        } else if (score < 50) {
          areasForDevelopment.add(_getEmotionalAreaDisplayName(area));
        }
      });
      
      // Рекомендации
      final recommendations = _generateSocialRecommendations(
        socialAreaScores, 
        emotionalAreaScores, 
        milestones
      );
      
      // Предстоящие вехи
      final child = await getChild(childId);
      final childAgeMonths = child != null ? _calculateAgeInMonths(child.birthDate) : 0;
      final upcomingMilestones = milestones
          .where((m) => 
            m.currentLevel == AchievementLevel.notStarted &&
            m.typicalAgeMonths <= childAgeMonths + 6)
          .map((m) => m.title)
          .toList();
      
      final analysis = SocialDevelopmentProgress(
        id: '',
        childId: childId,
        analysisDate: DateTime.now(),
        socialAreaScores: socialAreaScores,
        emotionalAreaScores: emotionalAreaScores,
        overallSocialScore: overallSocialScore,
        overallEmotionalScore: overallEmotionalScore,
        strengths: strengths,
        areasForDevelopment: areasForDevelopment,
        recommendations: recommendations,
        totalMilestones: totalMilestones,
        achievedMilestones: achievedMilestones,
        delayedMilestones: delayedMilestones,
        upcomingMilestones: upcomingMilestones,
        createdAt: DateTime.now(),
      );
      
      // Сохранить анализ
      await _saveSocialDevelopmentAnalysis(analysis);
      
      return analysis;
    } catch (e) {
      throw Exception('Ошибка анализа развития: ${e.toString()}');
    }
  }
  
  // Сохранить анализ социального развития
  Future<void> _saveSocialDevelopmentAnalysis(SocialDevelopmentProgress analysis) async {
    try {
      final docRef = _firestore.collection('social_development_analyses').doc();
      final analysisWithId = SocialDevelopmentProgress(
        id: docRef.id,
        childId: analysis.childId,
        analysisDate: analysis.analysisDate,
        socialAreaScores: analysis.socialAreaScores,
        emotionalAreaScores: analysis.emotionalAreaScores,
        overallSocialScore: analysis.overallSocialScore,
        overallEmotionalScore: analysis.overallEmotionalScore,
        strengths: analysis.strengths,
        areasForDevelopment: analysis.areasForDevelopment,
        recommendations: analysis.recommendations,
        totalMilestones: analysis.totalMilestones,
        achievedMilestones: analysis.achievedMilestones,
        delayedMilestones: analysis.delayedMilestones,
        upcomingMilestones: analysis.upcomingMilestones,
        createdAt: analysis.createdAt,
      );
      
      await docRef.set(analysisWithId.toJson());
    } catch (e) {
      throw Exception('Ошибка сохранения анализа: ${e.toString()}');
    }
  }
  
  // Получить поток анализов социального развития
  Stream<List<SocialDevelopmentProgress>> getSocialDevelopmentAnalysesStream(String childId) {
    return _firestore
        .collection('social_development_analyses')
        .where('childId', isEqualTo: childId)
        .orderBy('analysisDate', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SocialDevelopmentProgress.fromJson(doc.data()))
            .toList());
  }
  
  // Получить статистику социального развития
  Future<Map<String, dynamic>> getSocialDevelopmentStats(String childId) async {
    try {
      final milestonesSnapshot = await _firestore
          .collection('social_milestones')
          .where('childId', isEqualTo: childId)
          .get();
      
      final milestones = milestonesSnapshot.docs
          .map((doc) => SocialMilestone.fromJson(doc.data()))
          .toList();
      
      final observationsSnapshot = await _firestore
          .collection('behavior_observations')
          .where('childId', isEqualTo: childId)
          .get();
      
      final observations = observationsSnapshot.docs
          .map((doc) => BehaviorObservation.fromJson(doc.data()))
          .toList();
      
      final totalMilestones = milestones.length;
      final achievedMilestones = milestones.where((m) => 
        m.currentLevel == AchievementLevel.achieved || 
        m.currentLevel == AchievementLevel.mastered
      ).length;
      final totalObservations = observations.length;
      final recentObservations = observations.where((o) => 
        o.observationDate.isAfter(DateTime.now().subtract(const Duration(days: 30)))
      ).length;
      
      return {
        'totalMilestones': totalMilestones,
        'achievedMilestones': achievedMilestones,
        'progressPercentage': totalMilestones > 0 ? (achievedMilestones / totalMilestones) * 100 : 0,
        'totalObservations': totalObservations,
        'recentObservations': recentObservations,
        'delayedMilestones': milestones.where((m) => m.isDelayed).length,
        'attentionRequired': milestones.where((m) => m.requiresAttention).length,
      };
    } catch (e) {
      throw Exception('Ошибка получения статистики: ${e.toString()}');
    }
  }
  
  // Создать стандартные социальные вехи
  Future<void> createStandardSocialMilestones(String childId) async {
    try {
      final standardMilestones = _getStandardSocialMilestones(childId);
      
      for (final milestone in standardMilestones) {
        await createSocialMilestone(milestone);
      }
    } catch (e) {
      throw Exception('Ошибка создания стандартных социальных вех: ${e.toString()}');
    }
  }
  
  // Получить стандартные социальные вехи
  List<SocialMilestone> _getStandardSocialMilestones(String childId) {
    final now = DateTime.now();
    
    return [
      // Социальные вехи - Общение
      SocialMilestone(
        id: '',
        childId: childId,
        title: 'Улыбается в ответ',
        description: 'Ребенок улыбается в ответ на улыбку взрослого',
        type: MilestoneType.social,
        socialArea: SocialArea.communication,
        emotionalArea: null,
        typicalAgeMonths: 2,
        acceptableRangeStart: 1,
        acceptableRangeEnd: 4,
        currentLevel: AchievementLevel.notStarted,
        observationNotes: [],
        supportingActivities: ['Игры с мимикой', 'Песенки', 'Общение лицом к лицу'],
        isDelayed: false,
        requiresAttention: false,
        createdAt: now,
        updatedAt: now,
      ),
      SocialMilestone(
        id: '',
        childId: childId,
        title: 'Реагирует на голос',
        description: 'Поворачивает голову или смотрит на говорящего',
        type: MilestoneType.social,
        socialArea: SocialArea.communication,
        emotionalArea: null,
        typicalAgeMonths: 3,
        acceptableRangeStart: 2,
        acceptableRangeEnd: 5,
        currentLevel: AchievementLevel.notStarted,
        observationNotes: [],
        supportingActivities: ['Разговоры с ребенком', 'Пение колыбельных', 'Чтение вслух'],
        isDelayed: false,
        requiresAttention: false,
        createdAt: now,
        updatedAt: now,
      ),
      
      // Эмоциональные вехи - Самосознание
      SocialMilestone(
        id: '',
        childId: childId,
        title: 'Узнает себя в зеркале',
        description: 'Проявляет интерес к своему отражению',
        type: MilestoneType.emotional,
        socialArea: null,
        emotionalArea: EmotionalArea.selfAwareness,
        typicalAgeMonths: 18,
        acceptableRangeStart: 15,
        acceptableRangeEnd: 24,
        currentLevel: AchievementLevel.notStarted,
        observationNotes: [],
        supportingActivities: ['Игры с зеркалом', 'Фотографии ребенка', 'Называние частей тела'],
        isDelayed: false,
        requiresAttention: false,
        createdAt: now,
        updatedAt: now,
      ),
      
      // Комбинированные вехи
      SocialMilestone(
        id: '',
        childId: childId,
        title: 'Показывает эмпатию',
        description: 'Утешает других детей или животных, когда они расстроены',
        type: MilestoneType.combined,
        socialArea: SocialArea.empathy,
        emotionalArea: EmotionalArea.empathy,
        typicalAgeMonths: 24,
        acceptableRangeStart: 18,
        acceptableRangeEnd: 36,
        currentLevel: AchievementLevel.notStarted,
        observationNotes: [],
        supportingActivities: ['Чтение книг об эмоциях', 'Ролевые игры', 'Обсуждение чувств'],
        isDelayed: false,
        requiresAttention: false,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
  
  // Вспомогательные методы
  int _calculateAgeInMonths(DateTime birthDate) {
    final now = DateTime.now();
    final difference = now.difference(birthDate);
    return (difference.inDays / 30.44).round(); // Среднее количество дней в месяце
  }

  String _getSocialAreaDisplayName(SocialArea area) {
    switch (area) {
      case SocialArea.communication:
        return 'Общение';
      case SocialArea.cooperation:
        return 'Сотрудничество';
      case SocialArea.empathy:
        return 'Эмпатия';
      case SocialArea.independence:
        return 'Самостоятельность';
      case SocialArea.friendship:
        return 'Дружба';
      case SocialArea.familyBonds:
        return 'Семейные связи';
      case SocialArea.publicBehavior:
        return 'Поведение в обществе';
    }
  }
  
  String _getEmotionalAreaDisplayName(EmotionalArea area) {
    switch (area) {
      case EmotionalArea.selfAwareness:
        return 'Самосознание';
      case EmotionalArea.emotionRecognition:
        return 'Распознавание эмоций';
      case EmotionalArea.emotionRegulation:
        return 'Контроль эмоций';
      case EmotionalArea.empathy:
        return 'Эмпатия';
      case EmotionalArea.selfControl:
        return 'Самоконтроль';
      case EmotionalArea.socialSkills:
        return 'Социальные навыки';
      case EmotionalArea.resilience:
        return 'Устойчивость';
    }
  }
  
  List<String> _generateSocialRecommendations(
    Map<SocialArea, double> socialScores,
    Map<EmotionalArea, double> emotionalScores,
    List<SocialMilestone> milestones,
  ) {
    final recommendations = <String>[];
    
    // Рекомендации на основе низких показателей
    socialScores.forEach((area, score) {
      if (score < 50) {
        switch (area) {
          case SocialArea.communication:
            recommendations.add('Больше разговаривайте с ребенком, читайте книги, пойте песни');
            break;
          case SocialArea.cooperation:
            recommendations.add('Играйте в совместные игры, учите делиться игрушками');
            break;
          case SocialArea.empathy:
            recommendations.add('Обсуждайте эмоции, читайте книги о чувствах');
            break;
          case SocialArea.independence:
            recommendations.add('Поощряйте самостоятельность в простых задачах');
            break;
          case SocialArea.friendship:
            recommendations.add('Организуйте встречи с другими детьми');
            break;
          case SocialArea.familyBonds:
            recommendations.add('Проводите больше семейного времени');
            break;
          case SocialArea.publicBehavior:
            recommendations.add('Чаще бывайте в общественных местах');
            break;
        }
      }
    });
    
    emotionalScores.forEach((area, score) {
      if (score < 50) {
        switch (area) {
          case EmotionalArea.selfAwareness:
            recommendations.add('Играйте с зеркалом, фотографиями ребенка');
            break;
          case EmotionalArea.emotionRecognition:
            recommendations.add('Изучайте эмоции на картинках, в книгах');
            break;
          case EmotionalArea.emotionRegulation:
            recommendations.add('Учите техникам успокоения, дыхательным упражнениям');
            break;
          case EmotionalArea.empathy:
            recommendations.add('Развивайте сочувствие через игры и истории');
            break;
          case EmotionalArea.selfControl:
            recommendations.add('Практикуйте ожидание, учите терпению');
            break;
          case EmotionalArea.socialSkills:
            recommendations.add('Моделируйте социальное поведение');
            break;
          case EmotionalArea.resilience:
            recommendations.add('Поддерживайте при неудачах, учите преодолевать трудности');
            break;
        }
      }
    });
    
    // Общие рекомендации
    if (recommendations.isEmpty) {
      recommendations.addAll([
        'Продолжайте поддерживать развитие через ежедневное общение',
        'Читайте книги и обсуждайте события дня',
        'Хвалите за положительное поведение',
      ]);
    }
    
    return recommendations;
  }
}

// ===== МОДЕЛИ ДАННЫХ =====

// ==================== МОДЕЛИ СОЦИАЛЬНЫХ ВЕХ ====================

// Области социального развития
enum SocialArea {
  communication,
  cooperation,
  empathy,
  independence,
  friendship,
  familyBonds,
  publicBehavior
}

// Области эмоционального развития
enum EmotionalArea {
  selfAwareness,
  emotionRecognition,
  emotionRegulation,
  empathy,
  selfControl,
  socialSkills,
  resilience
}

// Тип вехи
enum MilestoneType {
  social,
  emotional,
  combined
}

// Уровень достижения
enum AchievementLevel {
  notStarted,
  beginning,
  developing,
  achieved,
  mastered
}

// Социальная веха
class SocialMilestone {
  final String id;
  final String childId;
  final String title;
  final String description;
  final MilestoneType type;
  final SocialArea? socialArea;
  final EmotionalArea? emotionalArea;
  final int typicalAgeMonths;
  final int acceptableRangeStart;
  final int acceptableRangeEnd;
  final AchievementLevel currentLevel;
  final DateTime? achievedDate;
  final DateTime? lastObservedDate;
  final List<String> observationNotes;
  final List<String> supportingActivities;
  final bool isDelayed;
  final bool requiresAttention;
  final DateTime createdAt;
  final DateTime updatedAt;

  SocialMilestone({
    required this.id,
    required this.childId,
    required this.title,
    required this.description,
    required this.type,
    this.socialArea,
    this.emotionalArea,
    required this.typicalAgeMonths,
    required this.acceptableRangeStart,
    required this.acceptableRangeEnd,
    required this.currentLevel,
    this.achievedDate,
    this.lastObservedDate,
    required this.observationNotes,
    required this.supportingActivities,
    required this.isDelayed,
    required this.requiresAttention,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'childId': childId,
    'title': title,
    'description': description,
    'type': type.name,
    'socialArea': socialArea?.name,
    'emotionalArea': emotionalArea?.name,
    'typicalAgeMonths': typicalAgeMonths,
    'acceptableRangeStart': acceptableRangeStart,
    'acceptableRangeEnd': acceptableRangeEnd,
    'currentLevel': currentLevel.name,
    'achievedDate': achievedDate?.toIso8601String(),
    'lastObservedDate': lastObservedDate?.toIso8601String(),
    'observationNotes': observationNotes,
    'supportingActivities': supportingActivities,
    'isDelayed': isDelayed,
    'requiresAttention': requiresAttention,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory SocialMilestone.fromJson(Map<String, dynamic> json) => SocialMilestone(
    id: json['id'],
    childId: json['childId'],
    title: json['title'],
    description: json['description'],
    type: MilestoneType.values.firstWhere((e) => e.name == json['type']),
    socialArea: json['socialArea'] != null 
      ? SocialArea.values.firstWhere((e) => e.name == json['socialArea']) 
      : null,
    emotionalArea: json['emotionalArea'] != null 
      ? EmotionalArea.values.firstWhere((e) => e.name == json['emotionalArea']) 
      : null,
    typicalAgeMonths: json['typicalAgeMonths'],
    acceptableRangeStart: json['acceptableRangeStart'],
    acceptableRangeEnd: json['acceptableRangeEnd'],
    currentLevel: AchievementLevel.values.firstWhere((e) => e.name == json['currentLevel']),
    achievedDate: json['achievedDate'] != null ? DateTime.parse(json['achievedDate']) : null,
    lastObservedDate: json['lastObservedDate'] != null ? DateTime.parse(json['lastObservedDate']) : null,
    observationNotes: List<String>.from(json['observationNotes'] ?? []),
    supportingActivities: List<String>.from(json['supportingActivities'] ?? []),
    isDelayed: json['isDelayed'] ?? false,
    requiresAttention: json['requiresAttention'] ?? false,
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
  );

  String get ageRangeText => '$acceptableRangeStart-$acceptableRangeEnd мес.';
  String get typicalAgeText => '$typicalAgeMonths мес.';
  
  String get levelText {
    switch (currentLevel) {
      case AchievementLevel.notStarted:
        return 'Не начато';
      case AchievementLevel.beginning:
        return 'Начальный';
      case AchievementLevel.developing:
        return 'Развивается';
      case AchievementLevel.achieved:
        return 'Достигнуто';
      case AchievementLevel.mastered:
        return 'Освоено';
    }
  }
  
  int get levelColorHex {
    switch (currentLevel) {
      case AchievementLevel.notStarted:
        return 0xFF9E9E9E;
      case AchievementLevel.beginning:
        return 0xFFFF9800;
      case AchievementLevel.developing:
        return 0xFF2196F3;
      case AchievementLevel.achieved:
        return 0xFF4CAF50;
      case AchievementLevel.mastered:
        return 0xFF8BC34A;
    }
  }
  
  String get areaDisplayName {
    if (socialArea != null) {
      switch (socialArea!) {
        case SocialArea.communication:
          return 'Общение';
        case SocialArea.cooperation:
          return 'Сотрудничество';
        case SocialArea.empathy:
          return 'Эмпатия';
        case SocialArea.independence:
          return 'Самостоятельность';
        case SocialArea.friendship:
          return 'Дружба';
        case SocialArea.familyBonds:
          return 'Семейные связи';
        case SocialArea.publicBehavior:
          return 'Поведение в обществе';
      }
    }
    if (emotionalArea != null) {
      switch (emotionalArea!) {
        case EmotionalArea.selfAwareness:
          return 'Самосознание';
        case EmotionalArea.emotionRecognition:
          return 'Распознавание эмоций';
        case EmotionalArea.emotionRegulation:
          return 'Контроль эмоций';
        case EmotionalArea.empathy:
          return 'Эмпатия';
        case EmotionalArea.selfControl:
          return 'Самоконтроль';
        case EmotionalArea.socialSkills:
          return 'Социальные навыки';
        case EmotionalArea.resilience:
          return 'Устойчивость';
      }
    }
    return 'Общее развитие';
  }
  
  String get areaEmoji {
    if (socialArea != null) {
      switch (socialArea!) {
        case SocialArea.communication:
          return '💬';
        case SocialArea.cooperation:
          return '🤝';
        case SocialArea.empathy:
          return '❤️';
        case SocialArea.independence:
          return '🎯';
        case SocialArea.friendship:
          return '👫';
        case SocialArea.familyBonds:
          return '👨‍👩‍👧‍👦';
        case SocialArea.publicBehavior:
          return '🌍';
      }
    }
    if (emotionalArea != null) {
      switch (emotionalArea!) {
        case EmotionalArea.selfAwareness:
          return '🧠';
        case EmotionalArea.emotionRecognition:
          return '👁️';
        case EmotionalArea.emotionRegulation:
          return '⚖️';
        case EmotionalArea.empathy:
          return '💝';
        case EmotionalArea.selfControl:
          return '🎛️';
        case EmotionalArea.socialSkills:
          return '🌟';
        case EmotionalArea.resilience:
          return '💪';
      }
    }
    return '🎭';
  }
}

// Наблюдение поведения
class BehaviorObservation {
  final String id;
  final String childId;
  final String milestoneId;
  final DateTime observationDate;
  final String behavior;
  final String context;
  final AchievementLevel observedLevel;
  final List<String> triggers;
  final List<String> supportingFactors;
  final String observerNotes;
  final List<String> photoUrls;
  final DateTime createdAt;

  BehaviorObservation({
    required this.id,
    required this.childId,
    required this.milestoneId,
    required this.observationDate,
    required this.behavior,
    required this.context,
    required this.observedLevel,
    required this.triggers,
    required this.supportingFactors,
    required this.observerNotes,
    required this.photoUrls,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'childId': childId,
    'milestoneId': milestoneId,
    'observationDate': observationDate.toIso8601String(),
    'behavior': behavior,
    'context': context,
    'observedLevel': observedLevel.name,
    'triggers': triggers,
    'supportingFactors': supportingFactors,
    'observerNotes': observerNotes,
    'photoUrls': photoUrls,
    'createdAt': createdAt.toIso8601String(),
  };

  factory BehaviorObservation.fromJson(Map<String, dynamic> json) => BehaviorObservation(
    id: json['id'],
    childId: json['childId'],
    milestoneId: json['milestoneId'],
    observationDate: DateTime.parse(json['observationDate']),
    behavior: json['behavior'],
    context: json['context'],
    observedLevel: AchievementLevel.values.firstWhere((e) => e.name == json['observedLevel']),
    triggers: List<String>.from(json['triggers'] ?? []),
    supportingFactors: List<String>.from(json['supportingFactors'] ?? []),
    observerNotes: json['observerNotes'],
    photoUrls: List<String>.from(json['photoUrls'] ?? []),
    createdAt: DateTime.parse(json['createdAt']),
  );
  
  String get formattedDate => DateFormat('dd.MM.yyyy в HH:mm', 'ru').format(observationDate);
}

// Прогресс социального развития
class SocialDevelopmentProgress {
  final String id;
  final String childId;
  final DateTime analysisDate;
  final Map<SocialArea, double> socialAreaScores;
  final Map<EmotionalArea, double> emotionalAreaScores;
  final double overallSocialScore;
  final double overallEmotionalScore;
  final List<String> strengths;
  final List<String> areasForDevelopment;
  final List<String> recommendations;
  final int totalMilestones;
  final int achievedMilestones;
  final int delayedMilestones;
  final List<String> upcomingMilestones;
  final DateTime createdAt;

  SocialDevelopmentProgress({
    required this.id,
    required this.childId,
    required this.analysisDate,
    required this.socialAreaScores,
    required this.emotionalAreaScores,
    required this.overallSocialScore,
    required this.overallEmotionalScore,
    required this.strengths,
    required this.areasForDevelopment,
    required this.recommendations,
    required this.totalMilestones,
    required this.achievedMilestones,
    required this.delayedMilestones,
    required this.upcomingMilestones,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'childId': childId,
    'analysisDate': analysisDate.toIso8601String(),
    'socialAreaScores': socialAreaScores.map((k, v) => MapEntry(k.name, v)),
    'emotionalAreaScores': emotionalAreaScores.map((k, v) => MapEntry(k.name, v)),
    'overallSocialScore': overallSocialScore,
    'overallEmotionalScore': overallEmotionalScore,
    'strengths': strengths,
    'areasForDevelopment': areasForDevelopment,
    'recommendations': recommendations,
    'totalMilestones': totalMilestones,
    'achievedMilestones': achievedMilestones,
    'delayedMilestones': delayedMilestones,
    'upcomingMilestones': upcomingMilestones,
    'createdAt': createdAt.toIso8601String(),
  };

  factory SocialDevelopmentProgress.fromJson(Map<String, dynamic> json) => SocialDevelopmentProgress(
    id: json['id'],
    childId: json['childId'],
    analysisDate: DateTime.parse(json['analysisDate']),
    socialAreaScores: Map<SocialArea, double>.fromEntries(
      (json['socialAreaScores'] as Map<String, dynamic>).entries.map(
        (e) => MapEntry(SocialArea.values.firstWhere((area) => area.name == e.key), e.value.toDouble())
      )
    ),
    emotionalAreaScores: Map<EmotionalArea, double>.fromEntries(
      (json['emotionalAreaScores'] as Map<String, dynamic>).entries.map(
        (e) => MapEntry(EmotionalArea.values.firstWhere((area) => area.name == e.key), e.value.toDouble())
      )
    ),
    overallSocialScore: json['overallSocialScore'].toDouble(),
    overallEmotionalScore: json['overallEmotionalScore'].toDouble(),
    strengths: List<String>.from(json['strengths'] ?? []),
    areasForDevelopment: List<String>.from(json['areasForDevelopment'] ?? []),
    recommendations: List<String>.from(json['recommendations'] ?? []),
    totalMilestones: json['totalMilestones'],
    achievedMilestones: json['achievedMilestones'],
    delayedMilestones: json['delayedMilestones'],
    upcomingMilestones: List<String>.from(json['upcomingMilestones'] ?? []),
    createdAt: DateTime.parse(json['createdAt']),
  );
  
  String get formattedDate => DateFormat('dd.MM.yyyy', 'ru').format(analysisDate);
  double get progressPercentage => totalMilestones > 0 ? (achievedMilestones / totalMilestones) * 100 : 0;
}

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

// ===== МЕДИЦИНСКИЕ МОДЕЛИ ДАННЫХ =====

// Типы прививок
enum VaccinationType {
  hepatitisB,
  tuberculosis,
  diphtheria,
  pertussis,
  tetanus,
  polio,
  pneumococcal,
  haemophilus,
  measles,
  mumps,
  rubella,
  chickenpox,
  meningococcal,
  rotavirus,
  influenza,
  covid19,
  other
}

// Статус прививки
enum VaccinationStatus {
  scheduled,    // Запланирована
  overdue,      // Просрочена
  completed,    // Выполнена
  postponed,    // Отложена
  contraindicated // Противопоказана
}

// Модель прививки
class Vaccination {
  final String id;
  final String childId;
  final VaccinationType type;
  final String name;
  final DateTime scheduledDate;
  final DateTime? actualDate;
  final VaccinationStatus status;
  final String? doctorName;
  final String? clinic;
  final String? batchNumber;
  final String? manufacturer;
  final String? reaction;
  final String? notes;
  final List<String> attachments; // фото справок, сертификатов
  final DateTime createdAt;
  final DateTime updatedAt;

  Vaccination({
    required this.id,
    required this.childId,
    required this.type,
    required this.name,
    required this.scheduledDate,
    this.actualDate,
    required this.status,
    this.doctorName,
    this.clinic,
    this.batchNumber,
    this.manufacturer,
    this.reaction,
    this.notes,
    required this.attachments,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'childId': childId,
      'type': type.name,
      'name': name,
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'actualDate': actualDate != null ? Timestamp.fromDate(actualDate!) : null,
      'status': status.name,
      'doctorName': doctorName,
      'clinic': clinic,
      'batchNumber': batchNumber,
      'manufacturer': manufacturer,
      'reaction': reaction,
      'notes': notes,
      'attachments': attachments,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static Vaccination fromJson(Map<String, dynamic> json) {
    return Vaccination(
      id: json['id'] ?? '',
      childId: json['childId'] ?? '',
      type: VaccinationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => VaccinationType.other,
      ),
      name: json['name'] ?? '',
      scheduledDate: (json['scheduledDate'] as Timestamp).toDate(),
      actualDate: json['actualDate'] != null 
          ? (json['actualDate'] as Timestamp).toDate() 
          : null,
      status: VaccinationStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => VaccinationStatus.scheduled,
      ),
      doctorName: json['doctorName'],
      clinic: json['clinic'],
      batchNumber: json['batchNumber'],
      manufacturer: json['manufacturer'],
      reaction: json['reaction'],
      notes: json['notes'],
      attachments: List<String>.from(json['attachments'] ?? []),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Вспомогательные методы
  bool get isOverdue => status == VaccinationStatus.scheduled && 
                       DateTime.now().isAfter(scheduledDate);
  
  bool get isUpcoming => status == VaccinationStatus.scheduled && 
                        DateTime.now().isBefore(scheduledDate) &&
                        scheduledDate.difference(DateTime.now()).inDays <= 30;

  String get statusDisplayName {
    switch (status) {
      case VaccinationStatus.scheduled:
        return isOverdue ? 'Просрочена' : 'Запланирована';
      case VaccinationStatus.overdue:
        return 'Просрочена';
      case VaccinationStatus.completed:
        return 'Выполнена';
      case VaccinationStatus.postponed:
        return 'Отложена';
      case VaccinationStatus.contraindicated:
        return 'Противопоказана';
    }
  }
}

// Типы медицинских записей
enum MedicalRecordType {
  checkup,        // Плановый осмотр
  illness,        // Болезнь
  emergency,      // Экстренное обращение
  consultation,   // Консультация
  hospitalization, // Госпитализация
  surgery,        // Операция
  allergy,        // Аллергическая реакция
  other
}

// Медицинская запись
class MedicalRecord {
  final String id;
  final String childId;
  final MedicalRecordType type;
  final String title;
  final String description;
  final DateTime date;
  final String? doctorName;
  final String? doctorSpecialty;
  final String? clinic;
  final String? diagnosis;
  final List<String> symptoms;
  final List<Prescription> prescriptions;
  final List<String> recommendations;
  final double? temperature;
  final double? weight;
  final double? height;
  final String? notes;
  final List<String> attachments; // фото справок, результатов анализов
  final DateTime createdAt;
  final DateTime updatedAt;

  MedicalRecord({
    required this.id,
    required this.childId,
    required this.type,
    required this.title,
    required this.description,
    required this.date,
    this.doctorName,
    this.doctorSpecialty,
    this.clinic,
    this.diagnosis,
    required this.symptoms,
    required this.prescriptions,
    required this.recommendations,
    this.temperature,
    this.weight,
    this.height,
    this.notes,
    required this.attachments,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'childId': childId,
      'type': type.name,
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'doctorName': doctorName,
      'doctorSpecialty': doctorSpecialty,
      'clinic': clinic,
      'diagnosis': diagnosis,
      'symptoms': symptoms,
      'prescriptions': prescriptions.map((p) => p.toJson()).toList(),
      'recommendations': recommendations,
      'temperature': temperature,
      'weight': weight,
      'height': height,
      'notes': notes,
      'attachments': attachments,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static MedicalRecord fromJson(Map<String, dynamic> json) {
    return MedicalRecord(
      id: json['id'] ?? '',
      childId: json['childId'] ?? '',
      type: MedicalRecordType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MedicalRecordType.other,
      ),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      date: (json['date'] as Timestamp).toDate(),
      doctorName: json['doctorName'],
      doctorSpecialty: json['doctorSpecialty'],
      clinic: json['clinic'],
      diagnosis: json['diagnosis'],
      symptoms: List<String>.from(json['symptoms'] ?? []),
      prescriptions: (json['prescriptions'] as List?)
          ?.map((p) => Prescription.fromJson(p as Map<String, dynamic>))
          .toList() ?? [],
      recommendations: List<String>.from(json['recommendations'] ?? []),
      temperature: json['temperature']?.toDouble(),
      weight: json['weight']?.toDouble(),
      height: json['height']?.toDouble(),
      notes: json['notes'],
      attachments: List<String>.from(json['attachments'] ?? []),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  String get typeDisplayName {
    switch (type) {
      case MedicalRecordType.checkup:
        return 'Плановый осмотр';
      case MedicalRecordType.illness:
        return 'Болезнь';
      case MedicalRecordType.emergency:
        return 'Экстренное обращение';
      case MedicalRecordType.consultation:
        return 'Консультация';
      case MedicalRecordType.hospitalization:
        return 'Госпитализация';
      case MedicalRecordType.surgery:
        return 'Операция';
      case MedicalRecordType.allergy:
        return 'Аллергия';
      case MedicalRecordType.other:
        return 'Другое';
    }
  }
}

// Назначение/рецепт
class Prescription {
  final String medicationName;
  final String dosage;
  final String frequency;
  final String duration;
  final String instructions;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isCompleted;

  Prescription({
    required this.medicationName,
    required this.dosage,
    required this.frequency,
    required this.duration,
    required this.instructions,
    required this.startDate,
    this.endDate,
    required this.isCompleted,
  });

  Map<String, dynamic> toJson() {
    return {
      'medicationName': medicationName,
      'dosage': dosage,
      'frequency': frequency,
      'duration': duration,
      'instructions': instructions,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'isCompleted': isCompleted,
    };
  }

  static Prescription fromJson(Map<String, dynamic> json) {
    return Prescription(
      medicationName: json['medicationName'] ?? '',
      dosage: json['dosage'] ?? '',
      frequency: json['frequency'] ?? '',
      duration: json['duration'] ?? '',
      instructions: json['instructions'] ?? '',
      startDate: (json['startDate'] as Timestamp).toDate(),
      endDate: json['endDate'] != null 
          ? (json['endDate'] as Timestamp).toDate() 
          : null,
      isCompleted: json['isCompleted'] ?? false,
    );
  }
}

// Календарь прививок по возрасту
class VaccinationSchedule {
  static List<VaccinationTemplate> getScheduleForAge(int ageInMonths) {
    final templates = <VaccinationTemplate>[];
    
    // Новорожденные (0-1 месяц)
    if (ageInMonths <= 1) {
      templates.addAll([
        VaccinationTemplate(
          type: VaccinationType.hepatitisB,
          name: 'Гепатит B (1-я доза)',
          recommendedAgeMonths: 0,
          description: 'Первая вакцинация от гепатита B в роддоме',
        ),
        VaccinationTemplate(
          type: VaccinationType.tuberculosis,
          name: 'БЦЖ',
          recommendedAgeMonths: 0,
          description: 'Вакцинация от туберкулеза',
        ),
      ]);
    }
    
    // 1 месяц
    if (ageInMonths >= 1 && ageInMonths <= 2) {
      templates.add(VaccinationTemplate(
        type: VaccinationType.hepatitisB,
        name: 'Гепатит B (2-я доза)',
        recommendedAgeMonths: 1,
        description: 'Вторая вакцинация от гепатита B',
      ));
    }
    
    // 2 месяца
    if (ageInMonths >= 2 && ageInMonths <= 3) {
      templates.addAll([
        VaccinationTemplate(
          type: VaccinationType.diphtheria,
          name: 'АКДС (1-я доза)',
          recommendedAgeMonths: 2,
          description: 'Коклюш, дифтерия, столбняк - первая доза',
        ),
        VaccinationTemplate(
          type: VaccinationType.polio,
          name: 'Полиомиелит (1-я доза)',
          recommendedAgeMonths: 2,
          description: 'Первая вакцинация от полиомиелита',
        ),
        VaccinationTemplate(
          type: VaccinationType.pneumococcal,
          name: 'Пневмококковая (1-я доза)',
          recommendedAgeMonths: 2,
          description: 'Защита от пневмококковых инфекций',
        ),
      ]);
    }
    
    // 4.5 месяца
    if (ageInMonths >= 4 && ageInMonths <= 5) {
      templates.addAll([
        VaccinationTemplate(
          type: VaccinationType.diphtheria,
          name: 'АКДС (2-я доза)',
          recommendedAgeMonths: 4,
          description: 'Коклюш, дифтерия, столбняк - вторая доза',
        ),
        VaccinationTemplate(
          type: VaccinationType.polio,
          name: 'Полиомиелит (2-я доза)',
          recommendedAgeMonths: 4,
          description: 'Вторая вакцинация от полиомиелита',
        ),
        VaccinationTemplate(
          type: VaccinationType.pneumococcal,
          name: 'Пневмококковая (2-я доза)',
          recommendedAgeMonths: 4,
          description: 'Вторая доза пневмококковой вакцины',
        ),
      ]);
    }
    
    // 6 месяцев
    if (ageInMonths >= 6 && ageInMonths <= 7) {
      templates.addAll([
        VaccinationTemplate(
          type: VaccinationType.diphtheria,
          name: 'АКДС (3-я доза)',
          recommendedAgeMonths: 6,
          description: 'Коклюш, дифтерия, столбняк - третья доза',
        ),
        VaccinationTemplate(
          type: VaccinationType.polio,
          name: 'Полиомиелит (3-я доза)',
          recommendedAgeMonths: 6,
          description: 'Третья вакцинация от полиомиелита',
        ),
        VaccinationTemplate(
          type: VaccinationType.hepatitisB,
          name: 'Гепатит B (3-я доза)',
          recommendedAgeMonths: 6,
          description: 'Третья вакцинация от гепатита B',
        ),
      ]);
    }
    
    // 12 месяцев
    if (ageInMonths >= 12 && ageInMonths <= 13) {
      templates.addAll([
        VaccinationTemplate(
          type: VaccinationType.measles,
          name: 'Корь, краснуха, паротит',
          recommendedAgeMonths: 12,
          description: 'Вакцинация от кори, краснухи и паротита',
        ),
        VaccinationTemplate(
          type: VaccinationType.pneumococcal,
          name: 'Пневмококковая (ревакцинация)',
          recommendedAgeMonths: 12,
          description: 'Ревакцинация пневмококковой инфекции',
        ),
      ]);
    }
    
    return templates;
  }
  
  static List<VaccinationTemplate> getAllSchedule() {
    // Возвращает полный календарь прививок от 0 до 18 лет
    return [
      // Можно расширить полным календарем
    ];
  }
}

// Шаблон прививки
class VaccinationTemplate {
  final VaccinationType type;
  final String name;
  final int recommendedAgeMonths;
  final String description;
  final bool isRequired;

  VaccinationTemplate({
    required this.type,
    required this.name,
    required this.recommendedAgeMonths,
    required this.description,
    this.isRequired = true,
  });
}

// ===== МОДЕЛИ ФИЗИЧЕСКОГО РАЗВИТИЯ =====

// Тип измерения роста
enum GrowthMeasurementType {
  height,      // Рост
  weight,      // Вес  
  headCircumference, // Окружность головы
  chestCircumference, // Окружность груди
  armCircumference,   // Окружность руки
  waistCircumference, // Окружность талии
  other
}

// Отдельный класс для детальных измерений
class DetailedGrowthMeasurement {
  final String id;
  final String childId;
  final GrowthMeasurementType type;
  final double value;
  final String unit; // см, кг, и т.д.
  final DateTime measurementDate;
  final String? measuredBy; // кто измерял (врач, родитель)
  final String? location; // где измеряли (дом, поликлиника)
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  DetailedGrowthMeasurement({
    required this.id,
    required this.childId,
    required this.type,
    required this.value,
    required this.unit,
    required this.measurementDate,
    this.measuredBy,
    this.location,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'childId': childId,
      'type': type.name,
      'value': value,
      'unit': unit,
      'measurementDate': Timestamp.fromDate(measurementDate),
      'measuredBy': measuredBy,
      'location': location,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static DetailedGrowthMeasurement fromJson(Map<String, dynamic> json) {
    return DetailedGrowthMeasurement(
      id: json['id'] ?? '',
      childId: json['childId'] ?? '',
      type: GrowthMeasurementType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => GrowthMeasurementType.other,
      ),
      value: (json['value'] ?? 0).toDouble(),
      unit: json['unit'] ?? '',
      measurementDate: (json['measurementDate'] as Timestamp).toDate(),
      measuredBy: json['measuredBy'],
      location: json['location'],
      notes: json['notes'],
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Вспомогательные методы
  String get typeDisplayName {
    switch (type) {
      case GrowthMeasurementType.height:
        return 'Рост';
      case GrowthMeasurementType.weight:
        return 'Вес';
      case GrowthMeasurementType.headCircumference:
        return 'Окружность головы';
      case GrowthMeasurementType.chestCircumference:
        return 'Окружность груди';
      case GrowthMeasurementType.armCircumference:
        return 'Окружность руки';
      case GrowthMeasurementType.waistCircumference:
        return 'Окружность талии';
      case GrowthMeasurementType.other:
        return 'Другое';
    }
  }

  String get formattedValue => '$value $unit';
}

// Область развития (перенесено в раздел раннего развития)

// Статус вехи развития
enum MilestoneStatus {
  notAchieved,   // Не достигнута
  inProgress,    // В процессе
  achieved,       // Достигнута
  delayed,        // Задержка
  advanced,       // Опережает норму
}

// Веха физического развития
class PhysicalMilestone {
  final String id;
  final String childId;
  final String title;
  final String description;
  final DevelopmentArea area;
  final int typicalAgeMonths; // Типичный возраст достижения в месяцах
  final int minAgeMonths;     // Минимальный возраст нормы
  final int maxAgeMonths;     // Максимальный возраст нормы
  final MilestoneStatus status;
  final DateTime? achievedDate;
  final String? observedBy;   // Кто наблюдал (родитель, врач)
  final String? notes;
  final List<String> photos;  // Фото/видео достижения
  final DateTime createdAt;
  final DateTime updatedAt;

  PhysicalMilestone({
    required this.id,
    required this.childId,
    required this.title,
    required this.description,
    required this.area,
    required this.typicalAgeMonths,
    required this.minAgeMonths,
    required this.maxAgeMonths,
    required this.status,
    this.achievedDate,
    this.observedBy,
    this.notes,
    required this.photos,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'childId': childId,
      'title': title,
      'description': description,
      'area': area.name,
      'typicalAgeMonths': typicalAgeMonths,
      'minAgeMonths': minAgeMonths,
      'maxAgeMonths': maxAgeMonths,
      'status': status.name,
      'achievedDate': achievedDate != null ? Timestamp.fromDate(achievedDate!) : null,
      'observedBy': observedBy,
      'notes': notes,
      'photos': photos,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static PhysicalMilestone fromJson(Map<String, dynamic> json) {
    return PhysicalMilestone(
      id: json['id'] ?? '',
      childId: json['childId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      area: DevelopmentArea.values.firstWhere(
        (e) => e.name == json['area'],
        orElse: () => DevelopmentArea.cognitive,
      ),
      typicalAgeMonths: json['typicalAgeMonths'] ?? 0,
      minAgeMonths: json['minAgeMonths'] ?? 0,
      maxAgeMonths: json['maxAgeMonths'] ?? 0,
      status: MilestoneStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MilestoneStatus.notAchieved,
      ),
      achievedDate: json['achievedDate'] != null 
          ? (json['achievedDate'] as Timestamp).toDate() 
          : null,
      observedBy: json['observedBy'],
      notes: json['notes'],
      photos: List<String>.from(json['photos'] ?? []),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Вспомогательные методы
  String get areaDisplayName {
    switch (area) {
      case DevelopmentArea.motor:
        return 'Моторное развитие';
      case DevelopmentArea.cognitive:
        return 'Познавательное развитие';
      case DevelopmentArea.language:
        return 'Речевое развитие';
      case DevelopmentArea.social:
        return 'Социальное развитие';
      case DevelopmentArea.creative:
        return 'Творческое развитие';
      case DevelopmentArea.sensory:
        return 'Сенсорное развитие';
      case DevelopmentArea.emotional:
        return 'Эмоциональное развитие';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case MilestoneStatus.notAchieved:
        return 'Не достигнута';
      case MilestoneStatus.inProgress:
        return 'В процессе';
      case MilestoneStatus.achieved:
        return 'Достигнута';
      case MilestoneStatus.delayed:
        return 'Задержка';
      case MilestoneStatus.advanced:
        return 'Опережает норму';
    }
  }

  bool get isOnTime {
    if (achievedDate == null) return true;
    
    final childAge = DateTime.now().difference(achievedDate!).inDays ~/ 30;
    return childAge >= minAgeMonths && childAge <= maxAgeMonths;
  }

  bool get isDelayed {
    // Проверяем от даты рождения ребенка (нужно получить из профиля)
    return status == MilestoneStatus.delayed;
  }

  bool get isAdvanced {
    return status == MilestoneStatus.advanced;
  }

  String get ageRangeText {
    if (minAgeMonths == maxAgeMonths) {
      return '$typicalAgeMonths мес.';
    }
    return '$minAgeMonths-$maxAgeMonths мес. (норма: $typicalAgeMonths мес.)';
  }
}

// Центильные данные ВОЗ
class WHOPercentileData {
  final int ageMonths;
  final String gender; // 'male' или 'female'
  final GrowthMeasurementType measurementType;
  final double p3;   // 3-й центиль
  final double p15;  // 15-й центиль
  final double p50;  // 50-й центиль (медиана)
  final double p85;  // 85-й центиль
  final double p97;  // 97-й центиль

  WHOPercentileData({
    required this.ageMonths,
    required this.gender,
    required this.measurementType,
    required this.p3,
    required this.p15,
    required this.p50,
    required this.p85,
    required this.p97,
  });

  // Определить в какой центиль попадает значение
  String getPercentileRange(double value) {
    if (value < p3) return 'Ниже 3-го центиля';
    if (value < p15) return '3-15 центиль';
    if (value < p50) return '15-50 центиль';
    if (value < p85) return '50-85 центиль';
    if (value < p97) return '85-97 центиль';
    return 'Выше 97-го центиля';
  }

  // Получить точный центиль (приблизительно)
  int getPercentile(double value) {
    if (value < p3) return 1;
    if (value < p15) return 9;  // среднее между 3 и 15
    if (value < p50) return 32; // среднее между 15 и 50
    if (value < p85) return 67; // среднее между 50 и 85
    if (value < p97) return 91; // среднее между 85 и 97
    return 99;
  }

  // Оценка значения
  String getAssessment(double value) {
    final percentile = getPercentile(value);
    
    if (percentile < 3) return 'Значительно ниже нормы';
    if (percentile < 15) return 'Ниже нормы';
    if (percentile >= 15 && percentile <= 85) return 'Норма';
    if (percentile > 85 && percentile <= 97) return 'Выше нормы';
    return 'Значительно выше нормы';
  }
}

// Анализ физического развития
class GrowthAnalysis {
  final String childId;
  final DateTime analysisDate;
  final int currentAgeMonths;
  final List<DetailedGrowthMeasurement> recentMeasurements;
  final Map<GrowthMeasurementType, double> currentPercentiles;
  final Map<GrowthMeasurementType, String> growthTrends; // 'increasing', 'stable', 'decreasing'
  final List<String> recommendations;
  final List<String> concerns;
  final double overallGrowthScore; // 0-100

  GrowthAnalysis({
    required this.childId,
    required this.analysisDate,
    required this.currentAgeMonths,
    required this.recentMeasurements,
    required this.currentPercentiles,
    required this.growthTrends,
    required this.recommendations,
    required this.concerns,
    required this.overallGrowthScore,
  });

  String get overallAssessment {
    if (overallGrowthScore >= 85) return 'Отличное развитие';
    if (overallGrowthScore >= 70) return 'Хорошее развитие';
    if (overallGrowthScore >= 50) return 'Нормальное развитие';
    if (overallGrowthScore >= 30) return 'Требует внимания';
    return 'Рекомендуется консультация врача';
  }

  bool get hasConcerns => concerns.isNotEmpty;
}

// ===== МОДЕЛИ ПИТАНИЯ =====

// Категория питания
enum FoodCategory {
  fruits,          // Фрукты
  vegetables,      // Овощи
  grains,          // Злаки и крупы
  protein,         // Белки (мясо, рыба, бобовые)
  dairy,           // Молочные продукты
  fats,            // Жиры и масла
  beverages,       // Напитки
  snacks,          // Перекусы
  babyFood,        // Детское питание
  supplements,     // Витамины и добавки
}

// Единица измерения
enum MeasurementUnit {
  grams,           // Граммы
  milliliters,     // Миллилитры
  pieces,          // Штуки
  cups,            // Чашки
  tablespoons,     // Столовые ложки
  teaspoons,       // Чайные ложки
}

// Продукт питания
class FoodItem {
  final String id;
  final String name;
  final String description;
  final FoodCategory category;
  final MeasurementUnit defaultUnit;
  
  // Пищевая ценность на 100г/100мл
  final double caloriesPer100g;
  final double proteinPer100g;     // Белки (г)
  final double fatsPer100g;        // Жиры (г)
  final double carbsPer100g;       // Углеводы (г)
  final double fiberPer100g;       // Клетчатка (г)
  final double sugarPer100g;       // Сахар (г)
  final double sodiumPer100g;      // Натрий (мг)
  
  // Витамины и минералы на 100г/100мл
  final double vitaminAPer100g;    // Витамин A (мкг)
  final double vitaminCPer100g;    // Витамин C (мг)
  final double vitaminDPer100g;    // Витамин D (мкг)
  final double calciumPer100g;     // Кальций (мг)
  final double ironPer100g;        // Железо (мг)
  
  // Метаданные
  final List<String> allergens;     // Список аллергенов
  final int minAgeMonths;          // Минимальный возраст для введения
  final bool isOrganic;            // Органический продукт
  final String? brand;             // Бренд (для готовых продуктов)
  final String? barcode;           // Штрихкод
  final DateTime createdAt;
  final DateTime updatedAt;

  FoodItem({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.defaultUnit,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.fatsPer100g,
    required this.carbsPer100g,
    required this.fiberPer100g,
    required this.sugarPer100g,
    required this.sodiumPer100g,
    required this.vitaminAPer100g,
    required this.vitaminCPer100g,
    required this.vitaminDPer100g,
    required this.calciumPer100g,
    required this.ironPer100g,
    required this.allergens,
    required this.minAgeMonths,
    required this.isOrganic,
    this.brand,
    this.barcode,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category.name,
      'defaultUnit': defaultUnit.name,
      'caloriesPer100g': caloriesPer100g,
      'proteinPer100g': proteinPer100g,
      'fatsPer100g': fatsPer100g,
      'carbsPer100g': carbsPer100g,
      'fiberPer100g': fiberPer100g,
      'sugarPer100g': sugarPer100g,
      'sodiumPer100g': sodiumPer100g,
      'vitaminAPer100g': vitaminAPer100g,
      'vitaminCPer100g': vitaminCPer100g,
      'vitaminDPer100g': vitaminDPer100g,
      'calciumPer100g': calciumPer100g,
      'ironPer100g': ironPer100g,
      'allergens': allergens,
      'minAgeMonths': minAgeMonths,
      'isOrganic': isOrganic,
      'brand': brand,
      'barcode': barcode,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static FoodItem fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: FoodCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => FoodCategory.fruits,
      ),
      defaultUnit: MeasurementUnit.values.firstWhere(
        (e) => e.name == json['defaultUnit'],
        orElse: () => MeasurementUnit.grams,
      ),
      caloriesPer100g: (json['caloriesPer100g'] ?? 0).toDouble(),
      proteinPer100g: (json['proteinPer100g'] ?? 0).toDouble(),
      fatsPer100g: (json['fatsPer100g'] ?? 0).toDouble(),
      carbsPer100g: (json['carbsPer100g'] ?? 0).toDouble(),
      fiberPer100g: (json['fiberPer100g'] ?? 0).toDouble(),
      sugarPer100g: (json['sugarPer100g'] ?? 0).toDouble(),
      sodiumPer100g: (json['sodiumPer100g'] ?? 0).toDouble(),
      vitaminAPer100g: (json['vitaminAPer100g'] ?? 0).toDouble(),
      vitaminCPer100g: (json['vitaminCPer100g'] ?? 0).toDouble(),
      vitaminDPer100g: (json['vitaminDPer100g'] ?? 0).toDouble(),
      calciumPer100g: (json['calciumPer100g'] ?? 0).toDouble(),
      ironPer100g: (json['ironPer100g'] ?? 0).toDouble(),
      allergens: List<String>.from(json['allergens'] ?? []),
      minAgeMonths: json['minAgeMonths'] ?? 0,
      isOrganic: json['isOrganic'] ?? false,
      brand: json['brand'],
      barcode: json['barcode'],
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Вспомогательные методы
  String get categoryDisplayName {
    switch (category) {
      case FoodCategory.fruits:
        return 'Фрукты';
      case FoodCategory.vegetables:
        return 'Овощи';
      case FoodCategory.grains:
        return 'Злаки и крупы';
      case FoodCategory.protein:
        return 'Белки';
      case FoodCategory.dairy:
        return 'Молочные продукты';
      case FoodCategory.fats:
        return 'Жиры и масла';
      case FoodCategory.beverages:
        return 'Напитки';
      case FoodCategory.snacks:
        return 'Перекусы';
      case FoodCategory.babyFood:
        return 'Детское питание';
      case FoodCategory.supplements:
        return 'Витамины и добавки';
    }
  }

  String get unitDisplayName {
    switch (defaultUnit) {
      case MeasurementUnit.grams:
        return 'г';
      case MeasurementUnit.milliliters:
        return 'мл';
      case MeasurementUnit.pieces:
        return 'шт';
      case MeasurementUnit.cups:
        return 'чашки';
      case MeasurementUnit.tablespoons:
        return 'ст.л.';
      case MeasurementUnit.teaspoons:
        return 'ч.л.';
    }
  }

  bool get hasAllergens => allergens.isNotEmpty;
  
  bool isAllowedForAge(int ageMonths) => ageMonths >= minAgeMonths;
}

// Время приема пищи
enum MealType {
  breakfast,    // Завтрак
  morningSnack, // Утренний перекус
  lunch,        // Обед
  afternoonSnack, // Полдник
  dinner,       // Ужин
  eveningSnack, // Вечерний перекус
  nightFeeding, // Ночное кормление
}

// Запись о приеме пищи
class NutritionEntry {
  final String id;
  final String childId;
  final String foodItemId;
  final String foodName;        // Дубликат для удобства
  final MealType mealType;
  final double amount;          // Количество съеденного
  final MeasurementUnit unit;   // Единица измерения
  final DateTime mealTime;
  final String? notes;          // Заметки (реакция, настроение)
  final List<String> photos;    // Фото еды
  final bool wasFinished;       // Съел ли полностью
  final int appetite;           // Аппетит 1-5
  final DateTime createdAt;
  final DateTime updatedAt;

  NutritionEntry({
    required this.id,
    required this.childId,
    required this.foodItemId,
    required this.foodName,
    required this.mealType,
    required this.amount,
    required this.unit,
    required this.mealTime,
    this.notes,
    required this.photos,
    required this.wasFinished,
    required this.appetite,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'childId': childId,
      'foodItemId': foodItemId,
      'foodName': foodName,
      'mealType': mealType.name,
      'amount': amount,
      'unit': unit.name,
      'mealTime': Timestamp.fromDate(mealTime),
      'notes': notes,
      'photos': photos,
      'wasFinished': wasFinished,
      'appetite': appetite,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static NutritionEntry fromJson(Map<String, dynamic> json) {
    return NutritionEntry(
      id: json['id'] ?? '',
      childId: json['childId'] ?? '',
      foodItemId: json['foodItemId'] ?? '',
      foodName: json['foodName'] ?? '',
      mealType: MealType.values.firstWhere(
        (e) => e.name == json['mealType'],
        orElse: () => MealType.breakfast,
      ),
      amount: (json['amount'] ?? 0).toDouble(),
      unit: MeasurementUnit.values.firstWhere(
        (e) => e.name == json['unit'],
        orElse: () => MeasurementUnit.grams,
      ),
      mealTime: (json['mealTime'] as Timestamp).toDate(),
      notes: json['notes'],
      photos: List<String>.from(json['photos'] ?? []),
      wasFinished: json['wasFinished'] ?? false,
      appetite: json['appetite'] ?? 3,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Вспомогательные методы
  String get mealTypeDisplayName {
    switch (mealType) {
      case MealType.breakfast:
        return 'Завтрак';
      case MealType.morningSnack:
        return 'Утренний перекус';
      case MealType.lunch:
        return 'Обед';
      case MealType.afternoonSnack:
        return 'Полдник';
      case MealType.dinner:
        return 'Ужин';
      case MealType.eveningSnack:
        return 'Вечерний перекус';
      case MealType.nightFeeding:
        return 'Ночное кормление';
    }
  }

  String get appetiteDescription {
    switch (appetite) {
      case 1:
        return 'Отказался';
      case 2:
        return 'Плохой аппетит';
      case 3:
        return 'Нормальный';
      case 4:
        return 'Хороший аппетит';
      case 5:
        return 'Отличный аппетит';
      default:
        return 'Нормальный';
    }
  }
}

// Ингредиент рецепта
class RecipeIngredient {
  final String foodItemId;
  final String foodName;
  final double amount;
  final MeasurementUnit unit;
  final bool isOptional;
  final String? notes;

  RecipeIngredient({
    required this.foodItemId,
    required this.foodName,
    required this.amount,
    required this.unit,
    required this.isOptional,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'foodItemId': foodItemId,
      'foodName': foodName,
      'amount': amount,
      'unit': unit.name,
      'isOptional': isOptional,
      'notes': notes,
    };
  }

  static RecipeIngredient fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      foodItemId: json['foodItemId'] ?? '',
      foodName: json['foodName'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      unit: MeasurementUnit.values.firstWhere(
        (e) => e.name == json['unit'],
        orElse: () => MeasurementUnit.grams,
      ),
      isOptional: json['isOptional'] ?? false,
      notes: json['notes'],
    );
  }
}

// Сложность рецепта
enum RecipeDifficulty {
  veryEasy,   // Очень просто
  easy,       // Просто
  medium,     // Средне
  hard,       // Сложно
  veryHard,   // Очень сложно
}

// Рецепт
class Recipe {
  final String id;
  final String name;
  final String description;
  final List<RecipeIngredient> ingredients;
  final List<String> instructions;    // Пошаговые инструкции
  final int prepTimeMinutes;         // Время приготовления
  final int cookTimeMinutes;         // Время готовки
  final int servings;               // Количество порций
  final RecipeDifficulty difficulty;
  final int minAgeMonths;           // Минимальный возраст
  final List<String> tags;          // Теги (здоровое, быстрое, без глютена и т.д.)
  final List<String> allergens;     // Аллергены в рецепте
  final List<String> photos;        // Фото готового блюда
  final double rating;              // Средний рейтинг
  final int ratingsCount;           // Количество оценок
  final String authorId;            // Автор рецепта
  final bool isPremium;             // Премиум рецепт
  final DateTime createdAt;
  final DateTime updatedAt;

  Recipe({
    required this.id,
    required this.name,
    required this.description,
    required this.ingredients,
    required this.instructions,
    required this.prepTimeMinutes,
    required this.cookTimeMinutes,
    required this.servings,
    required this.difficulty,
    required this.minAgeMonths,
    required this.tags,
    required this.allergens,
    required this.photos,
    required this.rating,
    required this.ratingsCount,
    required this.authorId,
    required this.isPremium,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'ingredients': ingredients.map((i) => i.toJson()).toList(),
      'instructions': instructions,
      'prepTimeMinutes': prepTimeMinutes,
      'cookTimeMinutes': cookTimeMinutes,
      'servings': servings,
      'difficulty': difficulty.name,
      'minAgeMonths': minAgeMonths,
      'tags': tags,
      'allergens': allergens,
      'photos': photos,
      'rating': rating,
      'ratingsCount': ratingsCount,
      'authorId': authorId,
      'isPremium': isPremium,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static Recipe fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      ingredients: (json['ingredients'] as List<dynamic>? ?? [])
          .map((i) => RecipeIngredient.fromJson(i))
          .toList(),
      instructions: List<String>.from(json['instructions'] ?? []),
      prepTimeMinutes: json['prepTimeMinutes'] ?? 0,
      cookTimeMinutes: json['cookTimeMinutes'] ?? 0,
      servings: json['servings'] ?? 1,
      difficulty: RecipeDifficulty.values.firstWhere(
        (e) => e.name == json['difficulty'],
        orElse: () => RecipeDifficulty.easy,
      ),
      minAgeMonths: json['minAgeMonths'] ?? 0,
      tags: List<String>.from(json['tags'] ?? []),
      allergens: List<String>.from(json['allergens'] ?? []),
      photos: List<String>.from(json['photos'] ?? []),
      rating: (json['rating'] ?? 0).toDouble(),
      ratingsCount: json['ratingsCount'] ?? 0,
      authorId: json['authorId'] ?? '',
      isPremium: json['isPremium'] ?? false,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Вспомогательные методы
  String get difficultyDisplayName {
    switch (difficulty) {
      case RecipeDifficulty.veryEasy:
        return 'Очень просто';
      case RecipeDifficulty.easy:
        return 'Просто';
      case RecipeDifficulty.medium:
        return 'Средне';
      case RecipeDifficulty.hard:
        return 'Сложно';
      case RecipeDifficulty.veryHard:
        return 'Очень сложно';
    }
  }

  int get totalTimeMinutes => prepTimeMinutes + cookTimeMinutes;
  
  bool get hasAllergens => allergens.isNotEmpty;
  
  bool isAllowedForAge(int ageMonths) => ageMonths >= minAgeMonths;
  
  String get formattedRating => rating.toStringAsFixed(1);
}

// Тип аллергической реакции
enum AllergyReactionType {
  mild,        // Легкая
  moderate,    // Средняя
  severe,      // Тяжелая
  anaphylaxis; // Анафилаксия
  
  String get displayName {
    switch (this) {
      case AllergyReactionType.mild:
        return 'Легкая реакция';
      case AllergyReactionType.moderate:
        return 'Умеренная реакция';
      case AllergyReactionType.severe:
        return 'Тяжелая реакция';
      case AllergyReactionType.anaphylaxis:
        return 'Анафилаксия';
    }
  }
}

// Информация об аллергии
class AllergyInfo {
  final String id;
  final String childId;
  final String allergen;                    // Название аллергена
  final AllergyReactionType reactionType;   // Тип реакции
  final List<String> symptoms;             // Симптомы
  final DateTime firstReactionDate;        // Дата первой реакции
  final DateTime? lastReactionDate;        // Дата последней реакции
  final bool isConfirmedByDoctor;         // Подтверждено врачом
  final String? doctorNotes;              // Заметки врача
  final List<String> avoidFoods;          // Продукты, которых следует избегать
  final String? emergencyMedication;      // Лекарства для экстренной помощи
  final bool isActive;                    // Активная аллергия
  final DateTime createdAt;
  final DateTime updatedAt;

  AllergyInfo({
    required this.id,
    required this.childId,
    required this.allergen,
    required this.reactionType,
    required this.symptoms,
    required this.firstReactionDate,
    this.lastReactionDate,
    required this.isConfirmedByDoctor,
    this.doctorNotes,
    required this.avoidFoods,
    this.emergencyMedication,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'childId': childId,
      'allergen': allergen,
      'reactionType': reactionType.name,
      'symptoms': symptoms,
      'firstReactionDate': Timestamp.fromDate(firstReactionDate),
      'lastReactionDate': lastReactionDate != null 
          ? Timestamp.fromDate(lastReactionDate!) 
          : null,
      'isConfirmedByDoctor': isConfirmedByDoctor,
      'doctorNotes': doctorNotes,
      'avoidFoods': avoidFoods,
      'emergencyMedication': emergencyMedication,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static AllergyInfo fromJson(Map<String, dynamic> json) {
    return AllergyInfo(
      id: json['id'] ?? '',
      childId: json['childId'] ?? '',
      allergen: json['allergen'] ?? '',
      reactionType: AllergyReactionType.values.firstWhere(
        (e) => e.name == json['reactionType'],
        orElse: () => AllergyReactionType.mild,
      ),
      symptoms: List<String>.from(json['symptoms'] ?? []),
      firstReactionDate: (json['firstReactionDate'] as Timestamp).toDate(),
      lastReactionDate: json['lastReactionDate'] != null
          ? (json['lastReactionDate'] as Timestamp).toDate()
          : null,
      isConfirmedByDoctor: json['isConfirmedByDoctor'] ?? false,
      doctorNotes: json['doctorNotes'],
      avoidFoods: List<String>.from(json['avoidFoods'] ?? []),
      emergencyMedication: json['emergencyMedication'],
      isActive: json['isActive'] ?? true,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Вспомогательные методы
  String get reactionTypeDisplayName {
    switch (reactionType) {
      case AllergyReactionType.mild:
        return 'Легкая';
      case AllergyReactionType.moderate:
        return 'Средняя';
      case AllergyReactionType.severe:
        return 'Тяжелая';
      case AllergyReactionType.anaphylaxis:
        return 'Анафилаксия';
    }
  }

  int get reactionTypeColorHex {
    switch (reactionType) {
      case AllergyReactionType.mild:
        return 0xFFFFEB3B; // yellow
      case AllergyReactionType.moderate:
        return 0xFFFF9800; // orange
      case AllergyReactionType.severe:
        return 0xFFF44336; // red
      case AllergyReactionType.anaphylaxis:
        return 0xFFB71C1C; // dark red
    }
  }

  bool get isEmergency => 
      reactionType == AllergyReactionType.severe ||
      reactionType == AllergyReactionType.anaphylaxis;
}

// Цели питания
class NutritionGoals {
  final String id;
  final String childId;
  final int ageMonths;              // Возраст ребенка
  final double targetCalories;      // Целевые калории в день
  final double targetProtein;       // Целевой белок (г)
  final double targetFats;          // Целевые жиры (г)
  final double targetCarbs;         // Целевые углеводы (г)
  final double targetFiber;         // Целевая клетчатка (г)
  final double targetVitaminA;      // Целевой витамин A (мкг)
  final double targetVitaminC;      // Целевой витамин C (мг)
  final double targetVitaminD;      // Целевой витамин D (мкг)
  final double targetCalcium;       // Целевой кальций (мг)
  final double targetIron;          // Целевое железо (мг)
  final double targetWater;         // Целевая вода (мл)
  final bool isCustom;              // Пользовательские или стандартные цели
  final DateTime validFrom;         // Действует с
  final DateTime? validUntil;       // Действует до
  final DateTime createdAt;
  final DateTime updatedAt;

  NutritionGoals({
    required this.id,
    required this.childId,
    required this.ageMonths,
    required this.targetCalories,
    required this.targetProtein,
    required this.targetFats,
    required this.targetCarbs,
    required this.targetFiber,
    required this.targetVitaminA,
    required this.targetVitaminC,
    required this.targetVitaminD,
    required this.targetCalcium,
    required this.targetIron,
    required this.targetWater,
    required this.isCustom,
    required this.validFrom,
    this.validUntil,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'childId': childId,
      'ageMonths': ageMonths,
      'targetCalories': targetCalories,
      'targetProtein': targetProtein,
      'targetFats': targetFats,
      'targetCarbs': targetCarbs,
      'targetFiber': targetFiber,
      'targetVitaminA': targetVitaminA,
      'targetVitaminC': targetVitaminC,
      'targetVitaminD': targetVitaminD,
      'targetCalcium': targetCalcium,
      'targetIron': targetIron,
      'targetWater': targetWater,
      'isCustom': isCustom,
      'validFrom': Timestamp.fromDate(validFrom),
      'validUntil': validUntil != null ? Timestamp.fromDate(validUntil!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static NutritionGoals fromJson(Map<String, dynamic> json) {
    return NutritionGoals(
      id: json['id'] ?? '',
      childId: json['childId'] ?? '',
      ageMonths: json['ageMonths'] ?? 0,
      targetCalories: (json['targetCalories'] ?? 0).toDouble(),
      targetProtein: (json['targetProtein'] ?? 0).toDouble(),
      targetFats: (json['targetFats'] ?? 0).toDouble(),
      targetCarbs: (json['targetCarbs'] ?? 0).toDouble(),
      targetFiber: (json['targetFiber'] ?? 0).toDouble(),
      targetVitaminA: (json['targetVitaminA'] ?? 0).toDouble(),
      targetVitaminC: (json['targetVitaminC'] ?? 0).toDouble(),
      targetVitaminD: (json['targetVitaminD'] ?? 0).toDouble(),
      targetCalcium: (json['targetCalcium'] ?? 0).toDouble(),
      targetIron: (json['targetIron'] ?? 0).toDouble(),
      targetWater: (json['targetWater'] ?? 0).toDouble(),
      isCustom: json['isCustom'] ?? false,
      validFrom: (json['validFrom'] as Timestamp).toDate(),
      validUntil: json['validUntil'] != null 
          ? (json['validUntil'] as Timestamp).toDate() 
          : null,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Создать стандартные цели по возрасту (на основе рекомендаций ВОЗ)
  static NutritionGoals createStandardGoals(String childId, int ageMonths) {
    final now = DateTime.now();
    
    // Стандартные рекомендации по возрасту
    double calories, protein, fats, carbs, fiber, vitA, vitC, vitD, calcium, iron, water;
    
    if (ageMonths < 6) {
      // 0-6 месяцев (в основном грудное молоко/смесь)
      calories = 600;
      protein = 9;
      fats = 31;
      carbs = 65;
      fiber = 0;
      vitA = 400;
      vitC = 40;
      vitD = 10;
      calcium = 200;
      iron = 0.27;
      water = 700;
    } else if (ageMonths < 12) {
      // 6-12 месяцев (введение прикорма)
      calories = 700;
      protein = 11;
      fats = 30;
      carbs = 95;
      fiber = 5;
      vitA = 500;
      vitC = 50;
      vitD = 10;
      calcium = 260;
      iron = 11;
      water = 800;
    } else if (ageMonths < 24) {
      // 1-2 года
      calories = 1000;
      protein = 13;
      fats = 30;
      carbs = 130;
      fiber = 19;
      vitA = 300;
      vitC = 15;
      vitD = 15;
      calcium = 700;
      iron = 7;
      water = 1300;
    } else if (ageMonths < 36) {
      // 2-3 года
      calories = 1200;
      protein = 16;
      fats = 35;
      carbs = 130;
      fiber = 25;
      vitA = 400;
      vitC = 25;
      vitD = 15;
      calcium = 1000;
      iron = 10;
      water = 1300;
    } else {
      // 3+ года
      calories = 1400;
      protein = 20;
      fats = 40;
      carbs = 130;
      fiber = 30;
      vitA = 500;
      vitC = 30;
      vitD = 15;
      calcium = 1000;
      iron = 10;
      water = 1700;
    }

    return NutritionGoals(
      id: '',
      childId: childId,
      ageMonths: ageMonths,
      targetCalories: calories,
      targetProtein: protein,
      targetFats: fats,
      targetCarbs: carbs,
      targetFiber: fiber,
      targetVitaminA: vitA,
      targetVitaminC: vitC,
      targetVitaminD: vitD,
      targetCalcium: calcium,
      targetIron: iron,
      targetWater: water,
      isCustom: false,
      validFrom: now,
      validUntil: null,
      createdAt: now,
      updatedAt: now,
    );
  }
}

// ===== ДНЕВНОЙ АНАЛИЗ ПИТАНИЯ =====
class DailyNutritionAnalysis {
  final String id;
  final String childId;
  final DateTime analysisDate;
  final List<NutritionEntry> nutritionEntries;
  final NutritionGoals goals;
  
  // Фактическое потребление
  final double actualCalories;
  final double actualProtein;
  final double actualFats;
  final double actualCarbs;
  final double actualFiber;
  final double actualVitaminA;
  final double actualVitaminC;
  final double actualVitaminD;
  final double actualCalcium;
  final double actualIron;
  final double actualWater;
  
  // Процент выполнения целей
  final Map<String, double> goalCompletion;
  
  // Качественная оценка
  final double overallScore;        // 0-100
  final List<String> achievements;  // Что хорошо
  final List<String> concerns;      // Что нужно улучшить
  final List<String> recommendations; // Рекомендации
  
  // Статистика приемов пищи
  final int totalMeals;
  final double averageAppetite;
  final int mealsFinished;
  final Map<MealType, int> mealDistribution;
  
  final DateTime createdAt;

  DailyNutritionAnalysis({
    required this.id,
    required this.childId,
    required this.analysisDate,
    required this.nutritionEntries,
    required this.goals,
    required this.actualCalories,
    required this.actualProtein,
    required this.actualFats,
    required this.actualCarbs,
    required this.actualFiber,
    required this.actualVitaminA,
    required this.actualVitaminC,
    required this.actualVitaminD,
    required this.actualCalcium,
    required this.actualIron,
    required this.actualWater,
    required this.goalCompletion,
    required this.overallScore,
    required this.achievements,
    required this.concerns,
    required this.recommendations,
    required this.totalMeals,
    required this.averageAppetite,
    required this.mealsFinished,
    required this.mealDistribution,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'childId': childId,
      'analysisDate': Timestamp.fromDate(analysisDate),
      'actualCalories': actualCalories,
      'actualProtein': actualProtein,
      'actualFats': actualFats,
      'actualCarbs': actualCarbs,
      'actualFiber': actualFiber,
      'actualVitaminA': actualVitaminA,
      'actualVitaminC': actualVitaminC,
      'actualVitaminD': actualVitaminD,
      'actualCalcium': actualCalcium,
      'actualIron': actualIron,
      'actualWater': actualWater,
      'goalCompletion': goalCompletion,
      'overallScore': overallScore,
      'achievements': achievements,
      'concerns': concerns,
      'recommendations': recommendations,
      'totalMeals': totalMeals,
      'averageAppetite': averageAppetite,
      'mealsFinished': mealsFinished,
      'mealDistribution': mealDistribution.map((k, v) => MapEntry(k.name, v)),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static DailyNutritionAnalysis fromJson(Map<String, dynamic> json, {
    required List<NutritionEntry> nutritionEntries,
    required NutritionGoals goals,
  }) {
    return DailyNutritionAnalysis(
      id: json['id'] ?? '',
      childId: json['childId'] ?? '',
      analysisDate: (json['analysisDate'] as Timestamp).toDate(),
      nutritionEntries: nutritionEntries,
      goals: goals,
      actualCalories: (json['actualCalories'] ?? 0).toDouble(),
      actualProtein: (json['actualProtein'] ?? 0).toDouble(),
      actualFats: (json['actualFats'] ?? 0).toDouble(),
      actualCarbs: (json['actualCarbs'] ?? 0).toDouble(),
      actualFiber: (json['actualFiber'] ?? 0).toDouble(),
      actualVitaminA: (json['actualVitaminA'] ?? 0).toDouble(),
      actualVitaminC: (json['actualVitaminC'] ?? 0).toDouble(),
      actualVitaminD: (json['actualVitaminD'] ?? 0).toDouble(),
      actualCalcium: (json['actualCalcium'] ?? 0).toDouble(),
      actualIron: (json['actualIron'] ?? 0).toDouble(),
      actualWater: (json['actualWater'] ?? 0).toDouble(),
      goalCompletion: Map<String, double>.from(json['goalCompletion'] ?? {}),
      overallScore: (json['overallScore'] ?? 0).toDouble(),
      achievements: List<String>.from(json['achievements'] ?? []),
      concerns: List<String>.from(json['concerns'] ?? []),
      recommendations: List<String>.from(json['recommendations'] ?? []),
      totalMeals: json['totalMeals'] ?? 0,
      averageAppetite: (json['averageAppetite'] ?? 0).toDouble(),
      mealsFinished: json['mealsFinished'] ?? 0,
      mealDistribution: (json['mealDistribution'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(
                MealType.values.firstWhere(
                  (e) => e.name == k,
                  orElse: () => MealType.breakfast,
                ),
                v as int,
              )),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  // Вспомогательные методы
  String get overallAssessment {
    if (overallScore >= 90) return 'Отличное питание';
    if (overallScore >= 80) return 'Хорошее питание';
    if (overallScore >= 70) return 'Нормальное питание';
    if (overallScore >= 60) return 'Требует улучшения';
    return 'Необходима коррекция питания';
  }

  double get calorieCompletion => goalCompletion['calories'] ?? 0;
  double get proteinCompletion => goalCompletion['protein'] ?? 0;
  double get vitaminCCompletion => goalCompletion['vitaminC'] ?? 0;
  
  bool get hasDeficiencies => concerns.isNotEmpty;
  bool get hasAchievements => achievements.isNotEmpty;
  
  double get finishedMealsPercentage => 
      totalMeals > 0 ? (mealsFinished / totalMeals) * 100 : 0;
}

// ===== МОДЕЛИ ДАННЫХ СНА =====

// Тип события сна
enum SleepEventType {
  bedtime,        // Время укладывания
  fallAsleep,     // Засыпание
  nightWaking,    // Ночное пробуждение
  morningWakeup,  // Утреннее пробуждение
  nap,           // Дневной сон
}

// Качество сна
enum SleepQuality {
  excellent,  // Отличное
  good,       // Хорошее  
  fair,       // Удовлетворительное
  poor,       // Плохое
  terrible;   // Ужасное
  
  String get displayName {
    switch (this) {
      case SleepQuality.excellent:
        return 'Отличное';
      case SleepQuality.good:
        return 'Хорошее';
      case SleepQuality.fair:
        return 'Удовлетворительное';
      case SleepQuality.poor:
        return 'Плохое';
      case SleepQuality.terrible:
        return 'Ужасное';
    }
  }
  
  int get scoreValue {
    switch (this) {
      case SleepQuality.excellent:
        return 5;
      case SleepQuality.good:
        return 4;
      case SleepQuality.fair:
        return 3;
      case SleepQuality.poor:
        return 2;
      case SleepQuality.terrible:
        return 1;
    }
  }
  
  int get colorHex {
    switch (this) {
      case SleepQuality.excellent:
        return 0xFF4CAF50; // green
      case SleepQuality.good:
        return 0xFF8BC34A; // light green
      case SleepQuality.fair:
        return 0xFFFFC107; // amber
      case SleepQuality.poor:
        return 0xFFFF9800; // orange
      case SleepQuality.terrible:
        return 0xFFF44336; // red
    }
  }
}

// Запись о сне
class SleepEntry {
  final String id;
  final String childId;
  final DateTime date;               // Дата сна
  final DateTime? bedtime;           // Время укладывания
  final DateTime? fallAsleepTime;    // Время засыпания
  final DateTime? wakeupTime;        // Время пробуждения
  final Duration? totalSleepTime;    // Общее время сна
  final Duration? timeToFallAsleep;  // Время засыпания (от укладывания)
  final List<SleepInterruption> interruptions; // Ночные пробуждения
  final List<Nap> naps;             // Дневные сны
  final SleepQuality quality;        // Качество сна
  final String? notes;               // Заметки
  final Map<String, dynamic> factors; // Факторы влияния (еда, болезнь, зубы и т.д.)
  final DateTime createdAt;
  final DateTime updatedAt;

  SleepEntry({
    required this.id,
    required this.childId,
    required this.date,
    this.bedtime,
    this.fallAsleepTime,
    this.wakeupTime,
    this.totalSleepTime,
    this.timeToFallAsleep,
    required this.interruptions,
    required this.naps,
    required this.quality,
    this.notes,
    required this.factors,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'childId': childId,
      'date': Timestamp.fromDate(date),
      'bedtime': bedtime != null ? Timestamp.fromDate(bedtime!) : null,
      'fallAsleepTime': fallAsleepTime != null ? Timestamp.fromDate(fallAsleepTime!) : null,
      'wakeupTime': wakeupTime != null ? Timestamp.fromDate(wakeupTime!) : null,
      'totalSleepTime': totalSleepTime?.inMinutes,
      'timeToFallAsleep': timeToFallAsleep?.inMinutes,
      'interruptions': interruptions.map((i) => i.toJson()).toList(),
      'naps': naps.map((n) => n.toJson()).toList(),
      'quality': quality.name,
      'notes': notes,
      'factors': factors,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static SleepEntry fromJson(Map<String, dynamic> json) {
    return SleepEntry(
      id: json['id'] ?? '',
      childId: json['childId'] ?? '',
      date: (json['date'] as Timestamp).toDate(),
      bedtime: json['bedtime'] != null ? (json['bedtime'] as Timestamp).toDate() : null,
      fallAsleepTime: json['fallAsleepTime'] != null ? (json['fallAsleepTime'] as Timestamp).toDate() : null,
      wakeupTime: json['wakeupTime'] != null ? (json['wakeupTime'] as Timestamp).toDate() : null,
      totalSleepTime: json['totalSleepTime'] != null ? Duration(minutes: json['totalSleepTime']) : null,
      timeToFallAsleep: json['timeToFallAsleep'] != null ? Duration(minutes: json['timeToFallAsleep']) : null,
      interruptions: (json['interruptions'] as List? ?? [])
          .map((i) => SleepInterruption.fromJson(i))
          .toList(),
      naps: (json['naps'] as List? ?? [])
          .map((n) => Nap.fromJson(n))
          .toList(),
      quality: SleepQuality.values.firstWhere(
        (q) => q.name == json['quality'],
        orElse: () => SleepQuality.fair,
      ),
      notes: json['notes'],
      factors: Map<String, dynamic>.from(json['factors'] ?? {}),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Вспомогательные методы
  Duration get actualSleepTime {
    if (totalSleepTime != null) return totalSleepTime!;
    
    if (fallAsleepTime != null && wakeupTime != null) {
      final grossSleep = wakeupTime!.difference(fallAsleepTime!);
      final interruptionTime = interruptions.fold<Duration>(
        Duration.zero,
        (sum, interruption) => sum + interruption.duration,
      );
      return grossSleep - interruptionTime;
    }
    
    return Duration.zero;
  }

  Duration get totalNapTime {
    return naps.fold<Duration>(
      Duration.zero,
      (sum, nap) => sum + nap.duration,
    );
  }

  Duration get totalDailySleep => actualSleepTime + totalNapTime;

  int get nightWakings => interruptions.length;

  bool get isCompleteEntry {
    return bedtime != null && 
           fallAsleepTime != null && 
           wakeupTime != null;
  }

  String get formattedSleepTime {
    final sleep = actualSleepTime;
    final hours = sleep.inHours;
    final minutes = sleep.inMinutes.remainder(60);
    return '${hours}ч ${minutes}м';
  }

  String get bedtimeString {
    if (bedtime == null) return 'Не указано';
    return '${bedtime!.hour.toString().padLeft(2, '0')}:${bedtime!.minute.toString().padLeft(2, '0')}';
  }

  String get wakeupString {
    if (wakeupTime == null) return 'Не указано';
    return '${wakeupTime!.hour.toString().padLeft(2, '0')}:${wakeupTime!.minute.toString().padLeft(2, '0')}';
  }
}

// Ночное пробуждение
class SleepInterruption {
  final DateTime startTime;
  final DateTime? endTime;
  final String? reason;        // Причина пробуждения
  final String? intervention;  // Что делали для успокоения

  SleepInterruption({
    required this.startTime,
    this.endTime,
    this.reason,
    this.intervention,
  });

  Duration get duration {
    if (endTime == null) return Duration.zero;
    return endTime!.difference(startTime);
  }

  Map<String, dynamic> toJson() {
    return {
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'reason': reason,
      'intervention': intervention,
    };
  }

  static SleepInterruption fromJson(Map<String, dynamic> json) {
    return SleepInterruption(
      startTime: (json['startTime'] as Timestamp).toDate(),
      endTime: json['endTime'] != null ? (json['endTime'] as Timestamp).toDate() : null,
      reason: json['reason'],
      intervention: json['intervention'],
    );
  }
}

// Дневной сон
class Nap {
  final DateTime startTime;
  final DateTime? endTime;
  final String? location;  // Где спал (кроватка, коляска, на руках)
  final SleepQuality quality;

  Nap({
    required this.startTime,
    this.endTime,
    this.location,
    required this.quality,
  });

  Duration get duration {
    if (endTime == null) return Duration.zero;
    return endTime!.difference(startTime);
  }

  String get formattedDuration {
    final d = duration;
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}ч ${minutes}м';
    } else {
      return '${minutes}м';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'location': location,
      'quality': quality.name,
    };
  }

  static Nap fromJson(Map<String, dynamic> json) {
    return Nap(
      startTime: (json['startTime'] as Timestamp).toDate(),
      endTime: json['endTime'] != null ? (json['endTime'] as Timestamp).toDate() : null,
      location: json['location'],
      quality: SleepQuality.values.firstWhere(
        (q) => q.name == json['quality'],
        orElse: () => SleepQuality.fair,
      ),
    );
  }
}

// Анализ сна за период
class SleepAnalysis {
  final String id;
  final String childId;
  final DateTime startDate;
  final DateTime endDate;
  final List<SleepEntry> sleepEntries;
  
  // Основная статистика
  final Duration averageNightSleep;
  final Duration averageDaytimeSleep;
  final Duration averageTotalSleep;
  final double averageBedtime;        // В минутах от полуночи
  final double averageWakeupTime;     // В минутах от полуночи
  final double averageTimeToFallAsleep; // В минутах
  final double averageNightWakings;
  final double averageSleepQuality;   // 1-5
  
  // Тренды
  final SleepTrend sleepTimeTrend;
  final SleepTrend qualityTrend;
  final SleepTrend bedtimeTrend;
  
  // Паттерны
  final Map<String, dynamic> sleepPatterns;
  final List<String> insights;        // Ключевые выводы
  final List<String> recommendations; // Рекомендации
  final Map<String, int> commonFactors; // Частые факторы влияния
  
  final DateTime createdAt;

  SleepAnalysis({
    required this.id,
    required this.childId,
    required this.startDate,
    required this.endDate,
    required this.sleepEntries,
    required this.averageNightSleep,
    required this.averageDaytimeSleep,
    required this.averageTotalSleep,
    required this.averageBedtime,
    required this.averageWakeupTime,
    required this.averageTimeToFallAsleep,
    required this.averageNightWakings,
    required this.averageSleepQuality,
    required this.sleepTimeTrend,
    required this.qualityTrend,
    required this.bedtimeTrend,
    required this.sleepPatterns,
    required this.insights,
    required this.recommendations,
    required this.commonFactors,
    required this.createdAt,
  });

  // Статистические методы
  String get averageBedtimeString {
    final minutes = averageBedtime.toInt();
    final hour = (minutes ~/ 60) % 24;
    final minute = minutes % 60;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  String get averageWakeupTimeString {
    final minutes = averageWakeupTime.toInt();
    final hour = (minutes ~/ 60) % 24;
    final minute = minutes % 60;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  String get formattedNightSleep {
    final hours = averageNightSleep.inHours;
    final minutes = averageNightSleep.inMinutes.remainder(60);
    return '${hours}ч ${minutes}м';
  }

  String get formattedTotalSleep {
    final hours = averageTotalSleep.inHours;
    final minutes = averageTotalSleep.inMinutes.remainder(60);
    return '${hours}ч ${minutes}м';
  }

  String get qualityAssessment {
    if (averageSleepQuality >= 4.5) return 'Отличное качество сна';
    if (averageSleepQuality >= 3.5) return 'Хорошее качество сна';
    if (averageSleepQuality >= 2.5) return 'Удовлетворительное качество';
    if (averageSleepQuality >= 1.5) return 'Плохое качество сна';
    return 'Очень плохое качество сна';
  }

  bool get hasGoodSleepHygiene {
    // Хорошая гигиена сна включает:
    // 1. Регулярное время укладывания (разброс < 30 мин)
    // 2. Достаточная продолжительность сна
    // 3. Быстрое засыпание (< 20 мин)
    // 4. Мало ночных пробуждений (< 2)
    
    return averageTimeToFallAsleep < 20 && 
           averageNightWakings < 2 &&
           averageSleepQuality >= 3.5;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'childId': childId,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'averageNightSleep': averageNightSleep.inMinutes,
      'averageDaytimeSleep': averageDaytimeSleep.inMinutes,
      'averageTotalSleep': averageTotalSleep.inMinutes,
      'averageBedtime': averageBedtime,
      'averageWakeupTime': averageWakeupTime,
      'averageTimeToFallAsleep': averageTimeToFallAsleep,
      'averageNightWakings': averageNightWakings,
      'averageSleepQuality': averageSleepQuality,
      'sleepTimeTrend': sleepTimeTrend.name,
      'qualityTrend': qualityTrend.name,
      'bedtimeTrend': bedtimeTrend.name,
      'sleepPatterns': sleepPatterns,
      'insights': insights,
      'recommendations': recommendations,
      'commonFactors': commonFactors,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static SleepAnalysis fromJson(Map<String, dynamic> json, List<SleepEntry> sleepEntries) {
    return SleepAnalysis(
      id: json['id'] ?? '',
      childId: json['childId'] ?? '',
      startDate: (json['startDate'] as Timestamp).toDate(),
      endDate: (json['endDate'] as Timestamp).toDate(),
      sleepEntries: sleepEntries,
      averageNightSleep: Duration(minutes: json['averageNightSleep'] ?? 0),
      averageDaytimeSleep: Duration(minutes: json['averageDaytimeSleep'] ?? 0),
      averageTotalSleep: Duration(minutes: json['averageTotalSleep'] ?? 0),
      averageBedtime: (json['averageBedtime'] ?? 0).toDouble(),
      averageWakeupTime: (json['averageWakeupTime'] ?? 0).toDouble(),
      averageTimeToFallAsleep: (json['averageTimeToFallAsleep'] ?? 0).toDouble(),
      averageNightWakings: (json['averageNightWakings'] ?? 0).toDouble(),
      averageSleepQuality: (json['averageSleepQuality'] ?? 0).toDouble(),
      sleepTimeTrend: SleepTrend.values.firstWhere(
        (t) => t.name == json['sleepTimeTrend'],
        orElse: () => SleepTrend.stable,
      ),
      qualityTrend: SleepTrend.values.firstWhere(
        (t) => t.name == json['qualityTrend'],
        orElse: () => SleepTrend.stable,
      ),
      bedtimeTrend: SleepTrend.values.firstWhere(
        (t) => t.name == json['bedtimeTrend'],
        orElse: () => SleepTrend.stable,
      ),
      sleepPatterns: Map<String, dynamic>.from(json['sleepPatterns'] ?? {}),
      insights: List<String>.from(json['insights'] ?? []),
      recommendations: List<String>.from(json['recommendations'] ?? []),
      commonFactors: Map<String, int>.from(json['commonFactors'] ?? {}),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }
}

// Тренд сна
enum SleepTrend {
  improving,    // Улучшается
  stable,       // Стабильно
  declining,    // Ухудшается
  inconsistent; // Нестабильно
  
  String get displayName {
    switch (this) {
      case SleepTrend.improving:
        return 'Улучшается';
      case SleepTrend.stable:
        return 'Стабильно';
      case SleepTrend.declining:
        return 'Ухудшается';
      case SleepTrend.inconsistent:
        return 'Нестабильно';
    }
  }
  
  int get colorHex {
    switch (this) {
      case SleepTrend.improving:
        return 0xFF4CAF50; // green
      case SleepTrend.stable:
        return 0xFF2196F3; // blue
      case SleepTrend.declining:
        return 0xFFF44336; // red
      case SleepTrend.inconsistent:
        return 0xFFFF9800; // orange
    }
  }
}

// ===== МОДЕЛИ ЭКСТРЕННЫХ СИТУАЦИЙ =====

// Тип экстренной ситуации
enum EmergencyType {
  choking,        // Удушье
  poisoning,      // Отравление
  injury,         // Травма
  fever,          // Высокая температура
  allergic,       // Аллергическая реакция
  breathing,      // Проблемы с дыханием
  seizure,        // Судороги
  unconscious,    // Потеря сознания
  burns,          // Ожоги
  other;          // Другое
  
  String get displayName {
    switch (this) {
      case EmergencyType.choking:
        return 'Удушье';
      case EmergencyType.poisoning:
        return 'Отравление';
      case EmergencyType.injury:
        return 'Травма';
      case EmergencyType.fever:
        return 'Высокая температура';
      case EmergencyType.allergic:
        return 'Аллергическая реакция';
      case EmergencyType.breathing:
        return 'Проблемы с дыханием';
      case EmergencyType.seizure:
        return 'Судороги';
      case EmergencyType.unconscious:
        return 'Потеря сознания';
      case EmergencyType.burns:
        return 'Ожоги';
      case EmergencyType.other:
        return 'Другое';
    }
  }
  
  String get iconEmoji {
    switch (this) {
      case EmergencyType.choking:
        return '🫁';
      case EmergencyType.poisoning:
        return '☠️';
      case EmergencyType.injury:
        return '🩹';
      case EmergencyType.fever:
        return '🌡️';
      case EmergencyType.allergic:
        return '🚨';
      case EmergencyType.breathing:
        return '💨';
      case EmergencyType.seizure:
        return '⚡';
      case EmergencyType.unconscious:
        return '😵';
      case EmergencyType.burns:
        return '🔥';
      case EmergencyType.other:
        return '❗';
    }
  }
  
  int get priorityLevel {
    switch (this) {
      case EmergencyType.choking:
      case EmergencyType.unconscious:
      case EmergencyType.breathing:
        return 1; // Критический
      case EmergencyType.poisoning:
      case EmergencyType.allergic:
      case EmergencyType.seizure:
        return 2; // Очень высокий
      case EmergencyType.fever:
      case EmergencyType.burns:
        return 3; // Высокий
      case EmergencyType.injury:
        return 4; // Умеренный
      case EmergencyType.other:
        return 5; // Низкий
    }
  }
  
  int get colorHex {
    switch (priorityLevel) {
      case 1:
        return 0xFFD32F2F; // Красный - критический
      case 2:
        return 0xFFFF5722; // Оранжево-красный - очень высокий
      case 3:
        return 0xFFFF9800; // Оранжевый - высокий
      case 4:
        return 0xFFFFC107; // Желтый - умеренный
      case 5:
        return 0xFF4CAF50; // Зеленый - низкий
      default:
        return 0xFFD32F2F;
    }
  }
}

// Контакт экстренной службы
class EmergencyContact {
  final String id;
  final String name;              // Название службы
  final String phone;             // Номер телефона
  final String description;       // Описание службы
  final EmergencyType type;       // К какому типу экстренной ситуации относится
  final bool isActive;            // Активный контакт
  final String? address;          // Адрес (для больниц, клиник)
  final String? workingHours;     // Часы работы
  final bool isAvailable24h;      // Работает 24/7
  final String country;           // Страна
  final String city;              // Город
  final int priority;             // Приоритет отображения (1 - наивысший)
  final DateTime createdAt;
  final DateTime updatedAt;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.description,
    required this.type,
    required this.isActive,
    this.address,
    this.workingHours,
    required this.isAvailable24h,
    required this.country,
    required this.city,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'description': description,
      'type': type.name,
      'isActive': isActive,
      'address': address,
      'workingHours': workingHours,
      'isAvailable24h': isAvailable24h,
      'country': country,
      'city': city,
      'priority': priority,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static EmergencyContact fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      description: json['description'] ?? '',
      type: EmergencyType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => EmergencyType.other,
      ),
      isActive: json['isActive'] ?? true,
      address: json['address'],
      workingHours: json['workingHours'],
      isAvailable24h: json['isAvailable24h'] ?? false,
      country: json['country'] ?? 'RU',
      city: json['city'] ?? '',
      priority: json['priority'] ?? 999,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  String get formattedPhone {
    // Форматирование российских номеров
    if (country == 'RU' && phone.length >= 10) {
      final cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
      if (cleaned.length == 11 && cleaned.startsWith('8')) {
        return '+7 ${cleaned.substring(1, 4)} ${cleaned.substring(4, 7)}-${cleaned.substring(7, 9)}-${cleaned.substring(9)}';
      } else if (cleaned.length == 11 && cleaned.startsWith('7')) {
        return '+${cleaned.substring(0, 1)} ${cleaned.substring(1, 4)} ${cleaned.substring(4, 7)}-${cleaned.substring(7, 9)}-${cleaned.substring(9)}';
      }
    }
    return phone;
  }

  bool get isAvailableNow {
    if (isAvailable24h) return true;
    
    if (workingHours == null) return true;
    
    // Упрощенная проверка времени работы
    final now = DateTime.now();
    final currentHour = now.hour;
    
    // Примеры форматов: "9:00-18:00", "08:00-20:00"
    final regex = RegExp(r'(\d{1,2}):(\d{2})-(\d{1,2}):(\d{2})');
    final match = regex.firstMatch(workingHours!);
    
    if (match != null) {
      final startHour = int.parse(match.group(1)!);
      final endHour = int.parse(match.group(3)!);
      
      return currentHour >= startHour && currentHour < endHour;
    }
    
    return true; // Если не можем распарсить, считаем доступным
  }
}

// Инструкция первой помощи
class FirstAidGuide {
  final String id;
  final EmergencyType type;       // Тип экстренной ситуации
  final String title;             // Заголовок инструкции
  final String shortDescription;  // Краткое описание
  final List<FirstAidStep> steps; // Пошаговые инструкции
  final List<String> warningsSigns; // Признаки опасности
  final List<String> doList;      // Что ДЕЛАТЬ
  final List<String> dontList;    // Что НЕ ДЕЛАТЬ
  final String? videoUrl;         // Ссылка на обучающее видео
  final List<String> imageUrls;   // Ссылки на изображения
  final AgeRange ageRange;        // Возрастной диапазон
  final bool isVerifiedByDoctor;  // Проверено врачом
  final DateTime createdAt;
  final DateTime updatedAt;

  FirstAidGuide({
    required this.id,
    required this.type,
    required this.title,
    required this.shortDescription,
    required this.steps,
    required this.warningsSigns,
    required this.doList,
    required this.dontList,
    this.videoUrl,
    required this.imageUrls,
    required this.ageRange,
    required this.isVerifiedByDoctor,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'shortDescription': shortDescription,
      'steps': steps.map((s) => s.toJson()).toList(),
      'warningsSigns': warningsSigns,
      'doList': doList,
      'dontList': dontList,
      'videoUrl': videoUrl,
      'imageUrls': imageUrls,
      'ageRange': ageRange.toJson(),
      'isVerifiedByDoctor': isVerifiedByDoctor,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static FirstAidGuide fromJson(Map<String, dynamic> json) {
    return FirstAidGuide(
      id: json['id'] ?? '',
      type: EmergencyType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => EmergencyType.other,
      ),
      title: json['title'] ?? '',
      shortDescription: json['shortDescription'] ?? '',
      steps: (json['steps'] as List? ?? [])
          .map((s) => FirstAidStep.fromJson(s))
          .toList(),
      warningsSigns: List<String>.from(json['warningsSigns'] ?? []),
      doList: List<String>.from(json['doList'] ?? []),
      dontList: List<String>.from(json['dontList'] ?? []),
      videoUrl: json['videoUrl'],
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      ageRange: AgeRange.fromJson(json['ageRange'] ?? {}),
      isVerifiedByDoctor: json['isVerifiedByDoctor'] ?? false,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  int get estimatedDuration {
    // Примерное время выполнения всех шагов в секундах
    return steps.fold<int>(0, (sum, step) => sum + step.estimatedSeconds);
  }

  String get formattedDuration {
    final minutes = estimatedDuration ~/ 60;
    final seconds = estimatedDuration % 60;
    
    if (minutes > 0) {
      return '${minutes}м ${seconds}с';
    } else {
      return '${seconds}с';
    }
  }
}

// Шаг инструкции первой помощи
class FirstAidStep {
  final int stepNumber;           // Номер шага
  final String instruction;       // Текст инструкции
  final String? imageUrl;         // Изображение для шага
  final int estimatedSeconds;     // Примерное время выполнения
  final bool isCritical;          // Критический шаг
  final String? tip;              // Дополнительная подсказка

  FirstAidStep({
    required this.stepNumber,
    required this.instruction,
    this.imageUrl,
    required this.estimatedSeconds,
    required this.isCritical,
    this.tip,
  });

  Map<String, dynamic> toJson() {
    return {
      'stepNumber': stepNumber,
      'instruction': instruction,
      'imageUrl': imageUrl,
      'estimatedSeconds': estimatedSeconds,
      'isCritical': isCritical,
      'tip': tip,
    };
  }

  static FirstAidStep fromJson(Map<String, dynamic> json) {
    return FirstAidStep(
      stepNumber: json['stepNumber'] ?? 1,
      instruction: json['instruction'] ?? '',
      imageUrl: json['imageUrl'],
      estimatedSeconds: json['estimatedSeconds'] ?? 30,
      isCritical: json['isCritical'] ?? false,
      tip: json['tip'],
    );
  }
}

// Возрастной диапазон
class AgeRange {
  final int minMonths;  // Минимальный возраст в месяцах
  final int maxMonths;  // Максимальный возраст в месяцах

  AgeRange({
    required this.minMonths,
    required this.maxMonths,
  });

  Map<String, dynamic> toJson() {
    return {
      'minMonths': minMonths,
      'maxMonths': maxMonths,
    };
  }

  static AgeRange fromJson(Map<String, dynamic> json) {
    return AgeRange(
      minMonths: json['minMonths'] ?? 0,
      maxMonths: json['maxMonths'] ?? 72, // 6 лет по умолчанию
    );
  }

  String get displayName {
    final minYears = minMonths ~/ 12;
    final minRemainingMonths = minMonths % 12;
    final maxYears = maxMonths ~/ 12;
    final maxRemainingMonths = maxMonths % 12;

    String formatAge(int years, int months) {
      if (years == 0) {
        return '${months}мес';
      } else if (months == 0) {
        return '${years}г';
      } else {
        return '${years}г ${months}мес';
      }
    }

    return '${formatAge(minYears, minRemainingMonths)} - ${formatAge(maxYears, maxRemainingMonths)}';
  }

  bool isApplicableForAge(int ageMonths) {
    return ageMonths >= minMonths && ageMonths <= maxMonths;
  }
}

// Запись экстренного случая
class EmergencyRecord {
  final String id;
  final String childId;
  final EmergencyType type;       // Тип экстренной ситуации
  final DateTime incidentDateTime; // Дата и время происшествия
  final String description;       // Описание ситуации
  final List<String> actionsTaken; // Предпринятые действия
  final List<String> contactsCalled; // Какие службы вызывались
  final String? outcome;          // Исход ситуации
  final bool wasHospitalized;     // Была ли госпитализация
  final String? hospitalName;     // Название больницы
  final List<String> symptoms;    // Симптомы
  final String? doctorNotes;      // Заметки врача
  final List<String> imageUrls;   // Фотографии (если необходимо)
  final Map<String, dynamic> additionalInfo; // Дополнительная информация
  final DateTime createdAt;
  final DateTime updatedAt;

  EmergencyRecord({
    required this.id,
    required this.childId,
    required this.type,
    required this.incidentDateTime,
    required this.description,
    required this.actionsTaken,
    required this.contactsCalled,
    this.outcome,
    required this.wasHospitalized,
    this.hospitalName,
    required this.symptoms,
    this.doctorNotes,
    required this.imageUrls,
    required this.additionalInfo,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'childId': childId,
      'type': type.name,
      'incidentDateTime': Timestamp.fromDate(incidentDateTime),
      'description': description,
      'actionsTaken': actionsTaken,
      'contactsCalled': contactsCalled,
      'outcome': outcome,
      'wasHospitalized': wasHospitalized,
      'hospitalName': hospitalName,
      'symptoms': symptoms,
      'doctorNotes': doctorNotes,
      'imageUrls': imageUrls,
      'additionalInfo': additionalInfo,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static EmergencyRecord fromJson(Map<String, dynamic> json) {
    return EmergencyRecord(
      id: json['id'] ?? '',
      childId: json['childId'] ?? '',
      type: EmergencyType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => EmergencyType.other,
      ),
      incidentDateTime: (json['incidentDateTime'] as Timestamp).toDate(),
      description: json['description'] ?? '',
      actionsTaken: List<String>.from(json['actionsTaken'] ?? []),
      contactsCalled: List<String>.from(json['contactsCalled'] ?? []),
      outcome: json['outcome'],
      wasHospitalized: json['wasHospitalized'] ?? false,
      hospitalName: json['hospitalName'],
      symptoms: List<String>.from(json['symptoms'] ?? []),
      doctorNotes: json['doctorNotes'],
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      additionalInfo: Map<String, dynamic>.from(json['additionalInfo'] ?? {}),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  String get formattedIncidentDate {
    return '${incidentDateTime.day}.${incidentDateTime.month}.${incidentDateTime.year} ${incidentDateTime.hour.toString().padLeft(2, '0')}:${incidentDateTime.minute.toString().padLeft(2, '0')}';
  }

  String get severityLevel {
    if (wasHospitalized) return 'Критический';
    if (contactsCalled.isNotEmpty) return 'Серьезный';
    return 'Умеренный';
  }

  int get severityColorHex {
    if (wasHospitalized) return 0xFFD32F2F; // Красный
    if (contactsCalled.isNotEmpty) return 0xFFFF9800; // Оранжевый
    return 0xFFFFC107; // Желтый
  }
}

// ===== МОДЕЛИ РАННЕГО РАЗВИТИЯ =====

// Область развития
enum DevelopmentArea {
  cognitive,      // Познавательное развитие
  motor,          // Моторное развитие  
  language,       // Речевое развитие
  social,         // Социальное развитие
  emotional,      // Эмоциональное развитие
  creative,       // Творческое развитие
  sensory;        // Сенсорное развитие

  String get displayName {
    switch (this) {
      case DevelopmentArea.cognitive:
        return 'Познавательное развитие';
      case DevelopmentArea.motor:
        return 'Моторное развитие';
      case DevelopmentArea.language:
        return 'Речевое развитие';
      case DevelopmentArea.social:
        return 'Социальное развитие';
      case DevelopmentArea.emotional:
        return 'Эмоциональное развитие';
      case DevelopmentArea.creative:
        return 'Творческое развитие';
      case DevelopmentArea.sensory:
        return 'Сенсорное развитие';
    }
  }

  String get iconEmoji {
    switch (this) {
      case DevelopmentArea.cognitive:
        return '🧠';
      case DevelopmentArea.motor:
        return '🏃';
      case DevelopmentArea.language:
        return '🗣️';
      case DevelopmentArea.social:
        return '👥';
      case DevelopmentArea.emotional:
        return '😊';
      case DevelopmentArea.creative:
        return '🎨';
      case DevelopmentArea.sensory:
        return '👁️';
    }
  }

  int get colorHex {
    switch (this) {
      case DevelopmentArea.cognitive:
        return 0xFF9C27B0; // purple
      case DevelopmentArea.motor:
        return 0xFF4CAF50; // green
      case DevelopmentArea.language:
        return 0xFF2196F3; // blue
      case DevelopmentArea.social:
        return 0xFFFF9800; // orange
      case DevelopmentArea.emotional:
        return 0xFFE91E63; // pink
      case DevelopmentArea.creative:
        return 0xFFFF5722; // deep orange
      case DevelopmentArea.sensory:
        return 0xFF607D8B; // blue grey
    }
  }

  String get description {
    switch (this) {
      case DevelopmentArea.cognitive:
        return 'Развитие мышления, памяти, внимания, логики';
      case DevelopmentArea.motor:
        return 'Развитие крупной и мелкой моторики';
      case DevelopmentArea.language:
        return 'Развитие речи, словарного запаса, коммуникации';
      case DevelopmentArea.social:
        return 'Навыки общения и взаимодействия с другими';
      case DevelopmentArea.emotional:
        return 'Понимание эмоций, эмпатия, самоконтроль';
      case DevelopmentArea.creative:
        return 'Творческие способности, воображение, искусство';
      case DevelopmentArea.sensory:
        return 'Развитие органов чувств и восприятия';
    }
  }
}

// Сложность активности
enum ActivityDifficulty {
  easy,           // Легкая
  medium,         // Средняя
  hard;           // Сложная

  String get displayName {
    switch (this) {
      case ActivityDifficulty.easy:
        return 'Легкая';
      case ActivityDifficulty.medium:
        return 'Средняя';
      case ActivityDifficulty.hard:
        return 'Сложная';
    }
  }

  int get colorHex {
    switch (this) {
      case ActivityDifficulty.easy:
        return 0xFF4CAF50; // green
      case ActivityDifficulty.medium:
        return 0xFFFF9800; // orange
      case ActivityDifficulty.hard:
        return 0xFFF44336; // red
    }
  }

  int get value {
    switch (this) {
      case ActivityDifficulty.easy:
        return 1;
      case ActivityDifficulty.medium:
        return 2;
      case ActivityDifficulty.hard:
        return 3;
    }
  }
}

// Развивающая активность
class DevelopmentActivity {
  final String id;
  final String title;                    // Название активности
  final String description;              // Описание
  final DevelopmentArea area;            // Область развития
  final ActivityDifficulty difficulty;   // Сложность
  final AgeRange ageRange;              // Возрастной диапазон
  final int durationMinutes;            // Продолжительность в минутах
  final List<String> materials;        // Необходимые материалы
  final List<ActivityStep> steps;      // Пошаговые инструкции
  final List<String> tips;             // Советы и подсказки
  final List<String> benefits;         // Польза от активности
  final List<String> variations;       // Вариации активности
  final String? videoUrl;              // Ссылка на обучающее видео
  final List<String> imageUrls;        // Изображения
  final List<String> tags;             // Теги для поиска
  final bool isIndoor;                 // Активность в помещении
  final bool requiresAdult;            // Нужно участие взрослого
  final double rating;                 // Рейтинг активности
  final int timesCompleted;            // Сколько раз выполнена
  final bool isFavorite;               // Избранная активность
  final DateTime createdAt;
  final DateTime updatedAt;

  DevelopmentActivity({
    required this.id,
    required this.title,
    required this.description,
    required this.area,
    required this.difficulty,
    required this.ageRange,
    required this.durationMinutes,
    required this.materials,
    required this.steps,
    required this.tips,
    required this.benefits,
    required this.variations,
    this.videoUrl,
    required this.imageUrls,
    required this.tags,
    required this.isIndoor,
    required this.requiresAdult,
    required this.rating,
    required this.timesCompleted,
    required this.isFavorite,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'area': area.name,
      'difficulty': difficulty.name,
      'ageRange': ageRange.toJson(),
      'durationMinutes': durationMinutes,
      'materials': materials,
      'steps': steps.map((s) => s.toJson()).toList(),
      'tips': tips,
      'benefits': benefits,
      'variations': variations,
      'videoUrl': videoUrl,
      'imageUrls': imageUrls,
      'tags': tags,
      'isIndoor': isIndoor,
      'requiresAdult': requiresAdult,
      'rating': rating,
      'timesCompleted': timesCompleted,
      'isFavorite': isFavorite,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static DevelopmentActivity fromJson(Map<String, dynamic> json) {
    return DevelopmentActivity(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      area: DevelopmentArea.values.firstWhere(
        (e) => e.name == json['area'],
        orElse: () => DevelopmentArea.cognitive,
      ),
      difficulty: ActivityDifficulty.values.firstWhere(
        (e) => e.name == json['difficulty'],
        orElse: () => ActivityDifficulty.easy,
      ),
      ageRange: AgeRange.fromJson(json['ageRange'] ?? {}),
      durationMinutes: json['durationMinutes'] ?? 15,
      materials: List<String>.from(json['materials'] ?? []),
      steps: (json['steps'] as List? ?? [])
          .map((s) => ActivityStep.fromJson(s))
          .toList(),
      tips: List<String>.from(json['tips'] ?? []),
      benefits: List<String>.from(json['benefits'] ?? []),
      variations: List<String>.from(json['variations'] ?? []),
      videoUrl: json['videoUrl'],
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
      isIndoor: json['isIndoor'] ?? true,
      requiresAdult: json['requiresAdult'] ?? true,
      rating: (json['rating'] ?? 0.0).toDouble(),
      timesCompleted: json['timesCompleted'] ?? 0,
      isFavorite: json['isFavorite'] ?? false,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  String get formattedDuration {
    if (durationMinutes < 60) {
      return '${durationMinutes}мин';
    } else {
      final hours = durationMinutes ~/ 60;
      final minutes = durationMinutes % 60;
      return '${hours}ч ${minutes}мин';
    }
  }

  int get estimatedTotalTime {
    // Время подготовки + время активности + время уборки
    return (durationMinutes * 1.3).round(); // +30% на подготовку
  }

  String get formattedTotalTime {
    if (estimatedTotalTime < 60) {
      return '${estimatedTotalTime}мин';
    } else {
      final hours = estimatedTotalTime ~/ 60;
      final minutes = estimatedTotalTime % 60;
      return '${hours}ч ${minutes}мин';
    }
  }

  bool isAgeAppropriate(int ageMonths) {
    return ageRange.isApplicableForAge(ageMonths);
  }

  String get ratingText {
    if (rating >= 4.5) return 'Отлично';
    if (rating >= 4.0) return 'Хорошо';
    if (rating >= 3.0) return 'Средне';
    if (rating >= 2.0) return 'Ниже среднего';
    return 'Плохо';
  }
}

// Шаг активности
class ActivityStep {
  final int stepNumber;          // Номер шага
  final String instruction;      // Инструкция
  final String? imageUrl;        // Изображение для шага
  final int estimatedMinutes;    // Примерное время выполнения
  final String? tip;             // Дополнительная подсказка

  ActivityStep({
    required this.stepNumber,
    required this.instruction,
    this.imageUrl,
    required this.estimatedMinutes,
    this.tip,
  });

  Map<String, dynamic> toJson() {
    return {
      'stepNumber': stepNumber,
      'instruction': instruction,
      'imageUrl': imageUrl,
      'estimatedMinutes': estimatedMinutes,
      'tip': tip,
    };
  }

  static ActivityStep fromJson(Map<String, dynamic> json) {
    return ActivityStep(
      stepNumber: json['stepNumber'] ?? 1,
      instruction: json['instruction'] ?? '',
      imageUrl: json['imageUrl'],
      estimatedMinutes: json['estimatedMinutes'] ?? 5,
      tip: json['tip'],
    );
  }
}

// Запись выполнения активности
class ActivityCompletion {
  final String id;
  final String childId;
  final String activityId;           // ID активности
  final DateTime completionDate;     // Дата выполнения
  final int actualDurationMinutes;   // Фактическое время выполнения
  final double childRating;          // Оценка ребенка (1-5)
  final double parentRating;         // Оценка родителя (1-5)
  final String? childFeedback;       // Отзыв ребенка
  final String? parentFeedback;      // Отзыв родителя
  final List<String> difficulties;   // Трудности при выполнении
  final List<String> enjoyedAspects; // Что понравилось
  final List<String> photoUrls;      // Фото выполнения
  final Map<String, dynamic> skillsProgress; // Прогресс навыков
  final bool wasCompleted;           // Была ли завершена
  final String? nextSuggestions;     // Предложения на следующий раз
  final DateTime createdAt;
  final DateTime updatedAt;

  ActivityCompletion({
    required this.id,
    required this.childId,
    required this.activityId,
    required this.completionDate,
    required this.actualDurationMinutes,
    required this.childRating,
    required this.parentRating,
    this.childFeedback,
    this.parentFeedback,
    required this.difficulties,
    required this.enjoyedAspects,
    required this.photoUrls,
    required this.skillsProgress,
    required this.wasCompleted,
    this.nextSuggestions,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'childId': childId,
      'activityId': activityId,
      'completionDate': Timestamp.fromDate(completionDate),
      'actualDurationMinutes': actualDurationMinutes,
      'childRating': childRating,
      'parentRating': parentRating,
      'childFeedback': childFeedback,
      'parentFeedback': parentFeedback,
      'difficulties': difficulties,
      'enjoyedAspects': enjoyedAspects,
      'photoUrls': photoUrls,
      'skillsProgress': skillsProgress,
      'wasCompleted': wasCompleted,
      'nextSuggestions': nextSuggestions,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static ActivityCompletion fromJson(Map<String, dynamic> json) {
    return ActivityCompletion(
      id: json['id'] ?? '',
      childId: json['childId'] ?? '',
      activityId: json['activityId'] ?? '',
      completionDate: (json['completionDate'] as Timestamp).toDate(),
      actualDurationMinutes: json['actualDurationMinutes'] ?? 0,
      childRating: (json['childRating'] ?? 0.0).toDouble(),
      parentRating: (json['parentRating'] ?? 0.0).toDouble(),
      childFeedback: json['childFeedback'],
      parentFeedback: json['parentFeedback'],
      difficulties: List<String>.from(json['difficulties'] ?? []),
      enjoyedAspects: List<String>.from(json['enjoyedAspects'] ?? []),
      photoUrls: List<String>.from(json['photoUrls'] ?? []),
      skillsProgress: Map<String, dynamic>.from(json['skillsProgress'] ?? {}),
      wasCompleted: json['wasCompleted'] ?? false,
      nextSuggestions: json['nextSuggestions'],
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  String get formattedDate {
    return '${completionDate.day}.${completionDate.month}.${completionDate.year}';
  }

  String get formattedDuration {
    if (actualDurationMinutes < 60) {
      return '${actualDurationMinutes}мин';
    } else {
      final hours = actualDurationMinutes ~/ 60;
      final minutes = actualDurationMinutes % 60;
      return '${hours}ч ${minutes}мин';
    }
  }

  double get averageRating {
    return (childRating + parentRating) / 2;
  }

  String get successLevel {
    if (!wasCompleted) return 'Не завершена';
    if (averageRating >= 4.5) return 'Отлично';
    if (averageRating >= 4.0) return 'Хорошо';
    if (averageRating >= 3.0) return 'Удовлетворительно';
    return 'Требует улучшения';
  }

  int get successColorHex {
    if (!wasCompleted) return 0xFF9E9E9E; // grey
    if (averageRating >= 4.5) return 0xFF4CAF50; // green
    if (averageRating >= 4.0) return 0xFF8BC34A; // light green
    if (averageRating >= 3.0) return 0xFFFF9800; // orange
    return 0xFFF44336; // red
  }
}

// Прогресс развития
class DevelopmentProgress {
  final String id;
  final String childId;
  final DevelopmentArea area;           // Область развития
  final DateTime assessmentDate;        // Дата оценки
  final double progressScore;           // Оценка прогресса (0-100)
  final Map<String, double> skillLevels; // Уровни навыков
  final List<String> achievedSkills;    // Достигнутые навыки
  final List<String> workingOnSkills;   // Навыки в работе
  final List<String> nextMilestones;    // Следующие вехи
  final String? notes;                  // Заметки
  final List<String> recommendedActivities; // Рекомендуемые активности
  final DateTime createdAt;
  final DateTime updatedAt;

  DevelopmentProgress({
    required this.id,
    required this.childId,
    required this.area,
    required this.assessmentDate,
    required this.progressScore,
    required this.skillLevels,
    required this.achievedSkills,
    required this.workingOnSkills,
    required this.nextMilestones,
    this.notes,
    required this.recommendedActivities,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'childId': childId,
      'area': area.name,
      'assessmentDate': Timestamp.fromDate(assessmentDate),
      'progressScore': progressScore,
      'skillLevels': skillLevels,
      'achievedSkills': achievedSkills,
      'workingOnSkills': workingOnSkills,
      'nextMilestones': nextMilestones,
      'notes': notes,
      'recommendedActivities': recommendedActivities,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static DevelopmentProgress fromJson(Map<String, dynamic> json) {
    return DevelopmentProgress(
      id: json['id'] ?? '',
      childId: json['childId'] ?? '',
      area: DevelopmentArea.values.firstWhere(
        (e) => e.name == json['area'],
        orElse: () => DevelopmentArea.cognitive,
      ),
      assessmentDate: (json['assessmentDate'] as Timestamp).toDate(),
      progressScore: (json['progressScore'] ?? 0.0).toDouble(),
      skillLevels: Map<String, double>.from(json['skillLevels'] ?? {}),
      achievedSkills: List<String>.from(json['achievedSkills'] ?? []),
      workingOnSkills: List<String>.from(json['workingOnSkills'] ?? []),
      nextMilestones: List<String>.from(json['nextMilestones'] ?? []),
      notes: json['notes'],
      recommendedActivities: List<String>.from(json['recommendedActivities'] ?? []),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  String get formattedDate {
    return '${assessmentDate.day}.${assessmentDate.month}.${assessmentDate.year}';
  }

  String get progressLevel {
    if (progressScore >= 90) return 'Превосходно';
    if (progressScore >= 80) return 'Отлично';
    if (progressScore >= 70) return 'Хорошо';
    if (progressScore >= 60) return 'Удовлетворительно';
    if (progressScore >= 50) return 'Ниже среднего';
    return 'Требует внимания';
  }

  int get progressColorHex {
    if (progressScore >= 90) return 0xFF4CAF50; // green
    if (progressScore >= 80) return 0xFF8BC34A; // light green
    if (progressScore >= 70) return 0xFFCDDC39; // lime
    if (progressScore >= 60) return 0xFFFF9800; // orange
    if (progressScore >= 50) return 0xFFFF5722; // deep orange
    return 0xFFF44336; // red
  }

  double get averageSkillLevel {
    if (skillLevels.isEmpty) return 0.0;
    return skillLevels.values.reduce((a, b) => a + b) / skillLevels.length;
  }
}
