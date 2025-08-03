// test/services/sync_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:master_parenthood/services/sync_service.dart';

void main() {
  group('SyncService', () {
    group('SyncResult', () {
      test('should create sync result with correct data', () {
        final result = SyncResult(
          success: true,
          message: 'Sync completed successfully',
          syncedCount: 5,
        );

        expect(result.success, isTrue);
        expect(result.message, equals('Sync completed successfully'));
        expect(result.syncedCount, equals(5));
      });

      test('should create failed sync result', () {
        final result = SyncResult(
          success: false,
          message: 'Network error',
          syncedCount: 0,
        );

        expect(result.success, isFalse);
        expect(result.message, equals('Network error'));
        expect(result.syncedCount, equals(0));
      });
    });

    group('SyncStatus', () {
      test('should create sync status with correct data', () {
        final status = SyncStatus(
          isSyncing: false,
          totalUnsyncedItems: 3,
          unsyncedBreakdown: {
            'diary': 1,
            'activities': 2,
            'measurements': 0,
          },
        );

        expect(status.isSyncing, isFalse);
        expect(status.totalUnsyncedItems, equals(3));
        expect(status.hasUnsyncedData, isTrue);
        expect(status.unsyncedBreakdown['diary'], equals(1));
        expect(status.unsyncedBreakdown['activities'], equals(2));
      });

      test('should detect when no unsynced data exists', () {
        final status = SyncStatus(
          isSyncing: false,
          totalUnsyncedItems: 0,
          unsyncedBreakdown: {
            'diary': 0,
            'activities': 0,
            'measurements': 0,
          },
        );

        expect(status.hasUnsyncedData, isFalse);
        expect(status.totalUnsyncedItems, equals(0));
      });

      test('should show syncing state correctly', () {
        final status = SyncStatus(
          isSyncing: true,
          totalUnsyncedItems: 5,
          unsyncedBreakdown: {
            'diary': 2,
            'activities': 3,
            'measurements': 0,
          },
        );

        expect(status.isSyncing, isTrue);
        expect(status.hasUnsyncedData, isTrue);
      });
    });

    group('OfflineDataInfo', () {
      test('should create offline data info with correct totals', () {
        final info = OfflineDataInfo(
          totalItems: 10,
          breakdown: {
            'diary': 4,
            'activities': 3,
            'children': 2,
            'measurements': 1,
            'stories': 0,
          },
        );

        expect(info.totalItems, equals(10));
        expect(info.breakdown['diary'], equals(4));
        expect(info.breakdown['activities'], equals(3));
        expect(info.breakdown['children'], equals(2));
        expect(info.breakdown['measurements'], equals(1));
        expect(info.breakdown['stories'], equals(0));
      });

      test('should handle empty offline data', () {
        final info = OfflineDataInfo(
          totalItems: 0,
          breakdown: {
            'diary': 0,
            'activities': 0,
            'children': 0,
            'measurements': 0,
            'stories': 0,
          },
        );

        expect(info.totalItems, equals(0));
        expect(info.breakdown.values.every((count) => count == 0), isTrue);
      });
    });

    // Примечание: Тесты для фактических методов SyncService требуют
    // моки Firebase и других сервисов, что выходит за рамки базового тестирования
    // В реальном проекте стоит добавить integration тесты или использовать моки
  });
}