import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:transparent_image/transparent_image.dart';

import '../../providers/content_provider.dart';
import '../../providers/theme_provider.dart';
import '../../constants/theme.dart';
import '../../models/content_models.dart';
import 'course_detail_screen.dart';
import '../../utils/image_utils.dart';
import '../../utils/app_icons.dart';

class CoursesTab extends StatefulWidget {
  const CoursesTab({Key? key}) : super(key: key);

  @override
  State<CoursesTab> createState() => _CoursesTabState();
}

class _CoursesTabState extends State<CoursesTab> {
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Mental Toughness', 'Focus Training', 'Motivation', 'Team Dynamics', 'Leadership'];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final contentProvider = Provider.of<ContentProvider>(context, listen: false);
      if (contentProvider.courses.isEmpty) {
        contentProvider.initContent(null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final contentProvider = Provider.of<ContentProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final courses = contentProvider.courses;
    final isLoading = contentProvider.isLoading;
    
    // Get theme-aware colors
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final accentColor = themeProvider.accentColor;
    final textColor = Theme.of(context).colorScheme.onBackground;
    final secondaryTextColor = themeProvider.secondaryTextColor;
    
    // Filter courses based on selected category and search query
    List<Course> filteredCourses = courses;
    if (_selectedCategory != 'All') {
      filteredCourses = filteredCourses.where(
        (course) => course.focusAreas.any((area) => 
          area.toLowerCase().contains(_selectedCategory.toLowerCase()) ||
          _selectedCategory.toLowerCase().contains(area.toLowerCase())
        )
      ).toList();
    }
    
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filteredCourses = filteredCourses.where(
        (course) => 
          course.title.toLowerCase().contains(query) ||
          course.description.toLowerCase().contains(query) ||
          course.creatorName.toLowerCase().contains(query) ||
          course.tags.any((tag) => tag.toLowerCase().contains(query))
      ).toList();
    }
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: _searchQuery.isEmpty ? 
          Text(
            'Courses',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ) :
          TextField(
            controller: _searchController,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: 'Search courses...',
              hintStyle: TextStyle(color: secondaryTextColor),
              border: InputBorder.none,
              suffixIcon: IconButton(
                icon: Icon(Icons.clear, color: secondaryTextColor),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                  FocusScope.of(context).unfocus();
                },
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        actions: [
          IconButton(
            icon: Icon(
              _searchQuery.isEmpty ? Icons.search : Icons.cancel,
              color: textColor,
            ),
            onPressed: () {
              setState(() {
                if (_searchQuery.isNotEmpty) {
                  _searchController.clear();
                  _searchQuery = '';
                  FocusScope.of(context).unfocus();
                } else {
                  FocusScope.of(context).requestFocus(FocusNode());
                  _searchController.selection = TextSelection.fromPosition(
                    TextPosition(offset: _searchController.text.length),
                  );
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Category tabs
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? accentColor : surfaceColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? themeProvider.accentTextColor : textColor,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Courses grid
          Expanded(
            child: isLoading 
              ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  ),
                )
              : filteredCourses.isEmpty
                ? _buildEmptyState()
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: filteredCourses.length,
                      itemBuilder: (context, index) {
                        final course = filteredCourses[index];
                        return _buildCourseCard(context, course);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accentColor = themeProvider.accentColor;
    final textColor = Theme.of(context).colorScheme.onBackground;
    final secondaryTextColor = themeProvider.secondaryTextColor;
    
    if (_searchQuery.isNotEmpty || _selectedCategory != 'All') {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              color: accentColor,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'No courses found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: secondaryTextColor,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedCategory = 'All';
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: themeProvider.accentTextColor,
              ),
              child: const Text('Reset Filters'),
            ),
          ],
        ),
      );
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school,
            size: 100,
            color: accentColor.withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          Text(
            'Courses Coming Soon',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Access video courses from mental performance experts to improve your game',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: secondaryTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCourseCard(BuildContext context, Course course) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final textColor = Theme.of(context).colorScheme.onBackground;
    final secondaryTextColor = themeProvider.secondaryTextColor;
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CourseDetailScreen(
              courseId: course.id,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course thumbnail
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: FadeInImage.memoryNetwork(
                    placeholder: kTransparentImage,
                    image: course.thumbnailUrl,
                    fit: BoxFit.cover,
                    imageErrorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Theme.of(context).colorScheme.surface,
                        child: Icon(
                          Icons.image_not_supported,
                          color: secondaryTextColor,
                          size: 48,
                        ),
                      );
                    },
                  ),
                ),
                
                // Course level/tag badge
                if (course.tags.isNotEmpty)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        course.tags.first,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                
                // Focus Points Cost Badge
                if (course.focusPointsCost > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: themeProvider.accentColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppIcons.getFocusPointIcon(
                            width: 12,
                            height: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${course.focusPointsCost}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // Creator badge
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: FadeInImage.memoryNetwork(
                        placeholder: kTransparentImage,
                        image: course.creatorImageUrl,
                        fit: BoxFit.cover,
                        imageErrorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.person,
                            color: secondaryTextColor,
                            size: 18,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Course info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    course.title,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  
                  // Creator name
                  Text(
                    course.creatorName,
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  
                  // Duration
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: secondaryTextColor,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${course.durationMinutes ~/ 60}h ${course.durationMinutes % 60}m',
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 