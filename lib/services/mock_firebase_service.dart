// lib/services/mock_firebase_service.dart
import 'package:firebase_auth/firebase_auth.dart';

class MockFirebaseService {
  static bool _isAuthenticated = false;
  static String? _currentUserEmail;
  static String? _currentUserName;
  static int _xp = 0;

  static bool get isAuthenticated => _isAuthenticated;
  static String? get currentUserEmail => _currentUserEmail;
  static String? get currentUserName => _currentUserName;
  static int get xp => _xp;

  static Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    // Имитация задержки сети
    await Future.delayed(const Duration(seconds: 1));
    
    if (email == 'test@example.com' && password == 'password') {
      _isAuthenticated = true;
      _currentUserEmail = email;
      _currentUserName = 'Test User';
    } else {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Неверный email или пароль',
      );
    }
  }

  static Future<void> registerWithEmail({
    required String email,
    required String password,
    required String parentName,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    
    _isAuthenticated = true;
    _currentUserEmail = email;
    _currentUserName = parentName;
  }

  static Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _isAuthenticated = false;
    _currentUserEmail = null;
    _currentUserName = null;
  }

  static Future<void> addXP(int amount) async {
    _xp += amount;
  }

  static Future<void> saveStory({
    required String childId,
    required String story,
    required String theme,
  }) async {
    // Имитация сохранения в Firestore
    await Future.delayed(const Duration(milliseconds: 300));
  }

  // Создаем мок-пользователя для совместимости с Firebase Auth
  static User? get currentUser {
    if (!_isAuthenticated) return null;
    
    // Возвращаем null для совместимости с Firebase Auth
    // В реальном приложении здесь был бы объект User
    return null;
  }
} 