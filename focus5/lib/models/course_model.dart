import 'package:cloud_firestore/cloud_firestore.dart';

class Course {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String coachId;
  final String coachName;
  final String coachImageUrl;
  final List<String> tags;
  final List<String> focusAreas;
  final int durationMinutes;
  final int xpReward;
  final bool featured;
  final bool premium;
  final DateTime createdAt;
  final bool universityExclusive;
  final List<String>? universityAccess;
  final List<dynamic>? lessons;
  final List<String> learningPoints;

  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.coachId,
    required this.coachName,
    required this.coachImageUrl,
    required this.tags,
    required this.focusAreas,
    required this.durationMinutes,
    required this.xpReward,
    required this.featured,
    required this.premium,
    required this.createdAt,
    required this.universityExclusive,
    this.universityAccess,
    this.lessons,
    this.learningPoints = const [],
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? json['thumbnailUrl'] ?? '',
      coachId: json['coachId'] ?? json['creatorId'] ?? '',
      coachName: json['coachName'] ?? json['creatorName'] ?? '',
      coachImageUrl: json['coachImageUrl'] ?? json['creatorImageUrl'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      focusAreas: List<String>.from(json['focusAreas'] ?? []),
      durationMinutes: json['durationMinutes'] ?? 0,
      xpReward: json['xpReward'] ?? 0,
      featured: json['featured'] ?? false,
      premium: json['premium'] ?? false,
      createdAt: json['createdAt']?.toDate() ?? DateTime.now(),
      universityExclusive: json['universityExclusive'] ?? false,
      universityAccess: json['universityAccess'] != null 
          ? List<String>.from(json['universityAccess'])
          : null,
      lessons: json['lessons'],
      learningPoints: List<String>.from(json['learningPoints'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'coachId': coachId,
      'coachName': coachName,
      'coachImageUrl': coachImageUrl,
      'tags': tags,
      'focusAreas': focusAreas,
      'durationMinutes': durationMinutes,
      'xpReward': xpReward,
      'featured': featured,
      'premium': premium,
      'createdAt': createdAt,
      'universityExclusive': universityExclusive,
      'universityAccess': universityAccess,
      'lessons': lessons,
      'learningPoints': learningPoints,
    };
  }

  static Course empty() {
    return Course(
      id: '',
      title: '',
      description: '',
      imageUrl: '',
      coachId: '',
      coachName: '',
      coachImageUrl: '',
      tags: [],
      focusAreas: [],
      durationMinutes: 0,
      xpReward: 0,
      featured: false,
      premium: false,
      createdAt: DateTime.now(),
      universityExclusive: false,
      learningPoints: [],
    );
  }

  factory Course.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Handle creatorId which might be a map or just an ID string
    String creatorId;
    if (data['creatorId'] is Map) {
      creatorId = (data['creatorId'] as Map<String, dynamic>)['id'] ?? 'unknown_creator';
    } else if (data['creatorId'] is String) {
      creatorId = data['creatorId'];
    } else {
      creatorId = 'unknown_creator'; // Default or error handling
    }

    return Course(
      id: doc.id,
      title: data['title'] ?? 'No Title',
      description: data['description'] ?? 'No Description',
      imageUrl: data['imageUrl'] ?? '',
      coachId: creatorId,
      coachName: data['creatorName'] ?? 'Unknown Creator',
      coachImageUrl: data['creatorImageUrl'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      focusAreas: List<String>.from(data['focusAreas'] ?? []),
      durationMinutes: data['durationMinutes'] ?? 0,
      xpReward: data['xpReward'] ?? 0,
      featured: data['featured'] ?? false,
      premium: data['premium'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      universityExclusive: data['universityExclusive'] ?? false,
      universityAccess: data['universityAccess'],
      learningPoints: List<String>.from(data['learningPoints'] ?? []),
    );
  }
} 