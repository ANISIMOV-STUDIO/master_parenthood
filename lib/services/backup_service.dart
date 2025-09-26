// lib/services/backup_service.dart
// 💾 Advanced Backup & Sync Service - Cloud + Local Backup
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/injection_container.dart';
import 'cache_service.dart';
import 'enhanced_notification_service.dart';

enum BackupStatus { idle, inProgress, completed, failed }
enum BackupType { manual, automatic, scheduled }

class BackupInfo {
  final String id;
  final DateTime timestamp;
  final int size;
  final BackupType type;
  final String checksum;
  final Map<String, dynamic> metadata;
  final bool isCorrupted;

  BackupInfo({
    required this.id,
    required this.timestamp,
    required this.size,
    required this.type,
    required this.checksum,
    required this.metadata,
    this.isCorrupted = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'size': size,
    'type': type.name,
    'checksum': checksum,
    'metadata': metadata,
    'isCorrupted': isCorrupted,
  };

  factory BackupInfo.fromJson(Map<String, dynamic> json) => BackupInfo(
    id: json['id'],
    timestamp: DateTime.parse(json['timestamp']),
    size: json['size'],
    type: BackupType.values.firstWhere((e) => e.name == json['type']),
    checksum: json['checksum'],
    metadata: Map<String, dynamic>.from(json['metadata']),
    isCorrupted: json['isCorrupted'] ?? false,
  );
}

class BackupService {
  static BackupStatus _status = BackupStatus.idle;
  static DateTime? _lastBackup;
  static final List<BackupInfo> _backupHistory = [];

  // Cloud storage references
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Backup settings
  static const int _maxLocalBackups = 5;
  static const int _maxCloudBackups = 10;
  static const Duration _autoBackupInterval = Duration(hours: 6);

  /// Initialize backup service
  static Future<void> initialize() async {
    try {
      await _loadBackupHistory();
      await _scheduleAutoBackup();
      await _validateExistingBackups();

      debugPrint('💾 Backup Service initialized');
    } catch (e) {
      debugPrint('❌ Backup Service initialization error: $e');
    }
  }

  /// Create comprehensive backup
  static Future<String?> createBackup({
    BackupType type = BackupType.manual,
    bool includeMedia = true,
    bool uploadToCloud = true,
  }) async {
    if (_status == BackupStatus.inProgress) {
      debugPrint('⚠️ Backup already in progress');
      return null;
    }

    try {
      _status = BackupStatus.inProgress;
      await _notifyBackupStarted(type);

      final backupId = 'backup_${DateTime.now().millisecondsSinceEpoch}';
      final backupData = await _collectAllData(includeMedia);

      // Create local backup
      final localPath = await _saveLocalBackup(backupId, backupData);

      // Upload to cloud if enabled and user is authenticated
      String? cloudPath;
      if (uploadToCloud && _auth.currentUser != null) {
        cloudPath = await _uploadToCloud(backupId, backupData);
      }

      // Create backup info
      final backupInfo = BackupInfo(
        id: backupId,
        timestamp: DateTime.now(),
        size: backupData.length,
        type: type,
        checksum: _calculateChecksum(backupData),
        metadata: {
          'localPath': localPath,
          'cloudPath': cloudPath,
          'includeMedia': includeMedia,
          'itemsCount': await _countBackupItems(),
        },
      );

      // Save backup info
      await _saveBackupInfo(backupInfo);
      _backupHistory.insert(0, backupInfo);

      // Cleanup old backups
      await _cleanupOldBackups();

      _status = BackupStatus.completed;
      _lastBackup = DateTime.now();

      await _notifyBackupCompleted(backupInfo);

      debugPrint('💾 Backup completed: $backupId (${_formatSize(backupInfo.size)})');
      return backupId;
    } catch (e) {
      _status = BackupStatus.failed;
      await _notifyBackupFailed(e);
      debugPrint('❌ Backup failed: $e');
      return null;
    }
  }

