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
  final List<Lesson> _lessons;
  final List<String> learningPoints;
  final List<String> universityCodes;
  final int focusPointsCost;

  String get creatorName => coachName;
  String get creatorId => coachId;
  String get creatorImageUrl => coachImageUrl;
  
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
    List<Lesson>? lessons,
    this.learningPoints = const [],
    this.universityCodes = const [],
    this.focusPointsCost = 0,
  }) : _lessons = lessons ?? [];

  List<Lesson> get lessons => _lessons;
  List<Lesson> get lessonsList => _lessons;

  Course copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    String? coachId,
    String? coachName,
    String? coachImageUrl,
    List<String>? tags,
    List<String>? focusAreas,
    int? durationMinutes,
    int? xpReward,
    bool? featured,
    bool? premium,
    DateTime? createdAt,
    bool? universityExclusive,
    List<Lesson>? lessonsList,
    List<String>? learningPoints,
    List<String>? universityCodes,
    int? focusPointsCost,
  }) {
    return Course(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      coachId: coachId ?? this.coachId,
      coachName: coachName ?? this.coachName,
      coachImageUrl: coachImageUrl ?? this.coachImageUrl,
      tags: tags ?? this.tags,
      focusAreas: focusAreas ?? this.focusAreas,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      xpReward: xpReward ?? this.xpReward,
      featured: featured ?? this.featured,
      premium: premium ?? this.premium,
      createdAt: createdAt ?? this.createdAt,
      universityExclusive: universityExclusive ?? this.universityExclusive,
      lessons: lessonsList ?? this._lessons,
      learningPoints: learningPoints ?? this.learningPoints,
      universityCodes: universityCodes ?? this.universityCodes,
      focusPointsCost: focusPointsCost ?? this.focusPointsCost,
    );
  }

  factory Course.empty() => Course(
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
    lessons: [],
    learningPoints: [],
    universityCodes: [],
    focusPointsCost: 0,
  );

  // ... rest of the class stays the same ...
}

class Article {
  final String id;
  final String title;
  final String content;
  final String imageUrl;
  final String authorId;
  final String authorName;
  final List<String> focusAreas;
  final List<String> tags;
  final DateTime createdAt;
  final int readTimeMinutes;
  final bool premium;

  Article({
    required this.id,
    required this.title,
    required this.content,
    required this.imageUrl,
    required this.authorId,
    required this.authorName,
    required this.focusAreas,
    required this.tags,
    required this.createdAt,
    required this.readTimeMinutes,
    required this.premium,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      authorId: json['authorId'] ?? '',
      authorName: json['authorName'] ?? '',
      focusAreas: List<String>.from(json['focusAreas'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: json['createdAt'] is DateTime 
          ? json['createdAt'] 
          : DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      readTimeMinutes: json['readTimeMinutes'] ?? 0,
      premium: json['premium'] ?? false,
    );
  }
}

class Lesson {
  final String id;
  final String title;
  final String description;
  final String textContent;
  final String audioUrl;
  final String videoUrl;
  final String thumbnailUrl;
  final DateTime createdAt;
  final String courseId;
  final int order;
  final int durationMinutes;
  final bool isFree;
  final String type;
  final int xp;
  final CreatorId creatorId;
  final String? quizId;
  final bool isCompleted;
  final Map<String, bool> userProgress;

  Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.textContent,
    required this.audioUrl,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.createdAt,
    required this.courseId,
    required this.order,
    required this.durationMinutes,
    required this.isFree,
    required this.type,
    required this.xp,
    required this.creatorId,
    required this.quizId,
    required this.isCompleted,
    required this.userProgress,
  });

  factory Lesson.fromJson(Map<String, dynamic> data, String id) {
    // Ensure required fields are present
    _validateRequiredField(data, 'title', id);
    _validateRequiredField(data, 'courseId', id);
    _validateRequiredField(data, 'order', id);
    _validateRequiredField(data, 'durationMinutes', id);
    _validateRequiredField(data, 'type', id);
    _validateRequiredField(data, 'xp', id);

    // Helper function to parse Timestamps safely
    DateTime? _parseTimestamp(dynamic timestamp) {
      if (timestamp is Timestamp) {
        return timestamp.toDate();
      } else if (timestamp is String) {
        return DateTime.tryParse(timestamp);
      }
      return null;
    }

    // Helper function to parse CreatorId safely
    CreatorId? _parseCreatorId(dynamic creatorData) {
      if (creatorData is Map<String, dynamic>) {
        return CreatorId.fromJson(creatorData);
      }
      return null;
    }

    return Lesson(
      id: id,
      title: data['title'] as String,
      description: data['description'] as String? ?? '',
      textContent: data['textContent'] as String? ?? '',
      audioUrl: data['audioUrl'] as String?,
      videoUrl: data['videoUrl'] as String?,
      thumbnailUrl: data['thumbnailUrl'] as String?,
      createdAt: _parseTimestamp(data['createdAt']),
      courseId: data['courseId'] as String,
      order: (data['order'] as num?)?.toInt() ?? 0,
      durationMinutes: (data['durationMinutes'] as num?)?.toInt() ?? 0,
      isFree: data['isFree'] as bool? ?? false,
      type: data['type'] as String? ?? 'video',
      xp: (data['xp'] as num?)?.toInt() ?? 0,
      creatorId: _parseCreatorId(data['creatorId']),
      quizId: data['quizId'] as String?,
      isCompleted: data['isCompleted'] as bool? ?? false,
      userProgress: (data['userProgress'] as Map<String, dynamic>?)
              ?.map((key, value) => MapEntry(key, value as bool)) ??
          {},
    );
  }

  // ... rest of the class stays the same ...
}

enum MediaType { article, video, audio, podcast, infographic }

class MediaItem {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String creatorId;
  final String creatorName;
  final String creatorImageUrl;
  final List<String> focusAreas;
  final List<String> tags;
  final DateTime createdAt;
  final int durationMinutes;
  final bool premium;
  final MediaType type;
  final String contentUrl;
  final List<String> universityCodes;
  
  MediaItem({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.creatorId,
    required this.creatorName,
    required this.creatorImageUrl,
    required this.focusAreas,
    required this.tags,
    required this.createdAt,
    required this.durationMinutes,
    required this.premium,
    required this.type,
    required this.contentUrl,
    this.universityCodes = const [],
  });

  factory MediaItem.fromJson(Map<String, dynamic> json, String id, MediaType type) {
    return MediaItem(
      id: id,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      creatorId: json['creatorId'] ?? json['authorId'] ?? '',
      creatorName: json['creatorName'] ?? json['authorName'] ?? '',
      creatorImageUrl: json['creatorImageUrl'] ?? json['authorImageUrl'] ?? '',
      focusAreas: List<String>.from(json['focusAreas'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: json['createdAt'] is DateTime 
          ? json['createdAt'] 
          : DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      durationMinutes: json['durationMinutes'] ?? json['readTimeMinutes'] ?? 0,
      premium: json['premium'] ?? false,
      type: type,
      contentUrl: json['contentUrl'] ?? json['videoUrl'] ?? json['audioUrl'] ?? '',
      universityCodes: List<String>.from(json['universityCodes'] ?? []),
    );
  }
}

enum LessonType { video, audio, text, quiz, other } 