import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';

/// Enum representing different permission levels in the app
enum UserRole {
  // Standard user with basic permissions
  user,
  
  // University admin with permissions to manage their university
  universityAdmin,
  
  // Super admin with full access to all features
  appAdmin
}

/// Service to manage user roles and permissions
class UserPermissionsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  
  // Domains that should automatically receive admin privileges
  static const List<String> _adminDomains = ['hmperform.com'];
  
  /// Check if an email address should automatically receive admin privileges
  bool shouldAutoAssignAdmin(String email) {
    if (email.isEmpty) return false;
    
    final domain = email.split('@').last.toLowerCase();
    return _adminDomains.contains(domain);
  }
  
  /// Process a new user registration to check if they should be an admin
  Future<bool> processNewUserRegistration(String email, String userId) async {
    try {
      if (shouldAutoAssignAdmin(email)) {
        // Automatically make this user an admin
        await _firestore.collection('users').doc(userId).update({
          'isAdmin': true
        });
        debugPrint('Auto-assigned admin privileges to $email');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error processing new user registration: $e');
      return false;
    }
  }
  
  /// Check if the current user has any admin privileges (app admin or university admin)
  Future<bool> isCurrentUserAnyAdmin() async {
    try {
      final String? userId = _auth.currentUser?.uid;
      if (userId == null) return false;
      
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;
      
      // Check if user is an app admin
      if (userDoc.data()?['isAdmin'] == true) return true;
      
      // Check if user is a university admin
      final String? universityCode = userDoc.data()?['universityCode'];
      if (universityCode != null) {
        final universityDoc = await _firestore.collection('universities').doc(universityCode).get();
        if (universityDoc.exists) {
          final List<dynamic> adminUserIds = universityDoc.data()?['adminUserIds'] ?? [];
          return adminUserIds.contains(userId);
        }
      }
      
      return false;
    } catch (e) {
      debugPrint('Error checking admin status: $e');
      return false;
    }
  }
  
  /// Get the current user's role
  Future<UserRole> getCurrentUserRole() async {
    try {
      final String? userId = _auth.currentUser?.uid;
      if (userId == null) return UserRole.user;
      
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return UserRole.user;
      
      // Check if user is an app admin
      if (userDoc.data()?['isAdmin'] == true) return UserRole.appAdmin;
      
      // Check if user is a university admin
      final String? universityCode = userDoc.data()?['universityCode'];
      if (universityCode != null) {
        final universityDoc = await _firestore.collection('universities').doc(universityCode).get();
        if (universityDoc.exists) {
          final List<dynamic> adminUserIds = universityDoc.data()?['adminUserIds'] ?? [];
          if (adminUserIds.contains(userId)) {
            return UserRole.universityAdmin;
          }
        }
      }
      
      return UserRole.user;
    } catch (e) {
      debugPrint('Error getting user role: $e');
      return UserRole.user;
    }
  }
  
  /// Check if the current user is a full app admin
  Future<bool> isCurrentUserAppAdmin() async {
    try {
      final String? userId = _auth.currentUser?.uid;
      if (userId == null) return false;
      
      final userDoc = await _firestore.collection('users').doc(userId).get();
      return userDoc.data()?['isAdmin'] == true;
    } catch (e) {
      debugPrint('Error checking app admin status: $e');
      return false;
    }
  }
  
  /// Check if the current user is a university admin
  Future<bool> isCurrentUserUniversityAdmin() async {
    try {
      final String? userId = _auth.currentUser?.uid;
      if (userId == null) return false;
      
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final String? universityCode = userDoc.data()?['universityCode'];
      
      if (universityCode == null) return false;
      
      final universityDoc = await _firestore.collection('universities').doc(universityCode).get();
      if (!universityDoc.exists) return false;
      
      final List<dynamic> adminUserIds = universityDoc.data()?['adminUserIds'] ?? [];
      return adminUserIds.contains(userId);
    } catch (e) {
      debugPrint('Error checking university admin status: $e');
      return false;
    }
  }
  
  /// Make a user an app admin
  Future<bool> makeUserAppAdmin(String userId, {bool isAdmin = true}) async {
    try {
      // Only allow current app admins to perform this action
      if (!await isCurrentUserAppAdmin()) {
        debugPrint('Only app admins can create other admins');
        return false;
      }
      
      await _firestore.collection('users').doc(userId).update({
        'isAdmin': isAdmin
      });
      
      debugPrint('Updated admin status for user $userId to $isAdmin');
      return true;
    } catch (e) {
      debugPrint('Error updating app admin status: $e');
      return false;
    }
  }
  
  /// Make a user a university admin
  Future<bool> makeUserUniversityAdmin(String userId, String universityCode) async {
    try {
      // Verify current user is an app admin or the university admin
      final currentUserRole = await getCurrentUserRole();
      final isCurrentUserAdmin = currentUserRole == UserRole.appAdmin;
      
      final String? currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return false;
      
      bool hasPermission = isCurrentUserAdmin;
      
      // If not an app admin, check if they're already an admin for this university
      if (!hasPermission && currentUserRole == UserRole.universityAdmin) {
        final userDoc = await _firestore.collection('users').doc(currentUserId).get();
        final String? userUniversityCode = userDoc.data()?['universityCode'];
        
        // Current user must be an admin of the same university
        if (userUniversityCode == universityCode) {
          final universityDoc = await _firestore.collection('universities').doc(universityCode).get();
          final List<dynamic> adminUserIds = universityDoc.data()?['adminUserIds'] ?? [];
          hasPermission = adminUserIds.contains(currentUserId);
        }
      }
      
      if (!hasPermission) {
        debugPrint('Current user does not have permission to modify university admins');
        return false;
      }
      
      // First ensure the target user exists and is part of this university
      final targetUserDoc = await _firestore.collection('users').doc(userId).get();
      if (!targetUserDoc.exists) {
        debugPrint('Target user does not exist');
        return false;
      }
      
      final String? targetUserUniversity = targetUserDoc.data()?['universityCode'];
      if (targetUserUniversity != universityCode) {
        // Update the user's university code if it doesn't match
        await _firestore.collection('users').doc(userId).update({
          'universityCode': universityCode
        });
      }
      
      // Update the university document to include this user as an admin
      final universityRef = _firestore.collection('universities').doc(universityCode);
      
      // Get current list of admin users
      final universityDoc = await universityRef.get();
      if (!universityDoc.exists) {
        debugPrint('University does not exist');
        return false;
      }
      
      // Add user to adminUserIds if not already there
      await _firestore.runTransaction((transaction) async {
        final freshDoc = await transaction.get(universityRef);
        List<dynamic> adminUserIds = List<dynamic>.from(freshDoc.data()?['adminUserIds'] ?? []);
        
        if (!adminUserIds.contains(userId)) {
          adminUserIds.add(userId);
          transaction.update(universityRef, {'adminUserIds': adminUserIds});
        }
      });
      
      debugPrint('Added $userId as admin for university $universityCode');
      return true;
    } catch (e) {
      debugPrint('Error making user university admin: $e');
      return false;
    }
  }
  
  /// Remove a user as a university admin
  Future<bool> removeUserAsUniversityAdmin(String userId, String universityCode) async {
    try {
      // Verify current user is an app admin or the university admin
      final currentUserRole = await getCurrentUserRole();
      final isCurrentUserAdmin = currentUserRole == UserRole.appAdmin;
      
      final String? currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return false;
      
      bool hasPermission = isCurrentUserAdmin;
      
      // If not an app admin, check if they're already an admin for this university
      if (!hasPermission && currentUserRole == UserRole.universityAdmin) {
        final userDoc = await _firestore.collection('users').doc(currentUserId).get();
        final String? userUniversityCode = userDoc.data()?['universityCode'];
        
        // Current user must be an admin of the same university
        if (userUniversityCode == universityCode) {
          final universityDoc = await _firestore.collection('universities').doc(universityCode).get();
          final List<dynamic> adminUserIds = universityDoc.data()?['adminUserIds'] ?? [];
          hasPermission = adminUserIds.contains(currentUserId);
        }
      }
      
      // Cannot remove yourself as an admin
      if (userId == currentUserId) {
        debugPrint('Cannot remove yourself as an admin');
        return false;
      }
      
      if (!hasPermission) {
        debugPrint('Current user does not have permission to modify university admins');
        return false;
      }
      
      // Update the university document to remove this user as an admin
      final universityRef = _firestore.collection('universities').doc(universityCode);
      
      // Get current list of admin users
      final universityDoc = await universityRef.get();
      if (!universityDoc.exists) {
        debugPrint('University does not exist');
        return false;
      }
      
      // Remove user from adminUserIds
      await _firestore.runTransaction((transaction) async {
        final freshDoc = await transaction.get(universityRef);
        List<dynamic> adminUserIds = List<dynamic>.from(freshDoc.data()?['adminUserIds'] ?? []);
        
        if (adminUserIds.contains(userId)) {
          adminUserIds.remove(userId);
          transaction.update(universityRef, {'adminUserIds': adminUserIds});
        }
      });
      
      debugPrint('Removed $userId as admin for university $universityCode');
      return true;
    } catch (e) {
      debugPrint('Error removing user as university admin: $e');
      return false;
    }
  }
  
  /// List all app admins
  Future<List<Map<String, dynamic>>> listAppAdmins() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('isAdmin', isEqualTo: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => {
            'userId': doc.id,
            'email': doc.data()['email'] ?? '',
            'fullName': doc.data()['fullName'] ?? '',
            'profileImageUrl': doc.data()['profileImageUrl']
          })
          .toList();
    } catch (e) {
      debugPrint('Error listing app admins: $e');
      return [];
    }
  }
  
  /// List admins for a specific university
  Future<List<Map<String, dynamic>>> listUniversityAdmins(String universityCode) async {
    try {
      final universityDoc = await _firestore
          .collection('universities')
          .doc(universityCode)
          .get();
      
      if (!universityDoc.exists) return [];
      
      final List<dynamic> adminUserIds = universityDoc.data()?['adminUserIds'] ?? [];
      
      if (adminUserIds.isEmpty) return [];
      
      // Get user details for each admin
      final List<Map<String, dynamic>> adminUsers = [];
      
      for (String adminId in adminUserIds) {
        final userDoc = await _firestore.collection('users').doc(adminId).get();
        if (userDoc.exists) {
          adminUsers.add({
            'userId': userDoc.id,
            'email': userDoc.data()?['email'] ?? '',
            'fullName': userDoc.data()?['fullName'] ?? '',
            'profileImageUrl': userDoc.data()?['profileImageUrl']
          });
        }
      }
      
      return adminUsers;
    } catch (e) {
      debugPrint('Error listing university admins: $e');
      return [];
    }
  }
  
  /// Check if a specific user has permission to access a feature
  /// 
  /// - `requiredRole`: The minimum role required to access the feature
  /// - `userId`: The user ID to check (defaults to current user)
  /// - `universityCode`: For university-specific features
  Future<bool> hasPermission(
    UserRole requiredRole, {
    String? userId,
    String? universityCode
  }) async {
    try {
      final String uid = userId ?? _auth.currentUser?.uid ?? '';
      if (uid.isEmpty) return false;
      
      // Get the user's current role
      UserRole userRole;
      
      if (userId == null) {
        // If checking current user, use cached method
        userRole = await getCurrentUserRole();
      } else {
        // If checking another user, determine their role
        final userDoc = await _firestore.collection('users').doc(uid).get();
        
        // App admin check
        if (userDoc.data()?['isAdmin'] == true) {
          userRole = UserRole.appAdmin;
        } 
        // University admin check
        else {
          final String? userUniversityCode = userDoc.data()?['universityCode'];
          
          if (userUniversityCode != null) {
            final universityDoc = await _firestore
                .collection('universities')
                .doc(userUniversityCode)
                .get();
                
            if (universityDoc.exists) {
              final List<dynamic> adminUserIds = universityDoc.data()?['adminUserIds'] ?? [];
              if (adminUserIds.contains(uid)) {
                userRole = UserRole.universityAdmin;
              } else {
                userRole = UserRole.user;
              }
            } else {
              userRole = UserRole.user;
            }
          } else {
            userRole = UserRole.user;
          }
        }
      }
      
      // Check if user role meets or exceeds required role
      switch (requiredRole) {
        case UserRole.user:
          return true; // Everyone has user permissions
        
        case UserRole.universityAdmin:
          // App admins and university admins have university admin permissions
          if (userRole == UserRole.appAdmin) return true;
          
          // For university admins, check if they have permission for the specified university
          if (userRole == UserRole.universityAdmin && universityCode != null) {
            final userDoc = await _firestore.collection('users').doc(uid).get();
            final String? userUniversityCode = userDoc.data()?['universityCode'];
            
            // University admin can only manage their own university
            return userUniversityCode == universityCode;
          }
          return false;
        
        case UserRole.appAdmin:
          // Only app admins have app admin permissions
          return userRole == UserRole.appAdmin;
          
        default:
          return false;
      }
    } catch (e) {
      debugPrint('Error checking permission: $e');
      return false;
    }
  }
  
  /// Create a new university (app admin only)
  Future<String?> createUniversity({
    required String name,
    required String code,
    required String domain,
    String? logoUrl,
    List<String> initialAdminUserIds = const [],
  }) async {
    try {
      // Verify current user is an app admin
      if (!await isCurrentUserAppAdmin()) {
        debugPrint('Only app admins can create universities');
        return null;
      }
      
      // Check if university code already exists
      final existingUniversity = await _firestore.collection('universities').doc(code).get();
      if (existingUniversity.exists) {
        debugPrint('University with code $code already exists');
        return null;
      }
      
      // Create the university
      await _firestore.collection('universities').doc(code).set({
        'code': code,
        'name': name,
        'domain': domain,
        'logoUrl': logoUrl,
        'primaryColor': '#1E88E5',
        'secondaryColor': '#64B5F6',
        'adminUserIds': initialAdminUserIds,
        'activeUntil': DateTime.now().add(const Duration(days: 365)).millisecondsSinceEpoch,
        'maxUsers': 100,
        'currentUserCount': 0,
        'teams': [],
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': _auth.currentUser?.uid,
      });
      
      return code;
    } catch (e) {
      debugPrint('Error creating university: $e');
      return null;
    }
  }
  
  /// Update university logo URL
  Future<bool> updateUniversityLogo(String universityCode, String logoUrl) async {
    try {
      // Verify current user has permission (app admin or university admin)
      final currentUserRole = await getCurrentUserRole();
      
      bool hasPermission = currentUserRole == UserRole.appAdmin;
      
      if (!hasPermission && currentUserRole == UserRole.universityAdmin) {
        final String? currentUserId = _auth.currentUser?.uid;
        if (currentUserId != null) {
          final userDoc = await _firestore.collection('users').doc(currentUserId).get();
          final String? userUniversityCode = userDoc.data()?['universityCode'];
          
          if (userUniversityCode == universityCode) {
            hasPermission = true;
          }
        }
      }
      
      if (!hasPermission) {
        debugPrint('User does not have permission to update university logo');
        return false;
      }
      
      // Update the university document
      await _firestore.collection('universities').doc(universityCode).update({
        'logoUrl': logoUrl,
      });
      
      return true;
    } catch (e) {
      debugPrint('Error updating university logo: $e');
      return false;
    }
  }
} 