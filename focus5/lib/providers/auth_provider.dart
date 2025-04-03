import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import '../constants/dummy_data.dart';

enum AuthStatus { initial, authenticated, unauthenticated, authenticating, error }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.initial;
  String? _errorMessage;
  User? _currentUser;
  final _secureStorage = const FlutterSecureStorage();

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
      final token = await _secureStorage.read(key: 'auth_token');
      if (token != null) {
        // In a real app, validate token with backend
        // For now, just load the dummy user
        await _loadUser();
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
      // In a real app, we would validate credentials with the backend
      // For now, just simulate a delay and success if the email contains "university"
      await Future.delayed(const Duration(seconds: 1));
      
      // Here we're using dummy data
      if (email.toLowerCase().contains('university')) {
        _currentUser = DummyData.dummyUniversityUser;
      } else {
        _currentUser = DummyData.dummyUser;
      }
      
      // Save the token in secure storage
      await _secureStorage.write(key: 'auth_token', value: 'dummy_token_${_currentUser!.id}');
      
      // Save user type (individual or university) in shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_individual', _currentUser!.isIndividual);
      
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Login failed. Please check your credentials.';
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
      // In a real app, we would send registration data to the backend
      // For now, just simulate a delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Create a new user based on provided data
      final newUser = User(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        username: username,
        fullName: fullName,
        profileImageUrl: null, // No image yet
        sport: sport,
        university: university,
        universityCode: universityCode,
        isIndividual: isIndividual,
        focusAreas: focusAreas,
        xp: 0, // New user starts with 0 XP
        badges: [], // No badges initially
        completedCourses: [],
        completedAudios: [],
        savedCourses: [],
        streak: 0,
        lastActive: DateTime.now(),
      );
      
      _currentUser = newUser;
      
      // Save the token in secure storage
      await _secureStorage.write(key: 'auth_token', value: 'dummy_token_${_currentUser!.id}');
      
      // Save user type in shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_individual', isIndividual);
      await prefs.setBool('is_first_launch', false);
      
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Registration failed. Please try again.';
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> logout() async {
    try {
      // Clear the auth token
      await _secureStorage.delete(key: 'auth_token');
      
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Logout failed';
      notifyListeners();
      return false;
    }
  }
  
  Future<void> _loadUser() async {
    // In a real app, fetch user data from backend using the token
    // For now, just load dummy data
    final prefs = await SharedPreferences.getInstance();
    final isIndividual = prefs.getBool('is_individual') ?? true;
    
    if (isIndividual) {
      _currentUser = DummyData.dummyUser;
    } else {
      _currentUser = DummyData.dummyUniversityUser;
    }
  }
  
  // Verify a university code
  bool verifyUniversityCode(String code) {
    return DummyData.universities.containsValue(code);
  }
  
  // Get university name from code
  String? getUniversityNameFromCode(String code) {
    for (var entry in DummyData.universities.entries) {
      if (entry.value == code) {
        return entry.key;
      }
    }
    return null;
  }
} 