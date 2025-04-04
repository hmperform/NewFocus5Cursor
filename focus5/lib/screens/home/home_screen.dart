import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  int _currentIndex = 0;
  bool _isInitialized = false;
  bool _isLoading = true;
  bool _isCriticalDataLoaded = false;
  DateTime? _lastContentRefresh;
  
  final List<Widget> _tabs = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeTabs();
    // Schedule initialization after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  void _initializeTabs() {
    _tabs.add(const DashboardTab());
    _tabs.add(const ExploreTab());
    _tabs.add(const DMsTab());
    _tabs.add(const ProfileTab());
    _tabs.add(const MoreTab());
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

    // Check when we last refreshed content
    final prefs = await SharedPreferences.getInstance();
    final lastRefreshStr = prefs.getString('last_content_refresh');
    if (lastRefreshStr != null) {
      _lastContentRefresh = DateTime.parse(lastRefreshStr);
    }

    // Initialize critical data first
    try {
      // Load cached user data if available
      final cachedUserData = prefs.getString('cached_user_data');
      if (cachedUserData != null) {
        // Parse and set cached user data
        // In a real app, you would deserialize the JSON data
        // For now, we'll use the demo implementation
      }
      
      // Load cached content data if available
      final cachedContentData = prefs.getString('cached_content_data');
      if (cachedContentData != null && !_shouldRefreshContent()) {
        // Parse and set cached content data
        // In a real app, you would deserialize the JSON data
      } else {
        // Initialize only essential content for immediate display
        await contentProvider.initContent(null);
        
        // Save the refresh timestamp
        await prefs.setString('last_content_refresh', DateTime.now().toIso8601String());
        
        // Cache the content data
        // In a real app, you would serialize the data to JSON
        // await prefs.setString('cached_content_data', serializedContentData);
      }

      setState(() {
        _isCriticalDataLoaded = true;
        _isLoading = false;
      });

      // Load non-critical data in the background
      _loadRemainingDataInBackground();
    } catch (e) {
      // Handle initialization error
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _shouldRefreshContent() {
    if (_lastContentRefresh == null) return true;
    
    // Refresh content if it's been more than 6 hours
    final now = DateTime.now();
    final difference = now.difference(_lastContentRefresh!);
    return difference.inHours > 6;
  }

  Future<void> _loadRemainingDataInBackground() async {
    // Load non-essential data that doesn't block UI
    final contentProvider = Provider.of<ContentProvider>(context, listen: false);
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    
    try {
      // Load articles, coaches, etc.
      await contentProvider.loadArticles();
      await contentProvider.loadCoaches();
      
      // Initialize audio content
      if (audioProvider.currentAudio == null) {
        await audioProvider.initializeAudio();
      }
      
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('Error loading background data: ${e.toString()}');
    }
  }

  void _onNavTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onBackground;
    final accentColor = themeProvider.accentColor;

    if (_isLoading && !_isCriticalDataLoaded) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              ),
              const SizedBox(height: 16),
              Text(
                "Loading your experience...",
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: surfaceColor,
        selectedItemColor: accentColor,
        unselectedItemColor: textColor.withOpacity(0.5),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_rounded),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.forum_rounded),
            label: 'DMs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz_rounded),
            label: 'More',
          ),
        ],
      ),
    );
  }
} 