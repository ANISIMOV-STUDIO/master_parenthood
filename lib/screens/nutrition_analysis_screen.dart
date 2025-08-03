// lib/screens/nutrition_analysis_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/firebase_service.dart';

class NutritionAnalysisScreen extends StatefulWidget {
  final String childId;

  const NutritionAnalysisScreen({super.key, required this.childId});

  @override
  State<NutritionAnalysisScreen> createState() => _NutritionAnalysisScreenState();
}

class _NutritionAnalysisScreenState extends State<NutritionAnalysisScreen>
    with TickerProviderStateMixin {
  
  late TabController _tabController;
  late AnimationController _chartsController;
  late Animation<double> _fadeAnimation;
  
  DailyNutritionAnalysis? _todayAnalysis;
  List<DailyNutritionAnalysis> _weekAnalyses = [];
  Map<String, dynamic>? _weekStats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _chartsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _chartsController, curve: Curves.easeInOut),
    );
    
    _loadAnalysisData();
    _chartsController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chartsController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalysisData() async {
    setState(() => _isLoading = true);
    
    try {
      // Загружаем цели питания

      // Создаем анализ за сегодня
      final todayAnalysis = await FirebaseService.generateDailyNutritionAnalysis(
        widget.childId, 
        DateTime.now()
      );
      
      // Загружаем анализы за неделю
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 7));
      
      final weekStats = await FirebaseService.getNutritionStats(
        widget.childId, 
        startDate, 
        endDate
      );
      
      // Загружаем анализы
      FirebaseService.getNutritionAnalysesStream(widget.childId).listen((analyses) {
        setState(() {
          _weekAnalyses = analyses.take(7).toList();
        });
      });
      
      setState(() {
        _todayAnalysis = todayAnalysis;
        _weekStats = weekStats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки анализа: $e'),
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
              Colors.indigo[700]!,
              Colors.indigo[500]!,
              Colors.indigo[300]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              if (_todayAnalysis != null) _buildTodayOverview(),
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
    return Container(
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
                  'Анализ питания',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Детальная аналитика и рекомендации',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _generateNewAnalysis,
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayOverview() {
    final analysis = _todayAnalysis!;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Сегодня',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo[700],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getScoreColor(analysis.overallScore),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${analysis.overallScore.toInt()}/100',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          
          Row(
            children: [
              Expanded(
                child: _buildMiniProgress(
                  'Калории',
                  analysis.calorieCompletion,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildMiniProgress(
                  'Белки',
                  analysis.proteinCompletion,
                  Colors.red,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildMiniProgress(
                  'Вит. C',
                  analysis.vitaminCCompletion,
                  Colors.green,
                ),
              ),
            ],
          ),
          
          if (analysis.hasAchievements || analysis.hasDeficiencies) ...[
            const SizedBox(height: 15),
            Row(
              children: [
                if (analysis.hasAchievements) ...[
                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 5),
                  Text(
                    '${analysis.achievements.length} достижений',
                    style: const TextStyle(color: Colors.green, fontSize: 12),
                  ),
                ],
                if (analysis.hasAchievements && analysis.hasDeficiencies)
                  const SizedBox(width: 15),
                if (analysis.hasDeficiencies) ...[
                  const Icon(Icons.warning, color: Colors.orange, size: 16),
                  const SizedBox(width: 5),
                  Text(
                    '${analysis.concerns.length} проблем',
                    style: const TextStyle(color: Colors.orange, fontSize: 12),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniProgress(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 5),
        LinearProgressIndicator(
          value: (value / 100).clamp(0.0, 1.0),
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
        const SizedBox(height: 5),
        Text(
          '${value.toInt()}%',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
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
          color: Colors.indigo[600],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.indigo[700],
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        tabs: const [
          Tab(text: 'Детали'),
          Tab(text: 'Графики'),
          Tab(text: 'Тренды'),
          Tab(text: 'Советы'),
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
          _buildDetailsTab(),
          _buildChartsTab(),
          _buildTrendsTab(),
          _buildRecommendationsTab(),
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    if (_isLoading || _todayAnalysis == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final analysis = _todayAnalysis!;
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              analysis.overallAssessment,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _getScoreColor(analysis.overallScore),
              ),
            ),
            const SizedBox(height: 20),
            
            // Макронутриенты
            _buildNutrientSection('Макронутриенты', [
              _buildNutrientRow(
                'Калории',
                '${analysis.actualCalories.toInt()}',
                '${analysis.goals.targetCalories.toInt()}',
                analysis.calorieCompletion,
                'ккал',
                Colors.orange,
              ),
              _buildNutrientRow(
                'Белки',
                analysis.actualProtein.toStringAsFixed(1),
                analysis.goals.targetProtein.toStringAsFixed(1),
                analysis.proteinCompletion,
                'г',
                Colors.red,
              ),
              _buildNutrientRow(
                'Жиры',
                analysis.actualFats.toStringAsFixed(1),
                analysis.goals.targetFats.toStringAsFixed(1),
                analysis.goalCompletion['fats'] ?? 0,
                'г',
                Colors.yellow[700]!,
              ),
              _buildNutrientRow(
                'Углеводы',
                analysis.actualCarbs.toStringAsFixed(1),
                analysis.goals.targetCarbs.toStringAsFixed(1),
                analysis.goalCompletion['carbs'] ?? 0,
                'г',
                Colors.blue,
              ),
            ]),
            
            const SizedBox(height: 20),
            
            // Витамины и минералы
            _buildNutrientSection('Витамины и минералы', [
              _buildNutrientRow(
                'Витамин C',
                analysis.actualVitaminC.toStringAsFixed(1),
                analysis.goals.targetVitaminC.toStringAsFixed(1),
                analysis.vitaminCCompletion,
                'мг',
                Colors.green,
              ),
              _buildNutrientRow(
                'Витамин D',
                analysis.actualVitaminD.toStringAsFixed(1),
                analysis.goals.targetVitaminD.toStringAsFixed(1),
                analysis.goalCompletion['vitaminD'] ?? 0,
                'мкг',
                Colors.purple,
              ),
              _buildNutrientRow(
                'Кальций',
                analysis.actualCalcium.toStringAsFixed(1),
                analysis.goals.targetCalcium.toStringAsFixed(1),
                analysis.goalCompletion['calcium'] ?? 0,
                'мг',
                Colors.indigo,
              ),
              _buildNutrientRow(
                'Железо',
                analysis.actualIron.toStringAsFixed(1),
                analysis.goals.targetIron.toStringAsFixed(1),
                analysis.goalCompletion['iron'] ?? 0,
                'мг',
                Colors.brown,
              ),
            ]),
            
            const SizedBox(height: 20),
            
            // Статистика приемов пищи
            _buildSection('Статистика приемов пищи', [
              _buildStatRow('Всего приемов пищи', '${analysis.totalMeals}'),
              _buildStatRow('Завершенных порций', '${analysis.mealsFinished}'),
              _buildStatRow('Процент завершения', '${analysis.finishedMealsPercentage.toStringAsFixed(1)}%'),
              _buildStatRow('Средний аппетит', '${analysis.averageAppetite.toStringAsFixed(1)}/5'),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsTab() {
    if (_isLoading || _todayAnalysis == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Круговая диаграмма макронутриентов
            _buildChartCard(
              'Распределение макронутриентов',
              SizedBox(
                height: 250,
                child: PieChart(
                  PieChartData(
                    sections: _buildMacroSections(),
                    centerSpaceRadius: 60,
                    sectionsSpace: 2,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Барная диаграмма выполнения целей
            _buildChartCard(
              'Выполнение целей питания',
              SizedBox(
                height: 250,
                child: BarChart(
                  BarChartData(
                    barGroups: _buildGoalBars(),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text('${value.toInt()}%');
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            const titles = ['Кал', 'Белки', 'Жиры', 'Угл', 'ВитC'];
                            if (value.toInt() < titles.length) {
                              return Text(titles[value.toInt()]);
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    maxY: 150,
                    gridData: const FlGridData(show: true),
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendsTab() {
    if (_isLoading || _weekStats == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('Статистика за неделю', [
              _buildStatRow('Общее количество записей', '${_weekStats!['totalEntries']}'),
              _buildStatRow('Завершенных приемов пищи', '${_weekStats!['finishedMeals']}'),
              _buildStatRow('Процент завершения', '${(_weekStats!['finishedPercentage'] as double).toStringAsFixed(1)}%'),
              _buildStatRow('Средний аппетит', '${(_weekStats!['averageAppetite'] as double).toStringAsFixed(1)}/5'),
              _buildStatRow('Любимый продукт', '${_weekStats!['favoriteFood']}'),
              _buildStatRow('Уникальных продуктов', '${_weekStats!['uniqueFoods']}'),
            ]),
            
            const SizedBox(height: 20),
            
            if (_weekAnalyses.isNotEmpty) ...[
              const Text(
                'Динамика оценок',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    lineBarsData: [
                      LineChartBarData(
                        spots: _weekAnalyses.asMap().entries.map((entry) {
                          return FlSpot(entry.key.toDouble(), entry.value.overallScore);
                        }).toList(),
                        isCurved: true,
                        color: Colors.indigo[600],
                        barWidth: 3,
                        dotData: const FlDotData(show: true),
                      ),
                    ],
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text('${value.toInt()}');
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < _weekAnalyses.length) {
                              final date = _weekAnalyses[index].analysisDate;
                              return Text('${date.day}.${date.month}');
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    minY: 0,
                    maxY: 100,
                    gridData: const FlGridData(show: true),
                    borderData: FlBorderData(show: true),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsTab() {
    if (_isLoading || _todayAnalysis == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final analysis = _todayAnalysis!;
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (analysis.achievements.isNotEmpty) ...[
              _buildRecommendationSection(
                'Достижения',
                analysis.achievements,
                Colors.green,
                Icons.check_circle,
              ),
              const SizedBox(height: 20),
            ],
            
            if (analysis.concerns.isNotEmpty) ...[
              _buildRecommendationSection(
                'Проблемы',
                analysis.concerns,
                Colors.orange,
                Icons.warning,
              ),
              const SizedBox(height: 20),
            ],
            
            if (analysis.recommendations.isNotEmpty) ...[
              _buildRecommendationSection(
                'Рекомендации',
                analysis.recommendations,
                Colors.blue,
                Icons.lightbulb,
              ),
            ],
            
            if (analysis.achievements.isEmpty && 
                analysis.concerns.isEmpty && 
                analysis.recommendations.isEmpty) ...[
              Center(
                child: Column(
                  children: [
                    Icon(Icons.analytics, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 20),
                    Text(
                      'Недостаточно данных',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Добавьте больше записей о питании',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Вспомогательные виджеты
  Widget _buildNutrientSection(String title, List<Widget> children) {
    return _buildSection(title, children);
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        ...children,
      ],
    );
  }

  Widget _buildNutrientRow(
    String name,
    String actual,
    String target,
    double percentage,
    String unit,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text('$actual $unit'),
          ),
          Expanded(
            child: Text('/ $target $unit'),
          ),
          Container(
            width: 60,
            alignment: Alignment.centerRight,
            child: Text(
              '${percentage.toInt()}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(String title, Widget chart) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          chart,
        ],
      ),
    );
  }

  Widget _buildRecommendationSection(
    String title,
    List<String> items,
    Color color,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...items.map((item) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.circle, size: 6, color: color),
              const SizedBox(width: 10),
              Expanded(child: Text(item)),
            ],
          ),
        )),
      ],
    );
  }

  // Данные для графиков
  List<PieChartSectionData> _buildMacroSections() {
    final analysis = _todayAnalysis!;
    final total = analysis.actualProtein + analysis.actualFats + analysis.actualCarbs;
    
    if (total == 0) return [];
    
    return [
      PieChartSectionData(
        value: analysis.actualProtein,
        title: 'Белки\n${(analysis.actualProtein / total * 100).toStringAsFixed(1)}%',
        color: Colors.red,
        radius: 80,
      ),
      PieChartSectionData(
        value: analysis.actualFats,
        title: 'Жиры\n${(analysis.actualFats / total * 100).toStringAsFixed(1)}%',
        color: Colors.yellow[700],
        radius: 80,
      ),
      PieChartSectionData(
        value: analysis.actualCarbs,
        title: 'Углеводы\n${(analysis.actualCarbs / total * 100).toStringAsFixed(1)}%',
        color: Colors.blue,
        radius: 80,
      ),
    ];
  }

  List<BarChartGroupData> _buildGoalBars() {
    final analysis = _todayAnalysis!;
    
    return [
      BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: analysis.calorieCompletion, color: Colors.orange)]),
      BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: analysis.proteinCompletion, color: Colors.red)]),
      BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: analysis.goalCompletion['fats'] ?? 0, color: Colors.yellow[700]!)]),
      BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: analysis.goalCompletion['carbs'] ?? 0, color: Colors.blue)]),
      BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: analysis.vitaminCCompletion, color: Colors.green)]),
    ];
  }

  Color _getScoreColor(double score) {
    if (score >= 90) return Colors.green;
    if (score >= 80) return Colors.lightGreen;
    if (score >= 70) return Colors.orange;
    if (score >= 60) return Colors.deepOrange;
    return Colors.red;
  }

  // Действия
  Future<void> _generateNewAnalysis() async {
    setState(() => _isLoading = true);
    
    try {
      final newAnalysis = await FirebaseService.generateDailyNutritionAnalysis(
        widget.childId, 
        DateTime.now()
      );
      
      setState(() {
        _todayAnalysis = newAnalysis;
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Анализ обновлен'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка обновления: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}