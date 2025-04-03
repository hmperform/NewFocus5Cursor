import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

enum MoodLevel {
  terrible,
  bad,
  okay,
  good,
  awesome,
}

extension MoodLevelExtension on MoodLevel {
  String get name {
    switch (this) {
      case MoodLevel.terrible:
        return 'Terrible';
      case MoodLevel.bad:
        return 'Bad';
      case MoodLevel.okay:
        return 'Okay';
      case MoodLevel.good:
        return 'Good';
      case MoodLevel.awesome:
        return 'Awesome';
    }
  }

  String get emoji {
    switch (this) {
      case MoodLevel.terrible:
        return '😞';
      case MoodLevel.bad:
        return '😔';
      case MoodLevel.okay:
        return '😐';
      case MoodLevel.good:
        return '🙂';
      case MoodLevel.awesome:
        return '😊';
    }
  }
}

class JournalEntry {
  final String id;
  final String userId;
  final String prompt;
  final String content;
  final DateTime date;
  final MoodLevel mood;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFavorite;

  JournalEntry({
    required this.id,
    required this.userId,
    required this.prompt,
    required this.content,
    required this.date,
    required this.mood,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isFavorite = false,
  });

  // Format the date in different ways
  String get formattedDate => DateFormat('EEEE, MMMM d, y').format(date);
  String get shortDate => DateFormat('MMM d').format(date);
  String get dayName => DateFormat('EEEE').format(date);
  String get monthDay => DateFormat('MMMM d').format(date);

  // Create from Map (for local storage)
  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    return JournalEntry(
      id: map['id'],
      userId: map['userId'],
      prompt: map['prompt'],
      content: map['content'],
      date: DateTime.parse(map['date']),
      mood: MoodLevel.values[map['mood']],
      tags: List<String>.from(map['tags']),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      isFavorite: map['isFavorite'] ?? false,
    );
  }

  // Convert to Map (for local storage)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'prompt': prompt,
      'content': content,
      'date': date.toIso8601String(),
      'mood': mood.index,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isFavorite': isFavorite,
    };
  }

  // Create a copy with updated fields
  JournalEntry copyWith({
    String? id,
    String? userId,
    String? prompt,
    String? content,
    DateTime? date,
    MoodLevel? mood,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFavorite,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      prompt: prompt ?? this.prompt,
      content: content ?? this.content,
      date: date ?? this.date,
      mood: mood ?? this.mood,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

class JournalPrompt {
  final String id;
  final String text;
  final List<String> categories;

  JournalPrompt({
    required this.id,
    required this.text,
    this.categories = const [],
  });

  // Create from Map (for local storage)
  factory JournalPrompt.fromMap(Map<String, dynamic> map) {
    return JournalPrompt(
      id: map['id'],
      text: map['text'],
      categories: List<String>.from(map['categories']),
    );
  }

  // Convert to Map (for local storage)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'categories': categories,
    };
  }
} 