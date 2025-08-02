// lib/screens/challenges_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../l10n/app_localizations.dart';
import '../services/firebase_service.dart';
import '../services/challenges_service.dart';


// Глобальная функция для получения цвета категории
Color getCategoryColor(String category) {
  switch (category) {
    case 'physical':
      return Colors.blue;
    case 'creative':
      return Colors.purple;
    case 'social':
      return Colors.green;
    case 'cognitive':
      return Colors.orange;
    case 'emotional':
      return Colors.pink;
    default:
      return Colors.grey;
  }
}

// Глобальная функция для получения иконки категории
IconData getCategoryIcon(String category) {
  switch (category) {
    case 'physical':
      return Icons.directions_run;
    case 'creative':
      return Icons.palette;
    case 'social':
      return Icons.people;
    case 'cognitive':
      return Icons.psychology;
    case 'emotional':
      return Icons.favorite;
    default:
      return Icons.stars;
  }
}

// Глобальная функция для получения названия категории
String getCategoryName(String category) {
  switch (category) {
    case 'physical':
      return 'Физическое';
    case 'creative':
      return 'Творческое';
    case 'social':
      return 'Социальное';
    case 'cognitive':
      return 'Познавательное';
    case 'emotional':
      return 'Эмоциональное';
    default:
      return 'Общее';
  }
}

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedChildId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadActiveChild();
  }

  Future<void> _loadActiveChild() async {
    final child = await FirebaseService.getActiveChild();
    if (child != null && mounted) {
      setState(() => _selectedChildId = child.id);
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
        title: Text(loc.challenges),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Ежедневные'),
            Tab(text: 'Недельные'),
            Tab(text: 'Выполненные'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Ежедневные челленджи
          _DailyChallengesTab(childId: _selectedChildId),
          // Недельные челленджи
          _WeeklyChallengesTab(childId: _selectedChildId),
          // История выполненных
          _CompletedChallengesTab(childId: _selectedChildId),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _generateNewChallenges(),
        tooltip: 'Сгенерировать новые челленджи',
        child: const Icon(Icons.refresh),
      ),
    );
  }

  void _generateNewChallenges() async {
    await ChallengesService.generateDailyChallenges(_selectedChildId);
    await ChallengesService.generateWeeklyChallenge(_selectedChildId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Новые челленджи созданы!')),
      );
    }
  }
}

// Вкладка ежедневных челленджей
class _DailyChallengesTab extends StatelessWidget {
  final String? childId;

  const _DailyChallengesTab({this.childId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Challenge>>(
      stream: ChallengesService.getDailyChallengesStream(childId: childId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final challenges = snapshot.data!;

        if (challenges.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.task_alt,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Нет активных челленджей',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () async {
                    await ChallengesService.generateDailyChallenges(childId);
                  },
                  child: const Text('Создать челленджи'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: challenges.length,
          itemBuilder: (context, index) {
            final challenge = challenges[index];
            return _ChallengeCard(
              challenge: challenge,
              index: index,
            );
          },
        );
      },
    );
  }
}

// Вкладка недельных челленджей
class _WeeklyChallengesTab extends StatelessWidget {
  final String? childId;

  const _WeeklyChallengesTab({this.childId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Challenge>>(
      stream: ChallengesService.getWeeklyChallengesStream(childId: childId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final challenges = snapshot.data!;

        if (challenges.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_note,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Нет недельных челленджей',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: challenges.length,
          itemBuilder: (context, index) {
            final challenge = challenges[index];
            return _WeeklyChallengeCard(
              challenge: challenge,
              index: index,
            );
          },
        );
      },
    );
  }
}

// Вкладка выполненных челленджей
class _CompletedChallengesTab extends StatelessWidget {
  final String? childId;

