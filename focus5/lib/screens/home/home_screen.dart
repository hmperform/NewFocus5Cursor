import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/content_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/audio_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/chat_provider.dart';
import '../../constants/theme.dart';
import '../auth/login_screen.dart';
import 'dashboard_tab.dart';
import 'explore_tab.dart';
import 'dms_tab.dart';
import 'profile_tab.dart';
import 'more_tab.dart';
import 'journal_search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _isInitialized = false;
  bool _isLoading = true;
  
  final List<Widget> _tabs = [
    const DashboardTab(),
    const ExploreTab(),
    const DMsTab(),
    const ProfileTab(),
    const MoreTab(),
  ];

  @override
  void initState() {
    super.initState();
    // Schedule initialization after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    if (_isInitialized) return;
    
    setState(() {
      _isLoading = true;
    });

    // Get the necessary providers
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final contentProvider = Provider.of<ContentProvider>(context, listen: false);
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    // For now, we'll assume the user is logged in since we haven't implemented auth yet
    // if (!authProvider.isLoggedIn) {
    //   Navigator.of(context).pushReplacement(
    //     MaterialPageRoute(builder: (context) => const LoginScreen()),
    //   );
    //   return;
    // }

    // Initialize data
    try {
      // For now, we'll skip initialization since we haven't implemented these methods yet
      // await Future.wait([
      //   userProvider.initializeUser(),
      //   contentProvider.initializeContent(),
      //   audioProvider.initializeAudio(),
      // ]);

      setState(() {
        _isInitialized = true;
        _isLoading = false;
      });
    } catch (e) {
      // Handle initialization error
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onNavTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onBackground;
    final accentColor = themeProvider.accentColor;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: _currentIndex == 0 
            ? AppBar(
                automaticallyImplyLeading: false,
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: IconButton(
                  icon: Icon(
                    Icons.settings,
                    color: textColor,
                  ),
                  onPressed: () {
                    // Settings functionality
                  },
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.search, color: textColor),
                    onPressed: () {
                      setState(() {
                        _currentIndex = 1;
                      });
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.notifications_none, color: textColor),
                    onPressed: () {
                      // Notifications
                    },
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 16.0),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Stack(
                      children: [
                        IconButton(
                          icon: Icon(Icons.local_fire_department, color: accentColor),
                          onPressed: () {
                            // Streak/fire functionality
                          },
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: accentColor,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '1',
                              style: TextStyle(
                                color: themeProvider.accentTextColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : _currentIndex == 1 || _currentIndex == 4
                ? null
                : AppBar(
                    automaticallyImplyLeading: false,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    title: Text(
                      _currentIndex == 2 ? 'Messages' : 'Profile',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _tabs[_currentIndex],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _onNavTapped,
          backgroundColor: surfaceColor,
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore),
              label: 'Explore',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_outlined),
              selectedIcon: Icon(Icons.chat),
              label: 'DMs',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
            NavigationDestination(
              icon: Icon(Icons.more_horiz),
              selectedIcon: Icon(Icons.more_horiz),
              label: 'More',
            ),
          ],
        ),
      ),
    );
  }
} 