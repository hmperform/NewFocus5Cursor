import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/content_models.dart';

class UserProvider extends ChangeNotifier {
  User? _user;
  List<JournalEntry> _journalEntries = [];
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  List<JournalEntry> get journalEntries => _journalEntries;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get xp => _user?.xp ?? 0;
  int get streak => _user?.streak ?? 0;
  List<AppBadge> get badges => _user?.badges ?? [];
  List<String> get focusAreas => _user?.focusAreas ?? [];

  void setUser(User user) {
    _user = user;
    notifyListeners();
  }

  Future<void> loadUserData(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // In a real app, this would be a call to the backend
      // For now, we use the user that's already set by the auth provider
      if (_user != null) {
        await _loadJournalEntries(_user!.id);
        _checkAndUpdateStreak();
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load user data';
      notifyListeners();
    }
  }

  Future<void> _loadJournalEntries(String userId) async {
    // In a real app, fetch from backend
    // For now, filter dummy entries
    _journalEntries = [];
    notifyListeners();
  }

  Future<void> _checkAndUpdateStreak() async {
    if (_user == null) return;

    final prefs = await SharedPreferences.getInstance();
    final lastActiveStr = prefs.getString('last_active_date');
    final currentDate = DateTime.now().toIso8601String().split('T')[0]; // Just get the date part

    if (lastActiveStr != null) {
      final lastActiveDate = DateTime.parse(lastActiveStr);
      final today = DateTime.now();
      final difference = today.difference(lastActiveDate).inDays;

      if (difference == 1) {
        // User was active yesterday, increment streak
        _user = _user!.copyWith(
          streak: _user!.streak + 1,
          lastActive: today,
        );
      } else if (difference > 1) {
        // User missed a day, reset streak
        _user = _user!.copyWith(
          streak: 1, // Reset to 1 for today
          lastActive: today,
        );
      }
    }

    // Save today's date
    await prefs.setString('last_active_date', currentDate);
    notifyListeners();
  }

  Future<void> updateUserProfile({
    String? fullName,
    String? username,
    String? sport,
    List<String>? focusAreas,
    String? profileImageUrl,
  }) async {
    if (_user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // In a real app, send update to backend
      // For now, just update the local user object
      _user = _user!.copyWith(
        fullName: fullName ?? _user!.fullName,
        username: username ?? _user!.username,
        sport: sport ?? _user!.sport,
        focusAreas: focusAreas ?? _user!.focusAreas,
        profileImageUrl: profileImageUrl ?? _user!.profileImageUrl,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to update profile';
      notifyListeners();
    }
  }

  Future<bool> addJournalEntry(String title, String content, List<String>? tags) async {
    if (_user == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      // Create a new journal entry
      final newEntry = JournalEntry(
        id: 'journal_${DateTime.now().millisecondsSinceEpoch}',
        userId: _user!.id,
        title: title,
        content: content,
        tags: tags,
        createdAt: DateTime.now(),
      );

      // In a real app, send to backend
      // For now, just add to the local list
      _journalEntries.insert(0, newEntry);
      
      // Add some XP for creating a journal entry
      await addXp(10, 'Created a journal entry');

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to add journal entry';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteJournalEntry(String entryId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // In a real app, send delete request to backend
      // For now, just remove from the local list
      _journalEntries.removeWhere((entry) => entry.id == entryId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to delete journal entry';
      notifyListeners();
      return false;
    }
  }

  Future<void> addXp(int amount, String reason) async {
    if (_user == null) return;

    try {
      // In a real app, send to backend
      // For now, just update the local user object
      _user = _user!.copyWith(
        xp: _user!.xp + amount,
      );

      // Check if the user has earned any badges
      _checkForNewBadges();

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to add XP';
      notifyListeners();
    }
  }

  void _checkForNewBadges() {
    if (_user == null) return;

    // In a real app, this logic would be more complex and likely on the backend
    // For this demo, we'll just add a badge if they reach certain XP thresholds
    
    // Example: Award "XP Milestone" badge at 1000 XP
    if (_user!.xp >= 1000 && !_hasBadge('badge_xp_1000')) {
      final newBadge = AppBadge(
        id: 'badge_xp_1000',
        name: 'XP Milestone: 1000',
        description: 'You\'ve earned 1000 XP!',
        imageUrl: 'assets/images/badges/xp_1000.png',
        earnedAt: DateTime.now(),
        xpValue: 50, // Earning the badge itself gives 50 XP
      );
      
      // Add the badge and its XP value
      final updatedBadges = [..._user!.badges, newBadge];
      _user = _user!.copyWith(
        badges: updatedBadges,
        xp: _user!.xp + newBadge.xpValue,
      );
    }
    
    // Example: Award streak badge at 7 days
    if (_user!.streak >= 7 && !_hasBadge('badge_streak_7')) {
      final newBadge = AppBadge(
        id: 'badge_streak_7',
        name: '7-Day Streak',
        description: 'You\'ve used Focus 5 for 7 days in a row!',
        imageUrl: 'assets/images/badges/streak_7.png',
        earnedAt: DateTime.now(),
        xpValue: 100,
      );
      
      final updatedBadges = [..._user!.badges, newBadge];
      _user = _user!.copyWith(
        badges: updatedBadges,
        xp: _user!.xp + newBadge.xpValue,
      );
    }
  }

  bool _hasBadge(String badgeId) {
    if (_user == null) return false;
    return _user!.badges.any((badge) => badge.id == badgeId);
  }

  Future<void> addCompletedCourse(String courseId, int xpReward) async {
    if (_user == null) return;

    try {
      // Avoid duplicate entries
      if (!_user!.completedCourses.contains(courseId)) {
        final updatedCourses = [..._user!.completedCourses, courseId];
        _user = _user!.copyWith(
          completedCourses: updatedCourses,
        );
        
        // Add XP for completing the course
        await addXp(xpReward, 'Completed a course');
      }

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to update completed courses';
      notifyListeners();
    }
  }

  Future<void> addCompletedAudio(String audioId, int xpReward) async {
    if (_user == null) return;

    try {
      // Avoid duplicate entries
      if (!_user!.completedAudios.contains(audioId)) {
        final updatedAudios = [..._user!.completedAudios, audioId];
        _user = _user!.copyWith(
          completedAudios: updatedAudios,
        );
        
        // Add XP for completing the audio
        await addXp(xpReward, 'Completed an audio session');
      }

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to update completed audio sessions';
      notifyListeners();
    }
  }

  Future<void> toggleSavedCourse(String courseId) async {
    if (_user == null) return;

    try {
      List<String> updatedSavedCourses;
      
      if (_user!.savedCourses.contains(courseId)) {
        // Remove if already saved
        updatedSavedCourses = _user!.savedCourses.where((id) => id != courseId).toList();
      } else {
        // Add if not saved
        updatedSavedCourses = [..._user!.savedCourses, courseId];
      }
      
      _user = _user!.copyWith(
        savedCourses: updatedSavedCourses,
      );

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to update saved courses';
      notifyListeners();
    }
  }

  // Check if a course is saved
  bool isSavedCourse(String courseId) {
    if (_user == null) return false;
    return _user!.savedCourses.contains(courseId);
  }

  // Check if user has completed a course
  bool hasCompletedCourse(String courseId) {
    if (_user == null) return false;
    return _user!.completedCourses.contains(courseId);
  }

  // Check if user has completed an audio
  bool hasCompletedAudio(String audioId) {
    if (_user == null) return false;
    return _user!.completedAudios.contains(audioId);
  }
} 