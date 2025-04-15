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
import '../../widgets/streak_widget.dart';

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
                  _buildBadgeImage(
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
  
  Widget _buildBadgeImage({required String? imageUrl, required double radius}) {
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
        child: imageUrl != null && imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
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
               _buildBadgeImage(imageUrl: badge.imageUrl, radius: 20),
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
    // Generate week data - this is a placeholder; in a real app, you'd have actual data
    // For now, we'll simulate based on the current streak
    List<bool> weekData = List.generate(7, (index) {
      if (index < user.streak) {
        return true; // Active for days in the streak
      } else {
        return false; // Inactive for other days
      }
    });
    
    return StreakWidget(
      weekData: weekData,
      currentStreak: user.streak,
      bestStreak: user.longestStreak,
    );
  }
} 