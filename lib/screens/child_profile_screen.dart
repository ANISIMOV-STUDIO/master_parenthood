// lib/screens/child_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:math' as math;
import 'dart:io';
import '../l10n/app_localizations.dart';
import '../services/firebase_service.dart';

class ChildProfileScreen extends StatefulWidget {
  const ChildProfileScreen({super.key});

  @override
  State<ChildProfileScreen> createState() => _ChildProfileScreenState();
}

class _ChildProfileScreenState extends State<ChildProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _petController;
  late AnimationController _statsController;

  ChildProfile? _activeChild;
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingPhoto = false;

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

  Future<void> _pickAndUploadPhoto() async {
    if (_activeChild == null) return;

    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => _isUploadingPhoto = true);

    try {
      final photoUrl = await FirebaseService.uploadChildPhoto(
        file: File(image.path),
        childId: _activeChild!.id,
      );

      if (photoUrl != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Фото обновлено')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки фото: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return StreamBuilder<List<ChildProfile>>(
      stream: FirebaseService.getChildrenStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.child_care, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Добавьте первого ребенка',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _showAddChildDialog(context),
                    child: const Text('Добавить ребенка'),
                  ),
                ],
              ),
            ),
          );
        }

        final children = snapshot.data!;
        _activeChild ??= children.first;

        return Scaffold(
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Красивый AppBar с фото
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                stretch: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    _activeChild!.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(blurRadius: 10, color: Colors.black45)],
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Фото ребенка или градиент
                      if (_activeChild!.photoURL != null)
                        CachedNetworkImage(
                          imageUrl: _activeChild!.photoURL!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
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
                          ),
                        )
                      else
                        Container(
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
                        ),

                      // Затемнение для читаемости текста
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.7),
                            ],
                          ),
                        ),
                      ),

                      // Кнопка добавления/изменения фото
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: FloatingActionButton.small(
                          onPressed:
                              _isUploadingPhoto ? null : _pickAndUploadPhoto,
                          child: _isUploadingPhoto
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.camera_alt),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  // Выбор ребенка, если их несколько
                  if (children.length > 1)
                    PopupMenuButton<ChildProfile>(
                      initialValue: _activeChild,
                      onSelected: (child) {
                        setState(() => _activeChild = child);
                      },
                      itemBuilder: (context) => children
                          .map((child) => PopupMenuItem(
                                value: child,
                                child: Text(child.name),
                              ))
                          .toList(),
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(Icons.switch_account),
                      ),
                    ),

                  // Редактирование
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () =>
                        _showEditChildDialog(context, _activeChild!),
                  ),
                ],
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Возраст и основная информация
                      Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.purple.shade400,
                                    Colors.pink.shade400
                                  ],
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
                                _activeChild!.ageFormatted,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ).animate().scale(delay: 200.ms, duration: 500.ms),

                            const SizedBox(height: 16),

                            // Пол
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _activeChild!.gender == 'male'
                                      ? Icons.male
                                      : Icons.female,
                                  color: _activeChild!.gender == 'male'
                                      ? Colors.blue
                                      : Colors.pink,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _activeChild!.gender == 'male'
                                      ? 'Мальчик'
                                      : 'Девочка',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

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

                      const SizedBox(height: 30),

                      // История сказок
                      _buildStoriesSection(context, loc),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
                    offset: Offset(
                        0, math.sin(_petController.value * math.pi) * 10),
                    child: Transform.scale(
                      scale:
                          1.0 + math.sin(_petController.value * math.pi) * 0.1,
                      child: Text(
                        _activeChild!.petType,
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _activeChild!.petName,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () => _showEditPetDialog(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildPetStat(loc.happiness,
                        _activeChild!.petStats['happiness']!, Colors.yellow),
                    const SizedBox(height: 8),
                    _buildPetStat(loc.energy, _activeChild!.petStats['energy']!,
                        Colors.pink),
                    const SizedBox(height: 8),
                    _buildPetStat(loc.knowledge,
                        _activeChild!.petStats['knowledge']!, Colors.blue),
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
              style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.bold),
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
    // Здесь можно добавить реальные данные из Firestore
    const growthData = [
      FlSpot(0, 80),
      FlSpot(1, 82),
      FlSpot(2, 84),
      FlSpot(3, 86),
      FlSpot(4, 87),
      FlSpot(5, 89),
    ];

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
    // Вехи развития можно загружать из базы данных или определять по возрасту
    final milestones = [
      MilestoneData('Говорит фразы из 2-3 слов', 85, Colors.green),
      MilestoneData('Самостоятельно ест ложкой', 70, Colors.blue),
      MilestoneData('Различает основные цвета', 60, Colors.purple),
      MilestoneData('Прыгает на двух ногах', 45, Colors.orange),
    ];

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
    ).animate().fadeIn(delay: (800 + index * 150).ms).slideX(begin: 0.2);
  }

  Widget _buildQuickStats(BuildContext context, AppLocalizations loc) {
    final stats = [
      StatItem(Icons.straighten, '${_activeChild!.height} ${loc.heightCm}',
          loc.heightCm, Colors.purple),
      StatItem(Icons.monitor_weight, '${_activeChild!.weight} ${loc.weightKg}',
          loc.weightKg, Colors.pink),
      StatItem(Icons.calendar_today, '${_activeChild!.ageInMonths} мес.',
          'Возраст', Colors.blue),
      StatItem(Icons.celebration, '${_activeChild!.petStats['happiness']}',
          'Счастье', Colors.green),
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
        )
            .animate()
            .fadeIn(delay: (800 + index * 100).ms)
            .scale(begin: const Offset(0.8, 0.8));
      },
    );
  }

  Widget _buildStoriesSection(BuildContext context, AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_stories, color: Colors.purple),
            const SizedBox(width: 8),
            Text(
              'История сказок',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        StreamBuilder<List<StoryData>>(
          stream: FirebaseService.getStoriesStream(_activeChild!.id),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text('Еще нет созданных сказок'),
                ),
              );
            }

            return SizedBox(
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final story = snapshot.data![index];
                  return Container(
                    width: 200,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.purple.shade100,
                          Colors.pink.shade100,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          story.theme,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Text(
                            story.story,
                            style: const TextStyle(fontSize: 14),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatDate(story.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: (100 * index).ms)
                      .slideX(begin: 0.2);
                },
              ),
            );
          },
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  void _showAddChildDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddChildDialog(),
    );
  }

  void _showEditChildDialog(BuildContext context, ChildProfile child) {
    showDialog(
      context: context,
      builder: (context) => EditChildDialog(child: child),
    );
  }

  void _showEditPetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => EditPetDialog(child: _activeChild!),
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

