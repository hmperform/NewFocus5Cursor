import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:transparent_image/transparent_image.dart';

import '../../providers/theme_provider.dart';
import '../../providers/content_provider.dart';
import '../../models/content_models.dart';
import 'course_detail_screen.dart';

class AllModulesScreen extends StatefulWidget {
  const AllModulesScreen({Key? key}) : super(key: key);

  @override
  _AllModulesScreenState createState() => _AllModulesScreenState();
}

class _AllModulesScreenState extends State<AllModulesScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  List<String> _selectedCategories = [];

  final List<String> _categories = [
    'All',
    'Mental',
    'Focus',
    'Visualization',
    'Team',
    'Recovery',
    'Performance'
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategories = ['All'];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleCategory(String category) {
    setState(() {
      if (category == 'All') {
        _selectedCategories = ['All'];
      } else {
        _selectedCategories.remove('All');
        if (_selectedCategories.contains(category)) {
          _selectedCategories.remove(category);
          if (_selectedCategories.isEmpty) {
            _selectedCategories = ['All'];
          }
        } else {
          _selectedCategories.add(category);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final contentProvider = Provider.of<ContentProvider>(context);
    final lessons = contentProvider.getLessons();
    
    // Filter lessons based on search and categories
    List<Lesson> filteredLessons = lessons;
    
    // Apply category filter
    if (!_selectedCategories.contains('All')) {
      filteredLessons = filteredLessons.where((lesson) {
        return lesson.categories.any((category) => 
          _selectedCategories.any((selectedCategory) => 
            category.toLowerCase().contains(selectedCategory.toLowerCase())));
      }).toList();
    }
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filteredLessons = filteredLessons.where((lesson) {
        return lesson.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               lesson.description.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Lessons'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search lessons...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: themeProvider.isDarkMode 
                  ? Colors.grey[800] 
                  : Colors.grey[200],
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          
          // Categories
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategories.contains(category);
                
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      _toggleCategory(category);
                    },
                    backgroundColor: themeProvider.isDarkMode 
                      ? Colors.grey[800] 
                      : Colors.grey[200],
                    selectedColor: Theme.of(context).primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected 
                        ? Colors.white 
                        : themeProvider.isDarkMode 
                          ? Colors.white 
                          : Colors.black,
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Module list
          Expanded(
            child: filteredLessons.isEmpty
              ? Center(
                  child: Text(
                    'No lessons found',
                    style: TextStyle(
                      fontSize: 18,
                      color: themeProvider.isDarkMode 
                        ? Colors.white70 
                        : Colors.black54,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredLessons.length,
                  itemBuilder: (context, index) {
                    return _buildLessonCard(filteredLessons[index]);
                  },
                ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLessonCard(Lesson lesson) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to lesson detail/player
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Module image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Image.network(
                lesson.imageUrl ?? 'https://via.placeholder.com/400x200',
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 160,
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        size: 40,
                        color: Colors.grey,
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Module info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    lesson.description,
                    style: TextStyle(
                      color: themeProvider.isDarkMode 
                        ? Colors.white70 
                        : Colors.black54,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  
                  // Categories
                  Wrap(
                    spacing: 8,
                    children: lesson.categories.map((category) {
                      return Chip(
                        label: Text(
                          category,
                          style: const TextStyle(
                            fontSize: 12,
                          ),
                        ),
                        backgroundColor: themeProvider.isDarkMode 
                          ? Colors.grey[800] 
                          : Colors.grey[200],
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
                  ),
                  
                  // Duration & premium indicator
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text('${lesson.durationMinutes} min'),
                      const Spacer(),
                      if (lesson.premium)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'PREMIUM',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
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