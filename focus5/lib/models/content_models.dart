// Module types enum
enum ModuleType {
  video,
  audio,
  text,
  quiz
}

class Lesson {
  final String id;
  final String title;
  final String description;
  final String? videoUrl;
  final String? audioUrl;
  final String? imageUrl;
  final int duration;
  final bool completed;
  final int sortOrder;

  Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.duration,
    required this.sortOrder,
    this.videoUrl,
    this.audioUrl,
    this.imageUrl,
    this.completed = false,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      videoUrl: json['videoUrl'],
      audioUrl: json['audioUrl'],
      imageUrl: json['imageUrl'],
      duration: json['duration'] ?? 0,
      completed: json['completed'] ?? false,
      sortOrder: json['sortOrder'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'videoUrl': videoUrl,
      'audioUrl': audioUrl,
      'imageUrl': imageUrl,
      'duration': duration,
      'completed': completed,
      'sortOrder': sortOrder,
    };
  }
}

class Course {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String thumbnailUrl;  // Added for backwards compatibility
  final String creatorId;     // Added for backwards compatibility
  final String creatorName;
  final String creatorImageUrl; // Added for backwards compatibility
  final List<String> tags;    // Added for backwards compatibility
  final int duration;
  final int durationMinutes;  // Added for backwards compatibility
  final int xpReward;         // Added for backwards compatibility
  final List<String> focusAreas;
  final List<Lesson> lessons;
  final List<Module> modules; // Added for backwards compatibility
  final bool premium;
  final bool featured;
  final DateTime createdAt;
  final bool universityExclusive; // Added for backwards compatibility
  final List<String>? universityAccess; // Added for backwards compatibility

  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.creatorName,
    required this.duration,
    required this.focusAreas,
    required this.lessons,
    this.premium = false,
    this.featured = false,
    required this.createdAt,
    // Backwards compatibility fields
    String? thumbnailUrl,
    String? creatorId,
    String? creatorImageUrl,
    List<String>? tags,
    int? durationMinutes,
    int? xpReward,
    List<Module>? modules,
    bool? universityExclusive,
    this.universityAccess,
  }) : 
    thumbnailUrl = thumbnailUrl ?? imageUrl,
    creatorId = creatorId ?? 'default',
    creatorImageUrl = creatorImageUrl ?? 'https://via.placeholder.com/150',
    tags = tags ?? focusAreas,
    durationMinutes = durationMinutes ?? duration,
    xpReward = xpReward ?? 100,
    modules = modules ?? [],
    universityExclusive = universityExclusive ?? false;

  // Factory method to create a Course from a Map
  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      thumbnailUrl: json['thumbnailUrl'],
      creatorId: json['creatorId'],
      creatorName: json['creatorName'] ?? 'Focus 5 Team',
      creatorImageUrl: json['creatorImageUrl'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      duration: json['duration'] ?? 0,
      durationMinutes: json['durationMinutes'],
      xpReward: json['xpReward'],
      focusAreas: List<String>.from(json['focusAreas'] ?? []),
      lessons: (json['lessons'] as List?)
              ?.map((lesson) => Lesson.fromJson(lesson))
              .toList() ??
          [],
      modules: (json['modules'] as List?)
              ?.map((module) => Module.fromJson(module))
              .toList(),
      premium: json['premium'] ?? false,
      featured: json['featured'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      universityExclusive: json['universityExclusive'],
    );
  }

  // Method to convert a Course to a Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'thumbnailUrl': thumbnailUrl,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'creatorImageUrl': creatorImageUrl,
      'tags': tags,
      'duration': duration,
      'durationMinutes': durationMinutes,
      'xpReward': xpReward,
      'focusAreas': focusAreas,
      'lessons': lessons.map((lesson) => lesson.toJson()).toList(),
      'modules': modules.map((module) => module.toJson()).toList(),
      'premium': premium,
      'featured': featured,
      'createdAt': createdAt.toIso8601String(),
      'universityExclusive': universityExclusive,
      'universityAccess': universityAccess,
    };
  }
}

class Module {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String? thumbnailUrl; // Added for backwards compatibility
  final int audioCount;
  final List<String> categories;
  final bool premium;
  final ModuleType type; // Added for backwards compatibility
  final String? videoUrl; // Added for backwards compatibility
  final String? audioUrl; // Added for backwards compatibility
  final String? textContent; // Added for backwards compatibility
  final int durationMinutes; // Added for backwards compatibility
  final int sortOrder; // Added for backwards compatibility

  Module({
    required this.id,
    required this.title,
    required this.description,
    String? imageUrl, // Make imageUrl optional with a default value
    this.thumbnailUrl,
    this.audioCount = 0,
    required this.categories,
    this.premium = false,
    // Backwards compatibility fields
    ModuleType? type,
    this.videoUrl,
    this.audioUrl,
    this.textContent,
    int? durationMinutes,
    int? sortOrder,
  }) : 
    imageUrl = imageUrl ?? 'https://via.placeholder.com/300', // Default placeholder
    type = type ?? ModuleType.video,
    durationMinutes = durationMinutes ?? 10,
    sortOrder = sortOrder ?? 0;

