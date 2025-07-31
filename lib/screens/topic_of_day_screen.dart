// lib/screens/topic_of_day_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../l10n/app_localizations.dart';
import '../services/firebase_service.dart';
import '../services/ai_service.dart';

class TopicOfDayScreen extends StatefulWidget {
  const TopicOfDayScreen({super.key});

  @override
  State<TopicOfDayScreen> createState() => _TopicOfDayScreenState();
}

class _TopicOfDayScreenState extends State<TopicOfDayScreen> {
  String? _selectedChildId;
  bool _isLoading = true;
  String? _currentTopic;
  String? _topicAdvice;
  final List<Map<String, String>> _generatedActivities = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final activeChild = await FirebaseService.getActiveChild();
    if (activeChild != null) {
      setState(() {
        _selectedChildId = activeChild.id;
      });
      await _loadTopicOfDay();
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadTopicOfDay() async {
    // Темы дня по дням недели
    final topics = [
      'Изучаем цвета и формы',
      'Развиваем мелкую моторику',
      'Учимся считать',
      'Знакомимся с животными',
      'Музыка и ритм',
      'Природа вокруг нас',
      'Эмоции и чувства',
    ];

    final dayOfWeek = DateTime.now().weekday - 1;
    setState(() {
      _currentTopic = topics[dayOfWeek];
    });

    // Получаем совет от AI
    if (_selectedChildId != null) {
      final child = await FirebaseService.getChild(_selectedChildId!);
      if (child != null) {
        final advice = await AIService.getParentingAdvice(
          topic: _currentTopic!,
          childAge: '${child.ageInYears} лет',
          language: 'ru',
        );
        setState(() {
          _topicAdvice = advice;
        });
      }
    }
  }

  Future<void> _generateActivity() async {
    if (_currentTopic == null || _selectedChildId == null) return;

    setState(() => _isLoading = true);

    try {
      final child = await FirebaseService.getChild(_selectedChildId!);
      if (child != null) {
        // Генерируем активность через AI
        final activity = await AIService.getParentingAdvice(
          topic: '$_currentTopic - придумай одну конкретную игру или активность',
          childAge: '${child.ageInYears} лет',
          language: 'ru',
        );

        setState(() {
          _generatedActivities.add({
            'title': 'Активность ${_generatedActivities.length + 1}',
            'description': activity,
            'time': DateTime.now().toString(),
          });
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Новая активность добавлена!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.topicOfDay),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Карточка темы дня
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.purple.shade400,
                    Colors.pink.shade400,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withValues(alpha: 0.3),
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
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.today,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Тема дня',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _currentTopic ?? 'Загрузка...',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_topicAdvice != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _topicAdvice!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ).animate()
                .fadeIn()
                .slideY(begin: -0.1, end: 0),

            const SizedBox(height: 24),

            // Кнопка генерации активности
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _generateActivity,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Сгенерировать активность'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            if (_generatedActivities.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Сгенерированные активности',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ..._generatedActivities.asMap().entries.map((entry) {
                final index = entry.key;
                final activity = entry.value;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.purple.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                activity['title']!,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          activity['description']!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate()
                    .fadeIn(delay: Duration(milliseconds: index * 100))
                    .slideX(begin: 0.1, end: 0);
              }),
            ],

            // Предложенные активности
            const SizedBox(height: 32),
            Text(
              'Идеи для сегодня',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._getDefaultActivities().map((activity) {
              return _ActivityCard(activity: activity);
            }),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Поделиться темой'),
              content: Text(
                'Тема дня: $_currentTopic\n\n'
                    'Поделитесь этой темой с другими родителями!',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Закрыть'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // TODO: Implement sharing
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Скоро будет доступно!')),
                    );
                  },
                  child: const Text('Поделиться'),
                ),
              ],
            ),
          );
        },
        child: const Icon(Icons.share),
      ),
    );
  }

  List<Map<String, dynamic>> _getDefaultActivities() {
    switch (_currentTopic) {
      case 'Изучаем цвета и формы':
        return [
          {
            'icon': Icons.palette,
            'title': 'Цветная охота',
            'description': 'Найдите в доме предметы разных цветов',
            'duration': '15 мин',
          },
          {
            'icon': Icons.category,
            'title': 'Сортировка форм',
            'description': 'Разложите игрушки по формам',
            'duration': '20 мин',
          },
        ];
      case 'Развиваем мелкую моторику':
        return [
          {
            'icon': Icons.pan_tool,
            'title': 'Пальчиковые игры',
            'description': 'Играем в "Сороку-белобоку"',
            'duration': '10 мин',
          },
          {
            'icon': Icons.draw,
            'title': 'Рисование пальчиками',
            'description': 'Создаем картину пальчиковыми красками',
            'duration': '30 мин',
          },
        ];
      default:
        return [
          {
            'icon': Icons.play_circle,
            'title': 'Свободная игра',
            'description': 'Время для творческой игры',
            'duration': '30 мин',
          },
        ];
    }
  }
}

// Карточка активности
class _ActivityCard extends StatelessWidget {
  final Map<String, dynamic> activity;

  const _ActivityCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          // TODO: Open activity details
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  activity['icon'],
                  color: Colors.purple,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity['title'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activity['description'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  activity['duration'],
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}