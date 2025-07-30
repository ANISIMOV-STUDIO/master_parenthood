// lib/screens/topic_of_day_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../l10n/app_localizations.dart';
import '../services/firebase_service.dart';
import '../services/topic_service.dart';
import '../services/ai_service.dart';

class TopicOfDayScreen extends StatefulWidget {
  const TopicOfDayScreen({super.key});

  @override
  State<TopicOfDayScreen> createState() => _TopicOfDayScreenState();
}

class _TopicOfDayScreenState extends State<TopicOfDayScreen> {
  DailyTopic? _todayTopic;
  bool _isLoading = true;
  bool _isGeneratingActivity = false;
  List<String> _generatedActivities = [];
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTodayTopic();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadTodayTopic() async {
    setState(() => _isLoading = true);

    try {
      final topic = await TopicService.getTodayTopic();
      setState(() {
        _todayTopic = topic;
        _isLoading = false;
      });

      // Генерируем тему если её нет
      if (topic == null) {
        await TopicService.generateTodayTopic();
        final newTopic = await TopicService.getTodayTopic();
        setState(() {
          _todayTopic = newTopic;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки: $e')),
        );
      }
    }
  }

  Future<void> _generateActivity() async {
    if (_todayTopic == null) return;

    setState(() => _isGeneratingActivity = true);

    try {
      final activeChild = await FirebaseService.getActiveChild();
      final childAge = activeChild?.ageFormattedShort ?? '2-3 года';

      // Генерируем активность через AI
      final activity = await AIService.generateTopicActivity(
        topic: _todayTopic!.title,
        ageGroup: childAge,
        language: Localizations.localeOf(context).languageCode,
      );

      setState(() {
        _generatedActivities.add(activity);
        _isGeneratingActivity = false;
      });

      // Сохраняем активность
      await TopicService.saveGeneratedActivity(
        topicId: _todayTopic!.id,
        activity: activity,
      );

      // Добавляем XP
      await FirebaseService.addXP(30);
    } catch (e) {
      setState(() => _isGeneratingActivity = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка генерации: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.pink.shade50,
              Colors.purple.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _todayTopic == null
              ? _buildEmptyState(context, loc)
              : _buildContent(context, loc),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations loc) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Тема дня еще не готова',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadTodayTopic,
            child: const Text('Обновить'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, AppLocalizations loc) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Заголовок
          _buildHeader(context, loc),

          // Карточка темы дня
          _buildTopicCard(context),

          // Секции
          _buildWhyImportantSection(context),
          _buildHowToDiscussSection(context),
          _buildActivitiesSection(context),
          _buildGeneratedActivitiesSection(context),
          _buildCommunitySection(context),

          const SizedBox(height: 100),
        ],
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
                  loc.topicOfDay,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _formatDate(DateTime.now()),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareTopic(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getTopicColor(_todayTopic!.category),
            _getTopicColor(_todayTopic!.category).withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: _getTopicColor(_todayTopic!.category).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            _getTopicIcon(_todayTopic!.category),
            size: 60,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          Text(
            _todayTopic!.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getCategoryName(_todayTopic!.category),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildWhyImportantSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Почему это важно?',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _todayTopic!.whyImportant,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1);
  }

  Widget _buildHowToDiscussSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Как обсудить с ребенком?',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._todayTopic!.discussionPoints.asMap().entries.map((entry) {
            final index = entry.key;
            final point = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      point,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.4,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: (300 + index * 100).ms).slideX(begin: -0.1);
          }),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.1);
  }

  Widget _buildActivitiesSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.shade50,
            Colors.teal.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.green.shade200,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.extension,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Активности по возрастам',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ..._todayTopic!.activities.entries.map((entry) {
            final ageGroup = entry.key;
            final activities = entry.value;
            return _buildAgeGroupActivities(context, ageGroup, activities);
          }),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildAgeGroupActivities(
      BuildContext context,
      String ageGroup,
      List<String> activities,
      ) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _getAgeGroupName(ageGroup),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ),
        children: activities.map((activity) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.play_circle_outline,
                  color: Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    activity,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGeneratedActivitiesSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Кнопка генерации
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.purple, Colors.pink],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _isGeneratingActivity ? null : _generateActivity,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isGeneratingActivity)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      else
                        const Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                        ),
                      const SizedBox(width: 12),
                      Text(
                        _isGeneratingActivity
                            ? 'Генерирую идею...'
                            : 'Сгенерировать идею с AI',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Сгенерированные активности
          if (_generatedActivities.isNotEmpty) ...[
            const SizedBox(height: 20),
            ..._generatedActivities.asMap().entries.map((entry) {
              final index = entry.key;
              final activity = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.purple.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            color: Colors.purple,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'AI идея',
                          style: TextStyle(
                            color: Colors.purple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.share, size: 20),
                          onPressed: () => Share.share(activity),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      activity,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.4,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.1);
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildCommunitySection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.forum,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Обсуждение сообщества',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Статистика
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.people,
                value: _todayTopic!.participantsCount.toString(),
                label: 'Участников',
                color: Colors.blue,
              ),
              _buildStatItem(
                icon: Icons.comment,
                value: _todayTopic!.commentsCount.toString(),
                label: 'Комментариев',
                color: Colors.green,
              ),
              _buildStatItem(
                icon: Icons.favorite,
                value: _todayTopic!.likesCount.toString(),
                label: 'Лайков',
                color: Colors.red,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Форма комментария
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: 'Поделитесь вашим опытом...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                backgroundColor: Colors.orange,
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: () => _addComment(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Последние комментарии
          StreamBuilder<List<TopicComment>>(
            stream: TopicService.getCommentsStream(_todayTopic!.id),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Будьте первым, кто поделится опытом!',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                );
              }

              final comments = snapshot.data!;
              return Column(
                children: comments.take(3).map((comment) {
                  return _buildCommentItem(context, comment);
                }).toList(),
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1);
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildCommentItem(BuildContext context, TopicComment comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: comment.userPhotoUrl != null
                    ? NetworkImage(comment.userPhotoUrl!)
                    : null,
                child: comment.userPhotoUrl == null
                    ? Text(comment.userName[0].toUpperCase())
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _formatCommentTime(comment.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (comment.userId == FirebaseService.currentUserId)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: () => _deleteComment(comment.id),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comment.text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  void _shareTopic() {
    if (_todayTopic == null) return;

    final text = '''
🌟 Тема дня: ${_todayTopic!.title}

${_todayTopic!.whyImportant}

Обсудите эту тему с вашим ребенком!

#MasterParenthood #РазвитиеДетей
''';

    Share.share(text);
  }

  void _addComment() async {
    if (_commentController.text.trim().isEmpty || _todayTopic == null) return;

    try {
      await TopicService.addComment(
        topicId: _todayTopic!.id,
        text: _commentController.text.trim(),
      );

      _commentController.clear();

      // Скрываем клавиатуру
      FocusScope.of(context).unfocus();

      // Добавляем XP
      await FirebaseService.addXP(10);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка отправки: $e')),
      );
    }
  }

  void _deleteComment(String commentId) async {
    try {
      await TopicService.deleteComment(commentId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка удаления: $e')),
      );
    }
  }

  Color _getTopicColor(String category) {
    switch (category) {
      case 'emotional':
        return Colors.pink;
      case 'social':
        return Colors.blue;
      case 'cognitive':
        return Colors.orange;
      case 'physical':
        return Colors.green;
      case 'creative':
        return Colors.purple;
      default:
        return Colors.teal;
    }
  }

  IconData _getTopicIcon(String category) {
    switch (category) {
      case 'emotional':
        return Icons.favorite;
      case 'social':
        return Icons.people;
      case 'cognitive':
        return Icons.psychology;
      case 'physical':
        return Icons.directions_run;
      case 'creative':
        return Icons.palette;
      default:
        return Icons.lightbulb;
    }
  }

  String _getCategoryName(String category) {
    switch (category) {
      case 'emotional':
        return 'Эмоциональное развитие';
      case 'social':
        return 'Социальные навыки';
      case 'cognitive':
        return 'Познавательное развитие';
      case 'physical':
        return 'Физическое развитие';
      case 'creative':
        return 'Творчество';
      default:
        return 'Общее развитие';
    }
  }

  String _getAgeGroupName(String ageGroup) {
    switch (ageGroup) {
      case '0-1':
        return '0-1 год';
      case '1-2':
        return '1-2 года';
      case '2-3':
        return '2-3 года';
      case '3-5':
        return '3-5 лет';
      case '5-7':
        return '5-7 лет';
      default:
        return ageGroup;
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatCommentTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'только что';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} мин назад';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ч назад';
    } else {
      return '${difference.inDays} дн назад';
    }
  }
}