// lib/screens/story_generator_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../services/ai_service.dart';
import '../services/firebase_service.dart';

class StoryGeneratorScreen extends StatefulWidget {
  const StoryGeneratorScreen({super.key});

  @override
  State<StoryGeneratorScreen> createState() => _StoryGeneratorScreenState();
}

class _StoryGeneratorScreenState extends State<StoryGeneratorScreen> {
  final _themeController = TextEditingController();
  List<ChildProfile> _children = [];
  ChildProfile? _selectedChild;
  String? _generatedStory;
  String? _storyId;
  bool _isGenerating = false;
  bool _isFavorite = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    final activeChild = await FirebaseService.getActiveChild();

    setState(() {
      _selectedChild = activeChild;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _themeController.dispose();
    super.dispose();
  }

  void _generateStory() async {
    if (_themeController.text.isEmpty || _selectedChild == null) return;

    setState(() {
      _isGenerating = true;
    });

    try {
      final locale = Provider.of<LocaleProvider>(context, listen: false).locale;

      // Генерация через ИИ
      final story = await AIService.generateStory(
        childName: _selectedChild!.name,
        theme: _themeController.text,
        language: locale.languageCode,
      );

      // Сохраняем сказку и получаем ID
      final storyId = await FirebaseService.saveStory(
        childId: _selectedChild!.id,
        story: story,
        theme: _themeController.text,
      );

      setState(() {
        _generatedStory = story;
        _storyId = storyId;
        _isGenerating = false;
        _isFavorite = false;
      });

      await FirebaseService.addXP(50);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Сказка создана! +50 XP'),
            duration: Duration(seconds: 2),
          ),
        );
      }
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
    setState(() {
      _isFavorite = !_isFavorite;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isFavorite ? 'Добавлено в избранное' : 'Удалено из избранного'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _shareStory() {
    if (_generatedStory == null) return;

    final text = '${_themeController.text}\n\n$_generatedStory\n\nСоздано в Master Parenthood';
    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
        appBar: AppBar(
          title: Text(loc.storyGenerator),
          centerTitle: true,
          actions: [
            if (_generatedStory != null)
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: _shareStory,
              ),
          ],
        ),
        body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              // Выбор ребенка
              StreamBuilder<List<ChildProfile>>(
              stream: FirebaseService.getChildrenStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('Добавьте ребенка для создания сказок'),
                  );
                }

                _children = snapshot.data!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Для кого сказка?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: DropdownButtonFormField<ChildProfile>(
                        value: _selectedChild,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16),
                        ),
                        items: _children.map((child) {
                          return DropdownMenuItem(
                            value: child,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.purple.withValues(alpha: 0.2),
                                  child: Text(
                                    child.name[0],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(child.name),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (child) {
                          setState(() => _selectedChild = child);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            // Поле ввода темы
            TextField(
              controller: _themeController,
              decoration: InputDecoration(
                labelText: loc.storyTheme,
                hintText: loc.storyHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                filled: true,
                fillColor: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                prefixIcon: Icon(
                  Icons.auto_stories,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Кнопка генерации
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isGenerating || _selectedChild == null ? null : _generateStory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
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
                    : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.auto_fix_high, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      loc.generateStory,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

            // Результат генерации
            if (_generatedStory != null) ...[
        const SizedBox(height: 30),
    Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
    gradient: LinearGradient(
    colors: [
    Colors.purple.withValues(alpha: 0.1),
    Colors.pink.withValues(alpha: 0.1),
    ],
    ),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
    color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
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
    color: Theme.of(context).primaryColor,
    size: 28,
    ),
    const SizedBox(width: 10),
    Expanded(
    child: Text(
    _themeController.text,
    style: TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Theme.of(context).primaryColor,
    ),
    ),
    ),
    IconButton(
    onPressed: _toggleFavorite,
    icon: Icon(
    _isFavorite ? Icons.favorite : Icons.favorite_border,
    color: _isFavorite ? Colors.red : Colors.grey,
    ),
    ),
    ],
    ),
    const SizedBox(height: 16),
    Text(
    _generatedStory!,
    style: const TextStyle(
    fontSize: 16,
    height: 1.6,
    ),
    ),
    ],
    ),
    ).animate()
        .fadeIn(duration: 600.ms)
        .slideY(begin: 0.2, end: 0)
    ],

    // История сказок
    if (_selectedChild != null) ...[
    const SizedBox(height: 40),
    Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
    const Text(
    'История сказок',
    style: TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    ),
    ),
    TextButton(
    onPressed: () {
    // TODO: Открыть полную историю
    },
    child: const Text('Все'),
    ),
    ],
    ),
    const SizedBox(height: 16),
    StreamBuilder<List<StoryData>>(
    stream: FirebaseService.getStoriesStream(_selectedChild!.id),
    builder: (context, snapshot) {
    if (!snapshot.hasData || snapshot.data!.isEmpty) {
    return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
    color: Colors.grey.withValues(alpha: 0.1),
    borderRadius: BorderRadius.circular(15),
    ),
    child: const Center(
    child: Text('Еще нет созданных сказок'),
    ),
    );
    }

    final stories = snapshot.data!.take(5).toList();

    return Column(
    children: stories.map((story) {
    return Card(
    margin: const EdgeInsets.only(bottom: 10),
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(15),
    ),
    child: ListTile(
    leading: CircleAvatar(
    backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
    child: Icon(
    Icons.auto_stories,
    color: Theme.of(context).primaryColor,
    ),
    ),
    title: Text(
    story.theme,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    ),
    subtitle: Text(
    story.story,
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
    ),
    trailing: story.isFavorite
    ? const Icon(Icons.favorite, color: Colors.red, size: 20)
        : null,
    onTap: () {
    _showStoryDialog(story);
    },
    ),
    );
    }).toList(),
    );
    },
    ),
    ],
    ],
    ),
    ),
    ),
    );
  }

  void _showStoryDialog(StoryData story) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_stories,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      story.theme,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    story.story,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      await FirebaseService.toggleStoryFavorite(story.id);
                      Navigator.pop(context);
                    },
                    icon: Icon(
                      story.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: story.isFavorite ? Colors.red : null,
                    ),
                    label: Text(story.isFavorite ? 'В избранном' : 'В избранное'),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Share.share('${story.theme}\n\n${story.story}\n\nСоздано в Master Parenthood');
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Поделиться'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}