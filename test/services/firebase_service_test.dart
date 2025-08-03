// test/services/firebase_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:master_parenthood/services/firebase_service.dart';

void main() {
  group('ChildProfile', () {
    test('should calculate age in months correctly', () {
      final birthDate = DateTime(2022, 1, 1);
      final child = ChildProfile(
        id: 'test',
        name: 'Test Child',
        birthDate: birthDate,
        gender: 'male',
        height: 75.0,
        weight: 10.0,
        petName: 'TestPet',
        petType: 'cat',
        petStats: {},
        milestones: {},
        vocabularySize: 50,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Проверяем расчет возраста (примерно)
      expect(child.ageInMonths, greaterThan(20));
      expect(child.ageInMonths, lessThan(50));
    });

    test('should calculate age in days correctly', () {
      final birthDate = DateTime.now().subtract(const Duration(days: 100));
      final child = ChildProfile(
        id: 'test',
        name: 'Test Child',
        birthDate: birthDate,
        gender: 'female',
        height: 65.0,
        weight: 8.0,
        petName: 'TestPet',
        petType: 'dog',
        petStats: {},
        milestones: {},
        vocabularySize: 30,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(child.ageInDays, equals(100));
    });

    test('should format age correctly for different ages', () {
      // 6 месяцев
      final child6Months = ChildProfile(
        id: 'test',
        name: 'Test Child',
        birthDate: DateTime.now().subtract(const Duration(days: 180)),
        gender: 'male',
        height: 65.0,
        weight: 8.0,
        petName: 'TestPet',
        petType: 'cat',
        petStats: {},
        milestones: {},
        vocabularySize: 20,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(child6Months.ageFormattedShort, contains('мес.'));

      // 1 год
      final child1Year = ChildProfile(
        id: 'test',
        name: 'Test Child',
        birthDate: DateTime.now().subtract(const Duration(days: 365)),
        gender: 'female',
        height: 75.0,
        weight: 10.0,
        petName: 'TestPet',
        petType: 'dog',
        petStats: {},
        milestones: {},
        vocabularySize: 50,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(child1Year.ageFormattedShort, equals('1 год'));

      // 2 года
      final child2Years = ChildProfile(
        id: 'test',
        name: 'Test Child',
        birthDate: DateTime.now().subtract(const Duration(days: 730)),
        gender: 'male',
        height: 85.0,
        weight: 12.0,
        petName: 'TestPet',
        petType: 'cat',
        petStats: {},
        milestones: {},
        vocabularySize: 100,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(child2Years.ageFormattedShort, contains('года'));

      // 5 лет
      final child5Years = ChildProfile(
        id: 'test',
        name: 'Test Child',
        birthDate: DateTime.now().subtract(const Duration(days: 1825)),
        gender: 'female',
        height: 110.0,
        weight: 18.0,
        petName: 'TestPet',
        petType: 'dog',
        petStats: {},
        milestones: {},
        vocabularySize: 500,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(child5Years.ageFormattedShort, contains('лет'));
    });
  });

  group('DiaryEntry', () {
    test('should create diary entry with correct data', () {
      final entry = DiaryEntry(
        id: 'test-id',
        childId: 'child-id',
        title: 'Test Entry',
        content: 'Test content',
        date: DateTime.now(),
        type: DiaryEntryType.milestone,
        photos: ['photo1.jpg', 'photo2.jpg'],
      );

      expect(entry.id, equals('test-id'));
      expect(entry.childId, equals('child-id'));
      expect(entry.title, equals('Test Entry'));
      expect(entry.content, equals('Test content'));
      expect(entry.type, equals(DiaryEntryType.milestone));
      expect(entry.photos.length, equals(2));
    });

    test('should convert to JSON correctly', () {
      final entry = DiaryEntry(
        id: 'test-id',
        childId: 'child-id',
        title: 'Test Entry',
        content: 'Test content',
        date: DateTime(2023, 1, 1, 12, 0, 0),
        type: DiaryEntryType.development,
        photos: ['photo1.jpg'],
      );

      final json = entry.toJson();

      expect(json['id'], equals('test-id'));
      expect(json['childId'], equals('child-id'));
      expect(json['title'], equals('Test Entry'));
      expect(json['content'], equals('Test content'));
      expect(json['type'], equals('development'));
      expect(json['photos'], equals(['photo1.jpg']));
    });

    test('should create from JSON correctly', () {
      final json = {
        'id': 'test-id',
        'childId': 'child-id',
        'title': 'Test Entry',
        'content': 'Test content',
        'date': DateTime(2023, 1, 1, 12, 0, 0),
        'type': 'daily',
        'photos': ['photo1.jpg', 'photo2.jpg'],
      };

      final entry = DiaryEntry.fromJson(json);

      expect(entry.id, equals('test-id'));
      expect(entry.childId, equals('child-id'));
      expect(entry.title, equals('Test Entry'));
      expect(entry.content, equals('Test content'));
      expect(entry.type, equals(DiaryEntryType.daily));
      expect(entry.photos.length, equals(2));
    });
  });

  group('Activity', () {
    test('should create activity with correct data', () {
      final startTime = DateTime.now();
      final endTime = startTime.add(const Duration(hours: 2));

      final activity = Activity(
        id: 'test-id',
        childId: 'child-id',
        type: ActivityType.sleep,
        startTime: startTime,
        endTime: endTime,
        notes: 'Good sleep',
        mood: Mood.happy,
      );

      expect(activity.id, equals('test-id'));
      expect(activity.childId, equals('child-id'));
      expect(activity.type, equals(ActivityType.sleep));
      expect(activity.startTime, equals(startTime));
      expect(activity.endTime, equals(endTime));
      expect(activity.notes, equals('Good sleep'));
      expect(activity.mood, equals(Mood.happy));
    });

    test('should convert to JSON correctly', () {
      final startTime = DateTime(2023, 1, 1, 10, 0, 0);
      final endTime = DateTime(2023, 1, 1, 12, 0, 0);

      final activity = Activity(
        id: 'test-id',
        childId: 'child-id',
        type: ActivityType.feeding,
        startTime: startTime,
        endTime: endTime,
        notes: 'Breakfast',
        mood: Mood.excited,
      );

      final json = activity.toJson();

      expect(json['id'], equals('test-id'));
      expect(json['childId'], equals('child-id'));
      expect(json['type'], equals('feeding'));
      expect(json['notes'], equals('Breakfast'));
      expect(json['mood'], equals('excited'));
    });

    test('should create from JSON correctly', () {
      final json = {
        'id': 'test-id',
        'childId': 'child-id',
        'type': 'walk',
        'startTime': DateTime(2023, 1, 1, 14, 0, 0).millisecondsSinceEpoch,
        'endTime': DateTime(2023, 1, 1, 15, 0, 0).millisecondsSinceEpoch,
        'notes': 'Park walk',
        'mood': 'calm',
      };

      final activity = Activity.fromJson(json);

      expect(activity.id, equals('test-id'));
      expect(activity.childId, equals('child-id'));
      expect(activity.type, equals(ActivityType.walk));
      expect(activity.notes, equals('Park walk'));
      expect(activity.mood, equals(Mood.calm));
    });

    test('should handle missing endTime', () {
      final json = {
        'id': 'test-id',
        'childId': 'child-id',
        'type': 'play',
        'startTime': DateTime(2023, 1, 1, 16, 0, 0).millisecondsSinceEpoch,
        'endTime': null,
        'notes': 'Playing with toys',
        'mood': 'happy',
      };

      final activity = Activity.fromJson(json);

      expect(activity.endTime, isNull);
      expect(activity.type, equals(ActivityType.play));
      expect(activity.mood, equals(Mood.happy));
    });
  });

  group('GrowthMeasurement', () {
    test('should create measurement with correct data', () {
      final date = DateTime.now();
      final measurement = GrowthMeasurement(
        id: 'test-id',
        childId: 'child-id',
        date: date,
        height: 75.5,
        weight: 10.2,
        notes: 'Regular checkup',
      );

      expect(measurement.id, equals('test-id'));
      expect(measurement.childId, equals('child-id'));
      expect(measurement.date, equals(date));
      expect(measurement.height, equals(75.5));
      expect(measurement.weight, equals(10.2));
      expect(measurement.notes, equals('Regular checkup'));
    });

    test('should convert to JSON correctly', () {
      final date = DateTime(2023, 1, 1);
      final measurement = GrowthMeasurement(
        id: 'test-id',
        childId: 'child-id',
        date: date,
        height: 80.0,
        weight: 11.5,
        notes: 'Monthly measurement',
      );

      final json = measurement.toJson();

      expect(json['id'], equals('test-id'));
      expect(json['childId'], equals('child-id'));
      expect(json['height'], equals(80.0));
      expect(json['weight'], equals(11.5));
      expect(json['notes'], equals('Monthly measurement'));
    });

    test('should create from JSON correctly', () {
      final json = {
        'id': 'test-id',
        'childId': 'child-id',
        'date': DateTime(2023, 1, 1),
        'height': 85.0,
        'weight': 12.8,
        'notes': 'Growth spurt',
      };

      final measurement = GrowthMeasurement.fromJson(json);

      expect(measurement.id, equals('test-id'));
      expect(measurement.childId, equals('child-id'));
      expect(measurement.height, equals(85.0));
      expect(measurement.weight, equals(12.8));
      expect(measurement.notes, equals('Growth spurt'));
    });
  });
}