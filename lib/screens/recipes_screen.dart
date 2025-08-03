// lib/screens/recipes_screen.dart
import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../data/recipe_database.dart';

class RecipesScreen extends StatefulWidget {
  final String childId;

  const RecipesScreen({super.key, required this.childId});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen>
    with TickerProviderStateMixin {
  
  late TabController _tabController;
  late AnimationController _headerController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  List<Recipe> _allRecipes = [];
  List<Recipe> _filteredRecipes = [];
  List<AllergyInfo> _childAllergies = [];
  int _childAgeMonths = 12;
  bool _isLoading = true;
  
  String _searchQuery = '';
  RecipeDifficulty? _selectedDifficulty;
  int? _maxTimeMinutes;
  bool _onlyForAge = true;
  bool _excludeAllergens = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _slideAnimation = Tween<double>(begin: -50.0, end: 0.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeInOut),
    );
    
    _loadData();
    _headerController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _headerController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Загружаем возраст ребенка
      final child = await FirebaseService.getChild(widget.childId);
      if (child != null) {
        _childAgeMonths = DateTime.now().difference(child.birthDate).inDays ~/ 30;
      }
      
      // Загружаем аллергии ребенка
      FirebaseService.getAllergiesStream(widget.childId).listen((allergies) {
        setState(() {
          _childAllergies = allergies;
        });
        _applyFilters();
      });
      
      // Загружаем рецепты из базы данных
      _allRecipes = RecipeDatabase.getAllRecipes();
      
      setState(() {
        _isLoading = false;
      });
      
