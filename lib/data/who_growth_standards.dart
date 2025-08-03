// lib/data/who_growth_standards.dart
// Данные центильных таблиц ВОЗ для оценки физического развития детей

import '../services/firebase_service.dart';

/// Хранилище официальных данных ВОЗ по физическому развитию детей
/// Источник: WHO Child Growth Standards (2006)
class WHOGrowthStandards {
  
  // Данные роста для мальчиков (0-60 месяцев), см
  static final Map<int, WHOPercentileData> _heightBoys = {
    0: WHOPercentileData(ageMonths: 0, gender: 'male', measurementType: GrowthMeasurementType.height, p3: 46.1, p15: 48.0, p50: 49.9, p85: 51.8, p97: 53.7),
    1: WHOPercentileData(ageMonths: 1, gender: 'male', measurementType: GrowthMeasurementType.height, p3: 50.8, p15: 52.8, p50: 54.7, p85: 56.7, p97: 58.6),
    2: WHOPercentileData(ageMonths: 2, gender: 'male', measurementType: GrowthMeasurementType.height, p3: 54.4, p15: 56.4, p50: 58.4, p85: 60.4, p97: 62.4),
    3: WHOPercentileData(ageMonths: 3, gender: 'male', measurementType: GrowthMeasurementType.height, p3: 57.3, p15: 59.4, p50: 61.4, p85: 63.5, p97: 65.5),
    4: WHOPercentileData(ageMonths: 4, gender: 'male', measurementType: GrowthMeasurementType.height, p3: 59.7, p15: 61.8, p50: 63.9, p85: 66.0, p97: 68.0),
    5: WHOPercentileData(ageMonths: 5, gender: 'male', measurementType: GrowthMeasurementType.height, p3: 61.7, p15: 63.8, p50: 65.9, p85: 68.0, p97: 70.1),
    6: WHOPercentileData(ageMonths: 6, gender: 'male', measurementType: GrowthMeasurementType.height, p3: 63.3, p15: 65.5, p50: 67.6, p85: 69.8, p97: 71.9),
    12: WHOPercentileData(ageMonths: 12, gender: 'male', measurementType: GrowthMeasurementType.height, p3: 71.0, p15: 73.4, p50: 75.7, p85: 78.1, p97: 80.5),
    18: WHOPercentileData(ageMonths: 18, gender: 'male', measurementType: GrowthMeasurementType.height, p3: 76.9, p15: 79.6, p50: 82.3, p85: 85.0, p97: 87.7),
    24: WHOPercentileData(ageMonths: 24, gender: 'male', measurementType: GrowthMeasurementType.height, p3: 81.7, p15: 84.8, p50: 87.8, p85: 90.9, p97: 93.9),
    36: WHOPercentileData(ageMonths: 36, gender: 'male', measurementType: GrowthMeasurementType.height, p3: 88.7, p15: 92.4, p50: 96.1, p85: 99.8, p97: 103.5),
    48: WHOPercentileData(ageMonths: 48, gender: 'male', measurementType: GrowthMeasurementType.height, p3: 94.9, p15: 99.1, p50: 103.3, p85: 107.5, p97: 111.7),
    60: WHOPercentileData(ageMonths: 60, gender: 'male', measurementType: GrowthMeasurementType.height, p3: 100.7, p15: 105.3, p50: 110.0, p85: 114.6, p97: 119.2),
  };