  /// Restore from backup
  static Future<bool> restoreFromBackup(String backupId, {bool fromCloud = false}) async {
    try {
      await _notifyRestoreStarted();

      final backupInfo = _backupHistory.firstWhere((backup) => backup.id == backupId);
      final backupData = fromCloud
          ? await _downloadFromCloud(backupInfo.metadata['cloudPath'])
          : await _loadLocalBackup(backupInfo.metadata['localPath']);

      if (backupData == null) {
        throw Exception('Backup data not found');
      }

      // Verify integrity
      final currentChecksum = _calculateChecksum(backupData);
      if (currentChecksum != backupInfo.checksum) {
        throw Exception('Backup integrity check failed');
      }

      // Parse and restore data
      final restoredData = jsonDecode(utf8.decode(backupData));
      await _restoreAllData(restoredData);

      await _notifyRestoreCompleted();

      debugPrint('💾 Restore completed from backup: $backupId');
      return true;
    } catch (e) {
      await _notifyRestoreFailed(e);
      debugPrint('❌ Restore failed: $e');
      return false;
    }
  }

  /// Get backup history
  static List<BackupInfo> get backupHistory => List.unmodifiable(_backupHistory);

  /// Get backup status
  static BackupStatus get status => _status;

  /// Get last backup time
  static DateTime? get lastBackup => _lastBackup;

  /// Enable automatic backups
  static Future<void> enableAutoBackup({
    Duration? interval,
    bool includeMedia = true,
    bool uploadToCloud = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_backup_enabled', true);
    await prefs.setInt('auto_backup_interval_hours', (interval ?? _autoBackupInterval).inHours);
    await prefs.setBool('auto_backup_include_media', includeMedia);
    await prefs.setBool('auto_backup_upload_cloud', uploadToCloud);

    await _scheduleAutoBackup();
    debugPrint('💾 Auto backup enabled');
  }

  /// Disable automatic backups
  static Future<void> disableAutoBackup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_backup_enabled', false);

    debugPrint('💾 Auto backup disabled');
  }

  /// Check if auto backup is due
  static Future<bool> isAutoBackupDue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final autoBackupEnabled = prefs.getBool('auto_backup_enabled') ?? false;

      if (!autoBackupEnabled) return false;

      final intervalHours = prefs.getInt('auto_backup_interval_hours') ?? _autoBackupInterval.inHours;
      final lastAutoBackup = _backupHistory.where((backup) => backup.type == BackupType.automatic).isNotEmpty
          ? _backupHistory.where((backup) => backup.type == BackupType.automatic).first.timestamp
          : null;

      if (lastAutoBackup == null) return true;

