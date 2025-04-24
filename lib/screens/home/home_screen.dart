import 'package:flutter/material.dart';
import 'package:focus5/screens/courses/courses_tab.dart';
import 'package:focus5/screens/home/home_tab.dart';
import 'package:focus5/screens/media/media_library_screen.dart';
import 'package:focus5/screens/profile/profile_tab.dart';
// import 'package:focus5/screens/home/more_tab.dart'; // REMOVE if exists

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ... potentially existing state ...

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4, // <<< CHANGE length back to 4
      child: Scaffold(
        body: TabBarView(
          children: [
            HomeTab(),        
            CoursesTab(),     
            MediaLibraryScreen(), // <<< ADD MediaLibraryScreen as 3rd tab
            ProfileTab(),     // <<< USE ProfileTab as 4th tab
          ],
        ),
        bottomNavigationBar: const TabBar( 
          tabs: [
            Tab(icon: Icon(Icons.home), text: 'Home'),
            Tab(icon: Icon(Icons.school), text: 'Courses'),
            Tab(icon: Icon(Icons.library_music), text: 'Media'), // <<< ADD Media tab back
            Tab(icon: Icon(Icons.person), text: 'Profile'), // <<< Change back to Profile tab
          ],
          labelColor: Colors.blue, 
          unselectedLabelColor: Colors.grey,
          indicatorSize: TabBarIndicatorSize.label,
          indicatorPadding: EdgeInsets.all(5.0),
          indicatorColor: Colors.blue,
        ),
      ),
    );
  }
} 