// lib/screens/story_generator_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../l10n/app_localizations.dart';
import '../services/firebase_service.dart';
import '../services/ai_service.dart';

class StoryGeneratorScreen extends StatefulWidget {
  const StoryGeneratorScreen({super.key});

  @override
  State<StoryGeneratorScreen> createState() => _StoryGeneratorScreenState();
}

class _StoryGeneratorScreenState extends State<StoryGeneratorScreen>
    with TickerProviderStateMixin {
  final _themeController = TextEditingController();
  late AnimationController _backgroundController;
  late AnimationController _floatingController;

  String? _generatedStory;
  bool _isGenerating = false;
  String? _selectedChildId;
  ChildProfile? _selectedChild;

  // Предустановленные темы
  final List<String> _popularThemes = [
    '🐲 Драконы',
    '👑 Принцессы',
    '🚀 Космос',
    '🦄 Единороги',
    '🏰 Замки',
    '🌊 Океан',
    '🦖 Динозавры',
    '✨ Волшебство',
    '🌳 Лес',
    '🚂 Поезда',
  ];

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _loadActiveChild();
  }

  Future<void> _loadActiveChild() async {
    final child = await FirebaseService.getActiveChild();
    if (child != null && mounted) {
      setState(() {
        _selectedChild = child;
        _selectedChildId = child.id;
      });
    }
  }

  @override
  void dispose() {
    _themeController.dispose();
    _backgroundController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  Future<void> _generateStory() async {
    if (_selectedChild == null || _themeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите ребенка и введите тему')),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final story = await AIService.generateStory(
        childName: _selectedChild!.name,
        theme: _themeController.text,
        language: Localizations.localeOf(context).languageCode,
      );

      setState(() {
        _generatedStory = story;
        _isGenerating = false;
      });

      // Сохраняем сказку
      await FirebaseService.saveStory(
        childId: _selectedChildId!,
        theme: _themeController.text,
        story: story,
      );

      // Добавляем XP
      await FirebaseService.addXP(20);
    } catch (e) {
      setState(() => _isGenerating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  void _shareStory() {
    if (_generatedStory == null) return;

    Share.share(
      'Сказка для ${_selectedChild?.name}\n\n$_generatedStory',
      subject: 'Сказка на тему: ${_themeController.text}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

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
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.purple.shade100,
                      Colors.blue.shade100,
                      Colors.pink.shade100,
                    ],
                    transform: GradientRotation(_backgroundController.value * 2 * 3.14159),
                  ),
                ),
              );
            },
          ),

          // Плавающие элементы
          ..._buildFloatingElements(),

          // Основной контент
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 200,
                  floating: true,
                  backgroundColor: Colors.transparent,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      loc.storyGenerator,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            blurRadius: 10.0,
                            color: Colors.black26,
                            offset: Offset(2.0, 2.0),
                          ),
                        ],
                      ),
                    ),
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.purple.withOpacity(0.6),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.auto_stories,
                          size: 80,
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Выбор ребенка
                      _buildChildSelector(),
                      const SizedBox(height: 20),

                      // Поле для темы
                      _buildThemeInput(),
                      const SizedBox(height: 16),

                      // Популярные темы
                      _buildPopularThemes(),
                      const SizedBox(height: 24),

                      // Кнопка генерации
                      _buildGenerateButton(),

                      // Результат
                      if (_generatedStory != null) ...[
                        const SizedBox(height: 32),
                        _buildStoryResult(),
                      ],

                      // История сказок
                      const SizedBox(height: 32),
                      _buildStoryHistory(),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFloatingElements() {
    return [
      Positioned(
        top: 100,
        left: 30,
        child: AnimatedBuilder(
          animation: _floatingController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _floatingController.value * 20),
              child: Icon(
                Icons.star,
                size: 30,
                color: Colors.yellow.withOpacity(0.3),
              ),
            );
          },
        ),
      ),
      Positioned(
        top: 200,
        right: 40,
        child: AnimatedBuilder(
          animation: _floatingController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, -_floatingController.value * 15),
              child: Icon(
                Icons.favorite,
                size: 25,
                color: Colors.pink.withOpacity(0.3),
              ),
            );
          },
        ),
      ),
      Positioned(
        bottom: 150,
        left: 50,
        child: AnimatedBuilder(
          animation: _floatingController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_floatingController.value * 10, 0),
              child: Icon(
                Icons.cloud,
                size: 40,
                color: Colors.white.withOpacity(0.3),
              ),
            );
          },
        ),
      ),
    ];
  }

  Widget _buildChildSelector() {
    return StreamBuilder<List<ChildProfile>>(
      stream: FirebaseService.getChildrenStream(),
      builder: (context, snapshot) {
        final children = snapshot.data ?? [];

        if (children.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Добавьте ребенка в профиле'),
          );
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Для кого сказка?',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: children.map((child) {
                    final isSelected = child.id == _selectedChildId;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedChild = child;
                          _selectedChildId = child.id;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundImage: child.photoURL != null
                                  ? CachedNetworkImageProvider(child.photoURL!)
                                  : null,
                              child: child.photoURL == null
                                  ? Text(child.name[0].toUpperCase())
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              child.name,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate()
                        .fadeIn(delay: Duration(milliseconds: children.indexOf(child) * 100))
                        .slideX(begin: 0.2);
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeInput() {
    final loc = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _themeController,
        decoration: InputDecoration(
          labelText: loc.storyTheme,
          hintText: loc.storyHint,
          prefixIcon: const Icon(Icons.auto_awesome),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
        ),
        onSubmitted: (_) => _generateStory(),
      ),
    );
  }

  Widget _buildPopularThemes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Популярные темы:',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _popularThemes.map((theme) {
            return GestureDetector(
              onTap: () {
                _themeController.text = theme.substring(2); // Убираем эмодзи
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  theme,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ).animate()
                .fadeIn(delay: Duration(milliseconds: _popularThemes.indexOf(theme) * 50))
                .scale(begin: const Offset(0.8, 0.8));
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGenerateButton() {
    final loc = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.purple, Colors.pink],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: _isGenerating ? null : _generateStory,
          child: Center(
            child: _isGenerating
                ? const SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.auto_stories,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  _isGenerating ? loc.generating : loc.generateStory,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate()
        .fadeIn()
        .slideY(begin: 0.2);
  }

  Widget _buildStoryResult() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_stories,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Сказка для ${_selectedChild?.name}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Тема: ${_themeController.text}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _shareStory,
                icon: const Icon(Icons.share),
                color: Colors.purple,
              ),
              IconButton(
                onPressed: () async {
                  if (_selectedChildId != null && _generatedStory != null) {
                    await FirebaseService.toggleStoryFavorite(
                      childId: _selectedChildId!,
                      storyId: '', // Нужно получить ID из сохраненной истории
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Добавлено в избранное')),
                    );
                  }
                },
                icon: const Icon(Icons.favorite_border),
                color: Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _generatedStory!,
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    ).animate()
        .fadeIn()
        .slideY(begin: 0.1);
  }

  Widget _buildStoryHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'История сказок',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            TextButton(
              onPressed: () {
                // Переход к полной истории
              },
              child: const Text('Все сказки'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<StoryData>>(
          stream: FirebaseService.getStoriesStream(childId: _selectedChildId),
          builder: (context, snapshot) {
            final stories = snapshot.data ?? [];

            if (stories.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.auto_stories,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Пока нет сказок',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: stories.take(5).length,
              itemBuilder: (context, index) {
                final story = stories[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.book,
                        color: Colors.purple,
                      ),
                    ),
                    title: Text(
                      story.theme,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      _formatDate(story.createdAt),
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (story.isFavorite)
                          const Icon(
                            Icons.favorite,
                            color: Colors.red,
                            size: 20,
                          ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.chevron_right,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                    onTap: () {
                      // Показать полную сказку
                      _showStoryDialog(story);
                    },
                  ),
                ).animate()
                    .fadeIn(delay: Duration(milliseconds: index * 100))
                    .slideX(begin: 0.1);
              },
            );
          },
        ),
      ],
    );
  }

  void _showStoryDialog(StoryData story) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          story.theme,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _formatDate(story.createdAt),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    story.story,
                    style: const TextStyle(fontSize: 16, height: 1.6),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Share.share(story.story, subject: story.theme);
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('Поделиться'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await FirebaseService.toggleStoryFavorite(
                          childId: story.childId,
                          storyId: story.id,
                        );
                        Navigator.pop(context);
                      },
                      icon: Icon(
                        story.isFavorite ? Icons.favorite : Icons.favorite_border,
                      ),
                      label: Text(
                        story.isFavorite ? 'В избранном' : 'В избранное',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Сегодня';
    } else if (difference.inDays == 1) {
      return 'Вчера';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} дней назад';
    } else {
      return '${date.day}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    }
  }
}