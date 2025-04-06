import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:transparent_image/transparent_image.dart';

import '../../providers/theme_provider.dart';
import '../../providers/content_provider.dart';
import '../../models/content_models.dart';
import '../../services/paywall_service.dart';
import 'course_detail_screen.dart';

class AllCoursesScreen extends StatefulWidget {
  const AllCoursesScreen({Key? key}) : super(key: key);

  @override
  State<AllCoursesScreen> createState() => _AllCoursesScreenState();
}

class _AllCoursesScreenState extends State<AllCoursesScreen> {
  bool _isLoading = true;
  String? _selectedCategory;
  List<String> _categories = ['All', 'Focus', 'Performance', 'Recovery', 'Mindfulness'];

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }
  
  Future<void> _loadCourses() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Ensure courses are loaded in the provider
      final contentProvider = Provider.of<ContentProvider>(context, listen: false);
      if (contentProvider.courses.isEmpty) {
        await contentProvider.initContent(null);
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  List<Course> _getFilteredCourses() {
    final contentProvider = Provider.of<ContentProvider>(context, listen: false);
    final allCourses = contentProvider.courses;
    
    if (_selectedCategory == null || _selectedCategory == 'All') {
      return allCourses;
    }
    
    return allCourses.where((course) {
      return course.focusAreas.contains(_selectedCategory) ||
             course.title.toLowerCase().contains(_selectedCategory!.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final contentProvider = Provider.of<ContentProvider>(context);
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).colorScheme.onBackground;
    final isDarkMode = themeProvider.isDarkMode;
    
    final filteredCourses = _getFilteredCourses();
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'All Courses',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: themeProvider.accentColor))
          : contentProvider.courses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.school_outlined, size: 48, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'No Courses Available',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Check back later for new courses',
                        style: TextStyle(color: textColor.withOpacity(0.7)),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Categories filter
                    Container(
                      height: 60,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          final isSelected = category == _selectedCategory;
                          
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(category),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedCategory = selected ? category : null;
                                });
                              },
                              backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                              selectedColor: themeProvider.accentColor,
                              labelStyle: TextStyle(
                                color: isSelected 
                                    ? (isDarkMode ? Colors.black : Colors.white) 
                                    : textColor,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    // Courses grid
                    Expanded(
                      child: filteredCourses.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_off, size: 48, color: Colors.grey),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No Courses Found',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Try a different category',
                                    style: TextStyle(color: textColor.withOpacity(0.7)),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadCourses,
                              color: themeProvider.accentColor,
                              child: GridView.builder(
                                padding: const EdgeInsets.all(16),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.75,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                                itemCount: filteredCourses.length,
                                itemBuilder: (context, index) {
                                  final course = filteredCourses[index];
                                  return _buildCourseCard(course);
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }
  
  Widget _buildCourseCard(Course course) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final textColor = Theme.of(context).colorScheme.onBackground;
    final isDarkMode = themeProvider.isDarkMode;
    
    return GestureDetector(
      onTap: () async {
        final paywallService = PaywallService();
        final canAccess = await paywallService.checkAccess();
        
        if (!canAccess && course.premium) {
          Navigator.pushNamed(context, '/paywall');
          return;
        }
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CourseDetailScreen(
              courseId: course.id,
              course: course,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: FadeInImage.memoryNetwork(
                    placeholder: kTransparentImage,
                    image: course.imageUrl,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    imageErrorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 120,
                        width: double.infinity,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image, color: Colors.grey),
                      );
                    },
                  ),
                ),
                if (course.premium)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade800,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star,
                            color: Colors.white,
                            size: 12,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Premium',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Course title
                  Text(
                    course.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Course meta info (lessons, duration)
                  Row(
                    children: [
                      Icon(
                        Icons.play_circle_outline,
                        size: 14,
                        color: textColor.withOpacity(0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${course.modules.length}',
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: textColor.withOpacity(0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${course.duration}m',
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Progress indicator
                  LinearProgressIndicator(
                    value: 0.0, // No progress initially
                    backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(themeProvider.accentColor),
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