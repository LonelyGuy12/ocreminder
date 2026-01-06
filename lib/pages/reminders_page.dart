import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:lonelyreminder/models/event_model.dart';
import 'package:lonelyreminder/services/database_service.dart';
import 'package:lonelyreminder/services/alarm_service.dart';
import 'package:lonelyreminder/services/ocr_service.dart';
import 'package:lonelyreminder/services/event_parser.dart';
import 'package:lonelyreminder/services/google_auth_service.dart';
import 'package:lonelyreminder/services/calendar_service.dart';
import 'package:lonelyreminder/providers/theme_provider.dart';
import 'package:lonelyreminder/widgets/event_list_item.dart';

class RemindersPage extends StatefulWidget {
  const RemindersPage({Key? key}) : super(key: key);

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage>
    with SingleTickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  final GoogleAuthService _googleAuthService = GoogleAuthService();
  final CalendarService _calendarService = CalendarService();
  List<Event> _events = [];
  bool _isLoading = false;
  bool _isSyncing = false;
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabController,
      curve: Curves.easeOutBack,
    );
    _loadEvents();
    _fabController.forward();
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);

    try {
      final allEvents = await _databaseService.getAllEvents();
      final now = DateTime.now();

      final currentEvents = allEvents.where((event) {
        return event.startTime.isAfter(now.subtract(const Duration(hours: 1)));
      }).toList();

      final pastEvents = allEvents.where((event) {
        return event.startTime.isBefore(now.subtract(const Duration(hours: 1)));
      }).toList();

      for (final event in pastEvents) {
        if (event.id != null) {
          await _databaseService.deleteEventById(event.id!);
          final eventId = int.tryParse(event.id!.split('_').first) ?? event.hashCode;
          await AlarmService.cancelAlarmById(eventId);
        }
      }

      currentEvents.sort((a, b) => a.startTime.compareTo(b.startTime));

      setState(() => _events = currentEvents);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading events: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _processImageAndAddEvent(ImageSource source) async {
    setState(() => _isLoading = true);

    try {
      final ocrService = OcrService();
      final event = source == ImageSource.camera
          ? await ocrService.processImageFromCamera()
          : await ocrService.processImageFromGallery();

      if (event.startTime.isBefore(DateTime.now())) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot add past events'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      await _databaseService.addEvent(event);
      await _scheduleEventNotifications(event);
      await _loadEvents();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Event "${event.title}" added!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _scheduleEventNotifications(Event event) async {
    await AlarmService.scheduleAlarm(event);
  }

  Future<void> _deleteEvent(Event event) async {
    try {
      if (event.id != null) {
        await _databaseService.deleteEventById(event.id!);
        final eventId = int.tryParse(event.id!.split('_').first) ?? event.hashCode;
        await AlarmService.cancelAlarmById(eventId);
      }
      await _loadEvents();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Event "${event.title}" deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting event: $e')),
        );
      }
    }
  }

  Future<void> _syncGoogleCalendar() async {
    setState(() => _isSyncing = true);

    try {
      // Sign in with Google
      final userCredential = await _googleAuthService.signInWithGoogle();
      if (userCredential == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Google sign-in cancelled'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Get access token
      final accessToken = await _googleAuthService.getGoogleCalendarAccessToken();
      if (accessToken == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to get calendar access'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Import events from Google Calendar
      final importedCount = await _calendarService.importToDatabase(accessToken);
      
      await _loadEvents();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Synced $importedCount events from Google Calendar'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  Future<void> _addFromText() async {
    final textController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Quick Add ✨'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Type naturally, e.g.:\n"Doctor appointment at 11 pm today"\n"Meeting tomorrow at 3pm"',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                decoration: const InputDecoration(
                  labelText: 'What do you need to remember?',
                  hintText: 'e.g. Call mom at 5pm tomorrow',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, textController.text),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        final event = await EventParser.parseEvent(result);
        
        if (event.startTime.isBefore(DateTime.now())) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cannot add past events'), backgroundColor: Colors.red),
            );
          }
          return;
        }

        await _databaseService.addEvent(event);
        await _scheduleEventNotifications(event);
        await _loadEvents();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ "${event.title}" at ${DateFormat('MMM d, h:mm a').format(event.startTime)}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addCustomEvent() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Custom Event'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Event Title'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(labelText: 'Description (optional)'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('Date'),
                      subtitle: Text(DateFormat.yMMMMd().format(selectedDate)),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() => selectedDate = date);
                        }
                      },
                    ),
                    ListTile(
                      title: const Text('Time'),
                      subtitle: Text(selectedTime.format(context)),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (time != null) {
                          setState(() => selectedTime = time);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true && titleController.text.isNotEmpty) {
      final finalDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );

      if (finalDateTime.isBefore(DateTime.now())) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cannot add past events')),
          );
        }
        return;
      }

      final event = Event(
        title: titleController.text,
        description: descriptionController.text.isEmpty ? null : descriptionController.text,
        startTime: finalDateTime,
      );

      try {
        await _databaseService.addEvent(event);
        await _scheduleEventNotifications(event);
        await _loadEvents();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Event "${event.title}" added!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPokemonMode = context.watch<ThemeProvider>().isPokemonMode;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isPokemonMode ? '🔥 Pokemon Reminder 🔥' : 'Lonely Reminder'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isPokemonMode ? Colors.black.withOpacity(0.5) : Colors.transparent,
        foregroundColor: isPokemonMode ? Colors.orange : (isDark ? const Color(0xFFE8E8F5) : Colors.black87),
        actions: [
          if (_isSyncing)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.cloud_sync),
              onPressed: _syncGoogleCalendar,
              tooltip: 'Sync Google Calendar',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEvents,
          ),
        ],
      ),
      extendBodyBehindAppBar: isPokemonMode,
      body: Container(
        decoration: isPokemonMode
            ? const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/charizard.jpg'),
                  fit: BoxFit.cover,
                ),
              )
            : BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [
                          const Color(0xFF0A0E27),
                          const Color(0xFF1A1F3A),
                        ]
                      : [
                          Colors.teal.shade50,
                          Colors.white,
                        ],
                ),
              ),
        child: SafeArea(
          top: !isPokemonMode,
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isPokemonMode ? Colors.orange : (isDark ? const Color(0xFF6C63FF) : Colors.teal),
                    ),
                  ),
                )
              : _events.isEmpty
                  ? Center(
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        margin: const EdgeInsets.all(24),
                        decoration: isPokemonMode
                            ? BoxDecoration(
                                color: Colors.black.withOpacity(0.75),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: const Color(0xFFFF6B35),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF6B35).withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              )
                            : BoxDecoration(
                                color: isDark ? const Color(0xFF161B22) : Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.08),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isPokemonMode) ...[
                              const Text('🔥', style: TextStyle(fontSize: 60)),
                              const SizedBox(height: 8),
                              ShaderMask(
                                shaderCallback: (bounds) => const LinearGradient(
                                  colors: [Color(0xFFFF6B35), Color(0xFFFFD54F)],
                                ).createShader(bounds),
                                child: const Text(
                                  'No Pokemon Yet!',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Gotta catch \'em all!\nAdd reminders to start your journey',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Text('⚡', style: TextStyle(fontSize: 24)),
                                  SizedBox(width: 8),
                                  Text('💧', style: TextStyle(fontSize: 24)),
                                  SizedBox(width: 8),
                                  Text('🌿', style: TextStyle(fontSize: 24)),
                                  SizedBox(width: 8),
                                  Text('🐉', style: TextStyle(fontSize: 24)),
                                ],
                              ),
                            ] else ...[
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    colors: isDark
                                        ? [const Color(0xFF7C4DFF).withOpacity(0.3), const Color(0xFF7C4DFF).withOpacity(0.05)]
                                        : [const Color(0xFF00897B).withOpacity(0.2), const Color(0xFF00897B).withOpacity(0.05)],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.event_note_rounded,
                                  size: 48,
                                  color: isDark ? const Color(0xFF7C4DFF) : const Color(0xFF00897B),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'No Reminders Yet',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? const Color(0xFFE6EDF3) : const Color(0xFF1A1A2E),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Sync your Google Calendar or\nadd a new reminder to get started',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? const Color(0xFF8B949E) : Colors.grey[600],
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.only(
                        top: isPokemonMode ? kToolbarHeight + MediaQuery.of(context).padding.top + 8 : 8,
                        bottom: 8,
                        left: 0,
                        right: 0,
                      ),
                      itemCount: _events.length,
                      itemBuilder: (context, index) {
                        return EventListItem(
                          key: ValueKey(_events[index].id ?? _events[index].title),
                          event: _events[index],
                          onDelete: () => _deleteEvent(_events[index]),
                          onEdit: () {},
                          index: index,
                        );
                      },
                    ),
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _buildAnimatedFab(
              heroTag: 'ocr_gallery',
              onPressed: () => _processImageAndAddEvent(ImageSource.gallery),
              backgroundColor: isPokemonMode
                  ? const Color(0xFF9C27B0)
                  : (isDark ? const Color(0xFF9C27B0) : const Color(0xFF7B1FA2)),
              icon: isPokemonMode ? Icons.photo_library : Icons.image,
              tooltip: isPokemonMode ? 'Scan Pokédex' : 'From Gallery',
              delay: 0,
              isPokemonMode: isPokemonMode,
            ),
            const SizedBox(height: 12),
            _buildAnimatedFab(
              heroTag: 'ocr_camera',
              onPressed: () => _processImageAndAddEvent(ImageSource.camera),
              backgroundColor: isPokemonMode
                  ? const Color(0xFFFF5722)
                  : (isDark ? const Color(0xFFFF7043) : const Color(0xFFE64A19)),
              icon: isPokemonMode ? Icons.camera : Icons.camera_alt,
              tooltip: isPokemonMode ? 'Catch with Camera' : 'Take Photo',
              delay: 100,
              isPokemonMode: isPokemonMode,
            ),
            const SizedBox(height: 12),
            _buildAnimatedFab(
              heroTag: 'add_text',
              onPressed: _addFromText,
              backgroundColor: isPokemonMode
                  ? const Color(0xFF2196F3)
                  : (isDark ? const Color(0xFF00B8D4) : const Color(0xFF0097A7)),
              icon: isPokemonMode ? Icons.edit : Icons.text_fields,
              tooltip: isPokemonMode ? 'Quick Catch' : 'Quick Add',
              delay: 200,
              isPokemonMode: isPokemonMode,
            ),
            const SizedBox(height: 12),
            _buildAnimatedFab(
              heroTag: 'add_custom',
              onPressed: _addCustomEvent,
              backgroundColor: isPokemonMode
                  ? const Color(0xFFFFEB3B)
                  : (isDark ? const Color(0xFF7C4DFF) : const Color(0xFF00897B)),
              icon: isPokemonMode ? Icons.catching_pokemon : Icons.add,
              tooltip: isPokemonMode ? 'New Pokemon!' : 'Add Event',
              delay: 300,
              isPokemonMode: isPokemonMode,
              isMain: true,
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildAnimatedFab({
    required String heroTag,
    required VoidCallback onPressed,
    required Color backgroundColor,
    required IconData icon,
    required int delay,
    String? tooltip,
    bool isPokemonMode = false,
    bool isMain = false,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + delay),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            decoration: isPokemonMode
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: backgroundColor.withOpacity(0.5),
                        blurRadius: isMain ? 16 : 10,
                        spreadRadius: isMain ? 2 : 1,
                      ),
                    ],
                  )
                : null,
            child: FloatingActionButton(
              heroTag: heroTag,
              onPressed: onPressed,
              backgroundColor: backgroundColor,
              foregroundColor: isPokemonMode && backgroundColor == const Color(0xFFFFEB3B)
                  ? Colors.black87
                  : Colors.white,
              elevation: isPokemonMode ? 12 : 8,
              tooltip: tooltip,
              child: Icon(icon, size: isMain ? 28 : 24),
            ),
          ),
        );
      },
    );
  }
}
