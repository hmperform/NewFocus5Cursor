import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/user_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/user_model.dart';
import '../../constants/theme.dart';
import '../../utils/image_utils.dart';

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

  // Dummy data for the profile screen
  final User _dummyUser = User(
    id: 'user123',
    email: 'bessiecooper@example.com',
    username: 'focus_athlete',
    fullName: 'Bessie Cooper',
    profileImageUrl: 'https://picsum.photos/200/200?random=3',
    sport: 'Soccer',
    university: 'Stanford University',
    universityCode: 'SU',
    isIndividual: true,
    focusAreas: ['Confidence', 'Pressure Situations', 'Game Day Preparation'],
    xp: 300,
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
    savedCourses: ['course3', 'course4'],
    streak: 5,
    lastActive: DateTime.now(),
  );

  // XP required for each level
  final int _maxXP = 2000;

  Future<void> _launchCalendly(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch booking URL')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // In a real app, we would use the UserProvider here
    // final userProvider = Provider.of<UserProvider>(context);
    // final user = userProvider.user;
    
    // For now, use the dummy data
    final user = _dummyUser;
    final themeProvider = Provider.of<ThemeProvider>(context);
    
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
            await Future.delayed(const Duration(milliseconds: 1000));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 20),
                
                // Profile avatar and badge
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
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: accentColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.diamond_outlined,
                            color: themeProvider.isDarkMode ? Colors.black : Colors.white,
                            size: 24,
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
                
                const SizedBox(height: 16),
                
                // Bio text
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    "Striving to build mental strength and discipline through daily challenges. Growth is a journey, not a destination.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: themeProvider.isDarkMode 
                          ? Colors.grey[300]
                          : Colors.grey[800],
                      height: 1.4,
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
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
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${user.xp} XP",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: accentColor,
                            ),
                          ),
                          Text(
                            "$_maxXP XP",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LinearPercentIndicator(
                        lineHeight: 8,
                        percent: user.xp / _maxXP,
                        backgroundColor: themeProvider.isDarkMode 
                            ? Colors.grey[800]
                            : Colors.grey[300],
                        progressColor: accentColor,
                        barRadius: const Radius.circular(4),
                        padding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Earn 10 XP per minute in the app. Unlock courses with 2000 XP.",
                        style: TextStyle(
                          fontSize: 12,
                          color: secondaryTextColor,
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
                      _buildStatCircle("4/30", "Badges", context),
                      _buildStatCircle("5/20", "Streaks", context),
                      _buildStatCircle("3/17", "Modules\ncompleted", context),
                      _buildStatCircle("1/10", "Courses\ncompleted", context),
                      _buildStatCircle("10", "Journal\nentries", context),
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