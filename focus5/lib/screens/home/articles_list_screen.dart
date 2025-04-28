import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/content_provider.dart';
import '../../models/content_models.dart';
import '../../widgets/article/article_card.dart';

class ArticlesListScreen extends StatefulWidget {
  final String? focusArea;
  final String? tag;

  const ArticlesListScreen({
    Key? key,
    this.focusArea,
    this.tag,
  }) : super(key: key);

  @override
  State<ArticlesListScreen> createState() => _ArticlesListScreenState();
}

class _ArticlesListScreenState extends State<ArticlesListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedTag = 'All';
  
  @override
  void initState() {
    super.initState();
    if (widget.tag != null) {
      _selectedTag = widget.tag!;
    }
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  void _handleSearch(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }
  
  void _handleTagSelection(String tag) {
    setState(() {
      _selectedTag = tag;
    });
  }
  
  List<Article> _getFilteredArticles(List<Article> articles) {
    final bool filterByTag = _selectedTag != 'All';
    final lowerQuery = _searchQuery.toLowerCase();
    
    return articles.where((article) {
      final matchesSearch = lowerQuery.isEmpty ||
          article.title.toLowerCase().contains(lowerQuery) ||
          article.tags.any((tag) => tag.toLowerCase().contains(lowerQuery)) ||
          (article.authorName?.toLowerCase().contains(lowerQuery) ?? false);
      
      final matchesFocusArea = widget.focusArea == null || 
          article.focusAreas.contains(widget.focusArea);
      
      final matchesTag = !filterByTag || article.tags.contains(_selectedTag);
      
      return matchesSearch && matchesFocusArea && matchesTag;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final contentProvider = Provider.of<ContentProvider>(context);
    final allArticles = contentProvider.articles;

    // --- Dynamic Tag Generation Start ---
    // 1. Count tag frequencies
    final Map<String, int> tagCounts = {};
    for (var article in allArticles) {
      for (var tag in article.tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }

    // 2. Sort tags by frequency (descending)
    final sortedTags = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // 3. Get top 5 tags (or fewer if not enough unique tags)
    final topTags = sortedTags.take(5).map((entry) => entry.key).toList();

    // 4. Create the final list for chips
    final List<String> filterTags = ['All', ...topTags];
    // --- Dynamic Tag Generation End ---

    final filteredArticles = _getFilteredArticles(allArticles);
    
    String title = 'Articles';
    if (widget.focusArea != null) {
      title = '${widget.focusArea} Articles';
    } else if (_selectedTag != 'All') {
      title = '$_selectedTag Articles';
    }
    
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Search articles...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                onChanged: _handleSearch,
              ),
            ),
          ),
          
          // Filter chips
          if (widget.focusArea == null)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: filterTags.map((tag) =>
                  _buildFilterChip(
                    tag,
                    isSelected: _selectedTag == tag,
                    onSelected: () => _handleTagSelection(tag),
                  )
                ).toList(),
              ),
            ),
          
          const SizedBox(height: 16),
          
          // Articles list
          Expanded(
            child: filteredArticles.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.article_outlined,
                          color: Colors.white54,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No articles found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[400],
                          ),
                        ),
                        if (_searchQuery.isNotEmpty || widget.focusArea != null || _selectedTag != 'All')
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Try adjusting your filters',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredArticles.length,
                    itemBuilder: (context, index) {
                      return ArticleListCard(article: filteredArticles[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterChip(String label, {required bool isSelected, required VoidCallback onSelected}) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        labelStyle: TextStyle(
          color: isSelected ? Colors.black : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        backgroundColor: const Color(0xFF2A2A2A),
        selectedColor: const Color(0xFFB4FF00),
        checkmarkColor: Colors.black,
        onSelected: (selected) {
          if (selected) {
            onSelected();
          }
        },
      ),
    );
  }
} 