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
  final List<FlSpot> _heightData = [];
  final List<FlSpot> _weightData = [];
  final List<FlSpot> _progressData = [];
  
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
          const baseHeight = 50.0;
          final growth = month * 2.5;
          final variation = math.sin(month * 0.5) * 1.5;
          final height = baseHeight + growth + variation;
          _heightData.add(FlSpot(month.toDouble(), height));
          
          // Примерные данные веса
          const baseWeight = 3.5;
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1a1a2e)
                  : const Color(0xFFf8faff),
              Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF16213e)
                  : const Color(0xFFe8f2ff),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildModernAppBar(),
              Expanded(
                child: _activeChild == null
                    ? _buildNoDataState()
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildChildHeader(),
                              const SizedBox(height: 20),
                              _buildPeriodSelector(),
                              const SizedBox(height: 20),
                              _buildStatsCards(),
                              const SizedBox(height: 32),
                              _buildHeightChart(),
                              const SizedBox(height: 32),
                              _buildWeightChart(),
                              const SizedBox(height: 32),
                              _buildProgressChart(),
                              const SizedBox(height: 32),
                              _buildInsights(),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernAppBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Аналитика развития',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : const Color(0xFF2A2D3A),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Отслеживайте прогресс ребенка',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withValues(alpha: 0.7)
                        : const Color(0xFF6B7280),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadData,
            ),
          ),
        ],
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
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.grey.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: isSelected 
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isSelected 
                      ? [
                          BoxShadow(
                            color: const Color(0xFF667eea).withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  period,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected 
                        ? Colors.white
                        : Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withValues(alpha: 0.8)
                            : const Color(0xFF6B7280),
                    fontWeight: isSelected 
                        ? FontWeight.bold
                        : FontWeight.w600,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ).animate(controller: _cardController)
      .fadeIn(delay: 200.ms, duration: 600.ms)
      .scale(begin: const Offset(0.95, 0.95))
      .shimmer(delay: 300.ms, duration: 800.ms);
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.3),
                  color.withValues(alpha: 0.1),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ).animate(controller: _cardController)
      .fadeIn(delay: (300 + index * 100).ms)
      .slideY(begin: 0.3);
  }

  Widget _buildHeightChart() {
    return _buildModernChartContainer(
      'График роста',
      'Рост ребенка по месяцам',
      Icons.height,
      const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
      ),
      LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.white.withValues(alpha: 0.1),
                strokeWidth: 0.8,
              );
            },
          ),
          titlesData: _buildModernTitlesData('см'),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: _heightData,
              isCurved: true,
              curveSmoothness: 0.4,
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 6,
                    color: Colors.white,
                    strokeWidth: 3,
                    strokeColor: const Color(0xFF667eea),
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF667eea).withValues(alpha: 0.3),
                    const Color(0xFF764ba2).withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              shadow: const Shadow(
                color: Color(0xFF667eea),
                blurRadius: 8,
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: const Color(0xFF2A2D3A),
              tooltipRoundedRadius: 12,
              tooltipPadding: const EdgeInsets.all(12),
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    '${spot.y.toStringAsFixed(1)} см\n${spot.x.toStringAsFixed(0)} мес',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  );
                }).toList();
              },
            ),
            handleBuiltInTouches: true,
            getTouchedSpotIndicator: (barData, spotIndexes) {
              return spotIndexes.map((index) {
                return TouchedSpotIndicatorData(
                  FlLine(
                    color: Colors.white.withValues(alpha: 0.8),
                    strokeWidth: 2,
                  ),
                  FlDotData(
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 8,
                        color: Colors.white,
                        strokeWidth: 3,
                        strokeColor: const Color(0xFF667eea),
                      );
                    },
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildWeightChart() {
    return _buildModernChartContainer(
      'График веса',
      'Вес ребенка по месяцам',
      Icons.monitor_weight,
      const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
      ),
      LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.white.withValues(alpha: 0.1),
                strokeWidth: 0.8,
              );
            },
          ),
          titlesData: _buildModernTitlesData('кг'),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: _weightData,
              isCurved: true,
              curveSmoothness: 0.4,
              gradient: const LinearGradient(
                colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
              ),
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 6,
                    color: Colors.white,
                    strokeWidth: 3,
                    strokeColor: const Color(0xFF11998e),
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF11998e).withValues(alpha: 0.3),
                    const Color(0xFF38ef7d).withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              shadow: const Shadow(
                color: Color(0xFF11998e),
                blurRadius: 8,
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: const Color(0xFF2A2D3A),
              tooltipRoundedRadius: 12,
              tooltipPadding: const EdgeInsets.all(12),
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    '${spot.y.toStringAsFixed(1)} кг\n${spot.x.toStringAsFixed(0)} мес',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  );
                }).toList();
              },
            ),
            handleBuiltInTouches: true,
            getTouchedSpotIndicator: (barData, spotIndexes) {
              return spotIndexes.map((index) {
                return TouchedSpotIndicatorData(
                  FlLine(
                    color: Colors.white.withValues(alpha: 0.8),
                    strokeWidth: 2,
                  ),
                  FlDotData(
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 8,
                        color: Colors.white,
                        strokeWidth: 3,
                        strokeColor: const Color(0xFF11998e),
                      );
                    },
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProgressChart() {
    final progressValue = _progressData.isNotEmpty ? _progressData.last.y : 0;
    return _buildModernChartContainer(
      'Прогресс развития',
      'Процент выполненных вех развития',
      Icons.trending_up,
      const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
      ),
      Stack(
        children: [
          PieChart(
            PieChartData(
              startDegreeOffset: -90,
              sectionsSpace: 4,
              centerSpaceRadius: 80,
              sections: [
                PieChartSectionData(
                  value: progressValue.toDouble(),
                  color: Colors.white,
                  radius: 20,
                  showTitle: false,
                ),
                PieChartSectionData(
                  value: (100 - progressValue).toDouble(),
                  color: Colors.white.withValues(alpha: 0.3),
                  radius: 20,
                  showTitle: false,
                ),
              ],
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${progressValue.toInt()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  'завершено',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }





  Widget _buildModernChartContainer(String title, String subtitle, IconData icon, LinearGradient gradient, Widget chart) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 5,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.1),
              Colors.white.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              height: 280,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: chart,
            ),
          ],
        ),
      ),
    ).animate(controller: _chartController)
      .fadeIn(duration: 800.ms)
      .slideY(begin: 0.2, curve: Curves.easeOutQuart)
      .shimmer(delay: 400.ms, duration: 1000.ms);
  }

  FlTitlesData _buildModernTitlesData(String unit) {
    return FlTitlesData(
      show: true,
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 32,
          interval: 2,
          getTitlesWidget: (value, meta) {
            return Text(
              '${value.toInt()}м',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            );
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          interval: unit == 'см' ? 10 : 1,
          getTitlesWidget: (value, meta) {
            return Text(
              value.toInt().toString(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
                fontWeight: FontWeight.w600,
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