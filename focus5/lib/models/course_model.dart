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
    );
  }
} 