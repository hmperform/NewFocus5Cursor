import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/content_models.dart';
import '../../providers/theme_provider.dart';
import '../../providers/badge_provider.dart';
import '../../models/user_model.dart';
import '../../screens/badges/badge_detail_screen.dart';
import '../../constants/theme.dart';

class AllBadgesScreen extends StatefulWidget {
  const AllBadgesScreen({super.key});

  @override
  State<AllBadgesScreen> createState() => _AllBadgesScreenState();
}

class _AllBadgesScreenState extends State<AllBadgesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _loadBadges();
  }
  
  Future<void> _loadBadges() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      final badgeProvider = Provider.of<BadgeProvider>(context, listen: false);
      await badgeProvider.loadBadges();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading badges: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load badges: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).colorScheme.onBackground;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'All Badges',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: themeProvider.accentColor))
          : _errorMessage != null
              ? _buildErrorWidget(textColor)
              : _buildBadgesGrid(textColor, themeProvider),
    );
  }
  
  Widget _buildErrorWidget(Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage!,
              style: TextStyle(color: textColor),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadBadges,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBadgesGrid(Color textColor, ThemeProvider themeProvider) {
    return Consumer<BadgeProvider>(
      builder: (context, badgeProvider, child) {
        final allBadges = badgeProvider.allBadges;
        
        if (allBadges.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  size: 48,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  'No Badges Available',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Check back later for badges to earn',
                  style: TextStyle(color: textColor.withOpacity(0.7)),
                ),
              ],
            ),
          );
        }
        
        return RefreshIndicator(
          onRefresh: _loadBadges,
          color: themeProvider.accentColor,
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.75,
            ),
            itemCount: allBadges.length,
            itemBuilder: (context, index) {
              final badge = allBadges[index];
              // Show all badges, including course-specific ones
              return _buildBadgeCard(badge, badgeProvider.earnedBadges.any((earned) => earned.id == badge.id), textColor, themeProvider);
            },
          ),
        );
      },
    );
  }
  
  Widget _buildBadgeCard(AppBadge badge, bool isEarned, Color textColor, ThemeProvider themeProvider) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BadgeDetailScreen(badge: badge, isEarned: isEarned),
          ),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Image.network(
                    badge.imageUrl ?? 'https://example.com/default_badge.png',
                    width: 80,
                    height: 80,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: themeProvider.accentColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.emoji_events,
                          size: 40,
                          color: themeProvider.accentColor,
                        ),
                      );
                    },
                  ),
                  if (!isEarned)
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                badge.name,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                isEarned
                    ? 'Earned!'
                    : _getRequirementText(badge),
                style: TextStyle(
                  color: isEarned ? Colors.green : textColor.withOpacity(0.7),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (isEarned) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '+${badge.xpValue} XP',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  // Show badge requirements in a bottom sheet
  void _showBadgeRequirements(AppBadge badge) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final accentColor = themeProvider.isDarkMode 
        ? AppColors.accentDark 
        : AppColors.accentLight;
        
    showModalBottomSheet(
      context: context,
      backgroundColor: themeProvider.isDarkMode ? Colors.grey[900] : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    color: accentColor,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Badge Requirements',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'How to earn "${badge.name}":',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onBackground,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                badge.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              _buildRequirementsList(badge, themeProvider, accentColor),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: themeProvider.isDarkMode ? Colors.black : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('GOT IT'),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildRequirementsList(AppBadge badge, ThemeProvider themeProvider, Color accentColor) {
    // Example requirements based on badge criteria type
    final List<String> requirements = [];
    
    switch (badge.criteriaType) {
      case 'StreakLength':
        requirements.add('Log in for consecutive ${badge.requiredCount} days');
        requirements.add('Don\'t miss a day to maintain your streak');
        break;
      case 'CoursesCompleted':
        requirements.add('Complete ${badge.requiredCount} courses');
        requirements.add('Each course must be completed fully');
        break;
      case 'AudioModulesCompleted':
        requirements.add('Complete ${badge.requiredCount} audio sessions');
        requirements.add('Listen to each session fully');
        break;
      case 'CourseLessonsCompleted':
        requirements.add('Complete ${badge.requiredCount} lessons');
        requirements.add('Watch or listen to each lesson fully');
        break;
      case 'JournalEntriesWritten':
        requirements.add('Write ${badge.requiredCount} journal entries');
        requirements.add('Express your thoughts and reflections');
        break;
      case 'TotalDaysInApp':
        requirements.add('Use the app for ${badge.requiredCount} days total');
        requirements.add('Keep engaging with the content');
        break;
      default:
        requirements.add('Complete specific activities to earn this badge');
        requirements.add('Required count: ${badge.requiredCount}');
    }
    
    return Column(
      children: requirements.map((requirement) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.check_circle_outline,
                color: accentColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  requirement,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
  
  IconData _getBadgeIcon(String criteriaType) {
    switch (criteriaType) {
      case 'StreakLength':
        return Icons.local_fire_department;
      case 'CoursesCompleted':
        return Icons.check_circle;
      case 'AudioModulesCompleted':
        return Icons.headphones;
      case 'CourseLessonsCompleted':
        return Icons.school;
      case 'JournalEntriesWritten':
        return Icons.edit_note;
      case 'TotalDaysInApp':
        return Icons.calendar_today;
      default:
        return Icons.star;
    }
  }

  // Helper method to get requirement text based on badge criteria
  String _getRequirementText(AppBadge badge) {
    switch (badge.criteriaType) {
      case 'AudioModulesCompleted':
        return 'Complete ${badge.requiredCount} audio sessions';
      case 'CoursesCompleted':
        if (badge.specificCourses != null && badge.specificCourses!.isNotEmpty) {
          return badge.description;
        }
        return 'Complete ${badge.requiredCount} courses';
      case 'CourseLessonsCompleted':
        return 'Complete ${badge.requiredCount} lessons';
      case 'JournalEntriesWritten':
        return 'Write ${badge.requiredCount} journal entries';
      case 'StreakLength':
        return 'Maintain a ${badge.requiredCount}-day streak';
      case 'TotalDaysInApp':
        return 'Use the app for ${badge.requiredCount} days';
      default:
        return badge.description;
    }
  }
} 