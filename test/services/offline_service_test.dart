// test/services/offline_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:master_parenthood/services/offline_service.dart';
import 'package:master_parenthood/services/firebase_service.dart';

void main() {
  group('OfflineService', () {
    setUpAll(() async {
      // Инициализируем Hive для тестов
      await Hive.initFlutter();
    });

    tearDownAll(() async {
      // Очищаем после тестов
      await Hive.deleteFromDisk();
    });

    group('Diary Entries', () {
      test('should save and retrieve diary entry offline', () async {
        await OfflineService.initialize();

        final entry = DiaryEntry(
          id: 'test-entry-1',
          childId: 'child-1',
          title: 'Test Entry',
          content: 'Test content',
          date: DateTime.now(),
          type: DiaryEntryType.milestone,
          photos: ['photo1.jpg'],
        );

        // Сохраняем offline
        await OfflineService.saveDiaryEntryOffline(entry);

        // Получаем обратно
        final retrievedEntries = OfflineService.getDiaryEntriesOffline('child-1');

        expect(retrievedEntries.length, equals(1));
        expect(retrievedEntries.first.title, equals('Test Entry'));
        expect(retrievedEntries.first.type, equals(DiaryEntryType.milestone));
      });

      test('should track unsynced diary entries', () async {
        await OfflineService.initialize();

        final entry = DiaryEntry(
          id: 'test-entry-2',
          childId: 'child-1',
          title: 'Unsynced Entry',
          content: 'Test content',
          date: DateTime.now(),
          type: DiaryEntryType.daily,
          photos: [],
        );

        await OfflineService.saveDiaryEntryOffline(entry);

        final unsyncedEntries = OfflineService.getUnsyncedDiaryEntries();
        expect(unsyncedEntries.length, greaterThanOrEqualTo(1));

        final testEntry = unsyncedEntries.firstWhere(
          (e) => e['title'] == 'Unsynced Entry',
          orElse: () => {},
        );
        expect(testEntry['synced'], equals(false));

        // Отмечаем как синхронизированную
        await OfflineService.markDiaryEntrySynced(testEntry['id']);

        final updatedUnsyncedEntries = OfflineService.getUnsyncedDiaryEntries();
        final stillUnsynced = updatedUnsyncedEntries.where(
          (e) => e['id'] == testEntry['id'],
        );
        expect(stillUnsynced.length, equals(0));
      });
    });

    group('Activities', () {
      test('should save and retrieve activity offline', () async {
        await OfflineService.initialize();

        final activity = Activity(
          id: 'test-activity-1',
          childId: 'child-1',
          type: ActivityType.sleep,
          startTime: DateTime.now(),
          endTime: DateTime.now().add(const Duration(hours: 2)),
          notes: 'Good sleep',
          mood: Mood.happy,
        );

        await OfflineService.saveActivityOffline(activity);

        final retrievedActivities = OfflineService.getActivitiesOffline(
          'child-1', 
          DateTime.now(),
        );

        expect(retrievedActivities.length, equals(1));
        expect(retrievedActivities.first.type, equals(ActivityType.sleep));
        expect(retrievedActivities.first.mood, equals(Mood.happy));
      });

      test('should filter activities by date', () async {
        await OfflineService.initialize();

        final today = DateTime.now();
        final yesterday = today.subtract(const Duration(days: 1));

        final todayActivity = Activity(
          id: 'today-activity',
          childId: 'child-1',
          type: ActivityType.feeding,
          startTime: today,
          notes: 'Today feeding',
          mood: Mood.happy,
        );

        final yesterdayActivity = Activity(
          id: 'yesterday-activity',
          childId: 'child-1',
          type: ActivityType.walk,
          startTime: yesterday,
          notes: 'Yesterday walk',
          mood: Mood.excited,
        );

        await OfflineService.saveActivityOffline(todayActivity);
        await OfflineService.saveActivityOffline(yesterdayActivity);

        final todayActivities = OfflineService.getActivitiesOffline('child-1', today);
        final yesterdayActivities = OfflineService.getActivitiesOffline('child-1', yesterday);

        expect(todayActivities.length, equals(1));
        expect(todayActivities.first.notes, equals('Today feeding'));

        expect(yesterdayActivities.length, equals(1));
        expect(yesterdayActivities.first.notes, equals('Yesterday walk'));
      });
    });

    group('Children Profiles', () {
      test('should save and retrieve children profiles offline', () async {
        await OfflineService.initialize();

        final children = [
          ChildProfile(
            id: 'child-1',
            name: 'Alice',
            birthDate: DateTime(2022, 1, 1),
            gender: 'female',
            height: 75.0,
            weight: 10.0,
            petName: 'AlicePet',
            petType: 'cat',
            petStats: {},
            milestones: {},
            vocabularySize: 50,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          ChildProfile(
            id: 'child-2',
            name: 'Bob',
            birthDate: DateTime(2021, 6, 1),
            gender: 'male',
            height: 85.0,
            weight: 12.0,
            petName: 'BobPet',
            petType: 'dog',
            petStats: {},
            milestones: {},
            vocabularySize: 100,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        await OfflineService.saveChildrenOffline(children);

        final retrievedChildren = OfflineService.getChildrenOffline();

        expect(retrievedChildren.length, equals(2));
        expect(retrievedChildren.map((c) => c.name).toList(), containsAll(['Alice', 'Bob']));
      });
    });

    group('Growth Measurements', () {
      test('should save and retrieve measurements offline', () async {
        await OfflineService.initialize();

        final measurement = GrowthMeasurement(
          id: 'measurement-1',
          childId: 'child-1',
          date: DateTime.now(),
          height: 80.0,
          weight: 11.5,
          notes: 'Monthly checkup',
        );

        await OfflineService.saveMeasurementOffline(measurement);

        final retrievedMeasurements = OfflineService.getMeasurementsOffline('child-1');

        expect(retrievedMeasurements.length, equals(1));
        expect(retrievedMeasurements.first.height, equals(80.0));
        expect(retrievedMeasurements.first.weight, equals(11.5));
      });
    });

    group('Stories', () {
      test('should save and retrieve stories offline', () async {
        await OfflineService.initialize();

        await OfflineService.saveStoryOffline(
          'child-1',
          'Adventure',
          'Once upon a time...',
        );

        final retrievedStories = OfflineService.getStoriesOffline('child-1');

        expect(retrievedStories.length, equals(1));
        expect(retrievedStories.first['theme'], equals('Adventure'));
        expect(retrievedStories.first['story'], equals('Once upon a time...'));
      });
    });

    group('Data Statistics', () {
      test('should provide unsynced data count', () async {
        await OfflineService.initialize();

        // Добавляем несинхронизированные данные
        await OfflineService.saveDiaryEntryOffline(
          DiaryEntry(
            id: 'entry-1',
            childId: 'child-1',
            title: 'Test',
            content: 'Content',
            date: DateTime.now(),
            type: DiaryEntryType.daily,
            photos: [],
          ),
        );

        await OfflineService.saveActivityOffline(
          Activity(
            id: 'activity-1',
            childId: 'child-1',
            type: ActivityType.feeding,
            startTime: DateTime.now(),
            notes: 'Test',
            mood: Mood.happy,
          ),
        );

        final unsyncedCount = OfflineService.getUnsyncedDataCount();

        expect(unsyncedCount['diary'], greaterThanOrEqualTo(1));
        expect(unsyncedCount['activities'], greaterThanOrEqualTo(1));
      });

      test('should provide offline data size', () async {
        await OfflineService.initialize();

        final dataSize = await OfflineService.getOfflineDataSize();

        expect(dataSize, isA<Map<String, int>>());
        expect(dataSize.keys, containsAll(['diary', 'activities', 'children', 'measurements', 'stories']));
      });
    });

    group('Data Management', () {
      test('should clear all offline data', () async {
        await OfflineService.initialize();

        // Добавляем данные
        await OfflineService.saveDiaryEntryOffline(
          DiaryEntry(
            id: 'entry-to-clear',
            childId: 'child-1',
            title: 'Test',
            content: 'Content',
            date: DateTime.now(),
            type: DiaryEntryType.daily,
            photos: [],
          ),
        );

        // Проверяем, что данные есть
        final beforeClear = await OfflineService.getOfflineDataSize();
        expect(beforeClear['diary'], greaterThan(0));

        // Очищаем
        await OfflineService.clearAllOfflineData();

        // Проверяем, что данные удалены
        final afterClear = await OfflineService.getOfflineDataSize();
        expect(afterClear['diary'], equals(0));
      });
    });
  });
}