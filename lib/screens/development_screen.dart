// lib/screens/development_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../l10n/app_localizations.dart';
import '../services/challenges_service.dart';
import '../services/firebase_service.dart';

class DevelopmentScreen extends StatefulWidget {
  const DevelopmentScreen({super.key});

  @override
  State<DevelopmentScreen> createState() => _DevelopmentScreenState();
}

class _DevelopmentScreenState extends State<DevelopmentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ChildProfile? _activeChild;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadActiveChild();
  }

  Future<void> _loadActiveChild() async {
    final child = await FirebaseService.getActiveChild();
    if (mounted) {
      setState(() => _activeChild = child);
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

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.development),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Вехи развития'),
            Tab(text: 'График роста'),
            Tab(text: 'Статистика'),
          ],
        ),
      ),
      body: _activeChild == null
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          _MilestonesTab(child: _activeChild!),
          _GrowthChartTab(child: _activeChild!),
          _StatisticsTab(child: _activeChild!),
        ],
      ),
    );
  }
}

// Вкладка вех развития
class _MilestonesTab extends StatelessWidget {
  final ChildProfile child;

  const _MilestonesTab({required this.child});

  @override
  Widget build(BuildContext context) {
    final milestones = _getMilestonesForAge(child.ageInMonths);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Карточка возраста
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  Colors.purple.withValues(alpha: 0.1),
                  Colors.pink.withValues(alpha: 0.1),
                ],
              ),
            ),
            child: Column(
              children: [
                Text(
                  child.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Возраст: ${child.ageFormatted}',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(
                      icon: Icons.height,
                      label: 'Рост',
                      value: '${child.height.toStringAsFixed(1)} см',
                      color: Colors.blue,
                    ),
                    _StatItem(
                      icon: Icons.monitor_weight,
                      label: 'Вес',
                      value: '${child.weight.toStringAsFixed(1)} кг',
                      color: Colors.green,
                    ),
                    _StatItem(
                      icon: Icons.abc,
                      label: 'Слов',
                      value: '${child.vocabularySize}',
                      color: Colors.orange,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ).animate().fadeIn().slideY(begin: -0.1, end: 0),

        const SizedBox(height: 20),

        // Вехи развития
        Text(
          'Вехи развития для ${child.ageInYears} ${_getYearWord(child.ageInYears)}',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        ...milestones.map((category) {
          final categoryData = category.entries.first;
          return _MilestoneCategoryCard(
            category: categoryData.key,
            milestones: categoryData.value,
            childMilestones: child.milestones[categoryData.key] ?? {},
          );
        }),
      ],
    );
  }

  String _getYearWord(int years) {
    if (years % 10 == 1 && years % 100 != 11) return 'год';
    if ([2, 3, 4].contains(years % 10) && ![12, 13, 14].contains(years % 100)) return 'года';
    return 'лет';
  }

  List<Map<String, List<Map<String, dynamic>>>> _getMilestonesForAge(int ageInMonths) {
    // Вехи развития по возрастам
    if (ageInMonths < 3) {
      return [
        {
          'physical': [
            {'title': 'Держит голову', 'desc': 'Может удерживать голову прямо'},
            {'title': 'Следит глазами', 'desc': 'Следит за движущимися предметами'},
          ]
        },
        {
          'social': [
            {'title': 'Улыбается', 'desc': 'Социальная улыбка в ответ'},
            {'title': 'Узнает голоса', 'desc': 'Различает знакомые голоса'},
          ]
        },
      ];
    } else if (ageInMonths < 6) {
      return [
        {
          'physical': [
            {'title': 'Переворачивается', 'desc': 'С живота на спину и обратно'},
            {'title': 'Хватает игрушки', 'desc': 'Целенаправленно берет предметы'},
          ]
        },
        {
          'cognitive': [
            {'title': 'Изучает предметы', 'desc': 'Рассматривает и трогает'},
            {'title': 'Реагирует на имя', 'desc': 'Поворачивается на свое имя'},
          ]
        },
      ];
    } else if (ageInMonths < 12) {
      return [
        {
          'physical': [
            {'title': 'Сидит без поддержки', 'desc': 'Уверенно сидит сам'},
            {'title': 'Ползает', 'desc': 'Передвигается на четвереньках'},
            {'title': 'Встает с опорой', 'desc': 'Подтягивается и стоит'},
          ]
        },
        {
          'language': [
            {'title': 'Лепетает', 'desc': 'Произносит слоги ба-ба, ма-ма'},
            {'title': 'Понимает "нет"', 'desc': 'Реагирует на запреты'},
          ]
        },
      ];
    } else {
      return [
        {
          'physical': [
            {'title': 'Ходит самостоятельно', 'desc': 'Делает первые шаги'},
            {'title': 'Поднимается по лестнице', 'desc': 'С поддержкой за руку'},
          ]
        },
        {
          'language': [
            {'title': 'Говорит слова', 'desc': 'Произносит 5-10 слов'},
            {'title': 'Показывает части тела', 'desc': 'По просьбе взрослого'},
          ]
        },
      ];
    }
  }
}

