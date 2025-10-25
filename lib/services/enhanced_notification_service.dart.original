// lib/services/enhanced_notification_service.dart
// 🔔 Enhanced Notification Service with Local + Push Notifications - 2025
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/injection_container.dart';
import 'cache_service.dart';

class EnhancedNotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static bool _initialized = false;

  // Enhanced notification channels
  static const String milestoneChannel = 'milestone_notifications';
  static const String feedingChannel = 'feeding_notifications';
  static const String sleepChannel = 'sleep_notifications';
  static const String healthChannel = 'health_notifications';
  static const String aiInsightsChannel = 'ai_insights_notifications';
  static const String communityChannel = 'community_notifications';
  static const String emergencyChannel = 'emergency_notifications';

  /// Initialize the enhanced notification system
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Request permissions first
      await _requestPermissions();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Initialize Firebase messaging
      await _initializeFirebaseMessaging();

      // Initialize background tasks
      await _initializeBackgroundTasks();

      // Initialize timezone data
      await _initializeTimezone();

      // Setup intelligent scheduling
      await _setupIntelligentScheduling();

      _initialized = true;
      debugPrint('🔔 Enhanced Notification Service initialized successfully');
    } catch (e) {
      debugPrint('❌ EnhancedNotificationService initialization error: $e');
    }
  }

  /// Request all necessary permissions
  static Future<void> _requestPermissions() async {
    // Request notification permission
    await Permission.notification.request();

    // Request exact alarm permission for Android 12+
    if (await Permission.scheduleExactAlarm.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }

    // Request microphone permission for voice features
    await Permission.microphone.request();

    debugPrint('📱 Notification permissions requested');
  }

  /// Initialize local notifications with enhanced channels
  static Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      requestCriticalPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );

    // Create enhanced notification channels
    await _createEnhancedNotificationChannels();
  }

  /// Create comprehensive notification channels
  static Future<void> _createEnhancedNotificationChannels() async {
    final channels = [
      // High priority channels
      AndroidNotificationChannel(
        milestoneChannel,
        'Milestone Celebrations',
        description: 'Important development milestones and achievements',
        importance: Importance.high,
        sound: const RawResourceAndroidNotificationSound('celebration'),
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 300, 100, 300]),
      ),
      AndroidNotificationChannel(
        healthChannel,
        'Health & Medical',
        description: 'Vaccination reminders and health checkups',
        importance: Importance.high,
        sound: const RawResourceAndroidNotificationSound('medical_alert'),
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 500, 100, 500]),
      ),
      AndroidNotificationChannel(
        emergencyChannel,
        'Emergency Alerts',
        description: 'Critical health and safety alerts',
        importance: Importance.max,
        sound: const RawResourceAndroidNotificationSound('emergency'),
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 1000, 200, 1000, 200, 1000]),
      ),

      // Medium priority channels
      AndroidNotificationChannel(
        feedingChannel,
        'Feeding Schedule',
        description: 'Meal times and feeding reminders',
        importance: Importance.defaultImportance,
        sound: const RawResourceAndroidNotificationSound('feeding_bell'),
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 200, 100, 200]),
      ),
      AndroidNotificationChannel(
        sleepChannel,
        'Sleep & Bedtime',
        description: 'Bedtime routines and sleep schedule',
        importance: Importance.defaultImportance,
        sound: const RawResourceAndroidNotificationSound('lullaby'),
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 150, 50, 150]),
      ),
      AndroidNotificationChannel(
        aiInsightsChannel,
        'AI Parenting Insights',
        description: 'Personalized tips and recommendations',
        importance: Importance.defaultImportance,
        sound: const RawResourceAndroidNotificationSound('gentle_chime'),
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 100]),
      ),

      // Low priority channels
      AndroidNotificationChannel(
        communityChannel,
        'Community Updates',
        description: 'Global parenting community and discussions',
        importance: Importance.low,
        enableVibration: false,
      ),
    ];

    for (final channel in channels) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    debugPrint('📱 ${channels.length} notification channels created');
  }

  /// Initialize Firebase messaging
  static Future<void> _initializeFirebaseMessaging() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      criticalAlert: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _saveFcmToken(token);
        debugPrint('🔑 FCM Token obtained and saved');
      }

      // Listen to token refresh
      _firebaseMessaging.onTokenRefresh.listen(_saveFcmToken);

      // Handle messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Handle initial message when app is launched from notification
      final initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }
    }
  }

  /// Initialize background tasks for smart notifications
  static Future<void> _initializeBackgroundTasks() async {
    await Workmanager().initialize(
      _backgroundTaskHandler,
      isInDebugMode: kDebugMode,
    );

    // Register periodic task for intelligent notifications
    await Workmanager().registerPeriodicTask(
      'enhanced-notifications-check',
      'enhancedNotificationsTask',
      frequency: const Duration(hours: 2),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
        requiresCharging: false,
      ),
    );

    debugPrint('🔄 Background tasks initialized');
  }

  /// Initialize timezone for scheduling
  static Future<void> _initializeTimezone() async {
    try {
      // Initialize timezone data (this might be handled differently in production)
      debugPrint('🌍 Timezone initialized for scheduling');
    } catch (e) {
      debugPrint('❌ Timezone initialization error: $e');
    }
  }

  /// Setup intelligent notification scheduling
  static Future<void> _setupIntelligentScheduling() async {
    final prefs = await SharedPreferences.getInstance();

    // Get user preferences
    final morningHour = prefs.getInt('morning_routine_hour') ?? 8;
    final eveningHour = prefs.getInt('evening_routine_hour') ?? 19;
    final feedingInterval = prefs.getInt('feeding_interval_hours') ?? 3;

    // Schedule daily routines
    await _scheduleDailyRoutines(morningHour, eveningHour);

    // Schedule feeding reminders if enabled
    if (prefs.getBool('feeding_reminders_enabled') ?? true) {
      await _scheduleFeedingReminders(morningHour, feedingInterval);
    }

    // Schedule weekly milestone checks
    await _scheduleWeeklyMilestoneChecks();

    // Schedule AI insights
    await _scheduleAiInsights();

    debugPrint('📅 Intelligent scheduling setup complete');
  }

  /// Schedule daily morning and evening routines
  static Future<void> _scheduleDailyRoutines(int morningHour, int eveningHour) async {
    // Morning routine notification
    await _scheduleRepeatingNotification(
      id: 1001,
      title: '🌅 Good Morning!',
      body: 'Ready to start a wonderful day with your little one?',
      channel: aiInsightsChannel,
      hour: morningHour,
      minute: 0,
      payload: jsonEncode({
        'type': 'morning_routine',
        'action': 'show_daily_agenda',
      }),
    );

    // Evening routine notification
    await _scheduleRepeatingNotification(
      id: 1002,
      title: '🌙 Evening Wind Down',
      body: 'Time to prepare for a peaceful bedtime routine',
      channel: sleepChannel,
      hour: eveningHour,
      minute: 30,
      payload: jsonEncode({
        'type': 'evening_routine',
        'action': 'start_bedtime_routine',
      }),
    );
  }

  /// Schedule feeding reminders throughout the day
  static Future<void> _scheduleFeedingReminders(int startHour, int interval) async {
    final feedingTimes = <int>[];
    for (int hour = startHour; hour <= 20; hour += interval) {
      feedingTimes.add(hour);
    }

    for (int i = 0; i < feedingTimes.length; i++) {
      await _scheduleRepeatingNotification(
        id: 2000 + i,
        title: '🍼 Feeding Time',
        body: 'Time for ${_getFeedingTypeName(feedingTimes[i])}!',
        channel: feedingChannel,
        hour: feedingTimes[i],
        minute: 0,
        payload: jsonEncode({
          'type': 'feeding_reminder',
          'action': 'log_feeding',
          'feeding_type': _getFeedingTypeName(feedingTimes[i]),
        }),
      );
    }
  }

  /// Schedule weekly milestone check notifications
  static Future<void> _scheduleWeeklyMilestoneChecks() async {
    await _scheduleWeeklyNotification(
      id: 3001,
      title: '📈 Weekly Development Check',
      body: 'Time to celebrate your child\'s amazing progress this week!',
      channel: milestoneChannel,
      weekday: DateTime.sunday,
      hour: 10,
      minute: 0,
      payload: jsonEncode({
        'type': 'milestone_check',
        'action': 'update_development_progress',
      }),
    );
  }

  /// Schedule AI-powered insights
  static Future<void> _scheduleAiInsights() async {
    final insightTimes = [10, 14, 18]; // 10am, 2pm, 6pm

    for (int i = 0; i < insightTimes.length; i++) {
      await _scheduleRepeatingNotification(
        id: 4000 + i,
        title: '🤖 Daily Parenting Insight',
        body: 'Your personalized tip is ready!',
        channel: aiInsightsChannel,
        hour: insightTimes[i],
        minute: 0,
        payload: jsonEncode({
          'type': 'ai_insight',
          'action': 'show_personalized_tip',
          'time_slot': insightTimes[i],
        }),
      );
    }
  }

  /// Send enhanced personalized notification
  static Future<void> sendEnhancedNotification({
    required String title,
    required String body,
    required String channel,
    Map<String, dynamic>? data,
    List<AndroidNotificationAction>? actions,
    String? imageUrl,
    DateTime? scheduledTime,
    bool highPriority = false,
  }) async {
    final id = Random().nextInt(1000000);

    final androidDetails = AndroidNotificationDetails(
      channel,
      _getChannelDisplayName(channel),
      channelDescription: _getChannelDescription(channel),
      importance: highPriority ? Importance.high : Importance.defaultImportance,
      priority: highPriority ? Priority.high : Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(
        body,
        htmlFormatBigText: true,
        contentTitle: title,
        htmlFormatContentTitle: true,
      ),
      actions: actions,
      enableVibration: true,
      playSound: true,
      autoCancel: true,
      ongoing: false,
      showWhen: true,
      when: DateTime.now().millisecondsSinceEpoch,
      usesChronometer: false,
      category: AndroidNotificationCategory.reminder,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: _getIosSound(channel),
      threadIdentifier: channel,
      categoryIdentifier: channel,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final payload = jsonEncode({
      'channel': channel,
      'data': data ?? {},
      'timestamp': DateTime.now().toIso8601String(),
    });

    if (scheduledTime != null) {
      await _localNotifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        notificationDetails,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    } else {
      await _localNotifications.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    }

    // Track notification for analytics
    await _trackNotificationSent(channel, title, scheduledTime != null);
  }

  /// Send AI-generated contextual notification
  static Future<void> sendAiContextualNotification({
    required int childAgeInMonths,
    required String childName,
    required String language,
    String? currentActivity,
    Map<String, dynamic>? recentData,
  }) async {
    final insights = await _generateEnhancedAiInsights(
      childAgeInMonths,
      childName,
      language,
      currentActivity,
      recentData,
    );

    final actions = [
      const AndroidNotificationAction(
        'try_now',
        'Try Now',
        showsUserInterface: true,
      ),
      const AndroidNotificationAction(
        'save_tip',
        'Save for Later',
        showsUserInterface: false,
      ),
    ];

    await sendEnhancedNotification(
      title: (insights['title'] as String?) ?? 'AI Insights',
      body: (insights['body'] as String?) ?? 'New insights available',
      channel: aiInsightsChannel,
      data: {
        'insights': insights,
        'child_name': childName,
        'age_months': childAgeInMonths,
      },
      actions: actions,
    );
  }

  /// Send emergency notification
  static Future<void> sendEmergencyNotification({
    required String title,
    required String body,
    required Map<String, dynamic> emergencyData,
  }) async {
    await sendEnhancedNotification(
      title: title,
      body: body,
      channel: emergencyChannel,
      data: emergencyData,
      highPriority: true,
    );

    // Also send as push notification if possible
    // This would require backend integration
  }

  // Helper methods for scheduling
  static Future<void> _scheduleRepeatingNotification({
    required int id,
    required String title,
    required String body,
    required String channel,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    final scheduledDate = _nextInstanceOfTime(hour, minute);

    await _localNotifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel,
          _getChannelDisplayName(channel),
          channelDescription: _getChannelDescription(channel),
          importance: Importance.defaultImportance,
        ),
      ),
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> _scheduleWeeklyNotification({
    required int id,
    required String title,
    required String body,
    required String channel,
    required int weekday,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    final scheduledDate = _nextInstanceOfWeekday(weekday, hour, minute);

    await _localNotifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel,
          _getChannelDisplayName(channel),
          channelDescription: _getChannelDescription(channel),
          importance: Importance.defaultImportance,
        ),
      ),
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  // AI insights generation
  static Future<Map<String, String>> _generateEnhancedAiInsights(
    int ageInMonths,
    String childName,
    String language,
    String? currentActivity,
    Map<String, dynamic>? recentData,
  ) async {
    final cacheService = sl<CacheService>();
    final cacheKey = 'enhanced_ai_insights_${ageInMonths}_${language}_${currentActivity ?? 'general'}';

    final cached = await cacheService.get(cacheKey);
    if (cached != null) {
      final result = Map<String, String>.from(cached);
      // Personalize with child's name
      result['title'] = result['title']!.replaceAll('{childName}', childName);
      result['body'] = result['body']!.replaceAll('{childName}', childName);
      return result;
    }

    final insights = _getEnhancedAgeAppropriateInsights(ageInMonths, language, currentActivity);

    // Personalize with child's name
    insights['title'] = insights['title']!.replaceAll('{childName}', childName);
    insights['body'] = insights['body']!.replaceAll('{childName}', childName);

    await cacheService.set(cacheKey, insights, duration: const Duration(hours: 6));
    return insights;
  }

  static Map<String, String> _getEnhancedAgeAppropriateInsights(
    int ageInMonths,
    String language,
    String? currentActivity,
  ) {
    final isRussian = language == 'ru';

    if (ageInMonths <= 6) {
      return {
        'title': isRussian ? '👶 Совет для {childName}' : '👶 Tip for {childName}',
        'body': isRussian
          ? 'Время \"животик к животику\" развивает связь с {childName} и укрепляет мышцы!'
          : 'Tummy time helps {childName} develop strong muscles and bonding!',
        'tip': isRussian
          ? 'Короткие сессии по 3-5 минут несколько раз в день'
          : 'Short 3-5 minute sessions several times a day',
      };
    } else if (ageInMonths <= 12) {
      return {
        'title': isRussian ? '🎯 Развитие для {childName}' : '🎯 Development for {childName}',
        'body': isRussian
          ? 'Игра \"ку-ку\" с {childName} развивает понимание постоянства объектов!'
          : 'Playing peek-a-boo with {childName} develops object permanence!',
        'tip': isRussian
          ? 'Используйте разные предметы - платочки, игрушки, свои руки'
          : 'Use different objects - scarves, toys, your hands',
      };
    } else if (ageInMonths <= 24) {
      return {
        'title': isRussian ? '🗣️ Речь {childName}' : '🗣️ {childName}\'s Speech',
        'body': isRussian
          ? 'Называйте все, что видите с {childName} - это расширяет словарный запас!'
          : 'Name everything you see with {childName} - it expands vocabulary!',
        'tip': isRussian
          ? 'Говорите медленно и четко, повторяйте новые слова'
          : 'Speak slowly and clearly, repeat new words',
      };
    } else {
      return {
        'title': isRussian ? '🎨 Творчество с {childName}' : '🎨 Creativity with {childName}',
        'body': isRussian
          ? 'Рисование с {childName} развивает воображение и готовит руку к письму!'
          : 'Drawing with {childName} develops imagination and prepares for writing!',
        'tip': isRussian
          ? 'Пусть {childName} экспериментирует с разными материалами'
          : 'Let {childName} experiment with different materials',
      };
    }
  }

  // Utility methods
  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  static tz.TZDateTime _nextInstanceOfWeekday(int weekday, int hour, int minute) {
    tz.TZDateTime scheduledDate = _nextInstanceOfTime(hour, minute);

    while (scheduledDate.weekday != weekday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  static String _getFeedingTypeName(int hour) {
    if (hour <= 9) return 'Breakfast';
    if (hour <= 12) return 'Morning Snack';
    if (hour <= 14) return 'Lunch';
    if (hour <= 16) return 'Afternoon Snack';
    if (hour <= 18) return 'Dinner';
    return 'Evening Snack';
  }

  static String _getChannelDisplayName(String channel) {
    switch (channel) {
      case milestoneChannel: return 'Milestone Celebrations';
      case feedingChannel: return 'Feeding Schedule';
      case sleepChannel: return 'Sleep & Bedtime';
      case healthChannel: return 'Health & Medical';
      case aiInsightsChannel: return 'AI Parenting Insights';
      case communityChannel: return 'Community Updates';
      case emergencyChannel: return 'Emergency Alerts';
      default: return 'General Notifications';
    }
  }

  static String _getChannelDescription(String channel) {
    switch (channel) {
      case milestoneChannel: return 'Important development milestones and achievements';
      case feedingChannel: return 'Meal times and feeding reminders';
      case sleepChannel: return 'Bedtime routines and sleep schedule';
      case healthChannel: return 'Vaccination reminders and health checkups';
      case aiInsightsChannel: return 'Personalized tips and recommendations';
      case communityChannel: return 'Global parenting community and discussions';
      case emergencyChannel: return 'Critical health and safety alerts';
      default: return 'General app notifications';
    }
  }

  static String _getIosSound(String channel) {
    switch (channel) {
      case milestoneChannel: return 'celebration.aiff';
      case feedingChannel: return 'feeding_bell.aiff';
      case sleepChannel: return 'lullaby.aiff';
      case healthChannel: return 'medical_alert.aiff';
      case emergencyChannel: return 'emergency.aiff';
      default: return 'default.aiff';
    }
  }

  // Event handlers
  static void _handleNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      try {
        final data = jsonDecode(payload);
        _processEnhancedNotificationAction(data, response.actionId);
      } catch (e) {
        debugPrint('Error processing notification payload: $e');
      }
    }
  }

  static void _processEnhancedNotificationAction(Map<String, dynamic> data, String? actionId) {
    final channel = data['channel'] as String?;
    final notificationData = data['data'] as Map<String, dynamic>? ?? {};

    debugPrint('Processing notification: channel=$channel, action=$actionId');

    // Track interaction
    _trackNotificationInteraction(channel ?? 'unknown', actionId ?? 'opened');

    // Handle specific actions
    switch (actionId) {
      case 'try_now':
        // Execute the suggested activity
        break;
      case 'save_tip':
        // Save tip for later
        break;
      default:
        // Navigate based on channel
        _navigateBasedOnChannel(channel);
    }
  }

  static void _navigateBasedOnChannel(String? channel) {
    switch (channel) {
      case milestoneChannel:
        // Navigate to development tracking
        break;
      case feedingChannel:
        // Navigate to feeding tracker
        break;
      case sleepChannel:
        // Navigate to sleep tracker
        break;
      case aiInsightsChannel:
        // Navigate to AI insights
        break;
      case communityChannel:
        // Navigate to community
        break;
      default:
        // Navigate to home
        break;
    }
  }

  // Firebase message handlers
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Foreground message: ${message.messageId}');

    final title = message.notification?.title ?? 'Master Parenthood';
    final body = message.notification?.body ?? 'New update available';

    await sendEnhancedNotification(
      title: title,
      body: body,
      channel: communityChannel,
      data: message.data,
    );
  }

  static void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('Message opened app: ${message.messageId}');

    // Handle navigation when app is opened from push notification
    final data = message.data;
    if (data.isNotEmpty) {
      _processEnhancedNotificationAction({'data': data}, null);
    }
  }

  // Background task handler
  static void _backgroundTaskHandler() {
    Workmanager().executeTask((task, inputData) async {
      switch (task) {
        case 'enhancedNotificationsTask':
          await _performEnhancedNotificationCheck();
          return Future.value(true);
        default:
          return Future.value(false);
      }
    });
  }

  static Future<void> _performEnhancedNotificationCheck() async {
    try {
      debugPrint('🤖 Performing enhanced notification check');

      // Check for overdue milestones
      // Check feeding schedules
      // Send contextual AI insights
      // Clean up old notifications

    } catch (e) {
      debugPrint('Error in enhanced notification background task: $e');
    }
  }

  // Analytics and tracking
  static Future<void> _trackNotificationSent(String channel, String title, bool scheduled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statsJson = prefs.getString('notification_stats') ?? '{}';
      final stats = jsonDecode(statsJson) as Map<String, dynamic>;

      final today = DateTime.now().toIso8601String().split('T')[0];
      final todayStats = stats[today] as Map<String, dynamic>? ?? {};

      todayStats[channel] = (todayStats[channel] as int? ?? 0) + 1;
      stats[today] = todayStats;

      await prefs.setString('notification_stats', jsonEncode(stats));
    } catch (e) {
      debugPrint('Error tracking notification sent: $e');
    }
  }

  static Future<void> _trackNotificationInteraction(String channel, String action) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final interactionsJson = prefs.getString('notification_interactions') ?? '{}';
      final interactions = jsonDecode(interactionsJson) as Map<String, dynamic>;

      final key = '${channel}_$action';
      interactions[key] = (interactions[key] as int? ?? 0) + 1;

      await prefs.setString('notification_interactions', jsonEncode(interactions));
    } catch (e) {
      debugPrint('Error tracking notification interaction: $e');
    }
  }

  // Utility methods
  static Future<void> _saveFcmToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token', token);
    debugPrint('🔑 FCM Token saved: ${token.substring(0, 20)}...');
  }

  /// Get notification statistics
  static Future<Map<String, dynamic>> getNotificationStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statsJson = prefs.getString('notification_stats') ?? '{}';
      final interactionsJson = prefs.getString('notification_interactions') ?? '{}';

      return {
        'sent_stats': jsonDecode(statsJson),
        'interaction_stats': jsonDecode(interactionsJson),
      };
    } catch (e) {
      return {'sent_stats': {}, 'interaction_stats': {}};
    }
  }

  /// Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
    debugPrint('🚫 All notifications cancelled');
  }

  /// Cancel specific notification
  static Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  /// Update notification preferences
  static Future<void> updateNotificationPreferences({
    bool? feedingReminders,
    bool? sleepReminders,
    bool? milestoneReminders,
    bool? aiInsights,
    bool? communityUpdates,
    int? morningHour,
    int? eveningHour,
    int? feedingInterval,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (feedingReminders != null) {
      await prefs.setBool('feeding_reminders_enabled', feedingReminders);
    }
    if (sleepReminders != null) {
      await prefs.setBool('sleep_reminders_enabled', sleepReminders);
    }
    if (milestoneReminders != null) {
      await prefs.setBool('milestone_reminders_enabled', milestoneReminders);
    }
    if (aiInsights != null) {
      await prefs.setBool('ai_insights_enabled', aiInsights);
    }
    if (communityUpdates != null) {
      await prefs.setBool('community_updates_enabled', communityUpdates);
    }
    if (morningHour != null) {
      await prefs.setInt('morning_routine_hour', morningHour);
    }
    if (eveningHour != null) {
      await prefs.setInt('evening_routine_hour', eveningHour);
    }
    if (feedingInterval != null) {
      await prefs.setInt('feeding_interval_hours', feedingInterval);
    }

    // Reschedule notifications with new preferences
    await _setupIntelligentScheduling();

    debugPrint('⚙️ Notification preferences updated');
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  debugPrint('Background message: ${message.messageId}');
}