  // Данные роста для девочек (0-60 месяцев), см
  static final Map<int, WHOPercentileData> _heightGirls = {
    0: WHOPercentileData(ageMonths: 0, gender: 'female', measurementType: GrowthMeasurementType.height, p3: 45.4, p15: 47.3, p50: 49.1, p85: 51.0, p97: 52.9),
    1: WHOPercentileData(ageMonths: 1, gender: 'female', measurementType: GrowthMeasurementType.height, p3: 49.8, p15: 51.7, p50: 53.7, p85: 55.6, p97: 57.6),
    2: WHOPercentileData(ageMonths: 2, gender: 'female', measurementType: GrowthMeasurementType.height, p3: 53.0, p15: 55.0, p50: 57.1, p85: 59.1, p97: 61.1),
    3: WHOPercentileData(ageMonths: 3, gender: 'female', measurementType: GrowthMeasurementType.height, p3: 55.6, p15: 57.7, p50: 59.8, p85: 61.9, p97: 64.0),
    4: WHOPercentileData(ageMonths: 4, gender: 'female', measurementType: GrowthMeasurementType.height, p3: 57.8, p15: 59.9, p50: 62.1, p85: 64.3, p97: 66.4),
    5: WHOPercentileData(ageMonths: 5, gender: 'female', measurementType: GrowthMeasurementType.height, p3: 59.6, p15: 61.8, p50: 64.0, p85: 66.2, p97: 68.5),
    6: WHOPercentileData(ageMonths: 6, gender: 'female', measurementType: GrowthMeasurementType.height, p3: 61.2, p15: 63.5, p50: 65.7, p85: 68.0, p97: 70.3),
    12: WHOPercentileData(ageMonths: 12, gender: 'female', measurementType: GrowthMeasurementType.height, p3: 68.9, p15: 71.4, p50: 74.0, p85: 76.6, p97: 79.2),
    18: WHOPercentileData(ageMonths: 18, gender: 'female', measurementType: GrowthMeasurementType.height, p3: 74.9, p15: 77.7, p50: 80.7, p85: 83.6, p97: 86.5),
    24: WHOPercentileData(ageMonths: 24, gender: 'female', measurementType: GrowthMeasurementType.height, p3: 80.0, p15: 83.2, p50: 86.4, p85: 89.6, p97: 92.9),
    36: WHOPercentileData(ageMonths: 36, gender: 'female', measurementType: GrowthMeasurementType.height, p3: 87.4, p15: 91.2, p50: 95.1, p85: 99.0, p97: 102.8),
    48: WHOPercentileData(ageMonths: 48, gender: 'female', measurementType: GrowthMeasurementType.height, p3: 94.1, p15: 98.4, p50: 102.7, p85: 107.0, p97: 111.3),
    60: WHOPercentileData(ageMonths: 60, gender: 'female', measurementType: GrowthMeasurementType.height, p3: 100.1, p15: 104.9, p50: 109.4, p85: 114.0, p97: 118.5),
  };

  // Данные веса для мальчиков (0-60 месяцев), кг
  static final Map<int, WHOPercentileData> _weightBoys = {
    0: WHOPercentileData(ageMonths: 0, gender: 'male', measurementType: GrowthMeasurementType.weight, p3: 2.5, p15: 2.9, p50: 3.3, p85: 3.9, p97: 4.4),
    1: WHOPercentileData(ageMonths: 1, gender: 'male', measurementType: GrowthMeasurementType.weight, p3: 3.4, p15: 3.9, p50: 4.5, p85: 5.1, p97: 5.8),
    2: WHOPercentileData(ageMonths: 2, gender: 'male', measurementType: GrowthMeasurementType.weight, p3: 4.3, p15: 4.9, p50: 5.6, p85: 6.3, p97: 7.1),
    3: WHOPercentileData(ageMonths: 3, gender: 'male', measurementType: GrowthMeasurementType.weight, p3: 5.0, p15: 5.7, p50: 6.4, p85: 7.2, p97: 8.0),
    4: WHOPercentileData(ageMonths: 4, gender: 'male', measurementType: GrowthMeasurementType.weight, p3: 5.6, p15: 6.2, p50: 7.0, p85: 7.8, p97: 8.7),
    5: WHOPercentileData(ageMonths: 5, gender: 'male', measurementType: GrowthMeasurementType.weight, p3: 6.0, p15: 6.7, p50: 7.5, p85: 8.4, p97: 9.3),
    6: WHOPercentileData(ageMonths: 6, gender: 'male', measurementType: GrowthMeasurementType.weight, p3: 6.4, p15: 7.1, p50: 7.9, p85: 8.8, p97: 9.8),
    12: WHOPercentileData(ageMonths: 12, gender: 'male', measurementType: GrowthMeasurementType.weight, p3: 7.7, p15: 8.6, p50: 9.6, p85: 10.8, p97: 12.0),
    18: WHOPercentileData(ageMonths: 18, gender: 'male', measurementType: GrowthMeasurementType.weight, p3: 8.8, p15: 9.8, p50: 11.0, p85: 12.4, p97: 13.9),
    24: WHOPercentileData(ageMonths: 24, gender: 'male', measurementType: GrowthMeasurementType.weight, p3: 9.7, p15: 10.8, p50: 12.2, p85: 13.8, p97: 15.5),
    36: WHOPercentileData(ageMonths: 36, gender: 'male', measurementType: GrowthMeasurementType.weight, p3: 11.3, p15: 12.7, p50: 14.3, p85: 16.2, p97: 18.3),
    48: WHOPercentileData(ageMonths: 48, gender: 'male', measurementType: GrowthMeasurementType.weight, p3: 12.8, p15: 14.5, p50: 16.3, p85: 18.6, p97: 21.2),
    60: WHOPercentileData(ageMonths: 60, gender: 'male', measurementType: GrowthMeasurementType.weight, p3: 14.1, p15: 16.0, p50: 18.3, p85: 20.9, p97: 24.0),
  };

