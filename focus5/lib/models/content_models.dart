class Course {
  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String creatorId;
  final String creatorName;
  final String creatorImageUrl;
  final List<String> tags;
  final List<String> focusAreas;
  final int durationMinutes;
  final int xpReward;
  final List<Module> modules;
  final DateTime createdAt;
  final bool universityExclusive;
  final List<String>? universityAccess;

  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.creatorId,
    required this.creatorName,
    required this.creatorImageUrl,
    required this.tags,
    required this.focusAreas,
    required this.durationMinutes,
    required this.xpReward,
    required this.modules,
    required this.createdAt,
    required this.universityExclusive,
    this.universityAccess,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String,
      creatorId: json['creatorId'] as String,
      creatorName: json['creatorName'] as String,
      creatorImageUrl: json['creatorImageUrl'] as String,
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
      focusAreas: (json['focusAreas'] as List<dynamic>).map((e) => e as String).toList(),
      durationMinutes: json['durationMinutes'] as int,
      xpReward: json['xpReward'] as int,
      modules: (json['modules'] as List<dynamic>)
          .map((e) => Module.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
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
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'creatorImageUrl': creatorImageUrl,
      'tags': tags,
      'focusAreas': focusAreas,
      'durationMinutes': durationMinutes,
      'xpReward': xpReward,
      'modules': modules.map((module) => module.toJson()).toList(),
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
  final ModuleType type;
  final String? videoUrl;
  final String? audioUrl;
  final String? textContent;
  final int durationMinutes;
  final int sortOrder;
  final String? thumbnailUrl;

  Module({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.videoUrl,
    this.audioUrl,
    this.textContent,
    required this.durationMinutes,
    required this.sortOrder,
    this.thumbnailUrl,
  });

  factory Module.fromJson(Map<String, dynamic> json) {
    return Module(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: ModuleType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => ModuleType.video,
      ),
      videoUrl: json['videoUrl'] as String?,
      audioUrl: json['audioUrl'] as String?,
      textContent: json['textContent'] as String?,
      durationMinutes: json['durationMinutes'] as int,
      sortOrder: json['sortOrder'] as int,
      thumbnailUrl: json['thumbnailUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.toString().split('.').last,
      'videoUrl': videoUrl,
      'audioUrl': audioUrl,
      'textContent': textContent,
      'durationMinutes': durationMinutes,
      'sortOrder': sortOrder,
      'thumbnailUrl': thumbnailUrl,
    };
  }
}

enum ModuleType { video, audio, text, quiz }

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