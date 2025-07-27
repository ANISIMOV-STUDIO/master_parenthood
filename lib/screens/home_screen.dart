// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../services/ai_service.dart';
import '../services/mock_firebase_service.dart' as mock_firebase;
import '../services/platform_firebase_service.dart' as platform_firebase;
import '../main.dart'; // Для ThemeProvider

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _backgroundController;

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);

    final features = [
      FeatureItem(
        icon: Icons.auto_awesome,
        title: loc.aiAssistant,
        gradient: [Colors.purple, Colors.pink],
        onTap: () => _showAIAssistant(context),
      ),
      FeatureItem(
        icon: Icons.camera_alt,
        title: loc.arHeight,
        gradient: [Colors.blue, Colors.cyan],
        onTap: () => _showComingSoon(context, loc.arHeight),
      ),
      FeatureItem(
        icon: Icons.emoji_events,
        title: loc.challenges,
        gradient: [Colors.orange, Colors.red],
        onTap: () => _showComingSoon(context, loc.challenges),
      ),
      FeatureItem(
        icon: Icons.menu_book,
        title: loc.stories,
        gradient: [Colors.green, Colors.teal],
        onTap: () => _showStoryGenerator(context),
      ),
      FeatureItem(
        icon: Icons.forum,
        title: loc.topicOfDay,
        gradient: [Colors.pink, Colors.purple],
        badge: '47',
        onTap: () => _showComingSoon(context, loc.topicOfDay),
      ),
      FeatureItem(
        icon: Icons.calendar_today,
        title: loc.dailyPlan,
        gradient: [Colors.indigo, Colors.blue],
        onTap: () => _showComingSoon(context, loc.dailyPlan),
      ),
      FeatureItem(
        icon: Icons.psychology,
        title: loc.development,
        gradient: [Colors.amber, Colors.orange],
        onTap: () => _showComingSoon(context, loc.development),
      ),
      FeatureItem(
        icon: Icons.sports_esports,
        title: loc.games,
        gradient: [Colors.teal, Colors.green],
        onTap: () => _showComingSoon(context, loc.games),
      ),
      FeatureItem(
        icon: Icons.favorite,
        title: loc.health,
        gradient: [Colors.red, Colors.pink],
        onTap: () => _showComingSoon(context, loc.health),
      ),
    ];

    return Scaffold(
      body: Stack(
        children: [
          // Анимированный фон
          AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(
                      _backgroundController.value * 2 - 1,
                      _backgroundController.value * 2 - 1,
                    ),
                    end: Alignment(
                      1 - _backgroundController.value * 2,
                      1 - _backgroundController.value * 2,
                    ),
                    colors: Theme.of(context).brightness == Brightness.dark
                        ? [
                      Colors.purple.shade900,
                      Colors.blue.shade900,
                      Colors.indigo.shade900,
                    ]
                        : [
                      Colors.purple.shade50,
                      Colors.pink.shade50,
                      Colors.blue.shade50,
                    ],
                  ),
                ),
              );
            },
          ),

          // Контент
          SafeArea(
            child: Column(
              children: [
                // Заголовок
                _buildHeader(context, themeProvider, localeProvider),

                // Приветствие
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    loc.hello,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate().fadeIn().slideY(begin: -0.2),
                ),

                // Сетка функций
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: features.length,
                      itemBuilder: (context, index) {
                        final feature = features[index];
                        return _FeatureCard(
                          feature: feature,
                          index: index,
                        );
                      },
                    ),
                  ),
                ),

                // Статистика
                _buildStatsBar(context),
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
      padding: const EdgeInsets.all(20),
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
                  Text(
                    '${loc.level} 7 • 2750 XP',
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
                onPressed: () {},
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

  Widget _buildStatsBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(value: '89', unit: 'см', color: Colors.purple),
          _StatItem(value: '12.5', unit: 'кг', color: Colors.pink),
          _StatItem(value: '2.3', unit: 'года', color: Colors.blue),
          _StatItem(value: '47', unit: 'слов', color: Colors.green),
        ],
      ),
    ).animate()
        .fadeIn(delay: 400.ms)
        .slideY(begin: 0.2);
  }

  void _showComingSoon(BuildContext context, String feature) {
    final loc = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature ${loc.comingSoon}'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showStoryGenerator(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => const StoryGeneratorSheet(),
    );
  }

  void _showAIAssistant(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => const AIAssistantSheet(),
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
                if (kIsWeb) {
        await mock_firebase.MockFirebaseService.signOut();
      } else {
        await platform_firebase.PlatformFirebaseService.signOut();
      }
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ИИ-ассистент
class AIAssistantSheet extends StatefulWidget {
  const AIAssistantSheet({super.key});

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

      // Получаем совет от ИИ
      final advice = await AIService.getParentingAdvice(
        topic: question,
        childAge: '2 года 3 месяца', // В реальном приложении брать из профиля
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
      if (kIsWeb) {
        if (mock_firebase.MockFirebaseService.isAuthenticated) {
          await mock_firebase.MockFirebaseService.addXP(10);
        }
      } else {
        if (platform_firebase.PlatformFirebaseService.isAuthenticated) {
          await platform_firebase.PlatformFirebaseService.addXP(10);
        }
      }

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
                    Text(
                      loc.aiAssistant,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
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
  final List<Color> gradient;
  final String? badge;
  final VoidCallback onTap;

  FeatureItem({
    required this.icon,
    required this.title,
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
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: feature.gradient.first.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    feature.icon,
                    color: Colors.white,
                    size: 35,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    feature.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
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
      ).animate()
          .scale(
        delay: (50 * index).ms,
        duration: 400.ms,
        curve: Curves.easeOutBack,
      ),
    );
  }
}

// Элемент статистики
class _StatItem extends StatelessWidget {
  final String value;
  final String unit;
  final Color color;

  const _StatItem({
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          unit,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

// Генератор сказок с ИИ
class StoryGeneratorSheet extends StatefulWidget {
  const StoryGeneratorSheet({super.key});

  @override
  State<StoryGeneratorSheet> createState() => _StoryGeneratorSheetState();
}

class _StoryGeneratorSheetState extends State<StoryGeneratorSheet> {
  final _nameController = TextEditingController(text: 'Максим');
  final _themeController = TextEditingController();
  String? _generatedStory;
  bool _isGenerating = false;

  @override
  void dispose() {
    _nameController.dispose();
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
        childName: _nameController.text,
        theme: _themeController.text,
        language: locale.languageCode,
      );

      setState(() {
        _generatedStory = story;
        _isGenerating = false;
      });

      // Сохраняем сказку и добавляем XP
      if (kIsWeb) {
        if (mock_firebase.MockFirebaseService.isAuthenticated) {
          await mock_firebase.MockFirebaseService.saveStory(
            childId: 'default', // В реальном приложении брать ID выбранного ребенка
            story: story,
            theme: _themeController.text,
          );
          await mock_firebase.MockFirebaseService.addXP(50);
        }
      } else {
        if (platform_firebase.PlatformFirebaseService.isAuthenticated) {
          await platform_firebase.PlatformFirebaseService.saveStory(
            childId: 'default', // В реальном приложении брать ID выбранного ребенка
            story: story,
            theme: _themeController.text,
          );
          await platform_firebase.PlatformFirebaseService.addXP(50);
        }
      }

    } catch (e) {
      setState(() {
        _isGenerating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: ${e.toString()}')),
      );
    }
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
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: loc.childName,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.child_care),
                ),
              ),
              const SizedBox(height: 16),
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
                            onPressed: () {
                              // Сохранить в избранное
                            },
                            icon: const Icon(Icons.favorite_border),
                            label: const Text('Сохранить'),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              // Поделиться
                            },
                            icon: const Icon(Icons.share),
                            label: const Text('Поделиться'),
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