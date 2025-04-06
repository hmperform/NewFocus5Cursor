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
      headerImageUrl: json['headerImageUrl'] ?? json['profileImageUrl'],
      bookingUrl: json['bookingUrl'] ?? '',
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
      createdAt: json['createdAt'] is DateTime 
          ? json['createdAt'] 
          : (json['createdAt'] is Timestamp 
              ? (json['createdAt'] as Timestamp).toDate() 
              : DateTime.now()),
      updatedAt: json['updatedAt'] is DateTime 
          ? json['updatedAt'] 
          : (json['updatedAt'] is Timestamp 
              ? (json['updatedAt'] as Timestamp).toDate() 
              : DateTime.now()),
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
  
  CoachModel copyWith({
    String? id,
    String? name,
    String? title, 
    String? bio,
    String? profileImageUrl,
    String? headerImageUrl,
    String? bookingUrl,
    String? email,
    String? phoneNumber,
    String? instagramUrl,
    String? twitterUrl,
    String? linkedinUrl,
    String? websiteUrl,
    List<String>? specialties,
    List<String>? credentials,
    bool? isVerified,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? education,
    String? certifications,
    String? experience,
    String? approach,
  }) {
    return CoachModel(
      id: id ?? this.id,
      name: name ?? this.name,
      title: title ?? this.title,
      bio: bio ?? this.bio,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      headerImageUrl: headerImageUrl ?? this.headerImageUrl,
      bookingUrl: bookingUrl ?? this.bookingUrl,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      instagramUrl: instagramUrl ?? this.instagramUrl,
      twitterUrl: twitterUrl ?? this.twitterUrl,
      linkedinUrl: linkedinUrl ?? this.linkedinUrl,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      specialties: specialties ?? this.specialties,
      credentials: credentials ?? this.credentials,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      education: education ?? this.education,
      certifications: certifications ?? this.certifications,
      experience: experience ?? this.experience,
      approach: approach ?? this.approach,
    );
  }
} 