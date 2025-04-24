import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/content_models.dart';

class BadgeProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<AppBadge> _allBadges = [];
  List<AppBadge> _earnedBadges = [];
  
  bool _isLoading = false;
  String? _errorMessage;
  
  // Getters
  List<AppBadge> get allBadges => _allBadges;
  List<AppBadge> get earnedBadges => _earnedBadges;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  Future<void> loadBadges() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      
      // Get current user ID
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      // Load all available badges
      final QuerySnapshot badgesSnapshot = await _firestore.collection('badges').get();
      
      debugPrint('Found ${badgesSnapshot.docs.length} badges in Firestore');
      
      _allBadges = badgesSnapshot.docs.map((doc) => AppBadge.fromFirestore(doc)).toList();
      
      debugPrint('Loaded ${_allBadges.length} badges total');
      
      // Load earned badges for the current user
      final DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      
      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data() as Map<String, dynamic>;
        
        // Check for badgesgranted array with badge references
        final badgesGranted = userData['badgesgranted'] as List<dynamic>? ?? [];
        
        if (badgesGranted.isNotEmpty) {
          // Extract badge IDs from badgesgranted references
          final earnedBadgeIds = badgesGranted
              .map((badgeRef) => badgeRef is Map<String, dynamic> ? badgeRef['id'] : null)
              .where((id) => id != null)
              .toList();
          
          _earnedBadges = _allBadges.where((badge) => 
            earnedBadgeIds.contains(badge.id)).toList();
            
          debugPrint('Loaded ${_earnedBadges.length} earned badges from badgesgranted');
        } else {
          // Fallback to legacy badges array if exists
          final legacyBadgeIds = userData['badges'] as List<dynamic>? ?? [];
          
          if (legacyBadgeIds.isNotEmpty) {
            _earnedBadges = _allBadges.where((badge) => 
              legacyBadgeIds.contains(badge.id)).toList();
              
            debugPrint('Loaded ${_earnedBadges.length} earned badges from legacy badges array');
          } else {
            _earnedBadges = [];
            debugPrint('No earned badges found for user');
          }
        }
      } else {
        _earnedBadges = [];
        debugPrint('User document does not exist or has no data');
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading badges: $e');
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
  
  // For testing purposes, add some dummy badges if none exist in Firestore
  Future<void> addDummyBadgesIfNeeded() async {
    try {
      final QuerySnapshot badgesSnapshot = await _firestore.collection('badges').get();
      
      if (badgesSnapshot.docs.isEmpty) {
        await _addDummyBadges();
      }
    } catch (e) {
      debugPrint('Error checking for dummy badges: $e');
    }
  }
  
  Future<void> _addDummyBadges() async {
    final List<Map<String, dynamic>> dummyBadges = [
      {
        'name': 'First Session',
        'description': 'Complete your first Focus 5 session',
        'criteriaType': 'achievement',
        'requiredCount': 1,
        'xpValue': 50,
      },
      {
        'name': 'Consistent Performer',
        'description': 'Complete 5 consecutive days of training',
        'criteriaType': 'streak',
        'requiredCount': 5,
        'xpValue': 100,
      },
      {
        'name': 'Mental Fitness Explorer',
        'description': 'Try all 5 types of mental training exercises',
        'criteriaType': 'completion',
        'requiredCount': 5,
        'xpValue': 150,
      },
      {
        'name': 'Focused Mind',
        'description': 'Complete 10 meditation sessions',
        'criteriaType': 'performance',
        'requiredCount': 10,
        'xpValue': 200,
      },
      {
        'name': 'Community Member',
        'description': 'Book your first coaching session',
        'criteriaType': 'social',
        'requiredCount': 1,
        'xpValue': 100,
      },
      {
        'name': '30-Day Commitment',
        'description': 'Use Focus 5 every day for a month',
        'criteriaType': 'milestone',
        'requiredCount': 30,
        'xpValue': 300,
      },
    ];
    
    final batch = _firestore.batch();
    
    for (final badge in dummyBadges) {
      final docRef = _firestore.collection('badges').doc();
      batch.set(docRef, badge);
    }
    
    await batch.commit();
    debugPrint('Added dummy badges to Firestore');
  }
  
  // Mark a badge as earned for the current user
  Future<void> awardBadge(String badgeId) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      // Add the badge to the user's earned badges
      await _firestore.collection('users').doc(currentUser.uid).update({
        'badgesgranted': FieldValue.arrayUnion([
          {'id': badgeId, 'earnedAt': FieldValue.serverTimestamp()}
        ])
      });
      
      // Refresh the badges list
      await loadBadges();
    } catch (e) {
      debugPrint('Error awarding badge: $e');
      rethrow;
    }
  }
} 