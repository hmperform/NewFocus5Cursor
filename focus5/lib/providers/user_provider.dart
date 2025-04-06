import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user_model.dart';
import '../models/content_models.dart';
import '../services/firebase_storage_service.dart';
import '../services/badge_service.dart';
import '../services/user_level_service.dart';
import '../providers/auth_provider.dart';
import '../services/firebase_auth_service.dart';
import 'package:provider/provider.dart';
import '../main.dart'; // Import to access navigatorKey

class UserProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorageService _storageService = FirebaseStorageService();
  final BadgeService _badgeService = BadgeService();
  final AuthProvider? _authProvider = null;
  
  User? _user;
  List<JournalEntry> _journalEntries = [];
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  List<JournalEntry> get journalEntries => _journalEntries;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get xp => _user?.xp ?? 0;
  int get focusPoints => _user?.focusPoints ?? 0;
  int get streak => _user?.streak ?? 0;
  List<AppBadge> get badges => _user?.badges ?? [];
  List<String> get focusAreas => _user?.focusAreas ?? [];
  
  // Level-related getters
  int get level => UserLevelService.getUserLevel(_user?.xp ?? 0);
  int get xpForNextLevel => UserLevelService.getXpForNextLevel(_user?.xp ?? 0);
  double get levelProgress => UserLevelService.getLevelProgress(_user?.xp ?? 0);

  void setUser(User user) {
    _user = user;
    notifyListeners();
  }

  Future<void> loadUserData(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Get user data from Firestore
      final docSnapshot = await _firestore.collection('users').doc(userId).get();
      
      if (docSnapshot.exists) {
        _user = User.fromFirestore(docSnapshot);
        await _loadJournalEntries(userId);
        await _checkAndUpdateStreak(userId);
        
        // Check for new badges
        final newBadges = await _badgeService.checkForNewBadges(userId, _user!);
        if (newBadges.isNotEmpty) {
          // Update local user with new badges
          final allBadges = [..._user!.badges, ...newBadges];
          _user = _user!.copyWith(
            badges: allBadges,
            xp: _user!.xp + newBadges.fold(0, (sum, badge) => sum + badge.xpValue),
          );
        }
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load user data: ${e.toString()}';
      notifyListeners();
    }
  }

  // Get real-time updates for user data
  Stream<User?> getUserStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
          if (snapshot.exists) {
            return User.fromFirestore(snapshot);
          }
          return null;
        });
  }

  Future<void> _loadJournalEntries(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('journal_entries')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      _journalEntries = querySnapshot.docs
          .map((doc) => JournalEntry.fromJson(doc.data()))
          .toList();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading journal entries: $e');
    }
  }

  Future<void> _checkAndUpdateStreak(String userId) async {
    if (_user == null) return;
    
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final lastLogin = _user!.lastLoginDate;
      final lastLoginDate = DateTime(lastLogin.year, lastLogin.month, lastLogin.day);
      
      // Check if this is a new day compared to last login
      if (today.isAfter(lastLoginDate)) {
        int newStreak = _user!.streak;
        
        // If the last login was yesterday, increment streak
        final yesterday = today.subtract(const Duration(days: 1));
        if (lastLoginDate.isAtSameMomentAs(yesterday)) {
          newStreak += 1;
        } else if (today.difference(lastLoginDate).inDays > 1) {
          // If more than one day has passed, reset streak
          newStreak = 1;
        }
        
        // Update streak in Firestore
        await _firestore.collection('users').doc(userId).update({
          'streak': newStreak,
          'lastLoginDate': FieldValue.serverTimestamp(),
          'longestStreak': FieldValue.increment(newStreak > _user!.longestStreak ? newStreak - _user!.longestStreak : 0),
        });
        
        // Update locally
        _user = _user!.copyWith(
          streak: newStreak,
          lastLoginDate: now,
          longestStreak: newStreak > _user!.longestStreak ? newStreak : _user!.longestStreak,
        );
        
        // Log login
        await _firestore.collection('user_logins').add({
          'userId': userId,
          'timestamp': FieldValue.serverTimestamp(),
        });
        
        // Add XP for daily login
        await addXp(userId, 25, 'Daily login');
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating streak: $e');
    }
  }
  
  // Add XP to user
  Future<void> addXp(String userId, int amount, String reason) async {
    if (_user == null || amount <= 0) return;
    
    try {
      int oldXp = _user!.xp;
      int newXp = oldXp + amount;
      
      // Update XP in Firestore
      await _firestore.collection('users').doc(userId).update({
        'xp': newXp,
      });
      
      // Log XP history
      await _firestore.collection('xp_history').add({
        'userId': userId,
        'amount': amount,
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      // Update local user
      _user = _user!.copyWith(xp: newXp);
      
      // Check for level up
      await UserLevelService.checkAndProcessLevelUp(userId, oldXp, newXp);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding XP: $e');
    }
  }
  
  // Add Focus Points to user
  Future<void> addFocusPoints(String userId, int amount, String source) async {
    if (_user == null || amount <= 0) return;
    
    try {
      // Update Focus Points in Firestore
      await _firestore.collection('users').doc(userId).update({
        'focusPoints': FieldValue.increment(amount),
      });
      
      // Log Focus Points history
      await _firestore.collection('focus_points_history').add({
        'userId': userId,
        'amount': amount,
        'source': source,
        'isAddition': true,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      // Update local user
      _user = _user!.copyWith(focusPoints: _user!.focusPoints + amount);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding Focus Points: $e');
    }
  }
  
  // Spend Focus Points
  Future<bool> spendFocusPoints(String userId, int amount, String purpose) async {
    if (_user == null || _user!.focusPoints < amount) return false;
    
    try {
      // Update Focus Points in Firestore
      await _firestore.collection('users').doc(userId).update({
        'focusPoints': FieldValue.increment(-amount),
      });
      
      // Log Focus Points history
      await _firestore.collection('focus_points_history').add({
        'userId': userId,
        'amount': amount,
        'source': purpose,
        'isAddition': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      // Update local user
      _user = _user!.copyWith(focusPoints: _user!.focusPoints - amount);
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error spending Focus Points: $e');
      return false;
    }
  }
  
  // Track app session
  Future<void> trackAppSession(String userId, int durationMinutes) async {
    if (_user == null || durationMinutes <= 0) return;
    
    try {
      // Log app session
      await _firestore.collection('app_sessions').add({
        'userId': userId,
        'durationMinutes': durationMinutes,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      // Calculate XP (10 XP per minute)
      int xpEarned = durationMinutes * 10;
      await addXp(userId, xpEarned, 'App usage');
      
      // Check for badges based on total time spent
      await _badgeService.checkForNewBadges(userId, _user!);
      
    } catch (e) {
      debugPrint('Error tracking app session: $e');
    }
  }

  Future<bool> updateUserProfile({
    String? fullName,
    String? email,
    String? profileImageUrl,
    String? sport,
    bool? isIndividual,
    String? university,
    String? universityCode,
    List<String>? focusAreas,
  }) async {
    if (_user == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final updates = <String, dynamic>{};
      if (fullName != null) updates['fullName'] = fullName;
      if (email != null) updates['email'] = email;
      if (profileImageUrl != null) updates['profileImageUrl'] = profileImageUrl;
      if (sport != null) updates['sport'] = sport;
      if (isIndividual != null) updates['isIndividual'] = isIndividual;
      if (university != null) updates['university'] = university;
      if (universityCode != null) updates['universityCode'] = universityCode;
      if (focusAreas != null) updates['focusAreas'] = focusAreas;
      
      // Handle profile image upload if provided
      if (profileImageUrl != null) {
        // Update local user object
        _user = _user!.copyWith(
          fullName: fullName ?? _user!.fullName,
          email: email ?? _user!.email,
          profileImageUrl: profileImageUrl,
          sport: sport ?? _user!.sport,
          isIndividual: isIndividual ?? _user!.isIndividual,
          university: university ?? _user!.university,
          universityCode: universityCode ?? _user!.universityCode,
          focusAreas: focusAreas ?? _user!.focusAreas,
        );
      }
      
      // Update Firestore
      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(_user!.id).update(updates);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to update profile: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
  
  // Track course completion
  Future<void> trackCourseCompletion(String userId, String courseId) async {
    if (_user == null) return;
    
    try {
      // Check if course is already completed
      if (_user!.completedCourses.contains(courseId)) return;
      
      // Add to completed courses
      List<String> updatedCourses = [..._user!.completedCourses, courseId];
      
      // Update user document
      await _firestore.collection('users').doc(userId).update({
        'completedCourses': updatedCourses,
      });
      
      // Log completion
      await _firestore.collection('course_completions').add({
        'userId': userId,
        'courseId': courseId,
        'completedAt': FieldValue.serverTimestamp(),
      });
      
      // Award XP
      await addXp(userId, 100, 'Course completion');
      
      // Award Focus Points
      await addFocusPoints(userId, 25, 'Course completion');
      
      // Update local user
      _user = _user!.copyWith(completedCourses: updatedCourses);
      
      // Check for badges
      await _badgeService.checkForNewBadges(userId, _user!);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error tracking course completion: $e');
    }
  }
  
  // Track audio module completion
  Future<void> trackAudioCompletion(String userId, String audioId) async {
    if (_user == null) return;
    
    try {
      // Check if audio is already completed
      if (_user!.completedAudios.contains(audioId)) return;
      
      // Add to completed audios
      List<String> updatedAudios = [..._user!.completedAudios, audioId];
      
      // Update user document
      await _firestore.collection('users').doc(userId).update({
        'completedAudios': updatedAudios,
      });
      
      // Log completion
      await _firestore.collection('audio_completions').add({
        'userId': userId,
        'audioId': audioId,
        'completedAt': FieldValue.serverTimestamp(),
      });
      
      // Award XP
      await addXp(userId, 50, 'Audio completion');
      
      // Award Focus Points
      await addFocusPoints(userId, 10, 'Audio completion');
      
      // Update local user
      _user = _user!.copyWith(completedAudios: updatedAudios);
      
      // Check for badges
      await _badgeService.checkForNewBadges(userId, _user!);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error tracking audio completion: $e');
    }
  }

  Future<void> updateProfile({
    String? name,
    String? university,
    File? imageFile,
    Uint8List? imageBytes,
  }) async {
    try {
      if (_user == null) {
        throw Exception('No user data available');
      }
      
      final authProvider = Provider.of<AuthProvider>(navigatorKey.currentContext!, listen: false);
      
      // Call the auth service to update the profile
      final error = await authProvider.updateUserProfile(
        uid: _user!.id,
        fullName: name,
        university: university,
        imageFile: imageFile,
        imageBytes: imageBytes,
      );
      
      if (error != null) {
        throw Exception(error);
      }
      
      // Reload user data to get the updated information including new image URL
      await loadUserData(_user!.id);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating profile: $e');
      rethrow;
    }
  }

  // Get all available badges including not yet earned ones
  Future<List<AppBadge>> getAllAvailableBadges() async {
    try {
      // Fetch all badge definitions from Firestore
      final FirebaseFirestore _db = FirebaseFirestore.instance;
      final querySnapshot = await _db.collection('badges').get();
      
      // Convert to AppBadge objects with earnedAt set to null (not yet earned)
      final List<AppBadge> allBadges = [];
      
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        allBadges.add(AppBadge(
          id: doc.id,
          name: data['name'] ?? '',
          description: data['description'] ?? '',
          imageUrl: data['imageUrl'] ?? 'assets/images/badges/default.png',
          earnedAt: null, // Not earned yet (now works since earnedAt is nullable)
          xpValue: data['xpValue'] ?? 0,
        ));
      }
      
      // If user has badges, mark them as earned
      if (_user != null && _user!.badges.isNotEmpty) {
        // For each badge in allBadges, check if the user has already earned it
        for (var i = 0; i < allBadges.length; i++) {
          final existingBadge = _user!.badges.firstWhere(
            (badge) => badge.id == allBadges[i].id,
            orElse: () => AppBadge(
              id: 'not_found',
              name: '',
              description: '',
              imageUrl: '',
              earnedAt: null,
              xpValue: 0,
            ),
          );
          
          if (existingBadge.id != 'not_found') {
            // User has this badge, so replace with the earned version
            allBadges[i] = existingBadge;
          }
        }
      }
      
      return allBadges;
    } catch (e) {
      debugPrint('Error getting available badges: $e');
      return [];
    }
  }
} 