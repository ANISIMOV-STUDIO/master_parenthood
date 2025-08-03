// lib/screens/sleep_tracker_screen.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/firebase_service.dart';

class SleepTrackerScreen extends StatefulWidget {
  final String childId;

  const SleepTrackerScreen({Key? key, required this.childId}) : super(key: key);

  @override
  State<SleepTrackerScreen> createState() => _SleepTrackerScreenState();
}

class _SleepTrackerScreenState extends State<SleepTrackerScreen>
    with TickerProviderStateMixin {
  
  late TabController _tabController;
  late AnimationController _moonController;
  late Animation<double> _moonAnimation;
  
  List<SleepEntry> _sleepEntries = [];
  SleepEntry? _todayEntry;
  SleepAnalysis? _weeklyAnalysis;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _moonController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _moonAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _moonController, curve: Curves.easeInOut),
    );
    
    _loadSleepData();
    _moonController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _moonController.dispose();
    super.dispose();
  }

  Future<void> _loadSleepData() async {
    setState(() => _isLoading = true);
    
    try {
      // Загружаем записи сна
      FirebaseService.getSleepEntriesStream(widget.childId).listen((entries) {
        setState(() {
          _sleepEntries = entries;
          _todayEntry = _getTodayEntry(entries);
        });
      });
      
      // Загружаем недельный анализ
      try {
        final endDate = DateTime.now();
        final startDate = endDate.subtract(const Duration(days: 7));
        final analysis = await FirebaseService.generateSleepAnalysis(
          widget.childId, 
          startDate, 
          endDate
        );
        
        setState(() {
          _weeklyAnalysis = analysis;
        });
      } catch (e) {
        // Если нет данных для анализа, это нормально
        // ignore: avoid_print
        print('Нет данных для анализа сна: $e');
      }
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки данных сна: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  SleepEntry? _getTodayEntry(List<SleepEntry> entries) {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    
    return entries.firstWhere(
      (entry) => entry.date.isAfter(todayStart.subtract(const Duration(days: 1))) && 
                 entry.date.isBefore(todayStart.add(const Duration(days: 1))),
      orElse: () => SleepEntry(
        id: '',
        childId: widget.childId,
        date: today,
        interruptions: [],
        naps: [],
        quality: SleepQuality.fair,
        factors: {},
        createdAt: today,
        updatedAt: today,
      ),
    );
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
              Colors.indigo[900]!,
              Colors.indigo[700]!,
              Colors.indigo[500]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildTodayStatus(),
              _buildTabBar(),
              Expanded(
                child: _buildTabBarView(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
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
                Row(
                  children: [
                    const Text(
                      'Трекер сна',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    AnimatedBuilder(
                      animation: _moonAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 0.8 + (_moonAnimation.value * 0.2),
                          child: const Icon(
                            Icons.bedtime,
                            color: Colors.yellow,
                            size: 24,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                Text(
                  'Здоровый сон для здорового роста',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          if (_weeklyAnalysis != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Color(_weeklyAnalysis!.qualityTrend.colorHex),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                _weeklyAnalysis!.qualityTrend.displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTodayStatus() {
    if (_isLoading || _todayEntry == null) {
      return Container(
        margin: const EdgeInsets.all(20),
        height: 120,
        child: const Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final entry = _todayEntry!;
    
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(entry.quality.colorHex),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  entry.quality.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
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
                child: _buildStatusItem(
                  'Время сна',
                  entry.isCompleteEntry ? entry.formattedSleepTime : 'Не записано',
                  Icons.bedtime,
                  Colors.indigo,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildStatusItem(
                  'Укладывание',
                  entry.bedtimeString,
                  Icons.schedule,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildStatusItem(
                  'Пробуждения',
                  '${entry.nightWakings}',
                  Icons.visibility,
                  Colors.red,
                ),
              ),
            ],
          ),
          
          if (entry.naps.isNotEmpty) ...[
            const SizedBox(height: 15),
            Row(
              children: [
                Icon(Icons.child_care, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 5),
                Text(
                  'Дневной сон: ${entry.naps.length} раз',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                Text(
                  entry.totalNapTime.inMinutes > 0 
                      ? '${entry.totalNapTime.inHours}ч ${entry.totalNapTime.inMinutes.remainder(60)}м'
                      : '0м',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
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
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'История'),
          Tab(text: 'Статистика'),
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
          _buildHistoryTab(),
          _buildStatisticsTab(),
          _buildAnalysisTab(),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_sleepEntries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bedtime, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 20),
            Text(
              'Нет записей о сне',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 10),
            Text(
              'Начните отслеживать сон ребенка',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _sleepEntries.length,
      itemBuilder: (context, index) {
        final entry = _sleepEntries[index];
        return _buildSleepEntryCard(entry);
      },
    );
  }

  Widget _buildSleepEntryCard(SleepEntry entry) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: CircleAvatar(
          backgroundColor: Color(entry.quality.colorHex),
          child: const Icon(
            Icons.bedtime,
            color: Colors.white,
          ),
        ),
        title: Text(
          '${entry.date.day}.${entry.date.month}.${entry.date.year}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            if (entry.isCompleteEntry) ...[
              Text('Сон: ${entry.formattedSleepTime}'),
              Text('${entry.bedtimeString} - ${entry.wakeupString}'),
            ] else
              const Text('Неполная запись'),
            if (entry.nightWakings > 0)
              Text('Пробуждения: ${entry.nightWakings}'),
            if (entry.naps.isNotEmpty)
              Text('Дневной сон: ${entry.naps.length} раз'),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Редактировать')),
            const PopupMenuItem(value: 'delete', child: Text('Удалить')),
          ],
          onSelected: (value) {
            if (value == 'delete') {
              _deleteSleepEntry(entry);
            } else if (value == 'edit') {
              _editSleepEntry(entry);
            }
          },
        ),
      ),
    );
  }

  Widget _buildStatisticsTab() {
    if (_isLoading || _sleepEntries.isEmpty) {
      return const Center(
        child: Text('Недостаточно данных для статистики'),
      );
    }

    final completeEntries = _sleepEntries.where((e) => e.isCompleteEntry).toList();
    
    if (completeEntries.isEmpty) {
      return const Center(
        child: Text('Нет полных записей для анализа'),
      );
    }

    // Рассчитываем статистику
    final avgSleep = completeEntries.fold<Duration>(
      Duration.zero,
      (sum, entry) => sum + entry.actualSleepTime,
    ) ~/ completeEntries.length;

    final avgQuality = completeEntries.fold<double>(
      0, 
      (sum, entry) => sum + entry.quality.scoreValue,
    ) / completeEntries.length;

    final avgWakings = completeEntries.fold<double>(
      0,
      (sum, entry) => sum + entry.nightWakings,
    ) / completeEntries.length;

    final totalNaps = _sleepEntries.fold<int>(0, (sum, entry) => sum + entry.naps.length);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Статистика за последние записи',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          
          _buildStatCard('Средняя продолжительность сна', 
              '${avgSleep.inHours}ч ${avgSleep.inMinutes.remainder(60)}м', 
              Icons.bedtime, Colors.indigo),
          _buildStatCard('Среднее качество сна', 
              '${avgQuality.toStringAsFixed(1)}/5', 
              Icons.star, Colors.amber),
          _buildStatCard('Среднее количество пробуждений', 
              avgWakings.toStringAsFixed(1), 
              Icons.visibility, Colors.red),
          _buildStatCard('Всего дневных снов', 
              totalNaps.toString(), 
              Icons.child_care, Colors.green),
          
          const SizedBox(height: 20),
          
          // График качества сна
          const Text(
            'Качество сна по дням',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: _sleepEntries.take(14).toList().asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value.quality.scoreValue.toDouble());
                    }).toList(),
                    isCurved: true,
                    color: Colors.indigo,
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
                        if (index < _sleepEntries.length) {
                          final date = _sleepEntries[index].date;
                          return Text('${date.day}.${date.month}');
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                minY: 1,
                maxY: 5,
                gridData: const FlGridData(show: true),
                borderData: FlBorderData(show: true),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisTab() {
    if (_weeklyAnalysis == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics, size: 80, color: Colors.grey),
            SizedBox(height: 20),
            Text('Недостаточно данных для анализа'),
            SizedBox(height: 10),
            Text('Добавьте больше записей о сне'),
          ],
        ),
      );
    }

    final analysis = _weeklyAnalysis!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Анализ за неделю',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.indigo[700],
            ),
          ),
          const SizedBox(height: 20),
          
          // Основные метрики
          Row(
            children: [
              Expanded(
                child: _buildAnalysisCard(
                  'Средний сон',
                  analysis.formattedNightSleep,
                  Icons.bedtime,
                  Colors.indigo,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildAnalysisCard(
                  'Качество',
                  analysis.qualityAssessment,
                  Icons.star,
                  Colors.amber,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 15),
          
          Row(
            children: [
              Expanded(
                child: _buildAnalysisCard(
                  'Укладывание',
                  analysis.averageBedtimeString,
                  Icons.schedule,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildAnalysisCard(
                  'Пробуждения',
                  '${analysis.averageNightWakings.toStringAsFixed(1)}/ночь',
                  Icons.visibility,
                  Colors.red,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Инсайты
          if (analysis.insights.isNotEmpty) ...[
            const Text(
              'Ключевые выводы:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...analysis.insights.map((insight) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb, size: 16, color: Colors.blue[600]),
                  const SizedBox(width: 10),
                  Expanded(child: Text(insight)),
                ],
              ),
            )),
            const SizedBox(height: 20),
          ],
          
          // Рекомендации
          if (analysis.recommendations.isNotEmpty) ...[
            const Text(
              'Рекомендации:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...analysis.recommendations.map((recommendation) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.eco, size: 16, color: Colors.green[600]),
                  const SizedBox(width: 10),
                  Expanded(child: Text(recommendation)),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildAnalysisCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _showAddSleepDialog,
      backgroundColor: Colors.indigo[600],
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: const Text('Записать сон'),
    );
  }

  // Действия
  void _showAddSleepDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddSleepDialog(childId: widget.childId),
    ).then((_) => _loadSleepData());
  }

  void _editSleepEntry(SleepEntry entry) {
    showDialog(
      context: context,
      builder: (context) => _EditSleepDialog(entry: entry),
    ).then((_) => _loadSleepData());
  }

  Future<void> _deleteSleepEntry(SleepEntry entry) async {
    try {
      await FirebaseService.deleteSleepEntry(entry.id);
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

// Диалог добавления записи сна
class _AddSleepDialog extends StatefulWidget {
  final String childId;

  const _AddSleepDialog({required this.childId});

  @override
  State<_AddSleepDialog> createState() => _AddSleepDialogState();
}

class _AddSleepDialogState extends State<_AddSleepDialog> {
  final _formKey = GlobalKey<FormState>();
  
  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _bedtime;
  TimeOfDay? _fallAsleepTime;
  TimeOfDay? _wakeupTime;
  SleepQuality _quality = SleepQuality.good;
  final _notesController = TextEditingController();
  
  final Map<String, bool> _factors = {
    'teething': false,
    'illness': false,
    'travel': false,
    'excitement': false,
    'noise': false,
  };

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Записать сон'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Дата
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Дата'),
                subtitle: Text('${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}'),
                onTap: _selectDate,
              ),
              
              // Время укладывания
              ListTile(
                leading: const Icon(Icons.bedtime),
                title: const Text('Время укладывания'),
                subtitle: Text(_bedtime?.format(context) ?? 'Не выбрано'),
                onTap: () => _selectTime('bedtime'),
              ),
              
              // Время засыпания
              ListTile(
                leading: const Icon(Icons.nightlight),
                title: const Text('Время засыпания'),
                subtitle: Text(_fallAsleepTime?.format(context) ?? 'Не выбрано'),
                onTap: () => _selectTime('fallAsleep'),
              ),
              
              // Время пробуждения
              ListTile(
                leading: const Icon(Icons.alarm),
                title: const Text('Время пробуждения'),
                subtitle: Text(_wakeupTime?.format(context) ?? 'Не выбрано'),
                onTap: () => _selectTime('wakeup'),
              ),
              
              const SizedBox(height: 15),
              
              // Качество сна
              DropdownButtonFormField<SleepQuality>(
                value: _quality,
                decoration: const InputDecoration(
                  labelText: 'Качество сна',
                  prefixIcon: Icon(Icons.star),
                ),
                items: SleepQuality.values.map((quality) {
                  return DropdownMenuItem(
                    value: quality,
                    child: Text(quality.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _quality = value!;
                  });
                },
              ),
              
              const SizedBox(height: 15),
              
              // Факторы влияния
              const Text(
                'Факторы влияния:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              ...(_factors.keys.map((factor) => CheckboxListTile(
                title: Text(_getFactorDisplayName(factor)),
                value: _factors[factor],
                onChanged: (value) {
                  setState(() {
                    _factors[factor] = value ?? false;
                  });
                },
              ))),
              
              const SizedBox(height: 15),
              
              // Заметки
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Заметки',
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _saveSleepEntry,
          child: const Text('Сохранить'),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(String timeType) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    
    if (picked != null) {
      setState(() {
        switch (timeType) {
          case 'bedtime':
            _bedtime = picked;
            break;
          case 'fallAsleep':
            _fallAsleepTime = picked;
            break;
          case 'wakeup':
            _wakeupTime = picked;
            break;
        }
      });
    }
  }

  String _getFactorDisplayName(String factor) {
    switch (factor) {
      case 'teething':
        return 'Прорезывание зубов';
      case 'illness':
        return 'Болезнь';
      case 'travel':
        return 'Путешествие';
      case 'excitement':
        return 'Возбуждение';
      case 'noise':
        return 'Шум';
      default:
        return factor;
    }
  }

  Future<void> _saveSleepEntry() async {
    try {
      DateTime? bedtimeDateTime;
      DateTime? fallAsleepDateTime;
      DateTime? wakeupDateTime;
      Duration? timeToFallAsleep;

      if (_bedtime != null) {
        bedtimeDateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _bedtime!.hour,
          _bedtime!.minute,
        );
      }

      if (_fallAsleepTime != null) {
        fallAsleepDateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _fallAsleepTime!.hour,
          _fallAsleepTime!.minute,
        );
        
        if (bedtimeDateTime != null) {
          timeToFallAsleep = fallAsleepDateTime.difference(bedtimeDateTime);
        }
      }

      if (_wakeupTime != null) {
        var wakeupDate = _selectedDate;
        // Если время пробуждения раньше времени засыпания, значит это следующий день
        if (_fallAsleepTime != null && _wakeupTime!.hour < _fallAsleepTime!.hour) {
          wakeupDate = _selectedDate.add(const Duration(days: 1));
        }
        
        wakeupDateTime = DateTime(
          wakeupDate.year,
          wakeupDate.month,
          wakeupDate.day,
          _wakeupTime!.hour,
          _wakeupTime!.minute,
        );
      }

      final sleepEntry = SleepEntry(
        id: '',
        childId: widget.childId,
        date: _selectedDate,
        bedtime: bedtimeDateTime,
        fallAsleepTime: fallAsleepDateTime,
        wakeupTime: wakeupDateTime,
        timeToFallAsleep: timeToFallAsleep,
        interruptions: [],
        naps: [],
        quality: _quality,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        factors: Map<String, dynamic>.from(_factors),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await FirebaseService.createSleepEntry(sleepEntry);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Запись сна сохранена')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }
}

// Диалог редактирования записи сна (упрощенный)
class _EditSleepDialog extends StatefulWidget {
  final SleepEntry entry;

  const _EditSleepDialog({required this.entry});

  @override
  State<_EditSleepDialog> createState() => _EditSleepDialogState();
}

class _EditSleepDialogState extends State<_EditSleepDialog> {
  late SleepQuality _quality;
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _quality = widget.entry.quality;
    _notesController.text = widget.entry.notes ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Редактировать запись'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<SleepQuality>(
            value: _quality,
            decoration: const InputDecoration(labelText: 'Качество сна'),
            items: SleepQuality.values.map((quality) {
              return DropdownMenuItem(
                value: quality,
                child: Text(quality.displayName),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _quality = value!;
              });
            },
          ),
          const SizedBox(height: 15),
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(labelText: 'Заметки'),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _updateEntry,
          child: const Text('Сохранить'),
        ),
      ],
    );
  }

  Future<void> _updateEntry() async {
    try {
      final updatedEntry = SleepEntry(
        id: widget.entry.id,
        childId: widget.entry.childId,
        date: widget.entry.date,
        bedtime: widget.entry.bedtime,
        fallAsleepTime: widget.entry.fallAsleepTime,
        wakeupTime: widget.entry.wakeupTime,
        totalSleepTime: widget.entry.totalSleepTime,
        timeToFallAsleep: widget.entry.timeToFallAsleep,
        interruptions: widget.entry.interruptions,
        naps: widget.entry.naps,
        quality: _quality,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        factors: widget.entry.factors,
        createdAt: widget.entry.createdAt,
        updatedAt: DateTime.now(),
      );

      await FirebaseService.updateSleepEntry(updatedEntry);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Запись обновлена')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }
}