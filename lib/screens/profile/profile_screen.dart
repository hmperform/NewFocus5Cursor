import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart' show User;
import '../../models/badge_model.dart';
import 'edit_profile_screen.dart';
import '../../utils/image_utils.dart';
import '../explore/focus_area_courses_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/level_utils.dart';
import '../../providers/theme_provider.dart';
import '../../utils/app_icons.dart';
import '../../widgets/daily_streak_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/content_models.dart';
import '../badges/all_badges_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  User? _userData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id;
      
      if (userId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'User not logged in';
        });
        return;
      }
      
      // Fetch user data
      await userProvider.loadUserData(userId);
      
      setState(() {
        _userData = userProvider.user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading user data: $e';
      });
    }
  }

  Widget _buildUserProfile(User user) {
    // ... existing code ...
  }

  Widget _buildBadgesGrid(User user) {
    // ... existing code ...
  }

  Widget _buildStreakWidget(User user) {
    // ... existing code ...
  }

  Widget _buildStatsSection(User user) {
    // ... existing code ...
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }

    if (_userData == null) {
      return const Center(child: Text('No user data available'));
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildUserProfile(_userData!),
            _buildStreakWidget(_userData!),
            _buildStatsSection(_userData!),
            _buildBadgesGrid(_userData!),
          ],
        ),
      ),
    );
  }
} 