  const _CompletedChallengesTab({this.childId});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Статистика
        StreamBuilder<int>(
          stream: ChallengesService.getCompletedTodayStream(),
          builder: (context, snapshot) {
            final completedToday = snapshot.data ?? 0;

            return Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade400, Colors.pink.shade400],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text(
                        'Сегодня выполнено',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$completedToday',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  StreamBuilder<List<Achievement>>(
                    stream: FirebaseService.getAchievementsStream(),
                    builder: (context, snapshot) {
                      final achievements = snapshot.data ?? [];
                      final unlockedCount = achievements.where((a) => a.unlocked).length;

                      return Column(
                        children: [
                          const Text(
                            'Достижений',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$unlockedCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),

        // Список выполненных
        Expanded(
          child: StreamBuilder<List<Challenge>>(
            stream: ChallengesService.getCompletedChallengesStream(childId: childId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final challenges = snapshot.data!;

              if (challenges.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Еще нет выполненных челленджей',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: challenges.length,
                itemBuilder: (context, index) {
                  final challenge = challenges[index];
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: getCategoryColor(challenge.category).withValues(alpha: 0.2),
                        child: Icon(
                          getCategoryIcon(challenge.category),
                          color: getCategoryColor(challenge.category),
                        ),
                      ),
                      title: Text(challenge.title),
                      subtitle: Text(
                        'Выполнено ${_formatDate(challenge.completedAt!)}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.stars,
                            color: Colors.amber.shade600,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '+${challenge.xpReward}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'сегодня';
    } else if (difference.inDays == 1) {
      return 'вчера';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} дней назад';
    } else {
      return '${date.day}.${date.month.toString().padLeft(2, '0')}';
    }
  }
}

// Карточка челленджа
class _ChallengeCard extends StatelessWidget {
  final Challenge challenge;
  final int index;

  const _ChallengeCard({
    required this.challenge,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: challenge.isCompleted ? 0 : 4,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: challenge.isCompleted ? null : () => _showChallengeDetails(context, challenge),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: challenge.isCompleted ? Colors.grey.shade200 : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getCategoryColor(challenge.category).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getCategoryIcon(challenge.category),
                      color: _getCategoryColor(challenge.category),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          challenge.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            decoration: challenge.isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getCategoryName(challenge.category),
                          style: TextStyle(
                            fontSize: 12,
                            color: _getCategoryColor(challenge.category),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!challenge.isCompleted) ...[
                    Column(
                      children: [
                        Icon(
                          Icons.stars,
                          color: Colors.amber.shade600,
                          size: 20,
                        ),
                        Text(
                          '+${challenge.xpReward}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 32,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Text(
                challenge.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (!challenge.isCompleted) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _completeChallenge(context, challenge),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getCategoryColor(challenge.category),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Выполнить'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ).animate()
        .fadeIn(duration: 400.ms, delay: Duration(milliseconds: index * 100))
        .slideY(begin: 0.2, end: 0);
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'physical':
        return Colors.blue;
      case 'creative':
        return Colors.purple;
      case 'social':
        return Colors.green;
      case 'cognitive':
        return Colors.orange;
      case 'emotional':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'physical':
        return Icons.directions_run;
      case 'creative':
        return Icons.palette;
      case 'social':
        return Icons.people;
      case 'cognitive':
        return Icons.psychology;
      case 'emotional':
        return Icons.favorite;
      default:
        return Icons.stars;
    }
  }

  String _getCategoryName(String category) {
    switch (category) {
      case 'physical':
        return 'Физическое';
      case 'creative':
        return 'Творческое';
      case 'social':
        return 'Социальное';
      case 'cognitive':
        return 'Познавательное';
      case 'emotional':
        return 'Эмоциональное';
      default:
        return 'Общее';
    }
  }

  void _completeChallenge(BuildContext context, Challenge challenge) async {
    // Анимация завершения
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ChallengeCompletionDialog(
        challenge: challenge,
      ),
    );

    // Отмечаем как выполненное
    await ChallengesService.completeChallenge(challenge.id);
  }

  void _showChallengeDetails(BuildContext context, Challenge challenge) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => _ChallengeDetailsSheet(challenge: challenge),
    );
  }
}

// Карточка недельного челленджа
class _WeeklyChallengeCard extends StatelessWidget {
  final Challenge challenge;
  final int index;

  const _WeeklyChallengeCard({
    required this.challenge,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final progress = challenge.progress ?? 0;
    final target = challenge.targetCount ?? 7;
    final progressPercent = progress / target;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              _getCategoryColor(challenge.category).withValues(alpha: 0.1),
              _getCategoryColor(challenge.category).withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(challenge.category).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _getCategoryIcon(challenge.category),
                    color: _getCategoryColor(challenge.category),
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Недельный челлендж',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Icon(
                      Icons.stars,
                      color: Colors.amber.shade600,
                      size: 24,
                    ),
                    Text(
                      '+${challenge.xpReward}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              challenge.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 20),
            // Прогресс
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Прогресс',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      '$progress / $target',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progressPercent,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getCategoryColor(challenge.category),
                  ),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
            if (challenge.isCompleted) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Выполнено!',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate()
        .fadeIn(duration: 400.ms, delay: Duration(milliseconds: index * 100))
        .slideY(begin: 0.2, end: 0);
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'physical':
        return Colors.blue;
      case 'creative':
        return Colors.purple;
      case 'social':
        return Colors.green;
      case 'cognitive':
        return Colors.orange;
      case 'emotional':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'physical':
        return Icons.directions_run;
      case 'creative':
        return Icons.palette;
      case 'social':
        return Icons.people;
      case 'cognitive':
        return Icons.psychology;
      case 'emotional':
        return Icons.favorite;
      default:
        return Icons.stars;
    }
  }
}

// Диалог завершения челленджа
class _ChallengeCompletionDialog extends StatefulWidget {
  final Challenge challenge;

  const _ChallengeCompletionDialog({required this.challenge});

  @override
  State<_ChallengeCompletionDialog> createState() => _ChallengeCompletionDialogState();
}

class _ChallengeCompletionDialogState extends State<_ChallengeCompletionDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * 3.14159,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.forward();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.rotate(
                    angle: _rotateAnimation.value,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.amber.shade400, Colors.orange.shade400],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.star,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Отлично!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '+${widget.challenge.xpReward} XP',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.amber.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Детали челленджа
class _ChallengeDetailsSheet extends StatelessWidget {
  final Challenge challenge;

  const _ChallengeDetailsSheet({required this.challenge});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
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
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: getCategoryColor(challenge.category).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  getCategoryIcon(challenge.category),
                  color: getCategoryColor(challenge.category),
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      getCategoryName(challenge.category),
                      style: TextStyle(
                        fontSize: 14,
                        color: getCategoryColor(challenge.category),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            challenge.description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
          if (challenge.tips != null && challenge.tips!.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Советы',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...challenge.tips!.map((tip) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tip,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Понятно'),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}