// Диалог добавления ребенка
class AddChildDialog extends StatefulWidget {
  const AddChildDialog({super.key});

  @override
  State<AddChildDialog> createState() => _AddChildDialogState();
}

class _AddChildDialogState extends State<AddChildDialog> {
  final _nameController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  DateTime _birthDate = DateTime.now().subtract(const Duration(days: 365 * 2));
  String _gender = 'male';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите имя ребенка')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseService.addChild(
        name: _nameController.text,
        birthDate: _birthDate,
        gender: _gender,
        height: double.tryParse(_heightController.text),
        weight: double.tryParse(_weightController.text),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ребенок добавлен')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Добавить ребенка'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Имя',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Дата рождения
            ListTile(
              title: const Text('Дата рождения'),
              subtitle: Text(
                '${_birthDate.day}.${_birthDate.month}.${_birthDate.year}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _birthDate,
                  firstDate:
                      DateTime.now().subtract(const Duration(days: 365 * 18)),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _birthDate = date);
                }
              },
            ),

            const SizedBox(height: 16),

            // Пол
            Row(
              children: [
                const Text('Пол: '),
                Radio<String>(
                  value: 'male',
                  groupValue: _gender,
                  onChanged: (value) => setState(() => _gender = value!),
                ),
                const Text('Мальчик'),
                Radio<String>(
                  value: 'female',
                  groupValue: _gender,
                  onChanged: (value) => setState(() => _gender = value!),
                ),
                const Text('Девочка'),
              ],
            ),

            const SizedBox(height: 16),

            // Рост и вес
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _heightController,
                    decoration: const InputDecoration(
                      labelText: 'Рост (см)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    decoration: const InputDecoration(
                      labelText: 'Вес (кг)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Добавить'),
        ),
      ],
    );
  }
}

