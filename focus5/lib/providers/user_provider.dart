import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
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
import '../widgets/streak_celebration_popup.dart'; // <-- Import added
import '../screens/level_up_screen.dart'; // <-- Import LevelUpScreen
import '../widgets/badge_unlock_popup.dart'; // <-- Import for badge pop-up (will be created later)

class UserProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorageService _storageService = FirebaseStorageService();
  final BadgeService _badgeService = BadgeService();
  final AuthProvider? _authProvider = null;
  final MediaCompletionService _mediaCompletionService = MediaCompletionService();
  StreamSubscription<DocumentSnapshot>? _userSubscription; // To manage the listener
  
  User? _user;
  List<AppBadge> _allBadgeDefinitions = []; // <-- Add state for all badge definitions
  bool _isLoading = false; // Change to private
  String? _errorMessage;
  Map<String, int> _lessonProgress = {}; // Key: lessonId, Value: last position in seconds
  bool _initialized = false;
  
  User? get user => _user;
  List<AppBadge> get allBadgeDefinitions => _allBadgeDefinitions; // <-- Getter
  bool get isLoading => _isLoading; // Add getter
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
  
  // Get list of completed course IDs
  List<String> get completedCourses => _user?.completedCourses ?? [];
  
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
      _isLoading = true; // Use private field
      notifyListeners(); // Notify UI that loading has started

      // Load all badge definitions first (or concurrently)
      await loadAllBadgeDefinitions(); 

      // Cancel previous subscription before starting a new one
      await _userSubscription?.cancel();
      _userSubscription = null;

      // Get the user document once to immediately display data
      final docSnapshot = await _firestore.collection('users').doc(userId).get();
      
      if (!docSnapshot.exists) {
        _user = null;
        _isLoading = false; // Use private field
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
        _isLoading = false; // Use private field
        notifyListeners();
      }

      // Add a debounce timer to reduce frequent updates
      Timer? _debounceTimer;
      
      _userSubscription = _firestore.collection('users').doc(userId).snapshots().listen(
        (doc) async {
          // <<< ADDED LOGGING >>>
          print('UserProvider [Listener]: Received snapshot update for user $userId. Doc exists: ${doc.exists}'); 
          if (!doc.exists) {
            _user = null; // User not found
            _isLoading = false; // Use private field
            notifyListeners();
            return;
          }
          
          try {
            // Cancel any pending debounce
            _debounceTimer?.cancel();
            
            // Capture previous state BEFORE parsing new data
            final previousBadgesGranted = _user?.badgesgranted ?? [];
            // print('UserProvider [Listener]: Previous badgesgranted refs: ${previousBadgesGranted.length}'); // Optional debug
            
            // <<< ADDED LOGGING >>>
            final incomingData = doc.data();
            final incomingBadgesGranted = incomingData?['badgesgranted'] as List<dynamic>? ?? [];
            print('UserProvider [Listener]: Incoming badgesgranted refs: ${incomingBadgesGranted.length}');
            
            // Process user data with debounce to avoid excessive updates
            _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
              print('UserProvider [Debounced]: Processing snapshot...'); // <<< ADDED LOGGING >>>
              
              // Parse the new user data first
              User newUser = User.fromFirestore(doc);
              final newBadgesGranted = newUser.badgesgranted; // Already parsed from doc
              print('UserProvider [Debounced]: New user badgesgranted refs: ${newBadgesGranted.length}');
              
              // *** MODIFIED LOGIC: Compare incoming refs with PREVIOUS refs ***
              bool shouldFetchDetails = newBadgesGranted.isNotEmpty && 
                  !_haveSameBadgeRefs(newBadgesGranted, previousBadgesGranted);
                   
              print('UserProvider [Debounced]: Should fetch badge details? $shouldFetchDetails'); // <<< ADDED LOGGING >>>

              // Update the main user object BEFORE potentially fetching details
              // This ensures non-badge data is updated promptly
              _user = newUser; 

              // Only fetch badge details if the references have actually changed
              if (shouldFetchDetails) {
                print('UserProvider [Debounced]: Calling _fetchBadgeDetails...'); // <<< ADDED LOGGING >>>
                _isLoading = true; // Set loading true for badge fetch
                notifyListeners(); // Notify for loading state
                await _fetchBadgeDetails(newBadgesGranted); // Pass the new refs
              } else {
                // If no badge changes, just notify with the updated user object
                print('UserProvider [Debounced]: No badge changes detected, just notifying.'); // <<< ADDED LOGGING >>>
                _isLoading = false; // Use private field
                notifyListeners(); // Notify with updated user data (like XP, streak etc.)
              }
            });
          } catch (e, stackTrace) { // <<< ADDED stackTrace >>>
            print('UserProvider [Listener Error]: $e\n$stackTrace'); // <<< ADDED LOGGING >>>
            _isLoading = false; // Use private field
            _user = null;
            notifyListeners();
          }
        },
        onError: (error, stackTrace) {
          print('UserProvider [Listener Stream Error]: $error\n$stackTrace'); // <<< ADDED LOGGING >>>
          _isLoading = false; // Use private field
          _user = null;
          notifyListeners();
        },
        onDone: () {
          print('UserProvider [Listener Done]'); // <<< ADDED LOGGING >>>
          _isLoading = false; // Use private field
          notifyListeners();
        }
      );
    } catch (e, stackTrace) { // <<< ADDED stackTrace >>>
      print('UserProvider [loadUserData Error]: $e\n$stackTrace'); // <<< ADDED LOGGING >>>
      _isLoading = false; // Use private field
      _user = null;
      notifyListeners();
    }
  }
  
  // Check if two badge reference lists contain the same badge IDs
  bool _haveSameBadgeRefs(List<Map<String, dynamic>> newRefs, List<Map<String, dynamic>> oldRefs) {
    if (newRefs.length != oldRefs.length) return false;
    
    // Convert lists of maps to sets of IDs for comparison
    final newIds = newRefs.map((ref) => ref['id'] as String?).where((id) => id != null).toSet();
    final oldIds = oldRefs.map((ref) => ref['id'] as String?).where((id) => id != null).toSet();
    
    // Check if sets have the same size and contain the same elements
    return newIds.length == oldIds.length && newIds.containsAll(oldIds); 
  }

  // Fetch detailed badge information based on references
  Future<void> _fetchBadgeDetails(List<Map<String, dynamic>> badgeRefs) async {
    if (badgeRefs.isEmpty) {
      print('UserProvider [_fetchBadgeDetails]: No badge references to process');
      if (_user != null) {
        _user = _user!.copyWith(badges: []); // Ensure badges list is empty
      }
      _isLoading = false; // Reset loading state
      notifyListeners(); // Notify UI
      return;
    }
    
    print('UserProvider [_fetchBadgeDetails]: Fetching details for ${badgeRefs.length} badge references');
    List<AppBadge> fetchedBadges = [];
    Set<String> processedIds = {}; // Track processed badge IDs

    // *** REMOVED the check that skipped fetching ***
    // if (_user != null && badgeRefIds.length == currentBadgeIds.length && ... ) { ... return; }

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
              badgeImage: badgeData['badgeImage'], 
              earnedAt: DateTime.now(), // Set earnedAt when fetching details
              xpValue: badgeData['xpValue'] is int ? badgeData['xpValue'] : 0,
              criteriaType: badgeData['criteriaType'] ?? 'Unknown', 
              requiredCount: badgeData['requiredCount'] is int ? badgeData['requiredCount'] : 1, 
              specificIds: badgeData['specificIds'] != null 
                  ? List<String>.from(badgeData['specificIds']) 
                  : null,
              specificCourses: badgeData['specificCourses'] != null
                  ? List<Map<String, dynamic>>.from(badgeData['specificCourses'])
                  : null,
              mustCompleteAllCourses: badgeData['mustCompleteAllCourses'] as bool?,
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
              criteriaType: 'Unknown', // Add required criteriaType
              requiredCount: 1, // Add required requiredCount
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
      // Use copyWith on the *current* _user state
      _user = _user!.copyWith(badges: fetchedBadges); 
    }
    
    // Ensure loading state is false and notify listeners *after* updating _user
    _isLoading = false; 
    notifyListeners(); 
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
      
      print('UserProvider: Checking streak/days. Today: $today, Last Active: $lastActiveDate, Current Total Days: $currentTotalDays');

      // --- Logic for totalLoginDays --- 
      if (currentTotalDays == 0) {
        // If user has 0 total days, set it to 1 on this first check
        print('UserProvider: First login check with 0 days. Setting totalLoginDays to 1.');
        newTotalLoginDays = 1;
        needsUpdate = true;
      } else if (today.isAfter(lastActiveDate)) {
        // It's a new day and user has logged in before
        print('UserProvider: New login day detected! Current Total Days: $currentTotalDays');
        newTotalLoginDays = currentTotalDays + 1;
        needsUpdate = true; // Need to update Firestore
      } else {
        // Same day login, no changes needed for total days
        print('UserProvider: Not a new login day. No totalLoginDays update needed.');
      }
      
      // Only update Firestore and local state if changes were made
      if (needsUpdate) {
        print('UserProvider: Preparing to update Firestore. New Total Days: $newTotalLoginDays');
        
        await _firestore.collection('users').doc(userId).update({
          'lastActive': FieldValue.serverTimestamp(), // Use server time instead of lastLoginDate
          'totalLoginDays': newTotalLoginDays,
        });
        
        print('UserProvider: Firestore update successful. Updating local state.');
        
        // Update local user state
        _user = _user!.copyWith(
          lastActive: now, // Use local 'now' for immediate consistency
          totalLoginDays: newTotalLoginDays,
        );
        
        print('UserProvider: Local user state updated. New totalLoginDays: ${_user?.totalLoginDays}');
        notifyListeners();
        print('UserProvider: Update complete. Notified listeners.');
      }
    } catch (e, stackTrace) {
      print('UserProvider: Error updating login days: $e');
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
    DocumentReference? university,
    String? universityCode,
    bool? isIndividual,
    bool? isPartnerChampion,
    bool? isPartnerCoach,
  }) async {
    try {
      if (_user == null || _user?.id == null) {
        print('UserProvider [updateUserProfile]: No user or user ID available');
        return false;
      }

      print('UserProvider [updateUserProfile]: Updating profile for user ${_user!.id}');
      print('UserProvider [updateUserProfile]: fullName: $fullName');
      print('UserProvider [updateUserProfile]: university reference: ${university?.path}');
      print('UserProvider [updateUserProfile]: universityCode: $universityCode');
      print('UserProvider [updateUserProfile]: isIndividual: $isIndividual');
      print('UserProvider [updateUserProfile]: isPartnerChampion: $isPartnerChampion');
      print('UserProvider [updateUserProfile]: isPartnerCoach: $isPartnerCoach');

      Map<String, dynamic> updates = {};
      
      if (fullName != null && fullName.isNotEmpty) {
        updates['fullName'] = fullName;
      }
      if (university != null) {
        // Store university as a path string
        updates['university'] = university.path;
      }
      if (universityCode != null) {
        updates['universityCode'] = universityCode;
      }
      if (isIndividual != null) {
        updates['isIndividual'] = isIndividual;
      }
      if (isPartnerChampion != null) {
        updates['isPartnerChampion'] = isPartnerChampion;
      }
      if (isPartnerCoach != null) {
        updates['isPartnerCoach'] = isPartnerCoach;
      }

      if (updates.isEmpty) {
        print('UserProvider [updateUserProfile]: No updates to apply');
        return true;
      }

      print('UserProvider [updateUserProfile]: Applying updates: $updates');
      
      await _firestore.collection('users').doc(_user!.id).update(updates);
      
      // Update local user object - make sure this is correct with proper string handling
      _user = _user!.copyWith(
        fullName: fullName ?? _user!.fullName,
        university: university?.path ?? _user!.university,
        universityCode: universityCode ?? _user!.universityCode,
        isIndividual: isIndividual ?? _user!.isIndividual,
        isPartnerChampion: isPartnerChampion ?? _user!.isPartnerChampion,
        isPartnerCoach: isPartnerCoach ?? _user!.isPartnerCoach,
      );
      
      notifyListeners();
      print('UserProvider [updateUserProfile]: Profile updated successfully');
      return true;
    } catch (e, stackTrace) {
      print('UserProvider [updateUserProfile] Error: $e');
      print('UserProvider [updateUserProfile] StackTrace: $stackTrace');
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
  Future<void> trackAudioCompletion(String userId, String audioId, {required BuildContext context}) async {
    if (_user == null) return;

    try {
      // Check and update streak for daily audio completion
      if (audioId.startsWith('audio-') || audioId.startsWith('daily-')) {
        await updateStreak(userId, true);
      }

      // Notify listeners after updating user state but before badge check potentially modifies it again
      notifyListeners();

      // --> Check for badges after completing audio and updating user state <--
      debugPrint('[trackAudioCompletion] Checking badges. Current streak: ${_user?.streak}');
      // We still call checkForNewBadges to trigger the award and popup,
      // but we no longer manually update the local state here.
      await _badgeService.checkForNewBadges(_user!.id, _user!, context: context); 

      // REMOVED MANUAL LOCAL UPDATE BLOCK
      // if (newlyAwardedBadges.isNotEmpty && _user != null) { ... }

    } catch (e) {
      debugPrint('Error tracking audio completion: $e');
    }
  }

  // New method to update streak (for audio, lesson, game completions)
  Future<bool> updateStreak(String userId, bool incrementStreak) async {
    if (_user == null) {
      debugPrint('[UserProvider UpdateStreak] User is null, cannot update streak.');
      return false;
    }
    
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final lastCompletionDate = _user!.lastCompletionDate;
      
      // Handle null lastCompletionDate (first ever completion)
      if (lastCompletionDate == null) {
        debugPrint('[UserProvider UpdateStreak] First completion ever. Setting streak to 1.');
        int newStreak = 1;
        int newLongestStreak = (_user!.longestStreak < 1) ? 1 : _user!.longestStreak;
        
        await _firestore.collection('users').doc(userId).update({
          'streak': newStreak,
          'longestStreak': newLongestStreak,
          'lastCompletionDate': now, // Important: Update last completion date
        });
        _user = _user!.copyWith(
          streak: newStreak,
          longestStreak: newLongestStreak,
          lastCompletionDate: now,
        );
        notifyListeners();
        return true;
      }
      
      // If current streak is 0, set it to 1 regardless of lastActive date
      if (_user!.streak == 0) {
        debugPrint('[UserProvider UpdateStreak] Current streak is 0. Setting to 1.');
        int newStreak = 1;
        int newLongestStreak = (_user!.longestStreak < 1) ? 1 : _user!.longestStreak;
        
        await _firestore.collection('users').doc(userId).update({
          'streak': newStreak,
          'longestStreak': newLongestStreak,
          'lastCompletionDate': now,
        });
        _user = _user!.copyWith(
          streak: newStreak,
          longestStreak: newLongestStreak,
          lastCompletionDate: now,
        );
        notifyListeners();
        return true;
      }
      
      // Proceed if lastCompletionDate is not null and streak is not 0
      final lastCompletionDay = DateTime(
        lastCompletionDate.year, 
        lastCompletionDate.month, 
        lastCompletionDate.day
      );
      
      debugPrint('[UserProvider UpdateStreak] Checking streak. Today: $today, Last Completion Day: $lastCompletionDay');

      int currentStreak = _user!.streak;
      int currentLongestStreak = _user!.longestStreak;
      int newStreak = currentStreak;
      int newLongestStreak = currentLongestStreak;
      bool streakUpdated = false;
      
      // Check if the user has already completed something today
      if (lastCompletionDay.isAtSameMomentAs(today)) {
        debugPrint('[UserProvider UpdateStreak] Already completed today. No streak change.');
        // Update lastCompletionDate to NOW to reflect the most recent activity
        await _firestore.collection('users').doc(userId).update({'lastCompletionDate': now});
        _user = _user!.copyWith(lastCompletionDate: now);
        notifyListeners(); // Notify even if streak doesn't change, as date updated
        return false; // Streak didn't change, but date did
      }
      
      // Check if the last completion was yesterday
      final yesterday = today.subtract(const Duration(days: 1));
      if (lastCompletionDay.isAtSameMomentAs(yesterday)) {
        // Consecutive day - increment streak
        if (incrementStreak) {
          newStreak = currentStreak + 1;
          newLongestStreak = newStreak > currentLongestStreak ? newStreak : currentLongestStreak;
          debugPrint('[UserProvider UpdateStreak] Consecutive day. Incrementing streak to $newStreak.');
          streakUpdated = true;
        } else {
          debugPrint('[UserProvider UpdateStreak] Consecutive day, but incrementStreak is false. No change.');
        }
      } else {
        // Not consecutive (gap of 1+ days OR first completion handled above)
        // Reset streak to 1 because the chain is broken.
        newStreak = 1;
        newLongestStreak = newStreak > currentLongestStreak ? newStreak : currentLongestStreak; // Longest streak might be 1 now
        debugPrint('[UserProvider UpdateStreak] Not a consecutive day. Resetting streak to 1.');
        streakUpdated = true;
      }
      
      if (streakUpdated) {
        debugPrint('[UserProvider UpdateStreak] Updating Firestore. New Streak: $newStreak, New Longest: $newLongestStreak');
        // Update Firestore
        await _firestore.collection('users').doc(userId).update({
          'streak': newStreak,
          'longestStreak': newLongestStreak,
          'lastCompletionDate': now, // Always update last completion date on change
        });
        
        // Update local user
        _user = _user!.copyWith(
          streak: newStreak,
          longestStreak: newLongestStreak,
          lastCompletionDate: now,
        );
        
        notifyListeners();
        debugPrint('[UserProvider UpdateStreak] Update complete.');
        return true;
      }
      
      debugPrint('[UserProvider UpdateStreak] No streak update was necessary.');
      return false;
    } catch (e, stackTrace) {
      debugPrint('[UserProvider UpdateStreak] Error updating streak: $e\n$stackTrace');
      return false;
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
      String? imageUrl;

      // Handle image upload if provided
      if (imageBytes != null || imageFile != null) {
        final storageRef = FirebaseStorage.instance.ref();
        final profileImageRef = storageRef.child('profile_images/${_user!.id}');
        
        if (kIsWeb && imageBytes != null) {
          // Web upload using Uint8List
          final uploadTask = profileImageRef.putData(
            imageBytes,
            SettableMetadata(contentType: 'image/jpeg'), // Adjust content type as needed
          );
          
          final snapshot = await uploadTask;
          imageUrl = await snapshot.ref.getDownloadURL();
        } else if (imageFile != null) {
          // Mobile upload using File
          final uploadTask = profileImageRef.putFile(imageFile);
          final snapshot = await uploadTask;
          imageUrl = await snapshot.ref.getDownloadURL();
        }
      }
      
      // Call the auth service to update the profile
      final error = await authProvider.updateUserProfile(
        uid: _user!.id,
        fullName: name,
        university: university,
        imageUrl: imageUrl, // Pass the uploaded image URL
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
        
        // Handle specificCourses field
        List<Map<String, dynamic>>? specificCourses;
        if (data['specificCourses'] != null) {
          specificCourses = (data['specificCourses'] as List)
              .map((course) => Map<String, dynamic>.from(course))
              .toList();
        }
        
        allBadges.add(AppBadge(
          id: doc.id,
          name: data['name'] ?? '',
          description: data['description'] ?? '',
          imageUrl: data['imageUrl'] ?? 'assets/images/badges/default.png',
          badgeImage: data['badgeImage'], // Add badgeImage if available
          earnedAt: null, // Not earned yet (now works since earnedAt is nullable)
          xpValue: data['xpValue'] ?? 0,
          criteriaType: data['criteriaType'] ?? 'Unknown', // Add criteriaType
          requiredCount: data['requiredCount'] ?? 1, // Add requiredCount
          specificIds: data['specificIds'] != null 
              ? List<String>.from(data['specificIds']) 
              : null,
          specificCourses: specificCourses,
          mustCompleteAllCourses: data['mustCompleteAllCourses'] as bool?,
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
              badgeImage: '', // Add badgeImage
              earnedAt: null,
              xpValue: 0,
              criteriaType: 'Unknown', // Add criteriaType
              requiredCount: 1, // Add requiredCount
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

      // <<< Refresh user data BEFORE checking completion status >>>
      debugPrint('[toggleLessonCompletion] Refreshing user data before processing lesson $lessonId');
      final docSnapshot = await _firestore.collection('users').doc(userId).get();
      if (!docSnapshot.exists) {
        debugPrint('[toggleLessonCompletion] User document no longer exists.');
        clearUserData();
        return false;
      }
      // Update local user state immediately with latest data
      _user = User.fromFirestore(docSnapshot);
      debugPrint('[toggleLessonCompletion] Refreshed user data. Current streak: ${_user?.streak}, Last Completion: ${_user?.lastCompletionDate}');
      // Notify listeners after refreshing data, before proceeding
      notifyListeners();
      // <<< End Refresh >>>

      List<String> updatedLessons = [..._user!.completedLessons];

      // Only allow marking lessons as completed, not uncompleting them
      if (isCompleted && !updatedLessons.contains(lessonId)) {
        // Check if the lesson media has been completed
        final hasCompletedMedia = await _mediaCompletionService.isMediaCompleted(userId, lessonId);

        if (!hasCompletedMedia) {
          debugPrint('[toggleLessonCompletion] Media for lesson $lessonId not completed yet.');
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

        debugPrint('[toggleLessonCompletion] Media completed. Proceeding to mark lesson $lessonId as complete.');
        // Add to completed lessons
        updatedLessons.add(lessonId);

        // Add XP for completing a lesson
        await addXp(userId, 50, 'Lesson completion');

        // Get current date for lastCompletionDate (used if streak updates)
        // final now = DateTime.now(); // Moved to updateStreak

        // Update in Firestore (only completedLessons for now, streak/date handled later)
        await _firestore.collection('users').doc(userId).update({
          'completedLessons': updatedLessons,
          // 'lastCompletionDate': now, // Moved to updateStreak if needed
        });

        // Log the completion
        await _firestore.collection('lesson_completions').add({
          'userId': userId,
          'lessonId': lessonId,
          'action': 'completed',
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Update local user (only completedLessons initially)
        _user = _user!.copyWith(completedLessons: updatedLessons);
        // Notify listeners for lesson completion update before streak/badge checks
        notifyListeners(); 

        // Check if this lesson completion completes an entire course
        await checkAndAwardCourseCompletionXp(lessonId, context: context);

        // Update streak for lesson completion (now uses refreshed data)
        debugPrint('[toggleLessonCompletion] Calling updateStreak for lesson $lessonId');
        final bool streakIncremented = await updateStreak(userId, true);

        // Optional: Add celebration logic here if streakIncremented is true
        if (streakIncremented && context.mounted) {
           final currentStreak = _user?.streak ?? 0;
           debugPrint('[toggleLessonCompletion] Streak incremented to $currentStreak. Showing celebration.');
           Future.delayed(const Duration(milliseconds: 500), () {
             if (context.mounted) {
               context.showStreakCelebration(streakCount: currentStreak);
             }
           });
        }
        
        // --> Check for badges after completing lesson and updating user state <--
        debugPrint('[toggleLessonCompletion] Checking badges. Current streak: ${_user?.streak}');
        // We still call checkForNewBadges to trigger the award and popup,
        // but we no longer manually update the local state here.
        await _badgeService.checkForNewBadges(_user!.id, _user!, context: context); 
        
        // REMOVED MANUAL LOCAL UPDATE BLOCK
        // if (newlyAwardedBadges.isNotEmpty && _user != null) { ... }
        
        return true;
      } else if (updatedLessons.contains(lessonId)) {
        debugPrint('[toggleLessonCompletion] Lesson $lessonId already completed. Ignoring.');
        // Silently ignore attempts to uncheck completed lessons or mark already completed ones
        return true;
      } else {
         debugPrint('[toggleLessonCompletion] Attempting to mark lesson $lessonId as incomplete (isCompleted=false). Ignoring.');
         return true; // Ignore unchecking
      }
    } catch (e, stackTrace) {
      debugPrint('[toggleLessonCompletion] Error: $e\n$stackTrace');
      return false;
    }
  }
  
  // Track game completion
  Future<bool> trackGameCompletion(String userId, String gameId, int score, {required BuildContext context}) async {
    if (_user == null) return false;
    
    try {
      // Get current date for lastCompletionDate
      final now = DateTime.now();
      
      // Update lastCompletionDate in user document
      await _firestore.collection('users').doc(userId).update({
        'lastCompletionDate': now,
      });
      
      // Log game completion
      await _firestore.collection('game_completions').add({
        'userId': userId,
        'gameId': gameId,
        'score': score,
        'completedAt': FieldValue.serverTimestamp(),
      });
      
      // Award XP based on score
      int xpAmount = 25;
      if (score > 50) xpAmount = 50;
      if (score > 80) xpAmount = 75;
      await addXp(userId, xpAmount, 'Game completion');
      
      // Award Focus Points
      await addFocusPoints(userId, 5, 'Game completion');
      
      // Update local user
      _user = _user!.copyWith(
        lastCompletionDate: now,
      );
      
      // Update streak for game completion
      await updateStreak(userId, true);
      
      notifyListeners(); // Notify after local updates

      // --> Check for badges after completing game and updating user state <--
      debugPrint('[trackGameCompletion] Checking badges. Current streak: ${_user?.streak}');
      // await checkAndAwardBadges(context); // Method doesn't exist
      await _badgeService.checkForNewBadges(_user!.id, _user!, context: context); // Direct call
      
      return true;
    } catch (e) {
      debugPrint('Error tracking game completion: $e');
      return false;
    }
  }
  
  // Track journal entry completion
  Future<bool> trackJournalEntryCompletion(String userId, Map<String, dynamic> journalData, {required BuildContext context}) async {
    if (_user == null) return false;
    
    try {
      debugPrint('[trackJournalEntryCompletion] Starting journal entry tracking for user $userId');
      debugPrint('[trackJournalEntryCompletion] Current lifetime entries (before): ${_user?.lifetimeJournalEntries ?? 0}');
      
      // Get current date for lastCompletionDate
      final now = DateTime.now();
      
      // Create a transaction to ensure atomic updates
      await _firestore.runTransaction((transaction) async {
        // Get the latest user data
        final userDoc = await transaction.get(_firestore.collection('users').doc(userId));
        final currentLifetimeEntries = userDoc.data()?['lifetimeJournalEntries'] as int? ?? 0;
        
        debugPrint('[trackJournalEntryCompletion] Latest lifetime entries from Firestore: $currentLifetimeEntries');
        debugPrint('[trackJournalEntryCompletion] Will update to: ${currentLifetimeEntries + 1}');
        
        // Update user document atomically
        transaction.update(_firestore.collection('users').doc(userId), {
          'lastCompletionDate': now,
          'lifetimeJournalEntries': currentLifetimeEntries + 1,
        });
        
        // Add journal entry within the same transaction
        final journalRef = _firestore.collection('journal_entries').doc();
        transaction.set(journalRef, {
          'userId': userId,
          'content': journalData['content'],
          'mood': journalData['mood'],
          'tags': journalData['tags'] ?? [],
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
      
      debugPrint('[trackJournalEntryCompletion] Transaction completed successfully');
      
      // Award XP
      await addXp(userId, 30, 'Journal entry');
      
      // Refetch user to get updated data
      await loadUserData(userId);
      debugPrint('[trackJournalEntryCompletion] User data reloaded. New lifetime entries: ${_user?.lifetimeJournalEntries ?? 0}');
      
      // Check for badge unlocks
      if (_badgeService != null) {
        debugPrint('[trackJournalEntryCompletion] Checking for badges...');
        await _badgeService!.checkForNewBadges(userId, _user!, context: context);
      }

      return true;
      
    } catch (e) {
      debugPrint('[trackJournalEntryCompletion] Error tracking journal entry: $e');
      return false;
    }
  }

  // Check if a course is completed and award XP (only once per course)
  Future<void> checkAndAwardCourseCompletionXp(String lessonId, {required BuildContext context}) async {
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
      
      notifyListeners(); // Notify after local updates
      
      // --> Check for badges after completing course and updating user state <--
      debugPrint('[checkAndAwardCourseCompletionXp] Checking badges. Current streak: ${_user?.streak}');
      // await checkAndAwardBadges(context); // Method doesn't exist
      await _badgeService.checkForNewBadges(_user!.id, _user!, context: context); // Direct call
      
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
    _allBadgeDefinitions = []; // Clear badge definitions
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

  // New method to check streak status on app launch - detects missed days
  Future<void> checkAndUpdateStreakStatus(String userId) async {
    if (_user == null) return;
    
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final lastCompletionDate = _user!.lastCompletionDate;
      final lastCompletionDay = DateTime(
        lastCompletionDate.year, 
        lastCompletionDate.month, 
        lastCompletionDate.day
      );
      
      int currentStreak = _user!.streak;
      int currentLongestStreak = _user!.longestStreak;
      
      // If last completion was more than 1 day ago, the streak is broken
      if (today.difference(lastCompletionDay).inDays > 1) {
        debugPrint('UserProvider: Streak broken due to missed day(s). Last activity: $lastCompletionDay, Today: $today');
        
        // Update Firestore - reset streak to 0 (will be incremented to 1 on next activity)
        await _firestore.collection('users').doc(userId).update({
          'streak': 0,
        });
        
        // Update local user
        _user = _user!.copyWith(streak: 0);
        notifyListeners();
      } else {
        debugPrint('UserProvider: Streak intact. Last completion day: $lastCompletionDay, Today: $today');
      }
    } catch (e) {
      debugPrint('Error checking streak status: $e');
    }
  }

  // Method to set lastCompletionDate to yesterday (for testing)
  Future<void> setLastCompletionToYesterday(String userId) async {
    if (_user == null) return;
    
    try {
      final now = DateTime.now();
      final yesterday = DateTime(now.year, now.month, now.day - 1);
      
      // Update Firestore
      await _firestore.collection('users').doc(userId).update({
        'lastCompletionDate': yesterday,
      });
      
      // Update local user
      _user = _user!.copyWith(lastCompletionDate: yesterday);
      notifyListeners();
      
      debugPrint('UserProvider: Last completion date set to yesterday: $yesterday');
    } catch (e) {
      debugPrint('Error setting last completion date to yesterday: $e');
    }
  }

  // --- Admin Methods ---

  // Admin: Add a specified amount of XP
  Future<bool> adminAddXp(int amount) async {
    if (_user == null || !_user!.isAdmin) return false;
    try {
      print('[ADMIN] Adding $amount XP for user ${_user!.id}');
      await addXp(_user!.id, amount, 'Admin Add XP');
      return true;
    } catch (e) {
      print('[ADMIN] Error adding XP: $e');
      return false;
    }
  }

  // Admin: Set user level by setting XP
  Future<bool> adminSetLevel(int targetLevel) async {
    if (_user == null || !_user!.isAdmin || targetLevel < 1) return false;
    try {
      print('[ADMIN] Setting level to $targetLevel for user ${_user!.id}');
      // Get the minimum XP required for the target level
      int targetXp = UserLevelService.levelThresholds[targetLevel] ?? -1;
      
      if (targetXp == -1) {
         print('[ADMIN] Error: Invalid target level $targetLevel');
         return false;
      }
      
      int currentXp = _user!.xp;
      int oldLevel = UserLevelService.getUserLevel(currentXp); // Capture old level
      
      // Update XP in Firestore
      await _firestore.collection('users').doc(_user!.id).update({'xp': targetXp});
      
      // Log XP history (optional, could be noisy)
      // await _firestore.collection('xp_history').add(...);
      
      // Update local user
      _user = _user!.copyWith(xp: targetXp);
      notifyListeners(); // Notify listeners IMMEDIATELY after local XP update
      
      // Check for level up (important for focus points etc. if levels were skipped)
      await UserLevelService.checkAndProcessLevelUp(_user!.id, currentXp, targetXp);
      
      // Check for new badges after XP update
      await _badgeService.checkForNewBadges(_user!.id, _user!);
      
      print('[ADMIN] User XP set to $targetXp for Level $targetLevel');
      
      // --- Trigger Level Up Screen if level increased ---
      int newLevel = UserLevelService.getUserLevel(targetXp);
      if (newLevel > oldLevel) {
        print('[ADMIN] Level increased from $oldLevel to $newLevel. Triggering LevelUpScreen.');
        // Use navigatorKey from main.dart to navigate
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => LevelUpScreen(newLevel: newLevel),
          ),
        );
      }
      // --- End Level Up Screen Trigger ---
      
      return true;
    } catch (e) {
      print('[ADMIN] Error setting level: $e');
      return false;
    }
  }

  // Admin: Increment streak (simulates a completion yesterday)
  Future<bool> adminIncrementStreak() async {
    if (_user == null || !_user!.isAdmin) return false;
    try {
      print('[ADMIN] Incrementing streak for user ${_user!.id}');
      // Set last completion to yesterday to guarantee streak increase
      await setLastCompletionToYesterday(_user!.id);
      // Call updateStreak with increment=true
      final bool streakUpdated = await updateStreak(_user!.id, true);
      print('[ADMIN] Streak increment attempted. New streak: ${_user?.streak}');
      
      // <<< ADD BADGE CHECK HERE >>>
      if (streakUpdated && navigatorKey.currentContext != null) {
        print('[ADMIN] Checking for badges after streak increment.');
        await _badgeService.checkForNewBadges(_user!.id, _user!, context: navigatorKey.currentContext!);
      } else if (navigatorKey.currentContext == null) {
         print('[ADMIN] Cannot check for badges, navigator context is null.');
      }
      // <<< END BADGE CHECK >>>
      
      return true;
    } catch (e) {
      print('[ADMIN] Error incrementing streak: $e');
      return false;
    }
  }
  
   // Admin: Reset streak to 0
  Future<bool> adminResetStreak() async {
    if (_user == null || !_user!.isAdmin) return false;
    try {
      print('[ADMIN] Resetting streak for user ${_user!.id}');
      await _firestore.collection('users').doc(_user!.id).update({
        'streak': 0,
        'lastCompletionDate': null, // Reset last completion date
      });
      _user = _user!.copyWith(streak: 0, lastCompletionDate: null);
      notifyListeners();
      print('[ADMIN] Streak reset to 0.');
      return true;
    } catch (e) {
      print('[ADMIN] Error resetting streak: $e');
      return false;
    }
  }

  // --- End Admin Methods ---

  // Check and award badges based on current user state
  Future<void> checkAndAwardBadges(BuildContext context) async {
    if (_user == null || _allBadgeDefinitions.isEmpty) {
      print('checkAndAwardBadges: User or badge definitions not loaded.');
      if (_user != null && _allBadgeDefinitions.isEmpty) {
        await loadAllBadgeDefinitions(); // Use the public method here
        if (_allBadgeDefinitions.isEmpty) {
          print('checkAndAwardBadges: Unable to load badge definitions, aborting.');
          return;
        }
      } else {
        return;
      }
    }

    print('checkAndAwardBadges: Checking ${_allBadgeDefinitions.length} badges for user ${_user!.id}');
    final currentUser = _user!;
    final earnedBadgeIds = currentUser.badgesgranted.map((ref) => ref['id'] as String?).toSet();
    List<AppBadge> newlyAwardedBadges = [];
    int totalXpGained = 0;
    bool userUpdated = false;

    for (final badgeDef in _allBadgeDefinitions) {
      if (earnedBadgeIds.contains(badgeDef.id)) {
        continue; // Already earned
      }

      bool criteriaMet = false;
      int currentCount = 0;

      // Check criteria based on criteriaType
      switch (badgeDef.criteriaType) {
        case 'AudioModulesCompleted':
          currentCount = currentUser.completedAudios.length;
          criteriaMet = currentCount >= badgeDef.requiredCount;
          break;
        case 'CoursesCompleted':
          currentCount = currentUser.completedCourses.length;
          // TODO: Add specific course ID check if badgeDef.specificIds is not null
          criteriaMet = currentCount >= badgeDef.requiredCount;
          break;
        case 'CourseLessonsCompleted':
          currentCount = currentUser.completedLessons.length;
          // TODO: Add specific lesson ID check if badgeDef.specificIds is not null
          criteriaMet = currentCount >= badgeDef.requiredCount;
          break;
        case 'JournalEntriesWritten':
          // TODO: Need to fetch/count journal entries if this feature exists
          // currentCount = _journalEntries.length; 
          // criteriaMet = currentCount >= badgeDef.requiredCount;
          print('JournalEntriesWritten criteria not implemented yet.');
          break;
        case 'StreakLength':
          currentCount = currentUser.streak;
          criteriaMet = currentCount >= badgeDef.requiredCount;
          break;
        case 'TotalDaysInApp':
          currentCount = currentUser.totalLoginDays;
          criteriaMet = currentCount >= badgeDef.requiredCount;
          break;
        // Add cases for other criteria types as needed
        default:
          print('Unknown badge criteria type: ${badgeDef.criteriaType}');
      }

      if (criteriaMet) {
        print('Criteria MET for badge: ${badgeDef.name} (${badgeDef.criteriaType} >= ${badgeDef.requiredCount}). Current: $currentCount');
        newlyAwardedBadges.add(badgeDef);
        // Explicitly cast to AppBadge if needed, assuming xpValue is int
        totalXpGained += (badgeDef as AppBadge).xpValue; // Cast added
        userUpdated = true;
      }
    }

    if (userUpdated) {
      print('Awarding ${newlyAwardedBadges.length} new badges. Total XP gain: $totalXpGained');
      // Update user document in Firestore
      final userRef = _firestore.collection('users').doc(currentUser.id);
      final List<Map<String, dynamic>> newBadgeRefs = newlyAwardedBadges
          .map((badge) => {
                'id': (badge as AppBadge).id,
                'path': 'badges' // Assuming collection name is 'badges'
              })
          .toList(); // Remove type argument

      try {
        await userRef.update({
          'badgesgranted': FieldValue.arrayUnion(newBadgeRefs),
          'xp': FieldValue.increment(totalXpGained),
        });
        print('Firestore updated successfully for new badges and XP.');

        // Update local user object immediately for UI responsiveness
        _user = currentUser.copyWith(
          xp: currentUser.xp + totalXpGained,
          badgesgranted: [...currentUser.badgesgranted, ...newBadgeRefs],
          // Also update the detailed badges list locally
          badges: [...currentUser.badges, ...newlyAwardedBadges.map((b) => (b as AppBadge).copyWith(earnedAt: DateTime.now()))]
        );
        notifyListeners(); // Notify UI about XP and potentially badge list changes

        // Show pop-up for each newly awarded badge
        for (final awardedBadge in newlyAwardedBadges) {
           // Use a short delay between popups if multiple badges are awarded at once
           await Future.delayed(const Duration(milliseconds: 500)); 
           // Ensure context is still valid if delays are involved
           if (context.mounted) { 
              showDialog(
                context: context,
                barrierDismissible: false, // Prevent dismissing by tapping outside
                builder: (dialogContext) => BadgeUnlockPopup(
                  badge: awardedBadge,
                ),
              );
           }
        }

        // Check for level up after awarding XP
        _checkAndHandleLevelUp(context, currentUser.xp, _user!.xp);

      } catch (e) {
        print('Error updating user document for badges/XP: $e');
        // Handle error - maybe revert local changes or show an error message
      }
    }
  }

  // --- Private Helper Methods ---

  void _checkAndHandleLevelUp(BuildContext context, int oldXp, int newXp) {
    if (_user == null) return;
    int oldLevel = UserLevelService.getUserLevel(oldXp);
    int newLevel = UserLevelService.getUserLevel(newXp);

    if (newLevel > oldLevel) {
      print('UserProvider: Level Up! $oldLevel -> $newLevel');
      // Ensure navigation happens safely after build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
            // Use navigatorKey from main.dart to navigate
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (context) => LevelUpScreen(newLevel: newLevel),
              ),
            );
        }
      });
    }
  }

  void _showStreakCelebration(BuildContext context, int streakCount) {
    if (streakCount <= 0) return; // Don't show for 0 or negative streaks
    // Ensure context is valid before showing popup
    WidgetsBinding.instance.addPostFrameCallback((_) { 
      if (context.mounted) {
        print('UserProvider: Showing streak celebration for $streakCount days');
        context.showStreakCelebration(streakCount: streakCount);
      }
    });
  }

  // Example integration point:
  /* COMMENT OUT START
  Future<void> recordActivityCompletion({
    required BuildContext context, // Pass context here
    String? courseId,
    String? lessonId,
    String? audioId,
    String? articleId,
    required int xpGained,
  }) async {
     if (_user == null) return;
     final currentXp = _user!.xp;

     // ... (existing logic to update completions, XP, streak)
     Map<String, dynamic> updates = await _mediaCompletionService.recordCompletion(
        userId: _user!.id,
        courseId: courseId,
        lessonId: lessonId,
        audioId: audioId,
        articleId: articleId,
        xpGained: xpGained,
        currentStreak: _user!.streak,
        lastCompletionDate: _user!.lastCompletionDate,
     );
     
     if (updates.isNotEmpty) {
       try {
          final userRef = _firestore.collection('users').doc(_user!.id);
          await userRef.update(updates);
          print('User stats updated successfully after activity completion.');
          
          // Update local user immediately
          // NOTE: This might be superseded by the snapshot listener, but provides
          // quicker UI feedback for the completion itself.
          _user = _user!.copyWith(
              xp: updates.containsKey('xp') ? updates['xp'] : _user!.xp,
              streak: updates.containsKey('streak') ? updates['streak'] : _user!.streak,
              longestStreak: updates.containsKey('longestStreak') 
                  ? updates['longestStreak'] 
                  : _user!.longestStreak,
              lastCompletionDate: updates.containsKey('lastCompletionDate') 
                  ? (updates['lastCompletionDate'] as Timestamp).toDate() 
                  : _user!.lastCompletionDate,
              // Update completion lists based on what was passed
              completedCourses: courseId != null ? [..._user!.completedCourses, courseId] : _user!.completedCourses,
              completedLessons: lessonId != null ? [..._user!.completedLessons, lessonId] : _user!.completedLessons,
              completedAudios: audioId != null ? [..._user!.completedAudios, audioId] : _user!.completedAudios,
              completedArticles: articleId != null ? [..._user!.completedArticles, articleId] : _user!.completedArticles,
          );
          notifyListeners(); 

          // Show streak celebration if streak increased
          if (updates.containsKey('streak') && updates['streak'] > currentXp) {
             _showStreakCelebration(context, updates['streak']);
          }
          
          // Check for level up
          _checkAndHandleLevelUp(context, currentXp, _user!.xp);

          // --> Check for badges AFTER updating user state
          await checkAndAwardBadges(context);
          
       } catch (e) {
          print('Error updating user stats after completion: $e');
          // Handle error appropriately
       }
     }
  }
  COMMENT OUT END */

  // Similar integration needed in updateStreakAndXP, updateLoginStats etc.
  Future<void> updateStreakAndXP(BuildContext context, {required int xpGained}) async {
     if (_user == null) return;
     final currentXp = _user!.xp;
     // ... logic to update streak and XP ...
     try {
        // ... Firestore update ...
        await _firestore.collection('users').doc(_user!.id).update({
           // ... fields to update ...
           'xp': FieldValue.increment(xpGained), 
        });
        // Update local user
        _user = _user!.copyWith(
            xp: _user!.xp + xpGained,
            // ... other fields
        );
        notifyListeners();
        
        // Check level up
        _checkAndHandleLevelUp(context, currentXp, _user!.xp);
        
        // --> Check for badges
        await checkAndAwardBadges(context);
        
     } catch (e) {
        // ... error handling ...
     }
  }
  
  Future<void> updateLoginStats(BuildContext context) async {
     if (_user == null) return;
     // ... logic to calculate login streak, total days ...
     int currentTotalDays = _user!.totalLoginDays;
     bool shouldUpdate = false; // Determine if update is needed
     Map<String, dynamic> updates = {};
     // ... calculate updates map ...
     
     if (shouldUpdate) {
        try {
           await _firestore.collection('users').doc(_user!.id).update(updates);
           // Update local user
           _user = _user!.copyWith(
              // ... updated fields ...
              totalLoginDays: updates['totalLoginDays'], 
              // ...
           );
           notifyListeners();
           
           // --> Check for badges (e.g., TotalDaysInApp)
           await checkAndAwardBadges(context);
           
        } catch (e) {
           // ... error handling ...
        }
     }
  }

  // Upload profile picture
  // ... (existing upload logic)
  
  // Update user profile
  // ... (existing update logic - should it check badges? Probably not needed here)

  // Get all badges with earned status for the current user
  Future<List<Map<String, dynamic>>> getAllBadgesWithEarnedStatus() async {
    if (_allBadgeDefinitions.isEmpty) {
      await loadAllBadgeDefinitions();
    }
    
    if (_user == null) {
      return _allBadgeDefinitions.map((badge) => {
        'badge': badge,
        'isEarned': false,
      }).toList();
    }
    
    // Create a set of earned badge IDs for quick lookup
    final earnedBadgeIds = _user!.badgesgranted
        .map((badgeRef) => badgeRef['id'] as String)
        .toSet();
    
    return _allBadgeDefinitions.map((badge) => {
      'badge': badge,
      'isEarned': earnedBadgeIds.contains(badge.id),
    }).toList();
  }

  // Check for new badges with context for showing popups
  Future<void> checkForNewBadgesWithContext(BuildContext context) async {
    if (_user == null) return;
    
    debugPrint('[UserProvider.checkForNewBadgesWithContext] Checking for new badges...');
    try {
      final earnedBadges = await _badgeService.checkForNewBadges(
        _user!.id,
        _user!,
        context: context, // Pass context for badge popups
      );
      
      if (earnedBadges.isNotEmpty) {
        debugPrint('[UserProvider.checkForNewBadgesWithContext] User earned ${earnedBadges.length} new badges!');
        // Refresh user data to get updated badges list
        await loadUserData(_user!.id);
      }
    } catch (e) {
      debugPrint('[UserProvider.checkForNewBadgesWithContext] Error checking for badges: $e');
    }
  }
  
  // Track content completion (audio, course, etc.) and check for badges
  Future<void> trackCompletion(BuildContext context, String contentType, String contentId) async {
    if (_user == null) return;
    
    try {
      // Update appropriate completion list based on content type
      switch (contentType) {
        case 'audio':
          if (!_user!.completedAudios.contains(contentId)) {
            await _firestore.collection('users').doc(_user!.id).update({
              'completedAudios': FieldValue.arrayUnion([contentId]),
            });
            _user = _user!.copyWith(
              completedAudios: [..._user!.completedAudios, contentId],
            );
          }
          break;
        case 'course':
          if (!_user!.completedCourses.contains(contentId)) {
            await _firestore.collection('users').doc(_user!.id).update({
              'completedCourses': FieldValue.arrayUnion([contentId]),
            });
            _user = _user!.copyWith(
              completedCourses: [..._user!.completedCourses, contentId],
            );
          }
          break;
        case 'lesson':
          if (!_user!.completedLessons.contains(contentId)) {
            await _firestore.collection('users').doc(_user!.id).update({
              'completedLessons': FieldValue.arrayUnion([contentId]),
            });
            _user = _user!.copyWith(
              completedLessons: [..._user!.completedLessons, contentId],
            );
          }
          break;
        // Add more content types as needed
      }
      
      // Update lastCompletionDate for streak tracking
      await updateLastCompletionDate(_user!.id);
      
      // Update streak if needed
      await updateStreak(_user!.id, true);
      
      // Add XP based on content type
      int xpToAdd = 0;
      switch (contentType) {
        case 'audio':
          xpToAdd = 50;
          break;
        case 'course':
          xpToAdd = 200;
          break;
        case 'lesson':
          xpToAdd = 100;
          break;
      }
      
      if (xpToAdd > 0) {
        await addXp(_user!.id, xpToAdd, '$contentType completion');
      }
      
      // Check for new badges with context for showing popups
      await checkForNewBadgesWithContext(context);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error tracking $contentType completion: $e');
    }
  }

  // Update the user's last completion date to track streaks
  Future<void> updateLastCompletionDate(String userId) async {
    if (_user == null) return;
    
    try {
      final now = DateTime.now();
      await _firestore.collection('users').doc(userId).update({
        'lastCompletionDate': Timestamp.fromDate(now),
      });
      
      // Update local user
      _user = _user!.copyWith(
        lastCompletionDate: now,
      );
      
      // No need to notify listeners here as this is usually called as part of a larger update
      // that will notify listeners when done
    } catch (e) {
      print('Error updating last completion date: $e');
    }
  }

  // Add method to load all badge definitions
  Future<void> loadAllBadgeDefinitions() async {
    try {
      debugPrint('UserProvider: Loading all badge definitions');
      final badges = await _badgeService.fetchAllBadgeDefinitions();
      
      if (badges.isNotEmpty) {
        _allBadgeDefinitions = badges;
        debugPrint('UserProvider: Loaded ${badges.length} badge definitions');
        notifyListeners();
      } else {
        debugPrint('UserProvider: No badge definitions found');
      }
    } catch (e) {
      debugPrint('Error loading badge definitions: $e');
      // Keep previous definitions if we had any
      if (_allBadgeDefinitions.isEmpty) {
        // Create a fallback definition using the provided schema
        _allBadgeDefinitions = [
          AppBadge(
            id: 'streak_7',
            name: 'Write On!',
            description: 'Write your first journal entry',
            criteriaType: 'JournalEntriesWritten',
            imageUrl: 'assets/images/badges/streak_7.png',
            badgeImage: 'https://firebasestorage.googleapis.com/v0/b/focus-5-app.firebasestorage.app/o/ixbie_bronzebadgejournal.png?alt=media&token=f2a7f260-e877-44ac-a5ba-578fcf83bf80',
            xpValue: 100,
            requiredCount: 1,
            specificIds: null,
          )
        ];
      }
    }
  }
  
  // Update initUser to load badge definitions
  Future<void> initUser(String userId) async {
    try {
      _isLoading = true; // Use private field
      notifyListeners();
      
      await loadUserData(userId);
      
      // Load badge definitions when user is initialized
      await loadAllBadgeDefinitions();
      
      _isLoading = false; // Use private field
      _initialized = true;
      notifyListeners();
    } catch (e) {
      _isLoading = false; // Use private field
      notifyListeners();
      debugPrint('Error initializing user: $e');
    }
  }

  // Add these methods after the existing methods in the class
  
  Future<void> updateUserPrivileges({
    bool? isPartnerChampion,
    bool? isPartnerCoach,
  }) async {
    if (_user == null || _user?.id == null) return;

    final updates = <String, dynamic>{};
    
    if (isPartnerChampion != null) {
      updates['isPartnerChampion'] = isPartnerChampion;
    }
    
    if (isPartnerCoach != null) {
      updates['isPartnerCoach'] = isPartnerCoach;
    }
    
    if (updates.isNotEmpty) {
      await _firestore.collection('users').doc(_user!.id).update(updates);
      // The listener will automatically update the local user object
    }
  }

  Future<void> setUniversityReference({
    required String id,
    required String path,
  }) async {
    if (_user == null || _user?.id == null) return;

    await _firestore.collection('users').doc(_user!.id).update({
      'university': {
        'id': id,
        'path': path,
      },
    });
    // The listener will automatically update the local user object
  }
} 