  // Данные веса для девочек (0-60 месяцев), кг
  static final Map<int, WHOPercentileData> _weightGirls = {
    0: WHOPercentileData(ageMonths: 0, gender: 'female', measurementType: GrowthMeasurementType.weight, p3: 2.4, p15: 2.8, p50: 3.2, p85: 3.7, p97: 4.2),
    1: WHOPercentileData(ageMonths: 1, gender: 'female', measurementType: GrowthMeasurementType.weight, p3: 3.2, p15: 3.6, p50: 4.2, p85: 4.8, p97: 5.5),
    2: WHOPercentileData(ageMonths: 2, gender: 'female', measurementType: GrowthMeasurementType.weight, p3: 3.9, p15: 4.5, p50: 5.1, p85: 5.8, p97: 6.6),
    3: WHOPercentileData(ageMonths: 3, gender: 'female', measurementType: GrowthMeasurementType.weight, p3: 4.5, p15: 5.2, p50: 5.8, p85: 6.6, p97: 7.5),
    4: WHOPercentileData(ageMonths: 4, gender: 'female', measurementType: GrowthMeasurementType.weight, p3: 5.0, p15: 5.7, p50: 6.4, p85: 7.3, p97: 8.2),
    5: WHOPercentileData(ageMonths: 5, gender: 'female', measurementType: GrowthMeasurementType.weight, p3: 5.4, p15: 6.1, p50: 6.9, p85: 7.8, p97: 8.8),
    6: WHOPercentileData(ageMonths: 6, gender: 'female', measurementType: GrowthMeasurementType.weight, p3: 5.7, p15: 6.5, p50: 7.3, p85: 8.2, p97: 9.3),
    12: WHOPercentileData(ageMonths: 12, gender: 'female', measurementType: GrowthMeasurementType.weight, p3: 7.0, p15: 7.9, p50: 8.9, p85: 10.1, p97: 11.5),
    18: WHOPercentileData(ageMonths: 18, gender: 'female', measurementType: GrowthMeasurementType.weight, p3: 8.1, p15: 9.1, p50: 10.2, p85: 11.6, p97: 13.2),
    24: WHOPercentileData(ageMonths: 24, gender: 'female', measurementType: GrowthMeasurementType.weight, p3: 9.0, p15: 10.2, p50: 11.5, p85: 13.0, p97: 14.8),
    36: WHOPercentileData(ageMonths: 36, gender: 'female', measurementType: GrowthMeasurementType.weight, p3: 10.8, p15: 12.2, p50: 13.9, p85: 15.8, p97: 18.1),
    48: WHOPercentileData(ageMonths: 48, gender: 'female', measurementType: GrowthMeasurementType.weight, p3: 12.3, p15: 14.0, p50: 16.1, p85: 18.5, p97: 21.5),
    60: WHOPercentileData(ageMonths: 60, gender: 'female', measurementType: GrowthMeasurementType.weight, p3: 13.7, p15: 15.8, p50: 18.2, p85: 21.2, p97: 24.9),
  };

