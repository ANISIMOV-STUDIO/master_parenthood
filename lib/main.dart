// lib/main.dart
// 🚀 Master Parenthood - Material 3 Expressive App 2025
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:velocity_x/velocity_x.dart';
import 'firebase_options.dart';

// Провайдеры
import 'providers/locale_provider.dart';
import 'providers/auth_provider.dart';

// Сервисы
import 'services/connectivity_service.dart';
import 'services/offline_service.dart';
import 'services/sync_service.dart';
import 'services/notification_service.dart';
import 'services/performance_service.dart';

// Экраны
import 'screens/home_screen.dart';
import 'screens/modern_home_screen.dart';
import 'screens/child_profile_screen.dart';
import 'screens/auth_screen.dart';

// Темы и UI
import 'core/theme/app_theme.dart';
import 'core/config/production_config.dart';

// Локализация
import 'l10n/app_localizations.dart';

// Сервисы
import 'services/firebase_service.dart';

// Dependency Injection
import 'core/injection_container.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Validate production configuration
  ProductionConfig.validateConfig();
  EnvironmentConfig.validateEnvironment();

  // Initialize dependency injection first
  try {
    await initializeDependencies();
    debugPrint('✅ Dependency injection initialized successfully');
  } catch (e) {
    debugPrint('❌ Dependency injection initialization error: $e');
  }

  // Инициализация Firebase с автоматической конфигурацией
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Включаем offline поддержку
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    
    debugPrint('✅ Firebase initialized successfully with offline support');
  } catch (e) {
    debugPrint('❌ Firebase initialization error: $e');
  }

  // Инициализация offline сервиса
  try {
    await OfflineService.initialize();
    debugPrint('✅ OfflineService initialized successfully');
  } catch (e) {
    debugPrint('❌ OfflineService initialization error: $e');
  }

  // Инициализация сервиса уведомлений
  try {
    await NotificationService.initialize();
    debugPrint('✅ NotificationService initialized successfully');
  } catch (e) {
    debugPrint('❌ NotificationService initialization error: $e');
  }

  // Инициализация сервиса производительности
  try {
    await PerformanceService.initialize();
    debugPrint('✅ PerformanceService initialized successfully');
  } catch (e) {
    debugPrint('❌ PerformanceService initialization error: $e');
  }

  // Загружаем сохраненные настройки
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('isDarkMode') ?? false;
  final languageCode = prefs.getString('languageCode') ?? 'ru';

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(isDarkMode),
        ),
        ChangeNotifierProvider(
          create: (_) => LocaleProvider(Locale(languageCode)),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => ConnectivityService(),
        ),
        StreamProvider<bool>(
          create: (_) => FirebaseService.authStateChanges.map((user) => user != null),
          initialData: false,
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    // Инициализируем сервис синхронизации
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final connectivityService = Provider.of<ConnectivityService>(context, listen: false);
      SyncService.initialize(connectivityService);
    });
  }

  @override
  void dispose() {
    // Proper cleanup when app is disposed
    disposeDependencies();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final isAuthenticated = Provider.of<bool>(context);

    return MaterialApp(
      title: 'Master Parenthood',
      debugShowCheckedModeBanner: false,

      // Modern Material 3 Expressive Themes
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,

      // Локализация
      locale: localeProvider.locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ru'), // Русский
        Locale('en'), // English
        Locale('es'), // Español
        Locale('fr'), // Français
        Locale('de'), // Deutsch
      ],

      // Навигация
      home: isAuthenticated ? const MainScreen() : const AuthScreen(),
    );
  }
}

// Провайдер темы
class ThemeProvider extends ChangeNotifier {
  bool isDarkMode;

  ThemeProvider(this.isDarkMode);

  void toggleTheme() async {
    isDarkMode = !isDarkMode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode);
  }
}

// Главный экран с навигацией
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const ModernHomeScreen(),  // Using new modern design
    const ChildProfileScreen(),
    const AchievementsScreen(),
    const CommunityScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home),
            label: loc.home,
          ),
          NavigationDestination(
            icon: const Icon(Icons.child_care),
            label: loc.child,
          ),
          NavigationDestination(
            icon: const Icon(Icons.emoji_events),
            label: loc.achievements,
          ),
          NavigationDestination(
            icon: const Icon(Icons.groups),
            label: loc.community,
          ),
        ],
      ),
    );
  }
}

// Экран достижений
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.achievements),
        centerTitle: true,
      ),
      body: StreamBuilder<UserProfile?>(
        stream: FirebaseService.getUserProfileStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final profile = snapshot.data;
          if (profile == null) {
            return const Center(child: Text('Профиль не найден'));
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Карточка уровня
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade400, Colors.pink.shade400],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.emoji_events,
                      size: 64,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${loc.level} ${profile.level}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${profile.xp} XP',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Прогресс бар
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: profile.levelProgress,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${profile.xpProgress} / ${profile.xpForNextLevel}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Список достижений
              Text(
                'Ваши достижения',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              // Список достижений
              _buildAchievementsList(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAchievementsList(BuildContext context) {
    // Предопределенные достижения
    final achievements = [
      AchievementData(
        id: 'first_story',
        title: 'Первая сказка',
        description: 'Создайте первую сказку для вашего ребенка',
        icon: Icons.auto_stories,
        color: Colors.purple,
        xpReward: 100,
      ),
      AchievementData(
        id: 'week_streak',
        title: 'Неделя заботы',
        description: 'Используйте приложение 7 дней подряд',
        icon: Icons.calendar_today,
        color: Colors.blue,
        xpReward: 200,
      ),
      AchievementData(
        id: 'ai_master',
        title: 'Мастер советов',
        description: 'Получите 10 советов от ИИ-ассистента',
        icon: Icons.auto_awesome,
        color: Colors.pink,
        xpReward: 150,
      ),
      AchievementData(
        id: 'photo_memories',
        title: 'Фотоархив',
        description: 'Загрузите 5 фотографий вашего ребенка',
        icon: Icons.photo_library,
        color: Colors.green,
        xpReward: 100,
      ),
      AchievementData(
        id: 'growth_tracker',
        title: 'Следопыт роста',
        description: 'Обновляйте данные роста и веса 3 месяца подряд',
        icon: Icons.trending_up,
        color: Colors.orange,
        xpReward: 300,
      ),
    ];

    return Column(
      children: achievements.map((achievement) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: achievement.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  achievement.icon,
                  color: achievement.color,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      achievement.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      achievement.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  const Icon(
                    Icons.stars,
                    color: Colors.amber,
                    size: 20,
                  ),
                  Text(
                    '+${achievement.xpReward}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// Экран сообщества
class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.community),
        centerTitle: true,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.groups,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Сообщество родителей',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Скоро здесь появится форум и чат',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Модель достижения
class AchievementData {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final int xpReward;

  AchievementData({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.xpReward,
  });
}