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

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    
    // Get the current user ID
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
              // Refresh data after returning from edit screen
              _loadUserData();
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
        : _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFB4FF00),
              ),
            )
          : _errorMessage != null
            ? Center(
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
                      'Error loading profile data: $_errorMessage',
                      style: const TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isLoading = true;
                          _errorMessage = null;
                        });
                        _loadUserData();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB4FF00),
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : _buildUserProfile(userProvider.user!),
    );
  }
  
  Widget _buildUserProfile(User user) {
    // Calculate level and progress directly from user data
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Circle background
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF2A2A2A),
                      ),
                      child: Center(
                        child: Text(
                          '${user.focusPoints}',
                          style: const TextStyle(
                            color: Color(0xFFB4FF00),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    // Focus Points Icon on top right
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF1A1A1A),
                          border: Border.all(
                            color: const Color(0xFFB4FF00),
                            width: 1.5,
                          ),
                        ),
                        child: Image.asset(
                          'assets/icons/focuspointicon-removebg-preview.png',
                          width: 18,
                          height: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Focus Points',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Use to unlock premium content',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFB4FF00), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFB4FF00).withOpacity(0.2),
                        ),
                        child: Center(
                          child: AppIcons.getFocusPointIcon(
                            width: 16, 
                            height: 16,
                            color: const Color(0xFFB4FF00),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${user.focusPoints}',
                        style: const TextStyle(
                          color: Color(0xFFB4FF00),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB4FF00).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/icons/focuspointicon-removebg-preview.png',
                        width: 16,
                        height: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Get More',
                        style: const TextStyle(
                          color: Color(0xFFB4FF00),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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

          // Streak widget - replace the three detail cards for streak
          _buildStreakWidget(user),
          const SizedBox(height: 24),
          
          // Add a divider between sections
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Divider(
              color: Colors.grey[800],
              thickness: 1,
            ),
          ),
          const SizedBox(height: 24),
          
          // Add the new stats section
          _buildStatsSection(user),
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
  }
  
  Widget _buildDetailCard(BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    String? subtitle,
  }) {
    final accentColor = const Color(0xFFB4FF00);
    
    // Special case for focus points icon
    if (icon == Icons.diamond_outlined) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: AppIcons.getFocusPointIcon(
                width: 20,
                height: 20,
                color: accentColor,
              ),
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
        ),
      );
    }
    
    // Regular icons
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: accentColor, size: 20),
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
      ),
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
    
    // Sort badges by earned date, most recent first
    final sortedBadges = List<AppBadge>.from(user.badges)
      ..sort((a, b) => (b.earnedAt ?? DateTime(0)).compareTo(a.earnedAt ?? DateTime(0)));
    
    // Take only the first 10 badges
    final displayBadges = sortedBadges.take(10).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (sortedBadges.length > 10)
          Padding(
            padding: const EdgeInsets.only(left: 24.0, bottom: 8.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AllBadgesScreen()),
                );
              },
              child: Text(
                'Showing ${displayBadges.length} of ${sortedBadges.length} badges',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        Container(
          height: 120,
          padding: const EdgeInsets.only(left: 24.0),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: displayBadges.length,
            itemBuilder: (context, index) {
              final badge = displayBadges[index];
              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: GestureDetector(
                  onTap: () {
                    _showBadgeDetails(context, badge);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildBadgeImage(badge: badge, radius: 35),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 70,
                        child: Text(
                          badge.name,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildBadgeImage({required AppBadge? badge, required double radius}) {
    // Only use badgeImage (the Firebase URL) instead of local assets
    final String? imageUrl = badge?.badgeImage;
    
    print('Badge image URL for ${badge?.name}: $imageUrl');
    
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[800],
        border: Border.all(
          color: Colors.white24,
          width: 2
        ),
      ),
      child: ClipOval(
        child: (imageUrl != null && imageUrl.isNotEmpty)
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / 
                            loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  print('Error loading badge network image: $error for URL: $imageUrl');
                  return Icon(
                    Icons.emoji_events,
                    color: Colors.white54,
                    size: radius,
                  );
                },
              )
            : Icon(
                Icons.emoji_events,
                color: Colors.white54,
                size: radius,
              ),
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
               _buildBadgeImage(badge: badge, radius: 20),
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

  Widget _buildStreakWidget(User user) {
    return DailyStreakWidget();
  }
  
  // New method to build a visually appealing stats section
  Widget _buildStatsSection(User user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 16.0),
            child: Text(
              'My Stats',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatCard(
                icon: Icons.headphones,
                value: '${user.completedAudios.length}',
                label: 'Audios',
                gradientColors: [Colors.purple, Colors.deepPurple],
              ),
              _buildStatCard(
                icon: Icons.menu_book,
                value: '${user.completedCourses.length}',
                label: 'Courses',
                gradientColors: [Colors.blue, Colors.lightBlue],
              ),
              _buildStatCard(
                icon: Icons.emoji_events,
                value: '${user.badges.length}',
                label: 'Badges',
                gradientColors: [Colors.amber, Colors.orange],
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatCard({
    required IconData icon, 
    required String value, 
    required String label, 
    required List<Color> gradientColors
  }) {
    return Container(
      width: 100,
      height: 110,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            gradientColors[0].withOpacity(0.2),
            gradientColors[1].withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: gradientColors[0].withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: gradientColors[0].withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
} 