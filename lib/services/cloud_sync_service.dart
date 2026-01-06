import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lonelyreminder/models/user_profile.dart';
import 'package:lonelyreminder/models/event_model.dart';
import 'package:get_storage/get_storage.dart';

class CloudSyncService {
  static final CloudSyncService _instance = CloudSyncService._internal();
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _storage = GetStorage();

  factory CloudSyncService() {
    return _instance;
  }

  CloudSyncService._internal();

  /// Save user profile to Firestore
  Future<bool> saveUserProfile(User user) async {
    try {
      final userProfile = UserProfile(
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
        photoUrl: user.photoURL,
        createdAt: user.metadata.creationTime ?? DateTime.now(),
        lastSyncedAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(user.uid).set(
        userProfile.toMap(),
        SetOptions(merge: true),
      );

      await _storage.write('user_profile', userProfile.toMap());
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Load user profile from Firestore
  Future<UserProfile?> loadUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserProfile.fromMap(doc.data() ?? {});
      }
    } catch (e) {
      // Fall back to local storage
    }
    return null;
  }

  /// Sync user profile data (pull from cloud)
  Future<UserProfile?> syncUserProfile(String uid) async {
    try {
      final profile = await loadUserProfile(uid);
      if (profile != null) {
        await _storage.write('user_profile', profile.toMap());
        return profile;
      }
    } catch (e) {
      // Continue with local profile
    }
    return null;
  }

  /// Get cached user profile from local storage
  UserProfile? getCachedUserProfile() {
    try {
      final data = _storage.read('user_profile');
      if (data != null) {
        return UserProfile.fromMap(Map<String, dynamic>.from(data));
      }
    } catch (e) {
      // Return null if cache is invalid
    }
    return null;
  }

  /// Save events to Firestore for cloud backup
  Future<bool> saveEventsToCloud(String uid, List<Event> events) async {
    try {
      final eventMaps = events.map((e) => {
        'id': e.id,
        'title': e.title,
        'description': e.description,
        'startTime': e.startTime.toIso8601String(),
        'endTime': e.endTime?.toIso8601String(),
      }).toList();

      await _firestore.collection('users').doc(uid).update({
        'events': eventMaps,
        'lastSyncedAt': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Load events from Firestore
  Future<List<Event>> loadEventsFromCloud(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final eventMaps = doc.data()?['events'] as List<dynamic>? ?? [];
        return eventMaps.map((e) {
          final event = Map<String, dynamic>.from(e);
          return Event(
            id: event['id'],
            title: event['title'] ?? 'Untitled',
            description: event['description'],
            startTime: DateTime.parse(event['startTime']),
            endTime: event['endTime'] != null ? DateTime.parse(event['endTime']) : null,
          );
        }).toList();
      }
    } catch (e) {
      // Return empty list on error
    }
    return [];
  }

  /// Set up real-time listener for user changes
  void listenToUserProfile(String uid, Function(UserProfile?) onUpdate) {
    try {
      _firestore.collection('users').doc(uid).snapshots().listen(
        (snapshot) {
          if (snapshot.exists) {
            final profile = UserProfile.fromMap(snapshot.data() ?? {});
            onUpdate(profile);
          } else {
            onUpdate(null);
          }
        },
        onError: (error) {
          onUpdate(null);
        },
      );
    } catch (e) {
      onUpdate(null);
    }
  }

  /// Check if user data exists in cloud
  Future<bool> userDataExistsInCloud(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Get last sync time for user
  Future<DateTime?> getLastSyncTime(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        final lastSyncStr = data['lastSyncedAt'];
        if (lastSyncStr != null) {
          return DateTime.parse(lastSyncStr);
        }
      }
    } catch (e) {
      // Return null on error
    }
    return null;
  }

  /// Delete user data from cloud
  Future<bool> deleteUserData(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check if cloud sync is needed (last sync older than 1 hour)
  Future<bool> isSyncNeeded(String uid) async {
    try {
      final lastSync = await getLastSyncTime(uid);
      if (lastSync == null) return true;

      final now = DateTime.now();
      final difference = now.difference(lastSync);
      return difference.inHours >= 1;
    } catch (e) {
      return true;
    }
  }
}
