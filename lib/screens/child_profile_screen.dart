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
import 'package:cloud_firestore/cloud_firestore.dart';

class ChildProfileScreen extends StatefulWidget {
  const ChildProfileScreen({super.key});

  @override
  State<ChildProfileScreen> createState() => _ChildProfileScreenState();
}

class _ChildProfileScreenState extends State<ChildProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _chartController;
  late TabController _tabController;

  ChildProfile? _activeChild;
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingPhoto = false;
  
  // Данные для графиков
  List<FlSpot> _heightData = [];
  List<FlSpot> _weightData = [];
  
  // Вехи развития
  final List<Milestone> _milestones = [
    Milestone('Первая улыбка', 'Социальное развитие', 0, 2, false),
    Milestone('Держит голову', 'Физическое развитие', 1, 4, false),
    Milestone('Переворачивается', 'Моторика', 3, 6, false),
    Milestone('Сидит без поддержки', 'Физическое развитие', 5, 8, false),
    Milestone('Первые слова', 'Речь', 8, 15, false),
    Milestone('Ходит самостоятельно', 'Моторика', 9, 18, false),
    Milestone('Говорит предложения', 'Речь', 18, 30, false),
    Milestone('Контроль мочевого пузыря', 'Самостоятельность', 24, 36, false),
  ];

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _chartController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _tabController = TabController(length: 3, vsync: this);
    
    _loadChildData();
    _generateSampleData();
  }

  @override
  void dispose() {
    _headerController.dispose();
    _chartController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadChildData() async {
    final activeChild = await FirebaseService.getActiveChild();
    if (mounted) {
      setState(() {
        _activeChild = activeChild;
      });
      _headerController.forward();
      _chartController.forward();
      
      if (activeChild != null) {
        _updateMilestonesForAge(activeChild.ageInMonths);
      }
    }
  }

  void _generateSampleData() {
    // Генерируем примерные данные роста и веса
    final now = DateTime.now();
    for (int i = 0; i <= 24; i++) {
      final date = now.subtract(Duration(days: 30 * (24 - i)));
      final ageInMonths = i;
      
      // Примерные данные роста (см)
      final height = 50 + (ageInMonths * 2.5) + (math.Random().nextDouble() * 2 - 1);
      _heightData.add(FlSpot(ageInMonths.toDouble(), height));
      
      // Примерные данные веса (кг)
      final weight = 3.5 + (ageInMonths * 0.6) + (math.Random().nextDouble() * 0.5 - 0.25);
      _weightData.add(FlSpot(ageInMonths.toDouble(), weight));
    }
  }

  void _updateMilestonesForAge(int ageInMonths) {
    for (var milestone in _milestones) {
      milestone.isAchieved = ageInMonths >= milestone.minAge;
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    if (_activeChild == null) return;

    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image == null) return;

    final file = File(image.path);
    final fileSizeInBytes = await file.length();
    final fileSizeInMB = fileSizeInBytes / (1024 * 1024);
    
    if (fileSizeInMB > 5) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Файл слишком большой'),
            content: Text('Размер фото не должен превышать 5 МБ.\nТекущий размер: ${fileSizeInMB.toStringAsFixed(2)} МБ'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Понятно'),
              ),
            ],
          ),
        );
      }
      return;
    }

    setState(() => _isUploadingPhoto = true);

    try {
      final photoUrl = await FirebaseService.uploadChildPhoto(
        file: file,
        childId: _activeChild!.id,
      );

      if (mounted) {
        if (photoUrl != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Фото обновлено')),
          );
          _loadChildData(); // Перезагружаем данные
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ChildProfile>>(
      stream: FirebaseService.getChildrenStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildNoChildrenState();
        }

        final children = snapshot.data!;
        _activeChild ??= children.first;

        return Scaffold(
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                _buildSliverAppBar(children),
              ];
            },
            body: _buildTabContent(),
          ),
        );
      },
    );
  }

  Widget _buildNoChildrenState() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль ребенка'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.child_care,
              size: 100,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              'Нет добавленных детей',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Добавьте профиль ребенка\nчтобы отслеживать развитие',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _showAddChildDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Добавить ребенка'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ],
        ).animate().fadeIn().slideY(begin: 0.3),
      ),
    );
  }

  Widget _buildSliverAppBar(List<ChildProfile> children) {
    return SliverAppBar(
      expandedHeight: 280,
      floating: false,
      pinned: true,
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
      actions: [
        if (children.length > 1)
          PopupMenuButton<ChildProfile>(
            initialValue: _activeChild,
            onSelected: (child) {
              setState(() {
                _activeChild = child;
                _updateMilestonesForAge(child.ageInMonths);
              });
            },
            itemBuilder: (context) => children
                .map((child) => PopupMenuItem(
                      value: child,
                      child: Text(child.name),
                    ))
                .toList(),
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.switch_account, color: Colors.white),
            ),
          ),
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.white),
          onPressed: () => _showEditChildDialog(),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withValues(alpha: 0.8),
                Colors.purple.shade300,
              ],
            ),
          ),
          child: _activeChild != null ? _buildHeaderContent() : null,
        ),
      ),
    );
  }

  Widget _buildHeaderContent() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const SizedBox(height: 60), // Место для AppBar
            
            // Фото ребенка
            Hero(
              tag: 'child_photo_${_activeChild!.id}',
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    ClipOval(
                      child: _activeChild!.photoURL != null
                          ? CachedNetworkImage(
                              imageUrl: _activeChild!.photoURL!,
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.child_care, size: 60),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.child_care, size: 60),
                              ),
                            )
                          : Container(
                              color: Colors.white,
                              child: Icon(
                                Icons.child_care,
                                size: 60,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: _isUploadingPhoto ? null : _pickAndUploadPhoto,
                          icon: _isUploadingPhoto
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Icon(
                                  Icons.camera_alt,
                                  color: Theme.of(context).primaryColor,
                                ),
                          iconSize: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ).animate(controller: _headerController).scale().fadeIn(),
            
            const SizedBox(height: 16),
            
            // Имя и возраст
            Column(
              children: [
                Text(
                  _activeChild!.name,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 10,
                        color: Colors.black26,
                      ),
                    ],
                  ),
                ).animate(controller: _headerController).fadeIn(delay: 200.ms).slideY(begin: 0.3),
                
                const SizedBox(height: 8),
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _activeChild!.ageFormatted,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ).animate(controller: _headerController).fadeIn(delay: 400.ms).scale(begin: const Offset(0.8, 0.8)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    return Column(
      children: [
        Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).primaryColor,
            indicatorWeight: 3,
            tabs: const [
              Tab(icon: Icon(Icons.show_chart), text: 'Рост'),
              Tab(icon: Icon(Icons.timeline), text: 'Развитие'),
              Tab(icon: Icon(Icons.info_outline), text: 'Данные'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildGrowthTab(),
              _buildMilestonesTab(),
              _buildDataTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGrowthTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Текущие показатели
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Рост',
                  '${_activeChild?.height.toStringAsFixed(0)} см',
                  Icons.height,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Вес',
                  '${_activeChild?.weight.toStringAsFixed(1)} кг',
                  Icons.monitor_weight,
                  Colors.green,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // График роста
          Text(
            'График роста',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Container(
            height: 300,
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
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 10,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withValues(alpha: 0.2),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 3,
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            '${value.toInt()}м',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w300,
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 10,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            '${value.toInt()}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w300,
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: _heightData,
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.withValues(alpha: 0.8),
                        Colors.blue.withValues(alpha: 0.3),
                      ],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.withValues(alpha: 0.2),
                          Colors.blue.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ).animate(controller: _chartController).fadeIn().slideY(begin: 0.3),
          
          const SizedBox(height: 24),
          
          // График веса
          Text(
            'График веса',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Container(
            height: 300,
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
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 2,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withValues(alpha: 0.2),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 3,
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            '${value.toInt()}м',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w300,
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 2,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            '${value.toStringAsFixed(0)}кг',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w300,
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: _weightData,
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.withValues(alpha: 0.8),
                        Colors.green.withValues(alpha: 0.3),
                      ],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.green.withValues(alpha: 0.2),
                          Colors.green.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ).animate(controller: _chartController).fadeIn(delay: 200.ms).slideY(begin: 0.3),
        ],
      ),
    );
  }

  Widget _buildMilestonesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Вехи развития',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: _showAddMilestoneDialog,
                icon: const Icon(Icons.add),
                label: const Text('Добавить'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Text(
            'Отметьте достижения вашего ребенка',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _milestones.length,
            itemBuilder: (context, index) {
              final milestone = _milestones[index];
              return _buildMilestoneCard(milestone, index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneCard(Milestone milestone, int index) {
    final isInRange = _activeChild != null && 
        _activeChild!.ageInMonths >= milestone.minAge && 
        _activeChild!.ageInMonths <= milestone.maxAge;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: milestone.isAchieved 
            ? Colors.green.withValues(alpha: 0.1)
            : isInRange 
                ? Colors.orange.withValues(alpha: 0.1)
                : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: milestone.isAchieved 
              ? Colors.green.withValues(alpha: 0.3)
              : isInRange 
                  ? Colors.orange.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: milestone.isAchieved 
                ? Colors.green
                : isInRange 
                    ? Colors.orange
                    : Colors.grey.shade300,
          ),
          child: Icon(
            milestone.isAchieved 
                ? Icons.check
                : isInRange 
                    ? Icons.schedule
                    : Icons.radio_button_unchecked,
            color: milestone.isAchieved || isInRange ? Colors.white : Colors.grey.shade600,
          ),
        ),
        title: Text(
          milestone.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: milestone.isAchieved ? Colors.green.shade700 : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(milestone.category),
            const SizedBox(height: 4),
            Text(
              '${milestone.minAge}-${milestone.maxAge} месяцев',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        trailing: Switch(
          value: milestone.isAchieved,
          onChanged: (value) {
            setState(() {
              milestone.isAchieved = value;
            });
            // Здесь можно сохранить в Firebase
          },
        ),
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.3);
  }

  Widget _buildDataTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Информация о ребенке',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          _buildInfoSection('Основные данные', [
            _buildInfoRow('Имя', _activeChild?.name ?? ''),
            _buildInfoRow('Пол', _activeChild?.gender == 'male' ? 'Мальчик' : 'Девочка'),
            _buildInfoRow('Дата рождения', _formatDate(_activeChild?.birthDate)),
            _buildInfoRow('Возраст', _activeChild?.ageFormatted ?? ''),
          ]),
          
          const SizedBox(height: 24),
          
          _buildInfoSection('Физические показатели', [
            _buildInfoRow('Рост', '${_activeChild?.height.toStringAsFixed(0)} см'),
            _buildInfoRow('Вес', '${_activeChild?.weight.toStringAsFixed(1)} кг'),
            _buildInfoRow('ИМТ', _calculateBMI()),
          ]),
          
          const SizedBox(height: 24),
          
          _buildInfoSection('Развитие', [
            _buildInfoRow('Словарный запас', '${_activeChild?.vocabularySize ?? 0} слов'),
            _buildInfoRow('Достижений выполнено', '${_milestones.where((m) => m.isAchieved).length}/${_milestones.length}'),
          ]),
          
          const SizedBox(height: 32),
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showAddMeasurementDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Добавить измерение'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showEditChildDialog,
                  icon: const Icon(Icons.edit),
                  label: const Text('Редактировать'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
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
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  String _calculateBMI() {
    if (_activeChild == null) return '';
    final heightInM = _activeChild!.height / 100;
    final bmi = _activeChild!.weight / (heightInM * heightInM);
    return bmi.toStringAsFixed(1);
  }

  void _showAddChildDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddChildDialog(
        onSave: () {
          _loadChildData(); // Перезагружаем данные после добавления
        },
      ),
    );
  }

  void _showEditChildDialog() {
    if (_activeChild == null) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditChildDialog(
        child: _activeChild!,
        onSave: () {
          _loadChildData(); // Перезагружаем данные после редактирования
        },
      ),
    );
  }

  void _showAddMilestoneDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddMilestoneDialog(
        onSave: (milestone) {
          setState(() {
            _milestones.add(milestone);
          });
        },
      ),
    );
  }

  void _showAddMeasurementDialog() {
    if (_activeChild == null) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddMeasurementDialog(
        childId: _activeChild!.id,
        currentHeight: _activeChild!.height,
        currentWeight: _activeChild!.weight,
        onSave: () {
          _loadChildData(); // Перезагружаем данные после добавления измерения
        },
      ),
    );
  }
}

