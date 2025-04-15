import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:focus5/models/user_model.dart';
import 'package:focus5/constants/theme.dart';
import 'package:focus5/utils/formatters.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:focus5/providers/theme_provider.dart';
import 'dart:math' as math;

class BadgeDetailScreen extends StatefulWidget {
  final AppBadge badge;

  const BadgeDetailScreen({super.key, required this.badge});

  @override
  State<BadgeDetailScreen> createState() => _BadgeDetailScreenState();
}

class _BadgeDetailScreenState extends State<BadgeDetailScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _borderAnimation;
  
  @override
  void initState() {
    super.initState();
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
      final name = widget.badge.name.toLowerCase();
      if (name.contains('streak') || name.contains('day')) return Icons.calendar_month;
      if (name.contains('audio')) return Icons.headphones;
      if (name.contains('course')) return Icons.school;
      if (name.contains('level')) return Icons.trending_up;
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
                
                // Badge Name with icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        getBadgeTypeIcon(),
                        color: accentColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.badge.name,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      textAlign: TextAlign.center,
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
                          color: accentColor.withOpacity(isDarkMode ? 0.1 : 0.05),
                          blurRadius: 15,
                          spreadRadius: 0,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: accentColor.withOpacity(isDarkMode ? 0.3 : 0.1),
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
                                color: accentColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.info_outline,
                                color: accentColor,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Badge Details',
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
                          accentColor,
                          textColor,
                          secondaryTextColor,
                        ),
                        
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Divider(
                            color: isDarkMode 
                                ? Colors.grey.shade800 
                                : Colors.grey.shade300,
                          ),
                        ),
                        
                        // Earned Date
                        _buildDetailRow(
                          context, 
                          'Earned On', 
                          widget.badge.earnedAt != null 
                              ? Formatters.formatDate(widget.badge.earnedAt!) 
                              : 'Not yet earned',
                          Icons.calendar_today_rounded,
                          isDarkMode,
                          accentColor,
                          textColor,
                          secondaryTextColor,
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Add progress section for badges that track completion
                        if (_shouldShowProgressSection())
                          _buildProgressSection(
                            context, 
                            theme, 
                            isDarkMode, 
                            accentColor,
                            textColor,
                            secondaryTextColor,
                          ),
                      ],
                    ),
                  ),
                ),
                
                // Add "How to Earn" section for unearnerd badges
                if (widget.badge.earnedAt == null)
                  _buildHowToEarnSection(context, theme, isDarkMode, accentColor, textColor, secondaryTextColor),
                
                // Pad the bottom for better visual spacing and scrolling
                SizedBox(height: MediaQuery.of(context).padding.bottom + 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildBadgeImage(bool isDarkMode, Color accentColor) {
    final badgeSize = 180.0;
    final borderWidth = 3.0;
    
    return Hero(
      tag: 'badge_${widget.badge.id}',
      child: Container(
        height: badgeSize,
        width: badgeSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(isDarkMode ? 0.4 : 0.2),
              blurRadius: 25,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Badge image with fallback
            Positioned.fill(
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: _getBadgeImageUrl(),
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade200,
                    child: Center(child: 
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade200,
                    child: Center(
                      child: Icon(
                        _getBadgeIconFromName(),
                        color: accentColor,
                        size: 70,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // Animated border only (no shimmer on the whole badge)
            AnimatedBuilder(
              animation: _borderAnimation,
              builder: (context, child) {
                return Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: NeonBorderPainter(
                        color: accentColor,
                        strokeWidth: borderWidth,
                        progress: _borderAnimation.value,
                        isDarkMode: isDarkMode,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  String _getBadgeImageUrl() {
    // Try badgeImage first, then imageUrl
    if (widget.badge.badgeImage != null && widget.badge.badgeImage!.isNotEmpty) {
      return widget.badge.badgeImage!;
    }
    
    // Fallback to imageUrl
    return widget.badge.imageUrl;
  }
  
  IconData _getBadgeIconFromName() {
    final name = widget.badge.name.toLowerCase();
    if (name.contains('audio')) return Icons.headphones;
    if (name.contains('streak')) return Icons.local_fire_department;
    if (name.contains('course')) return Icons.school;
    if (name.contains('level')) return Icons.trending_up;
    if (name.contains('complete')) return Icons.check_circle;
    return Icons.emoji_events;
  }
  
  bool _shouldShowProgressSection() {
    final name = widget.badge.name.toLowerCase();
    return name.contains('level') || 
           name.contains('streak') || 
           name.contains('progress') ||
           name.contains('day');
  }
  
  Widget _buildDetailRow(
    BuildContext context, 
    String label, 
    String value, 
    IconData icon,
    bool isDarkMode,
    Color accentColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    final theme = Theme.of(context);
    final valueColor = label == 'XP Value' ? accentColor : textColor;
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: accentColor, size: 22),
        ),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
            color: secondaryTextColor,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
  
  Widget _buildProgressSection(
    BuildContext context, 
    ThemeData theme, 
    bool isDarkMode, 
    Color accentColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    // Example values - in a real app, these would come from the badge data
    final name = widget.badge.name.toLowerCase();
    final int achievedDays = name.contains('streak') ? 14 : 270; 
    final int targetDays = name.contains('streak') ? 30 : 365;
    final double progress = achievedDays / targetDays;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Stack(
          children: [
            // Background
            Container(
              height: 12,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            // Progress with glow effect
            Container(
              height: 12,
              width: MediaQuery.of(context).size.width * progress * 0.8, // Approximate width adjustment
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  colors: [
                    accentColor,
                    accentColor.withOpacity(0.8),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 0,
                  )
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '$achievedDays / $targetDays ${name.contains("streak") ? "days streak" : "days"}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: secondaryTextColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHowToEarnSection(
    BuildContext context,
    ThemeData theme,
    bool isDarkMode,
    Color accentColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 32, left: 20, right: 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey.shade900.withOpacity(0.5) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: accentColor.withOpacity(0.2),
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
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.lightbulb_outline,
                    color: accentColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'How to Earn',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildRequirementRow(
              context, 
              'Complete the required activities',
              Icons.check_circle_outline,
              accentColor,
              textColor,
            ),
            const SizedBox(height: 12),
            _buildRequirementRow(
              context, 
              'Maintain consistent engagement',
              Icons.trending_up,
              accentColor,
              textColor,
            ),
            const SizedBox(height: 12),
            _buildRequirementRow(
              context, 
              'Earn XP through completing sessions',
              Icons.star_outline,
              accentColor,
              textColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirementRow(
    BuildContext context,
    String text,
    IconData icon,
    Color accentColor,
    Color textColor,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: accentColor,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }
}

// Custom painter for animated neon-style border
class NeonBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double progress;
  final bool isDarkMode;
  
  NeonBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.progress,
    required this.isDarkMode,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    
    final glowWidth = strokeWidth * 2;
    
    // Create path for the full circle
    final circlePath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    
    // Calculate the animation angle based on progress
    final angle = 2 * math.pi * progress;
    
    // Main border stroke path with partial sweep depending on animation
    // Only draw this if progress is at least a tiny amount (avoid flicker at beginning)
    if (progress > 0.05) {
      final borderPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      
      final path = Path();
      path.addArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        -math.pi / 2, // Start from top
        angle,
      );
      
      canvas.drawPath(path, borderPaint);
      
      // Outer glow
      final glowPaint = Paint()
        ..color = color.withOpacity(isDarkMode ? 0.5 : 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = glowWidth
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      
      canvas.drawPath(path, glowPaint);
    }
  }
  
  @override
  bool shouldRepaint(NeonBorderPainter oldDelegate) => 
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth;
} 