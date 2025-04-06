import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/user_model.dart';
import '../../constants/theme.dart';

class AllBadgesScreen extends StatelessWidget {
  const AllBadgesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = userProvider.user;
    
    // Use theme-aware colors
    final accentColor = themeProvider.isDarkMode 
        ? AppColors.accentDark 
        : AppColors.accentLight;
    final textColor = Theme.of(context).colorScheme.onBackground;
    final secondaryTextColor = themeProvider.isDarkMode 
        ? Colors.grey[400] 
        : Colors.grey[700];
    
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Badges')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    // Sort badges by most recently earned
    final badges = List<AppBadge>.from(user.badges)
      ..sort((a, b) => b.earnedAt.compareTo(a.earnedAt));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Badges'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: textColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: badges.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.emoji_events_outlined,
                        size: 80,
                        color: secondaryTextColor,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "No Badges Yet",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Complete courses, maintain streaks, and use the app regularly to earn badges!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: badges.length,
                itemBuilder: (context, index) => _buildBadgeListItem(
                  badges[index],
                  context,
                  accentColor,
                  textColor,
                  secondaryTextColor,
                ),
              ),
      ),
    );
  }
  
  Widget _buildBadgeListItem(
    AppBadge badge,
    BuildContext context,
    Color accentColor,
    Color textColor,
    Color? secondaryTextColor,
  ) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.grey[200],
                shape: BoxShape.circle,
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
                        size: 30,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    badge.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    badge.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              color: accentColor,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "+${badge.xpValue} XP",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: accentColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Earned ${_formatDate(badge.earnedAt)}",
                        style: TextStyle(
                          fontSize: 12,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? "week" : "weeks"} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? "month" : "months"} ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
} 