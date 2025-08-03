// lib/services/connectivity_service.dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityService extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  
  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  
  ConnectivityResult get connectionStatus => _connectionStatus;
  
  bool get isOnline => _connectionStatus != ConnectivityResult.none;
  
  bool get isOffline => _connectionStatus == ConnectivityResult.none;
  
  bool get hasInternet => _connectionStatus != ConnectivityResult.none;
  
  ConnectivityService() {
    _initConnectivity();
  }
  
  Future<void> _initConnectivity() async {
    try {
      _connectionStatus = await _connectivity.checkConnectivity();
    } catch (e) {
      debugPrint('Could not check connectivity status: $e');
    }
    
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
    
    notifyListeners();
  }
  
  void _updateConnectionStatus(ConnectivityResult result) {
    _connectionStatus = result;
    notifyListeners();
  }
  
  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }
}