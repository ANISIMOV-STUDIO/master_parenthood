// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;

  bool get isAuthenticated => _isAuthenticated;

  void setAuthenticated(bool value) {
    _isAuthenticated = value;
    notifyListeners();
  }
}