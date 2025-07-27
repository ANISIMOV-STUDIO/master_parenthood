// lib/screens/child_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import '../l10n/app_localizations.dart';

class ChildProfileScreen extends StatefulWidget {
  const ChildProfileScreen({super.key});

  @override
  State<ChildProfileScreen> createState() => _ChildProfileScreenState();
}

class _ChildProfileScreenState extends State<ChildProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _petController;
  late AnimationController _statsController;

  // Данные ребенка (в реальном приложении будут из Firebase)
  final String childName = 'Максим';
  final String childAge = '2 года 3 месяца';
  final double height = 89.0;
  final double weight = 12.5;
  final int wordsCount = 47;
  final int sleepHours = 11;

  // Виртуальный питомец
  final String petName = 'Искорка';
  final String petEmoji = '🦄';
  final int petHappiness = 85;
  final int petEnergy = 70;
  final int petKnowledge = 90;

  // Вехи развития
  final List<MilestoneData> milestones = [
    MilestoneData('Говорит фразы из 2-3 слов', 85, Colors.green),
    MilestoneData('Самостоятельно ест ложкой', 70, Colors.blue),
    MilestoneData('Различает основные цвета', 60, Colors.purple),
    MilestoneData('Прыгает на двух ногах', 45, Colors.orange),
  ];

  // Данные для графика роста
  final List<FlSpot> growthData = const [
    FlSpot(0, 80),
    FlSpot(1, 82),
    FlSpot(2, 84),
    FlSpot(3, 86),
    FlSpot(4, 87),
    FlSpot(5, 89),
  ];

  @override
  void initState() {
    super.initState();
    _petController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _statsController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _petController.dispose();
    _statsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Красивый AppBar
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            stretch: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                childName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 10, color: Colors.black45)],
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withBlue(200),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Декоративные круги
                    Positioned(
                      top: -50,
                      right: -50,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -30,
                      left: -30,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Возраст
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.purple.shade400, Colors.pink.shade400],
                        ),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        childAge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ).animate().scale(delay: 200.ms, duration: 500.ms),

                  const SizedBox(height: 30),

                  // Виртуальный питомец
                  _buildVirtualPetSection(context, loc),

                  const SizedBox(height: 30),

                  // График роста
                  _buildGrowthChart(context, loc),

                  const SizedBox(height: 30),

                  // Вехи развития
                  _buildMilestonesSection(context, loc),

                  const SizedBox(height: 30),

                  // Статистика
                  _buildQuickStats(context, loc),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVirtualPetSection(BuildContext context, AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.shade50,
            Colors.pink.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.pets, color: Colors.purple),
              const SizedBox(width: 8),
              Text(
                loc.virtualPet,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // Анимация питомца
              AnimatedBuilder(
                animation: _petController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, math.sin(_petController.value * math.pi) * 10),
                    child: Transform.scale(
                      scale: 1.0 + math.sin(_petController.value * math.pi) * 0.1,
                      child: Text(
                        petEmoji,
                        style: const TextStyle(fontSize: 80),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 20),
              // Статистика питомца
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      petName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildPetStat(loc.happiness, petHappiness, Colors.yellow),
                    const SizedBox(height: 8),
                    _buildPetStat(loc.energy, petEnergy, Colors.pink),
                    const SizedBox(height: 8),
                    _buildPetStat(loc.knowledge, petKnowledge, Colors.blue),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.1);
  }

  Widget _buildPetStat(String label, int value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            Text(
              '$value%',
              style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        AnimatedBuilder(
          animation: _statsController,
          builder: (context, child) {
            return LinearProgressIndicator(
              value: (value / 100) * _statsController.value,
              backgroundColor: color.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            );
          },
        ),
      ],
    );
  }

  Widget _buildGrowthChart(BuildContext context, AppLocalizations loc) {
    return Container(
      height: 200,
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
          Text(
            loc.growthChart,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: growthData,
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade400, Colors.pink.shade400],
                    ),
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.purple.withValues(alpha: 0.2),
                          Colors.pink.withValues(alpha: 0.2),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1);
  }

  Widget _buildMilestonesSection(BuildContext context, AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.flag, color: Colors.orange),
            const SizedBox(width: 8),
            Text(
              loc.milestones,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ...milestones.asMap().entries.map((entry) {
          final index = entry.key;
          final milestone = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildMilestoneItem(milestone, index),
          );
        }),
      ],
    );
  }

  Widget _buildMilestoneItem(MilestoneData milestone, int index) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  milestone.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${milestone.progress}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: milestone.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: milestone.progress / 100,
              backgroundColor: milestone.color.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(milestone.color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    ).animate()
        .fadeIn(delay: (800 + index * 150).ms)
        .slideX(begin: 0.2);
  }

  Widget _buildQuickStats(BuildContext context, AppLocalizations loc) {
    final stats = [
      StatItem(Icons.straighten, '$height ${loc.heightCm}', loc.heightCm, Colors.purple),
      StatItem(Icons.monitor_weight, '$weight ${loc.weightKg}', loc.weightKg, Colors.pink),
      StatItem(Icons.bedtime, '$sleepHours ч', 'Сон', Colors.blue),
      StatItem(Icons.abc, '$wordsCount', loc.words, Colors.green),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: stat.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: stat.color.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(stat.icon, color: stat.color, size: 28),
              const SizedBox(height: 8),
              Text(
                stat.value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: stat.color,
                ),
              ),
              Text(
                stat.label,
                style: TextStyle(
                  fontSize: 12,
                  color: stat.color.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ).animate()
            .fadeIn(delay: (800 + index * 100).ms)
            .scale(begin: const Offset(0.8, 0.8));
      },
    );
  }
}

// Модели данных
class MilestoneData {
  final String title;
  final int progress;
  final Color color;

  MilestoneData(this.title, this.progress, this.color);
}

class StatItem {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  StatItem(this.icon, this.value, this.label, this.color);
}