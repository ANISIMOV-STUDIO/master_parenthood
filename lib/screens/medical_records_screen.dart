// lib/screens/medical_records_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/firebase_service.dart';

class MedicalRecordsScreen extends StatefulWidget {
  final String childId;
  
  const MedicalRecordsScreen({
    super.key,
    required this.childId,
  });

  @override
  State<MedicalRecordsScreen> createState() => _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState extends State<MedicalRecordsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _headerController;
  
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  MedicalRecordType? _selectedType;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _headerController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFE),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(child: _buildSearchAndFilter()),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllRecordsTab(),
                _buildActivePrescriptionsTab(),
                _buildMedicalSummaryTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2E7D32),
                Color(0xFF388E3C),
                Color(0xFF4CAF50),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.medical_services,
                          color: Colors.white,
                          size: 28,
                        ),
                      ).animate().scale(delay: 200.ms),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Медицинские записи',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ).animate().slideX(delay: 300.ms),
                            Text(
                              'История здоровья',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 16,
                              ),
                            ).animate().slideX(delay: 400.ms),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    indicatorColor: Colors.white,
                    indicatorWeight: 3,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    tabs: const [
                      Tab(text: 'Все записи'),
                      Tab(text: 'Назначения'),
                      Tab(text: 'Сводка'),
                    ],
                  ).animate().slideY(delay: 500.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Поиск
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск по симптомам, диагнозам...',
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ).animate().slideY(delay: 600.ms),
          
          const SizedBox(height: 12),
          
          // Фильтр по типу
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip('Все', null),
                ...MedicalRecordType.values.map((type) => 
                  _buildFilterChip(_getTypeDisplayName(type), type)
                ),
              ],
            ),
          ).animate().slideY(delay: 700.ms),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, MedicalRecordType? type) {
    final isSelected = _selectedType == type;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF2E7D32),
            fontWeight: FontWeight.w500,
          ),
        ),
        selected: isSelected,
        selectedColor: const Color(0xFF2E7D32),
        backgroundColor: Colors.white,
        onSelected: (selected) {
          setState(() {
            _selectedType = selected ? type : null;
          });
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? const Color(0xFF2E7D32) : Colors.grey.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }

  Widget _buildAllRecordsTab() {
    return StreamBuilder<List<MedicalRecord>>(
      stream: _selectedType != null 
          ? FirebaseService.getMedicalRecordsByTypeStream(widget.childId, _selectedType!)
          : FirebaseService.getMedicalRecordsStream(widget.childId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        List<MedicalRecord> records = snapshot.data ?? [];
        
        // Применяем поисковый фильтр
        if (_searchQuery.isNotEmpty) {
          records = records.where((record) =>
              record.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              record.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (record.diagnosis?.toLowerCase().contains(_searchQuery.toLowerCase()) == true) ||
              record.symptoms.any((symptom) => 
                  symptom.toLowerCase().contains(_searchQuery.toLowerCase()))).toList();
        }

        if (records.isEmpty) {
          return _buildEmptyState(
            icon: Icons.medical_services,
            title: _searchQuery.isNotEmpty || _selectedType != null 
                ? 'Записи не найдены'
                : 'Нет медицинских записей',
            subtitle: _searchQuery.isNotEmpty || _selectedType != null
                ? 'Попробуйте изменить фильтры поиска'
                : 'Добавьте первую медицинскую запись',
            color: Colors.grey,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: records.length,
          itemBuilder: (context, index) {
            return _buildMedicalRecordCard(records[index], index);
          },
        );
      },
    );
  }

  Widget _buildActivePrescriptionsTab() {
    return FutureBuilder<List<Prescription>>(
      future: FirebaseService.getActivePrescriptions(widget.childId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final prescriptions = snapshot.data ?? [];

        if (prescriptions.isEmpty) {
          return _buildEmptyState(
            icon: Icons.medication,
            title: 'Нет активных назначений',
            subtitle: 'Назначения появятся после добавления медицинских записей',
            color: Colors.blue,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: prescriptions.length,
          itemBuilder: (context, index) {
            return _buildPrescriptionCard(prescriptions[index], index);
          },
        );
      },
    );
  }

  Widget _buildMedicalSummaryTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: FirebaseService.getMedicalSummary(widget.childId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData) {
          return _buildEmptyState(
            icon: Icons.analytics,
            title: 'Нет данных для сводки',
            subtitle: 'Добавьте медицинские записи для анализа',
            color: Colors.orange,
          );
        }

        final summary = snapshot.data!;
        return _buildSummaryContent(summary);
      },
    );
  }

  Widget _buildMedicalRecordCard(MedicalRecord record, int index) {
    Color typeColor = _getTypeColor(record.type);
    IconData typeIcon = _getTypeIcon(record.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showRecordDetails(record),
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
                        color: typeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(typeIcon, color: typeColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            record.typeDisplayName,
                            style: TextStyle(
                              color: typeColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatDate(record.date),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  record.description,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (record.diagnosis != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Диагноз: ${record.diagnosis}',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                if (record.prescriptions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.medication, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${record.prescriptions.length} назначений',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
                if (record.doctorName != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.person, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        record.doctorName!,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ).animate(delay: Duration(milliseconds: 100 * index)).slideX();
  }

  Widget _buildPrescriptionCard(Prescription prescription, int index) {
    final isActive = !prescription.isCompleted && 
                    (prescription.endDate == null || prescription.endDate!.isAfter(DateTime.now()));
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? Colors.green.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
                    color: (isActive ? Colors.green : Colors.grey).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.medication,
                    color: isActive ? Colors.green : Colors.grey,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prescription.medicationName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isActive ? 'Активное' : 'Завершено',
                        style: TextStyle(
                          color: isActive ? Colors.green : Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildPrescriptionDetail('Дозировка', prescription.dosage),
            _buildPrescriptionDetail('Частота', prescription.frequency),
            _buildPrescriptionDetail('Длительность', prescription.duration),
            if (prescription.instructions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Инструкции:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                prescription.instructions,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'С ${_formatDate(prescription.startDate)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                if (prescription.endDate != null) ...[
                  Text(
                    ' до ${_formatDate(prescription.endDate!)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    ).animate(delay: Duration(milliseconds: 100 * index)).slideX();
  }

  Widget _buildPrescriptionDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryContent(Map<String, dynamic> summary) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Статистика
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Статистика за год',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildSummaryStatItem(
                      icon: Icons.medical_services,
                      title: 'Всего записей',
                      value: summary['totalRecords'].toString(),
                      color: Colors.blue,
                    ),
                    _buildSummaryStatItem(
                      icon: Icons.vaccines,
                      title: 'Прививок',
                      value: summary['totalVaccinations'].toString(),
                      color: Colors.green,
                    ),
                  ],
                ),
              ],
            ),
          ).animate().slideY(),
          
          const SizedBox(height: 16),
          
          // Распределение по типам
          if (summary['recordsByType'] != null && 
              (summary['recordsByType'] as Map).isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Распределение по типам',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...(summary['recordsByType'] as Map<String, dynamic>).entries.map(
                    (entry) => _buildTypeStatRow(entry.key, entry.value),
                  ),
                ],
              ),
            ).animate().slideY(delay: 200.ms),
            
            const SizedBox(height: 16),
          ],
          
          // Активные назначения
          if (summary['activePrescriptions'] != null && 
              (summary['activePrescriptions'] as List).isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Активные назначения',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...(summary['activePrescriptions'] as List<Prescription>).take(3).map(
                    (prescription) => _buildActivePrescriptionRow(prescription),
                  ),
                  if ((summary['activePrescriptions'] as List).length > 3) ...[
                    const SizedBox(height: 8),
                    Text(
                      'И ещё ${(summary['activePrescriptions'] as List).length - 3} назначений...',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ).animate().slideY(delay: 400.ms),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryStatItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTypeStatRow(String type, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            type,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Color(0xFF2E7D32),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivePrescriptionRow(Prescription prescription) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.medication, size: 16, color: Colors.green[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              prescription.medicationName,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            prescription.frequency,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 64, color: color),
          ).animate().scale(),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ).animate().slideY(delay: 200.ms),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ).animate().slideY(delay: 300.ms),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: _showAddRecordDialog,
      backgroundColor: const Color(0xFF2E7D32),
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text(
        'Добавить запись',
        style: TextStyle(color: Colors.white),
      ),
    ).animate().scale(delay: 800.ms);
  }

  void _showRecordDetails(MedicalRecord record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MedicalRecordDetailsSheet(record: record),
    );
  }

  void _showAddRecordDialog() {
    showDialog(
      context: context,
      builder: (context) => AddMedicalRecordDialog(childId: widget.childId),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  String _getTypeDisplayName(MedicalRecordType type) {
    switch (type) {
      case MedicalRecordType.checkup:
        return 'Осмотры';
      case MedicalRecordType.illness:
        return 'Болезни';
      case MedicalRecordType.emergency:
        return 'Экстренные';
      case MedicalRecordType.consultation:
        return 'Консультации';
      case MedicalRecordType.hospitalization:
        return 'Госпитализации';
      case MedicalRecordType.surgery:
        return 'Операции';
      case MedicalRecordType.allergy:
        return 'Аллергии';
      case MedicalRecordType.other:
        return 'Другое';
    }
  }

  Color _getTypeColor(MedicalRecordType type) {
    switch (type) {
      case MedicalRecordType.checkup:
        return Colors.blue;
      case MedicalRecordType.illness:
        return Colors.orange;
      case MedicalRecordType.emergency:
        return Colors.red;
      case MedicalRecordType.consultation:
        return Colors.purple;
      case MedicalRecordType.hospitalization:
        return Colors.indigo;
      case MedicalRecordType.surgery:
        return Colors.pink;
      case MedicalRecordType.allergy:
        return Colors.amber;
      case MedicalRecordType.other:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(MedicalRecordType type) {
    switch (type) {
      case MedicalRecordType.checkup:
        return Icons.health_and_safety;
      case MedicalRecordType.illness:
        return Icons.sick;
      case MedicalRecordType.emergency:
        return Icons.emergency;
      case MedicalRecordType.consultation:
        return Icons.psychology;
      case MedicalRecordType.hospitalization:
        return Icons.local_hospital;
      case MedicalRecordType.surgery:
        return Icons.medical_services;
      case MedicalRecordType.allergy:
        return Icons.warning;
      case MedicalRecordType.other:
        return Icons.description;
    }
  }
}

// Детальный просмотр медицинской записи
class MedicalRecordDetailsSheet extends StatelessWidget {
  final MedicalRecord record;

  const MedicalRecordDetailsSheet({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      minChildSize: 0.6,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Заголовок
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getTypeColor().withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_getTypeIcon(), color: _getTypeColor(), size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              record.title,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getTypeColor().withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                record.typeDisplayName,
                                style: TextStyle(
                                  color: _getTypeColor(),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Основная информация
                  _buildDetailSection('Описание', record.description),
                  
                  if (record.diagnosis != null)
                    _buildDetailSection('Диагноз', record.diagnosis!),
                  
                  if (record.symptoms.isNotEmpty)
                    _buildDetailSection('Симптомы', record.symptoms.join(', ')),
                  
                  _buildDetailSection('Дата', _formatDate(record.date)),
                  
                  if (record.doctorName != null)
                    _buildDetailSection('Врач', '${record.doctorName}${record.doctorSpecialty != null ? ' (${record.doctorSpecialty})' : ''}'),
                  
                  if (record.clinic != null)
                    _buildDetailSection('Клиника', record.clinic!),
                  
                  // Показатели
                  if (record.temperature != null || record.weight != null || record.height != null) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Показатели',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (record.temperature != null)
                      _buildMeasurementRow('Температура', '${record.temperature}°C', Icons.thermostat),
                    if (record.weight != null)
                      _buildMeasurementRow('Вес', '${record.weight} кг', Icons.monitor_weight),
                    if (record.height != null)
                      _buildMeasurementRow('Рост', '${record.height} см', Icons.height),
                  ],
                  
                  // Назначения
                  if (record.prescriptions.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Назначения',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...record.prescriptions.map((prescription) => 
                      _buildPrescriptionDetails(prescription)),
                  ],
                  
                  // Рекомендации
                  if (record.recommendations.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Рекомендации',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...record.recommendations.map((recommendation) => 
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                            Expanded(child: Text(recommendation)),
                          ],
                        ),
                      )),
                  ],
                  
                  if (record.notes != null && record.notes!.isNotEmpty)
                    _buildDetailSection('Заметки', record.notes!),
                  
                  const SizedBox(height: 24),
                  
                  // Кнопки действий
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            // Редактирование записи
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Редактировать'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            // Экспорт записи
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2E7D32),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Экспорт'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionDetails(Prescription prescription) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            prescription.medicationName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text('${prescription.dosage}, ${prescription.frequency}'),
          if (prescription.instructions.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              prescription.instructions,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getTypeColor() {
    switch (record.type) {
      case MedicalRecordType.checkup:
        return Colors.blue;
      case MedicalRecordType.illness:
        return Colors.orange;
      case MedicalRecordType.emergency:
        return Colors.red;
      case MedicalRecordType.consultation:
        return Colors.purple;
      case MedicalRecordType.hospitalization:
        return Colors.indigo;
      case MedicalRecordType.surgery:
        return Colors.pink;
      case MedicalRecordType.allergy:
        return Colors.amber;
      case MedicalRecordType.other:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon() {
    switch (record.type) {
      case MedicalRecordType.checkup:
        return Icons.health_and_safety;
      case MedicalRecordType.illness:
        return Icons.sick;
      case MedicalRecordType.emergency:
        return Icons.emergency;
      case MedicalRecordType.consultation:
        return Icons.psychology;
      case MedicalRecordType.hospitalization:
        return Icons.local_hospital;
      case MedicalRecordType.surgery:
        return Icons.medical_services;
      case MedicalRecordType.allergy:
        return Icons.warning;
      case MedicalRecordType.other:
        return Icons.description;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}

// Диалог добавления записи (заглушка)
class AddMedicalRecordDialog extends StatelessWidget {
  final String childId;

  const AddMedicalRecordDialog({super.key, required this.childId});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Добавить медицинскую запись'),
      content: const Text('Форма добавления записи будет реализована далее'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Закрыть'),
        ),
      ],
    );
  }
}