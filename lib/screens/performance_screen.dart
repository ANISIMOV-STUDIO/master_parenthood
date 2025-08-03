// lib/screens/performance_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/performance_service.dart';

class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key});

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  PerformanceStats? _stats;
  PerformanceReport? _report;
  bool _isLoading = true;
  bool _isMonitoring = false;

  @override
  void initState() {
    super.initState();
    _loadPerformanceData();
  }

  Future<void> _loadPerformanceData() async {
    setState(() => _isLoading = true);

    try {
      final stats = PerformanceService.getPerformanceStats();
      final report = await PerformanceService.generatePerformanceReport();

      setState(() {
        _stats = stats;
        _report = report;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки данных: $e')),
        );
      }
    }
  }

  void _toggleMonitoring() {
    setState(() {
      _isMonitoring = !_isMonitoring;
    });

    if (_isMonitoring) {
      PerformanceService.startPerformanceMonitoring();
    } else {
      PerformanceService.stopPerformanceMonitoring();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isMonitoring 
            ? 'Мониторинг производительности включен' 
            : 'Мониторинг производительности выключен'),
      ),
    );
  }

  void _clearData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Очистить данные'),
        content: const Text('Вы уверены, что хотите очистить все данные производительности?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              PerformanceService.clearPerformanceData();
              _loadPerformanceData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Данные очищены')),
              );
            },
            child: const Text('Очистить'),
          ),
        ],
      ),
    );
  }

  void _exportData() async {
    try {
      final data = PerformanceService.exportPerformanceData();
      
      // В реальном приложении можно использовать share_plus
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Данные экспортированы в логи')),
      );
      
      debugPrint('📊 Performance data exported: $data');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка экспорта: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Производительность'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isMonitoring ? Icons.pause : Icons.play_arrow),
            onPressed: _toggleMonitoring,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'refresh':
                  _loadPerformanceData();
                  break;
                case 'clear':
                  _clearData();
                  break;
                case 'export':
                  _exportData();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 8),
                    Text('Обновить'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.clear),
                    SizedBox(width: 8),
                    Text('Очистить'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.file_download),
                    SizedBox(width: 8),
                    Text('Экспорт'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPerformanceData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMonitoringStatus(),
                    const SizedBox(height: 24),
                    _buildPerformanceMetrics(),
                    const SizedBox(height: 24),
                    _buildRecommendations(),
                    const SizedBox(height: 24),
                    _buildSessionInfo(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMonitoringStatus() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isMonitoring 
              ? [Colors.green.shade400, Colors.teal.shade400]
              : [Colors.grey.shade400, Colors.grey.shade600],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isMonitoring ? Icons.monitor_heart : Icons.monitor_outlined,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isMonitoring ? 'Мониторинг активен' : 'Мониторинг остановлен',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isMonitoring 
                      ? 'Отслеживание производительности в реальном времени'
                      : 'Нажмите play для начала мониторинга',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().slideY(begin: -0.3).fadeIn();
  }

  Widget _buildPerformanceMetrics() {
    if (_stats == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Метрики производительности',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildMetricCard(
          'FPS',
          _stats!.currentFps.toStringAsFixed(1),
          Icons.speed,
          _getFpsColor(_stats!.currentFps),
          'Частота кадров в секунду',
        ),
        _buildMetricCard(
          'Время кадра',
          '${_stats!.averageFrameTimeMs.toStringAsFixed(2)} мс',
          Icons.timer,
          _getFrameTimeColor(_stats!.averageFrameTimeMs),
          'Среднее время отрисовки кадра',
        ),
        _buildMetricCard(
          'Пропуски кадров',
          '${_stats!.frameDrops} / ${_stats!.totalFrames}',
          Icons.skip_next,
          _getFrameDropColor(_stats!.frameDropPercentage),
          '${_stats!.frameDropPercentage.toStringAsFixed(1)}% пропущенных кадров',
        ),
        _buildMetricCard(
          'Время работы',
          _formatDuration(Duration(milliseconds: _stats!.appUptimeMs)),
          Icons.access_time,
          Colors.blue,
          'Время с момента запуска приложения',
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String description,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().slideX(begin: 0.3).fadeIn();
  }

  Widget _buildRecommendations() {
    if (_report?.recommendations.isEmpty ?? true) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Рекомендации',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        for (final recommendation in _report!.recommendations) Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.orange.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  recommendation,
                  style: TextStyle(color: Colors.orange.shade700),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSessionInfo() {
    if (_report?.sessionInfo == null) return const SizedBox.shrink();

    final session = _report!.sessionInfo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Информация о сессии',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildInfoRow('Запуск приложения', _formatDateTime(session.startTime)),
              _buildInfoRow('Длительность сессии', _formatDuration(session.duration)),
              if (session.lastPerformanceCheck != null)
                _buildInfoRow('Последняя проверка', _formatDateTime(session.lastPerformanceCheck!)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Color _getFpsColor(double fps) {
    if (fps >= 55) return Colors.green;
    if (fps >= 45) return Colors.orange;
    return Colors.red;
  }

  Color _getFrameTimeColor(double frameTime) {
    if (frameTime <= 16.67) return Colors.green;
    if (frameTime <= 25) return Colors.orange;
    return Colors.red;
  }

  Color _getFrameDropColor(double percentage) {
    if (percentage <= 5) return Colors.green;
    if (percentage <= 15) return Colors.orange;
    return Colors.red;
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours}ч ${minutes}м ${seconds}с';
    } else if (minutes > 0) {
      return '${minutes}м ${seconds}с';
    } else {
      return '${seconds}с';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}