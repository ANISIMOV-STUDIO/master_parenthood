// lib/services/local_auth_service.dart
// Local Authentication Service - No Firebase, Pure Local Storage
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

/// Simple User model for local authentication
class LocalUser {
  final String id;
  final String email;
  final String displayName;
  final DateTime createdAt;

  LocalUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'displayName': displayName,
    'createdAt': createdAt.toIso8601String(),
  };

  factory LocalUser.fromJson(Map<String, dynamic> json) => LocalUser(
    id: json['id'] as String,
    email: json['email'] as String,
    displayName: json['displayName'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

/// Local Authentication Service
/// Uses SharedPreferences for simple key-value storage
/// Uses Hive for structured data storage
class LocalAuthService {
  static const String _currentUserKey = 'current_user';
  static const String _usersBoxName = 'users';
  static const String _isAuthenticatedKey = 'is_authenticated';

  static LocalAuthService? _instance;
  static LocalAuthService get instance {
    _instance ??= LocalAuthService._();
    return _instance!;
  }

  LocalAuthService._();

  LocalUser? _currentUser;

  /// Stream of authentication state changes
  final _authStateController = StreamController<LocalUser?>.broadcast();
  Stream<LocalUser?> get authStateChanges => _authStateController.stream;

  /// Get current user
  LocalUser? get currentUser => _currentUser;

  /// Check if user is authenticated
  Future<bool> get isAuthenticated async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isAuthenticatedKey) ?? false;
  }

  /// Initialize service
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_currentUserKey);

      if (userJson != null) {
        _currentUser = LocalUser.fromJson(json.decode(userJson));
        _authStateController.add(_currentUser);
      }
    } catch (e) {
      debugPrint('Error initializing LocalAuthService: $e');
    }
  }

  /// Sign up with email and password
  Future<LocalUser?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      // In production, you'd hash the password
      // For now, we'll just store it (NOT recommended for production)
      final userId = DateTime.now().millisecondsSinceEpoch.toString();

      final user = LocalUser(
        id: userId,
        email: email,
        displayName: displayName,
        createdAt: DateTime.now(),
      );

      // Save user data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentUserKey, json.encode(user.toJson()));
      await prefs.setBool(_isAuthenticatedKey, true);
      await prefs.setString('user_${userId}_password', password);

      _currentUser = user;
      _authStateController.add(user);

      debugPrint('✅ User registered: ${user.email}');
      return user;
    } catch (e) {
      debugPrint('❌ Sign up error: $e');
      return null;
    }
  }

  /// Sign in with email and password
  Future<LocalUser?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_currentUserKey);

      if (userJson == null) {
        throw Exception('No user found. Please sign up first.');
      }

      final user = LocalUser.fromJson(json.decode(userJson));
      final storedPassword = prefs.getString('user_${user.id}_password');

      if (storedPassword != password) {
        throw Exception('Invalid password');
      }

      await prefs.setBool(_isAuthenticatedKey, true);
      _currentUser = user;
      _authStateController.add(user);

      debugPrint('✅ User signed in: ${user.email}');
      return user;
    } catch (e) {
      debugPrint('❌ Sign in error: $e');
      throw Exception('Sign in failed: $e');
    }
  }

  /// Sign in anonymously (for quick access)
  Future<LocalUser?> signInAnonymously() async {
    try {
      final userId = 'anon_${DateTime.now().millisecondsSinceEpoch}';

      final user = LocalUser(
        id: userId,
        email: 'anonymous@local.app',
        displayName: 'Guest User',
        createdAt: DateTime.now(),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentUserKey, json.encode(user.toJson()));
      await prefs.setBool(_isAuthenticatedKey, true);

      _currentUser = user;
      _authStateController.add(user);

      debugPrint('✅ Anonymous user signed in');
      return user;
    } catch (e) {
      debugPrint('❌ Anonymous sign in error: $e');
      return null;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currentUserKey);
      await prefs.setBool(_isAuthenticatedKey, false);

      _currentUser = null;
      _authStateController.add(null);

      debugPrint('✅ User signed out');
    } catch (e) {
      debugPrint('❌ Sign out error: $e');
    }
  }

  /// Update user profile
  Future<void> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    if (_currentUser == null) return;

    try {
      final updatedUser = LocalUser(
        id: _currentUser!.id,
        email: _currentUser!.email,
        displayName: displayName ?? _currentUser!.displayName,
        createdAt: _currentUser!.createdAt,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentUserKey, json.encode(updatedUser.toJson()));

      _currentUser = updatedUser;
      _authStateController.add(updatedUser);

      debugPrint('✅ Profile updated');
    } catch (e) {
      debugPrint('❌ Update profile error: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _authStateController.close();
  }
}
