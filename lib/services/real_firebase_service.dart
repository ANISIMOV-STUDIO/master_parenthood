// lib/services/real_firebase_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class RealFirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  FirebaseAuth get firebaseAuth => _auth;

  User? get currentUser => _auth.currentUser;
  bool get isAuthenticated => _auth.currentUser != null;

  String? get currentUserEmail => _auth.currentUser?.email;
  String? get currentUserName => _auth.currentUser?.displayName;

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } catch (e) {
      print('Error signing in with email: $e');
      rethrow;
    }
  }

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    required String parentName,
  }) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Создаем документ пользователя при регистрации
      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': email,
          'parentName': parentName,
          'createdAt': FieldValue.serverTimestamp(),
          'xp': 0, // Инициализируем XP
          // TODO: Добавить поле для ID ребенка, если их может быть несколько
        });
        // TODO: Создать документ для ребенка и связать его с родителем
      }

      await userCredential.user?.updateDisplayName(parentName);

      return userCredential;
    } catch (e) {
      print('Error registering with email: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      // Добавляем пользователя в Firestore, если его нет
      if (userCredential.user != null) {
        final userDoc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();
        if (!userDoc.exists) {
          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .set({
            'email': userCredential.user!.email,
            'parentName': userCredential.user!.displayName ?? 'Неизвестный',
            'createdAt': FieldValue.serverTimestamp(),
            'xp': 0,
            // TODO: Добавить поле для ID ребенка
          });
          // TODO: Создать документ для ребенка
        }
      }

      return userCredential;
    } catch (e) {
      print('Error signing in with Google: $e');
      rethrow;
    }
  }

  Future<void> addXP(int amount) async {
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      try {
        await _firestore
            .collection('users')
            .doc(userId)
            .update({'xp': FieldValue.increment(amount)});
      } catch (e) {
        print('Error adding XP: $e');
        rethrow;
      }
    } else {
      print('Error adding XP: User not logged in');
      throw Exception('User not logged in');
    }
  }

  Future<void> saveStory({
    required String childId,
    required String story,
    required String theme,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      try {
        await _firestore.collection('stories').add({
          'userId': userId,
          'childId': childId,
          'story': story,
          'theme': theme,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print('Error saving story: $e');
        rethrow;
      }
    } else {
      print('Error saving story: User not logged in');
      throw Exception('User not logged in');
    }
  }

  Stream<int> get userXPStream {
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      return _firestore
          .collection('users')
          .doc(userId)
          .snapshots()
          .map((snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
          return snapshot.data()!['xp'] ?? 0;
        }
        return 0;
      });
    } else {
      return Stream.value(0);
    }
  }

  // TODO: Доработать логику получения данных ребенка, учитывая структуру данных и выбор активного ребенка
  Future<Map<String, dynamic>?> getChildData(
      String userId, String childId) async {
    try {
      // Пример: получаем документ ребенка из подколлекции 'children' в документе пользователя
      final childDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('children')
          .doc(childId)
          .get();
      if (childDoc.exists) {
        return childDoc.data();
      } else {
        print('Child document not found');
        return null;
      }
    } catch (e) {
      print('Error getting child data: $e');
      rethrow;
    }
  }
}
