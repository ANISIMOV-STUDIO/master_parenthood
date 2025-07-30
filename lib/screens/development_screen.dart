// lib/screens/development_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../services/firebase_service.dart';
import '../services/ai_service.dart';

class DevelopmentScreen extends StatefulWidget {
  const DevelopmentScreen({super.key});

  @override
  State<DevelopmentScreen> createState() => _DevelopmentScreenState();
}

class _DevelopmentScreenState extends State<DevelopmentScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _progressController;

  ChildProfile? _selectedChild;
  Map<String, dynamic>? _aiAnalysis;
  bool _isLoadingAnalysis = false;

  // Вехи развития по возрасту
  final Map<String, List<DevelopmentMilestone>> _milestones = {
    '0-6': [
      DevelopmentMilestone(
        title: 'Улыбается в ответ',
        description: 'Начинает улыбаться в ответ на улыбку взрослого',
        ageMonths: 2,
        category: 'social',
      ),
      DevelopmentMilestone(
        title: 'Держит голову',
        description: 'Уверенно держит голову в вертикальном положении',
        ageMonths: 3,
        category: 'physical',
      ),
      DevelopmentMilestone(
        title: 'Гулит',
        description: 'Произносит гласные звуки: "а", "у", "гу"',
        ageMonths: 3,
        category: 'speech',
      ),
      DevelopmentMilestone(
        title: 'Хватает игрушки',
        description: 'Целенаправленно хватает и удерживает предметы',
        ageMonths: 4,
        category: 'motor',
      ),
      DevelopmentMilestone(
        title: 'Переворачивается',
        description: 'Переворачивается со спины на живот и обратно',
        ageMonths: 5,
        category: 'physical',
      ),
    ],
    '6-12': [
      DevelopmentMilestone(
        title: 'Сидит без поддержки',
        description: 'Уверенно сидит без опоры',
        ageMonths: 7,
        category: 'physical',
      ),
      DevelopmentMilestone(
        title: 'Ползает',
        description: 'Передвигается ползком',
        ageMonths: 8,
        category: 'physical',
      ),
      DevelopmentMilestone(
        title: 'Говорит "мама", "папа"',
        description: 'Осознанно произносит простые слова',
        ageMonths: 10,
        category: 'speech',
      ),
      DevelopmentMilestone(
        title: 'Стоит с опорой',
        description: 'Встает и стоит, держась за опору',
        ageMonths: 9,
        category: 'physical',
      ),
      DevelopmentMilestone(
        title: 'Делает первые шаги',
        description: 'Начинает ходить самостоятельно',
        ageMonths: 12,
        category: 'physical',
      ),
    ],
    '12-24': [
      DevelopmentMilestone(
        title: 'Ходит уверенно',
        description: 'Ходит без поддержки, редко падает',
        ageMonths: 15,
        category: 'physical',
      ),
      DevelopmentMilestone(
        title: 'Говорит 10-20 слов',
        description: 'Активно использует простые слова',
        ageMonths: 18,
        category: 'speech',
      ),
      DevelopmentMilestone(
        title: 'Показывает части тела',
        description: 'Показывает нос, глаза, уши по просьбе',
        ageMonths: 18,
        category: 'cognitive',
      ),
      DevelopmentMilestone(
        title: 'Использует ложку',
        description: 'Самостоятельно ест ложкой',
        ageMonths: 18,
        category: 'motor',
      ),
      DevelopmentMilestone(
        title: 'Строит башню из кубиков',
        description: 'Строит башню из 3-4 кубиков',
        ageMonths: 20,
        category: 'motor',
      ),
    ],
    '24-36': [
      DevelopmentMilestone(
        title: 'Говорит предложениями',
        description: 'Составляет простые предложения из 2-3 слов',
        ageMonths: 24,
        category: 'speech',
      ),
      DevelopmentMilestone(
        title: 'Прыгает на двух ногах',
        description: 'Прыгает на месте на двух ногах',
        ageMonths: 30,
        category: 'physical',
      ),
      DevelopmentMilestone(
        title: 'Знает основные цвета',
        description: 'Различает и называет 3-4 основных цвета',
        ageMonths: 30,
        category: 'cognitive',
      ),
      DevelopmentMilestone(
        title: 'Играет с другими детьми',
        description: 'Участвует в совместных играх',
        ageMonths: 30,
        category: 'social',
      ),
      DevelopmentMilestone(
        title: 'Контролирует туалет',
        description: 'Просится на горшок днем',
        ageMonths: 30,
        category: 'self-care',
      ),
    ],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _progressController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..forward();
    _loadActiveChild();
  }

  Future<void> _loadActiveChild() async {
    final child = await FirebaseService.getActiveChild();
    if (child != null && mounted) {
      setState(() => _selectedChild = child);
      _loadAIAnalysis();
    }
  }

  Future<void> _loadAIAnalysis() async {
    if (_selectedChild == null) return;

    setState(() => _isLoadingAnalysis = true);

    try {
      final analysis = await AIService.getDevelopmentAnalysis(
        childName: _selectedChild!.name,
        ageInMonths: _selectedChild!.ageInMonths,
        language: Localizations.localeOf(context).languageCode,
      );

      setState(() {
        _aiAnalysis = analysis;
        _isLoadingAnalysis = false;
      });
    } catch (e) {
      setState(() => _isLoadingAnalysis = false);
      debugPrint('Error loading AI analysis: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Theme.of(context).primaryColor.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Заголовок
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    Expanded(
                      child: Text(
                        loc.development,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (_selectedChild != null)
                      CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor,
                        child: Text(
                          _selectedChild!.name[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),

              // Табы
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Вехи', icon: Icon(Icons.flag)),
                  Tab(text: 'Прогресс', icon: Icon(Icons.trending_up)),
                  Tab(text: 'Навыки', icon: Icon(Icons.star)),
                  Tab(text: 'AI Анализ', icon: Icon(Icons.psychology)),
                ],
                labelColor: Theme.of(context).primaryColor,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Theme.of(context).primaryColor,
              ),

              // Контент табов
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMilestonesTab(),
                    _buildProgressTab(),
                    _buildSkillsTab(),
                    _buildAIAnalysisTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMilestonesTab() {
    if (_selectedChild == null) {
      return const Center(child: Text('Выберите ребенка'));
    }

    final ageMonths = _selectedChild!.ageInMonths;
    String ageGroup = '0-6';
    if (ageMonths >= 6 && ageMonths < 12) {
      ageGroup = '6-12';
    } else if (ageMonths >= 12 && ageMonths < 24) {
      ageGroup = '12-24';
    } else if (ageMonths >= 24) {
      ageGroup = '24-36';
    }

    final relevantMilestones = _milestones[ageGroup] ?? [];

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: relevantMilestones.length,
      itemBuilder: (context, index) {
        final milestone = relevantMilestones[index];
        final isAchieved = ageMonths >= milestone.ageMonths;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isAchieved
                    ? Colors.green.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isAchieved ? Icons.check_circle : Icons.circle_outlined,
                color: isAchieved ? Colors.green : Colors.grey,
                size: 30,
              ),
            ),
            title: Text(
              milestone.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isAchieved ? Colors.black : Colors.grey,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(milestone.description),
                const SizedBox(height: 4),
                Text(
                  'Обычно в ${milestone.ageMonths} мес.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getMilestoneColor(milestone.category).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getMilestoneCategory(milestone.category),
                style: TextStyle(
                  fontSize: 12,
                  color: _getMilestoneColor(milestone.category),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ).animate()
            .fadeIn(delay: Duration(milliseconds: index * 100))
            .slideX(begin: 0.2);
      },
    );
  }

  Widget _buildProgressTab() {
    if (_selectedChild == null) {
      return const Center(child: Text('Выберите ребенка'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // График роста
          _buildGrowthChart(),
          const SizedBox(height: 32),

          // Статистика развития
          _buildDevelopmentStats(),
          const SizedBox(height: 32),

          // График прогресса по категориям
          _buildCategoryProgress(),
        ],
      ),
    );
  }

  Widget _buildGrowthChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.show_chart,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'График роста',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 10,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 3,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()} мес',
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 10,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()} см',
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: _selectedChild!.ageInMonths.toDouble(),
                minY: 40,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: _generateGrowthData(),
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withOpacity(0.5),
                      ],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: Theme.of(context).primaryColor,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor.withOpacity(0.2),
                          Theme.of(context).primaryColor.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
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
  }

  Widget _buildDevelopmentStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Статистика развития',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildStatCard('Рост', '${_selectedChild!.height ?? 0} см', Icons.height, Colors.blue)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Вес', '${_selectedChild!.weight ?? 0} кг', Icons.monitor_weight, Colors.green)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatCard('Слов', '${_selectedChild!.vocabularySize ?? 0}', Icons.abc, Colors.purple)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Навыков', '25', Icons.star, Colors.orange)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    ).animate()
        .fadeIn()
        .scale(begin: const Offset(0.8, 0.8));
  }

  Widget _buildCategoryProgress() {
    final categories = [
      {'name': 'Физическое', 'progress': 0.8, 'color': Colors.orange},
      {'name': 'Когнитивное', 'progress': 0.7, 'color': Colors.blue},
      {'name': 'Речевое', 'progress': 0.6, 'color': Colors.green},
      {'name': 'Социальное', 'progress': 0.75, 'color': Colors.purple},
      {'name': 'Моторика', 'progress': 0.85, 'color': Colors.red},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Прогресс по категориям',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ...categories.map((category) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        category['name'] as String,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '${((category['progress'] as double) * 100).toInt()}%',
                        style: TextStyle(
                          color: category['color'] as Color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AnimatedBuilder(
                    animation: _progressController,
                    builder: (context, child) {
                      return LinearProgressIndicator(
                        value: (category['progress'] as double) * _progressController.value,
                        backgroundColor: (category['color'] as Color).withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(category['color'] as Color),
                        minHeight: 8,
                      );
                    },
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildSkillsTab() {
    final skills = [
      {'category': 'motor', 'title': 'Держит карандаш', 'achieved': true},
      {'category': 'cognitive', 'title': 'Знает цвета', 'achieved': true},
      {'category': 'speech', 'title': 'Говорит предложениями', 'achieved': false},
      {'category': 'social', 'title': 'Играет с детьми', 'achieved': true},
      {'category': 'self-care', 'title': 'Одевается сам', 'achieved': false},
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Фильтр по категориям
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('Все', true),
              const SizedBox(width: 8),
              _buildFilterChip('Моторика', false),
              const SizedBox(width: 8),
              _buildFilterChip('Речь', false),
              const SizedBox(width: 8),
              _buildFilterChip('Социальные', false),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Список навыков
        ...skills.map((skill) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (skill['achieved'] as bool)
                      ? Colors.green.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  (skill['achieved'] as bool) ? Icons.check : Icons.circle_outlined,
                  color: (skill['achieved'] as bool) ? Colors.green : Colors.grey,
                ),
              ),
              title: Text(skill['title'] as String),
              subtitle: Text(_getMilestoneCategory(skill['category'] as String)),
              trailing: IconButton(
                onPressed: () {
                  // Переключить статус навыка
                },
                icon: Icon(
                  Icons.more_vert,
                  color: Colors.grey.shade400,
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        // Обработка фильтра
      },
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      checkmarkColor: Theme.of(context).primaryColor,
    );
  }

  Widget _buildAIAnalysisTab() {
    if (_selectedChild == null) {
      return const Center(child: Text('Выберите ребенка'));
    }

    if (_isLoadingAnalysis) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Анализирую развитие ${_selectedChild!.name}...',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    if (_aiAnalysis == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.psychology,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAIAnalysis,
              child: const Text('Получить AI анализ'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Сводка
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.purple.withOpacity(0.1),
                  Colors.blue.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.psychology,
                      color: Colors.purple,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'AI Анализ развития',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _aiAnalysis!['summary'] ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Сильные стороны
          _buildAnalysisSection(
            'Сильные стороны',
            Icons.star,
            Colors.amber,
            _aiAnalysis!['strengths'] ?? [],
          ),
          const SizedBox(height: 20),

          // Рекомендации
          _buildAnalysisSection(
            'Рекомендации',
            Icons.lightbulb,
            Colors.blue,
            _aiAnalysis!['suggestions'] ?? [],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisSection(String title, IconData icon, Color color, List<dynamic> items) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.toString(),
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  List<FlSpot> _generateGrowthData() {
    // Генерируем примерные данные роста
    final List<FlSpot> spots = [];
    final currentHeight = _selectedChild!.height ?? 50;
    final ageMonths = _selectedChild!.ageInMonths;

    for (int i = 0; i <= ageMonths; i++) {
      final height = 50 + (i * 2.5) + (i * 0.1);
      spots.add(FlSpot(i.toDouble(), height));
    }

    return spots;
  }

  Color _getMilestoneColor(String category) {
    switch (category) {
      case 'physical':
        return Colors.orange;
      case 'cognitive':
        return Colors.blue;
      case 'speech':
        return Colors.green;
      case 'social':
        return Colors.purple;
      case 'motor':
        return Colors.red;
      case 'self-care':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _getMilestoneCategory(String category) {
    switch (category) {
      case 'physical':
        return 'Физическое';
      case 'cognitive':
        return 'Когнитивное';
      case 'speech':
        return 'Речевое';
      case 'social':
        return 'Социальное';
      case 'motor':
        return 'Моторика';
      case 'self-care':
        return 'Самообслуживание';
      default:
        return 'Общее';
    }
  }
}

// Модель вехи развития
class DevelopmentMilestone {
  final String title;
  final String description;
  final int ageMonths;
  final String category;

  DevelopmentMilestone({
    required this.title,
    required this.description,
    required this.ageMonths,
    required this.category,
  });
}