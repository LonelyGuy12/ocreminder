class UserProfile {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime lastSyncedAt;

  UserProfile({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    required this.createdAt,
    required this.lastSyncedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'lastSyncedAt': lastSyncedAt.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] ?? '',
      email: map['email'],
      displayName: map['displayName'],
      photoUrl: map['photoUrl'],
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      lastSyncedAt: DateTime.parse(map['lastSyncedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  UserProfile copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastSyncedAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }

  @override
  String toString() {
    return 'UserProfile(uid: $uid, email: $email, displayName: $displayName)';
  }
}
