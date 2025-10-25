// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  ChildProfile? _currentChild;

  bool get isAuthenticated => _isAuthenticated;
  ChildProfile? get currentChild => _currentChild;

  void setAuthenticated(bool value) {
    _isAuthenticated = value;
    notifyListeners();
  }

  void setCurrentChild(ChildProfile? child) {
    _currentChild = child;
    notifyListeners();
  }
}