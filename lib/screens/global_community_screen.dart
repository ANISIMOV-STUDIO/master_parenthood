// lib/screens/global_community_screen.dart
// 🌍 Global Community Screen with Real-time Translation
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../services/global_community_service.dart';
import '../services/translation_service.dart';

class GlobalCommunityScreen extends StatefulWidget {
  const GlobalCommunityScreen({super.key});

  @override
  State<GlobalCommunityScreen> createState() => _GlobalCommunityScreenState();
}

class _GlobalCommunityScreenState extends State<GlobalCommunityScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _postController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Map<String, dynamic>? _currentWeeklyTopic;
  List<Map<String, dynamic>> _communityPosts = [];
  Map<String, dynamic>? _communityStats;
  String _selectedLanguage = 'auto';
  bool _isLoading = false;
  bool _showTranslation = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadCommunityData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _postController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCommunityData() async {
    setState(() => _isLoading = true);

    try {
      final l10n = AppLocalizations.of(context)!;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Load weekly topic
      final weeklyTopic = await GlobalCommunityService.generateWeeklyTopic(
        language: l10n.localeName,
      );

      // Load community posts
      final posts = await GlobalCommunityService.getCommunityPosts(
        userLanguage: l10n.localeName,
        userId: authProvider.currentUser?['uid'] ?? 'anonymous',
      );

      // Load community stats
      final stats = await GlobalCommunityService.getCommunityStats();

      setState(() {
        _currentWeeklyTopic = weeklyTopic;
        _communityPosts = posts;
        _communityStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading community data: $e');
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
            const Icon(Icons.public, color: Colors.blue),
            const SizedBox(width: 8),
            const Text(
              '🌍 Global Community',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showTranslation ? Icons.translate : Icons.translate_outlined),
            onPressed: () {
              setState(() {
                _showTranslation = !_showTranslation;
              });
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.language),
            onSelected: (String language) {
              setState(() {
                _selectedLanguage = language;
              });
              _loadCommunityData();
            },
            itemBuilder: (context) {
              final languages = TranslationService.getSupportedLanguages();
              return [
                const PopupMenuItem(
                  value: 'auto',
                  child: Text('🌐 Auto-detect'),
                ),
                ...languages.entries.map((entry) => PopupMenuItem(
                  value: entry.key,
                  child: Text('${entry.value['flag']} ${entry.value['nativeName']}'),
                )),
              ];
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blue,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.topic), text: 'Weekly Topic'),
            Tab(icon: Icon(Icons.forum), text: 'Community'),
            Tab(icon: Icon(Icons.add_circle), text: 'Create Post'),
            Tab(icon: Icon(Icons.analytics), text: 'Stats'),
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
                  Text('🌍 Loading global community...'),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildWeeklyTopicTab(),
                _buildCommunityTab(),
                _buildCreatePostTab(),
                _buildStatsTab(),
              ],
            ),
    );
  }

  Widget _buildWeeklyTopicTab() {
    if (_currentWeeklyTopic == null) {
      return const Center(child: Text('No weekly topic available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWeeklyTopicCard(_currentWeeklyTopic!),
          const SizedBox(height: 20),
          _buildTopicActivitiesCard(_currentWeeklyTopic!),
          const SizedBox(height: 20),
          _buildTopicDiscussionPreview(),
        ],
      ),
    );
  }

  Widget _buildWeeklyTopicCard(Map<String, dynamic> topic) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Week ${topic['week']} • ${topic['language']?.toUpperCase()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            topic['title'] ?? 'Weekly Topic',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            topic['description'] ?? 'Join the global conversation!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          if (topic['culturalNote'] != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      topic['culturalNote'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3);
  }

  Widget _buildTopicActivitiesCard(Map<String, dynamic> topic) {
    final activities = topic['activities'] as List<dynamic>? ?? [];
    final questions = topic['questions'] as List<dynamic>? ?? [];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.assignment, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  '🎯 This Week\'s Activities',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...activities.asMap().entries.map((entry) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: Colors.orange,
                    child: Text(
                      '${entry.key + 1}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.value.toString(),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 20),
            const Row(
              children: [
                Icon(Icons.help_outline, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  '❓ Discussion Questions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...questions.asMap().entries.map((entry) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple.withOpacity(0.3)),
              ),
              child: Text(
                entry.value.toString(),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            )),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildTopicDiscussionPreview() {
    final topicPosts = _communityPosts
        .where((post) => post['topicId'] == _currentWeeklyTopic?['id'])
        .take(3)
        .toList();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.chat_bubble, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      '💬 Recent Discussions',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => _tabController.animateTo(1),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (topicPosts.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(Icons.chat, size: 48, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        'Be the first to start a discussion!',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              ...topicPosts.map((post) => _buildMiniPostCard(post)),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(delay: 600.ms);
  }

  Widget _buildMiniPostCard(Map<String, dynamic> post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.blue,
                child: Text(
                  post['userName']?.toString().substring(0, 1).toUpperCase() ?? 'U',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post['userName'] ?? 'Anonymous',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    Text(
                      '${post['timeAgo']} • ${_getLanguageFlag(post['originalLanguage'])}',
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ],
                ),
              ),
              if (post['isTranslated'] == true && _showTranslation)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'T',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            post['displayContent'] ?? post['content'] ?? '',
            style: const TextStyle(fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityTab() {
    return Column(
      children: [
        // Language selector and filters
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.translate, size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        _showTranslation ? 'Auto-translate ON' : 'Original languages',
                        style: const TextStyle(color: Colors.blue, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadCommunityData,
              ),
            ],
          ),
        ),
        // Posts list
        Expanded(
          child: _communityPosts.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.forum, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No posts yet. Be the first to share!',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _communityPosts.length,
                  itemBuilder: (context, index) {
                    return _buildCommunityPostCard(_communityPosts[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCommunityPostCard(Map<String, dynamic> post) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info and language
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.blue,
                  child: Text(
                    post['userName']?.toString().substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            post['userName'] ?? 'Anonymous',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _getLanguageFlag(post['originalLanguage']),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      Text(
                        post['timeAgo'] ?? '',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (post['isTranslated'] == true && _showTranslation)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Translated',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Post content
            Text(
              post['displayContent'] ?? post['content'] ?? '',
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            if (post['isTranslated'] == true && _showTranslation) ...[
              const SizedBox(height: 12),
              ExpansionTile(
                title: const Text(
                  'View original',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      post['originalContent'] ?? '',
                      style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            // Actions
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _likePost(post['id']),
                  icon: const Icon(Icons.favorite_border, size: 18),
                  label: Text('${post['likes'] ?? 0}'),
                ),
                const SizedBox(width: 16),
                TextButton.icon(
                  onPressed: () => _replyToPost(post),
                  icon: const Icon(Icons.reply, size: 18),
                  label: Text('${post['replies'] ?? 0}'),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.share, size: 18),
                  onPressed: () => _sharePost(post),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (100).ms).slideY(begin: 0.1);
  }

  Widget _buildCreatePostTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.create, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        '✍️ Share with Global Community',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _postController,
                    maxLines: 6,
                    decoration: InputDecoration(
                      hintText: 'Share your parenting experience, ask questions, or join the weekly discussion...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.withOpacity(0.1),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.language, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        'Your post will be auto-translated to other languages',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _createPost,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '🌍 Share with World',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildQuickActionsCard(),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🚀 Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.mic,
                    label: 'Voice Post',
                    color: Colors.orange,
                    onTap: _createVoicePost,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.photo_camera,
                    label: 'Photo Post',
                    color: Colors.green,
                    onTap: _createPhotoPost,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.help_outline,
                    label: 'Ask Question',
                    color: Colors.purple,
                    onTap: _askQuestion,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.topic,
                    label: 'Join Topic',
                    color: Colors.teal,
                    onTap: () => _tabController.animateTo(0),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatsOverviewCard(),
          const SizedBox(height: 16),
          _buildLanguageDistributionCard(),
          const SizedBox(height: 16),
          _buildTopContributorsCard(),
        ],
      ),
    );
  }

  Widget _buildStatsOverviewCard() {
    final stats = _communityStats ?? {};

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  '📊 Community Overview',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Posts',
                    '${stats['totalPosts'] ?? 0}',
                    Icons.forum,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Active Users',
                    '${stats['totalUsers'] ?? 0}',
                    Icons.people,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Languages',
                    '${(stats['languageDistribution'] as Map?)?.length ?? 0}',
                    Icons.language,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'This Week',
                    '${((stats['averagePostsPerWeek'] ?? 0) * 7).round()}',
                    Icons.trending_up,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageDistributionCard() {
    final languageDistribution = _communityStats?['languageDistribution'] as Map<String, dynamic>? ?? {};

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.public, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  '🌍 Language Distribution',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (languageDistribution.isEmpty) ...[
              const Center(
                child: Text(
                  'No language data available yet',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ] else ...[
              ...languageDistribution.entries.map((entry) {
                final language = entry.key;
                final count = entry.value as int;
                final percentage = (count / (_communityStats?['totalPosts'] ?? 1) * 100).round();

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Text(_getLanguageFlag(language)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_getLanguageName(language)),
                      ),
                      Text('$count posts ($percentage%)'),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTopContributorsCard() {
    final topContributors = _communityStats?['topContributors'] as Map<String, dynamic>? ?? {};

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.star, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  '⭐ Top Contributors',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (topContributors.isEmpty) ...[
              const Center(
                child: Text(
                  'No contributors yet',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ] else ...[
              ...topContributors.entries.take(5).map((entry) {
                final userName = entry.key;
                final postCount = entry.value as int;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.amber,
                    child: Text(
                      userName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(userName),
                  trailing: Text('$postCount posts'),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  // Helper methods
  String _getLanguageFlag(String? languageCode) {
    final supportedLanguages = TranslationService.getSupportedLanguages();
    return supportedLanguages[languageCode]?['flag'] ?? '🌐';
  }

  String _getLanguageName(String? languageCode) {
    final supportedLanguages = TranslationService.getSupportedLanguages();
    return supportedLanguages[languageCode]?['nativeName'] ?? 'Unknown';
  }

  // Action methods
  Future<void> _createPost() async {
    if (_postController.text.trim().isEmpty) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final l10n = AppLocalizations.of(context)!;

      await GlobalCommunityService.createCommunityPost(
        userId: authProvider.currentUser?['uid'] ?? 'anonymous',
        userName: authProvider.currentUser?['displayName'] ?? 'Anonymous',
        content: _postController.text.trim(),
        userLanguage: l10n.localeName,
        topicId: _currentWeeklyTopic?['id'] ?? 'general',
      );

      _postController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🌍 Post shared with global community!')),
      );

      _loadCommunityData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create post')),
      );
    }
  }

  void _likePost(String postId) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    GlobalCommunityService.interactWithPost(
      postId: postId,
      userId: authProvider.currentUser?['uid'] ?? 'anonymous',
      action: 'like',
    );
  }

  void _replyToPost(Map<String, dynamic> post) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reply to Post'),
        content: const TextField(
          decoration: InputDecoration(hintText: 'Write your reply...'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reply posted!')),
              );
            },
            child: const Text('Reply'),
          ),
        ],
      ),
    );
  }

  void _sharePost(Map<String, dynamic> post) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Post shared!')),
    );
  }

  void _createVoicePost() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🎙️ Voice post feature coming soon!')),
    );
  }

  void _createPhotoPost() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('📸 Photo post feature coming soon!')),
    );
  }

  void _askQuestion() {
    _postController.text = 'Question: ';
    _tabController.animateTo(2);
  }
}