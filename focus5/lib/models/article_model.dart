class Article {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String author;
  final String authorId;
  final String authorName;
  final String authorImageUrl;
  final String authorTitle;
  final DateTime publishDate;
  final DateTime publishedDate;
  final List<String> tags;
  final List<String> focusAreas;
  final int readTime;
  final int readTimeMinutes;
  final bool isPremium;
  final String content;
  final String summary;
  final String thumbnailUrl;
  final bool universityExclusive;
  final List<String>? universityAccess;

  Article({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.author,
    this.authorId = '',
    this.authorName = '',
    required this.authorImageUrl,
    required this.authorTitle,
    required this.publishDate,
    DateTime? publishedDate,
    required this.tags,
    this.focusAreas = const [],
    required this.readTime,
    int? readTimeMinutes,
    this.isPremium = false,
    this.content = '',
    this.summary = '',
    String? thumbnailUrl,
    this.universityExclusive = false,
    this.universityAccess,
  }) : 
    this.publishedDate = publishedDate ?? publishDate,
    this.readTimeMinutes = readTimeMinutes ?? readTime,
    this.thumbnailUrl = thumbnailUrl ?? imageUrl;
} 