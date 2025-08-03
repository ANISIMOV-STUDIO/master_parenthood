// lib/data/recipe_database.dart
// База рецептов для детского питания

import '../services/firebase_service.dart';

/// База рецептов детского питания с учетом возраста и аллергий
class RecipeDatabase {
  
  // Рецепты для первого прикорма (4-6 месяцев)
  static final List<Recipe> _firstFoodRecipes = [
    Recipe(
      id: 'apple_puree',
      name: 'Яблочное пюре',
      description: 'Нежное яблочное пюре для первого прикорма',
      ingredients: [
        RecipeIngredient(
          foodItemId: 'apple',
          foodName: 'Яблоко',
          amount: 150,
          unit: MeasurementUnit.grams,
          isOptional: false,
        ),
        RecipeIngredient(
          foodItemId: 'water',
          foodName: 'Вода',
          amount: 50,
          unit: MeasurementUnit.milliliters,
          isOptional: false,
        ),
      ],
      instructions: [
        'Помойте и очистите яблоко от кожуры и семян',
        'Нарежьте яблоко небольшими кусочками',
        'Залейте водой и варите на медленном огне 10-15 минут',
        'Остудите и измельчите блендером до однородной массы',
        'Процедите через мелкое сито для получения гладкой текстуры',
        'Подавайте теплым, остатки храните в холодильнике не более 24 часов'
      ],
      prepTimeMinutes: 10,
      cookTimeMinutes: 15,
      servings: 2,
      difficulty: RecipeDifficulty.veryEasy,
      minAgeMonths: 4,
      tags: ['первый прикорм', 'фрукты', 'пюре', 'гипоаллергенно'],
      allergens: [],
      photos: [],
      rating: 4.8,
      ratingsCount: 245,
      authorId: 'system',
      isPremium: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Recipe(
      id: 'carrot_puree',
      name: 'Морковное пюре',
      description: 'Сладкое морковное пюре, богатое витамином А',
      ingredients: [
        RecipeIngredient(
          foodItemId: 'carrot',
          foodName: 'Морковь',
          amount: 200,
          unit: MeasurementUnit.grams,
          isOptional: false,
        ),
        RecipeIngredient(
          foodItemId: 'water',
          foodName: 'Вода',
          amount: 100,
          unit: MeasurementUnit.milliliters,
          isOptional: false,
        ),
      ],
      instructions: [
        'Очистите морковь и нарежьте кружочками',
        'Варите в кипящей воде 20 минут до мягкости',
        'Слейте воду, оставив немного для пюрирования',
        'Измельчите блендером, добавляя воду для нужной консистенции',
        'Протрите через сито для гладкой текстуры',
        'Подавайте теплым'
      ],
      prepTimeMinutes: 10,
      cookTimeMinutes: 20,
      servings: 3,
      difficulty: RecipeDifficulty.veryEasy,
      minAgeMonths: 5,
      tags: ['первый прикорм', 'овощи', 'витамин А', 'оранжевые овощи'],
      allergens: [],
      photos: [],
      rating: 4.7,
      ratingsCount: 189,
      authorId: 'system',
      isPremium: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Recipe(
      id: 'rice_porridge_first',
      name: 'Первая рисовая каша',
      description: 'Жидкая рисовая каша для знакомства со злаками',
      ingredients: [
        RecipeIngredient(
          foodItemId: 'rice_porridge',
          foodName: 'Рис',
          amount: 30,
          unit: MeasurementUnit.grams,
          isOptional: false,
        ),
        RecipeIngredient(
          foodItemId: 'water',
          foodName: 'Вода',
          amount: 200,
          unit: MeasurementUnit.milliliters,
          isOptional: false,
        ),
      ],
      instructions: [
        'Промойте рис до прозрачной воды',
        'Отварите рис в большом количестве воды до полной готовности (25-30 минут)',
        'Протрите через сито или измельчите блендером',
        'Разведите до жидкой консистенции кипяченой водой',
        'Подавайте теплым',
        'Начинайте с 1-2 чайных ложек'
      ],
      prepTimeMinutes: 5,
      cookTimeMinutes: 30,
      servings: 2,
      difficulty: RecipeDifficulty.easy,
      minAgeMonths: 4,
      tags: ['первый прикорм', 'злаки', 'гипоаллергенно', 'каша'],
      allergens: [],
      photos: [],
      rating: 4.6,
      ratingsCount: 156,
      authorId: 'system',
      isPremium: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  // Рецепты для детей 6-12 месяцев
  static final List<Recipe> _infantRecipes = [
    Recipe(
      id: 'vegetable_soup',
      name: 'Овощной суп-пюре',
      description: 'Нежный суп из овощей для расширения рациона',
      ingredients: [
        RecipeIngredient(
          foodItemId: 'carrot',
          foodName: 'Морковь',
          amount: 100,
          unit: MeasurementUnit.grams,
          isOptional: false,
        ),
        RecipeIngredient(
          foodItemId: 'sweet_potato',
          foodName: 'Батат',
          amount: 100,
          unit: MeasurementUnit.grams,
          isOptional: false,
        ),
        RecipeIngredient(
          foodItemId: 'broccoli',
          foodName: 'Брокколи',
          amount: 80,
          unit: MeasurementUnit.grams,
          isOptional: false,
        ),
        RecipeIngredient(
          foodItemId: 'water',
          foodName: 'Вода',
          amount: 300,
          unit: MeasurementUnit.milliliters,
          isOptional: false,
        ),
      ],
      instructions: [
        'Очистите и нарежьте морковь и батат кубиками',
        'Разберите брокколи на соцветия',
        'Варите все овощи в воде 20 минут до мягкости',
        'Измельчите блендером вместе с отваром',
        'Добавьте отвар для нужной консистенции',
        'Подавайте теплым, можно добавить капельку оливкового масла'
      ],
      prepTimeMinutes: 15,
      cookTimeMinutes: 20,
      servings: 4,
      difficulty: RecipeDifficulty.easy,
      minAgeMonths: 7,
      tags: ['овощи', 'суп', 'разноцветный', 'витамины'],
      allergens: [],
      photos: [],
      rating: 4.9,
      ratingsCount: 312,
      authorId: 'system',
      isPremium: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Recipe(
      id: 'banana_oatmeal',
      name: 'Овсянка с бананом',
      description: 'Питательная каша с натуральной сладостью банана',
      ingredients: [
        RecipeIngredient(
          foodItemId: 'oatmeal',
          foodName: 'Овсяные хлопья',
          amount: 40,
          unit: MeasurementUnit.grams,
          isOptional: false,
        ),
        RecipeIngredient(
          foodItemId: 'banana',
          foodName: 'Банан',
          amount: 60,
          unit: MeasurementUnit.grams,
          isOptional: false,
        ),
        RecipeIngredient(
          foodItemId: 'water',
          foodName: 'Вода',
          amount: 150,
          unit: MeasurementUnit.milliliters,
          isOptional: false,
        ),
      ],
      instructions: [
        'Залейте овсяные хлопья водой и варите 5-7 минут',
        'Разомните банан вилкой',
        'Добавьте банан в готовую кашу',
        'Перемешайте и слегка остудите',
        'Подавайте теплым',
        'Для детей старше 8 месяцев можно оставить небольшие кусочки банана'
      ],
      prepTimeMinutes: 5,
      cookTimeMinutes: 10,
      servings: 2,
      difficulty: RecipeDifficulty.veryEasy,
      minAgeMonths: 6,
      tags: ['каша', 'фрукты', 'сладкий', 'энергия'],
      allergens: ['gluten'],
      photos: [],
      rating: 4.8,
      ratingsCount: 278,
      authorId: 'system',
      isPremium: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  // Рецепты для детей 12+ месяцев
  static final List<Recipe> _toddlerRecipes = [
    Recipe(
      id: 'mini_meatballs',
      name: 'Мини-котлетки на пару',
      description: 'Нежные паровые котлетки из курицы для малышей',
      ingredients: [
        RecipeIngredient(
          foodItemId: 'chicken_breast',
          foodName: 'Куриная грудка',
          amount: 200,
          unit: MeasurementUnit.grams,
          isOptional: false,
        ),
        RecipeIngredient(
          foodItemId: 'rice_porridge',
          foodName: 'Отварной рис',
          amount: 50,
          unit: MeasurementUnit.grams,
          isOptional: false,
        ),
        RecipeIngredient(
          foodItemId: 'egg_yolk',
          foodName: 'Яичный желток',
          amount: 1,
          unit: MeasurementUnit.pieces,
          isOptional: false,
        ),
        RecipeIngredient(
          foodItemId: 'carrot',
          foodName: 'Морковь',
          amount: 30,
          unit: MeasurementUnit.grams,
          isOptional: true,
          notes: 'Для дополнительных витаминов',
        ),
      ],
      instructions: [
        'Пропустите курицу через мясорубку дважды',
        'Отварите рис до мягкости и остудите',
        'Натрите морковь на мелкой терке (опционально)',
        'Смешайте фарш с рисом, желтком и морковью',
        'Сформируйте маленькие котлетки размером с грецкий орех',
        'Готовьте на пару 15-20 минут',
        'Подавайте теплыми с овощным пюре'
      ],
      prepTimeMinutes: 20,
      cookTimeMinutes: 20,
      servings: 8,
      difficulty: RecipeDifficulty.medium,
      minAgeMonths: 10,
      tags: ['белок', 'мясо', 'на пару', 'finger food'],
      allergens: ['eggs'],
      photos: [],
      rating: 4.7,
      ratingsCount: 167,
      authorId: 'system',
      isPremium: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Recipe(
      id: 'fruit_salad_toddler',
      name: 'Фруктовый салат для малышей',
      description: 'Красочный фруктовый салат кусочками',
      ingredients: [
        RecipeIngredient(
          foodItemId: 'banana',
          foodName: 'Банан',
          amount: 80,
          unit: MeasurementUnit.grams,
          isOptional: false,
        ),
        RecipeIngredient(
          foodItemId: 'apple',
          foodName: 'Яблоко',
          amount: 100,
          unit: MeasurementUnit.grams,
          isOptional: false,
        ),
        RecipeIngredient(
          foodItemId: 'avocado',
          foodName: 'Авокадо',
          amount: 50,
          unit: MeasurementUnit.grams,
          isOptional: true,
          notes: 'Для полезных жиров',
        ),
        RecipeIngredient(
          foodItemId: 'natural_yogurt',
          foodName: 'Натуральный йогурт',
          amount: 30,
          unit: MeasurementUnit.grams,
          isOptional: true,
          notes: 'Для заправки',
        ),
      ],
      instructions: [
        'Помойте все фрукты',
        'Нарежьте банан кружочками 5-7 мм',
        'Нарежьте очищенное яблоко маленькими кубиками',
        'Нарежьте авокадо кубиками (если используете)',
        'Аккуратно перемешайте все фрукты',
        'Добавьте ложку йогурта если ребенок старше года',
        'Подавайте сразу после приготовления'
      ],
      prepTimeMinutes: 10,
      cookTimeMinutes: 0,
      servings: 2,
      difficulty: RecipeDifficulty.veryEasy,
      minAgeMonths: 9,
      tags: ['фрукты', 'finger food', 'витамины', 'свежий'],
      allergens: ['milk'],
      photos: [],
      rating: 4.9,
      ratingsCount: 203,
      authorId: 'system',
      isPremium: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  // Премиум рецепты
  static final List<Recipe> _premiumRecipes = [
    Recipe(
      id: 'salmon_quinoa_premium',
      name: 'Лосось с киноа и овощами',
      description: 'Премиум блюдо с омега-3 и суперфудами',
      ingredients: [
        RecipeIngredient(
          foodItemId: 'salmon',
          foodName: 'Лосось',
          amount: 80,
          unit: MeasurementUnit.grams,
          isOptional: false,
        ),
        RecipeIngredient(
          foodItemId: 'broccoli',
          foodName: 'Брокколи',
          amount: 60,
          unit: MeasurementUnit.grams,
          isOptional: false,
        ),
        RecipeIngredient(
          foodItemId: 'sweet_potato',
          foodName: 'Батат',
          amount: 100,
          unit: MeasurementUnit.grams,
          isOptional: false,
        ),
        RecipeIngredient(
          foodItemId: 'avocado',
          foodName: 'Авокадо',
          amount: 30,
          unit: MeasurementUnit.grams,
          isOptional: false,
          notes: 'Для заправки',
        ),
      ],
      instructions: [
        'Отварите лосось на пару 12-15 минут',
        'Отварите батат до мягкости (15 минут)',
        'Приготовьте брокколи на пару 8 минут',
        'Разомните авокадо в пюре',
        'Разберите лосось на мелкие кусочки, удалив кости',
        'Нарежьте овощи соответственно возрасту ребенка',
        'Подавайте с авокадо-пюре как соусом',
        'Блюдо богато омега-3, белком и витаминами'
      ],
      prepTimeMinutes: 15,
      cookTimeMinutes: 20,
      servings: 2,
      difficulty: RecipeDifficulty.medium,
      minAgeMonths: 10,
      tags: ['премиум', 'омега-3', 'суперфуд', 'развитие мозга', 'белок'],
      allergens: ['fish'],
      photos: [],
      rating: 4.9,
      ratingsCount: 89,
      authorId: 'chef_anna',
      isPremium: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Recipe(
      id: 'immunity_smoothie_bowl',
      name: 'Смузи-боул для иммунитета',
      description: 'Питательный смузи-боул с суперфудами для укрепления иммунитета',
      ingredients: [
        RecipeIngredient(
          foodItemId: 'banana',
          foodName: 'Замороженный банан',
          amount: 100,
          unit: MeasurementUnit.grams,
          isOptional: false,
        ),
        RecipeIngredient(
          foodItemId: 'natural_yogurt',
          foodName: 'Греческий йогурт',
          amount: 80,
          unit: MeasurementUnit.grams,
          isOptional: false,
        ),
        RecipeIngredient(
          foodItemId: 'avocado',
          foodName: 'Авокадо',
          amount: 40,
          unit: MeasurementUnit.grams,
          isOptional: false,
        ),
        RecipeIngredient(
          foodItemId: 'apple',
          foodName: 'Яблоко',
          amount: 50,
          unit: MeasurementUnit.grams,
          isOptional: false,
          notes: 'Для топпинга, кубиками',
        ),
      ],
      instructions: [
        'Взбейте замороженный банан с йогуртом и авокадо',
        'Добавьте немного воды для нужной консистенции',
        'Выложите смузи в миску',
        'Украсьте кубиками яблока',
        'Подавайте сразу с детской ложкой',
        'Богато пробиотиками, витаминами и полезными жирами'
      ],
      prepTimeMinutes: 10,
      cookTimeMinutes: 0,
      servings: 1,
      difficulty: RecipeDifficulty.easy,
      minAgeMonths: 12,
      tags: ['премиум', 'иммунитет', 'пробиотики', 'смузи', 'суперфуд'],
      allergens: ['milk'],
      photos: [],
      rating: 5.0,
      ratingsCount: 45,
      authorId: 'nutritionist_maria',
      isPremium: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  /// Получить все рецепты
  static List<Recipe> getAllRecipes() {
    return [
      ..._firstFoodRecipes,
      ..._infantRecipes,
      ..._toddlerRecipes,
      ..._premiumRecipes,
    ];
  }

  /// Получить рецепты по возрасту
  static List<Recipe> getRecipesForAge(int ageMonths) {
    return getAllRecipes()
        .where((recipe) => recipe.isAllowedForAge(ageMonths))
        .toList();
  }

  /// Получить рецепты без определенных аллергенов
  static List<Recipe> getRecipesWithoutAllergens(List<String> allergens) {
    return getAllRecipes()
        .where((recipe) => 
            !recipe.allergens.any((allergen) => allergens.contains(allergen)))
        .toList();
  }

  /// Получить рецепты по сложности
  static List<Recipe> getRecipesByDifficulty(RecipeDifficulty difficulty) {
    return getAllRecipes()
        .where((recipe) => recipe.difficulty == difficulty)
        .toList();
  }

  /// Получить рецепты по времени приготовления
  static List<Recipe> getQuickRecipes(int maxTotalMinutes) {
    return getAllRecipes()
        .where((recipe) => recipe.totalTimeMinutes <= maxTotalMinutes)
        .toList();
  }

  /// Получить популярные рецепты
  static List<Recipe> getPopularRecipes() {
    return getAllRecipes()
        .where((recipe) => recipe.rating >= 4.5 && recipe.ratingsCount >= 100)
        .toList()
        ..sort((a, b) => b.rating.compareTo(a.rating));
  }

  /// Получить премиум рецепты
  static List<Recipe> getPremiumRecipes() {
    return _premiumRecipes;
  }

  /// Найти рецепт по ID
  static Recipe? getRecipeById(String id) {
    try {
      return getAllRecipes().firstWhere((recipe) => recipe.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Поиск рецептов
  static List<Recipe> searchRecipes(String query) {
    final lowQuery = query.toLowerCase();
    return getAllRecipes()
        .where((recipe) => 
            recipe.name.toLowerCase().contains(lowQuery) ||
            recipe.description.toLowerCase().contains(lowQuery) ||
            recipe.tags.any((tag) => tag.toLowerCase().contains(lowQuery)))
        .toList();
  }

  /// Получить рекомендованные рецепты для возраста
  static List<Recipe> getRecommendedRecipesForAge(int ageMonths) {
    if (ageMonths < 6) {
      return _firstFoodRecipes
          .where((recipe) => recipe.isAllowedForAge(ageMonths))
          .toList();
    } else if (ageMonths < 12) {
      return [
        ..._firstFoodRecipes.where((r) => r.isAllowedForAge(ageMonths)),
        ..._infantRecipes.where((r) => r.isAllowedForAge(ageMonths)),
      ];
    } else {
      return [
        ...getPopularRecipes().where((r) => r.isAllowedForAge(ageMonths)),
        ..._toddlerRecipes.where((r) => r.isAllowedForAge(ageMonths)),
      ];
    }
  }

  /// Получить рецепты по тегам
  static List<Recipe> getRecipesByTags(List<String> tags) {
    return getAllRecipes()
        .where((recipe) => 
            recipe.tags.any((tag) => tags.contains(tag)))
        .toList();
  }
}