// Карточка категории вех
class _MilestoneCategoryCard extends StatelessWidget {
  final String category;
  final List<Map<String, dynamic>> milestones;
  final Map<String, dynamic> childMilestones;

  const _MilestoneCategoryCard({
    required this.category,
    required this.milestones,
    required this.childMilestones,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(category).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getCategoryIcon(category),
                    color: _getCategoryColor(category),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _getCategoryName(category),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...milestones.map((milestone) {
              final isCompleted = childMilestones[milestone['title']] ?? false;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: isCompleted,
                      onChanged: (value) {
                        // TODO: Update milestone status
                      },
                      activeColor: _getCategoryColor(category),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            milestone['title'],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            milestone['desc'],
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
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'physical':
        return Colors.blue;
      case 'cognitive':
        return Colors.orange;
      case 'language':
        return Colors.green;
      case 'social':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'physical':
        return Icons.directions_run;
      case 'cognitive':
        return Icons.psychology;
      case 'language':
        return Icons.chat;
      case 'social':
        return Icons.people;
      default:
        return Icons.check_circle;
    }
  }

  String _getCategoryName(String category) {
    switch (category) {
      case 'physical':
        return 'Физическое развитие';
      case 'cognitive':
        return 'Познавательное развитие';
      case 'language':
        return 'Речевое развитие';
      case 'social':
        return 'Социальное развитие';
      default:
        return 'Развитие';
    }
  }
}

// Вкладка графика роста
class _GrowthChartTab extends StatelessWidget {
  final ChildProfile child;

  const _GrowthChartTab({required this.child});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _GrowthChart(
            title: 'Рост (см)',
            currentValue: child.height,
            color: Colors.blue,
          ),
          const SizedBox(height: 24),
          _GrowthChart(
            title: 'Вес (кг)',
            currentValue: child.weight,
            color: Colors.green,
          ),
        ],
      ),
    );
  }
}

// График роста
class _GrowthChart extends StatelessWidget {
  final String title;
  final double currentValue;
  final Color color;

  const _GrowthChart({
    required this.title,
    required this.currentValue,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Текущее значение: ${currentValue.toStringAsFixed(1)}',
              style: TextStyle(
                fontSize: 16,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              height: 200,
              padding: const EdgeInsets.only(right: 16),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withValues(alpha: 0.3),
                        strokeWidth: 1,
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withValues(alpha: 0.3),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()} мес',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 10,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.3),
                    ),
                  ),
                  minX: 0,
                  maxX: 12,
                  minY: 0,
                  maxY: currentValue * 1.5,
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        FlSpot(0, currentValue * 0.7),
                        FlSpot(3, currentValue * 0.8),
                        FlSpot(6, currentValue * 0.9),
                        FlSpot(9, currentValue * 0.95),
                        FlSpot(12, currentValue),
                      ],
                      isCurved: true,
                      color: color,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Colors.white,
                            strokeWidth: 2,
                            strokeColor: color,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Вкладка статистики
class _StatisticsTab extends StatelessWidget {
  final ChildProfile child;

  const _StatisticsTab({required this.child});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Общая статистика
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Общая статистика',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _buildStatRow('Возраст', child.ageFormatted),
                _buildStatRow('Рост', '${child.height} см'),
                _buildStatRow('Вес', '${child.weight} кг'),
                _buildStatRow('Словарный запас', '${child.vocabularySize} слов'),
                const Divider(height: 32),
                _buildStatRow('Питомец', '${child.petName} ${child.petType}'),
                const SizedBox(height: 16),
                // Статы питомца
                ...child.petStats.entries.map((stat) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _getStatName(stat.key),
                              style: const TextStyle(fontSize: 14),
                            ),
                            Text(
                              '${stat.value}%',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: stat.value / 100,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getStatColor(stat.key),
                          ),
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Активность
        StreamBuilder<List<StoryData>>(
          stream: FirebaseService.getStoriesStream(child.id),
          builder: (context, storySnapshot) {
            final stories = storySnapshot.data ?? [];

            return StreamBuilder<List<Challenge>>(
              stream: ChallengesService.getCompletedChallengesStream(childId: child.id),
              builder: (context, challengeSnapshot) {
                final challenges = challengeSnapshot.data ?? [];

                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Активность',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildStatRow('Создано сказок', '${stories.length}'),
                        _buildStatRow('Выполнено челленджей', '${challenges.length}'),
                        _buildStatRow(
                            'Любимых сказок',
                            '${stories.where((s) => s.isFavorite).length}'
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _getStatName(String key) {
    switch (key) {
      case 'happiness':
        return 'Счастье';
      case 'energy':
        return 'Энергия';
      case 'knowledge':
        return 'Знания';
      default:
        return key;
    }
  }

  Color _getStatColor(String key) {
    switch (key) {
      case 'happiness':
        return Colors.pink;
      case 'energy':
        return Colors.orange;
      case 'knowledge':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

// Вспомогательный виджет для статистики
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}