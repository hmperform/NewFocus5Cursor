import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/theme_provider.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/settings/settings_screen.dart';

class StatusBar extends StatelessWidget {
  const StatusBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accentColor = themeProvider.accentColor;
    final user = userProvider.user;
    
    if (user == null) return const SizedBox.shrink();
    
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius:
             8, 
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Settings button
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            tooltip: 'Settings',
          ),
          
          // Spacer
          const Spacer(),
          
          // Streak indicator
          _buildStatusItem(
            icon: Icons.local_fire_department,
            value: '${user.streak}',
            color: Colors.orange,
            tooltip: '${user.streak} day streak',
          ),
          
          const SizedBox(width: 16),
          
          // Focus Points indicator 
          InkWell(
            onTap: () {
              // Show focus points purchase modal
              _showFocusPointsDialog(context);
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Image.asset(
                    'assets/icons/focuspointicon-removebg-preview.png',
                    width: 20,
                    height: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${user.focusPoints}',
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatusItem({
    required IconData icon, 
    required String value, 
    required Color color,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showFocusPointsDialog(BuildContext context) {
    // This method will show a modal to purchase focus points
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Get Focus Points',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Use Focus Points to unlock premium courses',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            _buildFocusPointPackage(
              points: 5,
              price: '\$2.99',
              context: context,
            ),
            const SizedBox(height: 12),
            _buildFocusPointPackage(
              points: 20,
              price: '\$9.99',
              context: context,
              isBestValue: true,
            ),
            const SizedBox(height: 12),
            _buildFocusPointPackage(
              points: 50,
              price: '\$19.99',
              context: context,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFocusPointPackage({
    required int points,
    required String price,
    required BuildContext context,
    bool isBestValue = false,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final accentColor = themeProvider.accentColor;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isBestValue ? accentColor : Colors.grey.withOpacity(0.3),
          width: isBestValue ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon with points
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isBestValue 
                    ? accentColor.withOpacity(0.2) 
                    : Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    '$points',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isBestValue ? accentColor : Colors.grey[800],
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Image.asset(
                      'assets/icons/focuspointicon-removebg-preview.png',
                      width: 18,
                      height: 18,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Points text and price
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '$points Focus Points',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isBestValue) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'BEST VALUE',
                            style: TextStyle(
                              color: themeProvider.accentTextColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    price,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            // Purchase button
            ElevatedButton(
              onPressed: () {
                // Purchase logic would go here
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: themeProvider.accentTextColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              child: const Text('Buy'),
            ),
          ],
        ),
      ),
    );
  }
} 