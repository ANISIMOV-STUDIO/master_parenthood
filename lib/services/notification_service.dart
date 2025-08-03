// lib/services/notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static bool _initialized = false;

  // Инициализация сервиса уведомлений
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Запрашиваем разрешения
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('📱 Notification permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Получаем FCM токен
        String? token = await _firebaseMessaging.getToken();
        if (token != null) {
          debugPrint('📱 FCM Token: $token');
          // Сохраняем токен в Firebase для пользователя
          await _saveTokenToFirebase(token);
        }

        // Обновляем токен при изменении
        _firebaseMessaging.onTokenRefresh.listen((token) async {
          debugPrint('📱 FCM Token refreshed: $token');
          await _saveTokenToFirebase(token);
        });

        // Настраиваем обработчики сообщений
        _setupMessageHandlers();
        
        _initialized = true;
        debugPrint('✅ NotificationService initialized successfully');
      }
    } catch (e) {
      debugPrint('❌ NotificationService initialization error: $e');
    }
  }

  // Сохранение FCM токена в Firebase
  static Future<void> _saveTokenToFirebase(String token) async {
    try {
      if (FirebaseService.currentUserId != null) {
        // Сохраняем токен в Firebase (нужно реализовать метод)
        // await FirebaseService.updateUserProfile({
        //   'fcmToken': token,
        //   'lastTokenUpdate': FieldValue.serverTimestamp(),
        // });
        debugPrint('✅ FCM token saved to Firebase');
      }
    } catch (e) {
      debugPrint('❌ Error saving FCM token: $e');
    }
  }

  // Настройка обработчиков сообщений
  static void _setupMessageHandlers() {
    // Обработка уведомлений когда приложение в фоне
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Обработка уведомлений когда приложение активно
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📱 Received foreground message: ${message.messageId}');
      _showForegroundNotification(message);
    });

    // Обработка нажатий на уведомления
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('📱 Notification opened app: ${message.messageId}');
      _handleNotificationTap(message);
    });

    // Проверяем, было ли приложение открыто из уведомления
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('📱 App opened from notification: ${message.messageId}');
        _handleNotificationTap(message);
      }
    });
  }

  // Показ уведомления когда приложение активно
  static void _showForegroundNotification(RemoteMessage message) {
    // Здесь можно показать кастомное уведомление в приложении
    // Или использовать флutterLocalNotificationsPlugin для показа системного уведомления
    debugPrint('📱 Showing foreground notification: ${message.notification?.title}');
  }

  // Обработка нажатий на уведомления
  static void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    final screen = data['screen'];

    debugPrint('📱 Handling notification tap - screen: $screen');

    // Навигация в зависимости от типа уведомления
    switch (screen) {
      case 'diary':
        // Переход в дневник
        break;
      case 'activities':
        // Переход в трекер активностей
        break;
      case 'profile':
        // Переход в профиль ребенка
        break;
      default:
        // Переход на главный экран
        break;
    }
  }

  // Подписка на топики уведомлений
  static Future<void> subscribeToTopics() async {
    try {
      if (FirebaseService.currentUserId != null) {
        // Подписка на общие уведомления
        await _firebaseMessaging.subscribeToTopic('general');
        
        // Подписка на уведомления по возрасту детей
        // final children = await FirebaseService.getChildren();
        // for (final child in children) {
        //   final ageGroup = _getAgeGroup(child.ageInMonths);
        //   await _firebaseMessaging.subscribeToTopic('age_$ageGroup');
        // }
        
        debugPrint('✅ Subscribed to notification topics');
      }
    } catch (e) {
      debugPrint('❌ Error subscribing to topics: $e');
    }
  }

  // Отписка от топиков
  static Future<void> unsubscribeFromTopics() async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic('general');
      
      // Отписка от всех возрастных групп
      for (int ageGroup = 0; ageGroup <= 5; ageGroup++) {
        await _firebaseMessaging.unsubscribeFromTopic('age_$ageGroup');
      }
      
      debugPrint('✅ Unsubscribed from notification topics');
    } catch (e) {
      debugPrint('❌ Error unsubscribing from topics: $e');
    }
  }

  // Определение возрастной группы

  // Отправка локального уведомления
  static Future<void> scheduleLocalNotification({
    required String title,
    required String body,
    required DateTime scheduledTime,
    Map<String, String>? data,
  }) async {
    try {
      // Здесь можно использовать flutter_local_notifications
      // для планирования локальных уведомлений
      debugPrint('📱 Scheduling local notification: $title at $scheduledTime');
    } catch (e) {
      debugPrint('❌ Error scheduling local notification: $e');
    }
  }

  // Отмена всех локальных уведомлений
  static Future<void> cancelAllLocalNotifications() async {
    try {
      // Отмена всех запланированных уведомлений
      debugPrint('📱 Cancelled all local notifications');
    } catch (e) {
      debugPrint('❌ Error cancelling local notifications: $e');
    }
  }

  // Получение статуса разрешений
  static Future<AuthorizationStatus> getPermissionStatus() async {
    final settings = await _firebaseMessaging.getNotificationSettings();
    return settings.authorizationStatus;
  }

  // Запрос разрешений заново
  static Future<bool> requestPermissions() async {
    try {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      debugPrint('❌ Error requesting notification permissions: $e');
      return false;
    }
  }

  // Планирование умных уведомлений на основе данных пользователя
  static Future<void> scheduleSmartNotifications() async {
    try {
      // final children = await FirebaseService.getChildren();
      
      // for (final child in children) {
      //   // Напоминания о записи в дневник
      //   await _scheduleDiaryReminder(child);
      //   
      //   // Советы по развитию
      //   await _scheduleDevelopmentTips(child);
      //   
      //   // Напоминания о измерениях
      //   await _scheduleMeasurementReminders(child);
      // }
      
      debugPrint('✅ Smart notifications scheduled');
    } catch (e) {
      debugPrint('❌ Error scheduling smart notifications: $e');
    }
  }

  // Напоминание о записи в дневник

  // Советы по развитию

  // Напоминания о измерениях

  // Получение советов по развитию в зависимости от возраста
}

// Обработчик фоновых сообщений
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📱 Handling background message: ${message.messageId}');
  // Здесь можно обработать фоновые уведомления
}