  // Factory method to create a Module from a Map
  factory Module.fromJson(Map<String, dynamic> json) {
    ModuleType type = ModuleType.video;
    if (json['type'] != null) {
      try {
        type = ModuleType.values.firstWhere(
          (e) => e.toString().split('.').last == json['type'],
          orElse: () => ModuleType.video,
        );
      } catch (_) {
        // Default to video on error
      }
    }

    return Module(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      thumbnailUrl: json['thumbnailUrl'],
      audioCount: json['audioCount'] ?? 0,
      categories: List<String>.from(json['categories'] ?? []),
      premium: json['premium'] ?? false,
      type: type,
      videoUrl: json['videoUrl'],
      audioUrl: json['audioUrl'],
      textContent: json['textContent'],
      durationMinutes: json['durationMinutes'],
      sortOrder: json['sortOrder'],
    );
  }

  // Method to convert a Module to a Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'thumbnailUrl': thumbnailUrl,
      'audioCount': audioCount,
      'categories': categories,
      'premium': premium,
      'type': type.toString().split('.').last,
      'videoUrl': videoUrl,
      'audioUrl': audioUrl,
      'textContent': textContent,
      'durationMinutes': durationMinutes,
      'sortOrder': sortOrder,
    };
  }
}

class DailyAudio {
  final String id;
  final String title;
  final String description;
  final String audioUrl;
  final String imageUrl;
  final String creatorId;
  final String creatorName;
  final int durationMinutes;
  final List<String> focusAreas;
  final int xpReward;
  final DateTime datePublished;
  final bool universityExclusive;
  final List<String>? universityAccess;
  final String category;

  DailyAudio({
    required this.id,
    required this.title,
    required this.description,
    required this.audioUrl,
    required this.imageUrl,
    required this.creatorId,
    required this.creatorName,
    required this.durationMinutes,
    required this.focusAreas,
    required this.xpReward,
    required this.datePublished,
    required this.universityExclusive,
    this.universityAccess,
    required this.category,
  });

  factory DailyAudio.fromJson(Map<String, dynamic> json) {
    return DailyAudio(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      audioUrl: json['audioUrl'] as String,
      imageUrl: json['imageUrl'] as String,
      creatorId: json['creatorId'] as String,
      creatorName: json['creatorName'] as String,
      durationMinutes: json['durationMinutes'] as int,
      focusAreas: (json['focusAreas'] as List<dynamic>).map((e) => e as String).toList(),
      xpReward: json['xpReward'] as int,
      datePublished: DateTime.parse(json['datePublished'] as String),
      universityExclusive: json['universityExclusive'] as bool,
      universityAccess: json['universityAccess'] != null
          ? (json['universityAccess'] as List<dynamic>).map((e) => e as String).toList()
          : null,
      category: json['category'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'audioUrl': audioUrl,
      'imageUrl': imageUrl,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'durationMinutes': durationMinutes,
      'focusAreas': focusAreas,
      'xpReward': xpReward,
      'datePublished': datePublished.toIso8601String(),
      'universityExclusive': universityExclusive,
      'universityAccess': universityAccess,
      'category': category,
    };
  }
}

// New class to handle both audio and video content
enum MediaType { audio, video }

class MediaItem {
  final String id;
  final String title;
  final String description;
  final MediaType mediaType;
  final String mediaUrl; // Can be audio or video URL
  final String imageUrl; 
  final String creatorId;
  final String creatorName;
  final int durationMinutes;
  final List<String> focusAreas;
  final int xpReward;
  final DateTime datePublished;
  final bool universityExclusive;
  final List<String>? universityAccess;
  final String category;

  MediaItem({
    required this.id,
    required this.title,
    required this.description,
    required this.mediaType,
    required this.mediaUrl,
    required this.imageUrl,
    required this.creatorId,
    required this.creatorName,
    required this.durationMinutes,
    required this.focusAreas,
    required this.xpReward,
    required this.datePublished,
    required this.universityExclusive,
    this.universityAccess,
    required this.category,
  });

