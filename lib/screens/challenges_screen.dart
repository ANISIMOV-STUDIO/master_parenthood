// lib/screens/challenges_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../services/firebase_service.dart';
import '../services/challenges_service.dart';

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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor.withValues(alpha: 0.1),
              Theme.of(context).primaryColor.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Заголовок
              _buildHeader(context, loc),

              // Табы
              _buildTabs(context),

              // Контент
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _DailyChallengesTab(childId: _selectedChildId),
                    _WeeklyChallengesTab(childId: _selectedChildId),
                    _CompletedChallengesTab(childId: _selectedChildId),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.challenges,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                StreamBuilder<List<ChildProfile>>(
                  stream: FirebaseService.getChildrenStream(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    final children = snapshot.data!;
                    return DropdownButton<String>(
                      value: _selectedChildId ?? children.first.id,
                      underline: Container(),
                      isDense: true,
                      items: children
                          .map((child) => DropdownMenuItem(
                        value: child.id,
                        child: Text(
                          'Для ${child.name}',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ))
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedChildId = value);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          // Счетчик выполненных
          StreamBuilder<int>(
            stream: ChallengesService.getCompletedTodayStream(),
            builder: (context, snapshot) {
              final completed = snapshot.data ?? 0;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '$completed',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: [Colors.orange.shade400, Colors.red.shade400],
          ),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey,
        tabs: const [
          Tab(text: 'Ежедневные'),
          Tab(text: 'Недельные'),
          Tab(text: 'Выполненные'),
        ],
      ),
    );
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final challenges = snapshot.data ?? [];
        if (challenges.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.emoji_events,
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
                ElevatedButton(
                  onPressed: () => ChallengesService.generateDailyChallenges(childId),
                  child: const Text('Сгенерировать'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final challenges = snapshot.data ?? [];
        if (challenges.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_month,
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
          padding: const EdgeInsets.all(20),
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
    return StreamBuilder<List<Challenge>>(
      stream: ChallengesService.getCompletedChallengesStream(childId: childId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final challenges = snapshot.data ?? [];
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
                  'Вы еще не выполнили ни одного челленджа',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Начните с ежедневных заданий!',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          );
        }

        // Группировка по датам
        final groupedChallenges = <String, List<Challenge>>{};
        for (final challenge in challenges) {
          final dateKey = _formatDate(challenge.completedAt!);
          groupedChallenges[dateKey] ??= [];
          groupedChallenges[dateKey]!.add(challenge);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: groupedChallenges.length,
          itemBuilder: (context, index) {
            final date = groupedChallenges.keys.elementAt(index);
            final dateChallenges = groupedChallenges[date]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    date,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ...dateChallenges.map((challenge) => _CompletedChallengeCard(
                  challenge: challenge,
                )),
                const SizedBox(height: 20),
              ],
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) return 'Сегодня';
    if (difference == 1) return 'Вчера';
    if (difference < 7) return '$difference дней назад';

    return '${date.day}.${date.month}.${date.year}';
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
    final isCompleted = challenge.isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCompleted
              ? [Colors.green.shade100, Colors.green.shade50]
              : _getChallengeGradient(challenge.category),
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _getChallengeColor(challenge.category).withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: isCompleted
              ? null
              : () => _showChallengeDetails(context, challenge),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        _getChallengeIcon(challenge.category),
                        color: _getChallengeColor(challenge.category),
                        size: 28,
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
                                Icons.stars,
                                size: 16,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '+${challenge.xpReward} XP',
                                style: TextStyle(
                                  color: Colors.amber.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _getChallengeColor(challenge.category)
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  _getCategoryName(challenge.category),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _getChallengeColor(challenge.category),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (isCompleted)
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                        ),
                      )
                    else
                      IconButton(
                        onPressed: () => _completeChallenge(context, challenge),
                        icon: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _getChallengeColor(challenge.category),
                              width: 2,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check,
                            color: _getChallengeColor(challenge.category),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  challenge.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
                if (challenge.tips != null && challenge.tips!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 20,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            challenge.tips!.first,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.2);
  }

  List<Color> _getChallengeGradient(String category) {
    switch (category) {
      case 'physical':
        return [Colors.blue.shade100, Colors.blue.shade50];
      case 'creative':
        return [Colors.purple.shade100, Colors.purple.shade50];
      case 'social':
        return [Colors.pink.shade100, Colors.pink.shade50];
      case 'cognitive':
        return [Colors.orange.shade100, Colors.orange.shade50];
      case 'emotional':
        return [Colors.teal.shade100, Colors.teal.shade50];
      default:
        return [Colors.grey.shade100, Colors.grey.shade50];
    }
  }

  Color _getChallengeColor(String category) {
    switch (category) {
      case 'physical':
        return Colors.blue;
      case 'creative':
        return Colors.purple;
      case 'social':
        return Colors.pink;
      case 'cognitive':
        return Colors.orange;
      case 'emotional':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getChallengeIcon(String category) {
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
    final progressPercent = (progress / target).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade100, Colors.indigo.shade50],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  Icons.calendar_month,
                  color: Colors.indigo,
                  size: 28,
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
                          Icons.stars,
                          size: 16,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '+${challenge.xpReward} XP',
                          style: TextStyle(
                            color: Colors.amber.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                '$progress/$target',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
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
          const SizedBox(height: 16),
          // Прогресс бар
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Прогресс',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    '${(progressPercent * 100).toInt()}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progressPercent,
                  backgroundColor: Colors.indigo.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
                  minHeight: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Дни недели
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (index) {
              final isCompleted = index < progress;
              return Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.indigo : Colors.white,
                  border: Border.all(
                    color: Colors.indigo,
                    width: 2,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 20,
                  )
                      : Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: Colors.indigo,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.2);
  }
}

// Карточка выполненного челленджа
class _CompletedChallengeCard extends StatelessWidget {
  final Challenge challenge;

  const _CompletedChallengeCard({required this.challenge});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.green,
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
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Получено ${challenge.xpReward} XP',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatTime(challenge.completedAt!),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

// Диалог завершения челленджа
class _ChallengeCompletionDialog extends StatefulWidget {
  final Challenge challenge;

  const _ChallengeCompletionDialog({required this.challenge});

  @override
  State<_ChallengeCompletionDialog> createState() =>
      _ChallengeCompletionDialogState();
}

class _ChallengeCompletionDialogState
    extends State<_ChallengeCompletionDialog> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _starController;
  final _noteController = TextEditingController();
  int _rating = 5;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
    _starController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _starController.dispose();
    _noteController.dispose();
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
            scale: _controller.value,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Анимированная звезда
                  AnimatedBuilder(
                    animation: _starController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _starController.value * 2 * 3.14159,
                        child: Icon(
                          Icons.star,
                          size: 80,
                          color: Colors.amber,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Отлично!',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Вы выполнили челлендж',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.stars, color: Colors.amber),
                        const SizedBox(width: 8),
                        Text(
                          '+${widget.challenge.xpReward} XP',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Как прошло?',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  // Рейтинг
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        onPressed: () {
                          setState(() => _rating = index + 1);
                        },
                        icon: Icon(
                          index < _rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 36,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  // Заметка
                  TextField(
                    controller: _noteController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Добавьте заметку (необязательно)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Пропустить'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            await ChallengesService.rateChallenge(
                              widget.challenge.id,
                              _rating,
                              _noteController.text,
                            );
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Готово',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
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
          Text(
            challenge.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
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