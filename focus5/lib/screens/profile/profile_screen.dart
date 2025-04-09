import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../models/badge_model.dart';
import 'edit_profile_screen.dart';
import '../../utils/image_utils.dart';
import '../explore/focus_area_courses_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    
    // Get the current user ID for the stream
    final String? userId = authProvider.currentUser?.id;
    
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        title: const Text(
          'My Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: userId == null
        ? const Center(
            child: Text(
              'Please log in to view your profile',
              style: TextStyle(color: Colors.white),
            ),
          )
        : StreamBuilder<User?>(
            stream: userProvider.getUserStream(userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFB4FF00),
                  ),
                );
              }
              
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading profile data: ${snapshot.error}',
                        style: const TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {});
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB4FF00),
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }
              
              final user = snapshot.data;
              if (user == null) {
                return const Center(
                  child: Text(
                    'User data not available',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }
              
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    
                    // Profile Picture
                    Center(
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white24,
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: ImageUtils.avatarWithFallback(
                            imageUrl: user.profileImageUrl,
                            radius: 60,
                            name: user.fullName,
                            backgroundColor: Colors.grey[800],
                            textColor: Colors.white70,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // User Name
                    Text(
                      user.fullName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Username
                    Text(
                      '@${user.username ?? user.fullName.split(' ')[0].toLowerCase()}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    
                    // XP and Level info
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.star,
                          color: Color(0xFFB4FF00),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${user.xp} XP | Level ${userProvider.level}',
                          style: const TextStyle(
                            color: Color(0xFFB4FF00),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Badges Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'My Badges',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                '${user.badges.length} earned',
                                style: const TextStyle(
                                  color: Colors.white60,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Tap on a badge to see how it was earned',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white38,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Badge Grid or empty state
                    _buildBadgesGrid(user, userProvider),
                    
                    const SizedBox(height: 24),
                    
                    // Details Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Profile Details',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (user.sport != null && user.sport!.isNotEmpty)
                              _buildDetailRow('Sport', user.sport!, Icons.sports),
                            if (user.sport != null && user.sport!.isNotEmpty)
                              const Divider(color: Colors.white12, height: 32),
                            
                            if (user.university != null && user.university!.isNotEmpty)
                              _buildDetailRow('University', user.university!, Icons.school),
                            if (user.university != null && user.university!.isNotEmpty)
                              const Divider(color: Colors.white12, height: 32),
                            
                            _buildDetailRow(
                              'Focus Areas', 
                              user.focusAreas.isEmpty 
                                  ? 'None selected' 
                                  : user.focusAreas.join(', '), 
                              Icons.psychology
                            ),
                            
                            const Divider(color: Colors.white12, height: 32),
                            
                            _buildDetailRow(
                              'Current Streak',
                              '${user.streak} days',
                              Icons.local_fire_department
                            ),
                            
                            if (user.longestStreak > 0) ...[
                              const Divider(color: Colors.white12, height: 32),
                              _buildDetailRow(
                                'Best Streak',
                                '${user.longestStreak} days',
                                Icons.emoji_events
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    
                    // Admin section (only visible for admins)
                    if (user.isAdmin) ...[
                      const SizedBox(height: 24),
                      
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.amber,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.admin_panel_settings,
                                    color: Colors.amber,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Admin Controls',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Use these controls with caution. Changes are immediate.',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Award Audio Ace badge button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.headphones),
                                  label: const Text('Award Audio Ace Badge'),
                                  onPressed: () async {
                                    final result = await userProvider.awardBadgeToCurrentUser('audio_complete_10');
                                    
                                    if (result && mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Audio Ace badge awarded!'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    } else if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Failed to award badge or badge already earned'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber,
                                    foregroundColor: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 32),
                    
                    // Fix Badges Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.badge_outlined),
                          label: const Text('Fix Badges'),
                          onPressed: () async {
                            // Show confirmation dialog
                            bool confirm = await showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Fix Badges'),
                                content: const Text(
                                  'This will update your badges to ensure they are properly displayed. Continue?'
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Continue'),
                                  ),
                                ],
                              ),
                            ) ?? false;
                            
                            if (confirm) {
                              try {
                                // Show loading indicator
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Fixing badges...'))
                                );
                                
                                // Run the migration for this user only
                                final firestore = FirebaseFirestore.instance;
                                final userData = await firestore.collection('users').doc(userId).get();
                                
                                if (userData.exists) {
                                  final data = userData.data();
                                  if (data != null && data['badges'] != null && data['badges'] is Map) {
                                    // If badges is a reference object with id and path
                                    final badgeRef = data['badges'] as Map<String, dynamic>;
                                    if (badgeRef.containsKey('id') && badgeRef.containsKey('path')) {
                                      // Convert to array with a single badge
                                      await firestore.collection('users').doc(userId).update({
                                        'badges': [{
                                          'id': badgeRef['id'],
                                          'name': 'Badge',
                                          'description': 'A badge from reference',
                                          'imageUrl': '',
                                          'earnedAt': FieldValue.serverTimestamp(),
                                          'xpValue': 0,
                                        }]
                                      });
                                      
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Badges fixed successfully! Refresh to see changes.'))
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Your badges are already in the correct format.'))
                                      );
                                    }
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Your badges are already in the correct format.'))
                                    );
                                  }
                                }
                              } catch (e) {
                                // Show error message
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error fixing badges: $e'))
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2A2A2A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }
  
  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFFB4FF00), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 4),
              label == 'Focus Areas' && value != 'None selected'
                  ? _buildFocusAreasChips(value.split(', '))
                  : Text(
                      value,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildFocusAreasChips(List<String> focusAreas) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: focusAreas.map((area) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FocusAreaCoursesScreen(focusArea: area),
              ),
            );
          },
          child: Chip(
            backgroundColor: const Color(0xFF303030),
            side: const BorderSide(color: Color(0xFFB4FF00), width: 1),
            label: Text(
              area,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildNoBadgesMessage() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white10,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.emoji_events_outlined,
            color: Colors.white30,
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            'No Badges Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Complete courses, maintain streaks, and participate in activities to earn badges.',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).pushNamed('/home');
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFB4FF00),
              side: const BorderSide(color: Color(0xFFB4FF00)),
            ),
            child: const Text('Explore Content'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBadgesGrid(User user, UserProvider userProvider) {
    return FutureBuilder<List<AppBadge>>(
      future: userProvider.getAllAvailableBadges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFB4FF00),
            ),
          );
        }
        
        if (snapshot.hasError) {
          debugPrint('Error loading badges: ${snapshot.error}');
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading badges: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        
        final allBadges = snapshot.data ?? [];
        
        if (allBadges.isEmpty) {
          return _buildNoBadgesMessage();
        }
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.8,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: allBadges.length,
            itemBuilder: (context, index) {
              final badge = allBadges[index];
              final isEarned = user.badges.any((earned) => earned.id == badge.id);
              return _buildBadge(context, badge, isEarned);
            },
          ),
        );
      },
    );
  }
  
  Widget _buildBadge(BuildContext context, AppBadge badge, bool isEarned) {
    return GestureDetector(
      onTap: () => _showBadgeDetails(context, badge, isEarned),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isEarned ? [
            BoxShadow(
              color: const Color(0xFFB4FF00).withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
          border: Border.all(
            color: isEarned ? const Color(0xFFB4FF00) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isEarned ? const Color(0xFFB4FF00) : Colors.white24,
                  width: 1,
                ),
              ),
              child: isEarned
                ? Icon(
                    _getBadgeIcon(badge.id),
                    color: const Color(0xFFB4FF00),
                    size: 32,
                  )
                : ColorFiltered(
                    colorFilter: const ColorFilter.matrix([
                      0.2, 0.2, 0.2, 0, 0,
                      0.2, 0.2, 0.2, 0, 0,
                      0.2, 0.2, 0.2, 0, 0,
                      0, 0, 0, 0.5, 0,
                    ]),
                    child: Icon(
                      _getBadgeIcon(badge.id),
                      color: Colors.white38,
                      size: 32,
                    ),
                  ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                badge.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isEarned ? FontWeight.bold : FontWeight.normal,
                  color: isEarned ? Colors.white : Colors.white60,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
              child: Text(
                isEarned ? '+${badge.xpValue} XP' : 'Tap to see how to unlock',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: isEarned ? const Color(0xFFB4FF00) : Colors.white38,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showBadgeDetails(BuildContext context, AppBadge badge, bool isEarned) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Badge icon
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    shape: BoxShape.circle,
                    boxShadow: isEarned ? [
                      BoxShadow(
                        color: const Color(0xFFB4FF00).withOpacity(0.2),
                        blurRadius: 12,
                        spreadRadius: 4,
                      ),
                    ] : null,
                    border: Border.all(
                      color: isEarned ? const Color(0xFFB4FF00) : Colors.white24,
                      width: 2,
                    ),
                  ),
                  child: isEarned 
                    ? Icon(
                        _getBadgeIcon(badge.id),
                        color: const Color(0xFFB4FF00),
                        size: 48,
                      )
                    : ColorFiltered(
                        colorFilter: const ColorFilter.matrix([
                          0.2, 0.2, 0.2, 0, 0,
                          0.2, 0.2, 0.2, 0, 0,
                          0.2, 0.2, 0.2, 0, 0,
                          0, 0, 0, 0.5, 0,
                        ]),
                        child: Icon(
                          _getBadgeIcon(badge.id),
                          color: Colors.white38,
                          size: 48,
                        ),
                      ),
                ),
                
                const SizedBox(height: 16),
                
                // Badge name
                Text(
                  badge.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
                // Badge description
                Text(
                  badge.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                // Earned status
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isEarned
                        ? const Color(0xFF2A2A2A)
                        : Colors.grey[800],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isEarned
                          ? const Color(0xFFB4FF00)
                          : Colors.white24,
                    ),
                  ),
                  child: Text(
                    isEarned
                        ? 'Earned on ${_formatEarnedDate(badge.earnedAt)}'
                        : 'Not earned yet',
                    style: TextStyle(
                      fontSize: 14,
                      color: isEarned ? const Color(0xFFB4FF00) : Colors.white70,
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Requirements section if not earned
                if (!isEarned)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: const Color(0xFFB4FF00),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'How to earn this badge:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _getEarningRequirements(badge),
                          style: const TextStyle(
                            color: Colors.white70,
                            height: 1.4,
                          ),
                        ),
                        if (badge.xpValue > 0) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.stars,
                                color: Colors.amber,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Earn +${badge.xpValue} XP when unlocked',
                                style: const TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                
                const SizedBox(height: 24),
                
                // Close button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB4FF00),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  String _formatEarnedDate(DateTime? earnedAt) {
    if (earnedAt == null) return 'Unknown date';
    return '${earnedAt.day}/${earnedAt.month}/${earnedAt.year}';
  }
  
  String _getEarningRequirements(AppBadge badge) {
    // Example implementation - replace with actual badge criteria
    switch (badge.id) {
      case 'streak_7_days':
        return 'Use the app for 7 consecutive days to establish a weekly routine.';
      case 'first_course':
        return 'Complete your first course to start your mental performance journey.';
      case 'five_courses':
        return 'Complete 5 courses to build a solid foundation in mental performance.';
      case 'meditation_master':
        return 'Complete 10 meditation sessions to strengthen your mindfulness skills.';
      case 'login_streak_30':
        return 'Maintain a 30-day login streak to demonstrate your commitment to mental training.';
      case 'audio_complete_10':
        return 'Listen to 10 audio sessions to improve your focus and relaxation techniques.';
      case 'xp_milestone_1000':
        return 'Earn 1000 XP by completing various activities in the app.';
      default:
        return 'Complete activities and challenges throughout the app to unlock this achievement badge.';
    }
  }
  
  IconData _getBadgeIcon(String badgeId) {
    // Map badge IDs to appropriate icons based on criteria type
    if (badgeId.contains('streak') || badgeId.contains('streak_')) {
      return Icons.local_fire_department;
    } else if (badgeId.contains('course') || badgeId.contains('course_')) {
      return Icons.school;
    } else if (badgeId.contains('login') || badgeId.contains('login_')) {
      return Icons.login;
    } else if (badgeId.contains('profile') || badgeId.contains('profile_')) {
      return Icons.person;
    } else if (badgeId.contains('audio') || badgeId.contains('audio_') || badgeId.contains('audio_complete_')) {
      return Icons.headphones;
    } else if (badgeId.contains('journal') || badgeId.contains('journal_')) {
      return Icons.book;
    } else if (badgeId.contains('share') || badgeId.contains('share_')) {
      return Icons.share;
    } else if (badgeId.contains('xp_milestone_')) {
      return Icons.star;
    } else {
      return Icons.emoji_events;
    }
  }
} 