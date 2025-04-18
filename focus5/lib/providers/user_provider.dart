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
import '../services/media_completion_service.dart';
import 'dart:async'; // Import async

class UserProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorageService _storageService = FirebaseStorageService();
  final BadgeService _badgeService = BadgeService();
  final AuthProvider? _authProvider = null;
  final MediaCompletionService _mediaCompletionService = MediaCompletionService();
  StreamSubscription<DocumentSnapshot>? _userSubscription; // To manage the listener
  
  User? _user;
  // List<JournalEntry> _journalEntries = []; // Commented out - Collection doesn't exist
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, int> _lessonProgress = {}; // Key: lessonId, Value: last position in seconds

  User? get user => _user;
  // List<JournalEntry> get journalEntries => _journalEntries; // Commented out
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get xp => _user?.xp ?? 0;
  int get focusPoints => _user?.focusPoints ?? 0;
  int get streak => _user?.streak ?? 0;
  List<AppBadge> get badges => _user?.badges ?? [];
  List<String> get focusAreas => _user?.focusAreas ?? [];
  
  // Get list of completed lesson IDs
  List<String> get completedLessonIds => _user?.completedLessons ?? [];
  
  // Get list of completed article IDs
  List<String> get completedArticleIds => _user?.completedArticles ?? [];
  
  // Level-related getters
  int get level => UserLevelService.getUserLevel(_user?.xp ?? 0);
  int get xpForNextLevel => UserLevelService.getXpForNextLevel(_user?.xp ?? 0);
  double get levelProgress => UserLevelService.getLevelProgress(_user?.xp ?? 0);
  Map<String, int> get lessonProgress => _lessonProgress;

  // Refresh current user data from Firestore
  Future<void> refreshUser() async {
    if (_user != null) {
      print('UserProvider [refreshUser]: Refreshing data for user ID: ${_user!.id}');
      await loadUserData(_user!.id);
    } else {
      print('UserProvider [refreshUser]: Cannot refresh, no current user');
    }
  }

  void setUser(User user) {
    _user = user;
    notifyListeners();
  }

  // Load user data from Firestore based on userId
  Future<void> loadUserData(String? userId) async {
    if (_isLoading) return; // Prevent concurrent loads

    try {
      if (userId == null || userId.isEmpty) {
        // Don't log here - reduce noise
        clearUserData(); // Clear data and notify
        return;
      }

      // Minimize logging
      _isLoading = true;
      notifyListeners(); // Notify UI that loading has started

      // Cancel previous subscription before starting a new one
      await _userSubscription?.cancel();
      _userSubscription = null;

      // Get the user document once to immediately display data
      final docSnapshot = await _firestore.collection('users').doc(userId).get();
      
      if (!docSnapshot.exists) {
        _user = null;
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      // Parse the user data
      _user = User.fromFirestore(docSnapshot);
      
      // If we have badge references, always attempt to load them
      // This ensures badges are loaded correctly from Firebase
      if (_user!.badgesgranted.isNotEmpty) {
        print('UserProvider [loadUserData]: User has ${_user!.badgesgranted.length} badge references. Loading badge details from Firebase.');
        // Set a short timeout to notify UI of the user data first
        Timer(const Duration(milliseconds: 100), () {
          notifyListeners();
        });
        
        // Then fetch badge details
        await _fetchBadgeDetails(_user!.badgesgranted);
      } else {
        _isLoading = false;
        notifyListeners();
      }

      // Add a debounce timer to reduce frequent updates
      Timer? _debounceTimer;
      
      _userSubscription = _firestore.collection('users').doc(userId).snapshots().listen(
        (doc) async {
          if (!doc.exists) {
            _user = null; // User not found
            _isLoading = false;
            notifyListeners();
            return;
          }
          
          try {
            // Cancel any pending debounce
            _debounceTimer?.cancel();
            
            // Process user data with debounce to avoid excessive updates
            _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
              // Parse the user data first
              User newUser = User.fromFirestore(doc);
              
              // Only fetch badge details if we have new references or no badges currently
              if (newUser.badgesgranted.isNotEmpty && 
                  (_user?.badges.isEmpty ?? true || 
                   !_haveSameBadgeRefs(newUser.badgesgranted, _user?.badgesgranted ?? []))) {
                await _fetchBadgeDetails(newUser.badgesgranted);
              } else {
                // If no badge changes, just update the user object
                _user = newUser;
                if (newUser.badges.isEmpty && (_user?.badges.isNotEmpty ?? false)) {
                  // Keep existing badges if new user doesn't have them
                  _user = _user!.copyWith(badges: _user!.badges);
                }
                _isLoading = false;
                notifyListeners();
              }
            });
          } catch (e) {
            _isLoading = false;
            _user = null;
            notifyListeners();
          }
        },
        onError: (error, stackTrace) {
          _isLoading = false;
          _user = null;
          notifyListeners();
        },
        onDone: () {
          _isLoading = false;
          notifyListeners();
        }
      );
    } catch (e) {
      _isLoading = false;
      _user = null;
      notifyListeners();
    }
  }
  
  // Check if two badge reference lists contain the same badge IDs
  bool _haveSameBadgeRefs(List<Map<String, dynamic>> newRefs, List<Map<String, dynamic>> oldRefs) {
    if (newRefs.length != oldRefs.length) return false;
    
    final newIds = newRefs.map((ref) => ref['id'] as String?).where((id) => id != null).toSet();
    final oldIds = oldRefs.map((ref) => ref['id'] as String?).where((id) => id != null).toSet();
    
    return newIds.length == oldIds.length && newIds.every((id) => oldIds.contains(id));
  }

  // Fetch detailed badge information based on references
  Future<void> _fetchBadgeDetails(List<Map<String, dynamic>> badgeRefs) async {
    if (badgeRefs.isEmpty) {
      print('UserProvider [_fetchBadgeDetails]: No badge references to process');
      if (_user != null) {
        _user = _user!.copyWith(badges: []);
      }
      _isLoading = false;
      notifyListeners();
      return;
    }
    
    print('UserProvider [_fetchBadgeDetails]: Processing ${badgeRefs.length} badge references');
    List<AppBadge> fetchedBadges = [];
    Set<String> processedIds = {}; // Track processed badge IDs

    // If we've already processed these same badge references recently, skip processing
    final badgeRefIds = badgeRefs.map((ref) => ref['id'] as String?).where((id) => id != null).toSet();
    final currentBadgeIds = _user?.badges.map((badge) => badge.id).toSet() ?? {};
    
    // Only refetch if the badge IDs have changed
    if (_user != null && badgeRefIds.length == currentBadgeIds.length && 
        badgeRefIds.every((id) => currentBadgeIds.contains(id))) {
      print('UserProvider [_fetchBadgeDetails]: Badge IDs unchanged, skipping fetch');
      _isLoading = false;  // Reset loading state
      notifyListeners();   // Notify UI to update
      return;
    }

    for (var badgeRef in badgeRefs) {
      final badgeId = badgeRef['id'] as String?;

      if (badgeId != null && badgeId.isNotEmpty && !processedIds.contains(badgeId)) {
        processedIds.add(badgeId); // Mark as processing
        print('UserProvider [_fetchBadgeDetails]: Processing badge ID: $badgeId');
        
        try {
          final badgeDoc = await _firestore.collection('badges').doc(badgeId).get();
          
          if (badgeDoc.exists) {
            final badgeData = badgeDoc.data() as Map<String, dynamic>;
            
            // Create badge with data from Firestore
            final AppBadge badge = AppBadge(
              id: badgeId,
              name: badgeData['name'] ?? 'Unknown Badge',
              description: badgeData['description'] ?? '',
              imageUrl: badgeData['imageUrl'],
              badgeImage: badgeData['badgeImage'], // Ensure badgeImage is captured
              earnedAt: DateTime.now(), // Default if not available
              xpValue: badgeData['xpValue'] is int ? badgeData['xpValue'] : 0,
            );
            
            print('UserProvider [_fetchBadgeDetails]: Successfully loaded badge from Firestore: ${badge.name}');
            fetchedBadges.add(badge);
          } else {
            print('UserProvider [_fetchBadgeDetails]: Badge document does not exist in Firestore for ID: $badgeId');
            
            // Create a placeholder badge when document doesn't exist in Firestore
            final AppBadge badge = AppBadge(
              id: badgeId,
              name: 'Badge',
              description: 'A badge you earned',
              imageUrl: '',
              badgeImage: '',
              earnedAt: DateTime.now(),
              xpValue: 0,
            );
            fetchedBadges.add(badge);
          }
        } catch (e) {
          print('UserProvider [_fetchBadgeDetails]: Error loading badge $badgeId: $e');
        }
      }
    }

    print('UserProvider [_fetchBadgeDetails]: Loaded ${fetchedBadges.length} badges');
    
    // Update the user object's badges list safely
    if (_user != null) {
      _user = _user!.copyWith(badges: fetchedBadges);
      
      // Only notify listeners once at the end of the entire badge fetch process
      _isLoading = false;
      notifyListeners();
    }
  }

  /* // Commented out - Collection doesn't exist
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
  */

  Future<void> _loadLessonProgress(String userId) async {
    // ... existing lesson progress loading ...
  }

  Future<void> updateLessonProgress(String userId, String lessonId, int position) async {
    // ... existing lesson progress update ...
  }

  // Check and update login streak/days
  Future<void> _checkAndUpdateStreak(String userId) async {
    if (_user == null || _user!.id != userId) {
      print('UserProvider: Cannot update streak, user data mismatch or not loaded.');
      return;
    }
    
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final lastActive = _user!.lastActive;
      final lastActiveDate = DateTime(lastActive.year, lastActive.month, lastActive.day);
      int currentTotalDays = _user!.totalLoginDays;
      int currentStreak = _user!.streak;
      int currentLongestStreak = _user!.longestStreak;
      bool needsUpdate = false;
      int newTotalLoginDays = currentTotalDays;
      int newStreak = currentStreak;
      int newLongestStreak = currentLongestStreak;
      
      print('UserProvider: Checking streak/days. Today: $today, Last Active: $lastActiveDate, Current Total Days: $currentTotalDays');

      // --- Logic Adjustment for totalLoginDays --- 
      if (currentTotalDays == 0) {
        // If user has 0 total days, set it to 1 on this first check
        print('UserProvider: First login check with 0 days. Setting totalLoginDays to 1.');
        newTotalLoginDays = 1;
        newStreak = 1; // Also reset streak to 1
        newLongestStreak = (newStreak > currentLongestStreak) ? newStreak : currentLongestStreak;
        needsUpdate = true;
      } else if (today.isAfter(lastActiveDate)) {
        // It's a new day and user has logged in before
        print('UserProvider: New login day detected! Current Total Days: $currentTotalDays');
        newTotalLoginDays = currentTotalDays + 1;
        needsUpdate = true; // Need to update Firestore
        
        // Handle streak logic only on new days
        final yesterday = today.subtract(const Duration(days: 1));
        if (lastActiveDate.isAtSameMomentAs(yesterday)) {
          newStreak = currentStreak + 1;
           print('UserProvider: Streak continued. New streak: $newStreak');
        } else {
          // More than one day passed, or first login after signup (if signup doesn't set streak)
          newStreak = 1; // Reset streak
          print('UserProvider: Streak broken or first real login day. Resetting streak to 1.');
        }
        newLongestStreak = (newStreak > currentLongestStreak) ? newStreak : currentLongestStreak;
      } else {
        // Same day login, no changes needed for streak or total days
        print('UserProvider: Not a new login day. No streak/total days update needed.');
      }
      // --- End Logic Adjustment ---
      
      // Only update Firestore and local state if changes were made
      if (needsUpdate) {
        print('UserProvider: Preparing to update Firestore. New Total Days: $newTotalLoginDays, New Streak: $newStreak, New Longest: $newLongestStreak');
        
        await _firestore.collection('users').doc(userId).update({
          'streak': newStreak,
          'lastActive': FieldValue.serverTimestamp(), // Use server time instead of lastLoginDate
          'longestStreak': newLongestStreak,
          'totalLoginDays': newTotalLoginDays,
        });
        
        print('UserProvider: Firestore update successful. Updating local state.');
        
        // Update local user state
        _user = _user!.copyWith(
          streak: newStreak,
          lastActive: now, // Use local 'now' for immediate consistency
          longestStreak: newLongestStreak,
          totalLoginDays: newTotalLoginDays,
        );
        
        print('UserProvider: Local user state updated. New totalLoginDays: ${_user?.totalLoginDays}');
        notifyListeners();
        print('UserProvider: Update complete. Notified listeners.');
      }
    } catch (e, stackTrace) {
      print('UserProvider: Error updating streak/login days: $e');
      print('UserProvider: Stack trace: $stackTrace');
    }
  }

  // Wrapper function called by AuthProvider
  Future<void> updateUserLoginInfo() async {
    if (_user == null) {
       print('UserProvider: updateUserLoginInfo called, but user is null.');
       return;
    }
     print('UserProvider: updateUserLoginInfo called for user ${_user!.id}');
    await _checkAndUpdateStreak(_user!.id);
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
      notifyListeners(); // Notify listeners IMMEDIATELY after local XP update
      
      // Check for level up
      await UserLevelService.checkAndProcessLevelUp(userId, oldXp, newXp);
      
      // Check for new badges after XP update (using the correct method)
      await _badgeService.checkForNewBadges(userId, _user!);
      
    } catch (e) {
      _errorMessage = 'Failed to add XP: $e';
      notifyListeners();
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
  Future<bool> spendFocusPoints(String userId, int amount, String purpose, {String? courseId}) async {
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
      
      // If this is a course redemption, add the course to purchased courses
      if (purpose.startsWith('Course redemption:') || courseId != null) {
        // Extract courseId from purpose if not directly provided
        String courseToPurchase = courseId ?? '';
        
        if (courseToPurchase.isEmpty && purpose.startsWith('Course redemption:')) {
          // Try to extract courseId from purpose format "Course redemption: {courseTitle}"
          // In the future, consider passing courseId directly instead
          debugPrint('Extracting courseId from purpose: $purpose');
        }
        
        // If we have a direct courseId, use that
        if (courseId != null && courseId.isNotEmpty) {
          await addPurchasedCourse(courseId);
          debugPrint('Added course $courseId to purchased courses');
        }
      }
      
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

  // Toggle lesson completion status
  Future<bool> toggleLessonCompletion(String lessonId, bool isCompleted, {required BuildContext context}) async {
    if (_user == null) return false;
    
    try {
      final userId = _user!.id;
      List<String> updatedLessons = [..._user!.completedLessons];
      
      // Only allow marking lessons as completed, not uncompleting them
      if (isCompleted && !updatedLessons.contains(lessonId)) {
        // Check if the lesson media has been completed
        final hasCompletedMedia = await _mediaCompletionService.isMediaCompleted(userId, lessonId);
        
        if (!hasCompletedMedia) {
          // Show message that user needs to watch/listen to the content first
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('You need to watch/listen to the entire content before marking it as completed.'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
                action: SnackBarAction(
                  label: 'OK',
                  textColor: Colors.white,
                  onPressed: () {},
                ),
              ),
            );
          }
          return false;
        }
        
        // Add to completed lessons
        updatedLessons.add(lessonId);
        
        // Add XP for completing a lesson
        await addXp(userId, 50, 'Lesson completion');

        // Update in Firestore
        await _firestore.collection('users').doc(userId).update({
          'completedLessons': updatedLessons,
        });
        
        // Log the completion
        await _firestore.collection('lesson_completions').add({
          'userId': userId,
          'lessonId': lessonId,
          'action': 'completed',
          'timestamp': FieldValue.serverTimestamp(),
        });
        
        // Update local user
        _user = _user!.copyWith(completedLessons: updatedLessons);
        notifyListeners();
        
        // Check if this lesson completion completes an entire course
        await checkAndAwardCourseCompletionXp(lessonId);
        
        return true;
      } else {
        // Silently ignore attempts to uncheck completed lessons
        return true;
      }
    } catch (e) {
      debugPrint('Error toggling lesson completion: $e');
      return false;
    }
  }
  
  // Check if a course is completed and award XP (only once per course)
  Future<void> checkAndAwardCourseCompletionXp(String lessonId) async {
    if (_user == null) return;
    
    try {
      // Step 1: Find which course this lesson belongs to by querying Firestore
      final courseQuery = await _firestore
          .collection('courses')
          .where('lessonsList', arrayContains: {'id': lessonId})
          .limit(1)
          .get();
      
      if (courseQuery.docs.isEmpty) {
        debugPrint('No course found containing lesson $lessonId');
        return;
      }
      
      final courseDoc = courseQuery.docs.first;
      final courseId = courseDoc.id;
      final courseData = courseDoc.data();
      
      // Skip if this course is already marked as completed
      if (_user!.completedCourses.contains(courseId)) {
        debugPrint('Course $courseId already completed, skipping XP award');
        return;
      }
      
      // Step 2: Get all lessons in this course
      List<String> courseLessonIds = [];
      if (courseData['lessonsList'] != null && courseData['lessonsList'] is List) {
        courseLessonIds = (courseData['lessonsList'] as List)
            .where((lessonData) => lessonData is Map && lessonData['id'] != null)
            .map((lessonData) => lessonData['id'].toString())
            .toList();
      } else if (courseData['lessons'] != null && courseData['lessons'] is List) {
        courseLessonIds = (courseData['lessons'] as List)
            .where((lessonData) => lessonData is Map && lessonData['id'] != null)
            .map((lessonData) => lessonData['id'].toString())
            .toList();
      }
      
      if (courseLessonIds.isEmpty) {
        debugPrint('No lessons found in course $courseId');
        return;
      }
      
      // Step 3: Check if all course lessons are completed
      bool allLessonsCompleted = courseLessonIds.every(
        (lessonId) => _user!.completedLessons.contains(lessonId)
      );
      
      if (!allLessonsCompleted) {
        debugPrint('Not all lessons completed for course $courseId yet');
        return;
      }
      
      // Step 4: All lessons are completed! Award XP and mark course as completed
      final xpReward = (courseData['xpReward'] as num?)?.toInt() ?? 100;
      final userId = _user!.id;
      
      // Update user document
      final updatedCompletedCourses = [..._user!.completedCourses, courseId];
      await _firestore.collection('users').doc(userId).update({
        'completedCourses': updatedCompletedCourses,
      });
      
      // Log the completion
      await _firestore.collection('course_completions').add({
        'userId': userId,
        'courseId': courseId,
        'completedAt': FieldValue.serverTimestamp(),
      });
      
      // Add XP for completing the course
      await addXp(userId, xpReward, 'Course completion');
      
      // Award Focus Points
      await addFocusPoints(userId, 25, 'Course completion');
      
      // Update local user
      _user = _user!.copyWith(
        completedCourses: updatedCompletedCourses,
      );
      
      // Show alert/notification
      debugPrint('🎉 Course $courseId completed! Awarded $xpReward XP');
      
      // Check for badges
      await _badgeService.checkForNewBadges(userId, _user!);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error checking course completion: $e');
    }
  }

  // Track article completion
  Future<bool> toggleArticleCompletion(String articleId, bool isCompleted, {required BuildContext context}) async {
    if (_user == null) return false;
    
    try {
      final userId = _user!.id;
      List<String> updatedArticles = [..._user!.completedArticles];
      
      if (isCompleted && !updatedArticles.contains(articleId)) {
        // Add to completed articles
        updatedArticles.add(articleId);
        
        // Add XP for completing an article
        await addXp(userId, 30, 'Article completion');

        // Update in Firestore
        await _firestore.collection('users').doc(userId).update({
          'completedArticles': updatedArticles,
        });
        
        // Log the completion/removal
        await _firestore.collection('article_completions').add({
          'userId': userId,
          'articleId': articleId,
          'action': 'completed',
          'timestamp': FieldValue.serverTimestamp(),
        });
        
        // Update local user
        _user = _user!.copyWith(completedArticles: updatedArticles);
        notifyListeners();
        
        return true;
        
      } else if (!isCompleted && updatedArticles.contains(articleId)) {
        // Remove from completed articles
        updatedArticles.remove(articleId);
        
        // Update in Firestore
        await _firestore.collection('users').doc(userId).update({
          'completedArticles': updatedArticles,
        });
        
        // Log the completion/removal
        await _firestore.collection('article_completions').add({
          'userId': userId,
          'articleId': articleId,
          'action': 'uncompleted',
          'timestamp': FieldValue.serverTimestamp(),
        });
        
        // Update local user
        _user = _user!.copyWith(completedArticles: updatedArticles);
        notifyListeners();
        
        return true;
      } else {
        // No change needed
        return true;
      }
    } catch (e) {
      debugPrint('Error toggling article completion: $e');
      return false;
    }
  }

  // Award a badge to the current user (admin only)
  Future<bool> awardBadgeToCurrentUser(String badgeId) async {
    if (_user == null || !_user!.isAdmin) {
      return false;
    }
    
    try {
      final badgeService = BadgeService();
      final success = await badgeService.manuallyAwardBadge(_user!.id, badgeId);
      
      if (success) {
        // Reload user data to get the updated badges
        await loadUserData(_user!.id);
      }
      
      return success;
    } catch (e) {
      debugPrint('Error awarding badge to current user: $e');
      return false;
    }
  }

  // Method to clear user data
  void clearUserData() {
    print('UserProvider: Clearing user data and cancelling subscription.');
    _userSubscription?.cancel();
    _userSubscription = null;
    _user = null;
    _isLoading = false;
    _lessonProgress = {};
    _errorMessage = null;
    notifyListeners();
  }

  // Ensure subscription is cancelled when provider is disposed
  @override
  void dispose() {
    print('UserProvider: Disposing.');
    clearUserData(); // Ensure subscription is cancelled on dispose
    super.dispose();
  }

  // Helper to update user data fields (example)
  Future<void> updateUserField(String field, dynamic value) async {
    if (_user == null) return;
    await _firestore.collection('users').doc(_user!.id).update({field: value});
  }
  
  // Method to add a course to the user's purchased courses
  Future<bool> addPurchasedCourse(String courseId) async {
    if (_user == null) return false;
    
    try {
      debugPrint('UserProvider [addPurchasedCourse]: Checking if course $courseId is already purchased');
      // Check if already purchased to avoid duplicates
      if (isCoursePurchased(courseId)) {
        debugPrint('UserProvider [addPurchasedCourse]: Course $courseId is already purchased, skipping');
        return true; // Already purchased
      }
      
      // Create the course reference object
      final courseRef = {
        'id': courseId,
        'path': 'courses'
      };
      debugPrint('UserProvider [addPurchasedCourse]: Adding course ref: $courseRef');
      
      // Create updated list
      List<Map<String, dynamic>> updatedPurchasedCourses = [..._user!.purchasedCourses, courseRef];
      
      // Update in Firestore
      await _firestore.collection('users').doc(_user!.id).update({
        'purchasedCourses': updatedPurchasedCourses,
      });
      debugPrint('UserProvider [addPurchasedCourse]: Successfully updated Firestore');
      
      // Update local user state
      _user = _user!.copyWith(purchasedCourses: updatedPurchasedCourses);
      notifyListeners();
      debugPrint('UserProvider [addPurchasedCourse]: Updated local state and notified listeners');
      
      return true;
    } catch (e) {
      debugPrint('UserProvider [addPurchasedCourse]: Error adding purchased course: $e');
      return false;
    }
  }
  
  // Method to check if a course is already purchased
  bool isCoursePurchased(String courseId) {
    if (_user == null) {
      return false;
    }
    
    // Check if any reference in purchasedCourses has the matching courseId
    final isPurchased = _user!.purchasedCourses.any((courseRef) => 
      courseRef['id'] == courseId
    );
    
    return isPurchased;
  }
  
  // Method to check if a course is purchased (alias for isCoursePurchased)
  bool hasPurchasedCourse(String courseId) {
    return isCoursePurchased(courseId);
  }
  
  // Method to force purchase the Confidence 101 course (for testing)
  Future<bool> forceAddConfidence101Course() async {
    if (_user == null) return false;
    
    try {
      const courseId = "course-001"; // Confidence 101 course ID
      debugPrint('UserProvider [forceAddConfidence101Course]: Adding course-001 to purchased courses');
      
      // Create the course reference object
      final courseRef = {
        'id': courseId,
        'path': 'courses'
      };
      
      // Check if already purchased first
      if (isCoursePurchased(courseId)) {
        debugPrint('UserProvider [forceAddConfidence101Course]: Course already in purchased courses! Removing it first.');
        
        // Remove the course first (for testing)
        List<Map<String, dynamic>> filteredCourses = _user!.purchasedCourses
            .where((course) => course['id'] != courseId)
            .toList();
            
        // Update in Firestore
        await _firestore.collection('users').doc(_user!.id).update({
          'purchasedCourses': filteredCourses,
        });
        
        debugPrint('UserProvider [forceAddConfidence101Course]: Removed course from Firestore');
        
        // Update local state
        _user = _user!.copyWith(purchasedCourses: filteredCourses);
        notifyListeners();
        
        // Wait a moment
        await Future.delayed(Duration(milliseconds: 500));
      }
      
      // Now add it
      List<Map<String, dynamic>> updatedPurchasedCourses = [..._user!.purchasedCourses, courseRef];
      
      // Update in Firestore
      await _firestore.collection('users').doc(_user!.id).update({
        'purchasedCourses': updatedPurchasedCourses,
      });
      debugPrint('UserProvider [forceAddConfidence101Course]: Successfully updated Firestore');
      
      // Update local user state
      _user = _user!.copyWith(purchasedCourses: updatedPurchasedCourses);
      notifyListeners();
      debugPrint('UserProvider [forceAddConfidence101Course]: Updated local state and notified listeners');
      
      return true;
    } catch (e) {
      debugPrint('UserProvider [forceAddConfidence101Course]: Error: $e');
      return false;
    }
  }
} 