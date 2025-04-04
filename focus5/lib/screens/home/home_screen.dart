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
    const DMsTab(),
    const ProfileTab(),
    const MoreTab(),
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize tab controller with 5 tabs for the More tab
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentIndex = _tabController.index;
        });
      }
    });
    
    // Schedule initialization AFTER the first frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Let the dashboard tab handle its own content loading
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Simple scaffold with bottom navigation - no complex state management
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _currentIndex,
          children: _tabs,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                  _tabController.animateTo(index);
                });
              },
              backgroundColor: Colors.transparent,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: const Color(0xFFB4FF00),
              unselectedItemColor: Colors.grey,
              showUnselectedLabels: true,
              elevation: 0,
              items: _bottomNavItems,
            ),
          ),
        ),
      ),
    );
  }
} 