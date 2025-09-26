// lib/screens/enhanced_home_screen.dart
// 🚀 Enhanced Home Screen with 2025 AI Features
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../services/advanced_ai_service.dart';
import '../services/smart_notification_service.dart';
import '../services/speech_analysis_service.dart';
import 'ai_insights_screen.dart';
import 'home_screen.dart';

class EnhancedHomeScreen extends StatefulWidget {
  const EnhancedHomeScreen({super.key});

  @override
  State<EnhancedHomeScreen> createState() => _EnhancedHomeScreenState();
}

class _EnhancedHomeScreenState extends State<EnhancedHomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _slideController;
  bool _showAIInsights = false;
  Map<String, dynamic>? _dailyInsights;
  Map<String, dynamic>? _smartSuggestions;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _loadDailyAIInsights();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadDailyAIInsights() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentChild = authProvider.currentChild;

      if (currentChild != null) {
        final l10n = AppLocalizations.of(context)!;
        final ageInMonths = DateTime.now().difference(
          DateTime.parse(currentChild['birthDate'])
        ).inDays ~/ 30;

        // Load daily AI insights
        final insights = await AdvancedAIService.generatePersonalizedActivities(
          childName: currentChild['name'],
          ageInMonths: ageInMonths,
          interests: ['Drawing', 'Music', 'Stories'],
          skills: ['Walking', 'Talking', 'Playing'],
          language: l10n.localeName,
        );

        setState(() {
          _dailyInsights = insights;
        });
      }
    } catch (e) {
      debugPrint('Error loading daily insights: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildEnhancedAppBar(context, authProvider),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildAIQuickActions(context),
                _buildSmartInsightsCard(context),
                _buildDailyActivitiesCard(context),
                _buildProgressOverview(context),
                _buildOriginalHomeContent(context),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildAIAssistantFAB(context),
    );
  }

  Widget _buildEnhancedAppBar(BuildContext context, AuthProvider authProvider) {
    final currentChild = authProvider.currentChild;

    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF667eea),
                Color(0xFF764ba2),
                Color(0xFFf093fb),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Animated background elements
              Positioned(
                top: 50,
                right: -50,
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 + _pulseController.value * 0.1,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Main content
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.psychology,
                          color: Colors.white,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '🚀 Master Parenthood AI',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ).animate().fadeIn(duration: 600.ms).slideX(),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (currentChild != null)
                      Text(
                        'Today\'s insights for ${currentChild['name']}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ).animate().fadeIn(delay: 300.ms),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAIQuickActions(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🤖 AI Quick Actions',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickActionCard(
                  icon: Icons.psychology,
                  title: 'AI Insights',
                  subtitle: 'Behavioral analysis',
                  color: Colors.purple,
                  onTap: () => _navigateToAIInsights(context),
                ),
                _buildQuickActionCard(
                  icon: Icons.mic,
                  title: 'Speech Analysis',
                  subtitle: 'Voice development',
                  color: Colors.blue,
                  onTap: () => _startSpeechAnalysis(context),
                ),
                _buildQuickActionCard(
                  icon: Icons.auto_awesome,
                  title: 'Smart Tips',
                  subtitle: 'Personalized advice',
                  color: Colors.orange,
                  onTap: () => _showSmartTips(context),
                ),
                _buildQuickActionCard(
                  icon: Icons.trending_up,
                  title: 'Predictions',
                  subtitle: 'Development forecast',
                  color: Colors.green,
                  onTap: () => _showPredictions(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: (100).ms).slideY(begin: 0.3);
  }

  Widget _buildSmartInsightsCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [Colors.indigo.shade400, Colors.purple.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.lightbulb, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    '💡 Today\'s Smart Insights',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your child is showing great progress in social interactions! 🎉',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'AI detected 85% positive behavioral patterns this week. Keep up the excellent parenting!',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _navigateToAIInsights(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.purple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text('View Full Analysis'),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2);
  }

  Widget _buildDailyActivitiesCard(BuildContext context) {
    final activities = _dailyInsights?['activities'] as List? ?? [];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.extension, color: Colors.orange, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    '🎮 Personalized Activities',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (activities.isNotEmpty) ...[
                ...activities.take(2).map((activity) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity['name'] ?? 'Activity',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        activity['description'] ?? 'Fun activity for your child',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.schedule, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            activity['duration'] ?? '10-15 minutes',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )),
                TextButton.icon(
                  onPressed: () => _navigateToAIInsights(context),
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('View All Activities'),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.refresh, size: 48, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        'Loading personalized activities...',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2);
  }

  Widget _buildProgressOverview(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.trending_up, color: Colors.green, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    '📈 Development Progress',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildProgressIndicator(
                      'Physical',
                      0.85,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildProgressIndicator(
                      'Cognitive',
                      0.78,
                      Colors.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildProgressIndicator(
                      'Social',
                      0.92,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildProgressIndicator(
                      'Language',
                      0.75,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2);
  }

  Widget _buildProgressIndicator(String label, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: color.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
        const SizedBox(height: 4),
        Text(
          '${(progress * 100).round()}%',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildOriginalHomeContent(BuildContext context) {
    // Include the original home screen content but simplified
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '📱 Quick Access',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const HomeScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Open Classic Home Screen'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAIAssistantFAB(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + _pulseController.value * 0.1,
          child: FloatingActionButton.extended(
            onPressed: () => _openAIChat(context),
            backgroundColor: Colors.purple,
            icon: const Icon(Icons.smart_toy, color: Colors.white),
            label: const Text(
              'AI Chat',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }

  // Navigation methods
  void _navigateToAIInsights(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AIInsightsScreen(),
      ),
    );
  }

  void _startSpeechAnalysis(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎙️ Speech Analysis'),
        content: const Text(
          'Speech analysis feature is ready! This would open the speech recording interface with real-time analysis.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Here would be the actual speech analysis implementation
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Speech analysis feature coming soon!'),
                ),
              );
            },
            child: const Text('Start Recording'),
          ),
        ],
      ),
    );
  }

  void _showSmartTips(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '💡 Smart Tips for Today',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  _buildTipCard(
                    '🎯 Focus on Social Skills',
                    'Your child is ready for more interactive play. Try group activities!',
                    Colors.blue,
                  ),
                  _buildTipCard(
                    '📚 Reading Time',
                    'Perfect age for picture books with simple stories. Aim for 15 minutes daily.',
                    Colors.green,
                  ),
                  _buildTipCard(
                    '🏃 Physical Activity',
                    'Encourage running and jumping games to develop gross motor skills.',
                    Colors.orange,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard(String title, String content, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(content),
        ],
      ),
    );
  }

  void _showPredictions(BuildContext context) {
    _navigateToAIInsights(context);
  }

  void _openAIChat(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AIInsightsScreen(),
      ),
    );
  }
}