  // Create a MediaItem from a DailyAudio object
  factory MediaItem.fromDailyAudio(DailyAudio audio) {
    return MediaItem(
      id: audio.id,
      title: audio.title,
      description: audio.description,
      mediaType: MediaType.audio,
      mediaUrl: audio.audioUrl,
      imageUrl: audio.imageUrl,
      creatorId: audio.creatorId,
      creatorName: audio.creatorName,
      durationMinutes: audio.durationMinutes,
      focusAreas: audio.focusAreas,
      xpReward: audio.xpReward,
      datePublished: audio.datePublished,
      universityExclusive: audio.universityExclusive,
      universityAccess: audio.universityAccess,
      category: audio.category,
    );
  }

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      mediaType: json['mediaType'] == 'video' ? MediaType.video : MediaType.audio,
      mediaUrl: json['mediaUrl'] as String,
      imageUrl: json['imageUrl'] as String,
      creatorId: json['creatorId'] as String,
      creatorName: json['creatorName'] as String,
      durationMinutes: json['durationMinutes'] as int,
      focusAreas: (json['focusAreas'] as List<dynamic>).map((e) => e as String).toList(),
      xpReward: json['xpReward'] as int,
      datePublished: DateTime.parse(json['datePublished'] as String),
      universityExclusive: json['universityExclusive'] as bool,
      universityAccess: json['universityAccess'] != null
          ? (json['universityAccess'] as List<dynamic>).map((e) => e as String).toList()
          : null,
      category: json['category'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'mediaType': mediaType == MediaType.video ? 'video' : 'audio',
      'mediaUrl': mediaUrl,
      'imageUrl': imageUrl,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'durationMinutes': durationMinutes,
      'focusAreas': focusAreas,
      'xpReward': xpReward,
      'datePublished': datePublished.toIso8601String(),
      'universityExclusive': universityExclusive,
      'universityAccess': universityAccess,
      'category': category,
    };
  }
}

class JournalEntry {
  final String id;
  final String userId;
  final String title;
  final String content;
  final List<String>? tags;
  final DateTime createdAt;
  final DateTime? updatedAt;

  JournalEntry({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    this.tags,
    required this.createdAt,
    this.updatedAt,
  });

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      tags: json['tags'] != null
          ? (json['tags'] as List<dynamic>).map((e) => e as String).toList()
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'content': content,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class Coach {
  final String id;
  final String fullName;
  final String bio;
  final String profileImageUrl;
  final String specialty;
  final List<String> focusAreas;
  final List<String> courseIds;
  final List<String> audioIds;
  final bool verified;
  final bool universityExclusive;
  final List<String>? universityAccess;

  Coach({
    required this.id,
    required this.fullName,
    required this.bio,
    required this.profileImageUrl,
    required this.specialty,
    required this.focusAreas,
    required this.courseIds,
    required this.audioIds,
    required this.verified,
    required this.universityExclusive,
    this.universityAccess,
  });

  factory Coach.fromJson(Map<String, dynamic> json) {
    return Coach(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      bio: json['bio'] as String,
      profileImageUrl: json['profileImageUrl'] as String,
      specialty: json['specialty'] as String,
      focusAreas: (json['focusAreas'] as List<dynamic>).map((e) => e as String).toList(),
      courseIds: (json['courseIds'] as List<dynamic>).map((e) => e as String).toList(),
      audioIds: (json['audioIds'] as List<dynamic>).map((e) => e as String).toList(),
      verified: json['verified'] as bool,
      universityExclusive: json['universityExclusive'] as bool,
      universityAccess: json['universityAccess'] != null
          ? (json['universityAccess'] as List<dynamic>).map((e) => e as String).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'bio': bio,
      'profileImageUrl': profileImageUrl,
      'specialty': specialty,
      'focusAreas': focusAreas,
      'courseIds': courseIds,
      'audioIds': audioIds,
      'verified': verified,
      'universityExclusive': universityExclusive,
      'universityAccess': universityAccess,
    };
  }
}

class Article {
  final String id;
  final String title;
  final String authorId;
  final String authorName;
  final String authorImageUrl;
  final String content;
  final String thumbnailUrl;
  final DateTime publishedDate;
  final List<String> tags;
  final int readTimeMinutes;
  final List<String> focusAreas;
  final bool universityExclusive;
  final List<String>? universityAccess;

  Article({
    required this.id,
    required this.title,
    required this.authorId,
    required this.authorName,
    required this.authorImageUrl,
    required this.content,
    required this.thumbnailUrl, 
    required this.publishedDate,
    required this.tags,
    required this.readTimeMinutes,
    required this.focusAreas,
    required this.universityExclusive,
    this.universityAccess,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['id'] as String,
      title: json['title'] as String,
      authorId: json['authorId'] as String,
      authorName: json['authorName'] as String,
      authorImageUrl: json['authorImageUrl'] as String,
      content: json['content'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String,
      publishedDate: DateTime.parse(json['publishedDate'] as String),
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
      readTimeMinutes: json['readTimeMinutes'] as int,
      focusAreas: (json['focusAreas'] as List<dynamic>).map((e) => e as String).toList(),
      universityExclusive: json['universityExclusive'] as bool,
      universityAccess: json['universityAccess'] != null
          ? (json['universityAccess'] as List<dynamic>).map((e) => e as String).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'authorId': authorId,
      'authorName': authorName,
      'authorImageUrl': authorImageUrl,
      'content': content,
      'thumbnailUrl': thumbnailUrl,
      'publishedDate': publishedDate.toIso8601String(),
      'tags': tags,
      'readTimeMinutes': readTimeMinutes,
      'focusAreas': focusAreas,
      'universityExclusive': universityExclusive,
      'universityAccess': universityAccess,
    };
  }
} 