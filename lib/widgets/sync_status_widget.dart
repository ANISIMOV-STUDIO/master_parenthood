// lib/widgets/sync_status_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/sync_service.dart';

class SyncStatusWidget extends StatefulWidget {
  const SyncStatusWidget({super.key});

  @override
  State<SyncStatusWidget> createState() => _SyncStatusWidgetState();
}

class _SyncStatusWidgetState extends State<SyncStatusWidget> {
  SyncStatus? _syncStatus;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _updateSyncStatus();
  }

  void _updateSyncStatus() {
    setState(() {
      _syncStatus = SyncService.getSyncStatus();
    });
  }

  Future<void> _performSync() async {
    setState(() => _isRefreshing = true);
    
    final result = await SyncService.forcSync();
    
    if (mounted) {
      setState(() => _isRefreshing = false);
      _updateSyncStatus();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? Colors.green : Colors.red,
          action: result.success && result.syncedCount > 0
              ? SnackBarAction(
                  label: 'Подробнее',
                  textColor: Colors.white,
                  onPressed: () => _showSyncDetails(result),
                )
              : null,
        ),
      );
    }
  }

  void _showSyncDetails(SyncResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Синхронизация завершена'),
          ],
        ),
        content: Text('Синхронизировано элементов: ${result.syncedCount}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ОК'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_syncStatus == null || !_syncStatus!.hasUnsyncedData) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade400,
            Colors.deepOrange.shade400,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: _syncStatus!.isSyncing || _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.sync_problem,
                    color: Colors.white,
                    size: 20,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _syncStatus!.isSyncing || _isRefreshing
                      ? 'Синхронизация...'
                      : 'Есть несинхронизированные данные',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _syncStatus!.isSyncing || _isRefreshing
                      ? 'Пожалуйста, подождите'
                      : '${_syncStatus!.totalUnsyncedItems} элементов ожидают синхронизации',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (!_syncStatus!.isSyncing && !_isRefreshing)
            TextButton(
              onPressed: _performSync,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Синхронизировать',
                style: TextStyle(fontSize: 12),
              ),
            ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.3);
  }
}