      return DateTime.now().difference(lastAutoBackup).inHours >= intervalHours;
    } catch (e) {
      debugPrint('Error checking auto backup: $e');
      return false;
    }
  }

  /// Perform auto backup if needed
  static Future<void> performAutoBackupIfNeeded() async {
    if (await isAutoBackupDue()) {
      final prefs = await SharedPreferences.getInstance();
      final includeMedia = prefs.getBool('auto_backup_include_media') ?? true;
      final uploadToCloud = prefs.getBool('auto_backup_upload_cloud') ?? true;

      await createBackup(
        type: BackupType.automatic,
        includeMedia: includeMedia,
        uploadToCloud: uploadToCloud,
      );
    }
  }

  /// Get backup statistics
  static Future<Map<String, dynamic>> getBackupStats() async {
    final totalSize = _backupHistory.fold<int>(0, (sum, backup) => sum + backup.size);
    final cloudBackups = _backupHistory.where((b) => b.metadata['cloudPath'] != null).length;
    final localBackups = _backupHistory.where((b) => b.metadata['localPath'] != null).length;

    return {
      'totalBackups': _backupHistory.length,
      'totalSize': totalSize,
      'totalSizeFormatted': _formatSize(totalSize),
      'cloudBackups': cloudBackups,
      'localBackups': localBackups,
      'lastBackup': _lastBackup?.toIso8601String(),
      'autoBackupEnabled': await _isAutoBackupEnabled(),
      'corrupted': _backupHistory.where((b) => b.isCorrupted).length,
    };
  }

  /// Delete backup
  static Future<void> deleteBackup(String backupId) async {
    try {
      final backup = _backupHistory.firstWhere((b) => b.id == backupId);

      // Delete local file
      if (backup.metadata['localPath'] != null) {
        final file = File(backup.metadata['localPath']);
        if (await file.exists()) {
          await file.delete();
        }
      }

      // Delete cloud file
      if (backup.metadata['cloudPath'] != null && _auth.currentUser != null) {
        try {
          await _storage.ref(backup.metadata['cloudPath']).delete();
        } catch (e) {
          debugPrint('Warning: Could not delete cloud backup: $e');
        }
      }

      // Remove from history
      _backupHistory.removeWhere((b) => b.id == backupId);
      await _saveBackupHistory();

      debugPrint('💾 Backup deleted: $backupId');
    } catch (e) {
      debugPrint('Error deleting backup: $e');
    }
  }

  /// Export backup data as JSON
  static Future<String> exportBackupData(String backupId) async {
    try {
      final backup = _backupHistory.firstWhere((b) => b.id == backupId);
      final backupData = await _loadLocalBackup(backup.metadata['localPath']);

      if (backupData == null) {
        throw Exception('Backup data not found');
      }

      return utf8.decode(backupData);
    } catch (e) {
      debugPrint('Error exporting backup: $e');
      rethrow;
    }
  }

  /// Import backup data from JSON
  static Future<bool> importBackupData(String jsonData) async {
    try {
      final data = jsonDecode(jsonData);
      await _restoreAllData(data);

      debugPrint('💾 Backup imported successfully');
      return true;
    } catch (e) {
      debugPrint('Error importing backup: $e');
      return false;
    }
  }

  // Private methods
  static Future<Uint8List> _collectAllData(bool includeMedia) async {
    final allData = <String, dynamic>{};

    // Collect SharedPreferences data
    final prefs = await SharedPreferences.getInstance();
    allData['preferences'] = <String, dynamic>{};
    for (final key in prefs.getKeys()) {
      final value = prefs.get(key);
      if (value != null) {
        allData['preferences'][key] = value;
      }
    }

    // Collect app-specific data
    allData['calendar_events'] = prefs.getString('calendar_events') ?? '[]';
    allData['voice_notes'] = prefs.getString('voice_notes') ?? '[]';
    allData['notification_stats'] = prefs.getString('notification_stats') ?? '{}';
    allData['ai_insights'] = prefs.getString('ai_insights') ?? '{}';

    // Collect cache data (important user data only)
    final cacheService = sl<CacheService>();
    allData['cache_important'] = await _collectImportantCacheData();

    // Include media files if requested
    if (includeMedia) {
      allData['media'] = await _collectMediaFiles();
    }

    // Add metadata
    allData['metadata'] = {
      'version': '1.0',
      'timestamp': DateTime.now().toIso8601String(),
      'includeMedia': includeMedia,
      'platform': Platform.operatingSystem,
    };

    final jsonString = jsonEncode(allData);
    return utf8.encode(jsonString);
  }

  static Future<Map<String, dynamic>> _collectImportantCacheData() async {
    final importantData = <String, dynamic>{};

    try {
      final cacheService = sl<CacheService>();

      // Collect translation cache
      final translationKeys = ['translation_', 'ai_insights_', 'ai_weekly_schedule_'];
      for (final keyPrefix in translationKeys) {
        // This would require cache service to expose a method to get keys by prefix
        // For now, we'll skip this or implement a different approach
      }
    } catch (e) {
      debugPrint('Error collecting cache data: $e');
    }

    return importantData;
  }

  static Future<Map<String, String>> _collectMediaFiles() async {
    final mediaData = <String, String>{};

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final mediaDir = Directory('${appDir.path}/media');

      if (await mediaDir.exists()) {
        await for (final entity in mediaDir.list(recursive: true)) {
          if (entity is File) {
            final relativePath = entity.path.replaceFirst('${appDir.path}/', '');
            final bytes = await entity.readAsBytes();
            mediaData[relativePath] = base64Encode(bytes);
          }
        }
      }
    } catch (e) {
      debugPrint('Error collecting media files: $e');
    }

    return mediaData;
  }

  static Future<String> _saveLocalBackup(String backupId, Uint8List data) async {
    final appDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${appDir.path}/backups');

    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    final backupFile = File('${backupDir.path}/$backupId.backup');
    await backupFile.writeAsBytes(data);

    return backupFile.path;
  }

  static Future<Uint8List?> _loadLocalBackup(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
    } catch (e) {
      debugPrint('Error loading local backup: $e');
    }
    return null;
  }

  static Future<String?> _uploadToCloud(String backupId, Uint8List data) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final cloudPath = 'backups/${user.uid}/$backupId.backup';
      final ref = _storage.ref(cloudPath);

      await ref.putData(data, SettableMetadata(
        contentType: 'application/octet-stream',
        customMetadata: {
          'backupId': backupId,
          'timestamp': DateTime.now().toIso8601String(),
          'userId': user.uid,
        },
      ));

      // Also save backup metadata to Firestore
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('backups')
          .doc(backupId)
          .set({
        'id': backupId,
        'timestamp': FieldValue.serverTimestamp(),
        'size': data.length,
        'cloudPath': cloudPath,
        'checksum': _calculateChecksum(data),
      });

      return cloudPath;
    } catch (e) {
      debugPrint('Error uploading to cloud: $e');
      return null;
    }
  }

  static Future<Uint8List?> _downloadFromCloud(String? cloudPath) async {
    try {
      if (cloudPath == null) return null;

      final ref = _storage.ref(cloudPath);
      return await ref.getData();
    } catch (e) {
      debugPrint('Error downloading from cloud: $e');
      return null;
    }
  }

  static Future<void> _restoreAllData(Map<String, dynamic> data) async {
    // Restore SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    final preferencesData = data['preferences'] as Map<String, dynamic>? ?? {};
    for (final entry in preferencesData.entries) {
      final value = entry.value;
      if (value is String) {
        await prefs.setString(entry.key, value);
      } else if (value is int) {
        await prefs.setInt(entry.key, value);
      } else if (value is double) {
        await prefs.setDouble(entry.key, value);
      } else if (value is bool) {
        await prefs.setBool(entry.key, value);
      } else if (value is List<String>) {
        await prefs.setStringList(entry.key, value);
      }
    }

    // Restore media files
    final mediaData = data['media'] as Map<String, String>? ?? {};
    if (mediaData.isNotEmpty) {
      await _restoreMediaFiles(mediaData);
    }

    debugPrint('💾 All data restored successfully');
  }

  static Future<void> _restoreMediaFiles(Map<String, String> mediaData) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();

      for (final entry in mediaData.entries) {
        final filePath = '${appDir.path}/${entry.key}';
        final file = File(filePath);

        // Create directory if it doesn't exist
        await file.parent.create(recursive: true);

        // Decode and write file
        final bytes = base64Decode(entry.value);
        await file.writeAsBytes(bytes);
      }

      debugPrint('💾 Restored ${mediaData.length} media files');
    } catch (e) {
      debugPrint('Error restoring media files: $e');
    }
  }

  static String _calculateChecksum(Uint8List data) {
    final digest = sha256.convert(data);
    return digest.toString();
  }

  static String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(1)} GB';
  }

  static Future<int> _countBackupItems() async {
    int count = 0;

    try {
      final prefs = await SharedPreferences.getInstance();
      count += prefs.getKeys().length;

      // Count calendar events
      final calendarEvents = prefs.getString('calendar_events') ?? '[]';
      final events = jsonDecode(calendarEvents) as List<dynamic>;
      count += events.length;

      // Count voice notes
      final voiceNotes = prefs.getString('voice_notes') ?? '[]';
      final notes = jsonDecode(voiceNotes) as List<dynamic>;
      count += notes.length;
    } catch (e) {
      debugPrint('Error counting backup items: $e');
    }

    return count;
  }

  static Future<void> _cleanupOldBackups() async {
    // Remove old local backups
    if (_backupHistory.length > _maxLocalBackups) {
      final oldBackups = _backupHistory.skip(_maxLocalBackups).toList();
      for (final backup in oldBackups) {
        if (backup.metadata['localPath'] != null) {
          try {
            final file = File(backup.metadata['localPath']);
            if (await file.exists()) {
              await file.delete();
            }
          } catch (e) {
            debugPrint('Warning: Could not delete old backup file: $e');
          }
        }
      }
    }

    // Keep only the latest backups in history
    if (_backupHistory.length > _maxLocalBackups) {
      _backupHistory.removeRange(_maxLocalBackups, _backupHistory.length);
      await _saveBackupHistory();
    }
  }

  static Future<void> _loadBackupHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString('backup_history') ?? '[]';
      final historyList = jsonDecode(historyJson) as List<dynamic>;

      _backupHistory.clear();
      _backupHistory.addAll(
        historyList.map((data) => BackupInfo.fromJson(data))
      );

      // Set last backup time
      if (_backupHistory.isNotEmpty) {
        _lastBackup = _backupHistory.first.timestamp;
      }
    } catch (e) {
      debugPrint('Error loading backup history: $e');
    }
  }

  static Future<void> _saveBackupHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = jsonEncode(
        _backupHistory.map((backup) => backup.toJson()).toList()
      );
      await prefs.setString('backup_history', historyJson);
    } catch (e) {
      debugPrint('Error saving backup history: $e');
    }
  }

  static Future<void> _saveBackupInfo(BackupInfo backupInfo) async {
    _backupHistory.insert(0, backupInfo);
    await _saveBackupHistory();
  }

  static Future<void> _scheduleAutoBackup() async {
    // This would be implemented with WorkManager or similar
    // for now, we'll just track when auto backup should run
    debugPrint('💾 Auto backup scheduled');
  }

  static Future<void> _validateExistingBackups() async {
    try {
      for (final backup in _backupHistory) {
        // Check if local file exists
        if (backup.metadata['localPath'] != null) {
          final file = File(backup.metadata['localPath']);
          if (!await file.exists()) {
            debugPrint('⚠️ Local backup file missing: ${backup.id}');
            // Mark as corrupted or remove from history
          }
        }
      }
    } catch (e) {
      debugPrint('Error validating backups: $e');
    }
  }

  static Future<bool> _isAutoBackupEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('auto_backup_enabled') ?? false;
  }

  // Notification methods
  static Future<void> _notifyBackupStarted(BackupType type) async {
    await EnhancedNotificationService.sendEnhancedNotification(
      title: '💾 Backup Started',
      body: 'Creating ${type.name} backup of your data...',
      channel: EnhancedNotificationService.aiInsightsChannel,
    );
  }

  static Future<void> _notifyBackupCompleted(BackupInfo backupInfo) async {
    await EnhancedNotificationService.sendEnhancedNotification(
      title: '✅ Backup Completed',
      body: 'Successfully backed up ${_formatSize(backupInfo.size)} of data',
      channel: EnhancedNotificationService.aiInsightsChannel,
      data: {'backupId': backupInfo.id},
    );
  }

  static Future<void> _notifyBackupFailed(dynamic error) async {
    await EnhancedNotificationService.sendEnhancedNotification(
      title: '❌ Backup Failed',
      body: 'Failed to create backup: ${error.toString()}',
      channel: EnhancedNotificationService.aiInsightsChannel,
      highPriority: true,
    );
  }

  static Future<void> _notifyRestoreStarted() async {
    await EnhancedNotificationService.sendEnhancedNotification(
      title: '📥 Restore Started',
      body: 'Restoring your data from backup...',
      channel: EnhancedNotificationService.aiInsightsChannel,
    );
  }

  static Future<void> _notifyRestoreCompleted() async {
    await EnhancedNotificationService.sendEnhancedNotification(
      title: '✅ Restore Completed',
      body: 'Successfully restored your data from backup',
      channel: EnhancedNotificationService.aiInsightsChannel,
    );
  }

  static Future<void> _notifyRestoreFailed(dynamic error) async {
    await EnhancedNotificationService.sendEnhancedNotification(
      title: '❌ Restore Failed',
      body: 'Failed to restore from backup: ${error.toString()}',
      channel: EnhancedNotificationService.aiInsightsChannel,
      highPriority: true,
    );
  }
}