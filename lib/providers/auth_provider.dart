import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lonelyreminder/services/google_auth_service.dart';

/// Provider for managing authentication state across the app
class AuthProvider extends ChangeNotifier {
  final GoogleAuthService _authService = GoogleAuthService();
  User? _currentUser;
  bool _isLoading = false;

  AuthProvider() {
    _init();
  }

  /// Initialize the auth provider by listening to auth state changes
  void _init() {
    _currentUser = _authService.getCurrentUser();
    _authService.userStream.listen((user) {
      _currentUser = user;
      notifyListeners();
    });
  }

  /// Get the current user
  User? get currentUser => _currentUser;

  /// Check if user is signed in
  bool get isSignedIn => _currentUser != null;

  /// Check if authentication is in progress
  bool get isLoading => _isLoading;

  /// Sign in with Google
  Future<bool> signIn() async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _authService.signInWithGoogle();
      _isLoading = false;
      notifyListeners();
      
      if (result != null) {
        developer.log('User signed in: ${result.user?.displayName}', name: 'AuthProvider');
        return true;
      }
      return false;
    } catch (e) {
      developer.log('Sign in error: $e', name: 'AuthProvider', error: e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signOut();
      developer.log('User signed out', name: 'AuthProvider');
    } catch (e) {
      developer.log('Sign out error: $e', name: 'AuthProvider', error: e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get Google Calendar access token
  Future<String?> getCalendarAccessToken() async {
    return await _authService.getGoogleCalendarAccessToken();
  }
}
