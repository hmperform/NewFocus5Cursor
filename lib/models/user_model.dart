import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_badges/app_badges.dart';

class User {
  final String id;
  final String email;
  final String fullName;
  final String username;
  final String profileImageUrl;
  final String sport;
  final String university;
  final String universityCode;
  final bool isIndividual;
  final bool isAdmin;
  final double xp;
  final double focusPoints;
  final double streak;
  final double longestStreak;
  final List<String> focusAreas;
  final List<AppBadge> badges;
  final List<String> completedCourses;
  final List<String> completedAudios;
  final DateTime? lastLoginDate;
  final DateTime? createdAt;
  final Map<String, dynamic>? preferences;

  const User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.username,
    required this.profileImageUrl,
    required this.sport,
    required this.university,
    required this.universityCode,
    required this.isIndividual,
    required this.isAdmin,
    required this.xp,
    required this.focusPoints,
    required this.streak,
    required this.longestStreak,
    required this.focusAreas,
    required this.badges,
    required this.completedCourses,
    required this.completedAudios,
    required this.lastLoginDate,
    required this.createdAt,
    required this.preferences,
  });

  factory User.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    // Sanitize the data to handle document references
    final sanitizedData = _sanitizeDocumentData(data);
    
    // Get list of badges
    List<AppBadge> badgesList = [];
    if (sanitizedData['badges'] != null) {
      badgesList = List<AppBadge>.from(
        (sanitizedData['badges'] as List).map((badge) {
          if (badge is Map) {
            return AppBadge.fromJson(badge as Map<String, dynamic>);
          } else {
            // If the badge is just an ID string
            return AppBadge(
              id: badge.toString(),
              name: 'Badge',
              description: 'A badge',
              imageUrl: '',
              earnedAt: null,
              xpValue: 0,
            );
          }
        })
      );
    }
    
    // Parse date fields
    DateTime? lastLogin;
    if (sanitizedData['lastLoginDate'] != null) {
      if (sanitizedData['lastLoginDate'] is Timestamp) {
        final timestamp = sanitizedData['lastLoginDate'] as Timestamp;
        lastLogin = DateTime.fromMillisecondsSinceEpoch(
          timestamp.millisecondsSinceEpoch
        );
      } else if (sanitizedData['lastLoginDate'] is String) {
        try {
          lastLogin = DateTime.parse(sanitizedData['lastLoginDate']);
        } catch (e) {
          // Fallback to now if unable to parse
          lastLogin = DateTime.now();
        }
      }
    }
    
    DateTime? created;
    if (sanitizedData['createdAt'] != null) {
      if (sanitizedData['createdAt'] is Timestamp) {
        final timestamp = sanitizedData['createdAt'] as Timestamp;
        created = DateTime.fromMillisecondsSinceEpoch(
          timestamp.millisecondsSinceEpoch
        );
      } else if (sanitizedData['createdAt'] is String) {
        try {
          created = DateTime.parse(sanitizedData['createdAt']);
        } catch (e) {
          // Fallback to now if unable to parse
          created = DateTime.now();
        }
      }
    }
    
    return User(
      id: doc.id,
      email: sanitizedData['email'] ?? '',
      fullName: sanitizedData['fullName'] ?? '',
      username: sanitizedData['username'],
      profileImageUrl: sanitizedData['profileImageUrl'],
      sport: sanitizedData['sport'],
      university: sanitizedData['university'],
      universityCode: sanitizedData['universityCode'],
      isIndividual: sanitizedData['isIndividual'] ?? false,
      isAdmin: sanitizedData['isAdmin'] ?? false,
      xp: sanitizedData['xp'] ?? 0,
      focusPoints: sanitizedData['focusPoints'] ?? 0,
      streak: sanitizedData['streak'] ?? 0,
      longestStreak: sanitizedData['longestStreak'] ?? 0,
      focusAreas: sanitizedData['focusAreas'] != null 
          ? List<String>.from(sanitizedData['focusAreas']) 
          : [],
      badges: badgesList,
      completedCourses: sanitizedData['completedCourses'] != null 
          ? List<String>.from(sanitizedData['completedCourses']) 
          : [],
      completedAudios: sanitizedData['completedAudios'] != null 
          ? List<String>.from(sanitizedData['completedAudios']) 
          : [],
      lastLoginDate: lastLogin,
      createdAt: created,
      preferences: sanitizedData['preferences'] as Map<String, dynamic>?,
    );
  }
  
  // Helper method to sanitize Firestore document data
  static Map<String, dynamic> _sanitizeDocumentData(Map<String, dynamic> data) {
    Map<String, dynamic> sanitizedData = {};
    
    data.forEach((key, value) {
      if (value is DocumentReference) {
        // Convert document references to string paths
        sanitizedData[key] = value.path;
      } else if (value is List) {
        // Handle lists containing document references
        sanitizedData[key] = _sanitizeList(value);
      } else if (value is Map) {
        // Handle nested maps
        sanitizedData[key] = _sanitizeDocumentData(Map<String, dynamic>.from(value));
      } else {
        // Keep other values as is
        sanitizedData[key] = value;
      }
    });
    
    return sanitizedData;
  }
  
  // Helper method to sanitize lists in Firestore data
  static List _sanitizeList(List list) {
    return list.map((item) {
      if (item is DocumentReference) {
        return item.path;
      } else if (item is Map) {
        return _sanitizeDocumentData(Map<String, dynamic>.from(item));
      } else if (item is List) {
        return _sanitizeList(item);
      } else {
        return item;
      }
    }).toList();
  }
} 