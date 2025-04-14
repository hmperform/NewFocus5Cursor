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
import '../../utils/level_utils.dart';

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
              
              // Calculate level and progress directly from snapshot data
              final int currentLevel = LevelUtils.calculateLevel(user.xp);
              final double currentProgress = LevelUtils.calculateXpProgress(user.xp);
              final int xpForNext = LevelUtils.getXpForLevel(currentLevel + 1);

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
                          '${user.xp} XP | Level $currentLevel',
                          style: const TextStyle(
                            color: Color(0xFFB4FF00),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    
                    // XP Progress Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 8.0),
                      child: LinearProgressIndicator(
                        value: currentProgress,
                        backgroundColor: Colors.grey[800],
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFB4FF00)),
                        minHeight: 6,
                      ),
                    ),
                    
                    // XP needed text
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${user.xp} XP',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          Text(
                            '$xpForNext XP needed for Level ${currentLevel + 1}',
                             style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Focus Points
                    _buildDetailCard(
                       context,
                       icon: Icons.diamond_outlined,
                       title: 'Focus Points',
                       value: '${user.focusPoints}',
                       subtitle: 'Use to unlock premium content',
                    ),
                    const SizedBox(height: 16),
                    
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
                    _buildBadgesGrid(user),
                    
                    const SizedBox(height: 24),
                    
                    // Focus Areas
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                             'My Focus Areas',
                             style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                           ),
                           const SizedBox(height: 12),
                           if (user.focusAreas.isEmpty)
                             const Text(
                               'No focus areas selected yet.',
                               style: TextStyle(color: Colors.white54),
                             )
                           else
                            Wrap(
                              spacing: 8.0,
                              runSpacing: 8.0,
                              children: user.focusAreas.map((area) {
                                return ActionChip(
                                  label: Text(area),
                                  onPressed: () {
                                    Navigator.push(
                                       context,
                                       MaterialPageRoute(
                                         builder: (context) => FocusAreaCoursesScreen(focusArea: area),
                                       ),
                                     );
                                  },
                                  backgroundColor: Colors.grey[800],
                                  labelStyle: const TextStyle(color: Colors.white),
                                );
                              }).toList(),
                           ),
                       ],
                     ),
                   ),
                  const SizedBox(height: 24),

                    // Other details like Streak (use user.streak)
                    _buildDetailCard(
                       context,
                       icon: Icons.local_fire_department_outlined,
                       title: 'Current Streak',
                       value: '${user.streak} days',
                       subtitle: 'Login daily to build your streak',
                    ),
                    const SizedBox(height: 16),
                     _buildDetailCard(
                       context,
                       icon: Icons.star_border_outlined,
                       title: 'Longest Streak',
                       value: '${user.longestStreak} days',
                    ),
                    const SizedBox(height: 16),
                     _buildDetailCard(
                       context,
                       icon: Icons.calendar_today_outlined,
                       title: 'Total Login Days',
                       value: '${user.totalLoginDays}',
                    ),
                    const SizedBox(height: 32),

                    // Sign out button (Uses AuthProvider)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[800],
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        onPressed: () async {
                           final authProvider = Provider.of<AuthProvider>(context, listen: false);
                           await authProvider.logout();
                           // No need for navigation here, SplashScreen listener handles it
                        },
                        child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
                     ),
                   ),
                    const SizedBox(height: 32),
                  ],
                ),
              );
            },
          ),
    );
  }
  
  Widget _buildDetailCard(BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    String? subtitle,
  }) {
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
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 4),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white54,
                  ),
                ),
              Text(
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
  
  Widget _buildBadgesGrid(User user) {
    if (user.badges.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.emoji_events_outlined, size: 48, color: Colors.white24),
              SizedBox(height: 8),
              Text(
                'No badges earned yet. Keep practicing!',
                style: TextStyle(color: Colors.white54),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    return Container(
      height: 120,
      padding: const EdgeInsets.only(left: 24.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: user.badges.length,
        itemBuilder: (context, index) {
          final badge = user.badges[index];
          return Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                _showBadgeDetails(context, badge);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ImageUtils.badgeImageWithFallback(
                    imageUrl: badge.imageUrl,
                    radius: 35,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    badge.name,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  void _showBadgeDetails(BuildContext context, AppBadge badge) {
    String formattedDate = 'Not specified';
    if (badge.earnedAt != null) {
       try {
         formattedDate = '${badge.earnedAt!.day}/${badge.earnedAt!.month}/${badge.earnedAt!.year}';
       } catch (e) {
         print("Error formatting badge earned date: $e");
       }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
             children: [
               ImageUtils.badgeImageWithFallback(imageUrl: badge.imageUrl, radius: 20),
               SizedBox(width: 10),
               Expanded(
                  child: Text(badge.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
               ),
             ],
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(badge.description, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 10),
                Text('Earned on: $formattedDate', style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Close', style: TextStyle(color: Theme.of(context).primaryColor)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
} 