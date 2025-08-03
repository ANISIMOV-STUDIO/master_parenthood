// lib/screens/vaccination_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/firebase_service.dart';

class VaccinationScreen extends StatefulWidget {
  final String childId;
  
  const VaccinationScreen({
    super.key,
    required this.childId,
  });

  @override
  State<VaccinationScreen> createState() => _VaccinationScreenState();
}

class _VaccinationScreenState extends State<VaccinationScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _headerController;
  
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  
  List<Vaccination> _allVaccinations = [];
  List<Vaccination> _selectedDayVaccinations = [];


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
    
    _loadVaccinations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _headerController.dispose();
    super.dispose();
  }

  void _loadVaccinations() {
    FirebaseService.getVaccinationsStream(widget.childId).listen((vaccinations) {
      setState(() {
        _allVaccinations = vaccinations;
        _updateSelectedDayVaccinations();
      });
    });
  }

  void _updateSelectedDayVaccinations() {
    _selectedDayVaccinations = _allVaccinations.where((vaccination) {
      return isSameDay(vaccination.scheduledDate, _selectedDay) ||
             (vaccination.actualDate != null && 
              isSameDay(vaccination.actualDate!, _selectedDay));
    }).toList();
  }

  List<Vaccination> _getVaccinationsForDay(DateTime day) {
    return _allVaccinations.where((vaccination) {
      return isSameDay(vaccination.scheduledDate, day) ||
             (vaccination.actualDate != null && 
              isSameDay(vaccination.actualDate!, day));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFE),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverFillRemaining(
            child: Column(
              children: [
                _buildQuickStats(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCalendarTab(),
                      _buildOverdueTab(),
                      _buildUpcomingTab(),
                      _buildCompletedTab(),
                    ],
                  ),
                ),
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
                Color(0xFF4A90E2),
                Color(0xFF357ABD),
                Color(0xFF1E88E5),
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
                          Icons.vaccines,
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
                              'Календарь прививок',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ).animate().slideX(delay: 300.ms),
                            Text(
                              'Контроль вакцинации',
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
                      Tab(text: 'Календарь'),
                      Tab(text: 'Просроченные'),
                      Tab(text: 'Предстоящие'),
                      Tab(text: 'Выполненные'),
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

  Widget _buildQuickStats() {
    return StreamBuilder<List<Vaccination>>(
      stream: FirebaseService.getVaccinationsStream(widget.childId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(height: 80);
        }

        final vaccinations = snapshot.data!;
        final completed = vaccinations.where((v) => v.status == VaccinationStatus.completed).length;
        final overdue = vaccinations.where((v) => v.isOverdue).length;
        final upcoming = vaccinations.where((v) => v.isUpcoming).length;

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
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
          child: Row(
            children: [
              _buildStatItem(
                icon: Icons.check_circle,
                color: Colors.green,
                title: 'Выполнено',
                value: completed.toString(),
              ),
              _buildStatItem(
                icon: Icons.warning,
                color: Colors.red,
                title: 'Просрочено',
                value: overdue.toString(),
              ),
              _buildStatItem(
                icon: Icons.schedule,
                color: Colors.orange,
                title: 'Предстоящие',
                value: upcoming.toString(),
              ),
            ],
          ),
        ).animate().slideY(delay: 600.ms);
      },
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
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

  Widget _buildCalendarTab() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
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
          child: TableCalendar<Vaccination>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: _getVaccinationsForDay,
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              markerDecoration: const BoxDecoration(
                color: Color(0xFF4A90E2),
                shape: BoxShape.circle,
              ),
              markersMaxCount: 3,
              selectedDecoration: BoxDecoration(
                color: const Color(0xFF4A90E2),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4A90E2).withValues(alpha: 0.3),
                    spreadRadius: 2,
                    blurRadius: 4,
                  ),
                ],
              ),
              todayDecoration: BoxDecoration(
                color: const Color(0xFF4A90E2).withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              weekendTextStyle: TextStyle(color: Colors.grey[600]),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
                _updateSelectedDayVaccinations();
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _buildVaccinationsList(_selectedDayVaccinations),
        ),
      ],
    );
  }

  Widget _buildOverdueTab() {
    return StreamBuilder<List<Vaccination>>(
      stream: FirebaseService.getOverdueVaccinationsStream(widget.childId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(
            icon: Icons.check_circle,
            title: 'Нет просроченных прививок',
            subtitle: 'Отлично! Все прививки сделаны вовремя',
            color: Colors.green,
          );
        }

        return _buildVaccinationsList(snapshot.data!);
      },
    );
  }

  Widget _buildUpcomingTab() {
    return StreamBuilder<List<Vaccination>>(
      stream: FirebaseService.getUpcomingVaccinationsStream(widget.childId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(
            icon: Icons.schedule,
            title: 'Нет предстоящих прививок',
            subtitle: 'На ближайшие 30 дней прививок не запланировано',
            color: Colors.blue,
          );
        }

        return _buildVaccinationsList(snapshot.data!);
      },
    );
  }

  Widget _buildCompletedTab() {
    return StreamBuilder<List<Vaccination>>(
      stream: FirebaseService.getVaccinationsStream(widget.childId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final completedVaccinations = snapshot.data
            ?.where((v) => v.status == VaccinationStatus.completed)
            .toList() ?? [];

        if (completedVaccinations.isEmpty) {
          return _buildEmptyState(
            icon: Icons.vaccines,
            title: 'Нет выполненных прививок',
            subtitle: 'Здесь будут отображаться завершенные прививки',
            color: Colors.grey,
          );
        }

        return _buildVaccinationsList(completedVaccinations);
      },
    );
  }

  Widget _buildVaccinationsList(List<Vaccination> vaccinations) {
    if (vaccinations.isEmpty) {
      return _buildEmptyState(
        icon: Icons.calendar_today,
        title: 'Нет прививок на эту дату',
        subtitle: 'Выберите другую дату в календаре',
        color: Colors.grey,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: vaccinations.length,
      itemBuilder: (context, index) {
        final vaccination = vaccinations[index];
        return _buildVaccinationCard(vaccination, index);
      },
    );
  }

  Widget _buildVaccinationCard(Vaccination vaccination, int index) {
    Color statusColor;
    IconData statusIcon;
    
    switch (vaccination.status) {
      case VaccinationStatus.completed:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case VaccinationStatus.scheduled:
        statusColor = vaccination.isOverdue ? Colors.red : Colors.orange;
        statusIcon = vaccination.isOverdue ? Icons.warning : Icons.schedule;
        break;
      case VaccinationStatus.postponed:
        statusColor = Colors.blue;
        statusIcon = Icons.pause;
        break;
      case VaccinationStatus.contraindicated:
        statusColor = Colors.red;
        statusIcon = Icons.block;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

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
          onTap: () => _showVaccinationDetails(vaccination),
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
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(statusIcon, color: statusColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vaccination.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            vaccination.statusDisplayName,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (vaccination.status == VaccinationStatus.scheduled &&
                        !vaccination.isOverdue)
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () => _markAsCompleted(vaccination),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      vaccination.actualDate != null
                          ? 'Выполнено: ${_formatDate(vaccination.actualDate!)}'
                          : 'Запланировано: ${_formatDate(vaccination.scheduledDate)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                if (vaccination.doctorName != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.person, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Врач: ${vaccination.doctorName}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
                if (vaccination.isOverdue) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.red, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Прививка просрочена на ${DateTime.now().difference(vaccination.scheduledDate).inDays} дней',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ).animate(delay: Duration(milliseconds: 100 * index)).slideX();
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
      onPressed: _showAddVaccinationDialog,
      backgroundColor: const Color(0xFF4A90E2),
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text(
        'Добавить прививку',
        style: TextStyle(color: Colors.white),
      ),
    ).animate().scale(delay: 800.ms);
  }

  void _showVaccinationDetails(Vaccination vaccination) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VaccinationDetailsSheet(vaccination: vaccination),
    );
  }

  void _showAddVaccinationDialog() {
    showDialog(
      context: context,
      builder: (context) => AddVaccinationDialog(childId: widget.childId),
    );
  }

  void _markAsCompleted(Vaccination vaccination) {
    showDialog(
      context: context,
      builder: (context) => MarkVaccinationCompletedDialog(vaccination: vaccination),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}

// Дополнительные виджеты (детали прививки, добавление, отметка выполнения)
class VaccinationDetailsSheet extends StatelessWidget {
  final Vaccination vaccination;

  const VaccinationDetailsSheet({super.key, required this.vaccination});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
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
                  Text(
                    vaccination.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(vaccination.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      vaccination.statusDisplayName,
                      style: TextStyle(
                        color: _getStatusColor(vaccination.status),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildDetailRow('Запланирована', _formatDate(vaccination.scheduledDate)),
                  if (vaccination.actualDate != null)
                    _buildDetailRow('Выполнена', _formatDate(vaccination.actualDate!)),
                  if (vaccination.doctorName != null)
                    _buildDetailRow('Врач', vaccination.doctorName!),
                  if (vaccination.clinic != null)
                    _buildDetailRow('Клиника', vaccination.clinic!),
                  if (vaccination.batchNumber != null)
                    _buildDetailRow('Серия', vaccination.batchNumber!),
                  if (vaccination.manufacturer != null)
                    _buildDetailRow('Производитель', vaccination.manufacturer!),
                  if (vaccination.reaction != null && vaccination.reaction!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Реакция:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(vaccination.reaction!),
                  ],
                  if (vaccination.notes != null && vaccination.notes!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Заметки:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(vaccination.notes!),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            // Открыть редактирование
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A90E2),
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
                            // Добавить документ
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF4A90E2),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Добавить документ'),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(VaccinationStatus status) {
    switch (status) {
      case VaccinationStatus.completed:
        return Colors.green;
      case VaccinationStatus.scheduled:
        return Colors.orange;
      case VaccinationStatus.overdue:
        return Colors.red;
      case VaccinationStatus.postponed:
        return Colors.blue;
      case VaccinationStatus.contraindicated:
        return Colors.red;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}

// Диалог добавления прививки (заглушка - будет реализован далее)
class AddVaccinationDialog extends StatelessWidget {
  final String childId;

  const AddVaccinationDialog({super.key, required this.childId});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Добавить прививку'),
      content: const Text('Форма добавления прививки будет реализована далее'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Закрыть'),
        ),
      ],
    );
  }
}

// Диалог отметки выполнения (заглушка - будет реализован далее)
class MarkVaccinationCompletedDialog extends StatelessWidget {
  final Vaccination vaccination;

  const MarkVaccinationCompletedDialog({super.key, required this.vaccination});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Отметить как выполненную'),
      content: const Text('Форма отметки выполнения будет реализована далее'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отметить'),
        ),
      ],
    );
  }
}