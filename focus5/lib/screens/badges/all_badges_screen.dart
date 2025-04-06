import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/badge_model.dart';
import '../../providers/theme_provider.dart';
import '../../providers/badge_provider.dart';

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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Badge Icon with conditional opacity
            Opacity(
              opacity: isEarned ? 1.0 : 0.3,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: themeProvider.accentColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getBadgeIcon(badge.criteriaType),
                  size: 40,
                  color: isEarned ? themeProvider.accentColor : Colors.grey,
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
                    ? themeProvider.accentColor.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isEarned ? 'EARNED' : 'LOCKED',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isEarned ? themeProvider.accentColor : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
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