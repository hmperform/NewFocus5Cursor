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
  final List<String>? slideshowImages;
  final String? courseTitle;
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
    this.slideshowImages,
    this.courseTitle,
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
      slideshowImages: (json['slideshowImages'] as List<dynamic>?)?.map((e) => e as String).toList(),
      courseTitle: json['courseTitle'] as String?,
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
      'slideshowImages': slideshowImages,
      'courseTitle': courseTitle,
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
  final int focusPointsCost;

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
    required this.focusPointsCost,
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
    learningPoints = [],
    focusPointsCost = 0;

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
      focusPointsCost: (json['focusPointsCost'] as num?)?.toInt() ?? (json['focusPointCost'] as num?)?.toInt() ?? 0,
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
      'focusPointsCost': focusPointsCost,
    };
  }
}

class DailyAudio {
  final String id;
  final String title;
  final String description;
  final String audioUrl;
  final String thumbnail;
  final String slideshow1;
  final String slideshow2;
  final String slideshow3;
  final DocumentReference creatorId;
  final DocumentReference creatorName;
  final List<String> focusAreas;
  final int durationMinutes;
  final int xpReward;
  final bool universityExclusive;
  final DocumentReference? universityAccess;
  final DateTime createdAt;
  final DateTime datePublished;
  final List<double> waveformData; // Add waveform data array
  final int waveformResolution; // Add waveform resolution (samples per second)
  final Map<String, dynamic>? postCompletionScreens; // Add post-completion screens data

  // Add these properties to fix errors
  String get imageUrl => thumbnail; // Alias thumbnail as imageUrl
  String get category => focusAreas.isNotEmpty ? focusAreas.first : ""; // Use first focus area as category
  List<String> get categories => focusAreas; // Alias focusAreas as categories

  DailyAudio({
    required this.id,
    required this.title,
    required this.description,
    required this.audioUrl,
    required this.thumbnail,
    required this.slideshow1,
    required this.slideshow2,
    required this.slideshow3,
    required this.creatorId,
    required this.creatorName,
    required this.focusAreas,
    required this.durationMinutes,
    required this.xpReward,
    required this.universityExclusive,
    this.universityAccess,
    required this.createdAt,
    required this.datePublished,
    this.waveformData = const [], // Default empty waveform
    this.waveformResolution = 100, // Default 100 samples per second
    this.postCompletionScreens, // Add post-completion screens parameter
  });

  factory DailyAudio.fromJson(Map<String, dynamic> json) {
    return DailyAudio(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      audioUrl: json['audioUrl'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
      slideshow1: json['slideshow1'] ?? '',
      slideshow2: json['slideshow2'] ?? '',
      slideshow3: json['slideshow3'] ?? '',
      creatorId: json['creatorId'] is DocumentReference
          ? json['creatorId']
          : FirebaseFirestore.instance.doc('coaches/${json['creatorId']['id'] ?? ''}'),
      creatorName: json['creatorName'] is DocumentReference
          ? json['creatorName']
          : FirebaseFirestore.instance.doc('coaches/${json['creatorName']['id'] ?? ''}'),
      focusAreas: List<String>.from(json['focusAreas'] ?? []),
      durationMinutes: json['durationMinutes'] ?? 0,
      xpReward: json['xpReward'] ?? 0,
      universityExclusive: json['universityExclusive'] ?? false,
      universityAccess: json['universityAccess'] != null
          ? FirebaseFirestore.instance.doc('universities/${json['universityAccess']['id'] ?? ''}')
          : null,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is Timestamp
              ? (json['createdAt'] as Timestamp).toDate()
              : DateTime.parse(json['createdAt']))
          : DateTime.now(),
      datePublished: json['datePublished'] != null
          ? (json['datePublished'] is Timestamp
              ? (json['datePublished'] as Timestamp).toDate()
              : DateTime.parse(json['datePublished']))
          : DateTime.now(),
      waveformData: List<double>.from(json['waveformData'] ?? []),
      waveformResolution: json['waveformResolution'] ?? 100,
      postCompletionScreens: json['postCompletionScreens'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'audioUrl': audioUrl,
      'thumbnail': thumbnail,
      'slideshow1': slideshow1,
      'slideshow2': slideshow2,
      'slideshow3': slideshow3,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'focusAreas': focusAreas,
      'durationMinutes': durationMinutes,
      'xpReward': xpReward,
      'universityExclusive': universityExclusive,
      'universityAccess': universityAccess,
      'createdAt': createdAt.toIso8601String(),
      'datePublished': datePublished.toIso8601String(),
      'waveformData': waveformData,
      'waveformResolution': waveformResolution,
      'postCompletionScreens': postCompletionScreens,
    };
  }
}

// Enum for Media Type (can be expanded)
enum MediaType {
  video,
  audio,
  article,
  quiz // Add other types as needed
}

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
      imageUrl: audio.thumbnail,
      creatorId: audio.creatorId.id,
      creatorName: audio.creatorName.id,
      durationMinutes: audio.durationMinutes,
      focusAreas: audio.focusAreas,
      xpReward: audio.xpReward,
      datePublished: audio.datePublished,
      universityExclusive: audio.universityExclusive,
      universityAccess: audio.universityAccess != null
          ? [audio.universityAccess!.id]
          : null,
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

// Enum to identify the origin of the audio in AudioProvider
enum AudioSource { daily, lesson, unknown }

// Audio Class used by AudioProvider
class Audio {
  final String id;
  final String title;
  final String subtitle; // Used for courseTitle in lessons, focusAreas in daily
  final String description;
  final String imageUrl;
  final String audioUrl;
  final int sequence;
  final String? waveformUrl;
  final List<String> slideshowImages;
  final AudioSource sourceType; // <-- ADD THIS
  final String? courseTitle;    // <-- ADD THIS (explicitly for lessons)

