class Event {
  /// Unique identifier for the event (Firestore document ID)
  String? id;

  /// The main title of the event.
  String title;

  /// An optional, longer description for the event.
  String? description;

  /// The start date and time of the event.
  DateTime startTime;

  /// The optional end date and time of the event.
  DateTime? endTime;

  /// The alarm ID used by the alarm package for O(1) deletion lookups
  int? alarmId;

  Event({
    this.id,
    required this.title,
    this.description,
    required this.startTime,
    this.endTime,
    this.alarmId,
  });

  /// Create an Event from Firestore document data
  factory Event.fromMap(Map<String, dynamic> data, String documentId) {
    return Event(
      id: documentId,
      title: data['title'] as String,
      description: data['description'] as String?,
      startTime: (data['startTime'] as dynamic).toDate(),
      endTime: data['endTime'] != null ? (data['endTime'] as dynamic).toDate() : null,
      alarmId: data['alarmId'] as int?,
    );
  }

  /// Convert Event to Map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'startTime': startTime,
      'endTime': endTime,
      'alarmId': alarmId,
    };
  }

  @override
  String toString() {
    return 'Event(id: $id, title: "$title", startTime: $startTime, alarmId: $alarmId)';
  }
}
