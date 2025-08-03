// lib/data/food_database.dart
// База данных продуктов питания для детей с полной пищевой ценностью

import '../services/firebase_service.dart';

/// База продуктов питания специально для детей
/// Включает возрастные ограничения и аллергены
class FoodDatabase {
  
  // База фруктов
  static final List<FoodItem> _fruits = [
    FoodItem(
      id: 'apple',
      name: 'Яблоко',
      description: 'Свежее яблоко, источник витаминов и клетчатки',
      category: FoodCategory.fruits,
      defaultUnit: MeasurementUnit.grams,
      caloriesPer100g: 52,
      proteinPer100g: 0.3,
      fatsPer100g: 0.2,
      carbsPer100g: 13.8,
      fiberPer100g: 2.4,
      sugarPer100g: 10.4,
      sodiumPer100g: 1,
      vitaminAPer100g: 3,
      vitaminCPer100g: 4.6,
      vitaminDPer100g: 0,
      calciumPer100g: 6,
      ironPer100g: 0.12,
      allergens: [],
      minAgeMonths: 6,
      isOrganic: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    FoodItem(
      id: 'banana',
      name: 'Банан',
      description: 'Спелый банан, идеальный для первого прикорма',
      category: FoodCategory.fruits,
      defaultUnit: MeasurementUnit.grams,
      caloriesPer100g: 89,
      proteinPer100g: 1.1,
      fatsPer100g: 0.3,
      carbsPer100g: 22.8,
      fiberPer100g: 2.6,
      sugarPer100g: 12.2,
      sodiumPer100g: 1,
      vitaminAPer100g: 3,
      vitaminCPer100g: 8.7,
      vitaminDPer100g: 0,
      calciumPer100g: 5,
      ironPer100g: 0.26,
      allergens: [],
      minAgeMonths: 6,
      isOrganic: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    FoodItem(
      id: 'avocado',
      name: 'Авокадо',
      description: 'Авокадо, богатое полезными жирами',
      category: FoodCategory.fruits,
      defaultUnit: MeasurementUnit.grams,
      caloriesPer100g: 160,
      proteinPer100g: 2.0,
      fatsPer100g: 14.7,
      carbsPer100g: 8.5,
      fiberPer100g: 6.7,
      sugarPer100g: 0.7,
      sodiumPer100g: 7,
      vitaminAPer100g: 7,
      vitaminCPer100g: 10,
      vitaminDPer100g: 0,
      calciumPer100g: 12,
      ironPer100g: 0.55,
      allergens: [],
      minAgeMonths: 6,
      isOrganic: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    FoodItem(
      id: 'orange',
      name: 'Апельсин',
      description: 'Свежий апельсин, источник витамина C',
      category: FoodCategory.fruits,
      defaultUnit: MeasurementUnit.grams,
      caloriesPer100g: 47,
      proteinPer100g: 0.9,
      fatsPer100g: 0.1,
      carbsPer100g: 11.8,
      fiberPer100g: 2.4,
      sugarPer100g: 9.4,
      sodiumPer100g: 0,
      vitaminAPer100g: 11,
      vitaminCPer100g: 53.2,
      vitaminDPer100g: 0,
      calciumPer100g: 40,
      ironPer100g: 0.1,
      allergens: [],
      minAgeMonths: 8,
      isOrganic: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  // База овощей
  static final List<FoodItem> _vegetables = [
    FoodItem(
      id: 'carrot',
      name: 'Морковь',
      description: 'Отварная морковь, богатая бета-каротином',
      category: FoodCategory.vegetables,
      defaultUnit: MeasurementUnit.grams,
      caloriesPer100g: 35,
      proteinPer100g: 0.8,
      fatsPer100g: 0.2,
      carbsPer100g: 8.2,
      fiberPer100g: 2.8,
      sugarPer100g: 4.7,
      sodiumPer100g: 69,
      vitaminAPer100g: 835,
      vitaminCPer100g: 5.9,
      vitaminDPer100g: 0,
      calciumPer100g: 33,
      ironPer100g: 0.3,
      allergens: [],
      minAgeMonths: 6,
      isOrganic: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    FoodItem(
      id: 'broccoli',
      name: 'Брокколи',
      description: 'Отварная брокколи, супер-продукт для детей',
      category: FoodCategory.vegetables,
      defaultUnit: MeasurementUnit.grams,
      caloriesPer100g: 34,
      proteinPer100g: 2.8,
      fatsPer100g: 0.4,
      carbsPer100g: 6.6,
      fiberPer100g: 2.6,
      sugarPer100g: 1.5,
      sodiumPer100g: 33,
      vitaminAPer100g: 31,
      vitaminCPer100g: 89.2,
      vitaminDPer100g: 0,
      calciumPer100g: 47,
      ironPer100g: 0.73,
      allergens: [],
      minAgeMonths: 8,
      isOrganic: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    FoodItem(
      id: 'sweet_potato',
      name: 'Батат (сладкий картофель)',
      description: 'Отварной батат, сладкий и питательный',
      category: FoodCategory.vegetables,
      defaultUnit: MeasurementUnit.grams,
      caloriesPer100g: 86,
      proteinPer100g: 1.6,
      fatsPer100g: 0.1,
      carbsPer100g: 20.1,
      fiberPer100g: 3.0,
      sugarPer100g: 4.2,
      sodiumPer100g: 54,
      vitaminAPer100g: 709,
      vitaminCPer100g: 2.4,
      vitaminDPer100g: 0,
      calciumPer100g: 30,
      ironPer100g: 0.61,
      allergens: [],
      minAgeMonths: 6,
      isOrganic: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  // База белковых продуктов
  static final List<FoodItem> _proteins = [
    FoodItem(
      id: 'chicken_breast',
      name: 'Куриная грудка',
      description: 'Отварная куриная грудка без кожи',
      category: FoodCategory.protein,
      defaultUnit: MeasurementUnit.grams,
      caloriesPer100g: 165,
      proteinPer100g: 31.0,
      fatsPer100g: 3.6,
      carbsPer100g: 0,
      fiberPer100g: 0,
      sugarPer100g: 0,
      sodiumPer100g: 74,
      vitaminAPer100g: 6,
      vitaminCPer100g: 0,
      vitaminDPer100g: 0.2,
      calciumPer100g: 15,
      ironPer100g: 0.7,
      allergens: [],
      minAgeMonths: 8,
      isOrganic: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    FoodItem(
      id: 'salmon',
      name: 'Лосось',
      description: 'Отварной лосось, источник омега-3',
      category: FoodCategory.protein,
      defaultUnit: MeasurementUnit.grams,
      caloriesPer100g: 208,
      proteinPer100g: 25.4,
      fatsPer100g: 12.4,
      carbsPer100g: 0,
      fiberPer100g: 0,
      sugarPer100g: 0,
      sodiumPer100g: 69,
      vitaminAPer100g: 12,
      vitaminCPer100g: 0,
      vitaminDPer100g: 11.0,
      calciumPer100g: 9,
      ironPer100g: 0.34,
      allergens: ['fish'],
      minAgeMonths: 10,
      isOrganic: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    FoodItem(
      id: 'egg_yolk',
      name: 'Яичный желток',
      description: 'Вареный яичный желток',
      category: FoodCategory.protein,
      defaultUnit: MeasurementUnit.pieces,
      caloriesPer100g: 322,
      proteinPer100g: 15.9,
      fatsPer100g: 26.5,
      carbsPer100g: 3.6,
      fiberPer100g: 0,
      sugarPer100g: 0.6,
      sodiumPer100g: 48,
      vitaminAPer100g: 381,
      vitaminCPer100g: 0,
      vitaminDPer100g: 5.4,
      calciumPer100g: 129,
      ironPer100g: 2.73,
      allergens: ['eggs'],
      minAgeMonths: 6,
      isOrganic: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  // База молочных продуктов
  static final List<FoodItem> _dairy = [
    FoodItem(
      id: 'whole_milk',
      name: 'Цельное молоко',
      description: 'Коровье молоко 3.5% жирности',
      category: FoodCategory.dairy,
      defaultUnit: MeasurementUnit.milliliters,
      caloriesPer100g: 60,
      proteinPer100g: 3.2,
      fatsPer100g: 3.3,
      carbsPer100g: 4.8,
      fiberPer100g: 0,
      sugarPer100g: 4.8,
      sodiumPer100g: 44,
      vitaminAPer100g: 28,
      vitaminCPer100g: 0,
      vitaminDPer100g: 1.0,
      calciumPer100g: 113,
      ironPer100g: 0.03,
      allergens: ['milk'],
      minAgeMonths: 12,
      isOrganic: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    FoodItem(
      id: 'natural_yogurt',
      name: 'Натуральный йогурт',
      description: 'Йогурт без добавок и сахара',
      category: FoodCategory.dairy,
      defaultUnit: MeasurementUnit.grams,
      caloriesPer100g: 61,
      proteinPer100g: 3.5,
      fatsPer100g: 3.3,
      carbsPer100g: 4.7,
      fiberPer100g: 0,
      sugarPer100g: 4.7,
      sodiumPer100g: 36,
      vitaminAPer100g: 27,
      vitaminCPer100g: 0.5,
      vitaminDPer100g: 0.1,
      calciumPer100g: 110,
      ironPer100g: 0.05,
      allergens: ['milk'],
      minAgeMonths: 8,
      isOrganic: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    FoodItem(
      id: 'cottage_cheese',
      name: 'Творог',
      description: 'Нежирный творог 5% жирности',
      category: FoodCategory.dairy,
      defaultUnit: MeasurementUnit.grams,
      caloriesPer100g: 103,
      proteinPer100g: 11.0,
      fatsPer100g: 4.3,
      carbsPer100g: 3.4,
      fiberPer100g: 0,
      sugarPer100g: 2.7,
      sodiumPer100g: 364,
      vitaminAPer100g: 37,
      vitaminCPer100g: 0,
      vitaminDPer100g: 0.1,
      calciumPer100g: 83,
      ironPer100g: 0.07,
      allergens: ['milk'],
      minAgeMonths: 8,
      isOrganic: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  // База злаков и круп
  static final List<FoodItem> _grains = [
    FoodItem(
      id: 'oatmeal',
      name: 'Овсяная каша',
      description: 'Овсяная каша на воде',
      category: FoodCategory.grains,
      defaultUnit: MeasurementUnit.grams,
      caloriesPer100g: 68,
      proteinPer100g: 2.4,
      fatsPer100g: 1.4,
      carbsPer100g: 12.0,
      fiberPer100g: 1.7,
      sugarPer100g: 0.3,
      sodiumPer100g: 49,
      vitaminAPer100g: 0,
      vitaminCPer100g: 0,
      vitaminDPer100g: 0,
      calciumPer100g: 9,
      ironPer100g: 0.9,
      allergens: ['gluten'],
      minAgeMonths: 6,
      isOrganic: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    FoodItem(
      id: 'rice_porridge',
      name: 'Рисовая каша',
      description: 'Рисовая каша на воде, гипоаллергенная',
      category: FoodCategory.grains,
      defaultUnit: MeasurementUnit.grams,
      caloriesPer100g: 86,
      proteinPer100g: 1.8,
      fatsPer100g: 0.1,
      carbsPer100g: 17.4,
      fiberPer100g: 0.1,
      sugarPer100g: 0,
      sodiumPer100g: 1,
      vitaminAPer100g: 0,
      vitaminCPer100g: 0,
      vitaminDPer100g: 0,
      calciumPer100g: 1,
      ironPer100g: 0.2,
      allergens: [],
      minAgeMonths: 4,
      isOrganic: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    FoodItem(
      id: 'buckwheat_porridge',
      name: 'Гречневая каша',
      description: 'Гречневая каша на воде',
      category: FoodCategory.grains,
      defaultUnit: MeasurementUnit.grams,
      caloriesPer100g: 92,
      proteinPer100g: 3.4,
      fatsPer100g: 0.6,
      carbsPer100g: 17.1,
      fiberPer100g: 1.3,
      sugarPer100g: 0.9,
      sodiumPer100g: 4,
      vitaminAPer100g: 0,
      vitaminCPer100g: 0,
      vitaminDPer100g: 0,
      calciumPer100g: 7,
      ironPer100g: 0.8,
      allergens: [],
      minAgeMonths: 5,
      isOrganic: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  // База детского питания
  static final List<FoodItem> _babyFood = [
    FoodItem(
      id: 'baby_formula',
      name: 'Детская смесь',
      description: 'Адаптированная молочная смесь для детей',
      category: FoodCategory.babyFood,
      defaultUnit: MeasurementUnit.milliliters,
      caloriesPer100g: 66,
      proteinPer100g: 1.4,
      fatsPer100g: 3.4,
      carbsPer100g: 7.4,
      fiberPer100g: 0,
      sugarPer100g: 7.4,
      sodiumPer100g: 17,
      vitaminAPer100g: 55,
      vitaminCPer100g: 10,
      vitaminDPer100g: 1.0,
      calciumPer100g: 52,
      ironPer100g: 0.7,
      allergens: ['milk'],
      minAgeMonths: 0,
      isOrganic: false,
      brand: 'NutriLon',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    FoodItem(
      id: 'baby_puree_apple',
      name: 'Детское пюре яблочное',
      description: 'Готовое яблочное пюре без сахара',
      category: FoodCategory.babyFood,
      defaultUnit: MeasurementUnit.grams,
      caloriesPer100g: 48,
      proteinPer100g: 0.2,
      fatsPer100g: 0.1,
      carbsPer100g: 11.5,
      fiberPer100g: 1.2,
      sugarPer100g: 10.5,
      sodiumPer100g: 2,
      vitaminAPer100g: 2,
      vitaminCPer100g: 4,
      vitaminDPer100g: 0,
      calciumPer100g: 5,
      ironPer100g: 0.1,
      allergens: [],
      minAgeMonths: 4,
      isOrganic: true,
      brand: 'HiPP',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  // База напитков
  static final List<FoodItem> _beverages = [
    FoodItem(
      id: 'water',
      name: 'Питьевая вода',
      description: 'Чистая детская питьевая вода',
      category: FoodCategory.beverages,
      defaultUnit: MeasurementUnit.milliliters,
      caloriesPer100g: 0,
      proteinPer100g: 0,
      fatsPer100g: 0,
      carbsPer100g: 0,
      fiberPer100g: 0,
      sugarPer100g: 0,
      sodiumPer100g: 0,
      vitaminAPer100g: 0,
      vitaminCPer100g: 0,
      vitaminDPer100g: 0,
      calciumPer100g: 0,
      ironPer100g: 0,
      allergens: [],
      minAgeMonths: 6,
      isOrganic: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    FoodItem(
      id: 'apple_juice',
      name: 'Яблочный сок',
      description: 'Разбавленный яблочный сок без сахара',
      category: FoodCategory.beverages,
      defaultUnit: MeasurementUnit.milliliters,
      caloriesPer100g: 46,
      proteinPer100g: 0.1,
      fatsPer100g: 0.1,
      carbsPer100g: 11.3,
      fiberPer100g: 0.2,
      sugarPer100g: 9.6,
      sodiumPer100g: 4,
      vitaminAPer100g: 1,
      vitaminCPer100g: 0.9,
      vitaminDPer100g: 0,
      calciumPer100g: 7,
      ironPer100g: 0.12,
      allergens: [],
      minAgeMonths: 6,
      isOrganic: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  /// Получить все продукты
  static List<FoodItem> getAllFoods() {
    return [
      ..._fruits,
      ..._vegetables,
      ..._proteins,
      ..._dairy,
      ..._grains,
      ..._babyFood,
      ..._beverages,
    ];
  }

  /// Получить продукты по категории
  static List<FoodItem> getFoodsByCategory(FoodCategory category) {
    switch (category) {
      case FoodCategory.fruits:
        return _fruits;
      case FoodCategory.vegetables:
        return _vegetables;
      case FoodCategory.protein:
        return _proteins;
      case FoodCategory.dairy:
        return _dairy;
      case FoodCategory.grains:
        return _grains;
      case FoodCategory.babyFood:
        return _babyFood;
      case FoodCategory.beverages:
        return _beverages;
      default:
        return [];
    }
  }

  /// Получить продукты по возрасту
  static List<FoodItem> getFoodsForAge(int ageMonths) {
    return getAllFoods()
        .where((food) => food.isAllowedForAge(ageMonths))
        .toList();
  }

  /// Получить продукты без определенных аллергенов
  static List<FoodItem> getFoodsWithoutAllergens(List<String> allergens) {
    return getAllFoods()
        .where((food) => 
            !food.allergens.any((allergen) => allergens.contains(allergen)))
        .toList();
  }

  /// Найти продукт по ID
  static FoodItem? getFoodById(String id) {
    try {
      return getAllFoods().firstWhere((food) => food.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Поиск продуктов по названию
  static List<FoodItem> searchFoods(String query) {
    final lowQuery = query.toLowerCase();
    return getAllFoods()
        .where((food) => 
            food.name.toLowerCase().contains(lowQuery) ||
            food.description.toLowerCase().contains(lowQuery))
        .toList();
  }

  /// Получить рекомендованные продукты для возраста
  static List<FoodItem> getRecommendedFoodsForAge(int ageMonths) {
    // Приоритетные продукты по возрастам
    if (ageMonths < 6) {
      return getFoodsByCategory(FoodCategory.babyFood)
          .where((food) => food.isAllowedForAge(ageMonths))
          .toList();
    } else if (ageMonths < 8) {
      return [
        ..._fruits.where((f) => f.isAllowedForAge(ageMonths)),
        ..._vegetables.where((f) => f.isAllowedForAge(ageMonths)),
        ..._grains.where((f) => f.isAllowedForAge(ageMonths)),
      ];
    } else if (ageMonths < 12) {
      return [
        ..._proteins.where((f) => f.isAllowedForAge(ageMonths)),
        ..._dairy.where((f) => f.isAllowedForAge(ageMonths)),
        ..._fruits.where((f) => f.isAllowedForAge(ageMonths)),
        ..._vegetables.where((f) => f.isAllowedForAge(ageMonths)),
      ];
    } else {
      return getFoodsForAge(ageMonths);
    }
  }
}