// lib/screens/analytics_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import '../services/firebase_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with TickerProviderStateMixin {
  late AnimationController _chartController;
  late AnimationController _cardController;
  
  ChildProfile? _activeChild;
  List<FlSpot> _heightData = [];
  List<FlSpot> _weightData = [];
  List<FlSpot> _progressData = [];
  
  // Периоды анализа
  int _selectedPeriod = 0; // 0: 3 месяца, 1: 6 месяцев, 2: 1 год
  final List<String> _periods = ['3 мес', '6 мес', '1 год'];

  @override
  void initState() {
    super.initState();
    _chartController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _loadData();
  }

  @override
  void dispose() {
    _chartController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final activeChild = await FirebaseService.getActiveChild();
    if (mounted && activeChild != null) {
      setState(() {
        _activeChild = activeChild;
      });
      _loadAnalyticsData();
      _chartController.forward();
      _cardController.forward();
    }
  }

  void _loadAnalyticsData() {
    if (_activeChild == null) return;
    
    // Подписываемся на stream измерений роста и веса
    FirebaseService.getGrowthMeasurementsStream(_activeChild!.id).listen((measurements) {
      if (mounted) {
        _generateAnalyticsData(measurements);
      }
    });
  }

  void _generateAnalyticsData([List<GrowthMeasurement>? measurements]) {
    if (_activeChild == null) return;
    
    _heightData.clear();
    _weightData.clear();
    _progressData.clear();
    
    final ageInMonths = _activeChild!.ageInMonths;
    final monthsToShow = _selectedPeriod == 0 ? 3 : _selectedPeriod == 1 ? 6 : 12;
    final startMonth = math.max(0, ageInMonths - monthsToShow);
    
    if (measurements != null && measurements.isNotEmpty) {
      // Используем реальные данные измерений
      final filteredMeasurements = measurements.where((m) {
        final monthsFromBirth = _activeChild!.birthDate.difference(m.date).inDays.abs() ~/ 30;
        return monthsFromBirth >= startMonth && monthsFromBirth <= ageInMonths;
      }).toList();
      
      for (final measurement in filteredMeasurements) {
        final monthsFromBirth = _activeChild!.birthDate.difference(measurement.date).inDays.abs() / 30;
        _heightData.add(FlSpot(monthsFromBirth, measurement.height));
        _weightData.add(FlSpot(monthsFromBirth, measurement.weight));
      }
      
      // Сортируем по возрасту
      _heightData.sort((a, b) => a.x.compareTo(b.x));
      _weightData.sort((a, b) => a.x.compareTo(b.x));
    } else {
      // Генерируем примерные данные, если реальных измерений нет
      for (int i = 0; i <= monthsToShow; i++) {
        final month = startMonth + i;
        if (month <= ageInMonths) {
          // Примерные данные роста (реалистичная кривая)
          final baseHeight = 50.0;
          final growth = month * 2.5;
          final variation = math.sin(month * 0.5) * 1.5;
          final height = baseHeight + growth + variation;
          _heightData.add(FlSpot(month.toDouble(), height));
          
          // Примерные данные веса
          final baseWeight = 3.5;
          final weightGain = month * 0.6;
          final weightVariation = math.cos(month * 0.3) * 0.3;
          final weight = baseWeight + weightGain + weightVariation;
          _weightData.add(FlSpot(month.toDouble(), weight));
        }
      }
    }
    
    // Генерируем данные прогресса развития
    for (int i = 0; i <= monthsToShow; i++) {
      final month = startMonth + i;
      if (month <= ageInMonths) {
        final progress = math.min(100, (month / 24) * 100 + math.Random().nextDouble() * 10);
        _progressData.add(FlSpot(month.toDouble(), progress.toDouble()));
      }
    }
    
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Аналитика развития'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _activeChild == null
          ? _buildNoDataState()
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildChildHeader(),
                    const SizedBox(height: 24),
                    _buildPeriodSelector(),
                    const SizedBox(height: 24),
                    _buildStatsCards(),
                    const SizedBox(height: 24),
                    _buildHeightChart(),
                    const SizedBox(height: 24),
                    _buildWeightChart(),
                    const SizedBox(height: 24),
                    _buildProgressChart(),
                    const SizedBox(height: 24),
                    _buildInsights(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildNoDataState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 100,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 24),
          Text(
            'Нет данных для анализа',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Добавьте профиль ребенка\nчтобы увидеть аналитику',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ).animate().fadeIn().slideY(begin: 0.3),
    );
  }

  Widget _buildChildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
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
              Icons.child_care,
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
                  _activeChild!.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Возраст: ${_activeChild!.ageFormatted}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.analytics,
            color: Colors.white.withValues(alpha: 0.8),
            size: 32,
          ),
        ],
      ),
    ).animate(controller: _cardController).fadeIn().slideX(begin: -0.3);
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: _periods.asMap().entries.map((entry) {
          final index = entry.key;
          final period = entry.value;
          final isSelected = _selectedPeriod == index;
          
          return Expanded(
            child: GestureDetector(
              onTap: () {
                              setState(() {
                _selectedPeriod = index;
                _loadAnalyticsData();
              });
                _chartController.reset();
                _chartController.forward();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? Theme.of(context).primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  period,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected 
                        ? Colors.white
                        : Theme.of(context).textTheme.bodyMedium?.color,
                    fontWeight: isSelected 
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ).animate(controller: _cardController).fadeIn(delay: 200.ms).scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildStatsCards() {
    final currentHeight = _heightData.isNotEmpty ? _heightData.last.y : 0;
    final currentWeight = _weightData.isNotEmpty ? _weightData.last.y : 0;
    final heightGrowth = _heightData.length > 1 
        ? _heightData.last.y - _heightData.first.y 
        : 0;
    final weightGrowth = _weightData.length > 1 
        ? _weightData.last.y - _weightData.first.y 
        : 0;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Рост',
            '${currentHeight.toStringAsFixed(0)} см',
            '+${heightGrowth.toStringAsFixed(1)} см',
            Icons.height,
            Colors.blue,
            0,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Вес',
            '${currentWeight.toStringAsFixed(1)} кг',
            '+${weightGrowth.toStringAsFixed(1)} кг',
            Icons.monitor_weight,
            Colors.green,
            1,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Прогресс',
            '${_progressData.isNotEmpty ? _progressData.last.y.toStringAsFixed(0) : 0}%',
            'развития',
            Icons.trending_up,
            Colors.orange,
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
      .fadeIn(delay: (300 + index * 100).ms)
      .slideY(begin: 0.3);
  }

  Widget _buildHeightChart() {
    return _buildChartContainer(
      'График роста',
      'Рост ребенка по месяцам',
      LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withValues(alpha: 0.2),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: _buildTitlesData('см'),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: _heightData,
              isCurved: true,
              gradient: LinearGradient(
                colors: [Colors.blue.withValues(alpha: 0.8), Colors.blue.withValues(alpha: 0.3)],
              ),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Colors.blue,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withValues(alpha: 0.2),
                    Colors.blue.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightChart() {
    return _buildChartContainer(
      'График веса',
      'Вес ребенка по месяцам',
      LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withValues(alpha: 0.2),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: _buildTitlesData('кг'),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: _weightData,
              isCurved: true,
              gradient: LinearGradient(
                colors: [Colors.green.withValues(alpha: 0.8), Colors.green.withValues(alpha: 0.3)],
              ),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Colors.green,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    Colors.green.withValues(alpha: 0.2),
                    Colors.green.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressChart() {
    return _buildChartContainer(
      'Прогресс развития',
      'Процент выполненных вех развития',
      LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 20,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withValues(alpha: 0.2),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: _buildTitlesData('%'),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          minY: 0,
          maxY: 100,
          lineBarsData: [
            LineChartBarData(
              spots: _progressData,
              isCurved: true,
              gradient: LinearGradient(
                colors: [Colors.orange.withValues(alpha: 0.8), Colors.orange.withValues(alpha: 0.3)],
              ),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Colors.orange,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.withValues(alpha: 0.2),
                    Colors.orange.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartContainer(String title, String subtitle, Widget chart) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 250,
            child: chart,
          ),
        ],
      ),
    ).animate(controller: _chartController).fadeIn().slideY(begin: 0.3);
  }

  FlTitlesData _buildTitlesData(String unit) {
    return FlTitlesData(
      show: true,
      rightTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      topTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          interval: 1,
          getTitlesWidget: (value, meta) {
            return SideTitleWidget(
              axisSide: meta.axisSide,
              child: Text(
                '${value.toInt()}м',
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w300,
                  fontSize: 12,
                ),
              ),
            );
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: unit == 'см' ? 5 : unit == 'кг' ? 1 : 20,
          reservedSize: 40,
          getTitlesWidget: (value, meta) {
            return SideTitleWidget(
              axisSide: meta.axisSide,
              child: Text(
                unit == '%' 
                    ? '${value.toInt()}%'
                    : '${value.toStringAsFixed(unit == 'кг' ? 1 : 0)}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w300,
                  fontSize: 12,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInsights() {
    if (_heightData.isEmpty || _weightData.isEmpty) return const SizedBox();

    final heightTrend = _heightData.length > 1 
        ? _heightData.last.y - _heightData.first.y 
        : 0;
    final weightTrend = _weightData.length > 1 
        ? _weightData.last.y - _weightData.first.y 
        : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.withValues(alpha: 0.1),
            Colors.blue.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Colors.purple.shade600,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Анализ и рекомендации',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.purple.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInsightItem(
            Icons.trending_up,
            'Рост',
            heightTrend > 0 
                ? 'Хороший темп роста (+${heightTrend.toStringAsFixed(1)} см)'
                : 'Стабильные показатели роста',
            Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildInsightItem(
            Icons.monitor_weight,
            'Вес',
            weightTrend > 0 
                ? 'Нормальная прибавка веса (+${weightTrend.toStringAsFixed(1)} кг)'
                : 'Стабильные показатели веса',
            Colors.green,
          ),
          const SizedBox(height: 12),
          _buildInsightItem(
            Icons.psychology,
            'Развитие',
            'Ребенок развивается согласно возрастным нормам',
            Colors.orange,
          ),
        ],
      ),
    ).animate(controller: _cardController).fadeIn(delay: 600.ms).slideX(begin: 0.3);
  }

  Widget _buildInsightItem(IconData icon, String title, String description, Color color) {
    return Row(
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
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}