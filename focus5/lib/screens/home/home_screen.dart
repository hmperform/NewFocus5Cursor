import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/content_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/audio_provider.dart';
import '../auth/login_screen.dart';
import 'dashboard_tab.dart';
import 'explore_tab.dart';
import 'journal_tab.dart';
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
    const JournalTab(),
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

    // Load user data if authenticated
    if (authProvider.isAuthenticated && authProvider.currentUser != null) {
      // Set the user in the user provider
      userProvider.setUser(authProvider.currentUser!);
      
      // Load user-specific data
      await userProvider.loadUserData(authProvider.currentUser!.id);
      
      // Initialize content with university code if applicable
      final universityCode = authProvider.currentUser!.isIndividual 
          ? null 
          : authProvider.currentUser!.universityCode;
          
      await contentProvider.initContent(universityCode);
    }

    if (mounted) {
      setState(() {
        _isInitialized = true;
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
    // Check if user is authenticated
    final authProvider = Provider.of<AuthProvider>(context);
    final audioProvider = Provider.of<AudioProvider>(context);
    
    if (!authProvider.isAuthenticated) {
      // Redirect to login if not authenticated
      return const LoginScreen();
    }

    // Use WillPopScope to prevent navigating back
    return WillPopScope(
      onWillPop: () async => false, // Prevent back navigation
      child: Scaffold(
        backgroundColor: const Color(0xFF121212), // Dark background
        appBar: _currentIndex == 0 
            ? AppBar(
                automaticallyImplyLeading: false, // Remove back button
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: IconButton(
                  icon: const Icon(
                    Icons.settings,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    // Settings functionality
                  },
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.white),
                    onPressed: () {
                      // Navigate to explore tab with search active
                      setState(() {
                        _currentIndex = 1; // Explore tab
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_none, color: Colors.white),
                    onPressed: () {
                      // Notifications
                    },
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 16.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.local_fire_department, color: Color(0xFFB4FF00)),
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
                              color: const Color(0xFFB4FF00),
                              shape: BoxShape.circle,
                            ),
                            child: const Text(
                              '1',
                              style: TextStyle(
                                color: Colors.black,
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
                ? null // No app bar for explore or more tab as they have their own search header
                : AppBar(
                    automaticallyImplyLeading: false, // Remove back button
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    title: Text(
                      _currentIndex == 2 ? 'Journal' : 'Profile',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    actions: _currentIndex == 2 ? [
                      IconButton(
                        icon: const Icon(
                          Icons.search,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          // Navigate to journal search screen
                          Navigator.push(
                            context, 
                            MaterialPageRoute(
                              builder: (context) => JournalSearchScreen(
                                initialQuery: '',
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.filter_list,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          // Show filter options dialog
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Filter Entries'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.calendar_today),
                                    title: const Text('Date'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      // Filter by date logic
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.tag),
                                    title: const Text('Tags'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      // Filter by tags logic
                                    },
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ] : null,
                  ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFB4FF00)),
              ))
            : IndexedStack(
                index: _currentIndex,
                children: _tabs,
              ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 0,
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onNavTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: const Color(0xFF1A1A1A),
            selectedItemColor: const Color(0xFFB4FF00),
            unselectedItemColor: Colors.grey,
            showUnselectedLabels: true,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.explore_outlined),
                activeIcon: Icon(Icons.explore),
                label: 'Explore',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.book_outlined),
                activeIcon: Icon(Icons.book),
                label: 'Journal',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.menu_outlined),
                activeIcon: Icon(Icons.menu),
                label: 'More',
              ),
            ],
          ),
        ),
      ),
    );
  }
} 