// Модель для вех развития
class Milestone {
  final String title;
  final String category;
  final int minAge; // в месяцах
  final int maxAge; // в месяцах
  bool isAchieved;

  Milestone(this.title, this.category, this.minAge, this.maxAge, this.isAchieved);
}

// Диалог добавления ребенка
class _AddChildDialog extends StatefulWidget {
  final VoidCallback onSave;

  const _AddChildDialog({required this.onSave});

  @override
  State<_AddChildDialog> createState() => _AddChildDialogState();
}

class _AddChildDialogState extends State<_AddChildDialog> {
  final _nameController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  String _selectedGender = 'male';
  DateTime _birthDate = DateTime.now().subtract(const Duration(days: 365));
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.purple, Colors.pink],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.child_care, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Добавить ребенка',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Имя ребенка',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedGender,
            decoration: const InputDecoration(
              labelText: 'Пол',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.wc),
            ),
            onChanged: (value) {
              setState(() {
                _selectedGender = value!;
              });
            },
            items: const [
              DropdownMenuItem(
                value: 'male',
                child: Text('Мальчик'),
              ),
              DropdownMenuItem(
                value: 'female',
                child: Text('Девочка'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _birthDate,
                firstDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() {
                  _birthDate = picked;
                });
              }
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Дата рождения',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
              child: Text(
                '${_birthDate.day.toString().padLeft(2, '0')}.${_birthDate.month.toString().padLeft(2, '0')}.${_birthDate.year}',
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _heightController,
                  decoration: const InputDecoration(
                    labelText: 'Рост (см)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.height),
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
                    prefixIcon: Icon(Icons.monitor_weight),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Отмена'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading || _nameController.text.isEmpty
                      ? null
                      : _saveChild,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Сохранить'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _saveChild() async {
    setState(() => _isLoading = true);

    try {
      await FirebaseService.addChild(
        name: _nameController.text,
        birthDate: _birthDate,
        gender: _selectedGender,
        height: double.tryParse(_heightController.text) ?? 0.0,
        weight: double.tryParse(_weightController.text) ?? 0.0,
      );
      
      widget.onSave();
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ребенок добавлен успешно!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

// Диалог редактирования ребенка
class _EditChildDialog extends StatefulWidget {
  final ChildProfile child;
  final VoidCallback onSave;

  const _EditChildDialog({required this.child, required this.onSave});

  @override
  State<_EditChildDialog> createState() => _EditChildDialogState();
}

class _EditChildDialogState extends State<_EditChildDialog> {
  late TextEditingController _nameController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late String _selectedGender;
  late DateTime _birthDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.child.name);
    _heightController = TextEditingController(text: widget.child.height.toString());
    _weightController = TextEditingController(text: widget.child.weight.toString());
    _selectedGender = widget.child.gender;
    _birthDate = widget.child.birthDate;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.blue, Colors.cyan],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.edit, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Редактировать данные',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Имя ребенка',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedGender,
            decoration: const InputDecoration(
              labelText: 'Пол',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.wc),
            ),
            onChanged: (value) {
              setState(() {
                _selectedGender = value!;
              });
            },
            items: const [
              DropdownMenuItem(
                value: 'male',
                child: Text('Мальчик'),
              ),
              DropdownMenuItem(
                value: 'female',
                child: Text('Девочка'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _birthDate,
                firstDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() {
                  _birthDate = picked;
                });
              }
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Дата рождения',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
              child: Text(
                '${_birthDate.day.toString().padLeft(2, '0')}.${_birthDate.month.toString().padLeft(2, '0')}.${_birthDate.year}',
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _heightController,
                  decoration: const InputDecoration(
                    labelText: 'Рост (см)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.height),
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
                    prefixIcon: Icon(Icons.monitor_weight),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // Открываем диалог добавления измерения
              _showAddMeasurementDialog();
            },
            icon: const Icon(Icons.add),
            label: const Text('Добавить новое измерение'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Отмена'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading || _nameController.text.isEmpty
                      ? null
                      : _saveChild,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Сохранить'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddMeasurementDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddMeasurementDialog(
        childId: widget.child.id,
        currentHeight: widget.child.height,
        currentWeight: widget.child.weight,
        onSave: () {
          widget.onSave();
        },
      ),
    );
  }

  Future<void> _saveChild() async {
    setState(() => _isLoading = true);

    try {
      await FirebaseService.updateChildProfile(widget.child.id, {
        'name': _nameController.text,
        'gender': _selectedGender,
        'birthDate': Timestamp.fromDate(_birthDate),
        'height': double.tryParse(_heightController.text) ?? widget.child.height,
        'weight': double.tryParse(_weightController.text) ?? widget.child.weight,
      });
      
      widget.onSave();
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Данные обновлены успешно!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

// Диалог добавления вехи развития
class _AddMilestoneDialog extends StatefulWidget {
  final Function(Milestone) onSave;

  const _AddMilestoneDialog({required this.onSave});

  @override
  State<_AddMilestoneDialog> createState() => _AddMilestoneDialogState();
}

class _AddMilestoneDialogState extends State<_AddMilestoneDialog> {
  final _titleController = TextEditingController();
  final _categoryController = TextEditingController();
  final _minAgeController = TextEditingController();
  final _maxAgeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.orange, Colors.red],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.flag, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Добавить веху развития',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Название вехи',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.flag),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _categoryController,
            decoration: const InputDecoration(
              labelText: 'Категория',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.category),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minAgeController,
                  decoration: const InputDecoration(
                    labelText: 'Мин. возраст (мес)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _maxAgeController,
                  decoration: const InputDecoration(
                    labelText: 'Макс. возраст (мес)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Отмена'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _titleController.text.isNotEmpty &&
                          _categoryController.text.isNotEmpty
                      ? () {
                          final milestone = Milestone(
                            _titleController.text,
                            _categoryController.text,
                            int.tryParse(_minAgeController.text) ?? 0,
                            int.tryParse(_maxAgeController.text) ?? 12,
                            false,
                          );
                          widget.onSave(milestone);
                          Navigator.pop(context);
                        }
                      : null,
                  child: const Text('Добавить'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Диалог добавления измерения
class _AddMeasurementDialog extends StatefulWidget {
  final String childId;
  final double currentHeight;
  final double currentWeight;
  final VoidCallback onSave;

  const _AddMeasurementDialog({
    required this.childId,
    required this.currentHeight,
    required this.currentWeight,
    required this.onSave,
  });

  @override
  State<_AddMeasurementDialog> createState() => _AddMeasurementDialogState();
}

class _AddMeasurementDialogState extends State<_AddMeasurementDialog> {
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _heightController = TextEditingController(text: widget.currentHeight.toString());
    _weightController = TextEditingController(text: widget.currentWeight.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.green, Colors.teal],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.straighten, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Новое измерение',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() {
                  _selectedDate = picked;
                });
              }
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Дата измерения',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
              child: Text(
                '${_selectedDate.day.toString().padLeft(2, '0')}.${_selectedDate.month.toString().padLeft(2, '0')}.${_selectedDate.year}',
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _heightController,
                  decoration: const InputDecoration(
                    labelText: 'Рост (см)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.height),
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
                    prefixIcon: Icon(Icons.monitor_weight),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Заметки (необязательно)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.note),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Отмена'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveMeasurement,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Сохранить'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _saveMeasurement() async {
    setState(() => _isLoading = true);

    try {
      final measurement = GrowthMeasurement(
        id: '', // Firebase сгенерирует ID
        childId: widget.childId,
        date: _selectedDate,
        height: double.tryParse(_heightController.text) ?? widget.currentHeight,
        weight: double.tryParse(_weightController.text) ?? widget.currentWeight,
        notes: _notesController.text,
      );

      await FirebaseService.addGrowthMeasurement(measurement);
      
      widget.onSave();
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Измерение добавлено успешно!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}