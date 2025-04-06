import 'package:cloud_firestore/cloud_firestore.dart';

class CoachModel {
  final String id;
  final String name;
  final String title;
  final String bio;
  final String profileImageUrl;
  final String headerImageUrl;
  final String bookingUrl;
  final String? email;
  final String? phoneNumber;
  final String? instagramUrl;
  final String? twitterUrl;
  final String? linkedinUrl;
  final String? websiteUrl;
  final List<String> specialties;
  final List<String> credentials;
  final bool isVerified;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Add missing properties
  final String? education;
  final String? certifications;
  final String? experience;
  final String? approach;

  CoachModel({
    required this.id,
    required this.name,
    required this.title,
    required this.bio,
    required this.profileImageUrl,
    required this.headerImageUrl,
    required this.bookingUrl,
    this.email,
    this.phoneNumber,
    this.instagramUrl,
    this.twitterUrl,
    this.linkedinUrl,
    this.websiteUrl,
    required this.specialties,
    required this.credentials,
    required this.isVerified,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.education,
    this.certifications,
    this.experience,
    this.approach,
  });

  factory CoachModel.fromJson(Map<String, dynamic> json) {
    return CoachModel(
      id: json['id'],
      name: json['name'],
      title: json['title'],
      bio: json['bio'],
      profileImageUrl: json['profileImageUrl'],
      headerImageUrl: json['headerImageUrl'],
      bookingUrl: json['bookingUrl'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      instagramUrl: json['instagramUrl'],
      twitterUrl: json['twitterUrl'],
      linkedinUrl: json['linkedinUrl'],
      websiteUrl: json['websiteUrl'],
      specialties: List<String>.from(json['specialties'] ?? []),
      credentials: List<String>.from(json['credentials'] ?? []),
      isVerified: json['isVerified'] ?? false,
      isActive: json['isActive'] ?? true,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
      education: json['education'],
      certifications: json['certifications'],
      experience: json['experience'],
      approach: json['approach'],
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
      'bookingUrl': bookingUrl,
      'email': email,
      'phoneNumber': phoneNumber,
      'instagramUrl': instagramUrl,
      'twitterUrl': twitterUrl,
      'linkedinUrl': linkedinUrl,
      'websiteUrl': websiteUrl,
      'specialties': specialties,
      'credentials': credentials,
      'isVerified': isVerified,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'education': education,
      'certifications': certifications,
      'experience': experience,
      'approach': approach,
    };
  }
} 