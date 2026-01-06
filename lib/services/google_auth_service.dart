import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;

class GoogleAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
      calendar.CalendarApi.calendarScope, // For reading and writing calendar events
    ],
  );

  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      developer.log('Error during Google Sign-in: $e', name: 'GoogleAuthService', error: e);
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Stream<User?> get userStream => _auth.authStateChanges();

  /// Get the access token to use with Google Calendar API
  Future<String?> getGoogleCalendarAccessToken() async {
    try {
      // Try to get current user, or sign in silently if needed
      GoogleSignInAccount? googleUser = _googleSignIn.currentUser;
      
      if (googleUser == null) {
        // Try silent sign in first
        googleUser = await _googleSignIn.signInSilently();
      }
      
      if (googleUser == null) {
        // If still null, do a full sign in
        googleUser = await _googleSignIn.signIn();
      }
      
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      return googleAuth.accessToken;
    } catch (e) {
      developer.log('Error getting calendar access token: $e', name: 'GoogleAuthService', error: e);
      return null;
    }
  }
}
