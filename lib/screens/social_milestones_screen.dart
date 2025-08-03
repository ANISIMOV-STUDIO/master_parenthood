import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firebase_service.dart';

class SocialMilestonesScreen extends StatefulWidget {
  final String? childId;

  const SocialMilestonesScreen({super.key, this.childId});

  @override
  State<SocialMilestonesScreen> createState() => _SocialMilestonesScreenState();
}

class _SocialMilestonesScreenState extends State<SocialMilestonesScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  SocialDevelopmentProgress? _latestAnalysis;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadLatestAnalysis();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLatestAnalysis() async {
    if (widget.childId == null) return;

    try {
      final firebaseService = Provider.of<FirebaseService>(context, listen: false);
      final analyses = await firebaseService
          .getSocialDevelopmentAnalysesStream(widget.childId!)
          .first;
      
      if (analyses.isNotEmpty) {
        setState(() {
          _latestAnalysis = analyses.first;
          _isLoading = false;
        });
      } else {
        // Генерируем новый анализ если его нет
        final analysis = await firebaseService
            .generateSocialDevelopmentAnalysis(widget.childId!);
        setState(() {
          _latestAnalysis = analysis;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.childId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Социальные вехи'),
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.child_care, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Выберите ребенка',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                'Для использования этого модуля необходимо\nвыбрать профиль ребенка',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('👥 Социальные вехи'),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.purple,
                      Colors.deepPurple,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),
                        if (!_isLoading && _latestAnalysis != null) ...[
                          Text(
                            'Прогресс: ${_latestAnalysis!.progressPercentage.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: _latestAnalysis!.progressPercentage / 100,
                            backgroundColor: Colors.white.withValues(alpha: 0.3),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
              tabs: const [
                Tab(text: 'Вехи'),
                Tab(text: 'Наблюдения'),
                Tab(text: 'Анализ'),
                Tab(text: 'Прогресс'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildMilestonesTab(),
            _buildObservationsTab(),
            _buildAnalysisTab(),
            _buildProgressTab(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMilestoneDialog,
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildMilestonesTab() {
    return Consumer<FirebaseService>(
      builder: (context, firebaseService, child) {
        return StreamBuilder<List<SocialMilestone>>(
          stream: firebaseService.getSocialMilestonesStream(widget.childId!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.timeline, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'Нет социальных вех',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => _createStandardMilestones(),
                      child: const Text('Создать стандартные вехи'),
                    ),
                  ],
                ),
              );
            }

            final milestones = snapshot.data!;

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: milestones.length,
              itemBuilder: (context, index) {
                final milestone = milestones[index];
                return _buildMilestoneCard(milestone);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildMilestoneCard(SocialMilestone milestone) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showMilestoneDetails(milestone),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(milestone.levelColorHex),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      milestone.areaEmoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          milestone.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          milestone.areaDisplayName,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Color(milestone.levelColorHex).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          milestone.levelText,
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(milestone.levelColorHex),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        milestone.typicalAgeText,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                milestone.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              if (milestone.isDelayed) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning, size: 16, color: Colors.orange),
                      SizedBox(width: 4),
                      Text(
                        'Требует внимания',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
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
    );
  }

  Widget _buildObservationsTab() {
    return Consumer<FirebaseService>(
      builder: (context, firebaseService, child) {
        return StreamBuilder<List<BehaviorObservation>>(
          stream: firebaseService.getChildBehaviorObservationsStream(widget.childId!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.visibility, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Нет наблюдений',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Добавьте наблюдения за поведением ребенка',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            final observations = snapshot.data!;

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: observations.length,
              itemBuilder: (context, index) {
                final observation = observations[index];
                return _buildObservationCard(observation);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildObservationCard(BehaviorObservation observation) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.visibility,
                  color: Color(observation.observedLevel.index == 0 ? 0xFF9E9E9E :
                    observation.observedLevel.index == 1 ? 0xFFFF9800 :
                    observation.observedLevel.index == 2 ? 0xFF2196F3 :
                    observation.observedLevel.index == 3 ? 0xFF4CAF50 : 0xFF8BC34A),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    observation.behavior,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  observation.formattedDate,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Контекст: ${observation.context}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            if (observation.observerNotes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Заметки: ${observation.observerNotes}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ],
            if (observation.triggers.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children: observation.triggers.map((trigger) {
                  return Chip(
                    label: Text(trigger),
                    backgroundColor: Colors.red.withValues(alpha: 0.1),
                    labelStyle: const TextStyle(fontSize: 12),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_latestAnalysis == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.analytics, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Нет данных для анализа',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _generateAnalysis,
              child: const Text('Сгенерировать анализ'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAnalysisSection(
            'Общий прогресс',
            Icons.timeline,
            [
              _buildProgressItem(
                'Социальное развитие',
                _latestAnalysis!.overallSocialScore,
                Colors.blue,
              ),
              _buildProgressItem(
                'Эмоциональное развитие',
                _latestAnalysis!.overallEmotionalScore,
                Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildAnalysisSection(
            'Сильные стороны',
            Icons.star,
            _latestAnalysis!.strengths.map((strength) {
              return ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: Text(strength),
                contentPadding: EdgeInsets.zero,
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          _buildAnalysisSection(
            'Области для развития',
            Icons.trending_up,
            _latestAnalysis!.areasForDevelopment.map((area) {
              return ListTile(
                leading: const Icon(Icons.build, color: Colors.orange),
                title: Text(area),
                contentPadding: EdgeInsets.zero,
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          _buildAnalysisSection(
            'Рекомендации',
            Icons.lightbulb,
            _latestAnalysis!.recommendations.map((recommendation) {
              return ListTile(
                leading: const Icon(Icons.tips_and_updates, color: Colors.amber),
                title: Text(recommendation),
                contentPadding: EdgeInsets.zero,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisSection(String title, IconData icon, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.purple),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildProgressItem(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text('${value.toStringAsFixed(1)}%'),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: value / 100,
            backgroundColor: color.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressTab() {
    return Consumer<FirebaseService>(
      builder: (context, firebaseService, child) {
        return StreamBuilder<List<SocialDevelopmentProgress>>(
          stream: firebaseService.getSocialDevelopmentAnalysesStream(widget.childId!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.show_chart, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Нет данных о прогрессе',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            final progressData = snapshot.data!;

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: progressData.length,
              itemBuilder: (context, index) {
                final progress = progressData[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Анализ от ${progress.formattedDate}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${progress.progressPercentage.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: progress.progressPercentage / 100,
                          backgroundColor: Colors.grey.withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.purple),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildStatItem(
                              'Достигнуто',
                              progress.achievedMilestones.toString(),
                              Colors.green,
                            ),
                            const SizedBox(width: 16),
                            _buildStatItem(
                              'Всего',
                              progress.totalMilestones.toString(),
                              Colors.blue,
                            ),
                            const SizedBox(width: 16),
                            _buildStatItem(
                              'Задержано',
                              progress.delayedMilestones.toString(),
                              Colors.orange,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  void _showMilestoneDetails(SocialMilestone milestone) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color(milestone.levelColorHex),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        milestone.areaEmoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            milestone.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            milestone.areaDisplayName,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailSection('Описание', milestone.description),
                        _buildDetailSection('Типичный возраст', milestone.typicalAgeText),
                        _buildDetailSection('Допустимый диапазон', milestone.ageRangeText),
                        _buildDetailSection('Текущий уровень', milestone.levelText),
                        if (milestone.supportingActivities.isNotEmpty)
                          _buildDetailSection(
                            'Поддерживающие активности',
                            milestone.supportingActivities.join('\n• '),
                          ),
                        if (milestone.observationNotes.isNotEmpty)
                          _buildDetailSection(
                            'Заметки наблюдений',
                            milestone.observationNotes.join('\n• '),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _updateMilestoneLevel(milestone),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Обновить уровень'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _addObservation(milestone),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Добавить наблюдение'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Future<void> _createStandardMilestones() async {
    try {
      final firebaseService = Provider.of<FirebaseService>(context, listen: false);
      await firebaseService.createStandardSocialMilestones(widget.childId!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Стандартные социальные вехи созданы'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _generateAnalysis() async {
    try {
      final firebaseService = Provider.of<FirebaseService>(context, listen: false);
      final analysis = await firebaseService
          .generateSocialDevelopmentAnalysis(widget.childId!);
      
      setState(() {
        _latestAnalysis = analysis;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Анализ сгенерирован'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddMilestoneDialog() {
    // TODO: Реализовать диалог добавления вехи
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Функция добавления вехи будет реализована'),
      ),
    );
  }

  void _updateMilestoneLevel(SocialMilestone milestone) {
    // TODO: Реализовать обновление уровня вехи
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Функция обновления уровня будет реализована'),
      ),
    );
  }

  void _addObservation(SocialMilestone milestone) {
    // TODO: Реализовать добавление наблюдения
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Функция добавления наблюдения будет реализована'),
      ),
    );
  }
}