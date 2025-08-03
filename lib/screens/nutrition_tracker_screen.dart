// lib/screens/nutrition_tracker_screen.dart
import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../data/food_database.dart';

class NutritionTrackerScreen extends StatefulWidget {
  final String childId;

  const NutritionTrackerScreen({super.key, required this.childId});

  @override
  State<NutritionTrackerScreen> createState() => _NutritionTrackerScreenState();
}

class _NutritionTrackerScreenState extends State<NutritionTrackerScreen>
    with TickerProviderStateMixin {
  
  late TabController _tabController;
  late AnimationController _headerController;
  late Animation<double> _fadeAnimation;
  
  DateTime _selectedDate = DateTime.now();
  List<NutritionEntry> _todayEntries = [];
  NutritionGoals? _nutritionGoals;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
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
      // Загружаем записи за сегодня
      final entries = await FirebaseService.getNutritionEntriesForDay(
        widget.childId, 
        _selectedDate
      );
      
      // Загружаем цели питания
      final goals = await FirebaseService.getCurrentNutritionGoals(widget.childId);
      
      if (goals == null) {
        // Создаем стандартные цели если их нет
        final child = await FirebaseService.getChild(widget.childId);
        if (child != null) {
          final ageMonths = DateTime.now().difference(child.birthDate).inDays ~/ 30;
          await FirebaseService.createStandardNutritionGoals(widget.childId, ageMonths);
          final newGoals = await FirebaseService.getCurrentNutritionGoals(widget.childId);
          setState(() {
            _nutritionGoals = newGoals;
          });
        }
      } else {
        setState(() {
          _nutritionGoals = goals;
        });
      }
      
      setState(() {
        _todayEntries = entries;
        _isLoading = false;
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green[700]!,
              Colors.green[500]!,
              Colors.green[300]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildDateSelector(),
              _buildQuickStats(),
              _buildTabBar(),
              Expanded(
                child: _buildTabBarView(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMealDialog,
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Добавить еду'),
      ),
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
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
                    'Дневник питания',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Отслеживайте питание ребенка',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _showNutritionGoalsDialog,
              icon: const Icon(Icons.tune, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
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
        children: [
          Icon(Icons.calendar_today, color: Colors.green[700]),
          const SizedBox(width: 15),
          Expanded(
            child: GestureDetector(
              onTap: _selectDate,
              child: Text(
                _formatDate(_selectedDate),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.green[700],
                ),
              ),
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () => _changeDate(-1),
                icon: Icon(Icons.chevron_left, color: Colors.green[700]),
              ),
              IconButton(
                onPressed: () => _changeDate(1),
                icon: Icon(Icons.chevron_right, color: Colors.green[700]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    if (_isLoading || _nutritionGoals == null) {
      return Container(
        margin: const EdgeInsets.all(20),
        height: 100,
        child: const Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final totalCalories = _calculateTotalCalories();
    final calorieProgress = totalCalories / _nutritionGoals!.targetCalories;

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
        children: [
          Expanded(
            child: _buildStatCard(
              'Калории',
              '${totalCalories.toInt()}',
              '${_nutritionGoals!.targetCalories.toInt()}',
              calorieProgress,
              Icons.local_fire_department,
              Colors.orange,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: _buildStatCard(
              'Приемы пищи',
              '${_todayEntries.length}',
              '5-7',
              _todayEntries.length / 6,
              Icons.restaurant,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: _buildStatCard(
              'Аппетит',
              _getAverageAppetite(),
              '5',
              _getAverageAppetiteScore() / 5,
              Icons.sentiment_satisfied,
              Colors.purple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String target,
    double progress,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          '/ $target',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(color),
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
          color: Colors.green[600],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.green[700],
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Сегодня'),
          Tab(text: 'Продукты'),
          Tab(text: 'Рецепты'),
          Tab(text: 'Анализ'),
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
          _buildTodayTab(),
          _buildFoodsTab(),
          _buildRecipesTab(),
          _buildAnalysisTab(),
        ],
      ),
    );
  }

  Widget _buildTodayTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_todayEntries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 20),
            Text(
              'Нет записей о питании',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 10),
            Text(
              'Добавьте первую запись о еде',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _showAddMealDialog,
              icon: const Icon(Icons.add),
              label: const Text('Добавить еду'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _todayEntries.length,
      itemBuilder: (context, index) {
        final entry = _todayEntries[index];
        return _buildNutritionEntryCard(entry);
      },
    );
  }

  Widget _buildNutritionEntryCard(NutritionEntry entry) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: CircleAvatar(
          backgroundColor: _getMealTypeColor(entry.mealType),
          child: Icon(
            _getMealTypeIcon(entry.mealType),
            color: Colors.white,
          ),
        ),
        title: Text(
          entry.foodName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            Text('${entry.amount} ${entry.unit.name}'),
            Text(entry.mealTypeDisplayName),
            Row(
              children: [
                ...List.generate(5, (i) => Icon(
                  i < entry.appetite ? Icons.star : Icons.star_border,
                  size: 16,
                  color: Colors.amber,
                )),
                const SizedBox(width: 10),
                if (entry.wasFinished)
                  const Icon(Icons.check_circle, size: 16, color: Colors.green),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Редактировать')),
            const PopupMenuItem(value: 'delete', child: Text('Удалить')),
          ],
          onSelected: (value) {
            if (value == 'delete') {
              _deleteEntry(entry);
            }
          },
        ),
      ),
    );
  }

  Widget _buildFoodsTab() {
    final foods = FoodDatabase.getAllFoods();
    
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: foods.length,
      itemBuilder: (context, index) {
        final food = foods[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getCategoryColor(food.category),
              child: Text(food.categoryDisplayName[0]),
            ),
            title: Text(food.name),
            subtitle: Text('${food.caloriesPer100g.toInt()} ккал/100${food.unitDisplayName}'),
            trailing: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _addFoodToMeal(food),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecipesTab() {
    return const Center(
      child: Text('Рецепты - в разработке'),
    );
  }

  Widget _buildAnalysisTab() {
    return const Center(
      child: Text('Анализ - в разработке'),
    );
  }

  // Вспомогательные методы
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(date.year, date.month, date.day);
    
    if (selectedDay == today) {
      return 'Сегодня';
    } else if (selectedDay == today.subtract(const Duration(days: 1))) {
      return 'Вчера';
    } else if (selectedDay == today.add(const Duration(days: 1))) {
      return 'Завтра';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }

  double _calculateTotalCalories() {
    return _todayEntries.fold(0.0, (sum, entry) => sum + (entry.amount * 0.5));
  }

  String _getAverageAppetite() {
    if (_todayEntries.isEmpty) return '0';
    final avg = _todayEntries.map((e) => e.appetite).reduce((a, b) => a + b) / _todayEntries.length;
    return avg.toStringAsFixed(1);
  }

  double _getAverageAppetiteScore() {
    if (_todayEntries.isEmpty) return 0;
    return _todayEntries.map((e) => e.appetite).reduce((a, b) => a + b) / _todayEntries.length;
  }

  Color _getMealTypeColor(MealType type) {
    switch (type) {
      case MealType.breakfast:
        return Colors.orange;
      case MealType.morningSnack:
        return Colors.amber;
      case MealType.lunch:
        return Colors.green;
      case MealType.afternoonSnack:
        return Colors.blue;
      case MealType.dinner:
        return Colors.purple;
      case MealType.eveningSnack:
        return Colors.indigo;
      case MealType.nightFeeding:
        return Colors.blueGrey;
    }
  }

  IconData _getMealTypeIcon(MealType type) {
    switch (type) {
      case MealType.breakfast:
        return Icons.free_breakfast;
      case MealType.morningSnack:
        return Icons.cookie;
      case MealType.lunch:
        return Icons.lunch_dining;
      case MealType.afternoonSnack:
        return Icons.local_cafe;
      case MealType.dinner:
        return Icons.dinner_dining;
      case MealType.eveningSnack:
        return Icons.nightlife;
      case MealType.nightFeeding:
        return Icons.bedtime;
    }
  }

  Color _getCategoryColor(FoodCategory category) {
    switch (category) {
      case FoodCategory.fruits:
        return Colors.red;
      case FoodCategory.vegetables:
        return Colors.green;
      case FoodCategory.grains:
        return Colors.amber;
      case FoodCategory.protein:
        return Colors.brown;
      case FoodCategory.dairy:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  // Действия
  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 7)),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadData();
    }
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
    _loadData();
  }

  void _showAddMealDialog() {
    // TODO: Implement add meal dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Добавление еды - в разработке')),
    );
  }

  void _showNutritionGoalsDialog() {
    // TODO: Implement nutrition goals dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Настройка целей питания - в разработке')),
    );
  }

  void _addFoodToMeal(FoodItem food) {
    // TODO: Implement add food to meal
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Добавить ${food.name} - в разработке')),
    );
  }

  Future<void> _deleteEntry(NutritionEntry entry) async {
    try {
      await FirebaseService.deleteNutritionEntry(entry.id);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Запись удалена')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка удаления: $e')),
        );
      }
    }
  }
}