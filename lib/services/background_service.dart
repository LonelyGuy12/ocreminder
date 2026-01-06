import 'package:lonelyreminder/services/database_service.dart';
import 'package:lonelyreminder/services/alarm_service.dart';
import 'dart:async';
import 'dart:io' show Platform;
import 'dart:developer' as developer;
import 'package:workmanager/workmanager.dart';

class BackgroundService {
  static Timer? _cleanupTimer;
  static Timer? _alarmCheckTimer;
  
  static Future<void> initialize() async {
    // Initialize periodic checks for cleaning up old events
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _cleanupOldEvents();
    });
    
    // Initialize periodic checks to ensure alarms are scheduled
    _alarmCheckTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
      _verifyAlarms();
    });
  }
  
  static Future<void> _cleanupOldEvents() async {
    try {
      final databaseService = DatabaseService();
      final allEvents = await databaseService.getAllEvents();
      final now = DateTime.now();
      developer.log('Background service checking for old events. Current time: $now, Total events: ${allEvents.length}', name: 'BackgroundService');
      
      // Remove past events that are more than 1 hour old
      // Get events that have passed in the last 24 hours
      final oldCheckTime = now.subtract(const Duration(hours: 24));
      final pastEvents = await databaseService.getPastEventsSince(oldCheckTime);
      developer.log('Found ${pastEvents.length} past events to delete', name: 'BackgroundService');
      
      // Delete past events and their alarms
      for (final event in pastEvents) {
        if (event.id != null) {
          developer.log('Deleting past event: ${event.title}, ID: ${event.id}', name: 'BackgroundService');
          await databaseService.deleteEvent(event.id!);
          await AlarmService.cancelAlarm(event);
        }
      }
    } catch (e) {
      developer.log('Error in _cleanupOldEvents: $e', name: 'BackgroundService', error: e);
    }
  }
  
  static Future<void> _verifyAlarms() async {
    try {
      final databaseService = DatabaseService();
      final allEvents = await databaseService.getAllEvents();
      final scheduledAlarms = await AlarmService.getScheduledAlarms();
      final now = DateTime.now();
      developer.log('Verifying alarms. Events: ${allEvents.length}, Scheduled alarms: ${scheduledAlarms.length}', name: 'BackgroundService');
      
      // Check if any future events are missing alarms
      for (final event in allEvents) {
        if (event.startTime.isAfter(now)) {
          final eventId = AlarmService.generateAlarmId(event);
          final hasAlarm = scheduledAlarms.any((alarm) => alarm.id == eventId);
          // If alarm is not scheduled, reschedule it
          if (!hasAlarm) {
            developer.log('Event "${event.title}" missing alarm, rescheduling...', name: 'BackgroundService');
            await AlarmService.scheduleAlarm(event);
          }
        }
      }
    } catch (e) {
      developer.log('Error in _verifyAlarms: $e', name: 'BackgroundService', error: e);
    }
  }
  
  static void dispose() {
    _cleanupTimer?.cancel();
    _alarmCheckTimer?.cancel();
  }
}