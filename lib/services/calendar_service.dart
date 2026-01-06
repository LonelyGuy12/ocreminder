import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:http/http.dart' as http;
import 'package:lonelyreminder/models/event_model.dart';
import 'package:lonelyreminder/services/database_service.dart';
import 'package:lonelyreminder/services/alarm_service.dart';

class CalendarService {
  final DatabaseService _databaseService = DatabaseService();

  /// Create an authenticated Google Calendar API client
  calendar.CalendarApi _createCalendarApi(String accessToken) {
    final authClient = _AuthorizedHttpClient(accessToken);
    return calendar.CalendarApi(authClient);
  }

  /// Fetch events from Google Calendar
  Future<List<calendar.Event>> importEventsFromGoogleCalendar(String accessToken) async {
    try {
      final calendarApi = _createCalendarApi(accessToken);
      final now = DateTime.now();
      
      final events = await calendarApi.events.list(
        'primary',
        timeMin: now.toUtc(),
        timeMax: now.add(const Duration(days: 7)).toUtc(),
        maxResults: 100,
        orderBy: 'startTime',
        singleEvents: true,
      );
      
      return events.items ?? [];
    } catch (e) {
      return [];
    }
  }

  /// Convert a Google Calendar event to our local Event model
  Event convertGoogleCalendarEventToModel(calendar.Event googleEvent) {
    final DateTime startDateTime;
    if (googleEvent.start?.dateTime != null) {
      startDateTime = googleEvent.start!.dateTime!;
    } else if (googleEvent.start?.date != null) {
      startDateTime = DateTime.parse(googleEvent.start!.date! as String);
    } else {
      startDateTime = DateTime.now();
    }
    
    final DateTime endDateTime;
    if (googleEvent.end?.dateTime != null) {
      endDateTime = googleEvent.end!.dateTime!;
    } else if (googleEvent.end?.date != null) {
      endDateTime = DateTime.parse(googleEvent.end!.date! as String);
    } else {
      endDateTime = startDateTime.add(const Duration(hours: 1));
    }
    
    return Event(
      id: googleEvent.id ?? 'gcal_${googleEvent.summary}_${startDateTime.millisecondsSinceEpoch}',
      title: googleEvent.summary ?? 'Untitled Event',
      description: googleEvent.description,
      startTime: startDateTime,
      endTime: endDateTime,
    );
  }

  /// Check if event already exists in database (duplicate check)
  Future<bool> _eventExists(String eventId) async {
    try {
      final allEvents = await _databaseService.getAllEvents();
      return allEvents.any((event) => event.id == eventId);
    } catch (e) {
      return false;
    }
  }

  /// Import events from Google Calendar to our local database with alarms
  Future<int> importToDatabase(String accessToken) async {
    try {
      final googleEvents = await importEventsFromGoogleCalendar(accessToken);
      int importedCount = 0;
      
      for (final googleEvent in googleEvents) {
        try {
          final localEvent = convertGoogleCalendarEventToModel(googleEvent);
          
          if (localEvent.startTime.isAfter(DateTime.now())) {
            final exists = await _eventExists(localEvent.id ?? '');
            if (!exists) {
              await _databaseService.addEvent(localEvent);
              await AlarmService.scheduleAlarm(localEvent);
              importedCount++;
            }
          }
        } catch (e) {
          continue;
        }
      }
      
      return importedCount;
    } catch (e) {
      return 0;
    }
  }
}

/// Custom HTTP client that adds authorization header with access token
class _AuthorizedHttpClient extends http.BaseClient {
  final String accessToken;
  final http.Client _inner = http.Client();

  _AuthorizedHttpClient(this.accessToken);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['authorization'] = 'Bearer $accessToken';
    return _inner.send(request);
  }
}