// lib/screens/allergy_tracker_screen.dart
import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

class AllergyTrackerScreen extends StatefulWidget {
  final String childId;

  const AllergyTrackerScreen({Key? key, required this.childId}) : super(key: key);

  @override
  State<AllergyTrackerScreen> createState() => _AllergyTrackerScreenState();
}

class _AllergyTrackerScreenState extends State<AllergyTrackerScreen>
    with TickerProviderStateMixin {
  
  late TabController _tabController;
  late AnimationController _emergencyController;
  late Animation<double> _emergencyPulseAnimation;
  
  List<AllergyInfo> _allAllergies = [];
  List<AllergyInfo> _emergencyAllergies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _emergencyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _emergencyPulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _emergencyController,
        curve: Curves.easeInOut,
      ),
    );
    
    _loadAllergies();
    _emergencyController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emergencyController.dispose();
    super.dispose();
  }

  Future<void> _loadAllergies() async {
    setState(() => _isLoading = true);
    
    try {
      // Подписываемся на изменения аллергий
      FirebaseService.getAllergiesStream(widget.childId).listen((allergies) {
        setState(() {
          _allAllergies = allergies;
        });
      });
      
      // Загружаем экстренные аллергии
      final emergencyAllergies = await FirebaseService.getEmergencyAllergies(widget.childId);
      
      setState(() {
        _emergencyAllergies = emergencyAllergies;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки аллергий: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.red[700]!,
              Colors.red[500]!,
              Colors.red[300]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              if (_emergencyAllergies.isNotEmpty) _buildEmergencyAlert(),
              _buildStatsRow(),
              _buildTabBar(),
              Expanded(
                child: _buildTabBarView(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddAllergyDialog,
        backgroundColor: Colors.red[600],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Добавить аллергию'),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Трекер аллергий',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Безопасность вашего ребенка',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _showEmergencyCard,
            icon: const Icon(Icons.medical_services, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyAlert() {
    return AnimatedBuilder(
      animation: _emergencyPulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _emergencyPulseAnimation.value,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red[900],
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.3),
                  blurRadius: 15,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_rounded,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ВНИМАНИЕ!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_emergencyAllergies.length} серьезных аллергий',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _showEmergencyCard,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red[900],
                  ),
                  child: const Text('ПОКАЗАТЬ'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsRow() {
    final totalAllergies = _allAllergies.length;
    final emergencyCount = _emergencyAllergies.length;
    final mildCount = _allAllergies
        .where((a) => a.reactionType == AllergyReactionType.mild)
        .length;

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Всего аллергий',
            '$totalAllergies',
            Icons.warning,
            Colors.orange,
          ),
          _buildStatItem(
            'Опасные',
            '$emergencyCount',
            Icons.dangerous,
            Colors.red,
          ),
          _buildStatItem(
            'Легкие',
            '$mildCount',
            Icons.info,
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
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
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(15),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Colors.red[600],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.red[700],
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Все аллергии'),
          Tab(text: 'Опасные'),
          Tab(text: 'История'),
        ],
      ),
    );
  }

  Widget _buildTabBarView() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildAllAllergiesList(),
          _buildEmergencyAllergiesList(),
          _buildAllergyHistory(),
        ],
      ),
    );
  }

  Widget _buildAllAllergiesList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_allAllergies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sentiment_satisfied, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 20),
            Text(
              'Нет известных аллергий',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 10),
            Text(
              'Это хорошо! Добавляйте при необходимости',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _allAllergies.length,
      itemBuilder: (context, index) {
        final allergy = _allAllergies[index];
        return _buildAllergyCard(allergy);
      },
    );
  }

  Widget _buildEmergencyAllergiesList() {
    if (_emergencyAllergies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 20),
            Text(
              'Нет опасных аллергий',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 10),
            Text(
              'Ваш ребенок в безопасности',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _emergencyAllergies.length,
      itemBuilder: (context, index) {
        final allergy = _emergencyAllergies[index];
        return _buildEmergencyAllergyCard(allergy);
      },
    );
  }

  Widget _buildAllergyHistory() {
    final inactiveAllergies = _allAllergies.where((a) => !a.isActive).toList();
    
    if (inactiveAllergies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 20),
            Text(
              'Нет истории аллергий',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: inactiveAllergies.length,
      itemBuilder: (context, index) {
        final allergy = inactiveAllergies[index];
        return _buildHistoryAllergyCard(allergy);
      },
    );
  }

  Widget _buildAllergyCard(AllergyInfo allergy) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: CircleAvatar(
          backgroundColor: Color(allergy.reactionTypeColorHex),
          child: Icon(
            _getReactionIcon(allergy.reactionType),
            color: Colors.white,
          ),
        ),
        title: Text(
          allergy.allergen,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            Text(allergy.reactionTypeDisplayName),
            if (allergy.symptoms.isNotEmpty)
              Text('Симптомы: ${allergy.symptoms.join(", ")}'),
            Text('Впервые: ${_formatDate(allergy.firstReactionDate)}'),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Редактировать')),
            const PopupMenuItem(value: 'deactivate', child: Text('Деактивировать')),
          ],
          onSelected: (value) {
            if (value == 'deactivate') {
              _deactivateAllergy(allergy);
            }
          },
        ),
      ),
    );
  }

  Widget _buildEmergencyAllergyCard(AllergyInfo allergy) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.red[700]!, width: 2),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.red[50]!, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(15),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red[700],
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.3),
                  blurRadius: 10,
                ),
              ],
            ),
            child: const Icon(
              Icons.dangerous,
              color: Colors.white,
              size: 24,
            ),
          ),
          title: Text(
            allergy.allergen.toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red[900],
              fontSize: 16,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red[700],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  allergy.reactionTypeDisplayName.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (allergy.emergencyMedication?.isNotEmpty == true)
                Text(
                  'Лекарство: ${allergy.emergencyMedication!}',
                  style: TextStyle(
                    color: Colors.red[800],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              if (allergy.symptoms.isNotEmpty)
                Text('Симптомы: ${allergy.symptoms.join(", ")}'),
            ],
          ),
          trailing: IconButton(
            onPressed: () => _showEmergencyDetails(allergy),
            icon: Icon(Icons.info, color: Colors.red[700]),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryAllergyCard(AllergyInfo allergy) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      color: Colors.grey[100],
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: CircleAvatar(
          backgroundColor: Colors.grey[400],
          child: const Icon(Icons.history, color: Colors.white),
        ),
        title: Text(
          allergy.allergen,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        subtitle: Text('Деактивирована ${_formatDate(allergy.updatedAt)}'),
        trailing: const Icon(Icons.check, color: Colors.green),
      ),
    );
  }

  IconData _getReactionIcon(AllergyReactionType type) {
    switch (type) {
      case AllergyReactionType.mild:
        return Icons.info;
      case AllergyReactionType.moderate:
        return Icons.warning;
      case AllergyReactionType.severe:
        return Icons.error;
      case AllergyReactionType.anaphylaxis:
        return Icons.dangerous;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  // Действия
  void _showAddAllergyDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddAllergyDialog(childId: widget.childId),
    ).then((_) => _loadAllergies());
  }

  void _showEmergencyCard() {
    if (_emergencyAllergies.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Нет опасных аллергий'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.medical_services, color: Colors.red[700]),
            const SizedBox(width: 10),
            const Text('ЭКСТРЕННАЯ КАРТА'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _emergencyAllergies.length,
            itemBuilder: (context, index) {
              final allergy = _emergencyAllergies[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red[300]!),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      allergy.allergen.toUpperCase(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[900],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text('Тип: ${allergy.reactionTypeDisplayName}'),
                    if (allergy.emergencyMedication?.isNotEmpty == true)
                                    Text(
                'Лекарство: ${allergy.emergencyMedication!}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    if (allergy.symptoms.isNotEmpty)
                      Text('Симптомы: ${allergy.symptoms.join(", ")}'),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _showEmergencyDetails(AllergyInfo allergy) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          allergy.allergen.toUpperCase(),
          style: TextStyle(color: Colors.red[900]),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Тип реакции: ${allergy.reactionTypeDisplayName}'),
            const SizedBox(height: 10),
            if (allergy.emergencyMedication?.isNotEmpty == true) ...[
              const Text(
                'Экстренное лекарство:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(allergy.emergencyMedication!),
              const SizedBox(height: 10),
            ],
            if (allergy.symptoms.isNotEmpty) ...[
              const Text(
                'Симптомы:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(allergy.symptoms.join(", ")),
              const SizedBox(height: 10),
            ],
            if (allergy.doctorNotes?.isNotEmpty == true) ...[
              const Text(
                'Заметки врача:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(allergy.doctorNotes!),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  Future<void> _deactivateAllergy(AllergyInfo allergy) async {
    try {
      await FirebaseService.deactivateAllergy(allergy.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Аллергия деактивирована')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }
}

// Диалог добавления аллергии
class _AddAllergyDialog extends StatefulWidget {
  final String childId;

  const _AddAllergyDialog({required this.childId});

  @override
  State<_AddAllergyDialog> createState() => _AddAllergyDialogState();
}

class _AddAllergyDialogState extends State<_AddAllergyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _allergenController = TextEditingController();
  final _medicationController = TextEditingController();
  final _notesController = TextEditingController();
  
  AllergyReactionType _reactionType = AllergyReactionType.mild;
  List<String> _symptoms = [];
  DateTime _firstReactionDate = DateTime.now();
  
  final List<String> _commonSymptoms = [
    'Сыпь',
    'Зуд',
    'Отек',
    'Затрудненное дыхание',
    'Тошнота',
    'Рвота',
    'Диарея',
    'Головокружение',
    'Потеря сознания',
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Добавить аллергию'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _allergenController,
                decoration: const InputDecoration(
                  labelText: 'Аллерген*',
                  hintText: 'Например: орехи, молоко, яйца',
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Введите аллерген';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              
              DropdownButtonFormField<AllergyReactionType>(
                value: _reactionType,
                decoration: const InputDecoration(labelText: 'Тип реакции*'),
                items: AllergyReactionType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _reactionType = value!;
                  });
                },
              ),
              const SizedBox(height: 15),
              
              // Симптомы
              const Text(
                'Симптомы:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Wrap(
                spacing: 8,
                children: _commonSymptoms.map((symptom) {
                  final isSelected = _symptoms.contains(symptom);
                  return FilterChip(
                    label: Text(symptom),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _symptoms.add(symptom);
                        } else {
                          _symptoms.remove(symptom);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 15),
              
              if (_reactionType == AllergyReactionType.severe ||
                  _reactionType == AllergyReactionType.anaphylaxis) ...[
                TextFormField(
                  controller: _medicationController,
                  decoration: const InputDecoration(
                    labelText: 'Экстренное лекарство',
                    hintText: 'Например: EpiPen, Супрастин',
                  ),
                ),
                const SizedBox(height: 15),
              ],
              
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Дополнительные заметки',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _saveAllergy,
          child: const Text('Сохранить'),
        ),
      ],
    );
  }

  Future<void> _saveAllergy() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final allergy = AllergyInfo(
        id: '',
        childId: widget.childId,
        allergen: _allergenController.text.trim(),
        reactionType: _reactionType,
        symptoms: _symptoms,
        firstReactionDate: _firstReactionDate,
        emergencyMedication: _medicationController.text.trim().isEmpty 
            ? null 
            : _medicationController.text.trim(),
        avoidFoods: [],
        isConfirmedByDoctor: false,
        doctorNotes: _notesController.text.trim().isEmpty 
            ? null 
            : _notesController.text.trim(),
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await FirebaseService.createAllergyInfo(allergy);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Аллергия добавлена')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }
}