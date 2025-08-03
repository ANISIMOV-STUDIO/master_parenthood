// lib/services/sync_service.dart
import 'package:flutter/foundation.dart';
import '../services/connectivity_service.dart';
import '../services/offline_service.dart';

class SyncService {
  static bool _isInitialized = false;
  static bool _isSyncing = false;
  
  // Инициализация сервиса синхронизации
  static void initialize(ConnectivityService connectivityService) {
    if (_isInitialized) return;
    
    // Слушаем изменения соединения
    connectivityService.addListener(() {
      if (connectivityService.hasInternet && !_isSyncing) {
        _performAutoSync();
      }
    });
    
    _isInitialized = true;
    debugPrint('✅ SyncService initialized');
  }

  // Выполнить автоматическую синхронизацию
  static Future<void> _performAutoSync() async {
    if (_isSyncing) return;
    
    _isSyncing = true;
    debugPrint('🔄 Starting auto sync...');
    
    try {
      final unsyncedCount = OfflineService.getUnsyncedDataCount();
      final totalUnsynced = unsyncedCount.values.fold(0, (sum, count) => sum + count);
      
      if (totalUnsynced > 0) {
        debugPrint('📊 Found $totalUnsynced unsynced items');
        await OfflineService.syncAllData();
        debugPrint('✅ Auto sync completed');
      } else {
        debugPrint('✅ No data to sync');
      }
    } catch (e) {
      debugPrint('❌ Auto sync failed: $e');
    } finally {
      _isSyncing = false;
    }
  }

  // Принудительная синхронизация
  static Future<SyncResult> forcSync() async {
    if (_isSyncing) {
      return SyncResult(
        success: false,
        message: 'Синхронизация уже выполняется',
        syncedCount: 0,
      );
    }
    
    _isSyncing = true;
    
    try {
      final unsyncedCount = OfflineService.getUnsyncedDataCount();
      final totalUnsynced = unsyncedCount.values.fold(0, (sum, count) => sum + count);
      
      if (totalUnsynced == 0) {
        return SyncResult(
          success: true,
          message: 'Все данные уже синхронизированы',
          syncedCount: 0,
        );
      }
      
      await OfflineService.syncAllData();
      
      return SyncResult(
        success: true,
        message: 'Синхронизация завершена успешно',
        syncedCount: totalUnsynced,
      );
    } catch (e) {
      return SyncResult(
        success: false,
        message: 'Ошибка синхронизации: ${e.toString()}',
        syncedCount: 0,
      );
    } finally {
      _isSyncing = false;
    }
  }

  // Получить статус синхронизации
  static SyncStatus getSyncStatus() {
    final unsyncedCount = OfflineService.getUnsyncedDataCount();
    final totalUnsynced = unsyncedCount.values.fold(0, (sum, count) => sum + count);
    
    return SyncStatus(
      isSyncing: _isSyncing,
      totalUnsyncedItems: totalUnsynced,
      unsyncedBreakdown: unsyncedCount,
    );
  }

  // Очистить все offline данные
  static Future<void> clearOfflineData() async {
    await OfflineService.clearAllOfflineData();
    debugPrint('🗑️ All offline data cleared by user');
  }

  // Получить информацию о размере offline данных
  static Future<OfflineDataInfo> getOfflineDataInfo() async {
    final dataSizes = await OfflineService.getOfflineDataSize();
    final totalItems = dataSizes.values.fold(0, (sum, count) => sum + count);
    
    return OfflineDataInfo(
      totalItems: totalItems,
      breakdown: dataSizes,
    );
  }
}

// Результат синхронизации
class SyncResult {
  final bool success;
  final String message;
  final int syncedCount;

  SyncResult({
    required this.success,
    required this.message,
    required this.syncedCount,
  });
}

// Статус синхронизации
class SyncStatus {
  final bool isSyncing;
  final int totalUnsyncedItems;
  final Map<String, int> unsyncedBreakdown;

  SyncStatus({
    required this.isSyncing,
    required this.totalUnsyncedItems,
    required this.unsyncedBreakdown,
  });

  bool get hasUnsyncedData => totalUnsyncedItems > 0;
}

// Информация о offline данных
class OfflineDataInfo {
  final int totalItems;
  final Map<String, int> breakdown;

  OfflineDataInfo({
    required this.totalItems,
    required this.breakdown,
  });
}