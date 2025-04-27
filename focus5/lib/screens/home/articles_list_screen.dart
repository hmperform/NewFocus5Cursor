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
  
  @override
  void initState() {
    super.initState();
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
  
  List<Article> _getFilteredArticles(List<Article> articles) {
    if (_searchQuery.isEmpty && widget.focusArea == null && widget.tag == null) {
      return articles;
    }
    
    final lowerQuery = _searchQuery.toLowerCase();
    
    return articles.where((article) {
      // Search filtering
      final matchesSearch = article.title.toLowerCase().contains(lowerQuery) ||
          article.tags.any((tag) => tag.toLowerCase().contains(lowerQuery)) ||
          (article.authorName?.toLowerCase().contains(lowerQuery) ?? false);
      
      // Focus area filtering
      final matchesFocusArea = widget.focusArea == null || 
          article.focusAreas.contains(widget.focusArea);
      
      // Tag filtering
      final matchesTag = widget.tag == null || 
          article.tags.contains(widget.tag);
      
      return matchesSearch && matchesFocusArea && matchesTag;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final contentProvider = Provider.of<ContentProvider>(context);
    final allArticles = contentProvider.articles;
    final filteredArticles = _getFilteredArticles(allArticles);
    
    String title = 'Articles';
    if (widget.focusArea != null) {
      title = '${widget.focusArea} Articles';
    } else if (widget.tag != null) {
      title = '${widget.tag} Articles';
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
          if (widget.focusArea == null && widget.tag == null)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildFilterChip('All', isSelected: true),
                  _buildFilterChip('Motivation'),
                  _buildFilterChip('Focus'),
                  _buildFilterChip('Performance'),
                  _buildFilterChip('Mindfulness'),
                  _buildFilterChip('Mental Toughness'),
                ],
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
                        if (_searchQuery.isNotEmpty || widget.focusArea != null || widget.tag != null)
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
  
  Widget _buildFilterChip(String label, {bool isSelected = false}) {
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
          // Handle filter selection
          // You would implement state changes here
        },
      ),
    );
  }
} 