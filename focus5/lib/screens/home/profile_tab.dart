import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/user_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/user_model.dart';
import '../../constants/theme.dart';
import '../../utils/image_utils.dart';
import '../../services/user_level_service.dart';
import 'all_badges_screen.dart';
import 'edit_profile_screen.dart';
import '../../utils/app_icons.dart';
import '../profile/profile_screen.dart';

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
    badges: [
      AppBadge(
        id: 'badge1',
        name: 'Fast Learner',
        description: 'Completed 5 lessons in a single day',
        imageUrl: 'assets/images/badge_fast_learner.png',
        earnedAt: DateTime.now().subtract(const Duration(days: 5)),
        xpValue: 50,
      ),
      AppBadge(
        id: 'badge2',
        name: 'Mental Athlete',
        description: 'Completed 10 mental training sessions',
        imageUrl: 'assets/images/badge_mental_athlete.png',
        earnedAt: DateTime.now().subtract(const Duration(days: 2)),
        xpValue: 100,
      ),
      AppBadge(
        id: 'badge3',
        name: 'Consistency',
        description: 'Maintained a 7-day streak',
        imageUrl: 'assets/images/badge_consistency.png',
        earnedAt: DateTime.now().subtract(const Duration(days: 1)),
        xpValue: 100,
      ),
      AppBadge(
        id: 'badge4',
        name: 'Power User',
        description: 'Used the app for 30 consecutive days',
        imageUrl: 'assets/images/badge_power_user.png',
        earnedAt: DateTime.now(),
        xpValue: 150,
      ),
    ],
    completedCourses: ['course1'],
    completedAudios: ['audio1', 'audio2', 'audio3'],
    lastLoginDate: DateTime.now(),
    createdAt: DateTime.now().subtract(const Duration(days: 30)),
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
  Widget build(BuildContext context) {
    // In a real app, we would use the UserProvider here
    final userProvider = Provider.of<UserProvider>(context);
    // Use real user data when available
    final user = userProvider.user ?? _dummyUser;
    
    final themeProvider = Provider.of<ThemeProvider>(context);
    
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
                            "${user.xp + xpForNextLevel} XP",
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
                          if (user.badges.length > 3)
                            TextButton(
                              onPressed: _navigateToAllBadges,
                              child: Text(
                                "See All",
                                style: TextStyle(
                                  color: accentColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (user.badges.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              "No badges earned yet. Complete courses and challenges to earn badges!",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: secondaryTextColor,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          height: 110,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: user.badges.length > 3 ? 3 : user.badges.length,
                            itemBuilder: (context, index) {
                              final badge = user.badges[index];
                              return Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: _buildBadgeItem(badge, context),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Stats row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatCircle("${user.badges.length}", "Badges", context),
                      _buildStatCircle("${user.streak}/${user.longestStreak}", "Current/\nBest Streak", context),
                      _buildStatCircle("${user.completedAudios.length}", "Audio\ncompleted", context),
                      _buildStatCircle("${user.completedCourses.length}", "Courses\ncompleted", context),
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
  
  Widget _buildBadgeItem(AppBadge badge, BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final textColor = Theme.of(context).colorScheme.onBackground;
    
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.grey[200],
            shape: BoxShape.circle,
            border: Border.all(
              color: themeProvider.isDarkMode ? Colors.white24 : Colors.black12,
              width: 2,
            ),
          ),
          child: ClipOval(
            child: Image.asset(
              badge.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Icon(
                    Icons.emoji_events,
                    color: themeProvider.isDarkMode ? Colors.white54 : Colors.black38,
                    size: 36,
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 80,
          child: Text(
            badge.name,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            style: TextStyle(
              fontSize: 12,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
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