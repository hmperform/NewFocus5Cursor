import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

// Module types enum
enum LessonType {
  video,
  audio,
  text,
  quiz
}

class Lesson {
  final String id;
  final String title;
  final String? description;
  final String? videoUrl;
  final String? audioUrl;
  final String? imageUrl;
  final String? thumbnailUrl;
  final String? textContent;
  final int durationMinutes;
  final bool completed;
  final int sortOrder;
  final LessonType type;
  final List<String> categories;
  final bool premium;
  final Map<String, dynamic>? courseId;
  // Add a convenience getter to access the course ID string
  String get courseIdString => courseId != null && courseId!.containsKey('id') ? courseId!['id'] as String : '';
  // Add a getter to create a DocumentReference from the courseId map
  DocumentReference? get courseRef => courseId != null && courseId!.containsKey('id') 
      ? FirebaseFirestore.instance.collection('courses').doc(courseId!['id'] as String)
      : null;

  Lesson({
    required this.id,
    required this.title,
    this.description,
    this.videoUrl,
    this.audioUrl,
    this.imageUrl,
    this.thumbnailUrl,
    this.textContent,
    required this.durationMinutes,
    required this.completed,
    required this.sortOrder,
    required this.type,
    this.categories = const [],
    this.premium = false,
    required this.courseId,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    LessonType type = LessonType.video;
    if (json['type'] != null) {
      try {
        type = LessonType.values.firstWhere(
          (e) => e.toString().split('.').last == json['type'],
          orElse: () => LessonType.video,
        );
      } catch (_) {
        // Default to video on error
      }
    }
    
    // Parse courseId field safely - handle all possible formats
    Map<String, dynamic>? parsedCourseId;
    if (json['courseId'] is Map) {
      // This handles the nested courseId object format: {id: "course-001", path: "courses"}
      parsedCourseId = Map<String, dynamic>.from(json['courseId']);
    } else if (json['courseId'] is String) {
      // Handle legacy string format
      parsedCourseId = {"id": json['courseId']};
    } else if (json['courseId'] is DocumentReference) {
      // Handle DocumentReference type
      DocumentReference ref = json['courseId'] as DocumentReference;
      parsedCourseId = {"id": ref.id, "path": ref.path};
    } else if (json['courseId'] == null) {
      // Handle null case
      parsedCourseId = null;
      debugPrint("Warning: Lesson ${json['id']} has null courseId");
    } else {
      // Handle unexpected type
      debugPrint("Warning: Lesson ${json['id']} has courseId of unexpected type: ${json['courseId'].runtimeType}");
      parsedCourseId = null;
    }
    
    return Lesson(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      videoUrl: json['videoUrl'] as String?,
      audioUrl: json['audioUrl'] as String?,
      imageUrl: json['imageUrl'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      textContent: json['textContent'] as String?,
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
      completed: json['completed'] as bool? ?? false,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      type: type,
      categories: (json['categories'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      premium: json['premium'] as bool? ?? false,
      courseId: parsedCourseId,
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
      'thumbnailUrl': thumbnailUrl,
      'textContent': textContent,
      'durationMinutes': durationMinutes,
      'completed': completed,
      'sortOrder': sortOrder,
      'type': type.toString().split('.').last,
      'categories': categories,
      'premium': premium,
      'courseId': courseId,
    };
  }
}

class Course {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String thumbnailUrl;
  final String creatorId;
  final String creatorName;
  final String creatorImageUrl;
  final List<String> tags;
  final List<String> focusAreas;
  final int durationMinutes;
  final int duration;
  final int xpReward;
  final List<Lesson> lessonsList;
  final DateTime createdAt;
  final bool universityExclusive;
  final List<String>? universityAccess;
  final bool featured;
  final bool premium;
  final List<String> learningPoints;

  // Getter for modules to maintain backward compatibility
  List<Lesson> get modules => lessonsList;

  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.thumbnailUrl,
    required this.creatorId,
    required this.creatorName,
    required this.creatorImageUrl,
    required this.tags,
    required this.focusAreas,
    required this.durationMinutes,
    required this.duration,
    required this.xpReward,
    required this.lessonsList,
    required this.createdAt,
    required this.universityExclusive,
    this.universityAccess,
    this.featured = false,
    this.premium = false,
    this.learningPoints = const [],
  });

  // Empty constructor for Course
  Course.empty() : 
    id = '',
    title = '',
    description = '',
    imageUrl = '',
    thumbnailUrl = '',
    creatorId = '',
    creatorName = '',
    creatorImageUrl = '',
    tags = [],
    focusAreas = [],
    durationMinutes = 0,
    duration = 0,
    xpReward = 0,
    lessonsList = [],
    createdAt = DateTime.now(),
    universityExclusive = false,
    universityAccess = null,
    featured = false,
    premium = false,
    learningPoints = [];

  factory Course.fromJson(Map<String, dynamic> json) {
    // This list will hold the parsed Lesson objects
    List<Lesson> parsedLessons = []; 
    
    // Check multiple keys and parse into Lesson objects
    if (json['lessons'] != null && json['lessons'] is List) {
      parsedLessons = (json['lessons'] as List)
          .map((lessonJson) {
            // Ensure lessonJson has an 'id' before parsing
            if (lessonJson is Map<String, dynamic> && lessonJson['id'] != null) {
              return Lesson.fromJson(lessonJson);
            } else {
              // Handle cases where lesson data is invalid or missing ID
              debugPrint('>>> Course.fromJson: Invalid lesson data encountered: $lessonJson');
              // Return a default/empty lesson or skip it
              return null; // Or return Lesson.empty() if you have an empty constructor
            }
          })
          .where((lesson) => lesson != null) // Filter out nulls from invalid data
          .cast<Lesson>() // Cast to List<Lesson>
          .toList();
    } 
    // Add checks for 'modules' and 'lessonsList' if needed, similar to above
    else if (json['modules'] != null && json['modules'] is List) {
      // Similar parsing logic as above, ensuring 'id' exists
      parsedLessons = (json['modules'] as List)
          .map((moduleJson) {
             if (moduleJson is Map<String, dynamic> && moduleJson['id'] != null) {
              return Lesson.fromJson(moduleJson);
            } else {
              debugPrint('>>> Course.fromJson: Invalid module data encountered: $moduleJson');
              return null;
            }
          })
          .where((lesson) => lesson != null)
          .cast<Lesson>()
          .toList();
    }
    else if (json['lessonsList'] != null && json['lessonsList'] is List) {
       // Similar parsing logic as above, ensuring 'id' exists
      parsedLessons = (json['lessonsList'] as List)
          .map((lessonJson) {
            if (lessonJson is Map<String, dynamic> && lessonJson['id'] != null) {
              return Lesson.fromJson(lessonJson);
            } else {
              debugPrint('>>> Course.fromJson: Invalid lessonsList data encountered: $lessonJson');
              return null;
            }
          })
          .where((lesson) => lesson != null)
          .cast<Lesson>()
          .toList();
    }

    // Helper function to safely parse creatorId (Now handles Map too)
    String _parseCreatorId(dynamic value) {
      if (value is String) {
        return value;
      } else if (value is DocumentReference) {
        return value.id;
      } else if (value is Map && value.containsKey('id') && value['id'] is String) {
        return value['id'];
      }
      return ''; 
    }

    // debugPrint(">>> Course.fromJson: Input json['lessons'] type: ${json['lessons']?.runtimeType}, Length: ${(json['lessons'] as List?)?.length}");
    // debugPrint(">>> Course.fromJson: Parsed lessons list length before return: ${parsedLessons.length}");

    return Course(
      id: json['id'] as String? ?? '', 
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? json['thumbnailUrl'] as String? ?? '',
      thumbnailUrl: json['thumbnailUrl'] as String? ?? '',
      // Use the updated helper function for creatorId
      creatorId: _parseCreatorId(json['creatorId']), 
      creatorName: json['creatorName'] as String? ?? '', 
      creatorImageUrl: json['creatorImageUrl'] as String? ?? '', 
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      focusAreas: (json['focusAreas'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
      duration: (json['duration'] as num?)?.toInt() ?? 0, 
      xpReward: (json['xpReward'] as num?)?.toInt() ?? 0,
      lessonsList: parsedLessons, 
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : (json['createdAt'] is String ? DateTime.tryParse(json['createdAt']) : null) ?? DateTime.now(),
      universityExclusive: json['universityExclusive'] as bool? ?? false,
      universityAccess: json['universityAccess'] != null
          ? (json['universityAccess'] as List<dynamic>).map((e) => e as String).toList()
          : null,
      featured: json['featured'] as bool? ?? false,
      premium: json['premium'] as bool? ?? false,
      learningPoints: (json['learningPoints'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
    );
  }

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
      'focusAreas': focusAreas,
      'durationMinutes': durationMinutes,
      'duration': duration,
      'xpReward': xpReward,
      'lessons': lessonsList.map((lesson) => lesson.toJson()).toList(),
      'lessonsList': lessonsList.map((lesson) => lesson.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'universityExclusive': universityExclusive,
      'universityAccess': universityAccess,
      'featured': featured,
      'premium': premium,
      'learningPoints': learningPoints,
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
  
  // Add categories property with getter that returns a list with the single category
  List<String> get categories => [category];

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