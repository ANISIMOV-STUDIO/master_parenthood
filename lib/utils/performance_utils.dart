// lib/utils/performance_utils.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PerformanceUtils {
  // Дебаунсер для поисковых полей
  static DebounceTimer? _debounceTimer;
  
  static void debounce(VoidCallback callback, {Duration delay = const Duration(milliseconds: 300)}) {
    _debounceTimer?.cancel();
    _debounceTimer = DebounceTimer(delay, callback);
  }

  // Throttle для частых обновлений
  static DateTime? _lastThrottleTime;
  
  static bool shouldThrottle({Duration interval = const Duration(milliseconds: 100)}) {
    final now = DateTime.now();
    if (_lastThrottleTime == null || now.difference(_lastThrottleTime!).inMilliseconds >= interval.inMilliseconds) {
      _lastThrottleTime = now;
      return false;
    }
    return true;
  }

  // Кэш для дорогих вычислений
  static final Map<String, dynamic> _computationCache = {};
  
  static T cachedComputation<T>(String key, T Function() computation) {
    if (_computationCache.containsKey(key)) {
      return _computationCache[key] as T;
    }
    
    final result = computation();
    _computationCache[key] = result;
    return result;
  }

  // Очистка кэша
  static void clearCache([String? specificKey]) {
    if (specificKey != null) {
      _computationCache.remove(specificKey);
    } else {
      _computationCache.clear();
    }
  }

  // Измерение производительности
  static Future<T> measurePerformance<T>(
    String operation,
    Future<T> Function() task,
  ) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await task();
      stopwatch.stop();
      
      debugPrint('⏱️ Performance: $operation took ${stopwatch.elapsedMilliseconds}ms');
      
      // Предупреждение о медленных операциях
      if (stopwatch.elapsedMilliseconds > 1000) {
        debugPrint('⚠️ Slow operation detected: $operation (${stopwatch.elapsedMilliseconds}ms)');
      }
      
      return result;
    } catch (e) {
      stopwatch.stop();
      debugPrint('❌ Performance: $operation failed after ${stopwatch.elapsedMilliseconds}ms: $e');
      rethrow;
    }
  }

  // Оптимизированный билдер для списков
  static Widget optimizedListBuilder({
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
    ScrollController? controller,
    bool shrinkWrap = false,
    ScrollPhysics? physics,
  }) {
    return ListView.builder(
      controller: controller,
      shrinkWrap: shrinkWrap,
      physics: physics ?? const BouncingScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // Lazy loading для больших списков
        if (itemCount > 100 && index > 50) {
          return FutureBuilder(
            future: Future.delayed(const Duration(milliseconds: 16), () => itemBuilder(context, index)),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return snapshot.data as Widget;
              }
              return const SizedBox(
                height: 60,
                child: Center(child: CircularProgressIndicator()),
              );
            },
          );
        }
        
        return itemBuilder(context, index);
      },
    );
  }

  // Предзагрузка изображений
  static Future<void> preloadImages(BuildContext context, List<String> imageUrls) async {
    for (final url in imageUrls) {
      try {
        await precacheImage(NetworkImage(url), context);
      } catch (e) {
        debugPrint('Failed to preload image: $url - $e');
      }
    }
  }

  // Оптимизация памяти для изображений
  static Widget optimizedImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    String? placeholder,
  }) {
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: width?.round(),
      cacheHeight: height?.round(),
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: Colors.grey.shade200,
          child: const Icon(Icons.error),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        
        return Container(
          width: width,
          height: height,
          color: Colors.grey.shade100,
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
    );
  }

  // Monitoring производительности виджетов
  static Widget performanceMonitor({
    required Widget child,
    String? name,
  }) {
    return kDebugMode
        ? _PerformanceMonitorWidget(child: child, name: name)
        : child;
  }
}

// Виджет для мониторинга производительности в debug режиме
class _PerformanceMonitorWidget extends StatefulWidget {
  final Widget child;
  final String? name;

  const _PerformanceMonitorWidget({required this.child, this.name});

  @override
  State<_PerformanceMonitorWidget> createState() => _PerformanceMonitorWidgetState();
}

class _PerformanceMonitorWidgetState extends State<_PerformanceMonitorWidget> {
  int _buildCount = 0;
  DateTime? _lastBuild;

  @override
  Widget build(BuildContext context) {
    _buildCount++;
    final now = DateTime.now();
    
    if (_lastBuild != null) {
      final timeBetweenBuilds = now.difference(_lastBuild!).inMilliseconds;
      if (timeBetweenBuilds < 16) { // Меньше 60 FPS
        debugPrint('⚠️ Frequent rebuilds detected in ${widget.name ?? 'Widget'}: ${timeBetweenBuilds}ms between builds');
      }
    }
    
    _lastBuild = now;
    
    if (_buildCount % 10 == 0) {
      debugPrint('🔄 Widget ${widget.name ?? 'Unknown'} built $_buildCount times');
    }
    
    return widget.child;
  }
}

// Кастомный Timer для дебаунса
class DebounceTimer {
  Future<void>? _timer;
  
  DebounceTimer(Duration duration, VoidCallback callback) {
    _timer = Future.delayed(duration).then((_) => callback());
  }
  
  void cancel() {
    _timer = null;
  }
}

// Lazy loading контроллер для больших списков
class LazyLoadingController extends ScrollController {
  final VoidCallback onLoadMore;
  final double threshold;
  
  LazyLoadingController({
    required this.onLoadMore,
    this.threshold = 200.0,
  }) {
    addListener(_onScroll);
  }
  
  void _onScroll() {
    if (position.pixels >= position.maxScrollExtent - threshold) {
      onLoadMore();
    }
  }
  
  @override
  void dispose() {
    removeListener(_onScroll);
    super.dispose();
  }
}

// Пагинация для больших наборов данных
class PaginatedData<T> {
  final List<T> items;
  final int currentPage;
  final int pageSize;
  final bool hasMore;
  
  const PaginatedData({
    required this.items,
    required this.currentPage,
    required this.pageSize,
    required this.hasMore,
  });
  
  PaginatedData<T> addPage(List<T> newItems) {
    return PaginatedData<T>(
      items: [...items, ...newItems],
      currentPage: currentPage + 1,
      pageSize: pageSize,
      hasMore: newItems.length == pageSize,
    );
  }
}

// Оптимизированный билдер для грид-виджетов
class OptimizedGridView extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final int crossAxisCount;
  final double childAspectRatio;
  final ScrollController? controller;

  const OptimizedGridView({
    Key? key,
    required this.itemCount,
    required this.itemBuilder,
    required this.crossAxisCount,
    this.childAspectRatio = 1.0,
    this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: controller,
      physics: const BouncingScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // Виртуализация для больших грид-виджетов
        return RepaintBoundary(
          child: itemBuilder(context, index),
        );
      },
    );
  }
}