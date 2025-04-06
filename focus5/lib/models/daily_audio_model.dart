class DailyAudio {
  final String id;
  final String title;
  final String description;
  final String category;
  final String imageUrl;
  final String audioUrl;
  final int duration; // in seconds
  final String creatorId;
  final String creatorName;
  final DateTime date;
  final List<String> focusAreas;
  final bool isFeatured;

  DailyAudio({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.imageUrl,
    required this.audioUrl,
    required this.duration,
    required this.creatorId,
    required this.creatorName,
    required this.date,
    required this.focusAreas,
    this.isFeatured = false,
  });

  // Create a DailyAudio from a Firestore document
  factory DailyAudio.fromMap(Map<String, dynamic> map) {
    return DailyAudio(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      category: map['category'] as String,
      imageUrl: map['imageUrl'] as String,
      audioUrl: map['audioUrl'] as String,
      duration: map['duration'] as int,
      creatorId: map['creatorId'] as String,
      creatorName: map['creatorName'] as String,
      date: DateTime.parse(map['date'] as String),
      focusAreas: List<String>.from(map['focusAreas'] as List),
      isFeatured: map['isFeatured'] as bool? ?? false,
    );
  }

  // Convert a DailyAudio to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'duration': duration,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'date': date.toIso8601String(),
      'focusAreas': focusAreas,
      'isFeatured': isFeatured,
    };
  }
} 