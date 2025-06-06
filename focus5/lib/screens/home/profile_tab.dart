import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/user_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/user_model.dart';
import '../../models/content_models.dart';
import '../../constants/theme.dart';
import '../../utils/image_utils.dart';
import '../../services/user_level_service.dart';
import 'all_badges_screen.dart';
import 'edit_profile_screen.dart';
import '../../utils/app_icons.dart';
import '../profile/profile_screen.dart';
import '../../providers/auth_provider.dart';
import '../badges/badge_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({Key? key}) : super(key: key);

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final List<Map<String, dynamic>> _dummyCoaches = [
    {
      'name': 'Dr. Sarah Johnson',
      'specialty': 'Performance Psychology',
      'imageUrl': 'https://picsum.photos/200/200?random=1',
      'calendlyUrl': 'https://calendly.com',
    },
    {
      'name': 'Mike Peterson',
      'specialty': 'Mental Conditioning',
      'imageUrl': 'https://picsum.photos/200/200?random=2',
      'calendlyUrl': 'https://calendly.com',
    },
  ];

  // This dummy data will be replaced by the real user data from Firebase
  // The dummy data matches our updated User model for testing purposes
  final User _dummyUser = User(
    id: 'user123',
    email: 'bessiecooper@example.com',
    fullName: 'Bessie Cooper',
    profileImageUrl: 'https://picsum.photos/200/200?random=3',
    xp: 300,
    focusPoints: 75,
    streak: 5,
    longestStreak: 7,
    focusAreas: ['Confidence', 'Pressure Situations', 'Game Day Preparation'],
    badges: [], // Badges should come from Firebase only
    completedCourses: ['course1'],
    completedAudios: ['audio1', 'audio2', 'audio3'],
    lastActive: DateTime.now(),
    createdAt: DateTime.now().subtract(const Duration(days: 30)),
    lastCompletionDate: DateTime.now(),
  );

  Future<void> _launchCalendly(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch booking URL')),
      );
    }
  }
  
  void _navigateToEditProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const EditProfileScreen(),
      ),
    );
  }
  
  void _navigateToAllBadges() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AllBadgesScreen(),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    
    // Force refresh user data to load badges from Firebase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.user != null) {
        print('ProfileTab [initState]: Refreshing user data to load badges from Firebase');
        userProvider.refreshUser();
        
        // If user has badges in badgesgranted but none loaded yet, force a second refresh
        // after a short delay to ensure they load properly
        if (userProvider.user!.badgesgranted.isNotEmpty && 
            userProvider.user!.badges.isEmpty) {
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted && userProvider.user != null) {
              print('ProfileTab [initState]: Badge data still missing, initiating second attempt');
              userProvider.refreshUser();
            }
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    
    // Handle loading and error states
    if (userProvider.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (userProvider.user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Error loading profile"),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  userProvider.refreshUser();
                },
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }
    
    final user = userProvider.user!;
    
    // Debug output for badges
    print('Profile tab - User has ${user.badges.length} badges and ${user.badgesgranted.length} badgesgranted');
    for (var badge in user.badges) {
      print('Badge: ${badge.name}, id: ${badge.id}, imageUrl: ${badge.imageUrl}, badgeImage: ${badge.badgeImage}');
    }
    for (var badgeRef in user.badgesgranted) {
      print('BadgeRef: id: ${badgeRef['id']}, path: ${badgeRef['path']}');
    }
    
    // Get level info
    final int userLevel = userProvider.level;
    final int xpForNextLevel = userProvider.xpForNextLevel;
    final double levelProgress = userProvider.levelProgress;
    
    // Use theme-aware colors
    final accentColor = themeProvider.isDarkMode 
        ? AppColors.accentDark 
        : AppColors.accentLight;
    final textColor = Theme.of(context).colorScheme.onBackground;
    final secondaryTextColor = themeProvider.isDarkMode 
        ? Colors.grey[400] 
        : Colors.grey[700];  // Darker in light mode for better contrast
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: null,
      body: SafeArea(
        child: RefreshIndicator(
          color: accentColor,
          onRefresh: () async {
            // In a real app, refresh user data here
            if (userProvider.user != null) {
              await userProvider.loadUserData(userProvider.user!.id);
            }
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 20),
                
                // Profile avatar and edit button
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: themeProvider.isDarkMode 
                                ? Colors.white30
                                : Colors.black26,
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: ImageUtils.avatarWithFallback(
                            imageUrl: user.profileImageUrl,
                            radius: 60,
                            name: user.fullName,
                            backgroundColor: themeProvider.isDarkMode 
                                ? Colors.grey[800]!
                                : Colors.grey[300]!,
                            textColor: themeProvider.isDarkMode 
                                ? Colors.white54
                                : Colors.black38,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 10,
                        child: GestureDetector(
                          onTap: _navigateToEditProfile,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: accentColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.edit,
                              color: themeProvider.isDarkMode ? Colors.black : Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // User name and email
                Text(
                  user.fullName,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: TextStyle(
                    fontSize: 14,
                    color: secondaryTextColor,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Level indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star,
                        color: accentColor,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Level $userLevel",
                        style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Focus Areas
                if (user.focusAreas.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: user.focusAreas.map((area) => Chip(
                        label: Text(area),
                        backgroundColor: themeProvider.isDarkMode
                            ? Colors.grey[800]
                            : Colors.grey[200],
                        labelStyle: TextStyle(
                          color: textColor,
                          fontSize: 12,
                        ),
                      )).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                
                // Theme toggle switch
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: Theme.of(context).colorScheme.surface,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20, 
                        vertical: 12
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                themeProvider.isDarkMode 
                                  ? Icons.dark_mode 
                                  : Icons.light_mode,
                                color: accentColor,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                themeProvider.isDarkMode
                                  ? "Dark Mode"
                                  : "Light Mode",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          Switch(
                            value: themeProvider.isDarkMode,
                            onChanged: (_) {
                              themeProvider.toggleTheme();
                            },
                            activeColor: accentColor,
                            activeTrackColor: accentColor.withOpacity(0.3),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // XP progress indicator
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Level Progress",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          Text(
                            "${(levelProgress * 100).toInt()}%",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: accentColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${user.xp} XP",
                            style: TextStyle(
                              fontSize: 14,
                              color: secondaryTextColor,
                            ),
                          ),
                          Text(
                            "${userProvider.level == 1 ? 500 : userProvider.level * 500} XP",
                            style: TextStyle(
                              fontSize: 14,
                              color: secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearPercentIndicator(
                        lineHeight: 8,
                        percent: levelProgress,
                        backgroundColor: themeProvider.isDarkMode 
                            ? Colors.grey[800]
                            : Colors.grey[300],
                        progressColor: accentColor,
                        barRadius: const Radius.circular(4),
                        padding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${xpForNextLevel} XP needed for Level ${userLevel + 1}",
                        style: TextStyle(
                          fontSize: 12,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Focus Points
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: Theme.of(context).colorScheme.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          AppIcons.getCustomFocusPointWidget(
                            value: '${user.focusPoints}',
                            backgroundColor: accentColor.withOpacity(0.2),
                            textColor: accentColor,
                            size: 48,
                            showLabel: false,
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Focus Points',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${user.focusPoints} points available',
                                style: TextStyle(
                                  color: textColor.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '+${user.focusPoints}',
                              style: TextStyle(
                                color: accentColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Badges section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Badges",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          TextButton(
                            onPressed: _navigateToAllBadges,
                            child: Row(
                              children: [
                                Text(
                                  "More",
                                  style: TextStyle(
                                    color: accentColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: accentColor,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Consumer<UserProvider>(
                        builder: (context, userProvider, child) {
                          // Check if user data is loaded
                          if (userProvider.isLoading || userProvider.user == null) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Loading badges...",
                                    style: TextStyle(
                                      color: secondaryTextColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          // Get all badge definitions and user's earned badge IDs
                          final allDefinitions = userProvider.allBadgeDefinitions;
                          final earnedBadgeIds = userProvider.user!.badgesgranted
                              .map((ref) => ref['id'] as String?)
                              .where((id) => id != null)
                              .toSet();

                          if (allDefinitions.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  "No badges available. Complete challenges to earn badges!",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: secondaryTextColor,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            );
                          }

                          // Create the list of badges with status
                          final badgesWithStatus = allDefinitions.map((badgeDef) {
                            final isEarned = earnedBadgeIds.contains(badgeDef.id);
                            // If earned, try to get the detailed badge from userProvider.user.badges
                            // This ensures we have the correct earnedAt date if available
                            final earnedBadgeDetail = isEarned
                                ? userProvider.user!.badges.firstWhere(
                                    (b) => b.id == badgeDef.id,
                                    orElse: () => badgeDef.copyWith(earnedAt: DateTime.now()) // Fallback if not found in detail list yet
                                  )
                                : badgeDef;
                            return {
                              'badge': earnedBadgeDetail,
                              'isEarned': isEarned,
                            };
                          }).toList();

                          // Show up to 10 badges (prioritize earned badges)
                          final earnedBadges = badgesWithStatus
                              .where((item) => item['isEarned'] == true)
                              .toList();
                          final unearnedBadges = badgesWithStatus
                              .where((item) => item['isEarned'] == false)
                              .toList();

                          // Combine them, showing earned first, up to 10 total
                          List<Map<String, dynamic>> displayedBadges = [];
                          displayedBadges.addAll(earnedBadges);

                          // Calculate remaining slots and add unearned badges if needed
                          int remainingSlots = 10 - displayedBadges.length;
                          if (remainingSlots > 0) {
                            displayedBadges.addAll(unearnedBadges.take(remainingSlots));
                          }

                          // Ensure the final list does not exceed 10 (optional safety check, take() handles it)
                          // final badgesToShow = displayedBadges.take(10).toList(); // Use displayedBadges directly

                          return SizedBox(
                            height: 125, // Increased from 115 to accommodate the content
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: displayedBadges.length, // Use the potentially longer list
                              itemBuilder: (context, index) {
                                final badgeData = displayedBadges[index];
                                final badge = badgeData['badge'] as AppBadge;
                                final isEarned = badgeData['isEarned'] as bool;

                                return Padding(
                                  padding: const EdgeInsets.only(right: 10), // Reduced from 12 to save space
                                  child: _buildBadgeItemWithStatus(context, badge, isEarned),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Stats row (Replaced Row with Wrap to prevent overflow)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Wrap(
                    alignment: WrapAlignment.spaceAround, // Distribute space around items
                    runAlignment: WrapAlignment.center, // Center items vertically if they wrap
                    spacing: 16.0, // Horizontal space between items
                    runSpacing: 16.0, // Vertical space between rows if wrapping occurs
                    children: [
                      // --- Updated StatCircle for Badges ---
                      Consumer<UserProvider>(
                         builder: (context, userProvider, child) {
                            if (userProvider.user == null || userProvider.allBadgeDefinitions.isEmpty) {
                               return _buildStatCircle("0/0", "Badges", context);
                            }
                            final earnedCount = userProvider.user!.badgesgranted.length;
                            final totalCount = userProvider.allBadgeDefinitions.length;
                            return _buildStatCircle("$earnedCount/$totalCount", "Badges", context);
                         }
                      ),
                      // --- End Updated StatCircle ---
                      // Use Consumer for other stats too for consistency
                      Consumer<UserProvider>(
                        builder: (context, userProvider, child) {
                           final streak = userProvider.user?.streak ?? 0;
                           final longestStreak = userProvider.user?.longestStreak ?? 0;
                           return _buildStatCircle("$streak/$longestStreak", "Current/\nBest Streak", context);
                        }
                      ),
                      Consumer<UserProvider>(
                        builder: (context, userProvider, child) {
                           final completedAudios = userProvider.user?.completedAudios.length ?? 0;
                           return _buildStatCircle("$completedAudios", "Audio\ncompleted", context);
                        }
                      ),
                       Consumer<UserProvider>(
                        builder: (context, userProvider, child) {
                           final completedCourses = userProvider.user?.completedCourses.length ?? 0;
                           return _buildStatCircle("$completedCourses", "Courses\ncompleted", context);
                        }
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Need guidance section
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: themeProvider.isDarkMode
                              ? Colors.grey[850]
                              : Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.call,
                          color: accentColor,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "Need Guidance?",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Book a call with one of our mental performance coaches",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: themeProvider.isDarkMode
                              ? Colors.white70
                              : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            _launchCalendly("https://calendly.com");
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: themeProvider.isDarkMode ? Colors.black : Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            "SCHEDULE CALL",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildBadgeItem(BuildContext context, AppBadge badge) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final accentColor = themeProvider.isDarkMode 
      ? AppColors.accentDark 
      : AppColors.accentLight;
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BadgeDetailScreen(badge: badge),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        width: 100,
        child: Column(
          children: [
            Hero(
              tag: 'badge_${badge.id}',
              child: Container(
                height: 85,
                width: 85,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: badge.badgeImage != null && badge.badgeImage!.isNotEmpty
                      ? Image.network(
                          badge.badgeImage!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(
                                Icons.emoji_events,
                                color: accentColor,
                                size: 40,
                              ),
                            );
                          },
                        )
                      : (badge.imageUrl != null && badge.imageUrl!.startsWith('http'))
                          ? Image.network(
                              badge.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(
                                    Icons.emoji_events,
                                    color: accentColor,
                                    size: 40,
                                  ),
                                );
                              },
                            )
                          : Center(
                              child: Icon(
                                Icons.emoji_events,
                                color: accentColor,
                                size: 40,
                              ),
                            ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              badge.name ?? 'Unknown Badge',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBadgeItemWithStatus(BuildContext context, AppBadge badge, bool isEarned) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final accentColor = themeProvider.accentColor;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BadgeDetailScreen(
              badge: badge,
              isEarned: isEarned,
            ),
          ),
        );
      },
      child: Opacity(
        opacity: 1.0,
        child: Container(
          margin: const EdgeInsets.only(right: 8), // Reduced from 12
          width: 90, // Reduced from 100
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Hero(
                tag: 'badge_${badge.id}',
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 80, // Reduced from 85
                      width: 80, // Reduced from 85
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                        border: isEarned
                            ? Border.all(color: accentColor.withOpacity(0.7), width: 2) // Add border if earned
                            : Border.all(color: (isDarkMode ? Colors.white12 : Colors.black12), width: 1), // Subtle border if unearned
                        boxShadow: isEarned ? [ // Add shadow if earned
                          BoxShadow(
                            color: accentColor.withOpacity(0.2),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ] : [], // No shadow if not earned
                      ),
                      child: ClipOval(
                        child: ColorFiltered( // Apply greyscale if not earned
                          colorFilter: isEarned
                              ? const ColorFilter.mode(
                                  Colors.transparent,
                                  BlendMode.saturation,
                                )
                              : const ColorFilter.matrix([
                                  // Greyscale matrix
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0,      0,      0,      1, 0,
                                ]),
                          child: (badge.badgeImage ?? badge.imageUrl ?? '').isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: badge.badgeImage ?? badge.imageUrl ?? '',
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(accentColor.withOpacity(0.5)),
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Icon(
                                    Icons.broken_image,
                                    color: isDarkMode ? Colors.white54 : Colors.black54,
                                    size: 40,
                                  ),
                                )
                              : Icon( // Fallback icon
                                  Icons.emoji_events,
                                  color: isDarkMode ? Colors.white30 : Colors.black38,
                                  size: 40,
                                 ),
                        ),
                      ),
                    ),
                    // Lock Icon Overlay if not earned
                    if (!isEarned)
                      Container(
                        height: 80,
                        width: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.4), // Semi-transparent overlay
                        ),
                        child: Icon(
                          Icons.lock,
                          color: Colors.white.withOpacity(0.8),
                          size: 32,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                badge.name,
                textAlign: TextAlign.center,
                maxLines: 2, // Allow wrapping
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isEarned ? FontWeight.w600 : FontWeight.normal,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(isEarned ? 1.0 : 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatCircle(String value, String label, BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final textColor = Theme.of(context).colorScheme.onBackground;
    final secondaryTextColor = themeProvider.isDarkMode 
        ? Colors.grey[400] 
        : Colors.grey[700];
  
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: themeProvider.isDarkMode ? Colors.white24 : Colors.black12,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: secondaryTextColor,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
} 