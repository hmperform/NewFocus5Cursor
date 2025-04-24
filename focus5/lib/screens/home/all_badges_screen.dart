import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/user_model.dart';
import '../../models/content_models.dart';
import '../../constants/theme.dart';
import '../../utils/formatters.dart';
import '../../services/badge_service.dart';
import '../badges/badge_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AllBadgesScreen extends StatefulWidget {
  const AllBadgesScreen({Key? key}) : super(key: key);

  @override
  State<AllBadgesScreen> createState() => _AllBadgesScreenState();
}

class _AllBadgesScreenState extends State<AllBadgesScreen> {
  bool _loading = true;
  
  @override
  void initState() {
    super.initState();
    // Load all badge definitions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBadgeDefinitions();
    });
  }
  
  Future<void> _loadBadgeDefinitions() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    // If badge definitions are not loaded yet, load them
    if (userProvider.allBadgeDefinitions.isEmpty) {
      await userProvider.loadAllBadgeDefinitions();
    }
    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

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
    
    if (user == null || _loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Badges')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    // Get all available badge definitions
    final allBadgeDefinitions = userProvider.allBadgeDefinitions;
    
    // Create a set of earned badge IDs for quick lookup
    final earnedBadgeIds = user.badgesgranted
        .map((badgeRef) => badgeRef['id'] as String)
        .toSet();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Badges'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: textColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: allBadgeDefinitions.isEmpty
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
                        "No Badges Available",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "There are no badges configured in the system yet.",
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
            : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: allBadgeDefinitions.length,
                itemBuilder: (context, index) {
                  final badge = allBadgeDefinitions[index];
                  final isEarned = earnedBadgeIds.contains(badge.id);
                  
                  return _buildBadgeGridItem(
                    badge,
                    context,
                    accentColor,
                    isEarned,
                  );
                },
              ),
      ),
    );
  }
  
  Widget _buildBadgeGridItem(
    AppBadge badge,
    BuildContext context,
    Color accentColor,
    bool isEarned,
  ) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    final textColor = Theme.of(context).colorScheme.onBackground;
    
    // Helper function to get appropriate icon based on criteria type
    IconData getBadgeTypeIcon() {
      final criteriaType = badge.criteriaType.toLowerCase();
      if (criteriaType.contains('streak')) return Icons.calendar_month;
      if (criteriaType.contains('audio')) return Icons.headphones;
      if (criteriaType.contains('course')) return Icons.school;
      if (criteriaType.contains('total')) return Icons.access_time_filled;
      if (criteriaType.contains('journal')) return Icons.edit_note;
      return Icons.emoji_events;
    }
    
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
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  // Badge image (with grayscale if not earned)
                  Hero(
                    tag: 'badge_${badge.id}',
                    child: Container(
                      height: 90,
                      width: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: ColorFiltered(
                          // Apply grayscale filter if not earned
                          colorFilter: !isEarned
                              ? const ColorFilter.matrix([
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0, 0, 0, 1, 0,
                                ])
                              : const ColorFilter.mode(
                                  Colors.transparent,
                                  BlendMode.saturation,
                                ),
                          child: badge.badgeImage != null && badge.badgeImage!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: badge.badgeImage!,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                                    child: Icon(
                                      getBadgeTypeIcon(),
                                      color: accentColor,
                                      size: 40,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                                    child: Icon(
                                      getBadgeTypeIcon(),
                                      color: accentColor,
                                      size: 40,
                                    ),
                                  ),
                                )
                              : Container(
                                  color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                                  child: Icon(
                                    getBadgeTypeIcon(),
                                    color: accentColor,
                                    size: 40,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Lock overlay for unearned badges
                  if (!isEarned)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.lock,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                badge.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                isEarned ? 'Earned' : 'Locked',
                style: TextStyle(
                  fontSize: 12,
                  color: isEarned ? accentColor : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 