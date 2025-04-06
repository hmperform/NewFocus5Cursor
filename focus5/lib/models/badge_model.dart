import 'package:cloud_firestore/cloud_firestore.dart';

enum BadgeCriteriaType {
  streak,
  completion,
  performance,
  achievement,
  social,
  milestone,
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

  BadgeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.criteriaType,
    required this.requiredCount,
    required this.xpValue,
    this.imageUrl,
    this.earnedDate,
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