  Audio({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.imageUrl,
    required this.audioUrl,
    required this.sequence,
    this.waveformUrl,
    required this.slideshowImages,
    this.sourceType = AudioSource.unknown, // <-- ADD DEFAULT
    this.courseTitle,                     // <-- ADD THIS
  });

  // fromMap and toMap might not be strictly necessary if AudioProvider
  // constructs this object programmatically, but added for completeness
  factory Audio.fromMap(Map<String, dynamic> map) {
    return Audio(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      subtitle: map['subtitle'] as String? ?? '',
      description: map['description'] as String? ?? '',
      imageUrl: map['imageUrl'] as String? ?? '',
      audioUrl: map['audioUrl'] as String? ?? '',
      sequence: map['sequence'] as int? ?? 0,
      waveformUrl: map['waveformUrl'] as String?,
      slideshowImages: map['slideshowImages'] != null 
          ? List<String>.from(map['slideshowImages'])
          : [],
      sourceType: map['sourceType'] != null
          ? AudioSource.values.firstWhere((e) => e.name == map['sourceType'], orElse: () => AudioSource.unknown)
          : AudioSource.unknown,
       courseTitle: map['courseTitle'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'sequence': sequence,
      'waveformUrl': waveformUrl,
      'slideshowImages': slideshowImages,
      'sourceType': sourceType.name, // Store enum name as string
      'courseTitle': courseTitle,
    };
  }
}

class AppBadge {
  final String id;
  final String name;
  final String description;
  final String? imageUrl; // Original field
  final String? badgeImage; // Field for the primary badge display image
  final DateTime earnedAt; // Keep this, even if not always set initially
  final int xpValue;
  final String criteriaType;
  final int requiredCount;
  final List<String>? specificIds;
  final List<Map<String, dynamic>>? specificCourses; // Add this field
  final bool? mustCompleteAllCourses; // Add this field

  AppBadge({
    required this.id,
    required this.name,
    required this.description,
    this.imageUrl,
    this.badgeImage,
    DateTime? earnedAt, // Make nullable in constructor for all badges
    required this.xpValue,
    required this.criteriaType,
    required this.requiredCount,
    this.specificIds,
    this.specificCourses, // Add to constructor
    this.mustCompleteAllCourses, // Add to constructor
  }) : this.earnedAt = earnedAt ?? DateTime.now(); // Default if needed

  factory AppBadge.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>? ?? {};
    
    // Handle specificIds separately to avoid type casting issues
    List<String>? specificIds;
    if (data['specificIds'] != null) {
      try {
        if (data['specificIds'] is List) {
          specificIds = (data['specificIds'] as List).map((e) {
            // Handle both string and reference types
            if (e is String) return e;
            if (e is DocumentReference) return e.id;
            if (e is Map) return e['id']?.toString();
            return e.toString();
          }).where((e) => e != null).cast<String>().toList();
        }
      } catch (e) {
        debugPrint('Error parsing specificIds for badge ${doc.id}: $e');
        specificIds = null;
      }
    }

    // Handle specificCourses field
    List<Map<String, dynamic>>? specificCourses;
    if (data['specificCourses'] != null) {
      try {
        if (data['specificCourses'] is List) {
          specificCourses = (data['specificCourses'] as List).map((course) {
            if (course is DocumentReference) {
              return {'id': course.id, 'path': course.path};
            }
            if (course is Map) {
              return Map<String, dynamic>.from(course);
            }
            return {'id': course.toString()};
          }).toList();
        }
      } catch (e) {
        debugPrint('Error parsing specificCourses for badge ${doc.id}: $e');
        specificCourses = null;
      }
    }
    
    return AppBadge(
      id: doc.id,
      name: data['name']?.toString() ?? 'Unknown Badge',
      description: data['description']?.toString() ?? '',
      imageUrl: data['imageUrl']?.toString(),
      badgeImage: data['badgeImage']?.toString(),
      xpValue: (data['xpValue'] as num?)?.toInt() ?? 0,
      criteriaType: data['criteriaType']?.toString() ?? '',
      requiredCount: (data['requiredCount'] as num?)?.toInt() ?? 0,
      specificIds: specificIds,
      specificCourses: specificCourses,
      mustCompleteAllCourses: data['mustCompleteAllCourses'] as bool?,
    );
  }

  // Add copyWith method to allow creating a new instance with some properties updated
  AppBadge copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    String? badgeImage,
    DateTime? earnedAt,
    int? xpValue,
    String? criteriaType,
    int? requiredCount,
    List<String>? specificIds,
    List<Map<String, dynamic>>? specificCourses,
    bool? mustCompleteAllCourses,
  }) {
    return AppBadge(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      badgeImage: badgeImage ?? this.badgeImage,
      earnedAt: earnedAt ?? this.earnedAt,
      xpValue: xpValue ?? this.xpValue,
      criteriaType: criteriaType ?? this.criteriaType,
      requiredCount: requiredCount ?? this.requiredCount,
      specificIds: specificIds ?? this.specificIds,
      specificCourses: specificCourses ?? this.specificCourses,
      mustCompleteAllCourses: mustCompleteAllCourses ?? this.mustCompleteAllCourses,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'imageUrl': imageUrl,
        'badgeImage': badgeImage,
        // Don't write earnedAt back to the definition
        // 'earnedAt': Timestamp.fromDate(earnedAt),
        'xpValue': xpValue,
        'criteriaType': criteriaType,
        'requiredCount': requiredCount,
        'specificIds': specificIds,
        'specificCourses': specificCourses,
        'mustCompleteAllCourses': mustCompleteAllCourses,
      };
} 