// Диалог редактирования ребенка
class EditChildDialog extends StatefulWidget {
  final ChildProfile child;

  const EditChildDialog({super.key, required this.child});

  @override
  State<EditChildDialog> createState() => _EditChildDialogState();
}

class _EditChildDialogState extends State<EditChildDialog> {
  late TextEditingController _nameController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late DateTime _birthDate;
  late String _gender;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.child.name);
    _heightController =
        TextEditingController(text: widget.child.height.toString());
    _weightController =
        TextEditingController(text: widget.child.weight.toString());
    _birthDate = widget.child.birthDate;
    _gender = widget.child.gender;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);

    try {
      await FirebaseService.updateChild(
        childId: widget.child.id,
        data: {
          'name': _nameController.text,
          'birthDate': _birthDate,
          'gender': _gender,
          'height': double.tryParse(_heightController.text) ?? 0,
          'weight': double.tryParse(_weightController.text) ?? 0,
        },
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Данные обновлены')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Редактировать данные'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Имя',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Дата рождения
            ListTile(
              title: const Text('Дата рождения'),
              subtitle: Text(
                '${_birthDate.day}.${_birthDate.month}.${_birthDate.year}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _birthDate,
                  firstDate:
                      DateTime.now().subtract(const Duration(days: 365 * 18)),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _birthDate = date);
                }
              },
            ),

            const SizedBox(height: 16),

            // Пол
            Row(
              children: [
                const Text('Пол: '),
                Radio<String>(
                  value: 'male',
                  groupValue: _gender,
                  onChanged: (value) => setState(() => _gender = value!),
                ),
                const Text('Мальчик'),
                Radio<String>(
                  value: 'female',
                  groupValue: _gender,
                  onChanged: (value) => setState(() => _gender = value!),
                ),
                const Text('Девочка'),
              ],
            ),

            const SizedBox(height: 16),

            // Рост и вес
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _heightController,
                    decoration: const InputDecoration(
                      labelText: 'Рост (см)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    decoration: const InputDecoration(
                      labelText: 'Вес (кг)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Сохранить'),
        ),
      ],
    );
  }
}

// Диалог редактирования питомца
class EditPetDialog extends StatefulWidget {
  final ChildProfile child;

  const EditPetDialog({super.key, required this.child});

  @override
  State<EditPetDialog> createState() => _EditPetDialogState();
}

class _EditPetDialogState extends State<EditPetDialog> {
  late TextEditingController _nameController;
  late String _selectedEmoji;
  bool _isLoading = false;

  final List<String> _petEmojis = [
    '🦄',
    '🐻',
    '🦊',
    '🐯',
    '🦁',
    '🐶',
    '🐱',
    '🐭',
    '🐹',
    '🐰'
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.child.petName);
    _selectedEmoji = widget.child.petType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);

    try {
      await FirebaseService.updateChild(
        childId: widget.child.id,
        data: {
          'petName': _nameController.text,
          'petType': _selectedEmoji,
        },
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Редактировать питомца'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Имя питомца',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Выберите питомца:'),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _petEmojis.map((emoji) {
              final isSelected = _selectedEmoji == emoji;
              return GestureDetector(
                onTap: () => setState(() => _selectedEmoji = emoji),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.purple.shade100
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.purple : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Text(emoji, style: const TextStyle(fontSize: 30)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Сохранить'),
        ),
      ],
    );
  }
}
