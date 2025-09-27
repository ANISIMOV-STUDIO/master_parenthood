// lib/screens/modern_home_screen.dart
// 🎨 Modern Home Screen with Material 3 Expressive Design 2025

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../widgets/modern_ui_components.dart';
import '../providers/auth_provider.dart';
import '../services/advanced_ai_service.dart';
import '../services/enhanced_notification_service.dart';
import '../services/voice_service.dart';
import '../core/injection_container.dart';

class ModernHomeScreen extends StatefulWidget {
  const ModernHomeScreen({super.key});

  @override
  State<ModernHomeScreen> createState() => _ModernHomeScreenState();
}

class _ModernHomeScreenState extends State<ModernHomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _cardController;
  late Animation<double> _headerAnimation;
  late Animation<double> _cardAnimation;

  Map<String, dynamic>? _dailyInsights;
  Map<String, dynamic>? _childData;
  bool _isVoiceListening = false;
  String _greeting = '';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadDailyData();
    _generateGreeting();
  }

  void _initializeAnimations() {
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _cardController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _headerAnimation = CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOutCubic,
    );

    _cardAnimation = CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOutBack,
    );

    _headerController.forward();
    _cardController.forward();
  }

  void _generateGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      _greeting = '🌅 Доброе утро!';
    } else if (hour < 17) {
      _greeting = '☀️ Добрый день!';
    } else {
      _greeting = '🌙 Добрый вечер!';
    }
  }

  Future<void> _loadDailyData() async {
    try {
      // Simulate loading daily insights
      await Future.delayed(const Duration(milliseconds: 800));
      setState(() {
        _dailyInsights = {
          'mood': 'happy',
          'activities': 3,
          'achievements': 2,
          'next_milestone': 'Ходьба',
        };
        _childData = {
          'name': 'Малыш',
          'age_months': 18,
          'weight': 12.5,
          'height': 85,
        };
      });
    } catch (e) {
      debugPrint('Error loading daily data: $e');
    }
  }

  Future<void> _toggleVoiceListening() async {
    setState(() {
      _isVoiceListening = !_isVoiceListening;
    });

    if (_isVoiceListening) {
      // Start voice recognition
      try {
        await VoiceService.startListening();
      } catch (e) {
        debugPrint('Voice listening error: $e');
        setState(() {
          _isVoiceListening = false;
        });
      }
    } else {
      await VoiceService.stopListening();
    }
  }

  @override
  void dispose() {
    _headerController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: WaveAnimationBackground(
        colors: [AppTheme.primaryLight, AppTheme.secondaryLight],
        height: screenSize.height * 0.4,
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Modern Header with Greeting
              _buildModernHeader(theme, screenSize),

              // Quick Actions Section
              _buildQuickActionsSection(),

              // Daily Progress Cards
              _buildDailyProgressSection(),

              // AI Insights Section
              _buildAIInsightsSection(),

              // Feature Navigation
              _buildFeatureNavigationSection(),

              // Recent Activity
              _buildRecentActivitySection(),

              // Bottom spacing for FAB
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        ),
      ),

      // Modern Voice Control FAB
      floatingActionButton: _buildVoiceControlFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildModernHeader(ThemeData theme, Size screenSize) {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _headerAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, (1 - _headerAnimation.value) * 50),
            child: Opacity(
              opacity: _headerAnimation.value,
              child: Container(
                height: screenSize.height * 0.35,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Info Row
                    Row(
                      children: [
                        // Avatar with Glow Effect
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppTheme.primaryGradient,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withOpacity(0.3),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 30,
                          ),
                        ).animate().scale(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.elasticOut,
                        ),

                        const SizedBox(width: 16),

                        // Greeting and User Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _greeting,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryColor,
                                ),
                              ).animate().slideX(
                                duration: const Duration(milliseconds: 500),
                                begin: 1,
                                curve: Curves.easeOutCubic,
                              ),

                              Text(
                                'Готовы к новому дню с малышом?',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ).animate().slideX(
                                duration: const Duration(milliseconds: 600),
                                begin: 1,
                                curve: Curves.easeOutCubic,
                              ),
                            ],
                          ),
                        ),

                        // Notification Bell
                        FeatureIconBadge(
                          icon: Icons.notifications_outlined,
                          color: AppTheme.warningColor,
                          badgeCount: 3,
                          size: 48,
                          onTap: () {
                            // Navigate to notifications
                          },
                        ).animate().scale(
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.elasticOut,
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Today's Summary Card
                    if (_childData != null)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Child Avatar
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppTheme.secondaryGradient,
                              ),
                              child: const Icon(
                                Icons.child_care,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),

                            const SizedBox(width: 16),

                            // Child Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _childData!['name'] ?? 'Малыш',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${_childData!['age_months']} месяцев',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Quick Stats
                            Column(
                              children: [
                                Text(
                                  '${_childData!['weight']} кг',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: AppTheme.successColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${_childData!['height']} см',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ).animate().slideY(
                        duration: const Duration(milliseconds: 800),
                        begin: 0.5,
                        curve: Curves.easeOutBack,
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '⚡ Быстрые действия',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ).animate().slideX(
              duration: const Duration(milliseconds: 500),
              begin: -0.3,
            ),

            const SizedBox(height: 16),

            AnimationLimiter(
              child: Row(
                children: AnimationConfiguration.toStaggeredList(
                  duration: const Duration(milliseconds: 375),
                  childAnimationBuilder: (widget) => SlideAnimation(
                    horizontalOffset: 50.0,
                    child: FadeInAnimation(child: widget),
                  ),
                  children: [
                    _buildQuickActionButton(
                      'Кормление',
                      Icons.restaurant,
                      AppTheme.feedingColor,
                      () => _logFeeding(),
                    ),
                    _buildQuickActionButton(
                      'Сон',
                      Icons.bedtime,
                      AppTheme.sleepColor,
                      () => _logSleep(),
                    ),
                    _buildQuickActionButton(
                      'Игра',
                      Icons.toys,
                      AppTheme.developmentColor,
                      () => _logActivity(),
                    ),
                    _buildQuickActionButton(
                      'Здоровье',
                      Icons.favorite,
                      AppTheme.healthColor,
                      () => _openHealth(),
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

  Widget _buildQuickActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyProgressSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.only(top: 32, left: 16, right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📊 Прогресс дня',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ).animate().slideX(
              duration: const Duration(milliseconds: 500),
              begin: -0.3,
            ),

            const SizedBox(height: 16),

            AnimationLimiter(
              child: Column(
                children: AnimationConfiguration.toStaggeredList(
                  duration: const Duration(milliseconds: 375),
                  childAnimationBuilder: (widget) => SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(child: widget),
                  ),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ModernStatsCard(
                            title: 'Кормлений',
                            value: '6',
                            unit: 'раз',
                            icon: Icons.restaurant,
                            color: AppTheme.feedingColor,
                            subtitle: 'Сегодня',
                          ),
                        ),
                        Expanded(
                          child: ModernStatsCard(
                            title: 'Сна',
                            value: '12',
                            unit: 'ч',
                            icon: Icons.bedtime,
                            color: AppTheme.sleepColor,
                            subtitle: 'За сутки',
                          ),
                        ),
                      ],
                    ),

                    AnimatedProgressCard(
                      title: 'Развитие навыков',
                      subtitle: 'Следующий этап: ходьба',
                      progress: 0.75,
                      color: AppTheme.developmentColor,
                      icon: Icons.psychology,
                      progressText: '75%',
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

  Widget _buildAIInsightsSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.only(top: 32, left: 16, right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '🤖 AI Инсайты',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    // Navigate to AI insights
                  },
                  child: const Text('Все'),
                ),
              ],
            ).animate().slideX(
              duration: const Duration(milliseconds: 500),
              begin: -0.3,
            ),

            const SizedBox(height: 16),

            ModernActionCard(
              title: 'Время для прогулки!',
              subtitle: 'Отличная погода для развития моторики',
              icon: Icons.directions_walk,
              color: AppTheme.successColor,
              onTap: () {
                // AI suggestion action
              },
            ).animate().slideY(
              duration: const Duration(milliseconds: 600),
              begin: 0.3,
              curve: Curves.easeOutBack,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureNavigationSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.only(top: 32, left: 16, right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🎯 Основные функции',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ).animate().slideX(
              duration: const Duration(milliseconds: 500),
              begin: -0.3,
            ),

            const SizedBox(height: 16),

            AnimationLimiter(
              child: Column(
                children: AnimationConfiguration.toStaggeredList(
                  duration: const Duration(milliseconds: 375),
                  childAnimationBuilder: (widget) => SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(child: widget),
                  ),
                  children: [
                    ModernActionCard(
                      title: 'Умный календарь',
                      subtitle: 'AI-планирование активностей и напоминания',
                      icon: Icons.calendar_today,
                      color: AppTheme.tertiaryColor,
                      onTap: () {
                        // Navigate to calendar
                      },
                      trailing: FeatureIconBadge(
                        icon: Icons.star,
                        color: AppTheme.warningColor,
                        size: 32,
                      ),
                    ),

                    ModernActionCard(
                      title: 'Глобальное сообщество',
                      subtitle: 'Общение с родителями со всего мира',
                      icon: Icons.public,
                      color: AppTheme.communityColor,
                      onTap: () {
                        // Navigate to community
                      },
                    ),

                    ModernActionCard(
                      title: 'Голосовое управление',
                      subtitle: 'Управляйте приложением голосом',
                      icon: Icons.mic,
                      color: AppTheme.voiceColor,
                      onTap: () {
                        // Navigate to voice settings
                      },
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

  Widget _buildRecentActivitySection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.only(top: 32, left: 16, right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📝 Недавняя активность',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ).animate().slideX(
              duration: const Duration(milliseconds: 500),
              begin: -0.3,
            ),

            const SizedBox(height: 16),

            // Recent activity items would go here
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.history,
                    color: AppTheme.textSecondary,
                    size: 24,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Активность появится здесь',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(
              duration: const Duration(milliseconds: 800),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceControlFAB() {
    return GestureDetector(
      onTap: _toggleVoiceListening,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: _isVoiceListening ? 80 : 64,
        height: _isVoiceListening ? 80 : 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: _isVoiceListening
              ? AppTheme.tertiaryGradient
              : AppTheme.secondaryGradient,
          boxShadow: [
            BoxShadow(
              color: (_isVoiceListening
                      ? AppTheme.tertiaryColor
                      : AppTheme.secondaryColor)
                  .withOpacity(0.4),
              blurRadius: _isVoiceListening ? 20 : 12,
              spreadRadius: _isVoiceListening ? 4 : 2,
            ),
          ],
        ),
        child: Icon(
          _isVoiceListening ? Icons.mic : Icons.mic_none,
          color: Colors.white,
          size: _isVoiceListening ? 32 : 28,
        ),
      ),
    ).animate(target: _isVoiceListening ? 1 : 0).scale(
      duration: const Duration(milliseconds: 300),
      begin: const Offset(1, 1),
      end: const Offset(1.1, 1.1),
    );
  }

  // Action Methods
  void _logFeeding() {
    // Implement feeding log
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Кормление записано!')),
    );
  }

  void _logSleep() {
    // Implement sleep log
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Сон записан!')),
    );
  }

  void _logActivity() {
    // Implement activity log
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Активность записана!')),
    );
  }

  void _openHealth() {
    // Navigate to health section
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Переход к здоровью')),
    );
  }
}