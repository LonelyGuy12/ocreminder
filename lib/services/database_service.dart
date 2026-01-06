import 'dart:async';
import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lonelyreminder/models/event_model.dart';

/// A Cloud Firestore-based database service for storing user events
/// Uses user-scoped collections: users/{userId}/events/
class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DatabaseService() {
    _enableOfflinePersistence();
  }

  /// Enable offline persistence for the app to work without internet
  void _enableOfflinePersistence() {
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  /// Get the current user's events collection reference
  CollectionReference<Map<String, dynamic>>? _getUserEventsCollection() {
    final user = _auth.currentUser;
    if (user == null) {
      developer.log('No authenticated user found', name: 'DatabaseService');
      return null;
    }
    return _firestore.collection('users').doc(user.uid).collection('events');
  }

  /// Adds a new Event object to the database
  Future<void> addEvent(Event event) async {
    final collection = _getUserEventsCollection();
    if (collection == null) {
      throw Exception('User must be authenticated to add events');
    }

    try {
      final docRef = await collection.add(event.toMap());
      developer.log('Event added with ID: ${docRef.id}', name: 'DatabaseService');
    } catch (e) {
      developer.log('Error adding event: $e', name: 'DatabaseService', error: e);
      rethrow;
    }
  }

  /// Updates an existing event in the database
  Future<void> updateEvent(Event event) async {
    if (event.id == null) {
      throw Exception('Event ID cannot be null for update');
    }

    final collection = _getUserEventsCollection();
    if (collection == null) {
      throw Exception('User must be authenticated to update events');
    }

    try {
      await collection.doc(event.id).update(event.toMap());
      developer.log('Event updated: ${event.id}', name: 'DatabaseService');
    } catch (e) {
      developer.log('Error updating event: $e', name: 'DatabaseService', error: e);
      rethrow;
    }
  }

  /// Deletes an event from the database by its document ID
  Future<void> deleteEvent(String eventId) async {
    final collection = _getUserEventsCollection();
    if (collection == null) {
      throw Exception('User must be authenticated to delete events');
    }

    try {
      await collection.doc(eventId).delete();
      developer.log('Event deleted: $eventId', name: 'DatabaseService');
    } catch (e) {
      developer.log('Error deleting event: $e', name: 'DatabaseService', error: e);
      rethrow;
    }
  }

  /// Get a real-time stream of all events for the current user
  Stream<List<Event>> getEventsStream() {
    final collection = _getUserEventsCollection();
    if (collection == null) {
      return Stream.value([]);
    }

    return collection.orderBy('startTime', descending: false).snapshots().map(
      (snapshot) {
        return snapshot.docs.map((doc) {
          return Event.fromMap(doc.data(), doc.id);
        }).toList();
      },
    );
  }

  /// Retrieves all events from the database as Event objects
  Future<List<Event>> getAllEvents() async {
    final collection = _getUserEventsCollection();
    if (collection == null) {
      return [];
    }

    try {
      final snapshot = await collection.orderBy('startTime', descending: false).get();
      return snapshot.docs.map((doc) {
        return Event.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      developer.log('Error getting all events: $e', name: 'DatabaseService', error: e);
      return [];
    }
  }

  /// Query event by alarm ID for O(1) deletion (instead of iterating through all events)
  Future<Event?> getEventByAlarmId(int alarmId) async {
    final collection = _getUserEventsCollection();
    if (collection == null) {
      return null;
    }

    try {
      final snapshot = await collection.where('alarmId', isEqualTo: alarmId).limit(1).get();
      if (snapshot.docs.isEmpty) {
        return null;
      }
      return Event.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id);
    } catch (e) {
      developer.log('Error getting event by alarmId: $e', name: 'DatabaseService', error: e);
      return null;
    }
  }

  /// Clears all events from the database
  Future<void> clearAllEvents() async {
    final collection = _getUserEventsCollection();
    if (collection == null) {
      throw Exception('User must be authenticated to clear events');
    }

    try {
      final snapshot = await collection.get();
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      developer.log('All events cleared', name: 'DatabaseService');
    } catch (e) {
      developer.log('Error clearing events: $e', name: 'DatabaseService', error: e);
      rethrow;
    }
  }

  /// Get events that are upcoming (within next 24 hours) for notifications
  Future<List<Event>> getUpcomingEvents() async {
    final collection = _getUserEventsCollection();
    if (collection == null) {
      return [];
    }

    try {
      final now = DateTime.now();
      final next24Hours = now.add(const Duration(hours: 24));
      
      final snapshot = await collection
          .where('startTime', isGreaterThan: now)
          .where('startTime', isLessThan: next24Hours)
          .get();

      return snapshot.docs.map((doc) {
        return Event.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      developer.log('Error getting upcoming events: $e', name: 'DatabaseService', error: e);
      return [];
    }
  }

  /// Get events that have passed since last check
  Future<List<Event>> getPastEventsSince(DateTime since) async {
    final collection = _getUserEventsCollection();
    if (collection == null) {
      return [];
    }

    try {
      final now = DateTime.now();
      final snapshot = await collection
          .where('startTime', isGreaterThan: since)
          .where('startTime', isLessThan: now)
          .get();

      return snapshot.docs.map((doc) {
        return Event.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      developer.log('Error getting past events: $e', name: 'DatabaseService', error: e);
      return [];
    }
  }

  /// Legacy compatibility method - deletes by event ID
  @Deprecated('Use deleteEvent(eventId) instead')
  Future<void> deleteEventById(String id) async {
    await deleteEvent(id);
  }
}
