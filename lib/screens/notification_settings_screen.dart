// lib/screens/notification_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _diaryReminders = true;
  bool _developmentTips = true;
  bool _measurementReminders = true;
  bool _achievementNotifications = true;
  bool _generalUpdates = false;
  
  TimeOfDay _diaryReminderTime = const TimeOfDay(hour: 20, minute: 0);
  TimeOfDay _developmentTipTime = const TimeOfDay(hour: 10, minute: 0);
  
  AuthorizationStatus? _permissionStatus;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkPermissionStatus();
  }

  Future<void> _loadSettings() async {
    // Здесь можно загрузить сохраненные настройки из SharedPreferences
    setState(() {
      // Загрузка настроек...
    });
  }

  Future<void> _checkPermissionStatus() async {
    final status = await NotificationService.getPermissionStatus();
    setState(() {
      _permissionStatus = status;
    });
  }

  Future<void> _requestPermissions() async {
    setState(() => _isLoading = true);
    
    final granted = await NotificationService.requestPermissions();
    
    if (granted) {
      await NotificationService.initialize();
      await NotificationService.subscribeToTopics();
    }
    
    await _checkPermissionStatus();
    setState(() => _isLoading = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(granted 
              ? 'Уведомления включены!' 
              : 'Разрешение на уведомления отклонено'),
          backgroundColor: granted ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    
    try {
      // Сохранение настроек в SharedPreferences
      // await _saveToPreferences();
      
      // Планирование уведомлений с новыми настройками
      if (_permissionStatus == AuthorizationStatus.authorized) {
        await NotificationService.scheduleSmartNotifications();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Настройки сохранены!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка сохранения: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки уведомлений'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveSettings,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPermissionStatus(),
            const SizedBox(height: 24),
            _buildNotificationTypes(),
            const SizedBox(height: 24),
            _buildTimeSettings(),
            const SizedBox(height: 24),
            _buildTestSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionStatus() {
    Color statusColor;
    String statusText;
    String statusDescription;
    IconData statusIcon;

    switch (_permissionStatus) {
      case AuthorizationStatus.authorized:
        statusColor = Colors.green;
        statusText = 'Уведомления разрешены';
        statusDescription = 'Вы будете получать push-уведомления';
        statusIcon = Icons.check_circle;
        break;
      case AuthorizationStatus.denied:
        statusColor = Colors.red;
        statusText = 'Уведомления отклонены';
        statusDescription = 'Включите разрешения в настройках устройства';
        statusIcon = Icons.block;
        break;
      case AuthorizationStatus.notDetermined:
        statusColor = Colors.orange;
        statusText = 'Разрешения не запрошены';
        statusDescription = 'Нажмите кнопку для запроса разрешений';
        statusIcon = Icons.help;
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Проверка разрешений...';
        statusDescription = 'Пожалуйста, подождите';
        statusIcon = Icons.hourglass_empty;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, color: statusColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      statusDescription,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_permissionStatus != AuthorizationStatus.authorized) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _requestPermissions,
                icon: const Icon(Icons.notifications),
                label: const Text('Включить уведомления'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: statusColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.3);
  }

  Widget _buildNotificationTypes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Типы уведомлений',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildNotificationTile(
          'Напоминания о дневнике',
          'Ежедневные напоминания записать события дня',
          Icons.book,
          _diaryReminders,
          (value) => setState(() => _diaryReminders = value),
          Colors.purple,
        ),
        _buildNotificationTile(
          'Советы по развитию',
          'Полезные советы в зависимости от возраста ребенка',
          Icons.lightbulb,
          _developmentTips,
          (value) => setState(() => _developmentTips = value),
          Colors.blue,
        ),
        _buildNotificationTile(
          'Напоминания об измерениях',
          'Ежемесячные напоминания измерить рост и вес',
          Icons.straighten,
          _measurementReminders,
          (value) => setState(() => _measurementReminders = value),
          Colors.green,
        ),
        _buildNotificationTile(
          'Достижения и вехи',
          'Поздравления с новыми достижениями',
          Icons.emoji_events,
          _achievementNotifications,
          (value) => setState(() => _achievementNotifications = value),
          Colors.orange,
        ),
        _buildNotificationTile(
          'Обновления приложения',
          'Новости о новых функциях и обновлениях',
          Icons.system_update,
          _generalUpdates,
          (value) => setState(() => _generalUpdates = value),
          Colors.teal,
        ),
      ],
    );
  }

  Widget _buildNotificationTile(
    String title,
    String description,
    IconData icon,
    bool value,
    Function(bool) onChanged,
    Color color,
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: _permissionStatus == AuthorizationStatus.authorized 
                ? onChanged 
                : null,
            activeColor: color,
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.3);
  }

  Widget _buildTimeSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Время уведомлений',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildTimeTile(
          'Напоминание о дневнике',
          'Время ежедневного напоминания',
          Icons.schedule,
          _diaryReminderTime,
          _diaryReminders,
          (time) => setState(() => _diaryReminderTime = time),
          Colors.purple,
        ),
        _buildTimeTile(
          'Советы по развитию',
          'Время ежедневных советов',
          Icons.wb_sunny,
          _developmentTipTime,
          _developmentTips,
          (time) => setState(() => _developmentTipTime = time),
          Colors.blue,
        ),
      ],
    );
  }

  Widget _buildTimeTile(
    String title,
    String description,
    IconData icon,
    TimeOfDay time,
    bool enabled,
    Function(TimeOfDay) onChanged,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: enabled 
            ? Theme.of(context).cardColor 
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        boxShadow: enabled ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: enabled 
                  ? color.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon, 
              color: enabled ? color : Colors.grey, 
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: enabled ? null : Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: enabled ? Colors.grey.shade600 : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: enabled ? () => _selectTime(onChanged) : null,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: enabled 
                    ? color.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                time.format(context),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: enabled ? color : Colors.grey,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.3);
  }

  Widget _buildTestSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bug_report, color: Colors.blue.shade600),
              const SizedBox(width: 8),
              Text(
                'Тестирование',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Проверьте работу уведомлений',
            style: TextStyle(
              color: Colors.blue.shade600,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _permissionStatus == AuthorizationStatus.authorized
                  ? _sendTestNotification
                  : null,
              icon: const Icon(Icons.send),
              label: const Text('Отправить тестовое уведомление'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.3);
  }

  Future<void> _selectTime(Function(TimeOfDay) onChanged) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    
    if (picked != null) {
      onChanged(picked);
    }
  }

  Future<void> _sendTestNotification() async {
    try {
      await NotificationService.scheduleLocalNotification(
        title: 'Тестовое уведомление 🔔',
        body: 'Уведомления работают корректно!',
        scheduledTime: DateTime.now().add(const Duration(seconds: 5)),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Тестовое уведомление запланировано на через 5 секунд'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}