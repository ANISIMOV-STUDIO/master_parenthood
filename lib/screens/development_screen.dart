// lib/screens/development_screen.dart
import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

class DevelopmentScreen extends StatefulWidget {
  final String childId;

  const DevelopmentScreen({super.key, required this.childId});

  @override
  State<DevelopmentScreen> createState() => _DevelopmentScreenState();
}

class _DevelopmentScreenState extends State<DevelopmentScreen>
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;
  List<DevelopmentActivity> _activities = [];
  List<ActivityCompletion> _completions = [];
  bool _isLoading = true;
  DevelopmentArea? _selectedArea;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDevelopmentData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDevelopmentData() async {
    setState(() => _isLoading = true);
    
    try {
      // Загружаем рекомендуемые активности
      final recommendedActivities = await FirebaseService.getRecommendedActivities(widget.childId);
      
      // Загружаем завершенные активности
      FirebaseService.getActivityCompletionsStream(widget.childId).listen((completions) {
        setState(() {
          _completions = completions;
        });
      });
      
      setState(() {
        _activities = recommendedActivities;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Раннее развитие'),
        backgroundColor: Colors.purple[700],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.lightbulb), text: 'Рекомендации'),
            Tab(icon: Icon(Icons.category), text: 'По областям'),
            Tab(icon: Icon(Icons.history), text: 'История'),
            Tab(icon: Icon(Icons.analytics), text: 'Прогресс'),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRecommendationsTab(),
                _buildAreaFilterTab(),
                _buildHistoryTab(),
                _buildProgressTab(),
              ],
            ),
    );
  }

  Widget _buildRecommendationsTab() {
    if (_activities.isEmpty) {
      return _buildEmptyState('Нет рекомендуемых активностей');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _activities.length,
      itemBuilder: (context, index) {
        final activity = _activities[index];
        return _buildActivityCard(activity);
      },
    );
  }

  Widget _buildAreaFilterTab() {
    return Column(
      children: [
        // Фильтр по областям развития
        Container(
          height: 120,
          padding: const EdgeInsets.all(16),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: DevelopmentArea.values.length,
            itemBuilder: (context, index) {
              final area = DevelopmentArea.values[index];
              final isSelected = _selectedArea == area;
              
              return Container(
                margin: const EdgeInsets.only(right: 12),
                child: FilterChip(
                  selected: isSelected,
                  onSelected: (selected) => _filterByArea(selected ? area : null),
                  avatar: Text(
                    area.iconEmoji,
                    style: const TextStyle(fontSize: 16),
                  ),
                  label: Text(
                    area.displayName,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Color(area.colorHex),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  backgroundColor: isSelected 
                      ? Color(area.colorHex) 
                      : Color(area.colorHex).withValues(alpha: 0.1),
                  selectedColor: Color(area.colorHex),
                  checkmarkColor: Colors.white,
                  side: BorderSide(
                    color: Color(area.colorHex).withValues(alpha: 0.3),
                  ),
                ),
              );
            },
          ),
        ),
        
        // Список активностей по выбранной области
        Expanded(
          child: _buildFilteredActivities(),
        ),
      ],
    );
  }

  Widget _buildFilteredActivities() {
    if (_selectedArea == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.filter_list, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Выберите область развития',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return FutureBuilder<List<DevelopmentActivity>>(
      future: FirebaseService.getActivitiesByArea(_selectedArea!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Ошибка: ${snapshot.error}'));
        }
        
        final activities = snapshot.data ?? [];
        
        if (activities.isEmpty) {
          return _buildEmptyState('Нет активностей для выбранной области');
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: activities.length,
          itemBuilder: (context, index) {
            final activity = activities[index];
            return _buildActivityCard(activity);
          },
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    if (_completions.isEmpty) {
      return _buildEmptyState('Нет выполненных активностей');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _completions.length,
      itemBuilder: (context, index) {
        final completion = _completions[index];
        return _buildCompletionCard(completion);
      },
    );
  }

  Widget _buildProgressTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: FirebaseService.generateDevelopmentReport(widget.childId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Ошибка: ${snapshot.error}'));
        }
        
        final report = snapshot.data ?? {};
        return _buildProgressReport(report);
      },
    );
  }

  Widget _buildActivityCard(DevelopmentActivity activity) {
    final isCompleted = _completions.any((c) => c.activityId == activity.id);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showActivityDetails(activity),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Иконка области развития
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Color(activity.area.colorHex).withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          activity.area.iconEmoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Заголовок и область
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          
                          const SizedBox(height: 4),
                          
                          Text(
                            activity.area.displayName,
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(activity.area.colorHex),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Статус выполнения
                    if (isCompleted)
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 28,
                      ),
                    
                    // Рейтинг и сложность
                    Column(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                            Text(
                              activity.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 4),
                        
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Color(activity.difficulty.colorHex),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            activity.difficulty.displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Описание
                Text(
                  activity.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 12),
                
                // Метрики
                Row(
                  children: [
                    _buildMetricChip(
                      icon: Icons.timer,
                      label: activity.formattedDuration,
                      color: Colors.blue,
                    ),
                    
                    const SizedBox(width: 12),
                    
                    _buildMetricChip(
                      icon: Icons.child_care,
                      label: activity.ageRange.displayName,
                      color: Colors.green,
                    ),
                    
                    const SizedBox(width: 12),
                    
                    if (activity.requiresAdult)
                      _buildMetricChip(
                        icon: Icons.supervisor_account,
                        label: 'С взрослым',
                        color: Colors.orange,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionCard(ActivityCompletion completion) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Color(completion.successColorHex).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                completion.wasCompleted ? Icons.check : Icons.close,
                color: Color(completion.successColorHex),
              ),
            ),
          ),
          title: FutureBuilder<DevelopmentActivity?>(
            future: _getActivityById(completion.activityId),
            builder: (context, snapshot) {
              final activity = snapshot.data;
              return Text(
                activity?.title ?? 'Активность не найдена',
                style: const TextStyle(fontWeight: FontWeight.w600),
              );
            },
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(completion.formattedDate),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text('Время: ${completion.formattedDuration}'),
                  const SizedBox(width: 16),
                  Text('Оценка: ${completion.averageRating.toStringAsFixed(1)}'),
                ],
              ),
            ],
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Color(completion.successColorHex),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              completion.successLevel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressReport(Map<String, dynamic> report) {
    final areaScores = Map<String, double>.from(report['areaScores'] ?? {});
    final recommendations = List<String>.from(report['recommendations'] ?? []);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Общая статистика
          _buildStatsCard(report),
          
          const SizedBox(height: 20),
          
          // Прогресс по областям
          if (areaScores.isNotEmpty) ...[
            const Text(
              'Прогресс по областям развития',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            ...areaScores.entries.map((entry) => _buildProgressBar(
              entry.key,
              entry.value,
            )),
            
            const SizedBox(height: 20),
          ],
          
          // Рекомендации
          if (recommendations.isNotEmpty) ...[
            const Text(
              'Рекомендации',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            ...recommendations.map((rec) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(rec)),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsCard(Map<String, dynamic> report) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Общая статистика',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Активностей',
                    '${report['recentActivitiesCount'] ?? 0}',
                    Icons.play_arrow,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Завершено',
                    '${report['completedActivities'] ?? 0}',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Ср. оценка',
                    (report['averageRating'] ?? 0.0).toStringAsFixed(1),
                    Icons.star,
                    Colors.amber,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
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

  Widget _buildProgressBar(String areaName, double score) {
    final color = _getProgressColor(score);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                areaName,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                '${score.toInt()}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          LinearProgressIndicator(
            value: score / 100,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.psychology,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  void _filterByArea(DevelopmentArea? area) {
    setState(() {
      _selectedArea = area;
    });
  }

  Future<DevelopmentActivity?> _getActivityById(String activityId) async {
    try {
      // Простой поиск активности по ID
      final allActivities = await FirebaseService.getDevelopmentActivitiesStream().first;
      return allActivities.firstWhere((a) => a.id == activityId);
    } catch (e) {
      return null;
    }
  }

  void _showActivityDetails(DevelopmentActivity activity) {
    showDialog(
      context: context,
      builder: (context) => ActivityDetailDialog(
        activity: activity,
        childId: widget.childId,
        onCompleted: _loadDevelopmentData,
      ),
    );
  }
}

// Диалог детальной информации об активности
class ActivityDetailDialog extends StatelessWidget {
  final DevelopmentActivity activity;
  final String childId;
  final VoidCallback onCompleted;

  const ActivityDetailDialog({
    super.key,
    required this.activity,
    required this.childId,
    required this.onCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Color(activity.area.colorHex).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      activity.area.iconEmoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        activity.area.displayName,
                        style: TextStyle(
                          color: Color(activity.area.colorHex),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Описание
            Text(
              activity.description,
              style: const TextStyle(fontSize: 16),
            ),
            
            const SizedBox(height: 16),
            
            // Метрики
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildChip(Icons.timer, activity.formattedDuration, Colors.blue),
                _buildChip(Icons.child_care, activity.ageRange.displayName, Colors.green),
                _buildChip(Icons.trending_up, activity.difficulty.displayName, Color(activity.difficulty.colorHex)),
                if (activity.requiresAdult)
                  _buildChip(Icons.supervisor_account, 'С взрослым', Colors.orange),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Материалы
            if (activity.materials.isNotEmpty) ...[
              const Text(
                'Материалы:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...activity.materials.map((material) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 8, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(child: Text(material)),
                  ],
                ),
              )),
              
              const SizedBox(height: 16),
            ],
            
            // Кнопки действий
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Закрыть'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _startActivity(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(activity.area.colorHex),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Начать'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _startActivity(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Начинаем активность: ${activity.title}'),
        backgroundColor: Color(activity.area.colorHex),
      ),
    );
    onCompleted();
  }
}