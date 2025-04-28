import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/content_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/content_models.dart';
import '../../widgets/course/course_card.dart'; // Assuming CourseCard can be reused

class AllCoursesScreen extends StatefulWidget {
  const AllCoursesScreen({Key? key}) : super(key: key);

  @override
  _AllCoursesScreenState createState() => _AllCoursesScreenState();
}

class _AllCoursesScreenState extends State<AllCoursesScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Course> _allCourses = [];
  List<Course> _filteredCourses = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCourses();
    _searchController.addListener(_filterCourses);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterCourses);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    final contentProvider = Provider.of<ContentProvider>(context, listen: false);
    // Assuming initContent handles loading if courses aren't already loaded
    await contentProvider.initContent(null); 
    if (mounted) {
      setState(() {
        _allCourses = contentProvider.courses;
        _filteredCourses = _allCourses;
        _isLoading = false;
      });
    }
  }

  void _filterCourses() {
    final query = _searchController.text.toLowerCase();
    if (query == _searchQuery) return; // Avoid redundant filtering

    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredCourses = _allCourses;
      } else {
        _filteredCourses = _allCourses.where((course) {
          final titleMatch = course.title.toLowerCase().contains(query);
          final descriptionMatch = course.description.toLowerCase().contains(query);
          final creatorMatch = course.creatorName.toLowerCase().contains(query);
          final tagsMatch = course.tags.any((tag) => tag.toLowerCase().contains(query));
          final focusAreaMatch = course.focusAreas.any((area) => area.toLowerCase().contains(query));
          return titleMatch || descriptionMatch || creatorMatch || tagsMatch || focusAreaMatch;
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final textColor = Theme.of(context).colorScheme.onBackground;
    final hintColor = Theme.of(context).hintColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Courses'),
        backgroundColor: themeProvider.accentColor,
        elevation: 1,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search courses by title, creator, tag...',
                hintStyle: TextStyle(color: hintColor.withOpacity(0.6)),
                prefixIcon: Icon(Icons.search, color: hintColor),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
              ),
              style: TextStyle(color: textColor),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCourses.isEmpty
                    ? Center(
                        child: Text(
                          _searchQuery.isEmpty
                              ? 'No courses available.'
                              : 'No courses found matching "$_searchQuery"',
                          style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                        itemCount: _filteredCourses.length,
                        itemBuilder: (context, index) {
                          final course = _filteredCourses[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: CourseCard(
                              course: course,
                              isPurchased: userProvider.hasPurchasedCourse(course.id),
                              description: course.description,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
} 