import 'package:cloud_firestore/cloud_firestore.dart';

class Coach {
  final String id;
  final String name;
  final String title;
  final String bio;
  final String profileImageUrl;
  final String headerImageUrl;
  final double rating;
  final int reviewCount;
  final List<String>? specialization;
  final List<String> credentials;
  final int experience;
  final bool isActive;
  final String bookingUrl;
  final String? email;
  final String? phoneNumber;
  final String? instagramUrl;
  final String? twitterUrl;
  final String? linkedinUrl;
  final String? websiteUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  Coach({
    required this.id,
    required this.name,
    required this.title,
    required this.bio,
    required this.profileImageUrl,
    required this.headerImageUrl,
    required this.rating,
    required this.reviewCount,
    this.specialization,
    required this.credentials,
    required this.experience,
    required this.isActive,
    required this.bookingUrl,
    this.email,
    this.phoneNumber,
    this.instagramUrl,
    this.twitterUrl,
    this.linkedinUrl,
    this.websiteUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Coach.fromJson(Map<String, dynamic> json) {
    DateTime? _toDateTime(dynamic timestamp) {
      if (timestamp is Timestamp) {
        return timestamp.toDate();
      } else if (timestamp is String) {
        return DateTime.tryParse(timestamp);
      }
      return null;
    }

    int _parseExperience(dynamic expValue) {
      if (expValue is int) {
        return expValue;
      } else if (expValue is double) {
        // Handle potential double values from Firestore
        return expValue.toInt();
      } else if (expValue is String) {
        // Try to extract leading digits from the string
        final match = RegExp(r'^(\d+)').firstMatch(expValue);
        if (match != null && match.group(1) != null) {
          return int.tryParse(match.group(1)!) ?? 0;
        }
      }
      // Default if null, not an int/double, or not a parsable string
      return 0;
    }

    // Handle potential list or string field for specialization
    List<String> specializationList = [];
    if (json['specialization'] is List) {
      specializationList = List<String>.from(json['specialization']);
    } else if (json['specializations'] is List) { // Check older field name
      specializationList = List<String>.from(json['specializations']);
    } else if (json['specialties'] is List) { // Check another older field name
      specializationList = List<String>.from(json['specialties']);
    } else if (json['specialization'] is String) {
      // Attempt to parse comma-separated string
      final specString = json['specialization'] as String;
      if (specString.isNotEmpty) {
        specializationList = specString.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      }
    }

    return Coach(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      title: json['title'] ?? '',
      bio: json['bio'] ?? '',
      profileImageUrl: json['profileImageUrl'] ?? json['imageUrl'] ?? '',
      headerImageUrl: json['headerImageUrl'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      specialization: specializationList.isNotEmpty ? specializationList : null,
      credentials: List<String>.from(json['credentials'] ?? []),
      experience: _parseExperience(json['experience']),
      isActive: json['isActive'] ?? true,
      bookingUrl: json['bookingUrl'] ?? '',
      email: json['email'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      instagramUrl: json['instagramUrl'] as String?,
      twitterUrl: json['twitterUrl'] as String?,
      linkedinUrl: json['linkedinUrl'] as String?,
      websiteUrl: json['websiteUrl'] as String?,
      createdAt: _toDateTime(json['createdAt']) ?? DateTime.now(),
      updatedAt: _toDateTime(json['updatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'title': title,
      'bio': bio,
      'profileImageUrl': profileImageUrl,
      'headerImageUrl': headerImageUrl,
      'rating': rating,
      'reviewCount': reviewCount,
      'specialization': specialization,
      'credentials': credentials,
      'experience': experience,
      'isActive': isActive,
      'bookingUrl': bookingUrl,
      'email': email,
      'phoneNumber': phoneNumber,
      'instagramUrl': instagramUrl,
      'twitterUrl': twitterUrl,
      'linkedinUrl': linkedinUrl,
      'websiteUrl': websiteUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Coach copyWith({
    String? id,
    String? name,
    String? title,
    String? bio,
    String? profileImageUrl,
    String? headerImageUrl,
    double? rating,
    int? reviewCount,
    List<String>? specialization,
    List<String>? credentials,
    int? experience,
    bool? isActive,
    String? bookingUrl,
    String? email,
    String? phoneNumber,
    String? instagramUrl,
    String? twitterUrl,
    String? linkedinUrl,
    String? websiteUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Coach(
      id: id ?? this.id,
      name: name ?? this.name,
      title: title ?? this.title,
      bio: bio ?? this.bio,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      headerImageUrl: headerImageUrl ?? this.headerImageUrl,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      specialization: specialization ?? this.specialization,
      credentials: credentials ?? this.credentials,
      experience: experience ?? this.experience,
      isActive: isActive ?? this.isActive,
      bookingUrl: bookingUrl ?? this.bookingUrl,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      instagramUrl: instagramUrl ?? this.instagramUrl,
      twitterUrl: twitterUrl ?? this.twitterUrl,
      linkedinUrl: linkedinUrl ?? this.linkedinUrl,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static Coach empty() {
    return Coach(
      id: '',
      name: '',
      title: '',
      bio: '',
      profileImageUrl: '',
      headerImageUrl: '',
      rating: 0,
      reviewCount: 0,
      specialization: [],
      credentials: [],
      experience: 0,
      isActive: true,
      bookingUrl: '',
      email: null,
      phoneNumber: null,
      instagramUrl: null,
      twitterUrl: null,
      linkedinUrl: null,
      websiteUrl: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

class CoachModel {
  final String id;
  final String name;
  final String title;
  final String profileImageUrl;
  final bool isActive;
  
  CoachModel({
    required this.id,
    required this.name,
    required this.title,
    required this.profileImageUrl,
    required this.isActive,
  });

  factory CoachModel.fromJson(Map<String, dynamic> data) => CoachModel(
        id: data['id'] ?? '',
        name: data['name'] ?? '',
        title: data['title'] ?? '',
        profileImageUrl: data['profileImageUrl'] ?? data['imageUrl'] ?? '',
        isActive: data['isActive'] ?? true,
      );
} 