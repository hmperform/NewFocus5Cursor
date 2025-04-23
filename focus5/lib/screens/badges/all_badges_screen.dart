import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/badge_model.dart';
import '../../models/content_models.dart';
import '../../providers/theme_provider.dart';
import '../../providers/badge_provider.dart';
import '../../models/user_model.dart';
import '../../screens/badges/badge_detail_screen.dart';
import '../../constants/theme.dart';

class AllBadgesScreen extends StatefulWidget {
  const AllBadgesScreen({Key? key}) : super(key: key);

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
              final isEarned = badgeProvider.earnedBadges.contains(badge);
              
              return _buildBadgeCard(badge, isEarned, textColor, themeProvider);
            },
          ),
        );
      },
    );
  }
  
  Widget _buildBadgeCard(BadgeModel badge, bool isEarned, Color textColor, ThemeProvider themeProvider) {
    final accentColor = themeProvider.isDarkMode 
        ? AppColors.accentDark 
        : AppColors.accentLight;
        
    return GestureDetector(
      onTap: () {
        // Show badge details or unlock requirements when tapped
        if (isEarned) {
          // Navigate to badge details if earned
          // Convert BadgeModel to AppBadge for navigation
          final appBadge = AppBadge(
            id: badge.id,
            name: badge.name,
            description: badge.description,
            imageUrl: badge.imageUrl ?? '',
            badgeImage: badge.imageUrl,
            earnedAt: badge.earnedDate,
            xpValue: badge.xpValue,
            criteriaType: badge.criteriaType.name,
            requiredCount: badge.requiredCount,
          );
          
          Navigator.push(
            context, 
            MaterialPageRoute(
              builder: (context) => BadgeDetailScreen(badge: appBadge, isEarned: true),
            ),
          );
        } else {
          // Show requirements to unlock
          _showBadgeRequirements(badge);
        }
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Badge Icon with circular design like in profile tab
              Hero(
                tag: 'badge_${badge.id}',
                child: Opacity(
                  opacity: isEarned ? 1.0 : 0.4,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.grey[200],
                      boxShadow: isEarned ? [
                        BoxShadow(
                          color: accentColor.withOpacity(0.2),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ] : null,
                    ),
                    child: ClipOval(
                      child: badge.imageUrl != null && badge.imageUrl!.isNotEmpty
                          ? Image.network(
                              badge.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(
                                    _getBadgeIcon(badge.criteriaType),
                                    color: isEarned ? accentColor : Colors.grey,
                                    size: 40,
                                  ),
                                );
                              },
                            )
                          : Center(
                              child: Icon(
                                _getBadgeIcon(badge.criteriaType),
                                color: isEarned ? accentColor : Colors.grey,
                                size: 40,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Badge Name
              Text(
                badge.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              // Badge Description
              Text(
                badge.description,
                style: TextStyle(
                  fontSize: 12,
                  color: textColor.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Badge Status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isEarned 
                      ? accentColor.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isEarned ? 'EARNED' : 'LOCKED',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isEarned ? accentColor : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Show badge requirements in a bottom sheet
  void _showBadgeRequirements(BadgeModel badge) {
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
  
  Widget _buildRequirementsList(BadgeModel badge, ThemeProvider themeProvider, Color accentColor) {
    // Example requirements based on badge criteria type
    final List<String> requirements = [];
    
    switch (badge.criteriaType) {
      case BadgeCriteriaType.streak:
        requirements.add('Log in for consecutive ${badge.requiredCount} days');
        requirements.add('Don\'t miss a day to maintain your streak');
        break;
      case BadgeCriteriaType.completion:
        requirements.add('Complete ${badge.requiredCount} sessions');
        requirements.add('Each session must be played to completion');
        break;
      case BadgeCriteriaType.performance:
        requirements.add('Achieve a score of ${badge.requiredCount}');
        requirements.add('Keep practicing to improve your performance');
        break;
      case BadgeCriteriaType.milestone:
        requirements.add('Earn a total of ${badge.requiredCount} XP');
        requirements.add('XP is earned by completing activities');
        break;
      case BadgeCriteriaType.achievement:
        requirements.add('Complete specific achievements (${badge.requiredCount} required)');
        requirements.add('Check the achievements tab for details');
        break;
      case BadgeCriteriaType.social:
        requirements.add('Connect with ${badge.requiredCount} other users');
        requirements.add('Participate in community discussions');
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
  
  IconData _getBadgeIcon(BadgeCriteriaType criteriaType) {
    switch (criteriaType) {
      case BadgeCriteriaType.streak:
        return Icons.local_fire_department;
      case BadgeCriteriaType.completion:
        return Icons.check_circle;
      case BadgeCriteriaType.performance:
        return Icons.trending_up;
      case BadgeCriteriaType.achievement:
        return Icons.emoji_events;
      case BadgeCriteriaType.social:
        return Icons.people;
      case BadgeCriteriaType.milestone:
        return Icons.flag;
      default:
        return Icons.star;
    }
  }
} 