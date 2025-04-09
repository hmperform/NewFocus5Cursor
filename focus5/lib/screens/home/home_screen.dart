import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/content_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/media_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/chat_provider.dart';
import '../../constants/theme.dart';
import '../../services/basic_video_service.dart';
import '../auth/login_screen.dart';
import 'dashboard_tab.dart';
import 'explore_tab.dart';
import '../chat/chat_list_screen.dart';
import 'profile_tab.dart';
import 'more_tab.dart';
import 'media_tab.dart';
import 'journal_search_screen.dart';
import '../../widgets/basic_mini_player.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isInitializing = false;
  bool _hasError = false;
  
  late TabController _tabController;
  
  // The bottom navigation items
  final List<BottomNavigationBarItem> _bottomNavItems = const [
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
  ];
  
  // All tabs to display
  final List<Widget> _tabs = [
    const DashboardTab(),
    const ExploreTab(),
    const ChatListScreen(),
    const ProfileTab(),
    const MoreTab(),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    
    // Initialize content and media providers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      try {
        final mediaProvider = Provider.of<MediaProvider>(context, listen: false);
        final contentProvider = Provider.of<ContentProvider>(context, listen: false);
        
        setState(() {
          _isInitializing = true;
        });
        
        // Initialize content
        contentProvider.initContent(null).then((_) {
          // Initialize media with cached state
          return mediaProvider.initializeMedia();
        }).then((_) {
          if (mounted) {
            setState(() {
              _isInitializing = false;
              _hasError = false;
            });
          }
        }).catchError((error) {
          debugPrint('Error initializing data: $error');
          if (mounted) {
            setState(() {
              _isInitializing = false;
              _hasError = true;
            });
          }
        });
      } catch (e) {
        debugPrint('Error in initialization: $e');
        if (mounted) {
          setState(() {
            _isInitializing = false;
            _hasError = true;
          });
        }
      }
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final mediaProvider = Provider.of<MediaProvider>(context, listen: false);
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Tab content
          IndexedStack(
            index: _currentIndex,
            children: _tabs,
          ),
          
          // Mini player - positioned at the bottom above the nav bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Consumer<BasicVideoService>(
              builder: (context, videoService, _) {
                if (videoService.showMiniPlayer) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: kBottomNavigationBarHeight),
                    child: const BasicMiniPlayer(),
                  );
                } else {
                  return const SizedBox.shrink();
                }
              },
            ),
          ),
        ],
      ),
      
      // Bottom navigation
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: themeProvider.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        selectedItemColor: themeProvider.accentColor,
        unselectedItemColor: themeProvider.isDarkMode ? Colors.white54 : Colors.black54,
        items: _bottomNavItems,
      ),
    );
  }
} 