  // Данные окружности головы для мальчиков (0-60 месяцев), см
  static final Map<int, WHOPercentileData> _headCircumferenceBoys = {
    0: WHOPercentileData(ageMonths: 0, gender: 'male', measurementType: GrowthMeasurementType.headCircumference, p3: 32.6, p15: 33.9, p50: 35.0, p85: 36.1, p97: 37.2),
    1: WHOPercentileData(ageMonths: 1, gender: 'male', measurementType: GrowthMeasurementType.headCircumference, p3: 35.1, p15: 36.6, p50: 37.9, p85: 39.1, p97: 40.4),
    2: WHOPercentileData(ageMonths: 2, gender: 'male', measurementType: GrowthMeasurementType.headCircumference, p3: 36.8, p15: 38.4, p50: 39.8, p85: 41.2, p97: 42.6),
    3: WHOPercentileData(ageMonths: 3, gender: 'male', measurementType: GrowthMeasurementType.headCircumference, p3: 38.1, p15: 39.8, p50: 41.3, p85: 42.7, p97: 44.2),
    6: WHOPercentileData(ageMonths: 6, gender: 'male', measurementType: GrowthMeasurementType.headCircumference, p3: 40.9, p15: 42.6, p50: 44.2, p85: 45.8, p97: 47.4),
    12: WHOPercentileData(ageMonths: 12, gender: 'male', measurementType: GrowthMeasurementType.headCircumference, p3: 43.5, p15: 45.2, p50: 46.9, p85: 48.6, p97: 50.4),
    24: WHOPercentileData(ageMonths: 24, gender: 'male', measurementType: GrowthMeasurementType.headCircumference, p3: 45.5, p15: 47.3, p50: 49.0, p85: 50.8, p97: 52.6),
    36: WHOPercentileData(ageMonths: 36, gender: 'male', measurementType: GrowthMeasurementType.headCircumference, p3: 46.8, p15: 48.6, p50: 50.4, p85: 52.3, p97: 54.1),
    48: WHOPercentileData(ageMonths: 48, gender: 'male', measurementType: GrowthMeasurementType.headCircumference, p3: 47.8, p15: 49.7, p50: 51.5, p85: 53.4, p97: 55.3),
    60: WHOPercentileData(ageMonths: 60, gender: 'male', measurementType: GrowthMeasurementType.headCircumference, p3: 48.6, p15: 50.5, p50: 52.4, p85: 54.4, p97: 56.4),
  };

  // Данные окружности головы для девочек (0-60 месяцев), см
  static final Map<int, WHOPercentileData> _headCircumferenceGirls = {
    0: WHOPercentileData(ageMonths: 0, gender: 'female', measurementType: GrowthMeasurementType.headCircumference, p3: 32.0, p15: 33.3, p50: 34.5, p85: 35.7, p97: 36.9),
    1: WHOPercentileData(ageMonths: 1, gender: 'female', measurementType: GrowthMeasurementType.headCircumference, p3: 34.2, p15: 35.8, p50: 37.1, p85: 38.4, p97: 39.8),
    2: WHOPercentileData(ageMonths: 2, gender: 'female', measurementType: GrowthMeasurementType.headCircumference, p3: 35.8, p15: 37.5, p50: 39.0, p85: 40.5, p97: 42.0),
    3: WHOPercentileData(ageMonths: 3, gender: 'female', measurementType: GrowthMeasurementType.headCircumference, p3: 37.1, p15: 38.9, p50: 40.4, p85: 42.0, p97: 43.6),
    6: WHOPercentileData(ageMonths: 6, gender: 'female', measurementType: GrowthMeasurementType.headCircumference, p3: 39.8, p15: 41.7, p50: 43.3, p85: 45.0, p97: 46.8),
    12: WHOPercentileData(ageMonths: 12, gender: 'female', measurementType: GrowthMeasurementType.headCircumference, p3: 42.2, p15: 44.2, p50: 45.9, p85: 47.7, p97: 49.6),
    24: WHOPercentileData(ageMonths: 24, gender: 'female', measurementType: GrowthMeasurementType.headCircumference, p3: 44.2, p15: 46.2, p50: 48.1, p85: 50.0, p97: 51.9),
    36: WHOPercentileData(ageMonths: 36, gender: 'female', measurementType: GrowthMeasurementType.headCircumference, p3: 45.6, p15: 47.6, p50: 49.6, p85: 51.5, p97: 53.5),
    48: WHOPercentileData(ageMonths: 48, gender: 'female', measurementType: GrowthMeasurementType.headCircumference, p3: 46.6, p15: 48.6, p50: 50.7, p85: 52.7, p97: 54.8),
    60: WHOPercentileData(ageMonths: 60, gender: 'female', measurementType: GrowthMeasurementType.headCircumference, p3: 47.4, p15: 49.5, p50: 51.6, p85: 53.7, p97: 55.8),
  };

