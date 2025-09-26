// lib/screens/smart_calendar_screen.dart
// 📅 Smart Calendar Screen with AI Features
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/smart_calendar_service.dart';
import '../services/voice_service.dart';
import '../services/enhanced_notification_service.dart';
import '../widgets/optimized_widgets.dart';

class SmartCalendarScreen extends StatefulWidget {
  const SmartCalendarScreen({super.key});

  @override
  State<SmartCalendarScreen> createState() => _SmartCalendarScreenState();
}

class _SmartCalendarScreenState extends State<SmartCalendarScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  List<CalendarEvent> _selectedEvents = [];
  List<CalendarEvent> _aiSuggestions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadEvents();
    _loadAiSuggestions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);

    try {
      final events = await SmartCalendarService.getEventsForDate(_selectedDay);
      setState(() {
        _selectedEvents = events;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading events: $e');
    }
  }

  Future<void> _loadAiSuggestions() async {
    try {
      final suggestions = await SmartCalendarService.getAiSuggestionsForToday(
        childAgeInMonths: 18, // This would come from child profile
        childName: 'Малыш', // This would come from child profile
        language: 'ru',
      );
      setState(() => _aiSuggestions = suggestions);
    } catch (e) {
      debugPrint('Error loading AI suggestions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('📅 Smart Calendar'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.mic),
            onPressed: _startVoiceCommand,
            tooltip: 'Voice Commands',
          ),
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            onPressed: _generateAiSchedule,
            tooltip: 'AI Schedule',
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download),
                    SizedBox(width: 8),
                    Text('Export Calendar'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.upload),
                    SizedBox(width: 8),
                    Text('Import Calendar'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'stats',
                child: Row(
                  children: [
                    Icon(Icons.analytics),
                    SizedBox(width: 8),
                    Text('Statistics'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.calendar_month), text: 'Calendar'),
            Tab(icon: Icon(Icons.event_note), text: 'Events'),
            Tab(icon: Icon(Icons.auto_awesome), text: 'AI Suggestions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCalendarTab(),
          _buildEventsTab(),
          _buildAiSuggestionsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewEvent,
        icon: const Icon(Icons.add),
        label: const Text('Add Event'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildCalendarTab() {
    return Column(
      children: [
        // Beautiful calendar widget
        OptimizedCard(
          margin: const EdgeInsets.all(16),
          child: TableCalendar<CalendarEvent>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: _calendarFormat,
            eventLoader: (day) => _getEventsForDay(day),
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
              weekendTextStyle: TextStyle(color: Colors.red[400]),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
              formatButtonShowsNext: false,
              formatButtonDecoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.all(Radius.circular(12.0)),
              ),
              formatButtonTextStyle: TextStyle(
                color: Colors.white,
              ),
            ),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              _loadEvents();
            },
            onFormatChanged: (format) {
              setState(() => _calendarFormat = format);
            },
            onPageChanged: (focusedDay) {
              setState(() => _focusedDay = focusedDay);
            },
          ),
        ),

        // Events for selected day
        Expanded(
          child: _isLoading
              ? const OptimizedLoadingWidget()
              : _selectedEvents.isEmpty
                  ? _buildEmptyEventsWidget()
                  : _buildEventsList(),
        ),
      ],
    );
  }

  Widget _buildEventsTab() {
    return _isLoading
        ? const OptimizedLoadingWidget()
        : _selectedEvents.isEmpty
            ? _buildEmptyEventsWidget()
            : _buildEventsList();
  }

  Widget _buildAiSuggestionsTab() {
    return Column(
      children: [
        // AI Suggestions Header
        OptimizedGradientContainer(
          margin: const EdgeInsets.all(16),
          colors: [Colors.purple.shade400, Colors.pink.shade400],
          child: const Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.white, size: 32),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Suggestions',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Personalized activities for your child',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // AI Suggestions List
        Expanded(
          child: _aiSuggestions.isEmpty
              ? _buildEmptyAiSuggestionsWidget()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _aiSuggestions.length,
                  itemBuilder: (context, index) {
                    final suggestion = _aiSuggestions[index];
                    return _buildAiSuggestionCard(suggestion);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEventsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _selectedEvents.length,
      itemBuilder: (context, index) {
        final event = _selectedEvents[index];
        return _buildEventCard(event);
      },
    );
  }

  Widget _buildEventCard(CalendarEvent event) {
    return OptimizedCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: _getEventIcon(event.type),
        title: Text(
          event.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: event.completed ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(event.description),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${_formatTime(event.startTime)}${event.endTime != null ? ' - ${_formatTime(event.endTime!)}' : ''}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(width: 12),
                if (event.aiGenerated)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'AI',
                      style: TextStyle(
                        color: Colors.purple,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!event.completed)
              IconButton(
                icon: const Icon(Icons.check_circle_outline),
                onPressed: () => _completeEvent(event),
                tooltip: 'Complete',
              ),
            PopupMenuButton<String>(
              onSelected: (action) => _handleEventAction(action, event),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete),
                      SizedBox(width: 8),
                      Text('Delete'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'remind',
                  child: Row(
                    children: [
                      Icon(Icons.notifications),
                      SizedBox(width: 8),
                      Text('Set Reminder'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () => _showEventDetails(event),
      ),
    );
  }

  Widget _buildAiSuggestionCard(CalendarEvent suggestion) {
    return OptimizedCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.auto_awesome,
                color: Colors.purple.shade600,
              ),
            ),
            title: Text(
              suggestion.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(suggestion.description),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () => _addSuggestionToCalendar(suggestion),
                  child: const Text('Add'),
                ),
                TextButton(
                  onPressed: () => _dismissSuggestion(suggestion),
                  child: const Text('Dismiss'),
                ),
              ],
            ),
          ),
          if (suggestion.metadata != null && suggestion.metadata!['materials'] != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 8,
                children: (suggestion.metadata!['materials'] as List<dynamic>)
                    .map((material) => Chip(
                          label: Text(material.toString()),
                          backgroundColor: Colors.blue.shade50,
                        ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyEventsWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No events for this day',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Tap + to add an event',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyAiSuggestionsWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No AI suggestions available',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Check back later for personalized recommendations',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _getEventIcon(EventType type) {
    IconData iconData;
    Color color;

    switch (type) {
      case EventType.feeding:
        iconData = Icons.restaurant;
        color = Colors.orange;
        break;
      case EventType.sleep:
        iconData = Icons.bedtime;
        color = Colors.blue;
        break;
      case EventType.development:
        iconData = Icons.psychology;
        color = Colors.green;
        break;
      case EventType.medical:
      case EventType.vaccination:
        iconData = Icons.medical_services;
        color = Colors.red;
        break;
      case EventType.play:
        iconData = Icons.toys;
        color = Colors.purple;
        break;
      case EventType.milestone:
        iconData = Icons.celebration;
        color = Colors.amber;
        break;
      default:
        iconData = Icons.event;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(iconData, color: color),
    );
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    // This would be optimized to use cached events
    return [];
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  // Event handlers
  Future<void> _addNewEvent() async {
    // Show add event dialog
    await showDialog(
      context: context,
      builder: (context) => _buildAddEventDialog(),
    );
  }

  Future<void> _completeEvent(CalendarEvent event) async {
    await SmartCalendarService.completeEvent(event.id);
    await _loadEvents();

    // Give positive feedback
    await VoiceService.speak(
      text: 'Event completed! Great job!',
      language: 'en',
    );
  }

  Future<void> _handleEventAction(String action, CalendarEvent event) async {
    switch (action) {
      case 'edit':
        await _editEvent(event);
        break;
      case 'delete':
        await _deleteEvent(event);
        break;
      case 'remind':
        await _setReminder(event);
        break;
    }
  }

  Future<void> _editEvent(CalendarEvent event) async {
    // Show edit event dialog
    await showDialog(
      context: context,
      builder: (context) => _buildEditEventDialog(event),
    );
  }

  Future<void> _deleteEvent(CalendarEvent event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text('Are you sure you want to delete "${event.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await SmartCalendarService.deleteEvent(event.id);
      await _loadEvents();
    }
  }

  Future<void> _setReminder(CalendarEvent event) async {
    await EnhancedNotificationService.sendEnhancedNotification(
      title: 'Reminder: ${event.title}',
      body: event.description,
      channel: EnhancedNotificationService.aiInsightsChannel,
      scheduledTime: event.startTime.subtract(const Duration(minutes: 15)),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminder set for 15 minutes before event')),
      );
    }
  }

  Future<void> _showEventDetails(CalendarEvent event) async {
    await showDialog(
      context: context,
      builder: (context) => _buildEventDetailsDialog(event),
    );
  }

  Future<void> _addSuggestionToCalendar(CalendarEvent suggestion) async {
    await SmartCalendarService.addEvent(suggestion);
    setState(() {
      _aiSuggestions.remove(suggestion);
    });
    await _loadEvents();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${suggestion.title} added to calendar')),
      );
    }
  }

  Future<void> _dismissSuggestion(CalendarEvent suggestion) async {
    setState(() {
      _aiSuggestions.remove(suggestion);
    });
  }

  Future<void> _startVoiceCommand() async {
    await VoiceService.startListening(
      onResult: (command) {
        // Process voice command
        if (command.toLowerCase().contains('add event')) {
          _addNewEvent();
        } else if (command.toLowerCase().contains('show today')) {
          setState(() {
            _selectedDay = DateTime.now();
            _focusedDay = DateTime.now();
          });
          _loadEvents();
        }
      },
      onError: (error) {
        debugPrint('Voice command error: $error');
      },
    );
  }

  Future<void> _generateAiSchedule() async {
    setState(() => _isLoading = true);

    try {
      final aiEvents = await SmartCalendarService.generateAiWeeklySchedule(
        childAgeInMonths: 18,
        childName: 'Малыш',
        childPreferences: {'interests': ['games', 'music', 'reading']},
        language: 'ru',
      );

      for (final event in aiEvents) {
        await SmartCalendarService.addEvent(event);
      }

      await _loadEvents();
      await _loadAiSuggestions();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Generated ${aiEvents.length} AI events')),
        );
      }
    } catch (e) {
      debugPrint('Error generating AI schedule: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleMenuAction(String action) async {
    switch (action) {
      case 'export':
        await _exportCalendar();
        break;
      case 'import':
        await _importCalendar();
        break;
      case 'stats':
        await _showStats();
        break;
    }
  }

  Future<void> _exportCalendar() async {
    try {
      final exportData = await SmartCalendarService.exportCalendarData();
      // Show export dialog or save to file
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Calendar exported successfully')),
        );
      }
    } catch (e) {
      debugPrint('Error exporting calendar: $e');
    }
  }

  Future<void> _importCalendar() async {
    // Show import dialog
    // This would allow users to paste JSON data or select a file
  }

  Future<void> _showStats() async {
    final stats = await SmartCalendarService.getCalendarStats();

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('📊 Calendar Statistics'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Events: ${stats['totalEvents'] ?? 0}'),
              Text('Events This Week: ${stats['eventsThisWeek'] ?? 0}'),
              Text('Completed This Week: ${stats['completedThisWeek'] ?? 0}'),
              Text('Completion Rate: ${((stats['completionRate'] ?? 0.0) * 100).toStringAsFixed(1)}%'),
              Text('AI Generated: ${stats['aiGeneratedEvents'] ?? 0}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildAddEventDialog() {
    // Implementation for add event dialog
    return AlertDialog(
      title: const Text('Add New Event'),
      content: const Text('Add event dialog would be implemented here'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Add'),
        ),
      ],
    );
  }

  Widget _buildEditEventDialog(CalendarEvent event) {
    // Implementation for edit event dialog
    return AlertDialog(
      title: const Text('Edit Event'),
      content: Text('Edit event dialog for ${event.title}'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildEventDetailsDialog(CalendarEvent event) {
    return AlertDialog(
      title: Text(event.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(event.description),
          const SizedBox(height: 16),
          Text('Time: ${_formatTime(event.startTime)}${event.endTime != null ? ' - ${_formatTime(event.endTime!)}' : ''}'),
          Text('Type: ${event.type.name}'),
          Text('Priority: ${event.priority.name}'),
          if (event.aiGenerated) const Text('Generated by AI'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}