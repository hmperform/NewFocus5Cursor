import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/firebase_auth_service.dart';

enum AuthStatus { initial, authenticated, unauthenticated, authenticating, error }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.initial;
  String? _errorMessage;
  User? _currentUser;
  final FirebaseAuthService _authService = FirebaseAuthService();

  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  AuthProvider() {
    // Check if we have a stored auth token on initialization
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    _status = AuthStatus.authenticating;
    notifyListeners();

    try {
      final user = _authService.currentUser;
      if (user != null) {
        await _loadUser(user.uid);
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = 'Failed to check authentication status';
    }
    
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      final userCredential = await _authService.signInWithEmailAndPassword(email, password);
      await _loadUser(userCredential.user!.uid);
      
      // Update last active time
      await _authService.updateLastActive(userCredential.user!.uid);
      
      // Save user type in shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_individual', _currentUser!.isIndividual);
      
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on firebase_auth.FirebaseAuthException catch (e) {
      _status = AuthStatus.error;
      if (e.code == 'user-not-found') {
        _errorMessage = 'No user found with this email.';
      } else if (e.code == 'wrong-password') {
        _errorMessage = 'Incorrect password.';
      } else {
        _errorMessage = 'Login failed: ${e.message}';
      }
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Login failed: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    required String username,
    required bool isIndividual,
    String? university,
    String? universityCode,
    String? sport,
    required List<String> focusAreas,
  }) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      final userCredential = await _authService.createUserWithEmailAndPassword(
        email, 
        password, 
        fullName, 
        username, 
        isIndividual,
        sport,
        university,
        universityCode,
        focusAreas
      );
      
      await _loadUser(userCredential.user!.uid);
      
      // Save user type in shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_individual', isIndividual);
      await prefs.setBool('is_first_launch', false);
      
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on firebase_auth.FirebaseAuthException catch (e) {
      _status = AuthStatus.error;
      if (e.code == 'weak-password') {
        _errorMessage = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        _errorMessage = 'An account already exists for that email.';
      } else {
        _errorMessage = 'Registration failed: ${e.message}';
      }
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Registration failed: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> logout() async {
    try {
      await _authService.signOut();
      
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Logout failed: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
  
  Future<void> _loadUser(String uid) async {
    try {
      final userData = await _authService.getUserData(uid);
      if (userData != null) {
        _currentUser = userData;
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }
  
  // Verify a university code
  Future<bool> verifyUniversityCode(String code) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('universities')
          .where('code', isEqualTo: code)
          .limit(1)
          .get();
      
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error verifying university code: $e');
      return false;
    }
  }
  
  // Get university name from code
  Future<String?> getUniversityNameFromCode(String code) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('universities')
          .where('code', isEqualTo: code)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data()['name'] as String?;
      }
      return null;
    } catch (e) {
      print('Error getting university name: $e');
      return null;
    }
  }
  
  // Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to send password reset email: ${e.toString()}';
      return false;
    }
  }
} 