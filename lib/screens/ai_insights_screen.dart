// lib/screens/ai_insights_screen.dart
// 🚀 Advanced AI Insights Screen with 2025 features
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/advanced_ai_service.dart';
import '../services/firebase_service.dart';
import '../providers/auth_provider.dart';
import '../l10n/app_localizations.dart';

class AIInsightsScreen extends StatefulWidget {
  const AIInsightsScreen({super.key});

  @override
  State<AIInsightsScreen> createState() => _AIInsightsScreenState();
}

class _AIInsightsScreenState extends State<AIInsightsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  Map<String, dynamic>? _behaviorAnalysis;
  Map<String, dynamic>? _predictiveInsights;
  Map<String, dynamic>? _moodAnalysis;
  Map<String, dynamic>? _personalizedActivities;

  final List<String> _chatHistory = [];
  final TextEditingController _chatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadAIInsights();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  Future<void> _loadAIInsights() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final l10n = AppLocalizations.of(context)!;

      // Get current child data
      final currentChild = authProvider.currentChild;
      if (currentChild == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Calculate age in months
      final birthDate = DateTime.parse(currentChild['birthDate']);
      final ageInMonths = DateTime.now().difference(birthDate).inDays ~/ 30;

      // Mock recent behaviors and moods for demo
      final recentBehaviors = [
        'Tantrum when tired',
        'Shares toys with siblings',
        'Asks many questions',
        'Prefers independent play'
      ];

      final moodEntries = [
        'Happy',
        'Frustrated',
        'Excited',
        'Calm',
        'Curious'
      ];

      final behaviorNotes = [
        'Very active in morning',
        'Needs routine for bedtime',
        'Enjoys creative activities'
      ];

      final interests = ['Drawing', 'Music', 'Animals', 'Puzzles'];
      final skills = ['Walking', 'Basic words', 'Color recognition'];

      // Load all AI insights in parallel
      final futures = await Future.wait([
        AdvancedAIService.analyzeBehavior(
          childName: currentChild['name'],
          ageInMonths: ageInMonths,
          recentBehaviors: recentBehaviors,
          language: l10n.localeName,
        ),
        AdvancedAIService.predictDevelopment(
          childName: currentChild['name'],
          currentMilestones: {
            'walking': true,
            'talking': true,
            'socializing': true,
          },
          ageInMonths: ageInMonths,
          language: l10n.localeName,
        ),
        AdvancedAIService.analyzeMoodAndEmotions(
          childName: currentChild['name'],
          moodEntries: moodEntries,
          behaviorNotes: behaviorNotes,
          language: l10n.localeName,
        ),
        AdvancedAIService.generatePersonalizedActivities(
          childName: currentChild['name'],
          ageInMonths: ageInMonths,
          interests: interests,
          skills: skills,
          language: l10n.localeName,
        ),
      ]);

      setState(() {
        _behaviorAnalysis = futures[0];
        _predictiveInsights = futures[1];
        _moodAnalysis = futures[2];
        _personalizedActivities = futures[3];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading AI insights: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.psychology, color: Colors.purple),
            const SizedBox(width: 8),
            Text(
              '🚀 AI Insights 2025',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                background: Paint()
                  ..shader = const LinearGradient(
                    colors: [Colors.purple, Colors.blue],
                  ).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.purple,
          labelColor: Colors.purple,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(icon: Icon(Icons.analytics), text: 'Behavior'),
            Tab(icon: Icon(Icons.trending_up), text: 'Predictions'),
            Tab(icon: Icon(Icons.mood), text: 'Emotions'),
            Tab(icon: Icon(Icons.extension), text: 'Activities'),
            Tab(icon: Icon(Icons.chat), text: 'AI Chat'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('🤖 AI is analyzing your child\'s development...'),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBehaviorAnalysisTab(),
                _buildPredictiveInsightsTab(),
                _buildMoodAnalysisTab(),
                _buildPersonalizedActivitiesTab(),
                _buildAIChatTab(),
              ],
            ),
    );
  }

  Widget _buildBehaviorAnalysisTab() {
    if (_behaviorAnalysis == null) {
      return const Center(child: Text('No behavior analysis available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInsightCard(
            title: '🎯 Behavior Analysis',
            icon: Icons.psychology,
            color: Colors.blue,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _behaviorAnalysis!['analysis'] ?? '',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                if (_behaviorAnalysis!['triggers'] != null) ...[
                  const Text(
                    'Common Triggers:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...(_behaviorAnalysis!['triggers'] as List).map(
                    (trigger) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber, size: 16, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(child: Text(trigger)),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildInsightCard(
            title: '💡 Strategies',
            icon: Icons.lightbulb,
            color: Colors.green,
            child: Column(
              children: (_behaviorAnalysis!['strategies'] as List? ?? []).map(
                (strategy) => ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: Text(strategy),
                  dense: true,
                ),
              ).toList(),
            ),
          ),
          const SizedBox(height: 16),
          if (_behaviorAnalysis!['positivePatterns'] != null)
            _buildInsightCard(
              title: '⭐ Positive Patterns',
              icon: Icons.star,
              color: Colors.amber,
              child: Column(
                children: (_behaviorAnalysis!['positivePatterns'] as List).map(
                  (pattern) => ListTile(
                    leading: const Icon(Icons.star, color: Colors.amber),
                    title: Text(pattern),
                    dense: true,
                  ),
                ).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPredictiveInsightsTab() {
    if (_predictiveInsights == null) {
      return const Center(child: Text('No predictive insights available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInsightCard(
            title: '🔮 Next Milestones',
            icon: Icons.flag,
            color: Colors.purple,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Expected timeframe: ${_predictiveInsights!['timeframe'] ?? 'Unknown'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...(_predictiveInsights!['nextMilestones'] as List? ?? []).map(
                  (milestone) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.flag, size: 16, color: Colors.purple),
                        const SizedBox(width: 8),
                        Expanded(child: Text(milestone)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildInsightCard(
            title: '📈 Recommendations',
            icon: Icons.recommend,
            color: Colors.teal,
            child: Column(
              children: (_predictiveInsights!['recommendations'] as List? ?? []).map(
                (rec) => ListTile(
                  leading: const Icon(Icons.recommend, color: Colors.teal),
                  title: Text(rec),
                  dense: true,
                ),
              ).toList(),
            ),
          ),
          const SizedBox(height: 16),
          _buildInsightCard(
            title: '👀 Watch For',
            icon: Icons.visibility,
            color: Colors.orange,
            child: Column(
              children: (_predictiveInsights!['watchFor'] as List? ?? []).map(
                (item) => ListTile(
                  leading: const Icon(Icons.visibility, color: Colors.orange),
                  title: Text(item),
                  dense: true,
                ),
              ).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodAnalysisTab() {
    if (_moodAnalysis == null) {
      return const Center(child: Text('No mood analysis available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInsightCard(
            title: '😊 Mood Pattern',
            icon: Icons.mood,
            color: Colors.pink,
            child: Text(
              _moodAnalysis!['moodPattern'] ?? '',
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 16),
          _buildInsightCard(
            title: '🧠 Emotional Development',
            icon: Icons.psychology,
            color: Colors.indigo,
            child: Text(
              _moodAnalysis!['emotionalDevelopment'] ?? '',
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 16),
          if (_moodAnalysis!['strategies'] != null)
            _buildInsightCard(
              title: '🛠️ Emotional Strategies',
              icon: Icons.build,
              color: Colors.brown,
              child: Column(
                children: (_moodAnalysis!['strategies'] as List).map(
                  (strategy) => ListTile(
                    leading: const Icon(Icons.build, color: Colors.brown),
                    title: Text(strategy),
                    dense: true,
                  ),
                ).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPersonalizedActivitiesTab() {
    if (_personalizedActivities == null) {
      return const Center(child: Text('No activities available'));
    }

    final activities = _personalizedActivities!['activities'] as List? ?? [];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: Colors.primaries[index % Colors.primaries.length],
              child: Text('${index + 1}'),
            ),
            title: Text(
              activity['name'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(activity['duration'] ?? ''),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity['description'] ?? '',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    if (activity['materials'] != null) ...[
                      const Text(
                        'Materials needed:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      ...((activity['materials'] as List?) ?? []).map(
                        (material) => Padding(
                          padding: const EdgeInsets.only(left: 16, bottom: 2),
                          child: Text('• $material'),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    if (activity['skills'] != null) ...[
                      const Text(
                        'Skills developed:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        children: ((activity['skills'] as List?) ?? []).map(
                          (skill) => Chip(
                            label: Text(skill),
                            backgroundColor: Colors.blue.shade100,
                          ),
                        ).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAIChatTab() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _chatHistory.length,
            itemBuilder: (context, index) {
              final isUser = index % 2 == 0;
              return Align(
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser ? Colors.blue : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _chatHistory[index],
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade300,
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  decoration: const InputDecoration(
                    hintText: 'Ask AI about your child...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _sendChatMessage,
                icon: const Icon(Icons.send),
                color: Colors.purple,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _sendChatMessage() async {
    final message = _chatController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _chatHistory.add(message);
      _chatController.clear();
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentChild = authProvider.currentChild;
      final l10n = AppLocalizations.of(context)!;

      final response = await AdvancedAIService.chatWithAI(
        message: message,
        conversationHistory: [],
        childContext: currentChild ?? {},
        language: l10n.localeName,
      );

      setState(() {
        _chatHistory.add(response);
      });
    } catch (e) {
      setState(() {
        _chatHistory.add('Sorry, I couldn\'t process your message. Please try again.');
      });
    }
  }

  Widget _buildInsightCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
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
            child,
          ],
        ),
      ),
    );
  }
}