      _applyFilters();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки данных: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredRecipes = _allRecipes.where((recipe) {
        // Фильтр по поиску
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          if (!recipe.name.toLowerCase().contains(query) &&
              !recipe.description.toLowerCase().contains(query) &&
              !recipe.tags.any((tag) => tag.toLowerCase().contains(query))) {
            return false;
          }
        }
        
        // Фильтр по возрасту
        if (_onlyForAge && !recipe.isAllowedForAge(_childAgeMonths)) {
          return false;
        }
        
        // Фильтр по аллергенам
        if (_excludeAllergens && _childAllergies.isNotEmpty) {
          final allergenNames = _childAllergies.map((a) => a.allergen.toLowerCase()).toList();
          if (recipe.allergens.any((allergen) => 
              allergenNames.contains(allergen.toLowerCase()))) {
            return false;
          }
        }
        
        // Фильтр по сложности
        if (_selectedDifficulty != null && recipe.difficulty != _selectedDifficulty) {
          return false;
        }
        
        // Фильтр по времени
        if (_maxTimeMinutes != null && recipe.totalTimeMinutes > _maxTimeMinutes!) {
          return false;
        }
        
        return true;
      }).toList();
      
      // Сортировка по рейтингу
      _filteredRecipes.sort((a, b) => b.rating.compareTo(a.rating));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.orange[700]!,
              Colors.orange[500]!,
              Colors.orange[300]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchAndFilters(),
              _buildStatsRow(),
              _buildTabBar(),
              Expanded(
                child: _buildTabBarView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _headerController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Рецепты',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Здоровые рецепты для вашего малыша',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _showFiltersDialog,
                    icon: const Icon(Icons.filter_list, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Поисковая строка
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: Colors.orange[700]),
                const SizedBox(width: 15),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Поиск рецептов...',
                      border: InputBorder.none,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                      _applyFilters();
                    },
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                      });
                      _applyFilters();
                    },
                    icon: const Icon(Icons.clear),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          
          // Быстрые фильтры
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip(
                  'Для возраста ${(_childAgeMonths/12).toStringAsFixed(1)} лет',
                  _onlyForAge,
                  () {
                    setState(() {
                      _onlyForAge = !_onlyForAge;
                    });
                    _applyFilters();
                  },
                ),
                const SizedBox(width: 10),
                _buildFilterChip(
                  'Без аллергенов',
                  _excludeAllergens,
                  () {
                    setState(() {
                      _excludeAllergens = !_excludeAllergens;
                    });
                    _applyFilters();
                  },
                ),
                const SizedBox(width: 10),
                _buildFilterChip(
                  'Быстрые (≤30 мин)',
                  _maxTimeMinutes == 30,
                  () {
                    setState(() {
                      _maxTimeMinutes = _maxTimeMinutes == 30 ? null : 30;
                    });
                    _applyFilters();
                  },
                ),
                const SizedBox(width: 10),
                _buildFilterChip(
                  'Простые',
                  _selectedDifficulty == RecipeDifficulty.easy,
                  () {
                    setState(() {
                      _selectedDifficulty = _selectedDifficulty == RecipeDifficulty.easy 
                          ? null 
                          : RecipeDifficulty.easy;
                    });
                    _applyFilters();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? Colors.white 
              : Colors.white.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
          border: isSelected 
              ? Border.all(color: Colors.orange[700]!, width: 2)
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.orange[700] : Colors.white,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Всего рецептов',
            '${_allRecipes.length}',
            Icons.menu_book,
            Colors.blue,
          ),
          _buildStatItem(
            'Подходящих',
            '${_filteredRecipes.length}',
            Icons.check_circle,
            Colors.green,
          ),
          _buildStatItem(
            'Премиум',
            '${_allRecipes.where((r) => r.isPremium).length}',
            Icons.star,
            Colors.amber,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(15),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Colors.orange[600],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.orange[700],
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Все рецепты'),
          Tab(text: 'Популярные'),
          Tab(text: 'Премиум'),
        ],
      ),
    );
  }

  Widget _buildTabBarView() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildRecipesList(_filteredRecipes),
          _buildRecipesList(_filteredRecipes.where((r) => r.rating >= 4.5).toList()),
          _buildRecipesList(_filteredRecipes.where((r) => r.isPremium).toList()),
        ],
      ),
    );
  }

  Widget _buildRecipesList(List<Recipe> recipes) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (recipes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 20),
            Text(
              'Рецепты не найдены',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 10),
            Text(
              'Попробуйте изменить фильтры',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        final recipe = recipes[index];
        return _buildRecipeCard(recipe);
      },
    );
  }

  Widget _buildRecipeCard(Recipe recipe) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () => _showRecipeDetails(recipe),
        borderRadius: BorderRadius.circular(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок рецепта
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                recipe.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (recipe.isPremium)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8, 
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'ПРЕМИУМ',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          recipe.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Детали рецепта
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildRecipeDetail(
                    Icons.schedule,
                    '${recipe.totalTimeMinutes} мин',
                    Colors.blue,
                  ),
                  const SizedBox(width: 20),
                  _buildRecipeDetail(
                    Icons.restaurant,
                    '${recipe.servings} порц.',
                    Colors.green,
                  ),
                  const SizedBox(width: 20),
                  _buildRecipeDetail(
                    Icons.trending_up,
                    recipe.difficultyDisplayName,
                    _getDifficultyColor(recipe.difficulty),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        recipe.formattedRating,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        ' (${recipe.ratingsCount})',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Теги
            if (recipe.tags.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: recipe.tags.take(3).map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )).toList(),
                ),
              ),
            
            // Возрастные ограничения и аллергены
            if (recipe.minAgeMonths > 0 || recipe.hasAllergens)
              Container(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  children: [
                    if (recipe.minAgeMonths > 0) ...[
                      Icon(Icons.child_care, size: 16, color: Colors.blue[600]),
                      const SizedBox(width: 4),
                      Text(
                        'От ${recipe.minAgeMonths} мес.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[600],
                        ),
                      ),
                    ],
                    if (recipe.minAgeMonths > 0 && recipe.hasAllergens)
                      const SizedBox(width: 15),
                    if (recipe.hasAllergens) ...[
                      Icon(Icons.warning, size: 16, color: Colors.orange[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Содержит аллергены',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeDetail(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Color _getDifficultyColor(RecipeDifficulty difficulty) {
    switch (difficulty) {
      case RecipeDifficulty.veryEasy:
        return Colors.green;
      case RecipeDifficulty.easy:
        return Colors.lightGreen;
      case RecipeDifficulty.medium:
        return Colors.orange;
      case RecipeDifficulty.hard:
        return Colors.red;
      case RecipeDifficulty.veryHard:
        return Colors.deepPurple;
    }
  }

  // Действия
  void _showFiltersDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Фильтры'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Только для возраста ребенка'),
              value: _onlyForAge,
              onChanged: (value) {
                setState(() {
                  _onlyForAge = value;
                });
                _applyFilters();
              },
            ),
            SwitchListTile(
              title: const Text('Исключить аллергены'),
              value: _excludeAllergens,
              onChanged: (value) {
                setState(() {
                  _excludeAllergens = value;
                });
                _applyFilters();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _showRecipeDetails(Recipe recipe) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Заголовок
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          recipe.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                
                // Контент
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe.description,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 20),
                        
                        // Ингредиенты
                        const Text(
                          'Ингредиенты:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...recipe.ingredients.map((ingredient) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Text('• ${ingredient.foodName}'),
                              const Spacer(),
                              Text('${ingredient.amount} ${ingredient.unit.name}'),
                            ],
                          ),
                        )),
                        
                        const SizedBox(height: 20),
                        
                        // Инструкции
                        const Text(
                          'Приготовление:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...recipe.instructions.asMap().entries.map((entry) => 
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: Colors.orange[600],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${entry.key + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(entry.value),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}