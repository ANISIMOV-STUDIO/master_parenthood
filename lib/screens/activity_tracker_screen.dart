// lib/screens/activity_tracker_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'dart:math' as math;
import '../services/firebase_service.dart';
import '../services/offline_service.dart';
import '../services/connectivity_service.dart';
import 'package:provider/provider.dart';

class ActivityTrackerScreen extends StatefulWidget {
  const ActivityTrackerScreen({super.key});

  @override
  State<ActivityTrackerScreen> createState() => _ActivityTrackerScreenState();
}

class _ActivityTrackerScreenState extends State<ActivityTrackerScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _cardController;
  late TabController _tabController;
  
  ChildProfile? _activeChild;
  List<Activity> _todayActivities = [];
  DateTime _selectedDate = DateTime.now();
  
  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _headerController.dispose();
    _cardController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final activeChild = await FirebaseService.getActiveChild();
    if (mounted && activeChild != null) {
      setState(() {
        _activeChild = activeChild;
      });
      _loadActivities();
      _headerController.forward();
      _cardController.forward();
    }
  }

  void _loadActivities() {
    if (_activeChild == null) return;
    
    final connectivityService = Provider.of<ConnectivityService>(context, listen: false);
    
    if (connectivityService.hasInternet) {
      // Подписываемся на stream активностей для выбранной даты
      FirebaseService.getActivitiesStream(_activeChild!.id, _selectedDate).listen((activities) {
        if (mounted) {
          setState(() {
            _todayActivities = activities;
          });
          // Сохраняем данные offline
          for (final activity in activities) {
            OfflineService.saveActivityOffline(activity);
          }
        }
      });
    } else {
      // Загружаем данные из offline хранилища
      final offlineActivities = OfflineService.getActivitiesOffline(_activeChild!.id, _selectedDate);
      setState(() {
        _todayActivities = offlineActivities;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Трекер активностей'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDate,
          ),
        ],
      ),
      body: _activeChild == null
          ? _buildNoDataState()
          : Column(
              children: [
                _buildHeader(),
                _buildDateSelector(),
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverview(),
                      _buildSleepTab(),
                      _buildFeedingTab(),
                      _buildActivityTab(),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: _activeChild != null
          ? FloatingActionButton.extended(
              onPressed: _showAddActivityDialog,
              icon: const Icon(Icons.add),
              label: const Text('Добавить'),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Widget _buildNoDataState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timeline,
            size: 100,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 24),
          Text(
            'Нет данных активности',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Добавьте профиль ребенка\nчтобы отслеживать активности',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ).animate().fadeIn().slideY(begin: 0.3),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.teal.shade400,
            Colors.cyan.shade400,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.timeline,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Активности ${_activeChild!.name}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_todayActivities.length} записей сегодня',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getMoodIcon(_getAverageMood()),
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    ).animate(controller: _headerController).fadeIn().slideX(begin: -0.3);
  }

  Widget _buildDateSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: () {
                          setState(() {
              _selectedDate = _selectedDate.subtract(const Duration(days: 1));
              _loadActivities(); // Перезагружаем активности для новой даты
            });
            },
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Text(
              _formatSelectedDate(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: _selectedDate.day < DateTime.now().day
                ? () {
                    setState(() {
                      _selectedDate = _selectedDate.add(const Duration(days: 1));
                      _loadActivities(); // Перезагружаем активности для новой даты
                    });
                  }
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    ).animate(controller: _headerController).fadeIn(delay: 200.ms).scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade400, Colors.cyan.shade400],
          ),
          borderRadius: BorderRadius.circular(25),
        ),
        tabs: const [
          Tab(text: 'Обзор'),
          Tab(text: 'Сон'),
          Tab(text: 'Еда'),
          Tab(text: 'Прогулки'),
        ],
      ),
    ).animate(controller: _headerController).fadeIn(delay: 400.ms).slideY(begin: -0.2);
  }

  Widget _buildOverview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsRow(),
          const SizedBox(height: 24),
          _buildTimeline(),
          const SizedBox(height: 24),
          _buildMoodChart(),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final sleepActivities = _todayActivities.where((a) => a.type == ActivityType.sleep).toList();
    final feedingActivities = _todayActivities.where((a) => a.type == ActivityType.feeding).toList();
    final walkActivities = _todayActivities.where((a) => a.type == ActivityType.walk).toList();
    
    final totalSleep = sleepActivities.fold<int>(0, (sum, activity) {
      return sum + (activity.endTime?.difference(activity.startTime).inMinutes ?? 0);
    });
    
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Сон',
            '${(totalSleep / 60).toStringAsFixed(1)}ч',
            '${sleepActivities.length} раз',
            Icons.bedtime,
            Colors.purple,
            0,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Кормления',
            '${feedingActivities.length}',
            'раз',
            Icons.restaurant,
            Colors.orange,
            1,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Прогулки',
            '${walkActivities.length}',
            'раз',
            Icons.directions_walk,
            Colors.green,
            2,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, 
      IconData icon, Color color, int index) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    ).animate(controller: _cardController)
      .fadeIn(delay: (index * 100).ms)
      .slideY(begin: 0.3);
  }

  Widget _buildTimeline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Расписание дня',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 300,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListView.builder(
            itemCount: _todayActivities.length,
            itemBuilder: (context, index) {
              final activity = _todayActivities[index];
              return _buildTimelineItem(activity, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem(Activity activity, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 50,
            child: Text(
              '${activity.startTime.hour.toString().padLeft(2, '0')}:${activity.startTime.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getActivityColor(activity.type).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getActivityIcon(activity.type),
              color: _getActivityColor(activity.type),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getActivityTitle(activity.type),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (activity.notes.isNotEmpty)
                  Text(
                    activity.notes,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
          Icon(
            _getMoodIcon(activity.mood),
            color: _getMoodColor(activity.mood),
            size: 20,
          ),
        ],
      ),
    ).animate(controller: _cardController)
      .fadeIn(delay: (200 + index * 100).ms)
      .slideX(begin: 0.3);
  }

  Widget _buildMoodChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Настроение за день',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMoodItem(Mood.excited, 'Восторг', 2),
              _buildMoodItem(Mood.happy, 'Радость', 5),
              _buildMoodItem(Mood.calm, 'Спокойствие', 3),
              _buildMoodItem(Mood.sad, 'Грусть', 1),
              _buildMoodItem(Mood.crying, 'Плач', 0),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMoodItem(Mood mood, String label, int count) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 40,
          height: count * 20.0 + 20,
          decoration: BoxDecoration(
            color: _getMoodColor(mood).withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Icon(
          _getMoodIcon(mood),
          color: _getMoodColor(mood),
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSleepTab() {
    final sleepActivities = _todayActivities.where((a) => a.type == ActivityType.sleep).toList();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSleepStats(sleepActivities),
          const SizedBox(height: 24),
          _buildSleepChart(sleepActivities),
          const SizedBox(height: 24),
          _buildSleepList(sleepActivities),
        ],
      ),
    );
  }

  Widget _buildSleepStats(List<Activity> sleepActivities) {
    final totalSleep = sleepActivities.fold<int>(0, (sum, activity) {
      return sum + (activity.endTime?.difference(activity.startTime).inMinutes ?? 0);
    });
    
    final avgSleep = sleepActivities.isNotEmpty ? totalSleep / sleepActivities.length : 0;
    
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Всего сна',
            '${(totalSleep / 60).toStringAsFixed(1)}ч',
            '${totalSleep % 60}мин',
            Icons.bedtime,
            Colors.purple,
            0,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Среднее',
            '${(avgSleep / 60).toStringAsFixed(1)}ч',
            'за сон',
            Icons.access_time,
            Colors.indigo,
            1,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Количество',
            '${sleepActivities.length}',
            'снов',
            Icons.hotel,
            Colors.blue,
            2,
          ),
        ),
      ],
    );
  }

  Widget _buildSleepChart(List<Activity> sleepActivities) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'График сна',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              children: List.generate(24, (hour) {
                final hasSleep = sleepActivities.any((activity) {
                  final startHour = activity.startTime.hour;
                  final endHour = activity.endTime?.hour ?? startHour;
                  return hour >= startHour && hour <= endHour;
                });
                
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: hasSleep 
                          ? Colors.purple.withValues(alpha: 0.7)
                          : Colors.grey.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: hour % 6 == 0
                        ? Center(
                            child: Text(
                              hour.toString(),
                              style: TextStyle(
                                fontSize: 8,
                                color: hasSleep ? Colors.white : Colors.grey.shade600,
                              ),
                            ),
                          )
                        : null,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSleepList(List<Activity> sleepActivities) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Периоды сна',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...sleepActivities.map((activity) => _buildActivityCard(activity)),
      ],
    );
  }

  Widget _buildFeedingTab() {
    final feedingActivities = _todayActivities.where((a) => a.type == ActivityType.feeding).toList();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFeedingStats(feedingActivities),
          const SizedBox(height: 24),
          _buildFeedingList(feedingActivities),
        ],
      ),
    );
  }

  Widget _buildFeedingStats(List<Activity> feedingActivities) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Кормлений',
            '${feedingActivities.length}',
            'раз',
            Icons.restaurant,
            Colors.orange,
            0,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Последнее',
            feedingActivities.isNotEmpty 
                ? '${feedingActivities.last.startTime.hour}:${feedingActivities.last.startTime.minute.toString().padLeft(2, '0')}'
                : '--:--',
            'время',
            Icons.schedule,
            Colors.deepOrange,
            1,
          ),
        ),
      ],
    );
  }

  Widget _buildFeedingList(List<Activity> feedingActivities) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Список кормлений',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...feedingActivities.map((activity) => _buildActivityCard(activity)),
      ],
    );
  }

  Widget _buildActivityTab() {
    final walkActivities = _todayActivities.where((a) => a.type == ActivityType.walk).toList();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWalkStats(walkActivities),
          const SizedBox(height: 24),
          _buildWalkList(walkActivities),
        ],
      ),
    );
  }

  Widget _buildWalkStats(List<Activity> walkActivities) {
    final totalWalk = walkActivities.fold<int>(0, (sum, activity) {
      return sum + (activity.endTime?.difference(activity.startTime).inMinutes ?? 0);
    });
    
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Прогулок',
            '${walkActivities.length}',
            'раз',
            Icons.directions_walk,
            Colors.green,
            0,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Всего',
            '${totalWalk}',
            'минут',
            Icons.timer,
            Colors.teal,
            1,
          ),
        ),
      ],
    );
  }

  Widget _buildWalkList(List<Activity> walkActivities) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Список прогулок',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...walkActivities.map((activity) => _buildActivityCard(activity)),
      ],
    );
  }

  Widget _buildActivityCard(Activity activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getActivityColor(activity.type).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getActivityIcon(activity.type),
              color: _getActivityColor(activity.type),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getActivityTitle(activity.type),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${activity.startTime.hour.toString().padLeft(2, '0')}:${activity.startTime.minute.toString().padLeft(2, '0')} - ${activity.endTime?.hour.toString().padLeft(2, '0')}:${activity.endTime?.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (activity.notes.isNotEmpty)
                  Text(
                    activity.notes,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
          Icon(
            _getMoodIcon(activity.mood),
            color: _getMoodColor(activity.mood),
            size: 20,
          ),
        ],
      ),
    );
  }

  // Вспомогательные методы
  Color _getActivityColor(ActivityType type) {
    switch (type) {
      case ActivityType.sleep:
        return Colors.purple;
      case ActivityType.feeding:
        return Colors.orange;
      case ActivityType.walk:
        return Colors.green;
      case ActivityType.play:
        return Colors.blue;
    }
  }

  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.sleep:
        return Icons.bedtime;
      case ActivityType.feeding:
        return Icons.restaurant;
      case ActivityType.walk:
        return Icons.directions_walk;
      case ActivityType.play:
        return Icons.toys;
    }
  }

  String _getActivityTitle(ActivityType type) {
    switch (type) {
      case ActivityType.sleep:
        return 'Сон';
      case ActivityType.feeding:
        return 'Кормление';
      case ActivityType.walk:
        return 'Прогулка';
      case ActivityType.play:
        return 'Игра';
    }
  }

  Color _getMoodColor(Mood mood) {
    switch (mood) {
      case Mood.excited:
        return Colors.yellow;
      case Mood.happy:
        return Colors.green;
      case Mood.calm:
        return Colors.blue;
      case Mood.sad:
        return Colors.orange;
      case Mood.crying:
        return Colors.red;
    }
  }

  IconData _getMoodIcon(Mood mood) {
    switch (mood) {
      case Mood.excited:
        return Icons.sentiment_very_satisfied;
      case Mood.happy:
        return Icons.sentiment_satisfied;
      case Mood.calm:
        return Icons.sentiment_neutral;
      case Mood.sad:
        return Icons.sentiment_dissatisfied;
      case Mood.crying:
        return Icons.sentiment_very_dissatisfied;
    }
  }

  Mood _getAverageMood() {
    if (_todayActivities.isEmpty) return Mood.calm;
    
    final moodCounts = <Mood, int>{};
    for (final activity in _todayActivities) {
      moodCounts[activity.mood] = (moodCounts[activity.mood] ?? 0) + 1;
    }
    
    return moodCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  String _formatSelectedDate() {
    final now = DateTime.now();
    if (_selectedDate.day == now.day && 
        _selectedDate.month == now.month && 
        _selectedDate.year == now.year) {
      return 'Сегодня';
    }
    
    final yesterday = now.subtract(const Duration(days: 1));
    if (_selectedDate.day == yesterday.day && 
        _selectedDate.month == yesterday.month && 
        _selectedDate.year == yesterday.year) {
      return 'Вчера';
    }
    
    return '${_selectedDate.day}.${_selectedDate.month.toString().padLeft(2, '0')}.${_selectedDate.year}';
  }

  void _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _loadActivities(); // Перезагружаем активности для выбранной даты
      });
    }
  }

  void _showAddActivityDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddActivityDialog(
        onSave: (activity) {
          setState(() {
            _todayActivities.insert(0, activity);
          });
        },
        childId: _activeChild!.id,
      ),
    );
  }
}

