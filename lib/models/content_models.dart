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
  }) : _lessons = lessons ?? [];

  List<Lesson> get lessons => _lessons;
  List<Lesson> get lessonsList => _lessons;

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