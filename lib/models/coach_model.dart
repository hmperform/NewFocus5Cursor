import 'package:cloud_firestore/cloud_firestore.dart';

class Coach {
  final String id;
  final String name;
  final String title;
  final String bio;
  final String imageUrl;
  final String experience;
  final List<String> specializations;
  final bool isActive;
  final double rating;
  final int reviewCount;
  final DateTime createdAt;
  final List<String> courses;

  Coach({
    required this.id,
    required this.name,
    required this.title,
    required this.bio,
    required this.imageUrl,
    required this.experience,
    required this.specializations,
    required this.isActive,
    required this.rating,
    required this.reviewCount,
    required this.createdAt,
    required this.courses,
  });

  factory Coach.fromJson(Map<String, dynamic> json) {
    return Coach(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      title: json['title'] ?? '',
      bio: json['bio'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      experience: json['experience'] ?? '',
      specializations: List<String>.from(json['specializations'] ?? []),
      isActive: json['isActive'] ?? false,
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      courses: List<String>.from(json['courses'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'title': title,
      'bio': bio,
      'imageUrl': imageUrl,
      'experience': experience,
      'specializations': specializations,
      'isActive': isActive,
      'rating': rating,
      'reviewCount': reviewCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'courses': courses,
    };
  }

  Coach copyWith({
    String? id,
    String? name,
    String? title,
    String? bio,
    String? imageUrl,
    String? experience,
    List<String>? specializations,
    bool? isActive,
    double? rating,
    int? reviewCount,
    DateTime? createdAt,
    List<String>? courses,
  }) {
    return Coach(
      id: id ?? this.id,
      name: name ?? this.name,
      title: title ?? this.title,
      bio: bio ?? this.bio,
      imageUrl: imageUrl ?? this.imageUrl,
      experience: experience ?? this.experience,
      specializations: specializations ?? this.specializations,
      isActive: isActive ?? this.isActive,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      createdAt: createdAt ?? this.createdAt,
      courses: courses ?? this.courses,
    );
  }
} 