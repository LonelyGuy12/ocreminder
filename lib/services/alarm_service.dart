import 'dart:io' show Platform;
import 'dart:developer' as developer;
import 'package:alarm/alarm.dart';
import 'package:lonelyreminder/models/event_model.dart';
import 'package:intl/intl.dart';

class AlarmService {
  // Alarm package only supports iOS and Android
  static bool get _isSupported => Platform.isIOS || Platform.isAndroid;

  static Future<void> scheduleAlarm(Event event) async {
    if (!_isSupported) {
      developer.log('Alarm not supported on this platform', name: 'AlarmService');
      return;
    }
    
    try {
      if (event.startTime.isBefore(DateTime.now())) {
        developer.log('Event ${event.title} is in the past, not scheduling alarm', name: 'AlarmService');
        return;
      }

      final eventId = _generateAlarmId(event);
      
      // Cancel any existing alarm with this ID first
      await Alarm.stop(eventId);

      // Using the alarm package's built-in sound
      // On Android, the notification channel in MainActivity uses system alarm sound
      final alarmSettings = AlarmSettings(
        id: eventId,
        dateTime: event.startTime,
        assetAudioPath: 'assets/alarm.mp3',
        loopAudio: true,
        vibrate: true,
        volumeSettings: const VolumeSettings.fixed(volume: 1.0),
        warningNotificationOnKill: true,
        androidFullScreenIntent: true,
        notificationSettings: NotificationSettings(
          title: '🔔 ${event.title}',
          body: event.description ?? 'Reminder at ${DateFormat.jm().format(event.startTime)}',
          stopButton: 'Dismiss',
          icon: 'notification_icon',
        ),
      );

      await Alarm.set(alarmSettings: alarmSettings);
      developer.log('Alarm scheduled for ${event.title} at ${event.startTime} with ID $eventId', name: 'AlarmService');
    } catch (e) {
      developer.log('Error scheduling alarm: $e', name: 'AlarmService', error: e);
      rethrow;
    }
  }

  static Future<void> cancelAlarm(Event event) async {
    if (!_isSupported) return;
    try {
      final eventId = _generateAlarmId(event);
      await Alarm.stop(eventId);
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> cancelAlarmById(int id) async {
    if (!_isSupported) return;
    try {
      await Alarm.stop(id);
    } catch (e) {
      rethrow;
    }
  }

  static Future<List<AlarmSettings>> getScheduledAlarms() async {
    if (!_isSupported) return [];
    try {
      return await Alarm.getAlarms();
    } catch (e) {
      return [];
    }
  }

  static int _generateAlarmId(Event event) {
    if (event.id != null) {
      try {
        return int.parse(event.id!.split('_').first);
      } catch (e) {
        return event.title.hashCode.abs() % 0x7FFFFFFF;
      }
    }
    return event.title.hashCode.abs() % 0x7FFFFFFF;
  }
  
  // Public method for background service
  static int generateAlarmId(Event event) => _generateAlarmId(event);

  static Future<void> stopAllAlarms() async {
    if (!_isSupported) return;
    try {
      final alarms = await Alarm.getAlarms();
      for (final alarm in alarms) {
        await Alarm.stop(alarm.id);
      }
    } catch (e) {
      rethrow;
    }
  }
}
