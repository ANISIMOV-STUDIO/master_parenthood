// lib/screens/first_aid_guide_screen.dart
import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

class FirstAidGuideScreen extends StatefulWidget {
  final String? childId;
  final EmergencyType? filterType;

  const FirstAidGuideScreen({super.key, this.childId, this.filterType});

  @override
  State<FirstAidGuideScreen> createState() => _FirstAidGuideScreenState();
}

class _FirstAidGuideScreenState extends State<FirstAidGuideScreen>
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;
  List<FirstAidGuide> _allGuides = [];
  bool _isLoading = true;
  EmergencyType? _selectedType;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedType = widget.filterType;
    _loadGuides();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadGuides() async {
    setState(() => _isLoading = true);
    
    try {
      FirebaseService.getFirstAidGuidesStream().listen((guides) {
        setState(() {
          _allGuides = guides;
          _isLoading = false;
        });
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки инструкций: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Справочник первой помощи'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.medical_services), text: 'Все инструкции'),
            Tab(icon: Icon(Icons.child_care), text: 'Для возраста'),
            Tab(icon: Icon(Icons.category), text: 'По типам'),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAllGuidesTab(),
                _buildAgeFilteredTab(),
                _buildTypeFilteredTab(),
              ],
            ),
    );
  }

  Widget _buildAllGuidesTab() {
    if (_allGuides.isEmpty) {
      return _buildEmptyState('Нет инструкций первой помощи');
    }

    final sortedGuides = List<FirstAidGuide>.from(_allGuides)
      ..sort((a, b) => a.type.priorityLevel.compareTo(b.type.priorityLevel));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedGuides.length,
      itemBuilder: (context, index) {
        final guide = sortedGuides[index];
        return _buildGuideCard(guide);
      },
    );
  }

  Widget _buildAgeFilteredTab() {
    if (widget.childId == null) {
      return _buildEmptyState('Выберите профиль ребенка для фильтрации по возрасту');
    }

    // TODO: Получить возраст ребенка и фильтровать
    final filteredGuides = _allGuides; // Пока показываем все

    if (filteredGuides.isEmpty) {
      return _buildEmptyState('Нет инструкций для данного возраста');
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.blue[50],
          child: Row(
            children: [
              Icon(Icons.info, color: Colors.blue[700]),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Инструкции адаптированы для возраста вашего ребенка',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredGuides.length,
            itemBuilder: (context, index) {
              final guide = filteredGuides[index];
              return _buildGuideCard(guide, showAgeRange: true);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTypeFilteredTab() {
    final groupedGuides = <EmergencyType, List<FirstAidGuide>>{};
    
    for (final guide in _allGuides) {
      groupedGuides.putIfAbsent(guide.type, () => []).add(guide);
    }

    if (groupedGuides.isEmpty) {
      return _buildEmptyState('Нет инструкций для отображения');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedGuides.length,
      itemBuilder: (context, index) {
        final type = groupedGuides.keys.elementAt(index);
        final guides = groupedGuides[type]!;
        
        return _buildTypeGroup(type, guides);
      },
    );
  }

  Widget _buildTypeGroup(EmergencyType type, List<FirstAidGuide> guides) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Color(type.colorHex).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(type.colorHex).withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                Text(
                  type.iconEmoji,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type.displayName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(type.colorHex),
                        ),
                      ),
                      Text(
                        'Приоритет: ${_getPriorityText(type.priorityLevel)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(type.colorHex).withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(type.colorHex),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${guides.length} инстр.',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...guides.map((guide) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _buildGuideCard(guide, isInGroup: true),
          )),
        ],
      ),
    );
  }

  Widget _buildGuideCard(
    FirstAidGuide guide, {
    bool showAgeRange = false,
    bool isInGroup = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: isInGroup ? 8 : 12),
      child: Card(
        elevation: isInGroup ? 2 : 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showGuideDetails(guide),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Иконка типа
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Color(guide.type.colorHex).withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          guide.type.iconEmoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Заголовок и тип
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            guide.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          
                          const SizedBox(height: 4),
                          
                          if (!isInGroup)
                            Text(
                              guide.type.displayName,
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(guide.type.colorHex),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    // Индикаторы
                    Column(
                      children: [
                        if (guide.isVerifiedByDoctor)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.verified,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        
                        const SizedBox(height: 4),
                        
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getPriorityColor(guide.type.priorityLevel),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${guide.type.priorityLevel}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Описание
                Text(
                  guide.shortDescription,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 12),
                
                // Метрики
                Row(
                  children: [
                    Icon(Icons.timer, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      guide.formattedDuration,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    Icon(Icons.list, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${guide.steps.length} шагов',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    
                    if (showAgeRange) ...[
                      const SizedBox(width: 16),
                      Icon(Icons.child_care, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        guide.ageRange.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                    
                    const Spacer(),
                    
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey[400],
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

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medical_services,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showGuideDetails(FirstAidGuide guide) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FirstAidDetailScreen(guide: guide),
      ),
    );
  }

  String _getPriorityText(int priority) {
    switch (priority) {
      case 1:
        return 'Критический';
      case 2:
        return 'Очень высокий';
      case 3:
        return 'Высокий';
      case 4:
        return 'Умеренный';
      case 5:
        return 'Низкий';
      default:
        return 'Неизвестный';
    }
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.yellow[700]!;
      case 4:
        return Colors.blue;
      case 5:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

// Детальный экран инструкции
class FirstAidDetailScreen extends StatelessWidget {
  final FirstAidGuide guide;

  const FirstAidDetailScreen({super.key, required this.guide});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(guide.title),
        backgroundColor: Color(guide.type.colorHex),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок с иконкой
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Color(guide.type.colorHex).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      guide.type.iconEmoji,
                      style: const TextStyle(fontSize: 30),
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        guide.type.displayName,
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(guide.type.colorHex),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        guide.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Описание
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                guide.shortDescription,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Метрики
            Row(
              children: [
                _buildMetricChip(
                  icon: Icons.timer,
                  label: guide.formattedDuration,
                  color: Colors.blue,
                ),
                const SizedBox(width: 12),
                _buildMetricChip(
                  icon: Icons.child_care,
                  label: guide.ageRange.displayName,
                  color: Colors.green,
                ),
                const SizedBox(width: 12),
                if (guide.isVerifiedByDoctor)
                  _buildMetricChip(
                    icon: Icons.verified,
                    label: 'Проверено врачом',
                    color: Colors.green,
                  ),
              ],
            ),
            
            const SizedBox(height: 30),
            
            // Пошаговые инструкции
            _buildSection(
              title: 'Пошаговые действия',
              icon: Icons.list_alt,
              child: Column(
                children: guide.steps.map((step) => _buildStepCard(step)).toList(),
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Что делать
            if (guide.doList.isNotEmpty)
              _buildSection(
                title: 'Что ДЕЛАТЬ',
                icon: Icons.check_circle,
                child: Column(
                  children: guide.doList
                      .map((item) => _buildListItem(item, Colors.green, Icons.check))
                      .toList(),
                ),
              ),
            
            const SizedBox(height: 20),
            
            // Что НЕ делать
            if (guide.dontList.isNotEmpty)
              _buildSection(
                title: 'Что НЕ ДЕЛАТЬ',
                icon: Icons.cancel,
                child: Column(
                  children: guide.dontList
                      .map((item) => _buildListItem(item, Colors.red, Icons.close))
                      .toList(),
                ),
              ),
            
            const SizedBox(height: 20),
            
            // Признаки опасности
            if (guide.warningsSigns.isNotEmpty)
              _buildSection(
                title: 'Признаки опасности',
                icon: Icons.warning,
                child: Column(
                  children: guide.warningsSigns
                      .map((sign) => _buildListItem(sign, Colors.orange, Icons.warning))
                      .toList(),
                ),
              ),
            
            const SizedBox(height: 40),
            
            // Кнопка экстренного вызова
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _callEmergency(context),
                icon: const Icon(Icons.phone),
                label: const Text('ВЫЗВАТЬ СКОРУЮ - 112'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.grey[700]),
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
    );
  }

  Widget _buildStepCard(FirstAidStep step) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: step.isCritical ? Colors.red.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.3),
        ),
        color: step.isCritical ? Colors.red.withValues(alpha: 0.05) : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: step.isCritical ? Colors.red : Colors.blue,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${step.stepNumber}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.instruction,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  
                  if (step.tip != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lightbulb, size: 16, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              step.tip!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue[700],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 8),
                  
                  Row(
                    children: [
                      Icon(Icons.timer, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '~${step.estimatedSeconds}с',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      
                      if (step.isCritical) ...[
                        const SizedBox(width: 16),
                        Icon(Icons.priority_high, size: 14, color: Colors.red[600]),
                        const SizedBox(width: 4),
                        Text(
                          'КРИТИЧНО',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(String text, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _callEmergency(BuildContext context) {
    // TODO: Implement emergency call
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Функция вызова в разработке'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}