// Импортируем модели из firebase_service.dart

// Диалог добавления активности
class _AddActivityDialog extends StatefulWidget {
  final Function(Activity) onSave;
  final String childId;

  const _AddActivityDialog({
    required this.onSave,
    required this.childId,
  });

  @override
  State<_AddActivityDialog> createState() => _AddActivityDialogState();
}

class _AddActivityDialogState extends State<_AddActivityDialog> {
  ActivityType _selectedType = ActivityType.feeding;
  Mood _selectedMood = Mood.happy;
  DateTime _startTime = DateTime.now();
  DateTime? _endTime;
  final _notesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Добавить активность',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<ActivityType>(
            value: _selectedType,
            decoration: const InputDecoration(
              labelText: 'Тип активности',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _selectedType = value!;
              });
            },
            items: const [
              DropdownMenuItem(
                value: ActivityType.sleep,
                child: Text('Сон'),
              ),
              DropdownMenuItem(
                value: ActivityType.feeding,
                child: Text('Кормление'),
              ),
              DropdownMenuItem(
                value: ActivityType.walk,
                child: Text('Прогулка'),
              ),
              DropdownMenuItem(
                value: ActivityType.play,
                child: Text('Игра'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Заметки',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<Mood>(
            value: _selectedMood,
            decoration: const InputDecoration(
              labelText: 'Настроение',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _selectedMood = value!;
              });
            },
            items: const [
              DropdownMenuItem(
                value: Mood.excited,
                child: Text('😄 Восторг'),
              ),
              DropdownMenuItem(
                value: Mood.happy,
                child: Text('😊 Радость'),
              ),
              DropdownMenuItem(
                value: Mood.calm,
                child: Text('😐 Спокойствие'),
              ),
              DropdownMenuItem(
                value: Mood.sad,
                child: Text('😔 Грусть'),
              ),
              DropdownMenuItem(
                value: Mood.crying,
                child: Text('😭 Плач'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Отмена'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final activity = Activity(
                      id: '', // Firebase сгенерирует ID
                      childId: widget.childId,
                      type: _selectedType,
                      startTime: _startTime,
                      endTime: _selectedType == ActivityType.sleep 
                          ? _startTime.add(const Duration(hours: 2))
                          : _startTime.add(const Duration(minutes: 30)),
                      notes: _notesController.text,
                      mood: _selectedMood,
                    );
                    
                    try {
                      final connectivityService = Provider.of<ConnectivityService>(context, listen: false);
                      
                      if (connectivityService.hasInternet) {
                        // Сохраняем в Firebase
                        await FirebaseService.createActivity(activity);
                      } else {
                        // Сохраняем offline
                        await OfflineService.saveActivityOffline(activity);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Активность сохранена offline. Синхронизируется при подключении к интернету.')),
                        );
                      }
                      
                      widget.onSave(activity);
                      Navigator.pop(context);
                    } catch (e) {
                      // В случае ошибки сохраняем offline
                      await OfflineService.saveActivityOffline(activity);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Активность сохранена offline. Синхронизируется позже.')),
                      );
                      widget.onSave(activity);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Сохранить'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}