  /// Получить центильные данные для конкретного возраста, пола и типа измерения
  static WHOPercentileData? getPercentileData({
    required int ageMonths,
    required String gender,
    required GrowthMeasurementType measurementType,
  }) {
    // Ограничиваем возраст до 60 месяцев (5 лет)
    if (ageMonths > 60) return null;
    
    Map<int, WHOPercentileData>? dataMap;
    
    switch (measurementType) {
      case GrowthMeasurementType.height:
        dataMap = gender == 'male' ? _heightBoys : _heightGirls;
        break;
      case GrowthMeasurementType.weight:
        dataMap = gender == 'male' ? _weightBoys : _weightGirls;
        break;
      case GrowthMeasurementType.headCircumference:
        dataMap = gender == 'male' ? _headCircumferenceBoys : _headCircumferenceGirls;
        break;
      default:
        return null;
    }
    
    // Сначала ищем точное соответствие возраста
    if (dataMap.containsKey(ageMonths)) {
      return dataMap[ageMonths];
    }
    
    // Если точного соответствия нет, ищем ближайший младший возраст
    final sortedAges = dataMap.keys.toList()..sort();
    int? closestAge;
    
    for (final age in sortedAges) {
      if (age <= ageMonths) {
        closestAge = age;
      } else {
        break;
      }
    }
    
    return closestAge != null ? dataMap[closestAge] : null;
  }

  /// Получить интерполированные данные между двумя точками
  static WHOPercentileData? getInterpolatedData({
    required int ageMonths,
    required String gender,
    required GrowthMeasurementType measurementType,
  }) {
    if (ageMonths > 60) return null;
    
    Map<int, WHOPercentileData>? dataMap;
    
    switch (measurementType) {
      case GrowthMeasurementType.height:
        dataMap = gender == 'male' ? _heightBoys : _heightGirls;
        break;
      case GrowthMeasurementType.weight:
        dataMap = gender == 'male' ? _weightBoys : _weightGirls;
        break;
      case GrowthMeasurementType.headCircumference:
        dataMap = gender == 'male' ? _headCircumferenceBoys : _headCircumferenceGirls;
        break;
      default:
        return null;
    }
    
    // Точное соответствие
    if (dataMap.containsKey(ageMonths)) {
      return dataMap[ageMonths];
    }
    
    // Интерполяция между двумя ближайшими точками
    final sortedAges = dataMap.keys.toList()..sort();
    int? lowerAge, upperAge;
    
    for (int i = 0; i < sortedAges.length - 1; i++) {
      if (sortedAges[i] <= ageMonths && sortedAges[i + 1] > ageMonths) {
        lowerAge = sortedAges[i];
        upperAge = sortedAges[i + 1];
        break;
      }
    }
    
    if (lowerAge == null || upperAge == null) {
      // Если не можем интерполировать, возвращаем ближайшие данные
      return getPercentileData(
        ageMonths: ageMonths,
        gender: gender,
        measurementType: measurementType,
      );
    }
    
    final lowerData = dataMap[lowerAge]!;
    final upperData = dataMap[upperAge]!;
    
    // Линейная интерполяция
    final ratio = (ageMonths - lowerAge) / (upperAge - lowerAge);
    
    return WHOPercentileData(
      ageMonths: ageMonths,
      gender: gender,
      measurementType: measurementType,
      p3: lowerData.p3 + (upperData.p3 - lowerData.p3) * ratio,
      p15: lowerData.p15 + (upperData.p15 - lowerData.p15) * ratio,
      p50: lowerData.p50 + (upperData.p50 - lowerData.p50) * ratio,
      p85: lowerData.p85 + (upperData.p85 - lowerData.p85) * ratio,
      p97: lowerData.p97 + (upperData.p97 - lowerData.p97) * ratio,
    );
  }

