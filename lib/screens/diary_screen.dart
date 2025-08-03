// lib/screens/diary_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'dart:io';
import '../services/firebase_service.dart';
import '../services/offline_service.dart';
import '../services/connectivity_service.dart';
import '../utils/performance_utils.dart';
import 'package:provider/provider.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen>
    with TickerProviderStateMixin {
  late AnimationController _listController;
  late TabController _tabController;
  
  ChildProfile? _activeChild;
  List<DiaryEntry> _entries = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _listController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _listController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final activeChild = await FirebaseService.getActiveChild();
      if (mounted && activeChild != null) {
        setState(() {
          _activeChild = activeChild;
        });
        
        // Загружаем записи дневника
        _loadDiaryEntries();
        _listController.forward();
      }
    } catch (e) {
      if (mounted) {
        // Error logged internally
        // Продолжаем работу без активного ребенка
      }
    }
    
    setState(() => _isLoading = false);
  }

  void _loadDiaryEntries() {
    if (_activeChild == null) return;
    
    final connectivityService = Provider.of<ConnectivityService>(context, listen: false);
    
    if (connectivityService.hasInternet) {
      // Подписываемся на stream записей дневника
      FirebaseService.getDiaryEntriesStream(_activeChild!.id).listen((entries) {
        if (mounted) {
          setState(() {
            _entries = entries;
          });
          // Сохраняем данные offline для будущего использования
          for (final entry in entries) {
            OfflineService.saveDiaryEntryOffline(entry);
          }
        }
      });
    } else {
      // Загружаем данные из offline хранилища
      final offlineEntries = OfflineService.getDiaryEntriesOffline(_activeChild!.id);
      setState(() {
        _entries = offlineEntries;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Дневник развития'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
        ],
      ),
      body: _activeChild == null
          ? _buildNoDataState()
          : Column(
              children: [
                _buildChildHeader(),
                _buildTabBar(),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildAllEntries(),
                            _buildMilestones(),
                            _buildMemories(),
                          ],
                        ),
                ),
              ],
            ),
      floatingActionButton: _activeChild != null
          ? FloatingActionButton.extended(
              onPressed: _showAddEntryDialog,
              icon: const Icon(Icons.add),
              label: const Text('Добавить запись'),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Widget _buildNoDataState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_book,
            size: 100,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 24),
          Text(
            'Дневник пуст',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Добавьте профиль ребенка\nчтобы вести дневник',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ).animate().fadeIn().slideY(begin: 0.3),
    );
  }

  Widget _buildChildHeader() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.pink.shade400,
            Colors.purple.shade400,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.menu_book,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Дневник ${_activeChild!.name}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_entries.length} записей',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              _activeChild!.ageFormattedShort,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: -0.3);
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.pink.shade400, Colors.purple.shade400],
          ),
          borderRadius: BorderRadius.circular(25),
        ),
        tabs: const [
          Tab(text: 'Все записи'),
          Tab(text: 'Вехи'),
          Tab(text: 'Воспоминания'),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildAllEntries() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: PerformanceUtils.optimizedListBuilder(
        itemCount: _entries.length,
        itemBuilder: (context, index) {
          final entry = _entries[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: RepaintBoundary(
              child: _buildEntryCard(entry, index),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMilestones() {
    final milestones = _entries.where((e) => e.type == DiaryEntryType.milestone).toList();
    
    if (milestones.isEmpty) {
      return _buildEmptyState('Нет записанных вех', Icons.flag);
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: milestones.length,
      itemBuilder: (context, index) {
        final entry = milestones[index];
        return _buildEntryCard(entry, index, showBadge: true);
      },
    );
  }

  Widget _buildMemories() {
    final memories = _entries.where((e) => e.photos.isNotEmpty).toList();
    
    if (memories.isEmpty) {
      return _buildEmptyState('Нет фотовоспоминаний', Icons.photo_library);
    }
    
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: memories.length,
      itemBuilder: (context, index) {
        final entry = memories[index];
        return _buildMemoryCard(entry, index);
      },
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddEntryDialog,
            icon: const Icon(Icons.add),
            label: const Text('Добавить запись'),
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.8, 0.8));
  }

  Widget _buildEntryCard(DiaryEntry entry, int index, {bool showBadge = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: InkWell(
        onTap: () => _showEntryDetails(entry),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getTypeColor(entry.type).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getTypeIcon(entry.type),
                      color: _getTypeColor(entry.type),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _formatDate(entry.date),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showBadge)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'ВЕХА',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                entry.content,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (entry.photos.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.photo_library,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${entry.photos.length} фото',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    ).animate(controller: _listController)
      .fadeIn(delay: (index * 100).ms)
      .slideX(begin: 0.3);
  }

  Widget _buildMemoryCard(DiaryEntry entry, int index) {
    return Container(
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
      child: InkWell(
        onTap: () => _showEntryDetails(entry),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: const Center(
                  child: Icon(Icons.photo, size: 40, color: Colors.grey),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      _formatDate(entry.date),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate(controller: _listController)
      .fadeIn(delay: (index * 150).ms)
      .scale(begin: const Offset(0.8, 0.8));
  }

  Color _getTypeColor(DiaryEntryType type) {
    switch (type) {
      case DiaryEntryType.milestone:
        return Colors.orange;
      case DiaryEntryType.development:
        return Colors.blue;
      case DiaryEntryType.daily:
        return Colors.green;
    }
  }

  IconData _getTypeIcon(DiaryEntryType type) {
    switch (type) {
      case DiaryEntryType.milestone:
        return Icons.flag;
      case DiaryEntryType.development:
        return Icons.psychology;
      case DiaryEntryType.daily:
        return Icons.today;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      return 'Сегодня';
    } else if (difference == 1) {
      return 'Вчера';
    } else if (difference < 7) {
      return '$difference дней назад';
    } else {
      return '${date.day}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    }
  }

  void _showAddEntryDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddEntryDialog(
        onSave: (entry) {
          setState(() {
            _entries.insert(0, entry);
          });
        },
        childId: _activeChild!.id,
      ),
    );
  }

  void _showEntryDetails(DiaryEntry entry) {
    showDialog(
      context: context,
      builder: (context) => _EntryDetailsDialog(entry: entry),
    );
  }

  void _showSearchDialog() {
    showSearch(
      context: context,
      delegate: _DiarySearchDelegate(_entries),
    );
  }
}

// Импортируем модели из firebase_service.dart

// Диалог добавления записи
class _AddEntryDialog extends StatefulWidget {
  final Function(DiaryEntry) onSave;
  final String childId;

  const _AddEntryDialog({
    required this.onSave,
    required this.childId,
  });

  @override
  State<_AddEntryDialog> createState() => _AddEntryDialogState();
}

class _AddEntryDialogState extends State<_AddEntryDialog> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  DiaryEntryType _selectedType = DiaryEntryType.daily;
  final DateTime _selectedDate = DateTime.now();

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
          Text(
            'Новая запись в дневник',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Заголовок',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _contentController,
            decoration: const InputDecoration(
              labelText: 'Описание',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<DiaryEntryType>(
            value: _selectedType,
            decoration: const InputDecoration(
              labelText: 'Тип записи',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _selectedType = value!;
              });
            },
            items: const [
              DropdownMenuItem(
                value: DiaryEntryType.daily,
                child: Text('Ежедневная запись'),
              ),
              DropdownMenuItem(
                value: DiaryEntryType.development,
                child: Text('Развитие'),
              ),
              DropdownMenuItem(
                value: DiaryEntryType.milestone,
                child: Text('Веха развития'),
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
                  onPressed: _titleController.text.isNotEmpty && _contentController.text.isNotEmpty
                                              ? () async {
                          final entry = DiaryEntry(
                            id: '', // Firebase сгенерирует ID
                            childId: widget.childId,
                            title: _titleController.text,
                            content: _contentController.text,
                            date: _selectedDate,
                            type: _selectedType,
                            photos: [],
                          );
                          
                          try {
                            final connectivityService = Provider.of<ConnectivityService>(context, listen: false);
                            
                            if (connectivityService.hasInternet) {
                              // Сохраняем в Firebase
                              await FirebaseService.createDiaryEntry(entry);
                            } else {
                              // Сохраняем offline
                              await OfflineService.saveDiaryEntryOffline(entry);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Запись сохранена offline. Синхронизируется при подключении к интернету.')),
                              );
                            }
                            
                            widget.onSave(entry);
                            Navigator.pop(context);
                          } catch (e) {
                            // В случае ошибки сохраняем offline
                            await OfflineService.saveDiaryEntryOffline(entry);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Запись сохранена offline. Синхронизируется позже.')),
                            );
                            widget.onSave(entry);
                            Navigator.pop(context);
                          }
                        }
                      : null,
                  child: const Text('Сохранить'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Диалог деталей записи
class _EntryDetailsDialog extends StatelessWidget {
  final DiaryEntry entry;

  const _EntryDetailsDialog({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    entry.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${entry.date.day}.${entry.date.month.toString().padLeft(2, '0')}.${entry.date.year}',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              entry.content,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            if (entry.photos.isNotEmpty) ...[
              const Text(
                'Фотографии:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text('Фото будут загружены'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Поиск по дневнику
class _DiarySearchDelegate extends SearchDelegate<DiaryEntry?> {
  final List<DiaryEntry> entries;

  _DiarySearchDelegate(this.entries);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () => query = '',
        icon: const Icon(Icons.clear),
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () => close(context, null),
      icon: const Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return buildSuggestions(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final filteredEntries = entries.where((entry) {
      return entry.title.toLowerCase().contains(query.toLowerCase()) ||
             entry.content.toLowerCase().contains(query.toLowerCase());
    }).toList();

    if (filteredEntries.isEmpty) {
      return const Center(
        child: Text('Записи не найдены'),
      );
    }

    return ListView.builder(
      itemCount: filteredEntries.length,
      itemBuilder: (context, index) {
        final entry = filteredEntries[index];
        return ListTile(
          title: Text(entry.title),
          subtitle: Text(
            entry.content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => close(context, entry),
        );
      },
    );
  }
}