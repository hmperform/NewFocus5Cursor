import 'package:cloud_firestore/cloud_firestore.dart';

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
    DateTime? lastLogin;
    if (data['lastLoginDate'] != null) {
      final timestamp = data['lastLoginDate'] as Timestamp;
      lastLogin = DateTime.fromMillisecondsSinceEpoch(
        timestamp.millisecondsSinceEpoch
      );
    }
    
    DateTime? lastActive;
    if (data['lastActive'] != null) {
      final timestamp = data['lastActive'] as Timestamp;
      lastActive = DateTime.fromMillisecondsSinceEpoch(
        timestamp.millisecondsSinceEpoch
      );
    }
    
    DateTime? created;
    if (data['createdAt'] != null) {
      final timestamp = data['createdAt'] as Timestamp;
      created = DateTime.fromMillisecondsSinceEpoch(
        timestamp.millisecondsSinceEpoch
      );
    }
    
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
      lastCompletionDate: data['lastCompletionDate'] != null 
          ? (data['lastCompletionDate'] as Timestamp).toDate() 
          : DateTime.now(),
      savedCourses: data['savedCourses'] != null 
          ? List<String>.from(data['savedCourses']) 
          : [],
    );
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
    );
  }
}

class AppBadge {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String? badgeImage;
  final DateTime? earnedAt;
  final int xpValue;

  AppBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    this.badgeImage,
    required this.earnedAt,
    required this.xpValue,
  });

  factory AppBadge.fromJson(Map<String, dynamic> json) {
    DateTime? earned;
    if (json['earnedAt'] != null) {
      if (json['earnedAt'] is Timestamp) {
        earned = DateTime.fromMillisecondsSinceEpoch(
          (json['earnedAt'] as Timestamp).millisecondsSinceEpoch
        );
      } else {
        earned = DateTime.parse(json['earnedAt'].toString());
      }
    } else {
      earned = null;
    }
    
    return AppBadge(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String,
      badgeImage: json['badgeImage'] as String?,
      earnedAt: earned,
      xpValue: json['xpValue'] as int,
    );
  }

  factory AppBadge.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    print('AppBadge.fromFirestore called with doc ID: ${doc.id}, data: $data');
    
    return AppBadge(
      id: doc.id,
      name: data['name'] ?? 'Unknown Badge',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'],
      badgeImage: data['badgeImage'],
      earnedAt: data['earnedAt'] != null 
          ? (data['earnedAt'] as Timestamp).toDate() 
          : DateTime.now(),
      xpValue: data['xpValue'] is int ? data['xpValue'] : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'badgeImage': badgeImage,
      'earnedAt': earnedAt?.toIso8601String(),
      'xpValue': xpValue,
    };
  }
} 