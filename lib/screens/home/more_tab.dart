import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:provider/provider.dart';
import '../more/games_screen.dart';
import '../more/journal_screen.dart';
import '../media/media_library_screen.dart';
import '../more/partner_admin_screen.dart';
import '../../providers/theme_provider.dart';
import '../../providers/user_provider.dart';
import '../../constants/theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MoreTab extends StatefulWidget {
  const MoreTab({Key? key}) : super(key: key);

  @override
  State<MoreTab> createState() => _MoreTabState();
}

class _MoreTabState extends State<MoreTab> {
  bool _isPartnerChampion = false;
  bool _isPartnerCoach = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
        
        setState(() {
          _isPartnerChampion = userDoc.data()?['isPartnerChampion'] ?? false;
          _isPartnerCoach = userDoc.data()?['isPartnerCoach'] ?? false;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    // Theme-aware colors
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final cardBackgroundColor = Theme.of(context).colorScheme.surface;
    final accentColor = themeProvider.accentColor;
    final textColor = Theme.of(context).colorScheme.onBackground;
    final secondaryTextColor = themeProvider.secondaryTextColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'More',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: accentColor))
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main categories with icons
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        // Games
                        _buildMenuItem(
                          context,
                          'Mind Games',
                          Icons.games,
                          Colors.blue.shade300,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const GamesScreen(),
                              ),
                            );
                          },
                        ),
                        
                        // Journal
                        _buildMenuItem(
                          context,
                          'Journal',
                          Icons.book,
                          Colors.orange.shade300,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const JournalScreen(),
                              ),
                            );
                          },
                        ),
                        
                        // Media Library
                        _buildMenuItem(
                          context,
                          'Media Library',
                          Icons.library_music,
                          Colors.green.shade300,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MediaLibraryScreen(),
                              ),
                            );
                          },
                        ),
                        
                        // Partner Admin (only for champions and coaches)
                        if (_isPartnerChampion || _isPartnerCoach)
                          _buildMenuItem(
                            context,
                            'Partner Admin',
                            Icons.admin_panel_settings,
                            Colors.purple.shade300,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const PartnerAdminScreen(),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
  
  Widget _buildMenuItem(
    BuildContext context,
    String title,
    IconData icon,
    Color iconColor,
    VoidCallback onTap,
  ) {
    final cardColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onBackground;
    
    return Card(
      color: cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: iconColor,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 