import 'package:lonelyreminder/models/event_model.dart';

class EventParser {
  /// Parses raw text to extract event details
  static Future<Event> parseEvent(String text) async {
    String cleanedText = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    
    DateTime? parsedTime = _parseDateTime(cleanedText);
    String title = _extractTitle(cleanedText);
    
    if (parsedTime == null) {
      parsedTime = DateTime.now().add(const Duration(hours: 1));
    }
    
    // If parsed time is in the past, adjust to next occurrence
    if (parsedTime.isBefore(DateTime.now())) {
      // Check if it's just the time that's passed today
      final todayWithTime = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        parsedTime.hour,
        parsedTime.minute,
      );
      
      if (todayWithTime.isBefore(DateTime.now())) {
        // Time has passed today, check if date was explicitly set
        if (parsedTime.day == DateTime.now().day && 
            parsedTime.month == DateTime.now().month) {
          // Same day, move to tomorrow
          parsedTime = parsedTime.add(const Duration(days: 1));
        } else {
          // Different day but in past, move to next year
          parsedTime = DateTime(
            parsedTime.year + 1,
            parsedTime.month,
            parsedTime.day,
            parsedTime.hour,
            parsedTime.minute,
          );
        }
      }
    }

    return Event(
      title: title.isEmpty ? 'Reminder' : title,
      startTime: parsedTime,
      description: 'Parsed from: "$text"',
    );
  }

  /// Parse date and time from text
  static DateTime? _parseDateTime(String text) {
    final lowerText = text.toLowerCase();
    DateTime now = DateTime.now();
    DateTime? date;
    int? hour;
    int? minute;
    bool isPM = false;
    bool isAM = false;

    // Check for AM/PM
    if (lowerText.contains('pm') || lowerText.contains('p.m')) {
      isPM = true;
    } else if (lowerText.contains('am') || lowerText.contains('a.m')) {
      isAM = true;
    }

    // Parse time patterns
    // Pattern: 11 pm, 11pm, 11:00 pm, 11:30pm
    final timePatterns = [
      RegExp(r'(\d{1,2}):(\d{2})\s*(am|pm|a\.m|p\.m)?', caseSensitive: false),
      RegExp(r'(\d{1,2})\s*(am|pm|a\.m|p\.m)', caseSensitive: false),
      RegExp(r'at\s+(\d{1,2}):?(\d{2})?\s*(am|pm|a\.m|p\.m)?', caseSensitive: false),
    ];

    for (final pattern in timePatterns) {
      final match = pattern.firstMatch(lowerText);
      if (match != null) {
        hour = int.tryParse(match.group(1) ?? '');
        minute = int.tryParse(match.group(2) ?? '0') ?? 0;
        
        String? ampm = match.groupCount >= 3 ? match.group(3) : null;
        if (ampm != null) {
          if (ampm.startsWith('p')) isPM = true;
          if (ampm.startsWith('a')) isAM = true;
        }
        break;
      }
    }

    // Adjust for PM/AM
    if (hour != null) {
      if (isPM && hour < 12) hour += 12;
      if (isAM && hour == 12) hour = 0;
    }

    // Parse date patterns
    // Pattern: today, tomorrow, Dec 8, December 8, 8 Dec, 8/12, 12/8
    if (lowerText.contains('today')) {
      date = DateTime(now.year, now.month, now.day);
    } else if (lowerText.contains('tomorrow')) {
      date = DateTime(now.year, now.month, now.day + 1);
    } else {
      // Try month name patterns
      final months = {
        'jan': 1, 'january': 1,
        'feb': 2, 'february': 2,
        'mar': 3, 'march': 3,
        'apr': 4, 'april': 4,
        'may': 5,
        'jun': 6, 'june': 6,
        'jul': 7, 'july': 7,
        'aug': 8, 'august': 8,
        'sep': 9, 'september': 9,
        'oct': 10, 'october': 10,
        'nov': 11, 'november': 11,
        'dec': 12, 'december': 12,
      };

      // Pattern: Dec 8, December 8, 8 Dec, 8th December
      for (final entry in months.entries) {
        final patterns = [
          RegExp('${entry.key}\\w*\\s+(\\d{1,2})', caseSensitive: false),
          RegExp('(\\d{1,2})\\s*(?:st|nd|rd|th)?\\s+${entry.key}', caseSensitive: false),
        ];
        
        for (final pattern in patterns) {
          final match = pattern.firstMatch(lowerText);
          if (match != null) {
            int day = int.tryParse(match.group(1) ?? '') ?? now.day;
            // Always use current year first
            date = DateTime(now.year, entry.value, day);
            break;
          }
        }
        if (date != null) break;
      }

      // Pattern: numeric dates like 8/12 or 12/8
      if (date == null) {
        final numericDate = RegExp(r'(\d{1,2})[/\-](\d{1,2})(?:[/\-](\d{2,4}))?');
        final match = numericDate.firstMatch(text);
        if (match != null) {
          int first = int.tryParse(match.group(1) ?? '') ?? 1;
          int second = int.tryParse(match.group(2) ?? '') ?? 1;
          int year = int.tryParse(match.group(3) ?? '') ?? now.year;
          if (year < 100) year += 2000;
          
          // Assume day/month format
          int day = first;
          int month = second;
          if (month > 12) {
            // Swap if month > 12
            day = second;
            month = first;
          }
          date = DateTime(year, month, day);
        }
      }
    }

    // Combine date and time
    if (date != null && hour != null) {
      return DateTime(date.year, date.month, date.day, hour, minute ?? 0);
    } else if (date != null) {
      // Date without time - default to 9 AM
      return DateTime(date.year, date.month, date.day, 9, 0);
    } else if (hour != null) {
      // Time without date - assume today or tomorrow
      DateTime result = DateTime(now.year, now.month, now.day, hour, minute ?? 0);
      if (result.isBefore(now)) {
        result = result.add(const Duration(days: 1));
      }
      return result;
    }

    return null;
  }

  /// Extract title from text by removing date/time parts
  static String _extractTitle(String text) {
    String title = text;
    
    // Remove common time patterns
    final patternsToRemove = [
      RegExp(r'\b\d{1,2}:\d{2}\s*(am|pm|a\.m|p\.m)?\b', caseSensitive: false),
      RegExp(r'\b\d{1,2}\s*(am|pm|a\.m|p\.m)\b', caseSensitive: false),
      RegExp(r'\bat\s+\d{1,2}(:\d{2})?\s*(am|pm)?\b', caseSensitive: false),
      RegExp(r'\b(today|tomorrow)\b', caseSensitive: false),
      RegExp(r'\b(on|at|by)\b', caseSensitive: false),
      RegExp(r'\b(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\w*\s+\d{1,2}\b', caseSensitive: false),
      RegExp(r'\b\d{1,2}\s*(st|nd|rd|th)?\s+(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\w*\b', caseSensitive: false),
      RegExp(r'\b\d{1,2}[/\-]\d{1,2}([/\-]\d{2,4})?\b'),
    ];

    for (final pattern in patternsToRemove) {
      title = title.replaceAll(pattern, ' ');
    }

    // Clean up
    title = title.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    // Capitalize first letter
    if (title.isNotEmpty) {
      title = title[0].toUpperCase() + title.substring(1);
    }

    return title;
  }
}
