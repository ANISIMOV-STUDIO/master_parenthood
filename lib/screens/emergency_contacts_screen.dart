// lib/screens/emergency_contacts_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/firebase_service.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen>
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;
  List<EmergencyContact> _allContacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadContacts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);
    
    try {
      FirebaseService.getEmergencyContactsStream().listen((contacts) {
        setState(() {
          _allContacts = contacts;
          _isLoading = false;
        });
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки контактов: $e'),
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
        title: const Text('Экстренные контакты'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Все контакты'),
            Tab(text: 'Доступные'),
            Tab(text: 'По типам'),
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
                _buildAllContactsTab(),
                _buildAvailableContactsTab(),
                _buildContactsByTypeTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewContact,
        backgroundColor: Colors.red[700],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildAllContactsTab() {
    if (_allContacts.isEmpty) {
      return _buildEmptyState('Нет экстренных контактов');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _allContacts.length,
      itemBuilder: (context, index) {
        final contact = _allContacts[index];
        return _buildContactCard(contact);
      },
    );
  }

  Widget _buildAvailableContactsTab() {
    final availableContacts = _allContacts
        .where((contact) => contact.isAvailableNow)
        .toList();

    if (availableContacts.isEmpty) {
      return _buildEmptyState('Нет доступных контактов в данный момент');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: availableContacts.length,
      itemBuilder: (context, index) {
        final contact = availableContacts[index];
        return _buildContactCard(contact, showAvailableTag: true);
      },
    );
  }

  Widget _buildContactsByTypeTab() {
    final groupedContacts = <EmergencyType, List<EmergencyContact>>{};
    
    for (final contact in _allContacts) {
      groupedContacts.putIfAbsent(contact.type, () => []).add(contact);
    }

    if (groupedContacts.isEmpty) {
      return _buildEmptyState('Нет контактов для отображения');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedContacts.length,
      itemBuilder: (context, index) {
        final type = groupedContacts.keys.elementAt(index);
        final contacts = groupedContacts[type]!;
        
        return _buildTypeGroup(type, contacts);
      },
    );
  }

  Widget _buildTypeGroup(EmergencyType type, List<EmergencyContact> contacts) {
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
                Text(
                  type.displayName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(type.colorHex),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(type.colorHex),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${contacts.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...contacts.map((contact) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _buildContactCard(contact, isInGroup: true),
          )),
        ],
      ),
    );
  }

  Widget _buildContactCard(
    EmergencyContact contact, {
    bool showAvailableTag = false,
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
          onTap: () => _showContactDetails(contact),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Иконка типа
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Color(contact.type.colorHex).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      contact.type.iconEmoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Информация о контакте
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              contact.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (showAvailableTag)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Доступен',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                      
                      const SizedBox(height: 4),
                      
                      Text(
                        contact.formattedPhone,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      
                      if (contact.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          contact.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      
                      if (!contact.isAvailableNow && contact.workingHours != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 12,
                              color: Colors.orange[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Работает: ${contact.workingHours}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Кнопка звонка
                Column(
                  children: [
                    IconButton(
                      onPressed: () => _callContact(contact),
                      icon: Icon(
                        Icons.phone,
                        color: contact.isAvailableNow ? Colors.green : Colors.grey,
                        size: 28,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: contact.isAvailableNow 
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.grey.withValues(alpha: 0.1),
                      ),
                    ),
                    
                    // Приоритет
                    if (contact.priority <= 3)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: contact.priority == 1 
                              ? Colors.red 
                              : contact.priority == 2 
                                  ? Colors.orange 
                                  : Colors.yellow[700],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${contact.priority}',
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
            Icons.contact_phone,
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
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addNewContact,
            icon: const Icon(Icons.add),
            label: const Text('Добавить контакт'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Действия
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

  void _showContactDetails(EmergencyContact contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(contact.type.iconEmoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Expanded(child: Text(contact.name)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Телефон', contact.formattedPhone),
            _buildDetailRow('Тип', contact.type.displayName),
            _buildDetailRow('Описание', contact.description),
            if (contact.address != null)
              _buildDetailRow('Адрес', contact.address!),
            if (contact.workingHours != null)
              _buildDetailRow('Часы работы', contact.workingHours!),
            _buildDetailRow(
              'Статус',
              contact.isAvailableNow ? 'Доступен сейчас' : 'Недоступен',
            ),
            _buildDetailRow('Приоритет', '${contact.priority}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _callContact(contact);
            },
            icon: const Icon(Icons.phone),
            label: const Text('Позвонить'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _addNewContact() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Функция добавления контакта в разработке'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}