  /// Получить оценку измерения относительно норм ВОЗ
  static String evaluateMeasurement({
    required double value,
    required int ageMonths,
    required String gender,
    required GrowthMeasurementType measurementType,
  }) {
    final percentileData = getInterpolatedData(
      ageMonths: ageMonths,
      gender: gender,
      measurementType: measurementType,
    );
    
    if (percentileData == null) {
      return 'Данные недоступны для данного возраста';
    }
    
    return percentileData.getAssessment(value);
  }

  /// Получить центиль для конкретного значения
  static int getPercentileForValue({
    required double value,
    required int ageMonths,
    required String gender,
    required GrowthMeasurementType measurementType,
  }) {
    final percentileData = getInterpolatedData(
      ageMonths: ageMonths,
      gender: gender,
      measurementType: measurementType,
    );
    
    if (percentileData == null) return 50; // Возвращаем средний центиль если данных нет
    
    return percentileData.getPercentile(value);
  }

  /// Получить все доступные возрасты для типа измерения
  static List<int> getAvailableAges(GrowthMeasurementType measurementType) {
    Map<int, WHOPercentileData> dataMap;
    
    switch (measurementType) {
      case GrowthMeasurementType.height:
        dataMap = _heightBoys;
        break;
      case GrowthMeasurementType.weight:
        dataMap = _weightBoys;
        break;
      case GrowthMeasurementType.headCircumference:
        dataMap = _headCircumferenceBoys;
        break;
      default:
        return [];
    }
    
    return dataMap.keys.toList()..sort();
  }

  /// Создать рекомендации на основе центиля
  static List<String> generateRecommendations({
    required double value,
    required int ageMonths,
    required String gender,
    required GrowthMeasurementType measurementType,
  }) {
    final percentile = getPercentileForValue(
      value: value,
      ageMonths: ageMonths,
      gender: gender,
      measurementType: measurementType,
    );
    
    final recommendations = <String>[];
    
    if (percentile < 3) {
      recommendations.addAll([
        'Показатель значительно ниже нормы',
        'Рекомендуется консультация педиатра',
        'Возможно потребуется дополнительное обследование',
        'Следите за питанием и общим состоянием ребенка',
      ]);
    } else if (percentile < 15) {
      recommendations.addAll([
        'Показатель ниже среднего',
        'Рекомендуется наблюдение у педиатра',
        'Обратите внимание на питание ребенка',
        'Регулярно отслеживайте динамику роста',
      ]);
    } else if (percentile >= 15 && percentile <= 85) {
      recommendations.addAll([
        'Показатель в пределах нормы',
        'Продолжайте следить за развитием ребенка',
        'Обеспечивайте сбалансированное питание',
        'Регулярные измерения помогут отслеживать динамику',
      ]);
    } else if (percentile > 85 && percentile <= 97) {
      recommendations.addAll([
        'Показатель выше среднего',
        'Обычно это вариант нормы',
        'При необходимости проконсультируйтесь с педиатром',
        'Следите за общим физическим развитием',
      ]);
    } else {
      recommendations.addAll([
        'Показатель значительно выше нормы',
        'Рекомендуется консультация педиатра',
        'Возможно потребуется коррекция питания',
        'Обратите внимание на физическую активность',
      ]);
    }
    
    return recommendations;
  }
}