// lib/services/performance_service.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PerformanceService {
  static const String _keyAppStartTime = 'app_start_time';
  static const String _keyLastPerformanceCheck = 'last_performance_check';
  static const String _keyAverageFrameTime = 'average_frame_time';
  
  static DateTime? _appStartTime;
  static final List<Duration> _frameTimes = [];
  static bool _isMonitoring = false;
  static Duration? _lastTimestamp;

  // Инициализация мониторинга производительности
  static Future<void> initialize() async {
    _appStartTime = DateTime.now();
    await _saveAppStartTime();
    
    if (kDebugMode) {
      startPerformanceMonitoring();
    }
    
    debugPrint('✅ PerformanceService initialized');
  }

  // Запуск мониторинга производительности
  static void startPerformanceMonitoring() {
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    
    // Мониторинг частоты кадров
    WidgetsBinding.instance.addPostFrameCallback(_measureFrameTime);
    
    debugPrint('🔍 Performance monitoring started');
  }

  // Остановка мониторинга
  static void stopPerformanceMonitoring() {
    _isMonitoring = false;
    debugPrint('⏹️ Performance monitoring stopped');
  }

  // Измерение времени кадра
  static void _measureFrameTime(Duration timestamp) {
    if (!_isMonitoring) return;
    
    if (_lastTimestamp != null) {
      final frameTime = timestamp - _lastTimestamp!;
      _frameTimes.add(frameTime);
      
      // Ограничиваем количество сохраненных измерений
      if (_frameTimes.length > 100) {
        _frameTimes.removeAt(0);
      }
      
      // Предупреждение о пропущенных кадрах
      if (frameTime.inMilliseconds > 16.67) { // Больше 60 FPS
        debugPrint('⚠️ Frame drop detected: ${frameTime.inMilliseconds}ms');
      }
    }
    
    _lastTimestamp = timestamp;
    
    // Планируем следующее измерение
    WidgetsBinding.instance.addPostFrameCallback(_measureFrameTime);
  }

  // Получение статистики производительности
  static PerformanceStats getPerformanceStats() {
    final averageFrameTime = _frameTimes.isNotEmpty
        ? _frameTimes.map((d) => d.inMicroseconds).reduce((a, b) => a + b) / _frameTimes.length
        : 0.0;
    
    final fps = averageFrameTime > 0 ? 1000000 / averageFrameTime : 0.0;
    
    final frameDrops = _frameTimes.where((d) => d.inMilliseconds > 16.67).length;
    
    return PerformanceStats(
      averageFrameTimeMs: averageFrameTime / 1000,
      currentFps: fps,
      frameDrops: frameDrops,
      totalFrames: _frameTimes.length,
      appUptimeMs: _appStartTime != null 
          ? DateTime.now().difference(_appStartTime!).inMilliseconds 
          : 0,
    );
  }

  // Сохранение времени запуска приложения
  static Future<void> _saveAppStartTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyAppStartTime, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Failed to save app start time: $e');
    }
  }

  // Логирование медленных операций
  static void logSlowOperation(String operation, Duration duration) {
    if (duration.inMilliseconds > 100) {
      debugPrint('🐌 Slow operation: $operation took ${duration.inMilliseconds}ms');
      
      // В production можно отправлять в аналитику
      if (kReleaseMode) {
        _sendSlowOperationAnalytics(operation, duration);
      }
    }
  }

  // Мониторинг использования памяти
  static void logMemoryUsage(String context) {
    if (kDebugMode) {
      // В реальном приложении можно использовать dart:developer
      debugPrint('💾 Memory usage check: $context');
    }
  }

  // Отчет о производительности
  static Future<PerformanceReport> generatePerformanceReport() async {
    final stats = getPerformanceStats();
    final prefs = await SharedPreferences.getInstance();
    
    final lastCheck = prefs.getInt(_keyLastPerformanceCheck) ?? 0;
    final appStartTime = prefs.getInt(_keyAppStartTime) ?? 0;
    
    await prefs.setInt(_keyLastPerformanceCheck, DateTime.now().millisecondsSinceEpoch);
    
    return PerformanceReport(
      timestamp: DateTime.now(),
      stats: stats,
      recommendations: _generateRecommendations(stats),
      sessionInfo: SessionInfo(
        startTime: DateTime.fromMillisecondsSinceEpoch(appStartTime),
        duration: DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(appStartTime)),
        lastPerformanceCheck: lastCheck > 0 
            ? DateTime.fromMillisecondsSinceEpoch(lastCheck)
            : null,
      ),
    );
  }

  // Генерация рекомендаций по оптимизации
  static List<String> _generateRecommendations(PerformanceStats stats) {
    final recommendations = <String>[];
    
    if (stats.currentFps < 55) {
      recommendations.add('Частота кадров ниже оптимальной. Рассмотрите оптимизацию анимаций.');
    }
    
    if (stats.frameDrops > stats.totalFrames * 0.1) {
      recommendations.add('Высокий процент пропущенных кадров. Проверьте сложные виджеты.');
    }
    
    if (stats.averageFrameTimeMs > 20) {
      recommendations.add('Среднее время кадра высокое. Используйте RepaintBoundary.');
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('Производительность в норме. Продолжайте следить за метриками.');
    }
    
    return recommendations;
  }

  // Отправка аналитики медленных операций (заглушка)
  static void _sendSlowOperationAnalytics(String operation, Duration duration) {
    // Здесь можно интегрировать с Firebase Analytics или другим сервисом
    debugPrint('📊 Analytics: Slow operation logged - $operation (${duration.inMilliseconds}ms)');
  }

  // Очистка данных производительности
  static void clearPerformanceData() {
    _frameTimes.clear();
    debugPrint('🗑️ Performance data cleared');
  }

  // Проверка системных ресурсов
  static SystemResourceInfo getSystemResourceInfo() {
    // В реальном приложении можно получить информацию о системе
    return SystemResourceInfo(
      platform: defaultTargetPlatform.toString(),
      isLowEndDevice: _isLowEndDevice(),
      batteryOptimized: false, // Заглушка
    );
  }

  // Определение слабого устройства
  static bool _isLowEndDevice() {
    // Эвристика для определения слабых устройств
    // В реальности можно использовать device_info_plus
    return false;
  }

  // Экспорт данных производительности
  static Map<String, dynamic> exportPerformanceData() {
    final stats = getPerformanceStats();
    
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'performance_stats': {
        'average_frame_time_ms': stats.averageFrameTimeMs,
        'current_fps': stats.currentFps,
        'frame_drops': stats.frameDrops,
        'total_frames': stats.totalFrames,
        'app_uptime_ms': stats.appUptimeMs,
      },
      'frame_times': _frameTimes.map((d) => d.inMicroseconds).toList(),
    };
  }
}

// Модели данных для производительности
class PerformanceStats {
  final double averageFrameTimeMs;
  final double currentFps;
  final int frameDrops;
  final int totalFrames;
  final int appUptimeMs;

  const PerformanceStats({
    required this.averageFrameTimeMs,
    required this.currentFps,
    required this.frameDrops,
    required this.totalFrames,
    required this.appUptimeMs,
  });

  double get frameDropPercentage => totalFrames > 0 ? (frameDrops / totalFrames) * 100 : 0;
}

class PerformanceReport {
  final DateTime timestamp;
  final PerformanceStats stats;
  final List<String> recommendations;
  final SessionInfo sessionInfo;

  const PerformanceReport({
    required this.timestamp,
    required this.stats,
    required this.recommendations,
    required this.sessionInfo,
  });
}

class SessionInfo {
  final DateTime startTime;
  final Duration duration;
  final DateTime? lastPerformanceCheck;

  const SessionInfo({
    required this.startTime,
    required this.duration,
    this.lastPerformanceCheck,
  });
}

class SystemResourceInfo {
  final String platform;
  final bool isLowEndDevice;
  final bool batteryOptimized;

  const SystemResourceInfo({
    required this.platform,
    required this.isLowEndDevice,
    required this.batteryOptimized,
  });
}