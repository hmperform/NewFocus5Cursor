class User {
  final String id;
  final String email;
  final String username;
  final String fullName;
  final String? profileImageUrl;
  final String? sport;
  final String? university;
  final String? universityCode;
  final bool isIndividual;
  final List<String> focusAreas;
  final int xp;
  final List<AppBadge> badges;
  final List<String> completedCourses;
  final List<String> completedAudios;
  final List<String> savedCourses;
  final int streak;
  final DateTime lastActive;

  User({
    required this.id,
    required this.email,
    required this.username,
    required this.fullName,
    this.profileImageUrl,
    this.sport,
    this.university,
    this.universityCode,
    required this.isIndividual,
    required this.focusAreas,
    required this.xp,
    required this.badges,
    required this.completedCourses,
    required this.completedAudios,
    required this.savedCourses,
    required this.streak,
    required this.lastActive,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      username: json['username'] as String,
      fullName: json['fullName'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
      sport: json['sport'] as String?,
      university: json['university'] as String?,
      universityCode: json['universityCode'] as String?,
      isIndividual: json['isIndividual'] as bool,
      focusAreas: (json['focusAreas'] as List<dynamic>).map((e) => e as String).toList(),
      xp: json['xp'] as int,
      badges: (json['badges'] as List<dynamic>)
          .map((e) => AppBadge.fromJson(e as Map<String, dynamic>))
          .toList(),
      completedCourses: (json['completedCourses'] as List<dynamic>).map((e) => e as String).toList(),
      completedAudios: (json['completedAudios'] as List<dynamic>).map((e) => e as String).toList(),
      savedCourses: (json['savedCourses'] as List<dynamic>).map((e) => e as String).toList(),
      streak: json['streak'] as int,
      lastActive: DateTime.parse(json['lastActive'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'fullName': fullName,
      'profileImageUrl': profileImageUrl,
      'sport': sport,
      'university': university,
      'universityCode': universityCode,
      'isIndividual': isIndividual,
      'focusAreas': focusAreas,
      'xp': xp,
      'badges': badges.map((badge) => badge.toJson()).toList(),
      'completedCourses': completedCourses,
      'completedAudios': completedAudios,
      'savedCourses': savedCourses,
      'streak': streak,
      'lastActive': lastActive.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? username,
    String? fullName,
    String? profileImageUrl,
    String? sport,
    String? university,
    String? universityCode,
    bool? isIndividual,
    List<String>? focusAreas,
    int? xp,
    List<AppBadge>? badges,
    List<String>? completedCourses,
    List<String>? completedAudios,
    List<String>? savedCourses,
    int? streak,
    DateTime? lastActive,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      sport: sport ?? this.sport,
      university: university ?? this.university,
      universityCode: universityCode ?? this.universityCode,
      isIndividual: isIndividual ?? this.isIndividual,
      focusAreas: focusAreas ?? this.focusAreas,
      xp: xp ?? this.xp,
      badges: badges ?? this.badges,
      completedCourses: completedCourses ?? this.completedCourses,
      completedAudios: completedAudios ?? this.completedAudios,
      savedCourses: savedCourses ?? this.savedCourses,
      streak: streak ?? this.streak,
      lastActive: lastActive ?? this.lastActive,
    );
  }
}

class AppBadge {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final DateTime earnedAt;
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
    return AppBadge(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String,
      earnedAt: DateTime.parse(json['earnedAt'] as String),
      xpValue: json['xpValue'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'earnedAt': earnedAt.toIso8601String(),
      'xpValue': xpValue,
    };
  }
} 