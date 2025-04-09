import 'package:cloud_firestore/cloud_firestore.dart';

class Coach {
  final String id;
  final String name;
  final String title;
  final String bio;
  final String imageUrl;
  final double rating;
  final int reviewCount;
  final String specialization;
  final String experience;
  final bool isActive;
  final String bookingLink;
  final List<String> courses;
  final DateTime createdAt;

  Coach({
    required this.id,
    required this.name,
    required this.title,
    required this.bio,
    required this.imageUrl,
    required this.rating,
    required this.reviewCount,
    required this.specialization,
    required this.experience,
    required this.isActive,
    required this.bookingLink,
    required this.courses,
    required this.createdAt,
  });

  factory Coach.fromJson(Map<String, dynamic> json) {
    return Coach(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      title: json['title'] ?? '',
      bio: json['bio'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      specialization: json['specialization'] ?? '',
      experience: json['experience'] ?? '',
      isActive: json['isActive'] ?? false,
      bookingLink: json['bookingLink'] ?? '',
      courses: List<String>.from(json['courses'] ?? []),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'title': title,
      'bio': bio,
      'imageUrl': imageUrl,
      'rating': rating,
      'reviewCount': reviewCount,
      'specialization': specialization,
      'experience': experience,
      'isActive': isActive,
      'bookingLink': bookingLink,
      'courses': courses,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Coach copyWith({
    String? id,
    String? name,
    String? title,
    String? bio,
    String? imageUrl,
    double? rating,
    int? reviewCount,
    String? specialization,
    String? experience,
    bool? isActive,
    String? bookingLink,
    List<String>? courses,
    DateTime? createdAt,
  }) {
    return Coach(
      id: id ?? this.id,
      name: name ?? this.name,
      title: title ?? this.title,
      bio: bio ?? this.bio,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      specialization: specialization ?? this.specialization,
      experience: experience ?? this.experience,
      isActive: isActive ?? this.isActive,
      bookingLink: bookingLink ?? this.bookingLink,
      courses: courses ?? this.courses,
      createdAt: createdAt ?? this.createdAt,
    );
  }
} 