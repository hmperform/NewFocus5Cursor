import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/content_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/content_models.dart';
import '../home/course_detail_screen.dart';
import '../../services/paywall_service.dart';
import '../../utils/app_icons.dart';
import 'package:transparent_image/transparent_image.dart';

class FocusAreaCoursesScreen extends StatefulWidget {
  final String focusArea;
  
  const FocusAreaCoursesScreen({
    Key? key,
    required this.focusArea,
  }) : super(key: key);

  @override
  State<FocusAreaCoursesScreen> createState() => _FocusAreaCoursesScreenState();
}

class _FocusAreaCoursesScreenState extends State<FocusAreaCoursesScreen> {
  List<Course> _courses = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadCourses();
  }
  
  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
    });
    
    final contentProvider = Provider.of<ContentProvider>(context, listen: false);
    final focusAreaCourses = contentProvider.getCoursesForFocusArea(widget.focusArea);
    
    setState(() {
      _courses = focusAreaCourses;
      _isLoading = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).colorScheme.onBackground;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: Text(
          widget.focusArea,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: themeProvider.accentColor,
              ),
            )
          : _courses.isEmpty
              ? _buildEmptyState()
              : _buildCoursesList(),
    );
  }
  
  Widget _buildEmptyState() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final textColor = Theme.of(context).colorScheme.onBackground;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 64,
              color: textColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No courses found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'We couldn\'t find any courses for "${widget.focusArea}". Try exploring other focus areas.',
              style: TextStyle(
                fontSize: 16,
                color: textColor.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeProvider.accentColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Explore Other Areas'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCoursesList() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8.0, bottom: 80),
      itemCount: _courses.length,
      itemBuilder: (context, index) {
        return _buildCourseCard(context, _courses[index]);
      },
    );
  }

  Widget _buildCourseCard(BuildContext context, Course course) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        elevation: 4.0,
        clipBehavior: Clip.antiAlias, 
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: InkWell(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    height: screenWidth * 0.4,
                    width: double.infinity,
                    child: course.imageUrl.isNotEmpty
                        ? FadeInImage.memoryNetwork(
                            placeholder: kTransparentImage,
                            image: course.imageUrl,
                            fit: BoxFit.cover,
                            imageErrorBuilder: (context, error, stackTrace) => 
                              Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.school, color: Colors.grey, size: 50),
                              ),
                          )
                        : Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.school, color: Colors.grey, size: 50),
                          ),
                  ),
                  if (course.premium)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade700,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 3, offset: Offset(0, 1))]
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Premium',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
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
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${course.lessonsList.length} Lessons',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (course.focusPointsCost > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: themeProvider.accentColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppIcons.getFocusPointIcon(
                              width: 14,
                              height: 14,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${course.focusPointsCost}',
                              style: TextStyle(
                                color: themeProvider.accentColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 