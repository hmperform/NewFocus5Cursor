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
  final DateTime createdAt;
  final Map<String, dynamic>? preferences;

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
    DateTime? createdAt,
    this.preferences,
  }) : 
    this.lastLoginDate = lastLoginDate ?? DateTime.now(),
    this.createdAt = createdAt ?? DateTime.now();

  factory User.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    // Get list of badges
    List<AppBadge> badgesList = [];
    if (data['badges'] != null) {
      // Handle the case where badges is a reference object instead of an array
      if (data['badges'] is Map<String, dynamic>) {
        // If badges is a reference object with id and path
        final badgeRef = data['badges'] as Map<String, dynamic>;
        if (badgeRef.containsKey('id') && badgeRef.containsKey('path')) {
          // Create a single badge from the reference
          badgesList.add(AppBadge(
            id: badgeRef['id'],
            name: 'Badge',
            description: 'A badge',
            imageUrl: '',
            earnedAt: DateTime.now(),
            xpValue: 0,
          ));
        }
      } else if (data['badges'] is List) {
        // Normal case - badges is a list
        badgesList = List<AppBadge>.from(
          (data['badges'] as List).map((badge) => AppBadge.fromJson(badge))
        );
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
      createdAt: created,
      preferences: data['preferences'] as Map<String, dynamic>?,
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
      'badges': badges.map((badge) => badge.toJson()).toList(),
      'completedCourses': completedCourses,
      'completedAudios': completedAudios,
      'completedLessons': completedLessons,
      'completedArticles': completedArticles,
      'lastLoginDate': Timestamp.fromDate(lastLoginDate),
      'createdAt': Timestamp.fromDate(createdAt),
      if (preferences != null) 'preferences': preferences,
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
    DateTime? createdAt,
    Map<String, dynamic>? preferences,
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
      createdAt: createdAt ?? this.createdAt,
      preferences: preferences ?? this.preferences,
    );
  }
}

class AppBadge {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final DateTime? earnedAt;
  final int xpValue;

  AppBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
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
      earnedAt: earned,
      xpValue: json['xpValue'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'earnedAt': earnedAt?.toIso8601String(),
      'xpValue': xpValue,
    };
  }
} 