import 'package:cloud_firestore/cloud_firestore.dart';

enum BadgeCriteriaType {
  streak,
  completion,
  performance,
  achievement,
  social,
  milestone,
  coursesCompleted,
  audioModulesCompleted,
  courseLessonsCompleted,
  journalEntriesWritten,
  totalDaysInApp,
  other
}

class BadgeModel {
  final String id;
  final String name;
  final String description;
  final BadgeCriteriaType criteriaType;
  final int requiredCount;
  final int xpValue;
  final String? imageUrl;
  final DateTime? earnedDate;
  final List<String>? specificIds;
  final List<Map<String, dynamic>>? specificCourses;
  final bool? mustCompleteAllCourses;

  BadgeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.criteriaType,
    required this.requiredCount,
    required this.xpValue,
    this.imageUrl,
    this.earnedDate,
    this.specificIds,
    this.specificCourses,
    this.mustCompleteAllCourses,
  });

  factory BadgeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BadgeModel(
      id: doc.id,
      name: data['name'] ?? 'Unknown Badge',
      description: data['description'] ?? 'No description available',
      criteriaType: _getCriteriaTypeFromString(data['criteriaType'] ?? 'other'),
      requiredCount: data['requiredCount'] ?? 1,
      xpValue: data['xpValue'] ?? 50,
      imageUrl: data['imageUrl'],
      earnedDate: data['earnedDate'] != null 
          ? (data['earnedDate'] as Timestamp).toDate() 
          : null,
      specificIds: data['specificIds'] as List<String>?,
      specificCourses: data['specificCourses'] as List<Map<String, dynamic>>?,
      mustCompleteAllCourses: data['mustCompleteAllCourses'] as bool?,
    );
  }

  factory BadgeModel.fromMap(Map<String, dynamic> map, String id) {
    return BadgeModel(
      id: id,
      name: map['name'] ?? 'Unknown Badge',
      description: map['description'] ?? 'No description available',
      criteriaType: _getCriteriaTypeFromString(map['criteriaType'] ?? 'other'),
      requiredCount: map['requiredCount'] ?? 1,
      xpValue: map['xpValue'] ?? 50,
      imageUrl: map['imageUrl'],
      earnedDate: map['earnedDate'] != null 
          ? (map['earnedDate'] as Timestamp).toDate() 
          : null,
      specificIds: map['specificIds'] as List<String>?,
      specificCourses: map['specificCourses'] as List<Map<String, dynamic>>?,
      mustCompleteAllCourses: map['mustCompleteAllCourses'] as bool?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'criteriaType': _getCriteriaTypeAsString(criteriaType),
      'requiredCount': requiredCount,
      'xpValue': xpValue,
      'imageUrl': imageUrl,
      'earnedDate': earnedDate,
      'specificIds': specificIds,
      'specificCourses': specificCourses,
      'mustCompleteAllCourses': mustCompleteAllCourses,
    };
  }

  static BadgeCriteriaType _getCriteriaTypeFromString(String type) {
    switch (type.toLowerCase()) {
      case 'streak':
        return BadgeCriteriaType.streak;
      case 'completion':
        return BadgeCriteriaType.completion;
      case 'performance':
        return BadgeCriteriaType.performance;
      case 'achievement':
        return BadgeCriteriaType.achievement;
      case 'social':
        return BadgeCriteriaType.social;
      case 'milestone':
        return BadgeCriteriaType.milestone;
      case 'coursescompleted':
      case 'coursesCompleted':
        return BadgeCriteriaType.coursesCompleted;
      case 'audiomodulescompleted':
      case 'audioModulesCompleted':
        return BadgeCriteriaType.audioModulesCompleted;
      case 'courselessonscompleted':
      case 'courseLessonsCompleted':
        return BadgeCriteriaType.courseLessonsCompleted;
      case 'journalentrieswritten':
      case 'journalEntriesWritten':
        return BadgeCriteriaType.journalEntriesWritten;
      case 'totaldaysinapp':
      case 'totalDaysInApp':
        return BadgeCriteriaType.totalDaysInApp;
      default:
        return BadgeCriteriaType.other;
    }
  }

  static String _getCriteriaTypeAsString(BadgeCriteriaType type) {
    switch (type) {
      case BadgeCriteriaType.streak:
        return 'streak';
      case BadgeCriteriaType.completion:
        return 'completion';
      case BadgeCriteriaType.performance:
        return 'performance';
      case BadgeCriteriaType.achievement:
        return 'achievement';
      case BadgeCriteriaType.social:
        return 'social';
      case BadgeCriteriaType.milestone:
        return 'milestone';
      case BadgeCriteriaType.coursesCompleted:
        return 'CoursesCompleted';
      case BadgeCriteriaType.audioModulesCompleted:
        return 'AudioModulesCompleted';
      case BadgeCriteriaType.courseLessonsCompleted:
        return 'CourseLessonsCompleted';
      case BadgeCriteriaType.journalEntriesWritten:
        return 'JournalEntriesWritten';
      case BadgeCriteriaType.totalDaysInApp:
        return 'TotalDaysInApp';
      case BadgeCriteriaType.other:
        return 'other';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BadgeModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
} 