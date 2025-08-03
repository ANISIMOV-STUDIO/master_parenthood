// lib/screens/growth_charts_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/firebase_service.dart';
import '../data/who_growth_standards.dart';

class GrowthChartsScreen extends StatefulWidget {
  final String childId;
  
  const GrowthChartsScreen({
    super.key,
    required this.childId,
  });

  @override
  State<GrowthChartsScreen> createState() => _GrowthChartsScreenState();
}

class _GrowthChartsScreenState extends State<GrowthChartsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _headerController;
  
  ChildProfile? _childProfile;
  GrowthAnalysis? _growthAnalysis;
  bool _isLoadingAnalysis = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
    
    _loadChildData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _headerController.dispose();
    super.dispose();
  }

  Future<void> _loadChildData() async {
    try {
      final child = await FirebaseService.getChild(widget.childId);
      if (child != null && mounted) {
        setState(() {
          _childProfile = child;
        });
        
        _loadGrowthAnalysis();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки данных: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadGrowthAnalysis() async {
    if (_childProfile == null) return;
    
    setState(() {
      _isLoadingAnalysis = true;
    });
    
    try {
      final analysis = await FirebaseService.generateGrowthAnalysis(
        widget.childId, 
        _childProfile!.birthDate
      );
      
      if (mounted) {
        setState(() {
          _growthAnalysis = analysis;
          _isLoadingAnalysis = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAnalysis = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка анализа: ${e.toString()}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFE),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          if (_childProfile != null) ...[
            SliverToBoxAdapter(child: _buildAnalysisOverview()),
            SliverFillRemaining(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildHeightChart(),
                  _buildWeightChart(),
                  _buildHeadCircumferenceChart(),
                  _buildAnalysisTab(),
                ],
              ),
            ),
          ] else ...[
            SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                ),
              ),
            ),
          ],
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF667eea),
                Color(0xFF764ba2),
                Color(0xFF6a82fb),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.show_chart,
                          color: Colors.white,
                          size: 28,
                        ),
                      ).animate().scale(delay: 200.ms),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Графики роста',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ).animate().slideX(delay: 300.ms),
                            Text(
                              _childProfile != null ? _childProfile!.name : 'Загрузка...',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 16,
                              ),
                            ).animate().slideX(delay: 400.ms),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    indicatorColor: Colors.white,
                    indicatorWeight: 3,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    tabs: const [
                      Tab(text: 'Рост'),
                      Tab(text: 'Вес'),
                      Tab(text: 'Окр. головы'),
                      Tab(text: 'Анализ'),
                    ],
                  ).animate().slideY(delay: 500.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnalysisOverview() {
    if (_growthAnalysis == null) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: _isLoadingAnalysis 
            ? const Center(child: CircularProgressIndicator())
            : const Center(child: Text('Нет данных для анализа')),
      );
    }

    final analysis = _growthAnalysis!;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Общая оценка развития',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      analysis.overallAssessment,
                      style: TextStyle(
                        fontSize: 16,
                        color: _getScoreColor(analysis.overallGrowthScore),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getScoreColor(analysis.overallGrowthScore).withValues(alpha: 0.1),
                ),
                child: Center(
                  child: Text(
                    '${analysis.overallGrowthScore.toInt()}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _getScoreColor(analysis.overallGrowthScore),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          if (analysis.hasConcerns) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Требует внимания:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...analysis.concerns.map((concern) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(color: Colors.orange)),
                        Expanded(child: Text(concern, style: const TextStyle(fontSize: 14))),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],
          
          if (analysis.currentPercentiles.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Текущие показатели:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            ...analysis.currentPercentiles.entries.map((entry) =>
              _buildPercentileRow(entry.key, entry.value)
            ),
          ],
        ],
      ),
    ).animate().slideY(delay: 600.ms);
  }

  Widget _buildPercentileRow(GrowthMeasurementType type, double percentile) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(_getTypeDisplayName(type)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getPercentileColor(percentile).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${percentile.toInt()}-й центиль',
              style: TextStyle(
                color: _getPercentileColor(percentile),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeightChart() {
    return StreamBuilder<List<DetailedGrowthMeasurement>>(
      stream: FirebaseService.getDetailedGrowthMeasurementsByTypeStream(
        widget.childId, 
        GrowthMeasurementType.height
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final measurements = snapshot.data ?? [];
        if (measurements.isEmpty) {
          return _buildEmptyChartState(
            'Нет данных о росте',
            'Добавьте первое измерение роста',
            Icons.height,
          );
        }

        return _buildChart(
          measurements,
          GrowthMeasurementType.height,
          'Рост (см)',
          Colors.blue,
        );
      },
    );
  }

  Widget _buildWeightChart() {
    return StreamBuilder<List<DetailedGrowthMeasurement>>(
      stream: FirebaseService.getDetailedGrowthMeasurementsByTypeStream(
        widget.childId, 
        GrowthMeasurementType.weight
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final measurements = snapshot.data ?? [];
        if (measurements.isEmpty) {
          return _buildEmptyChartState(
            'Нет данных о весе',
            'Добавьте первое измерение веса',
            Icons.monitor_weight,
          );
        }

        return _buildChart(
          measurements,
          GrowthMeasurementType.weight,
          'Вес (кг)',
          Colors.green,
        );
      },
    );
  }

  Widget _buildHeadCircumferenceChart() {
    return StreamBuilder<List<DetailedGrowthMeasurement>>(
      stream: FirebaseService.getDetailedGrowthMeasurementsByTypeStream(
        widget.childId, 
        GrowthMeasurementType.headCircumference
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final measurements = snapshot.data ?? [];
        if (measurements.isEmpty) {
          return _buildEmptyChartState(
            'Нет данных об окружности головы',
            'Добавьте первое измерение',
            Icons.account_circle,
          );
        }

        return _buildChart(
          measurements,
          GrowthMeasurementType.headCircumference,
          'Окружность головы (см)',
          Colors.purple,
        );
      },
    );
  }

  Widget _buildChart(
    List<DetailedGrowthMeasurement> measurements,
    GrowthMeasurementType type,
    String title,
    Color color,
  ) {
    if (_childProfile == null) return const Center(child: CircularProgressIndicator());

    // Сортируем измерения по дате
    measurements.sort((a, b) => a.measurementDate.compareTo(b.measurementDate));

    // Создаем точки данных ребенка
    final childSpots = measurements.map((measurement) {
      final ageMonths = measurement.measurementDate
          .difference(_childProfile!.birthDate)
          .inDays / 30.44; // Более точный расчет месяцев
      return FlSpot(ageMonths, measurement.value);
    }).toList();

    // Получаем центильные кривые ВОЗ
    final whoSpots = _generateWHOSpots(type, _childProfile!.gender);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: 60, // До 5 лет
                  lineBarsData: [
                    // Центильные кривые ВОЗ
                    ...whoSpots.entries.map((entry) => LineChartBarData(
                      spots: entry.value,
                      isCurved: true,
                      color: _getCentileColor(entry.key),
                      barWidth: 1.5,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    )),
                    
                    // Данные ребенка
                    LineChartBarData(
                      spots: childSpots,
                      isCurved: true,
                      color: color,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                          radius: 6,
                          color: color,
                          strokeWidth: 3,
                          strokeColor: Colors.white,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 6,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}м',
                            style: const TextStyle(fontSize: 12),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 12),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    drawVerticalLine: true,
                    horizontalInterval: _getGridInterval(type),
                    verticalInterval: 6,
                    getDrawingHorizontalLine: (value) => const FlLine(
                      color: Colors.grey,
                      strokeWidth: 0.5,
                    ),
                    getDrawingVerticalLine: (value) => const FlLine(
                      color: Colors.grey,
                      strokeWidth: 0.5,
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          if (spot.barIndex == whoSpots.length) {
                            // Это точка ребенка
                            final ageMonths = spot.x;
                            final value = spot.y;
                            return LineTooltipItem(
                              '${ageMonths.toInt()} мес.: ${value.toStringAsFixed(1)}',
                              TextStyle(color: color, fontWeight: FontWeight.bold),
                            );
                          }
                          return null;
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildChartLegend(),
        ],
      ),
    );
  }

  Widget _buildChartLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Центильные кривые ВОЗ:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _LegendItem(color: Colors.red, label: '3%'),
              _LegendItem(color: Colors.orange, label: '15%'),
              _LegendItem(color: Colors.green, label: '50%'),
              _LegendItem(color: Colors.orange, label: '85%'),
              _LegendItem(color: Colors.red, label: '97%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisTab() {
    if (_growthAnalysis == null) {
      return Center(
        child: _isLoadingAnalysis 
            ? const CircularProgressIndicator()
            : const Text('Нет данных для анализа'),
      );
    }

    final analysis = _growthAnalysis!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Рекомендации
          if (analysis.recommendations.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.lightbulb, color: Colors.blue, size: 24),
                      SizedBox(width: 12),
                      Text(
                        'Рекомендации',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...analysis.recommendations.map((recommendation) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(top: 8),
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            recommendation,
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ).animate().slideY(),
            
            const SizedBox(height: 16),
          ],
          
          // Тренды роста
          if (analysis.growthTrends.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.trending_up, color: Colors.green, size: 24),
                      SizedBox(width: 12),
                      Text(
                        'Тренды развития',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...analysis.growthTrends.entries.map((entry) =>
                    _buildTrendRow(entry.key, entry.value)
                  ),
                ],
              ),
            ).animate().slideY(delay: 200.ms),
          ],
        ],
      ),
    );
  }

  Widget _buildTrendRow(GrowthMeasurementType type, String trend) {
    IconData trendIcon;
    Color trendColor;
    String trendText;
    
    switch (trend) {
      case 'increasing':
        trendIcon = Icons.trending_up;
        trendColor = Colors.green;
        trendText = 'Растет';
        break;
      case 'decreasing':
        trendIcon = Icons.trending_down;
        trendColor = Colors.red;
        trendText = 'Снижается';
        break;
      default:
        trendIcon = Icons.trending_flat;
        trendColor = Colors.blue;
        trendText = 'Стабильно';
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(trendIcon, color: trendColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _getTypeDisplayName(type),
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: trendColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              trendText,
              style: TextStyle(
                color: trendColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChartState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 64, color: Colors.grey[400]),
          ).animate().scale(),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ).animate().slideY(delay: 200.ms),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ).animate().slideY(delay: 300.ms),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: _showAddMeasurementDialog,
      backgroundColor: const Color(0xFF667eea),
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text(
        'Добавить измерение',
        style: TextStyle(color: Colors.white),
      ),
    ).animate().scale(delay: 800.ms);
  }

  // Вспомогательные методы
  Map<String, List<FlSpot>> _generateWHOSpots(
    GrowthMeasurementType type, 
    String gender
  ) {
    final spots = <String, List<FlSpot>>{};
    final centiles = ['p3', 'p15', 'p50', 'p85', 'p97'];
    
    for (final centile in centiles) {
      final centileSpots = <FlSpot>[];
      
      for (int ageMonths = 0; ageMonths <= 60; ageMonths += 3) {
        final data = WHOGrowthStandards.getInterpolatedData(
          ageMonths: ageMonths,
          gender: gender,
          measurementType: type,
        );
        
        if (data != null) {
          double value;
          switch (centile) {
            case 'p3': value = data.p3; break;
            case 'p15': value = data.p15; break;
            case 'p50': value = data.p50; break;
            case 'p85': value = data.p85; break;
            case 'p97': value = data.p97; break;
            default: value = data.p50;
          }
          centileSpots.add(FlSpot(ageMonths.toDouble(), value));
        }
      }
      
      spots[centile] = centileSpots;
    }
    
    return spots;
  }

  Color _getCentileColor(String centile) {
    switch (centile) {
      case 'p3':
      case 'p97':
        return Colors.red.withValues(alpha: 0.6);
      case 'p15':
      case 'p85':
        return Colors.orange.withValues(alpha: 0.6);
      case 'p50':
        return Colors.green.withValues(alpha: 0.8);
      default:
        return Colors.grey;
    }
  }

  Color _getScoreColor(double score) {
    if (score >= 85) return Colors.green;
    if (score >= 70) return Colors.blue;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }

  Color _getPercentileColor(double percentile) {
    if (percentile >= 15 && percentile <= 85) return Colors.green;
    if (percentile < 3 || percentile > 97) return Colors.red;
    return Colors.orange;
  }

  String _getTypeDisplayName(GrowthMeasurementType type) {
    switch (type) {
      case GrowthMeasurementType.height:
        return 'Рост';
      case GrowthMeasurementType.weight:
        return 'Вес';
      case GrowthMeasurementType.headCircumference:
        return 'Окружность головы';
      default:
        return 'Неизвестно';
    }
  }

  double _getGridInterval(GrowthMeasurementType type) {
    switch (type) {
      case GrowthMeasurementType.height:
        return 10;
      case GrowthMeasurementType.weight:
        return 2;
      case GrowthMeasurementType.headCircumference:
        return 5;
      default:
        return 5;
    }
  }

  void _showAddMeasurementDialog() {
    showDialog(
      context: context,
      builder: (context) => AddMeasurementDialog(childId: widget.childId),
    );
  }
}

// Легенда графика
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 2,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10),
        ),
      ],
    );
  }
}

// Диалог добавления измерения (заглушка)
class AddMeasurementDialog extends StatelessWidget {
  final String childId;

  const AddMeasurementDialog({super.key, required this.childId});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Добавить измерение'),
      content: const Text('Форма добавления измерения будет реализована далее'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Закрыть'),
        ),
      ],
    );
  }
}