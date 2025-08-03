// lib/services/offline_service.dart
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import '../services/firebase_service.dart';

class OfflineService {
  static const String _diaryBox = 'diary_entries';
  static const String _activitiesBox = 'activities';
  static const String _childrenBox = 'children';
  static const String _measurementsBox = 'measurements';
  static const String _storiesBox = 'stories';
  
  static late Box<Map> _diaryEntries;
  static late Box<Map> _activities;
  static late Box<Map> _children;
  static late Box<Map> _measurements;
  static late Box<Map> _stories;

  // Инициализация Hive
  static Future<void> initialize() async {
    await Hive.initFlutter();
    
    // Открываем все боксы
    _diaryEntries = await Hive.openBox<Map>(_diaryBox);
    _activities = await Hive.openBox<Map>(_activitiesBox);
    _children = await Hive.openBox<Map>(_childrenBox);
    _measurements = await Hive.openBox<Map>(_measurementsBox);
    _stories = await Hive.openBox<Map>(_storiesBox);
    
    debugPrint('✅ OfflineService initialized');
  }

  // ===== ДНЕВНИК РАЗВИТИЯ =====

  // Сохранить запись дневника offline
  static Future<void> saveDiaryEntryOffline(DiaryEntry entry) async {
    final data = entry.toJson();
    data['id'] = entry.id.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : entry.id;
    data['synced'] = false;
    
    await _diaryEntries.put(data['id'], data);
    debugPrint('📝 Diary entry saved offline: ${data['id']}');
  }

  // Получить записи дневника offline
  static List<DiaryEntry> getDiaryEntriesOffline(String childId) {
    final entries = <DiaryEntry>[];
    
    for (final data in _diaryEntries.values) {
      if (data['childId'] == childId) {
        entries.add(DiaryEntry.fromJson(Map<String, dynamic>.from(data)));
      }
    }
    
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  // Получить несинхронизированные записи дневника
  static List<Map<String, dynamic>> getUnsyncedDiaryEntries() {
    final unsyncedEntries = <Map<String, dynamic>>[];
    
    for (final data in _diaryEntries.values) {
      if (data['synced'] == false) {
        unsyncedEntries.add(Map<String, dynamic>.from(data));
      }
    }
    
    return unsyncedEntries;
  }

  // Отметить запись как синхронизированную
  static Future<void> markDiaryEntrySynced(String entryId) async {
    final data = _diaryEntries.get(entryId);
    if (data != null) {
      data['synced'] = true;
      await _diaryEntries.put(entryId, data);
    }
  }

  // ===== АКТИВНОСТИ =====

  // Сохранить активность offline
  static Future<void> saveActivityOffline(Activity activity) async {
    final data = activity.toJson();
    data['id'] = activity.id.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : activity.id;
    data['synced'] = false;
    
    await _activities.put(data['id'], data);
    debugPrint('🏃 Activity saved offline: ${data['id']}');
  }

  // Получить активности offline
  static List<Activity> getActivitiesOffline(String childId, DateTime date) {
    final activities = <Activity>[];
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    
    for (final data in _activities.values) {
      if (data['childId'] == childId) {
        final startTime = DateTime.fromMillisecondsSinceEpoch(data['startTime']);
        if (startTime.isAfter(startOfDay) && startTime.isBefore(endOfDay)) {
          activities.add(Activity.fromJson(Map<String, dynamic>.from(data)));
        }
      }
    }
    
    activities.sort((a, b) => a.startTime.compareTo(b.startTime));
    return activities;
  }

  // Получить несинхронизированные активности
  static List<Map<String, dynamic>> getUnsyncedActivities() {
    final unsyncedActivities = <Map<String, dynamic>>[];
    
    for (final data in _activities.values) {
      if (data['synced'] == false) {
        unsyncedActivities.add(Map<String, dynamic>.from(data));
      }
    }
    
    return unsyncedActivities;
  }

  // Отметить активность как синхронизированную
  static Future<void> markActivitySynced(String activityId) async {
    final data = _activities.get(activityId);
    if (data != null) {
      data['synced'] = true;
      await _activities.put(activityId, data);
    }
  }

  // ===== ДЕТИ =====

  // Сохранить профили детей offline
  static Future<void> saveChildrenOffline(List<ChildProfile> children) async {
    await _children.clear();
    
    for (final child in children) {
      final data = {
        'id': child.id,
        'name': child.name,
        'birthDate': child.birthDate.millisecondsSinceEpoch,
        'gender': child.gender,
        'height': child.height,
        'weight': child.weight,
        'photoURL': child.photoURL,
        'vocabularySize': child.vocabularySize,
      };
      
      await _children.put(child.id, data);
    }
    
    debugPrint('👶 ${children.length} children saved offline');
  }

  // Получить профили детей offline
  static List<ChildProfile> getChildrenOffline() {
    final children = <ChildProfile>[];
    
    for (final data in _children.values) {
      children.add(ChildProfile(
        id: data['id'] ?? '',
        name: data['name'] ?? '',
        birthDate: DateTime.fromMillisecondsSinceEpoch(data['birthDate'] ?? 0),
        gender: data['gender'] ?? 'male',
        height: (data['height'] ?? 0.0).toDouble(),
        weight: (data['weight'] ?? 0.0).toDouble(),
        photoURL: data['photoURL'],
        petName: data['petName'] ?? 'Питомец',
        petType: data['petType'] ?? 'cat',
        petStats: Map<String, int>.from(data['petStats'] ?? {}),
        milestones: Map<String, dynamic>.from(data['milestones'] ?? {}),
        vocabularySize: data['vocabularySize'] ?? 0,
        createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] ?? DateTime.now().millisecondsSinceEpoch),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(data['updatedAt'] ?? DateTime.now().millisecondsSinceEpoch),
      ));
    }
    
