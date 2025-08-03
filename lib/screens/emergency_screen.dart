// lib/screens/emergency_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/firebase_service.dart';
import 'emergency_contacts_screen.dart';
import 'first_aid_guide_screen.dart';

class EmergencyScreen extends StatefulWidget {
  final String? childId;

  const EmergencyScreen({super.key, this.childId});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen>
    with TickerProviderStateMixin {
  
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;
  
  List<EmergencyContact> _emergencyContacts = [];
  List<FirstAidGuide> _firstAidGuides = [];
  bool _isLoading = true;
  // bool _sosPressed = false; // Удалено - не используется

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );
    
    _loadEmergencyData();
    
    // Анимация пульсации для SOS кнопки
    _pulseController.repeat(reverse: true);
    
    // Медленное вращение для фона
    _rotationController.repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _loadEmergencyData() async {
    setState(() => _isLoading = true);
    
    try {
      // Загружаем экстренные контакты
      FirebaseService.getEmergencyContactsStream().listen((contacts) {
        setState(() {
          _emergencyContacts = contacts;
        });
      });
      
      // Загружаем инструкции первой помощи
      FirebaseService.getFirstAidGuidesStream().listen((guides) {
        setState(() {
          _firstAidGuides = guides;
        });
      });
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки данных: $e'),
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
              Colors.red[900]!,
              Colors.red[700]!,
              Colors.red[500]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _buildMainContent(),
              ),
            ],
          ),
        ),
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
                const Row(
                  children: [
                    Icon(
                      Icons.medical_services,
                      color: Colors.white,
                      size: 28,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Экстренные ситуации',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
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
          AnimatedBuilder(
            animation: _rotationAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationAnimation.value * 2 * 3.14159,
                child: Icon(
                  Icons.health_and_safety,
                  color: Colors.white.withValues(alpha: 0.3),
                  size: 40,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // SOS кнопка
          _buildSOSButton(),
          
          const SizedBox(height: 30),
          
          // Быстрые действия
          _buildQuickActions(),
          
          const SizedBox(height: 30),
          
          // Экстренные контакты
          if (_emergencyContacts.isNotEmpty) _buildEmergencyContacts(),
          
          const SizedBox(height: 30),
          
          // Инструкции первой помощи
          if (_firstAidGuides.isNotEmpty) _buildFirstAidGuides(),
        ],
      ),
    );
  }

  Widget _buildSOSButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'ЭКСТРЕННЫЙ ВЫЗОВ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
              letterSpacing: 1.2,
            ),
          ),
          
          const SizedBox(height: 20),
          
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: GestureDetector(
                  onTap: _onSOSPressed,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          Colors.red[400]!,
                          Colors.red[700]!,
                          Colors.red[900]!,
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.phone,
                            color: Colors.white,
                            size: 40,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'SOS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 20),
          
          Text(
            'Нажмите для экстренного вызова',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      _QuickAction(
        title: 'Удушье',
        icon: '🫁',
        type: EmergencyType.choking,
        color: Colors.red[700]!,
      ),
      _QuickAction(
        title: 'Температура',
        icon: '🌡️',
        type: EmergencyType.fever,
        color: Colors.orange[700]!,
      ),
      _QuickAction(
        title: 'Отравление',
        icon: '☠️',
        type: EmergencyType.poisoning,
        color: Colors.purple[700]!,
      ),
      _QuickAction(
        title: 'Травма',
        icon: '🩹',
        type: EmergencyType.injury,
        color: Colors.indigo[700]!,
      ),
    ];

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Быстрые действия',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
          ),
          
          const SizedBox(height: 15),
          
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.0,
            ),
            itemCount: actions.length,
            itemBuilder: (context, index) {
              final action = actions[index];
              return _buildQuickActionCard(action);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(_QuickAction action) {
    return GestureDetector(
      onTap: () => _onQuickActionTapped(action.type),
      child: Container(
        decoration: BoxDecoration(
          color: action.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: action.color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              action.icon,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 8),
            Text(
              action.title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: action.color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyContacts() {
    // Показываем только топ-3 контакта для краткости
    final topContacts = _emergencyContacts.take(3).toList();
    
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Экстренные контакты',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
              TextButton(
                onPressed: _showAllContacts,
                child: const Text('Все контакты'),
              ),
            ],
          ),
          
          const SizedBox(height: 15),
          
          ...topContacts.map((contact) => _buildContactCard(contact)),
        ],
      ),
    );
  }

  Widget _buildContactCard(EmergencyContact contact) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: contact.isAvailableNow 
            ? Colors.green[50] 
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: contact.isAvailableNow 
              ? Colors.green[300]! 
              : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Color(contact.type.colorHex),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                contact.type.iconEmoji,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          
          const SizedBox(width: 15),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  contact.formattedPhone,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                if (!contact.isAvailableNow && contact.workingHours != null)
                  Text(
                    'Работает: ${contact.workingHours}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[700],
                    ),
                  ),
              ],
            ),
          ),
          
          IconButton(
            onPressed: () => _callContact(contact),
            icon: Icon(
              Icons.phone,
              color: contact.isAvailableNow ? Colors.green : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFirstAidGuides() {
    // Показываем только топ-3 инструкции
    final topGuides = _firstAidGuides.take(3).toList();
    
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Первая помощь',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
              TextButton(
                onPressed: _showAllGuides,
                child: const Text('Все инструкции'),
              ),
            ],
          ),
          
          const SizedBox(height: 15),
          
          ...topGuides.map((guide) => _buildGuideCard(guide)),
        ],
      ),
    );
  }

  Widget _buildGuideCard(FirstAidGuide guide) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        tileColor: Color(guide.type.colorHex).withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: Color(guide.type.colorHex).withValues(alpha: 0.3),
          ),
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Color(guide.type.colorHex),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              guide.type.iconEmoji,
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ),
        title: Text(
          guide.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(guide.shortDescription),
            const SizedBox(height: 5),
            Row(
              children: [
                Icon(Icons.timer, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 5),
                Text(
                  guide.formattedDuration,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 15),
                Icon(Icons.child_care, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 5),
                Text(
                  guide.ageRange.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () => _showGuideDetails(guide),
      ),
    );
  }

  // Действия
  void _onSOSPressed() {
    // setState(() => _sosPressed = true); // Удалено - не используется
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red[700]),
            const SizedBox(width: 10),
            const Text('ЭКСТРЕННЫЙ ВЫЗОВ'),
          ],
        ),
        content: const Text(
          'Вызвать экстренную службу?\n\nБудет произведен вызов службы экстренного реагирования 112.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              // setState(() => _sosPressed = false); // Удалено - не используется
              Navigator.pop(context);
            },
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _callEmergencyService();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('ВЫЗВАТЬ'),
          ),
        ],
      ),
    );
  }

  void _onQuickActionTapped(EmergencyType type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          type.displayName,
          style: TextStyle(color: Color(type.colorHex)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Выберите действие для ситуации "${type.displayName}":'),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showFirstAidForType(type);
                  },
                  icon: const Icon(Icons.medical_services),
                  label: const Text('Первая помощь'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showContactsForType(type);
                  },
                  icon: const Icon(Icons.phone),
                  label: const Text('Контакты'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _callEmergencyService() async {
    try {
      await launchUrl(Uri.parse('tel:112'));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка вызова: $e')),
        );
      }
    }
  }

  Future<void> _callContact(EmergencyContact contact) async {
    try {
      await launchUrl(Uri.parse('tel:${contact.phone}'));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка вызова: $e')),
        );
      }
    }
  }

  void _showAllContacts() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EmergencyContactsScreen(),
      ),
    );
  }

  void _showAllGuides() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FirstAidGuideScreen(childId: widget.childId),
      ),
    );
  }

  void _showFirstAidForType(EmergencyType type) {
    // TODO: Navigate to specific first aid guide
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Инструкция для ${type.displayName} в разработке')),
    );
  }

  void _showContactsForType(EmergencyType type) {
    // TODO: Show contacts filtered by type
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Контакты для ${type.displayName} в разработке')),
    );
  }

  void _showGuideDetails(FirstAidGuide guide) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(guide.type.colorHex),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        guide.type.iconEmoji,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      guide.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 15),
              
              Text(guide.shortDescription),
              
              const SizedBox(height: 15),
              
              Text(
                'Действия (${guide.formattedDuration}):',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              
              const SizedBox(height: 10),
              
              ...guide.steps.take(3).map((step) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: step.isCritical ? Colors.red : Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${step.stepNumber}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(step.instruction),
                    ),
                  ],
                ),
              )),
              
              if (guide.steps.length > 3) ...[
                const SizedBox(height: 10),
                Text(
                  '...еще ${guide.steps.length - 3} шагов',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              
              const SizedBox(height: 20),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Закрыть'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // TODO: Navigate to full guide
                    },
                    child: const Text('Полная инструкция'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Модель быстрого действия
class _QuickAction {
  final String title;
  final String icon;
  final EmergencyType type;
  final Color color;

  _QuickAction({
    required this.title,
    required this.icon,
    required this.type,
    required this.color,
  });
}