import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/badge_model.dart';
import '../../providers/badge_provider.dart';
import '../../services/badge_service.dart';

class AllBadgesScreen extends StatelessWidget {
  const AllBadgesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'All Badges',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<BadgeProvider>(
        builder: (context, badgeProvider, child) {
          final earnedBadges = badgeProvider.earnedBadges;
          final availableBadges = badgeProvider.availableBadges;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Achievements',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'You have earned ${earnedBadges.length} out of ${availableBadges.length} badges',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Earned Badges Section
                if (earnedBadges.isNotEmpty) ...[
                  const Text(
                    'Earned Badges',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFB4FF00),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: earnedBadges.length,
                    itemBuilder: (context, index) {
                      final badge = earnedBadges[index];
                      return _buildBadgeItem(badge, true);
                    },
                  ),
                  const SizedBox(height: 32),
                ],
                
                // Available Badges Section
                const Text(
                  'Available Badges',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: availableBadges.length,
                  itemBuilder: (context, index) {
                    final badge = availableBadges[index];
                    final bool isEarned = earnedBadges.any((earned) => earned.id == badge.id);
                    return _buildBadgeItem(badge, isEarned);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildBadgeItem(BadgeModel badge, bool isEarned) {
    String criteriaText = '';
    
    switch (badge.criteriaType) {
      case BadgeCriteriaType.courseCompletions:
        criteriaText = '${badge.requiredCount} courses';
        break;
      case BadgeCriteriaType.audioCompletions:
        criteriaText = '${badge.requiredCount} audio sessions';
        break;
      case BadgeCriteriaType.sessionCount:
        criteriaText = '${badge.requiredCount} sessions';
        break;
      case BadgeCriteriaType.sessionStreak:
        criteriaText = '${badge.requiredCount} day streak';
        break;
      case BadgeCriteriaType.totalMinutes:
        criteriaText = '${badge.requiredCount} minutes';
        break;
      case BadgeCriteriaType.journalEntries:
        criteriaText = '${badge.requiredCount} journal entries';
        break;
    }
    
    return GestureDetector(
      onTap: () => _showBadgeDetails(badge, isEarned),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isEarned ? const Color(0xFFB4FF00) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isEarned ? const Color(0xFF2A2A2A) : Colors.black26,
                    border: Border.all(
                      color: isEarned ? const Color(0xFFB4FF00) : Colors.white24,
                      width: 2,
                    ),
                  ),
                  child: isEarned
                      ? Image.asset(
                          badge.imageUrl,
                          width: 40,
                          height: 40,
                        )
                      : ColorFiltered(
                          colorFilter: const ColorFilter.matrix([
                            0.2, 0.2, 0.2, 0, 0,
                            0.2, 0.2, 0.2, 0, 0,
                            0.2, 0.2, 0.2, 0, 0,
                            0, 0, 0, 0.5, 0,
                          ]),
                          child: Image.asset(
                            badge.imageUrl,
                            width: 40,
                            height: 40,
                          ),
                        ),
                ),
                if (!isEarned)
                  const Icon(
                    Icons.lock,
                    color: Colors.white38,
                    size: 20,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                badge.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isEarned ? FontWeight.bold : FontWeight.normal,
                  color: isEarned ? Colors.white : Colors.white70,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                criteriaText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white38,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showBadgeDetails(BadgeModel badge, bool isEarned) {
    final BuildContext context = navigatorKey.currentContext!;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isEarned ? const Color(0xFF2A2A2A) : Colors.black26,
                  border: Border.all(
                    color: isEarned ? const Color(0xFFB4FF00) : Colors.white24,
                    width: 2,
                  ),
                ),
                child: isEarned
                    ? Image.asset(
                        badge.imageUrl,
                        width: 50,
                        height: 50,
                      )
                    : ColorFiltered(
                        colorFilter: const ColorFilter.matrix([
                          0.2, 0.2, 0.2, 0, 0,
                          0.2, 0.2, 0.2, 0, 0,
                          0.2, 0.2, 0.2, 0, 0,
                          0, 0, 0, 0.5, 0,
                        ]),
                        child: Image.asset(
                          badge.imageUrl,
                          width: 50,
                          height: 50,
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              Text(
                badge.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isEarned ? const Color(0xFFB4FF00).withOpacity(0.2) : Colors.white10,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isEarned ? 'Earned' : 'Locked',
                  style: TextStyle(
                    fontSize: 14,
                    color: isEarned ? const Color(0xFFB4FF00) : Colors.white38,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                badge.description,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.star,
                    color: Color(0xFFB4FF00),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '+${badge.xpValue} XP when earned',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A2A2A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('CLOSE'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Global navigator key for accessing context
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>(); 