    return children;
  }

  // ===== ИЗМЕРЕНИЯ =====

  // Сохранить измерение offline
  static Future<void> saveMeasurementOffline(GrowthMeasurement measurement) async {
    final data = measurement.toJson();
    data['id'] = measurement.id.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : measurement.id;
    data['synced'] = false;
    
    await _measurements.put(data['id'], data);
    debugPrint('📏 Measurement saved offline: ${data['id']}');
  }

  // Получить измерения offline
  static List<GrowthMeasurement> getMeasurementsOffline(String childId) {
    final measurements = <GrowthMeasurement>[];
    
    for (final data in _measurements.values) {
      if (data['childId'] == childId) {
        measurements.add(GrowthMeasurement.fromJson(Map<String, dynamic>.from(data)));
      }
    }
    
    measurements.sort((a, b) => b.date.compareTo(a.date));
    return measurements;
  }

  // Получить несинхронизированные измерения
  static List<Map<String, dynamic>> getUnsyncedMeasurements() {
    final unsyncedMeasurements = <Map<String, dynamic>>[];
    
    for (final data in _measurements.values) {
      if (data['synced'] == false) {
        unsyncedMeasurements.add(Map<String, dynamic>.from(data));
      }
    }
    
    return unsyncedMeasurements;
  }

  // Отметить измерение как синхронизированное
  static Future<void> markMeasurementSynced(String measurementId) async {
    final data = _measurements.get(measurementId);
    if (data != null) {
      data['synced'] = true;
      await _measurements.put(measurementId, data);
    }
  }

  // ===== ИСТОРИИ =====

  // Сохранить сказку offline
  static Future<void> saveStoryOffline(String childId, String theme, String story) async {
    final data = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'childId': childId,
      'theme': theme,
      'story': story,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'isFavorite': false,
    };
    
    await _stories.put(data['id'], data);
    debugPrint('📚 Story saved offline: ${data['id']}');
  }

  // Получить сказки offline
  static List<Map<String, dynamic>> getStoriesOffline(String childId) {
    final stories = <Map<String, dynamic>>[];
    
    for (final data in _stories.values) {
      if (data['childId'] == childId) {
        stories.add(Map<String, dynamic>.from(data));
      }
    }
    
    stories.sort((a, b) => (b['createdAt'] ?? 0).compareTo(a['createdAt'] ?? 0));
    return stories;
  }

  // ===== СИНХРОНИЗАЦИЯ =====

  // Синхронизировать все offline данные с Firebase
  static Future<void> syncAllData() async {
    debugPrint('🔄 Starting offline data sync...');
    
    try {
      // Синхронизация записей дневника
      await _syncDiaryEntries();
      
      // Синхронизация активностей  
      await _syncActivities();
      
      // Синхронизация измерений
      await _syncMeasurements();
      
      debugPrint('✅ Offline data sync completed');
    } catch (e) {
      debugPrint('❌ Offline data sync failed: $e');
    }
  }

  // Синхронизировать записи дневника
  static Future<void> _syncDiaryEntries() async {
    final unsyncedEntries = getUnsyncedDiaryEntries();
    
    for (final entryData in unsyncedEntries) {
      try {
        final entry = DiaryEntry.fromJson(entryData);
        final newId = await FirebaseService.createDiaryEntry(entry);
        await markDiaryEntrySynced(entryData['id']);
        debugPrint('📝 Synced diary entry: ${entryData['id']} -> $newId');
      } catch (e) {
        debugPrint('❌ Failed to sync diary entry ${entryData['id']}: $e');
      }
    }
  }

  // Синхронизировать активности
  static Future<void> _syncActivities() async {
    final unsyncedActivities = getUnsyncedActivities();
    
    for (final activityData in unsyncedActivities) {
      try {
        final activity = Activity.fromJson(activityData);
        final newId = await FirebaseService.createActivity(activity);
        await markActivitySynced(activityData['id']);
        debugPrint('🏃 Synced activity: ${activityData['id']} -> $newId');
      } catch (e) {
        debugPrint('❌ Failed to sync activity ${activityData['id']}: $e');
      }
    }
  }

  // Синхронизировать измерения
  static Future<void> _syncMeasurements() async {
    final unsyncedMeasurements = getUnsyncedMeasurements();
    
    for (final measurementData in unsyncedMeasurements) {
      try {
        final measurement = GrowthMeasurement.fromJson(measurementData);
        final newId = await FirebaseService.addGrowthMeasurement(measurement);
        await markMeasurementSynced(measurementData['id']);
        debugPrint('📏 Synced measurement: ${measurementData['id']} -> $newId');
      } catch (e) {
        debugPrint('❌ Failed to sync measurement ${measurementData['id']}: $e');
      }
    }
  }

  // ===== СТАТИСТИКА =====

  // Получить количество несинхронизированных данных
  static Map<String, int> getUnsyncedDataCount() {
    return {
      'diary': getUnsyncedDiaryEntries().length,
      'activities': getUnsyncedActivities().length,
      'measurements': getUnsyncedMeasurements().length,
    };
  }

  // Очистить все offline данные
  static Future<void> clearAllOfflineData() async {
    await _diaryEntries.clear();
    await _activities.clear();
    await _children.clear();
    await _measurements.clear();
    await _stories.clear();
    
    debugPrint('🗑️ All offline data cleared');
  }

  // Получить размер offline данных
  static Future<Map<String, int>> getOfflineDataSize() async {
    return {
      'diary': _diaryEntries.length,
      'activities': _activities.length,
      'children': _children.length,
      'measurements': _measurements.length,
      'stories': _stories.length,
    };
  }
}