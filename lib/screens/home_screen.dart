// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../services/ai_service.dart';
import '../services/firebase_service.dart';
import '../main.dart';
import 'challenges_screen.dart';
import 'analytics_screen.dart';
import 'diary_screen.dart';
import 'activity_tracker_screen.dart';
import 'notification_settings_screen.dart';
import 'performance_screen.dart';
import 'child_profile_screen.dart';
import 'vaccination_screen.dart';
import 'medical_records_screen.dart';
import 'growth_charts_screen.dart';
import 'nutrition_tracker_screen.dart';
import 'recipes_screen.dart';
import 'sleep_tracker_screen.dart';
import 'emergency_screen.dart';
import 'development_screen.dart';
import 'social_milestones_screen.dart';
import '../widgets/connectivity_indicator.dart';
import '../widgets/sync_status_widget.dart';
import '../services/cache_service.dart';
import '../services/error_handler.dart';
// import '../services/sync_service.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  UserProfile? _userProfile;
  List<ChildProfile> _children = [];
  ChildProfile? _activeChild;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    // Сначала загружаем из кэша для быстрого отображения
    final cachedProfile = CacheService.getCachedUserProfile();
    final cachedChild = CacheService.getCachedActiveChild();
    
    if (cachedProfile != null || cachedChild != null) {
      if (mounted) {
        setState(() {
          _userProfile = cachedProfile;
          _activeChild = cachedChild;
        });
      }
    }
    
    // Затем обновляем из сети в фоне
    try {
      final profile = await ErrorHandler.safeExecute(
        () => FirebaseService.getUserProfile(),
        fallback: cachedProfile,
        errorMessage: 'Loading user profile',
      );
      
      final activeChild = await ErrorHandler.safeExecute(
        () => FirebaseService.getActiveChild(),
        fallback: cachedChild,
        errorMessage: 'Loading active child',
      );

      // Кэшируем полученные данные
      CacheService.cacheUserProfile(profile);
      CacheService.cacheActiveChild(activeChild);

    if (mounted) {
      setState(() {
        _userProfile = profile;
        _activeChild = activeChild;
      });
      }
    } catch (e) {
      // Если нет кэша и произошла ошибка - показываем её
      if (cachedProfile == null && cachedChild == null && mounted) {
        ErrorHandler.showError(context, e, title: 'Ошибка загрузки данных');
      }
    }
  }

  Future<void> _navigateWithChildCheck(BuildContext context, Widget Function(String) builder) async {
    // Используем кэшированного ребенка для мгновенной навигации
    var activeChild = CacheService.getCachedActiveChild() ?? _activeChild;
    
    if (activeChild != null && context.mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => builder(activeChild!.id)));
      return;
    }
    
    try {
      // Только если нет в кэше - делаем запрос к сети
      activeChild = await FirebaseService.getActiveChild();
      
      if (activeChild != null) {
        CacheService.cacheActiveChild(activeChild);
        if (context.mounted) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => builder(activeChild!.id)));
        }
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Сначала добавьте профиль ребенка'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ErrorHandler.showError(context, e, title: 'Ошибка навигации');
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);

    // Группы функций по категориям
    final featureGroups = {
      'Профиль': {
        'icon': Icons.child_care,
        'features': [
      FeatureItem(
            icon: Icons.child_care,
            title: 'Профиль ребенка',
            subtitle: 'Рост, вес, развитие',
            gradient: [Colors.blue, Colors.lightBlue],
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChildProfileScreen())),
      ),
      FeatureItem(
            icon: Icons.show_chart,
            title: 'Физическое развитие',
            subtitle: 'Графики роста и ВОЗ',
            gradient: [Colors.purple[700]!, Colors.purple[500]!],
            onTap: () => _navigateWithChildCheck(context, (childId) => GrowthChartsScreen(childId: childId)),
      ),
      FeatureItem(
            icon: Icons.psychology,
            title: 'Раннее развитие',
            subtitle: 'Активности и прогресс',
            gradient: [Colors.purple[700]!, Colors.purple[500]!],
            onTap: () => _navigateWithChildCheck(context, (childId) => DevelopmentScreen(childId: childId)),
      ),
      FeatureItem(
            icon: Icons.people,
            title: 'Социальные вехи',
            subtitle: 'Эмоциональное развитие',
            gradient: [Colors.deepPurple[700]!, Colors.deepPurple[500]!],
            onTap: () => _navigateWithChildCheck(context, (childId) => SocialMilestonesScreen(childId: childId)),
          ),
        ]
      },
      'Здоровье': {
        'icon': Icons.health_and_safety,
        'features': [
      FeatureItem(
        icon: Icons.vaccines,
        title: 'Прививки',
        subtitle: 'Календарь вакцинации',
        gradient: [Colors.blue[700]!, Colors.blue[500]!],
            onTap: () => _navigateWithChildCheck(context, (childId) => VaccinationScreen(childId: childId)),
      ),
      FeatureItem(
        icon: Icons.medical_services,
        title: 'Медкарта',
        subtitle: 'Записи врачей, анализы',
        gradient: [Colors.green[700]!, Colors.green[500]!],
            onTap: () => _navigateWithChildCheck(context, (childId) => MedicalRecordsScreen(childId: childId)),
      ),
      FeatureItem(
            icon: Icons.emergency,
            title: 'Экстренные ситуации',
            subtitle: 'SOS и первая помощь',
            gradient: [Colors.red[800]!, Colors.red[600]!],
        onTap: () async {
          final activeChild = await FirebaseService.getActiveChild();
              if (context.mounted) {
                Navigator.push(context, MaterialPageRoute(builder: (context) => EmergencyScreen(childId: activeChild?.id)));
          }
        },
      ),
        ]
      },
      'Питание': {
        'icon': Icons.restaurant,
        'features': [
      FeatureItem(
        icon: Icons.restaurant,
        title: 'Дневник питания',
        subtitle: 'Отслеживание и анализ питания',
        gradient: [Colors.green[700]!, Colors.green[500]!],
            onTap: () => _navigateWithChildCheck(context, (childId) => NutritionTrackerScreen(childId: childId)),
      ),
      FeatureItem(
        icon: Icons.menu_book,
        title: 'Рецепты',
        subtitle: 'Здоровые рецепты по возрасту',
        gradient: [Colors.orange[700]!, Colors.orange[500]!],
            onTap: () => _navigateWithChildCheck(context, (childId) => RecipesScreen(childId: childId)),
      ),
      FeatureItem(
        icon: Icons.bedtime,
        title: 'Трекер сна',
        subtitle: 'Мониторинг качества сна',
        gradient: [Colors.indigo[700]!, Colors.indigo[500]!],
            onTap: () => _navigateWithChildCheck(context, (childId) => SleepTrackerScreen(childId: childId)),
          ),
        ]
      },
      'Активности': {
        'icon': Icons.timeline,
        'features': [
          FeatureItem(
            icon: Icons.timeline,
            title: 'Активности',
            subtitle: 'Сон, еда, прогулки',
            gradient: [Colors.teal, Colors.cyan],
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ActivityTrackerScreen())),
      ),
      FeatureItem(
            icon: Icons.book,
            title: 'Дневник',
            subtitle: 'Записи и фото',
            gradient: [Colors.pink, Colors.purple],
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DiaryScreen())),
      ),
      FeatureItem(
            icon: Icons.analytics,
            title: 'Аналитика',
            subtitle: 'Статистика развития',
            gradient: [Colors.indigo, Colors.blue],
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AnalyticsScreen())),
          ),
        ]
      },
      'AI & Игры': {
        'icon': Icons.auto_awesome,
        'features': [
          FeatureItem(
            icon: Icons.auto_awesome,
            title: loc.aiAssistant,
            subtitle: 'Советы по воспитанию',
            gradient: [Colors.purple, Colors.pink],
            onTap: () => _showAIAssistant(context),
      ),
      FeatureItem(
            icon: Icons.menu_book,
            title: loc.stories,
            subtitle: 'Персональные сказки',
            gradient: [Colors.green, Colors.teal],
            onTap: () => _showStoryGenerator(context),
          ),
          FeatureItem(
            icon: Icons.emoji_events,
            title: loc.challenges,
            subtitle: 'Задания и достижения',
            gradient: [Colors.orange, Colors.red],
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChallengesScreen())),
          ),
        ]
      },
    };

    return Scaffold(
      body: Stack(
        children: [
          // Статичный оптимизированный фон
          RepaintBoundary(
            child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                    colors: Theme.of(context).brightness == Brightness.dark
                        ? [
                    const Color(0xFF1a1a2e),
                    const Color(0xFF16213e),
                    const Color(0xFF0f3460),
                  ]
                      : [
                    const Color(0xFFf8faff),
                    const Color(0xFFe8f2ff),
                    const Color(0xFFddeeff),
                    ],
                  ),
                ),
            ),
          ),

          // Контент
          SafeArea(
            child: Column(
              children: [
                // Индикатор сети
                const ConnectivityIndicator(),
                
                // Статус синхронизации
                const SyncStatusWidget(),
                
                // Заголовок
                _buildHeader(context, themeProvider, localeProvider),

                // Приветствие
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text(
                    loc.hello,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate().fadeIn().slideY(begin: -0.2),
                ),

                // Вкладки категорий
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: false,
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                    indicator: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    unselectedLabelStyle: const TextStyle(fontSize: 9),
                    tabs: featureGroups.entries.map((entry) => Tab(
                      icon: Icon(entry.value['icon'] as IconData, size: 16),
                      text: entry.key,
                    )).toList(),
                  ),
                ),

                const SizedBox(height: 16),

                // Содержимое вкладок
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: featureGroups.values.map((group) {
                      final features = group['features'] as List<FeatureItem>;
                      return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                      childAspectRatio: 1.0,
                          ),
                          itemCount: features.length,
                      itemBuilder: (context, index) {
                        return RepaintBoundary(
                          child: _FeatureCard(
                                feature: features[index],
                            index: index,
                          ),
                        );
                      },
                    ),
                      );
                    }).toList(),
                  ),
                ),

                // Компактная информация о ребенке
                StreamBuilder<List<ChildProfile>>(
                  stream: FirebaseService.getChildrenStream(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      // Показываем кэшированные данные если есть
                      final cachedChild = CacheService.getCachedActiveChild();
                      if (cachedChild != null) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _CompactStat(icon: Icons.child_care, value: cachedChild.name, size: 12),
                              _CompactStat(icon: Icons.cake, value: cachedChild.ageFormatted, size: 12),
                              if (cachedChild.height > 0) _CompactStat(icon: Icons.height, value: '${cachedChild.height.toInt()} см', size: 12),
                              Icon(Icons.offline_bolt, size: 14, color: Colors.orange.shade700),
                            ],
                          ),
                        );
                      }
                      
                      // Если нет кэша - показываем ошибку
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_off, size: 16, color: Theme.of(context).colorScheme.error),
                            const SizedBox(width: 8),
                            Text(
                              ErrorHandler.handleFirebaseError(snapshot.error),
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                      _children = snapshot.data!;
                      final child = _activeChild ?? snapshot.data!.first;
                      // Обновляем кэш при получении новых данных
                      CacheService.cacheActiveChild(child);
                      
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _CompactStat(icon: Icons.child_care, value: child.name, size: 12),
                            _CompactStat(icon: Icons.cake, value: child.ageFormatted, size: 12),
                            if (child.height > 0) _CompactStat(icon: Icons.height, value: '${child.height.toInt()} см', size: 12),
                          ],
                        ),
                      );
                    }
                    
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      // Показываем кэш во время загрузки
                      final cachedChild = CacheService.getCachedActiveChild();
                      if (cachedChild != null) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _CompactStat(icon: Icons.child_care, value: cachedChild.name, size: 12),
                              _CompactStat(icon: Icons.cake, value: cachedChild.ageFormatted, size: 12),
                              if (cachedChild.height > 0) _CompactStat(icon: Icons.height, value: '${cachedChild.height.toInt()} см', size: 12),
                              const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(strokeWidth: 1.5),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('Загрузка...', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      );
                    }
                    
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _showAddChildDialog(context),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Добавить ребенка', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: PopupMenuButton<String>(
                              icon: Icon(Icons.arrow_drop_down, size: 20, color: Theme.of(context).primaryColor),
                              tooltip: 'Выбрать тип ребенка',
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              onSelected: (value) {
                                if (value == 'add_child') {
                                  _showAddChildDialog(context);
                                } else if (value == 'add_unborn') {
                                  _showAddUnbornChildDialog(context);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'add_child',
                                  child: Row(
                                    children: [
                                      Icon(Icons.child_care, size: 18, color: Colors.blue),
                                      SizedBox(width: 12),
                                      Text('Родившийся ребенок', style: TextStyle(fontSize: 14)),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'add_unborn',
                                  child: Row(
                                    children: [
                                      Icon(Icons.pregnant_woman, size: 18, color: Colors.pink),
                                      SizedBox(width: 12),
                                      Text('Ожидаемый ребенок', style: TextStyle(fontSize: 14)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeProvider themeProvider, LocaleProvider localeProvider) {
    final loc = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.purple, Colors.pink],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.child_care, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.appTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_userProfile != null)
                    Text(
                      '${loc.level} ${_userProfile!.level} • ${_userProfile!.xp} XP',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationSettingsScreen(),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.speed),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PerformanceScreen(),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => _showSettings(context, themeProvider, localeProvider),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }



  void _showStoryGenerator(BuildContext context) {
    if (_children.isEmpty) {
      _showAddChildDialog(context);
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => StoryGeneratorSheet(
        children: _children,
        activeChild: _activeChild,
      ),
    );
  }

  void _showAIAssistant(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => AIAssistantSheet(
        activeChild: _activeChild,
      ),
    );
  }

  void _showAddChildDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddChildDialog(),
    );
  }

  void _showAddUnbornChildDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddChildDialog(initiallyUnborn: true),
    );
  }

  void _showSettings(BuildContext context, ThemeProvider themeProvider, LocaleProvider localeProvider) {
    final loc = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              loc.settings,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Темная тема
            ListTile(
              leading: Icon(
                themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              ),
              title: Text(loc.darkMode),
              trailing: Switch(
                value: themeProvider.isDarkMode,
                onChanged: (_) => themeProvider.toggleTheme(),
              ),
            ),

            // Выбор языка
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(loc.language),
              trailing: DropdownButton<String>(
                value: localeProvider.locale.languageCode,
                underline: Container(),
                items: LocaleProvider.languageNames.entries
                    .map((entry) => DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value),
                ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    localeProvider.setLocale(Locale(value));
                  }
                },
              ),
            ),

            // Уведомления
            ListTile(
              leading: const Icon(Icons.notifications),
              title: Text(loc.notifications),
              trailing: Switch(
                value: true,
                onChanged: (value) {},
              ),
            ),

            const Divider(),

            // Выход
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: Text(
                loc.signOut,
                style: const TextStyle(color: Colors.red),
              ),
              onTap: () async {
                Navigator.of(context).pop();
                await FirebaseService.signOut();
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ИИ-ассистент с поддержкой активного ребенка
class AIAssistantSheet extends StatefulWidget {
  final ChildProfile? activeChild;

  const AIAssistantSheet({
    super.key,
    this.activeChild,
  });

  @override
  State<AIAssistantSheet> createState() => _AIAssistantSheetState();
}

class _AIAssistantSheetState extends State<AIAssistantSheet> {
  final _questionController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  void _sendMessage() async {
    if (_questionController.text.isEmpty) return;

    final question = _questionController.text;
    _questionController.clear();

    setState(() {
      _messages.add(ChatMessage(
        text: question,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });

    try {
      final locale = Provider.of<LocaleProvider>(context, listen: false).locale;

      // Используем возраст активного ребенка
      final childAge = widget.activeChild?.ageFormattedShort ?? '2 года';

      // Получаем совет от ИИ
      final advice = await AIService.getParentingAdvice(
        topic: question,
        childAge: childAge,
        language: locale.languageCode,
      );

      setState(() {
        _messages.add(ChatMessage(
          text: advice,
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });

      // Добавляем XP за использование ИИ
      await FirebaseService.addXP(10);

    } catch (e) {
      setState(() {
        _isLoading = false;
        _messages.add(ChatMessage(
          text: 'Извините, произошла ошибка. Попробуйте позже.',
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        children: [
          // Заголовок
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: Column(
              children: [
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: Theme.of(context).primaryColor,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.aiAssistant,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (widget.activeChild != null)
                            Text(
                              'Советы для ${widget.activeChild!.name} (${widget.activeChild!.ageFormattedShort})',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Сообщения
          Expanded(
            child: _messages.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Задайте любой вопрос о воспитании',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                  if (widget.activeChild != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Рекомендации будут адаптированы под возраст вашего ребенка',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _ChatBubble(message: message);
              },
            ),
          ),

          if (_isLoading)
            Container(
              padding: const EdgeInsets.all(20),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),

          // Поле ввода
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _questionController,
                    decoration: InputDecoration(
                      hintText: 'Спросите что-нибудь...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Генератор сказок с функциями сохранения и поделиться
class StoryGeneratorSheet extends StatefulWidget {
  final List<ChildProfile> children;
  final ChildProfile? activeChild;

  const StoryGeneratorSheet({
    super.key,
    required this.children,
    this.activeChild,
  });

  @override
  State<StoryGeneratorSheet> createState() => _StoryGeneratorSheetState();
}

class _StoryGeneratorSheetState extends State<StoryGeneratorSheet> {
  final _themeController = TextEditingController();
  late ChildProfile _selectedChild;
  String? _generatedStory;
  String? _storyId;
  bool _isGenerating = false;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _selectedChild = widget.activeChild ?? widget.children.first;
  }

  @override
  void dispose() {
    _themeController.dispose();
    super.dispose();
  }

  void _generateStory() async {
    if (_themeController.text.isEmpty) return;

    setState(() {
      _isGenerating = true;
    });

    try {
      final locale = Provider.of<LocaleProvider>(context, listen: false).locale;

      // Генерация через ИИ
      final story = await AIService.generateStory(
        childName: _selectedChild.name,
        theme: _themeController.text,
        language: locale.languageCode,
      );

      if (!mounted) return;

      // Сохраняем сказку и получаем ID
      final storyId = await FirebaseService.saveStory(
        childId: _selectedChild.id,
        story: story,
        theme: _themeController.text,
      );

      if (!mounted) return;

      setState(() {
        _generatedStory = story;
        _storyId = storyId;
        _isGenerating = false;
        _isFavorite = false;
      });

      await FirebaseService.addXP(50);

      if (!mounted) return;

    } catch (e) {
      setState(() {
        _isGenerating = false;
      });
      if (mounted) {
        final errorMessage = e.toString().replaceAll('Exception: ', '');
        final isNetworkError = errorMessage.contains('internet') || 
                               errorMessage.contains('Network') || 
                               errorMessage.contains('timeout');
        
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(
                    isNetworkError ? Icons.wifi_off : Icons.error_outline,
                    color: Colors.red,
                  ),
                  const SizedBox(width: 8),
                  const Text('Ошибка'),
                ],
              ),
              content: Text(errorMessage),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Закрыть'),
                ),
                if (isNetworkError) 
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _generateStory();
                    },
                    child: const Text('Повторить'),
                  ),
              ],
            );
          },
        );
      }
    }
  }

  void _toggleFavorite() async {
    if (_storyId == null) return;

    await FirebaseService.toggleStoryFavorite(_storyId!);

    if (!mounted) {
      return; // Если виджет был удалён, выходим из функции.
    }

    setState(() {
      _isFavorite = !_isFavorite;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isFavorite ? 'Добавлено в избранное' : 'Удалено из избранного'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _shareStory() {
    if (_generatedStory == null) return;

    final text = '${_themeController.text}\n\n$_generatedStory\n\nСоздано в Master Parenthood';
    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                loc.storyGenerator,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Выбор ребенка
              if (widget.children.length > 1) ...[
                DropdownButtonFormField<ChildProfile>(
                  value: _selectedChild,
                  decoration: const InputDecoration(
                    labelText: 'Для кого сказка?',
                    border: OutlineInputBorder(),
                  ),
                  items: widget.children.map((child) => DropdownMenuItem(
                    value: child,
                    child: Text(child.name),
                  )).toList(),
                  onChanged: (child) {
                    if (child != null) {
                      setState(() => _selectedChild = child);
                    }
                  },
                ),
                const SizedBox(height: 16),
              ],

              TextField(
                controller: _themeController,
                decoration: InputDecoration(
                  labelText: loc.storyTheme,
                  hintText: loc.storyHint,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.auto_stories),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isGenerating ? null : _generateStory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isGenerating
                      ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        loc.generating,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  )
                      : Text(
                    loc.generateStory,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
              if (_generatedStory != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.purple.shade200,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.auto_stories,
                            color: Colors.purple.shade700,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _themeController.text,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _generatedStory!,
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton.icon(
                            onPressed: _toggleFavorite,
                            icon: Icon(
                              _isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: _isFavorite ? Colors.red : null,
                            ),
                            label: Text(_isFavorite ? 'В избранном' : 'Сохранить'),
                          ),
                          TextButton.icon(
                            onPressed: _shareStory,
                            icon: const Icon(Icons.share),
                            label: const Text('Поделиться'),
                          ),
                          TextButton.icon(
                            onPressed: _generateStory,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Новая'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: 0.1),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// Модель сообщения чата
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

// Пузырь сообщения
class _ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: message.isUser
              ? Theme.of(context).primaryColor
              : Theme.of(context).primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight: message.isUser ? const Radius.circular(5) : null,
            bottomLeft: !message.isUser ? const Radius.circular(5) : null,
          ),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.isUser
                ? Colors.white
                : Theme.of(context).textTheme.bodyLarge?.color,
            fontSize: 16,
          ),
        ),
      ),
    ).animate().fadeIn().slideX(begin: message.isUser ? 0.1 : -0.1);
  }
}

// Модель данных для функции
class FeatureItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final List<Color> gradient;
  final String? badge;
  final VoidCallback onTap;

  FeatureItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.gradient,
    this.badge,
    required this.onTap,
  });
}

// Карточка функции
class _FeatureCard extends StatelessWidget {
  final FeatureItem feature;
  final int index;

  const _FeatureCard({
    required this.feature,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: feature.onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: feature.gradient,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: feature.gradient.first.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.1),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Stack(
                children: [
                  // Glassmorphism backdrop
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.1),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                    feature.icon,
                    color: Colors.white,
                            size: 28,
                          ),
                  ),
                  const SizedBox(height: 12),
                        Flexible(
                          child: Text(
                    feature.title,
                    style: const TextStyle(
                      color: Colors.white,
                              fontSize: 14,
                      fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                    ),
                    textAlign: TextAlign.center,
                            maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                          ),
                  ),
                  if (feature.subtitle != null) ...[
                    const SizedBox(height: 4),
                          Flexible(
                            child: Text(
                      feature.subtitle!,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.3,
                      ),
                      textAlign: TextAlign.center,
                              maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                            ),
                    ),
                  ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (feature.badge != null)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    feature.badge!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ).animate().scale(
      delay: (50 * index).ms,
      duration: 400.ms,
      curve: Curves.easeOutBack,
    );
  }
}



// Диалог добавления ребенка
class AddChildDialog extends StatefulWidget {
  final bool initiallyUnborn;
  
  const AddChildDialog({super.key, this.initiallyUnborn = false});

  @override
  State<AddChildDialog> createState() => _AddChildDialogState();
}

class _AddChildDialogState extends State<AddChildDialog> {
  final _nameController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  DateTime _birthDate = DateTime.now().subtract(const Duration(days: 365 * 2));
  String _gender = 'male';
  bool _isLoading = false;
  bool _isUnborn = false;

  @override
  void initState() {
    super.initState();
    _isUnborn = widget.initiallyUnborn;
    if (_isUnborn) {
      _birthDate = DateTime.now().add(const Duration(days: 90)); // 3 месяца вперед по умолчанию
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите имя ребенка')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseService.addChild(
        name: _nameController.text,
        birthDate: _birthDate,
        gender: _gender,
        height: double.tryParse(_heightController.text) ?? 0.0,
        weight: double.tryParse(_weightController.text) ?? 0.0,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ребенок добавлен')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isUnborn ? 'Добавить ожидаемого ребенка' : 'Добавить ребенка'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Имя',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Переключатель: родился / не родился
            SwitchListTile(
              title: Text(_isUnborn ? 'Ожидается рождение' : 'Уже родился'),
              subtitle: Text(_isUnborn ? 'Предполагаемая дата родов' : 'Дата рождения'),
              value: _isUnborn,
              onChanged: (value) {
                setState(() {
                  _isUnborn = value;
                  if (_isUnborn) {
                    _birthDate = DateTime.now().add(const Duration(days: 90)); // 3 месяца вперед по умолчанию
                  } else {
                    _birthDate = DateTime.now().subtract(const Duration(days: 365 * 2)); // 2 года назад по умолчанию
                  }
                });
              },
            ),

            // Дата рождения/родов
            ListTile(
              title: Text(_isUnborn ? 'Предполагаемая дата родов' : 'Дата рождения'),
              subtitle: Text(
                '${_birthDate.day}.${_birthDate.month}.${_birthDate.year}',
              ),
              trailing: Icon(_isUnborn ? Icons.pregnant_woman : Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _birthDate,
                  firstDate: _isUnborn 
                    ? DateTime.now() 
                    : DateTime.now().subtract(const Duration(days: 365 * 18)),
                  lastDate: _isUnborn 
                    ? DateTime.now().add(const Duration(days: 365))
                    : DateTime.now(),
                );
                if (date != null) {
                  setState(() => _birthDate = date);
                }
              },
            ),

            const SizedBox(height: 16),

            // Пол
            Row(
              children: [
                const Text('Пол: '),
                Radio<String>(
                  value: 'male',
                  groupValue: _gender,
                  onChanged: (value) => setState(() => _gender = value!),
                ),
                const Text('Мальчик'),
                Radio<String>(
                  value: 'female',
                  groupValue: _gender,
                  onChanged: (value) => setState(() => _gender = value!),
                ),
                const Text('Девочка'),
              ],
            ),

            const SizedBox(height: 16),

            // Рост и вес
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _heightController,
                    decoration: const InputDecoration(
                      labelText: 'Рост (см)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    decoration: const InputDecoration(
                      labelText: 'Вес (кг)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          child: _isLoading
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : Text(_isUnborn ? 'Добавить в ожидании' : 'Добавить'),
        ),
      ],
    );
  }
}

// Компактный виджет статистики
class _CompactStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final double size;

  const _CompactStat({
    required this.icon,
    required this.value,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor.withValues(alpha: 0.1),
            Theme.of(context).primaryColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon, 
              size: size + 2, 
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: size,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyMedium?.color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}