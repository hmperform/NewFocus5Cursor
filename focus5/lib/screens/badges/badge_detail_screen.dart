import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:focus5/models/user_model.dart';
import 'package:focus5/constants/theme.dart';
import 'package:focus5/utils/formatters.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:focus5/providers/theme_provider.dart';
import 'dart:math' as math;
import 'package:lottie/lottie.dart';
import '../../models/content_models.dart';

class BadgeDetailScreen extends StatefulWidget {
  final AppBadge badge;
  final bool isEarned;

  const BadgeDetailScreen({
    super.key, 
    required this.badge,
    this.isEarned = false,
  });

  @override
  State<BadgeDetailScreen> createState() => _BadgeDetailScreenState();
}

class _BadgeDetailScreenState extends State<BadgeDetailScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _borderAnimation;
  late bool _showLock;
  
  @override
  void initState() {
    super.initState();
    _showLock = !widget.isEarned;
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );
    
    _borderAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
      ),
    );
    
    _animationController.forward();
    
    // Set system UI overlay style based on app colors
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
    ));
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    // Restore system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    super.dispose();
  }

  // Builds the badge image with proper styling based on locked/unlocked status
  Widget _buildBadgeImage(bool isDarkMode, Color accentColor) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Glow effect
        if (widget.isEarned)
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.5),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
          ),
        
        // Badge image
        Hero(
          tag: 'badge_${widget.badge.id}',
          child: Container(
            height: 180,
            width: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.isEarned 
                    ? accentColor.withOpacity(_borderAnimation.value)
                    : Colors.grey.withOpacity(0.3),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipOval(
              child: ColorFiltered(
                // Apply grayscale filter if not earned
                colorFilter: widget.isEarned
                    ? const ColorFilter.mode(
                        Colors.transparent,
                        BlendMode.saturation,
                      )
                    : const ColorFilter.matrix([
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0, 0, 0, 1, 0,
                      ]),
                child: CachedNetworkImage(
                  imageUrl: widget.badge.badgeImage ?? '',
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => Container(
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    child: Icon(
                      Icons.emoji_events,
                      color: widget.isEarned ? accentColor : Colors.grey,
                      size: 80,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        
        // Lock overlay for unearned badges
        if (_showLock)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.5),
              ),
              child: Center(
                child: Icon(
                  Icons.lock_outline,
                  color: Colors.white.withOpacity(0.7),
                  size: 60,
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    // Theme colors using the app's neon accent color for a better neon theme
    final accentColor = isDarkMode ? AppColors.accentDark : AppColors.accentLight;
    final backgroundColor = isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight;
    final cardColor = isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textColor = isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    
    // Badge type icons based on name
    IconData getBadgeTypeIcon() {
      final criteriaType = widget.badge.criteriaType.toLowerCase();
      if (criteriaType.contains('streak')) return Icons.calendar_month;
      if (criteriaType.contains('audio')) return Icons.headphones;
      if (criteriaType.contains('course')) return Icons.school;
      if (criteriaType.contains('total')) return Icons.access_time_filled;
      if (criteriaType.contains('journal')) return Icons.edit_note;
      return Icons.emoji_events;
    }
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: textColor,
        elevation: 0,
        title: const Text('Badge Detail'),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeInAnimation.value,
            child: Transform.translate(
              offset: Offset(0, _slideAnimation.value),
              child: child,
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: isDarkMode
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF121212), Colors.black],
                  )
                : const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFF8F8F8), Colors.white],
                  ),
          ),
          height: MediaQuery.of(context).size.height,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 20),
                
                // Badge Image with enhanced edge glow
                _buildBadgeImage(isDarkMode, accentColor),
                
                const SizedBox(height: 24),
                
                // Badge Status (Earned or Locked)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: widget.isEarned 
                        ? Colors.green.withOpacity(0.2) 
                        : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.isEarned ? Icons.check_circle : Icons.lock,
                        color: widget.isEarned ? Colors.green : Colors.grey,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.isEarned ? 'EARNED' : 'LOCKED',
                        style: TextStyle(
                          color: widget.isEarned ? Colors.green : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Badge Name with icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (widget.isEarned ? accentColor : Colors.grey).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        getBadgeTypeIcon(),
                        color: widget.isEarned ? accentColor : Colors.grey,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        widget.badge.name,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Badge Description
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    widget.badge.description,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: secondaryTextColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Badge Details Section with neon-styled card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: (widget.isEarned ? accentColor : Colors.grey).withOpacity(isDarkMode ? 0.1 : 0.05),
                          blurRadius: 15,
                          spreadRadius: 0,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: (widget.isEarned ? accentColor : Colors.grey).withOpacity(isDarkMode ? 0.3 : 0.1),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (widget.isEarned ? accentColor : Colors.grey).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                widget.isEarned ? Icons.info_outline : Icons.lock_open,
                                color: widget.isEarned ? accentColor : Colors.grey,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              widget.isEarned ? 'Badge Details' : 'How to Unlock',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // XP Value
                        _buildDetailRow(
                          context,
                          'XP Value',
                          '${widget.badge.xpValue} XP',
                          Icons.star_rounded,
                          isDarkMode,
                          widget.isEarned ? accentColor : Colors.grey,
                        ),
                        
                        if (!widget.isEarned) ...[
                          const SizedBox(height: 16),
                          // Requirements to unlock
                          _buildDetailRow(
                            context,
                            'Requirement',
                            _getRequirementText(),
                            _getRequirementIcon(),
                            isDarkMode,
                            Colors.grey,
                          ),
                          
                          const SizedBox(height: 16),
                          // Progress (if applicable)
                          _buildDetailRow(
                            context,
                            'Your Progress',
                            _getProgressText(),
                            Icons.stacked_line_chart,
                            isDarkMode,
                            Colors.grey,
                          ),
                        ] else if (widget.badge.earnedAt != null) ...[
                          const SizedBox(height: 16),
                          // Earned Date (if earned)
                          _buildDetailRow(
                            context,
                            'Earned On',
                            Formatters.formatDate(widget.badge.earnedAt),
                            Icons.calendar_today,
                            isDarkMode,
                            accentColor,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                
                // Tip for locked badges
                if (!widget.isEarned) ...[
                  const SizedBox(height: 32),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.blue.withOpacity(0.1) : Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.lightbulb_outline,
                          color: Colors.blue,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _getTipText(),
                            style: TextStyle(
                              color: isDarkMode ? Colors.blue[200] : Colors.blue[800],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // Helper method to build consistent detail rows
  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    bool isDarkMode,
    Color iconColor,
  ) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  // Helper method to get requirement text based on badge criteria
  String _getRequirementText() {
    switch (widget.badge.criteriaType) {
      case 'AudioModulesCompleted':
        return 'Complete ${widget.badge.requiredCount} audio sessions';
      case 'CoursesCompleted':
        if (widget.badge.specificCourses != null && widget.badge.specificCourses!.isNotEmpty) {
          // Use the badge's description for specific course badges
          return widget.badge.description;
        } else {
          return 'Complete ${widget.badge.requiredCount} courses';
        }
      case 'CourseLessonsCompleted':
        return 'Complete ${widget.badge.requiredCount} course lessons';
      case 'JournalEntriesWritten':
        return 'Write ${widget.badge.requiredCount} journal entries';
      case 'StreakLength':
        return 'Achieve a ${widget.badge.requiredCount}-day streak';
      case 'TotalDaysInApp':
        return 'Use the app for ${widget.badge.requiredCount} days';
      default:
        return widget.badge.description;
    }
  }
  
  // Helper method to get requirement icon based on badge criteria
  IconData _getRequirementIcon() {
    switch (widget.badge.criteriaType) {
      case 'AudioModulesCompleted':
        return Icons.headphones;
      case 'CoursesCompleted':
        return Icons.school;
      case 'CourseLessonsCompleted':
        return Icons.menu_book;
      case 'JournalEntriesWritten':
        return Icons.edit_note;
      case 'StreakLength':
        return Icons.local_fire_department;
      case 'TotalDaysInApp':
        return Icons.access_time_filled;
      default:
        return Icons.emoji_events;
    }
  }
  
  // Helper method to get progress text based on user data
  // In a real app, you'd get this from the UserProvider
  String _getProgressText() {
    // This is a placeholder - in a real implementation you would
    // access the user's actual progress from UserProvider
    switch (widget.badge.criteriaType) {
      case 'AudioModulesCompleted':
        return 'You\'ve completed some audio sessions';
      case 'CoursesCompleted':
        return 'You\'ve completed some courses';
      case 'CourseLessonsCompleted':
        return 'You\'ve completed some lessons';
      case 'JournalEntriesWritten':
        return 'You\'ve written some journal entries';
      case 'StreakLength':
        return 'Your current streak is getting there!';
      case 'TotalDaysInApp':
        return 'You\'ve used the app for multiple days';
      default:
        return 'Keep using the app to progress';
    }
  }
  
  // Helper method to get tip text based on badge criteria
  String _getTipText() {
    switch (widget.badge.criteriaType) {
      case 'AudioModulesCompleted':
        return 'Tip: Check out the Daily Audio section for new audio sessions to complete!';
      case 'CoursesCompleted':
        return 'Tip: Explore courses in your focus areas to complete this badge faster.';
      case 'CourseLessonsCompleted':
        return 'Tip: Focus on completing one course at a time to earn this badge.';
      case 'JournalEntriesWritten':
        return 'Tip: Try to write in your journal every day after practicing to track your progress.';
      case 'StreakLength':
        return 'Tip: Use the app every day to maintain your streak and unlock this badge!';
      case 'TotalDaysInApp':
        return 'Tip: Open the app daily, even if briefly, to count toward this badge.';
      default:
        return 'Tip: Keep using Focus 5 regularly to earn badges and improve your mental game!';
    }
  }
} 