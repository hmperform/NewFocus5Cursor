import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'content_models.dart';

class User {
  final String id;
  final String email;
  final String fullName;
  final String? username;
  final String? profileImageUrl;
  final String? sport;
  final String? university;
  final String? universityCode;
  final bool isIndividual;
  final bool isAdmin;
  final bool isPartnerChampion;
  final bool isPartnerCoach;
  final bool isCoach;
  final int xp;
  final int focusPoints;
  final int streak;
  final int longestStreak;
  final List<String> focusAreas;
  final List<AppBadge> badges;
  final List<String> completedCourses;
  final List<String> completedAudios;
  final List<String> completedLessons;
  final List<String> completedArticles;
  final DateTime lastLoginDate;
  final DateTime lastActive;
  final DateTime createdAt;
  final Map<String, dynamic>? preferences;
  final int loginStreak;
  final int totalLoginDays;
  final List<Map<String, dynamic>> badgesgranted;
  final List<Map<String, dynamic>> purchasedCourses;
  final DateTime lastCompletionDate;
  final List<String> savedCourses;
  final int? lifetimeJournalEntries;
  final int? currentJournalEntries;
  final int? highScoreGrid;
  final int? highScoreGridHard;
  final int? highScoreWordSearch;
  final DateTime? lastSelectionDate;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    this.username,
    this.profileImageUrl,
    this.sport,
    this.university,
    this.universityCode,
    this.isIndividual = false,
    this.isAdmin = false,
    this.isPartnerChampion = false,
    this.isPartnerCoach = false,
    this.isCoach = false,
    this.xp = 0,
    this.focusPoints = 0,
    this.streak = 0,
    this.longestStreak = 0,
    this.focusAreas = const [],
    this.badges = const [],
    this.completedCourses = const [],
    this.completedAudios = const [],
    this.completedLessons = const [],
    this.completedArticles = const [],
    DateTime? lastLoginDate,
    DateTime? lastActive,
    DateTime? createdAt,
    this.preferences,
    this.loginStreak = 0,
    this.totalLoginDays = 0,
    this.badgesgranted = const [],
    this.purchasedCourses = const [],
    required this.lastCompletionDate,
    this.savedCourses = const [],
    this.lifetimeJournalEntries,
    this.currentJournalEntries,
    this.highScoreGrid,
    this.highScoreGridHard,
    this.highScoreWordSearch,
    this.lastSelectionDate,
  }) : 
    this.lastLoginDate = lastLoginDate ?? DateTime.now(),
    this.lastActive = lastActive ?? DateTime.now(),
    this.createdAt = createdAt ?? DateTime.now();

  factory User.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    // Parse badgesgranted first (the references)
    List<Map<String, dynamic>> grantedBadgesList = [];
    if (data['badgesgranted'] != null && data['badgesgranted'] is List) {
       grantedBadgesList = List<Map<String, dynamic>>.from(
          (data['badgesgranted'] as List).map((item) {
            // Handle DocumentReference objects from Firestore
            if (item is DocumentReference) {
              // Create reference in our standard format
              return {
                'id': item.id,
                'path': item.path.split('/')[0] // Get the collection name
              };
            }
            // Ensure each item is a map before casting
            else if (item is Map) {
              return Map<String, dynamic>.from(item);
            }
            return {}; // Return empty map or handle error if item is not a map
          }).where((item) => item.isNotEmpty) // Filter out empty maps
       );
    } else if (data['badgesgranted'] != null && data['badgesgranted'] is DocumentReference) {
       // Handle single DocumentReference
       final docRef = data['badgesgranted'] as DocumentReference;
       grantedBadgesList.add({
         'id': docRef.id,
         'path': docRef.path.split('/')[0] // Get the collection name
       });
    } else if (data['badgesgranted'] != null && data['badgesgranted'] is Map) {
      // Handle legacy case if it was ever a single map reference
      final badgeRef = data['badgesgranted'] as Map<String, dynamic>; 
      if (badgeRef.containsKey('id') && badgeRef.containsKey('path')) {
         grantedBadgesList.add(Map<String, dynamic>.from(badgeRef));
      }
    }
    
    // We'll let the badge details be fetched separately by UserProvider
    // rather than hardcoding them here
    List<AppBadge> badgesList = [];
    
    // Parse purchasedCourses references
    List<Map<String, dynamic>> purchasedCoursesList = [];
    if (data['purchasedCourses'] != null && data['purchasedCourses'] is List) {
       purchasedCoursesList = List<Map<String, dynamic>>.from(
          (data['purchasedCourses'] as List).map((item) {
            // Ensure each item is a map before casting
            if (item is Map) {
              return Map<String, dynamic>.from(item);
            }
            return {}; // Return empty map or handle error if item is not a map
          }).where((item) => item.isNotEmpty) // Filter out empty maps
       );
    } else if (data['purchasedCourses'] != null && data['purchasedCourses'] is Map) {
      // Handle legacy case if it was ever a single map reference
      final courseRef = data['purchasedCourses'] as Map<String, dynamic>; 
      if (courseRef.containsKey('id') && courseRef.containsKey('path')) {
         purchasedCoursesList.add(Map<String, dynamic>.from(courseRef));
      }
    }

    // Parse date fields
    DateTime? lastLogin = _parseTimestamp(data['lastLoginDate']);
    DateTime? lastActive = _parseTimestamp(data['lastActive']);
    DateTime? created = _parseTimestamp(data['createdAt']);
    DateTime? lastCompletion = _parseTimestamp(data['lastCompletionDate']);
    DateTime? lastSelection = _parseTimestamp(data['lastSelectionDate']);

    return User(
      id: doc.id,
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      username: data['username'],
      profileImageUrl: data['profileImageUrl'],
      sport: data['sport'],
      university: data['university'],
      universityCode: data['universityCode'],
      isIndividual: data['isIndividual'] ?? false,
      isAdmin: data['isAdmin'] ?? false,
      isPartnerChampion: data['isPartnerChampion'] ?? false,
      isPartnerCoach: data['isPartnerCoach'] ?? false,
      isCoach: data['isCoach'] ?? false,
      xp: data['xp'] ?? 0,
      focusPoints: data['focusPoints'] ?? 0,
      streak: data['streak'] ?? 0,
      longestStreak: data['longestStreak'] ?? 0,
      focusAreas: data['focusAreas'] != null 
          ? List<String>.from(data['focusAreas']) 
          : [],
      badges: badgesList,
      completedCourses: data['completedCourses'] != null 
          ? List<String>.from(data['completedCourses']) 
          : [],
      completedAudios: data['completedAudios'] != null 
          ? List<String>.from(data['completedAudios']) 
          : [],
      completedLessons: data['completedLessons'] != null 
          ? List<String>.from(data['completedLessons']) 
          : [],
      completedArticles: data['completedArticles'] != null 
          ? List<String>.from(data['completedArticles']) 
          : [],
      lastLoginDate: lastLogin,
      lastActive: lastActive,
      createdAt: created,
      preferences: data['preferences'] as Map<String, dynamic>?,
      loginStreak: data['loginStreak'] ?? 0,
      totalLoginDays: data['totalLoginDays'] ?? 0,
      badgesgranted: grantedBadgesList,
      purchasedCourses: purchasedCoursesList,
      lastCompletionDate: lastCompletion ?? DateTime.now(),
      savedCourses: data['savedCourses'] != null 
          ? List<String>.from(data['savedCourses']) 
          : [],
      lifetimeJournalEntries: data['lifetimeJournalEntries'] as int? ?? 0,
      currentJournalEntries: data['currentJournalEntries'] as int? ?? 0,
      highScoreGrid: (data['highScoreGrid'] as num?)?.toInt(),
      highScoreGridHard: (data['highScoreGridHard'] as num?)?.toInt(),
      highScoreWordSearch: (data['highScoreWordSearch'] as num?)?.toInt(),
      lastSelectionDate: lastSelection,
    );
  }

  // Helper function to safely parse Timestamps
  static DateTime? _parseTimestamp(dynamic timestampData) {
    if (timestampData is Timestamp) {
      return timestampData.toDate();
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'fullName': fullName,
      if (username != null) 'username': username,
      if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
      if (sport != null) 'sport': sport,
      if (university != null) 'university': university,
      if (universityCode != null) 'universityCode': universityCode,
      'isIndividual': isIndividual,
      'isAdmin': isAdmin,
      'isPartnerChampion': isPartnerChampion,
      'isPartnerCoach': isPartnerCoach,
      'isCoach': isCoach,
      'xp': xp,
      'focusPoints': focusPoints,
      'streak': streak,
      'longestStreak': longestStreak,
      'focusAreas': focusAreas,
      'badgesgranted': badgesgranted,
      'completedCourses': completedCourses,
      'completedAudios': completedAudios,
      'completedLessons': completedLessons,
      'completedArticles': completedArticles,
      'lastLoginDate': Timestamp.fromDate(lastLoginDate),
      'lastActive': Timestamp.fromDate(lastActive),
      'createdAt': Timestamp.fromDate(createdAt),
      if (preferences != null) 'preferences': preferences,
      'loginStreak': loginStreak,
      'totalLoginDays': totalLoginDays,
      'purchasedCourses': purchasedCourses,
      'lastCompletionDate': Timestamp.fromDate(lastCompletionDate),
      'savedCourses': savedCourses,
      if (lifetimeJournalEntries != null) 'lifetimeJournalEntries': lifetimeJournalEntries,
      if (currentJournalEntries != null) 'currentJournalEntries': currentJournalEntries,
      if (highScoreGrid != null) 'highScoreGrid': highScoreGrid,
      if (highScoreGridHard != null) 'highScoreGridHard': highScoreGridHard,
      if (highScoreWordSearch != null) 'highScoreWordSearch': highScoreWordSearch,
      if (lastSelectionDate != null) 'lastSelectionDate': Timestamp.fromDate(lastSelectionDate!),
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? fullName,
    String? username,
    String? profileImageUrl,
    String? sport,
    String? university,
    String? universityCode,
    bool? isIndividual,
    bool? isAdmin,
    bool? isPartnerChampion,
    bool? isPartnerCoach,
    bool? isCoach,
    int? xp,
    int? focusPoints,
    int? streak,
    int? longestStreak,
    List<String>? focusAreas,
    List<AppBadge>? badges,
    List<String>? completedCourses,
    List<String>? completedAudios,
    List<String>? completedLessons,
    List<String>? completedArticles,
    DateTime? lastLoginDate,
    DateTime? lastActive,
    DateTime? createdAt,
    Map<String, dynamic>? preferences,
    int? loginStreak,
    int? totalLoginDays,
    List<Map<String, dynamic>>? badgesgranted,
    List<Map<String, dynamic>>? purchasedCourses,
    DateTime? lastCompletionDate,
    List<String>? savedCourses,
    int? lifetimeJournalEntries,
    int? currentJournalEntries,
    int? highScoreGrid,
    int? highScoreGridHard,
    int? highScoreWordSearch,
    DateTime? lastSelectionDate,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      sport: sport ?? this.sport,
      university: university ?? this.university,
      universityCode: universityCode ?? this.universityCode,
      isIndividual: isIndividual ?? this.isIndividual,
      isAdmin: isAdmin ?? this.isAdmin,
      isPartnerChampion: isPartnerChampion ?? this.isPartnerChampion,
      isPartnerCoach: isPartnerCoach ?? this.isPartnerCoach,
      isCoach: isCoach ?? this.isCoach,
      xp: xp ?? this.xp,
      focusPoints: focusPoints ?? this.focusPoints,
      streak: streak ?? this.streak,
      longestStreak: longestStreak ?? this.longestStreak,
      focusAreas: focusAreas ?? this.focusAreas,
      badges: badges ?? this.badges,
      completedCourses: completedCourses ?? this.completedCourses,
      completedAudios: completedAudios ?? this.completedAudios,
      completedLessons: completedLessons ?? this.completedLessons,
      completedArticles: completedArticles ?? this.completedArticles,
      lastLoginDate: lastLoginDate ?? this.lastLoginDate,
      lastActive: lastActive ?? this.lastActive,
      createdAt: createdAt ?? this.createdAt,
      preferences: preferences ?? this.preferences,
      loginStreak: loginStreak ?? this.loginStreak,
      totalLoginDays: totalLoginDays ?? this.totalLoginDays,
      badgesgranted: badgesgranted ?? this.badgesgranted,
      purchasedCourses: purchasedCourses ?? this.purchasedCourses,
      lastCompletionDate: lastCompletionDate ?? this.lastCompletionDate,
      savedCourses: savedCourses ?? this.savedCourses,
      lifetimeJournalEntries: lifetimeJournalEntries ?? this.lifetimeJournalEntries,
      currentJournalEntries: currentJournalEntries ?? this.currentJournalEntries,
      highScoreGrid: highScoreGrid ?? this.highScoreGrid,
      highScoreGridHard: highScoreGridHard ?? this.highScoreGridHard,
      highScoreWordSearch: highScoreWordSearch ?? this.highScoreWordSearch,
      lastSelectionDate: lastSelectionDate ?? this.lastSelectionDate,
    );
  }
}

// End of file maybe? 