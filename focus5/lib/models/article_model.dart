class Article {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String author;
  final String authorImageUrl;
  final String authorTitle;
  final DateTime publishDate;
  final List<String> tags;
  final int readTime; // in minutes
  final bool isPremium;

  Article({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.author,
    required this.authorImageUrl,
    required this.authorTitle,
    required this.publishDate,
    required this.tags,
    required this.readTime,
    this.isPremium = false,
  });
} 