import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/firebase_auth_service.dart';
import '../providers/user_provider.dart';
import 'dart:async';

enum AuthStatus { initial, authenticated, unauthenticated, authenticating, error }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.initial;
  String? _errorMessage;
  User? _currentUser;
  final FirebaseAuthService _authService = FirebaseAuthService();
  final UserProvider? _userProvider;
  Timer? _authDebounceTimer;
  String? _lastLoadedUserId;

  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  User? get currentUser => _currentUser;
  bool get isUserDataReady => _userProvider?.user != null && !_userProvider!.isLoading;
  bool get isAuthenticatedAndReady => status == AuthStatus.authenticated && isUserDataReady;
  bool get isLoggedIn => status == AuthStatus.authenticated;

  AuthProvider(this._userProvider) {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    // Debounce rapid successive calls
    if (_authDebounceTimer?.isActive ?? false) {
      print('AuthProvider: Debouncing rapid checkAuthStatus call');
      return; // Skip if a check is already in progress
    }
    
    // Set debounce timer
    _authDebounceTimer?.cancel();
    _authDebounceTimer = Timer(const Duration(milliseconds: 500), () {});
    
    // If we recently loaded this user, don't reload
    final currentUid = _authService.currentUser?.uid;
    if (currentUid != null && currentUid == _lastLoadedUserId && _status == AuthStatus.authenticated) {
      print('AuthProvider: Skipping reload for already loaded user: $currentUid');
      return;
    }
    
    _status = AuthStatus.authenticating;

    try {
      final firebaseUser = _authService.currentUser;
      if (firebaseUser != null) {
        await _loadUser(firebaseUser.uid);
        bool dataLoadSuccess = false;
        if (_userProvider != null) {
          print('AuthProvider: checkAuthStatus - User authenticated (${firebaseUser.uid}). Triggering UserProvider.loadUserData...');
          await _userProvider!.loadUserData(firebaseUser.uid);
          if (_userProvider!.user != null && _userProvider!.user!.id == firebaseUser.uid) {
            dataLoadSuccess = true;
            _lastLoadedUserId = firebaseUser.uid; // Track successfully loaded user
            print('AuthProvider: checkAuthStatus - UserProvider successfully loaded data for ${firebaseUser.uid}.');
            await _userProvider!.updateUserLoginInfo();
          } else {
            print('AuthProvider: checkAuthStatus - UserProvider FAILED to load data for ${firebaseUser.uid} (Document likely missing).');
          }
        } else {
          print('AuthProvider: checkAuthStatus - UserProvider is null, cannot load detailed data.');
        }

        if (dataLoadSuccess) {
          _status = AuthStatus.authenticated;
        } else {
          _status = AuthStatus.unauthenticated;
          _errorMessage = 'User profile data missing. Please sign up again or contact support.';
          _userProvider?.clearUserData();
          notifyListeners();
        }
      } else {
        print('AuthProvider: checkAuthStatus - No Firebase user found.');
        _status = AuthStatus.unauthenticated;
        _userProvider?.clearUserData();
        notifyListeners();
      }
    } catch (e) {
      print('AuthProvider: checkAuthStatus - Error: $e');
      _status = AuthStatus.unauthenticated;
      _userProvider?.clearUserData();
      _errorMessage = 'Failed to check authentication status';
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;

    try {
      final userCredential = await _authService.signInWithEmailAndPassword(email, password);
      final userId = userCredential.user!.uid;

      await _loadUser(userId);

      if (_userProvider != null) {
        print('AuthProvider: login successful for $userId. Triggering UserProvider.loadUserData...');
        await _userProvider!.loadUserData(userId);
        print('AuthProvider: login - Calling updateUserLoginInfo for $userId...');
        await _userProvider!.updateUserLoginInfo();
      } else {
        print('AuthProvider: login - UserProvider is null.');
      }

      await _authService.updateLastActive(userId);

      final prefs = await SharedPreferences.getInstance();
      if (_currentUser != null) {
        await prefs.setBool('is_individual', _currentUser!.isIndividual);
      }

      _status = AuthStatus.authenticated;
      return true;
    } on firebase_auth.FirebaseAuthException catch (e) {
      print('AuthProvider: login error - ${e.code}');
      _status = AuthStatus.error;
      if (e.code == 'user-not-found' || e.code == 'invalid-email') {
        _errorMessage = 'No user found with this email.';
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        _errorMessage = 'Incorrect password.';
      } else {
        _errorMessage = 'Login failed: ${e.message}';
      }
      return false;
    } catch (e) {
      print('AuthProvider: login error - $e');
      _status = AuthStatus.error;
      _errorMessage = 'Login failed: ${e.toString()}';
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
    File? profileImageFile,
    Uint8List? profileImageBytes,
    String? profileImageName,
  }) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;

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
        focusAreas,
        profileImageFile,
        profileImageBytes,
        profileImageName,
      );
      final userId = userCredential.user!.uid;

      await _loadUser(userId);

      if (_userProvider != null) {
        print('AuthProvider: register successful for $userId. Triggering UserProvider.loadUserData...');
        await _userProvider!.loadUserData(userId);
      } else {
        print('AuthProvider: register - UserProvider is null.');
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_first_launch', true);
      await prefs.setBool('profile_setup_complete', false);

      // Keep the user authenticated during profile setup
      _status = AuthStatus.authenticated;
      _lastLoadedUserId = userId;
      notifyListeners();
      
      return true;
    } on firebase_auth.FirebaseAuthException catch (e) {
      print('AuthProvider: register error - ${e.code}');
      _status = AuthStatus.error;
      if (e.code == 'weak-password') {
        _errorMessage = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        _errorMessage = 'An account already exists for that email.';
      } else {
        _errorMessage = 'Registration failed: ${e.message}';
      }
      return false;
    } catch (e) {
      print('AuthProvider: register error - $e');
      _status = AuthStatus.error;
      _errorMessage = 'Registration failed: ${e.toString()}';
      return false;
    }
  }
  
  Future<bool> logout() async {
    try {
      await _authService.signOut();
      
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
      _userProvider?.clearUserData();
      notifyListeners();
      return true;
    } catch (e) {
      print('AuthProvider: logout error - $e');
      _errorMessage = 'Logout failed: ${e.toString()}';
      return false;
    }
  }
  
  Future<void> _loadUser(String uid) async {
    try {
      final userData = await _authService.getUserData(uid);
      if (userData != null) {
        _currentUser = userData;
        print('AuthProvider: _loadUser successful for $uid. Name: ${_currentUser?.fullName}');
      } else {
        print('AuthProvider: _loadUser - No user data found in Firestore for $uid');
      }
    } catch (e) {
      print('AuthProvider: _loadUser error: $e');
    }
  }
  
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
  
  Future<String?> updateUserProfile({
    required String uid,
    String? fullName,
    String? username,
    String? sport,
    String? university,
    String? universityCode,
    bool? isIndividual,
    List<String>? focusAreas,
    File? imageFile,
    Uint8List? imageBytes,
    String? imageUrl,
  }) async {
    try {
      return await _authService.updateUserProfile(
        uid: uid,
        fullName: fullName,
        username: username,
        sport: sport,
        university: university,
        universityCode: universityCode,
        isIndividual: isIndividual,
        focusAreas: focusAreas,
        imageFile: imageFile,
        imageBytes: imageBytes,
        profileImageUrl: imageUrl,
      );
    } catch (e) {
      print('Error in updateUserProfile: $e');
      return e.toString();
    }
  }
  
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
  
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to send password reset email: ${e.toString()}';
      return false;
    }
  }

  @override
  void dispose() {
    _authDebounceTimer?.cancel();
    super.dispose();
  }
} 