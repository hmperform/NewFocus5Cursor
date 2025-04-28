import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../../models/chat_models.dart';
import '../../../providers/chat_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../providers/theme_provider.dart';
import '../../../models/content_models.dart'; // Import content models

class ContentSharingScreen extends StatefulWidget {
  final String chatId;

  const ContentSharingScreen({Key? key, required this.chatId}) : super(key: key);

  @override
  State<ContentSharingScreen> createState() => _ContentSharingScreenState();
}

class _ContentSharingScreenState extends State<ContentSharingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  String _errorMessage = '';
  int _selectedTabIndex = 0; // 0: Courses, 1: Modules, 2: Articles
  final TextEditingController _searchController = TextEditingController(); // Use this controller

  // Original unfiltered lists
  List<Map<String, dynamic>> _originalCourses = [];
  List<DailyAudio> _originalModules = []; // Use DailyAudio model
  List<Article> _originalArticles = []; // Use Article model

  // Filtered lists for display
  List<Map<String, dynamic>> _filteredCourses = [];
  List<DailyAudio> _filteredModules = []; // Use DailyAudio model
  List<Article> _filteredArticles = []; // Use Article model
  
  // String _searchQuery = ''; // Keep this if needed elsewhere, but controller is primary
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(() {
      // Filter content whenever the search text changes
      _filterContent(_searchController.text);
    });
    _loadContent(); // Initial load
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose(); // Dispose the controller
    super.dispose();
  }
  
  Future<void> _loadContent() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      // Initialize lists separately
      _filteredCourses = [];
      _filteredModules = [];
      _filteredArticles = [];
      _originalCourses = [];
      _originalModules = [];
      _originalArticles = [];
    });

    debugPrint('[ContentSharingScreen] Starting to load content...');

    try {
      // Fetch Courses (Remains Map<String, dynamic> as no Course model was specified)
      final coursesSnapshot = await _firestore.collection('courses').get();
      int fetchedCourseCount = coursesSnapshot.docs.length;
      debugPrint('[ContentSharingScreen] Fetched $fetchedCourseCount course documents.');
      List<Map<String, dynamic>> tempCourses = [];
       for (var doc in coursesSnapshot.docs) {
          final data = doc.data();
          debugPrint('[ContentSharingScreen] Raw Course Data (ID: ${doc.id}): $data');
          try {
              tempCourses.add({
                'id': doc.id,
                ...data, // Spread operator adds all fields from data
                'title': data['title'] ?? 'Unnamed Course', // Ensure title exists
              });
          } catch (e) {
              debugPrint('[ContentSharingScreen] !! Error processing course ${doc.id}: $e');
          }
       }
      debugPrint('[ContentSharingScreen] Processed ${tempCourses.length} courses.');

      // Fetch Audio Modules (Using DailyAudio Model)
      debugPrint('[ContentSharingScreen] --- Fetching Audio Modules --- '); // Renamed log
      final modulesSnapshot = await _firestore.collection('audio_modules').get(); // Corrected collection name
      int fetchedModuleCount = modulesSnapshot.docs.length;
      debugPrint('[ContentSharingScreen] Fetched $fetchedModuleCount module documents from audio_modules.'); // Updated log
      List<DailyAudio> tempModules = [];
       for (var i = 0; i < modulesSnapshot.docs.length; i++) { // Loop with index
          final doc = modulesSnapshot.docs[i];
          final data = doc.data();
          data['id'] = doc.id;
          debugPrint('[ContentSharingScreen] [Module ${i+1}/${fetchedModuleCount}] Raw Data (ID: ${doc.id}): $data');
          try {
             debugPrint('[ContentSharingScreen] [Module ${i+1}] Attempting DailyAudio.fromJson...'); // Added print
             final parsedModule = DailyAudio.fromJson(data);
             tempModules.add(parsedModule);
             debugPrint('[ContentSharingScreen] [Module ${i+1}] Successfully parsed: ${parsedModule.title}'); // Added print
          } catch (e, stackTrace) { // Catch stack trace too
              // Enhanced error print
              debugPrint('[ContentSharingScreen] !! [Module ${i+1}] ERROR processing module ${doc.id}:\nError: $e\nStackTrace: $stackTrace'); 
          }
       }
      // Log final count before setting state
      debugPrint('[ContentSharingScreen] Finished processing modules. tempModules count: ${tempModules.length}'); 

      // Fetch Articles (Using Article Model)
      debugPrint('[ContentSharingScreen] --- Fetching Articles --- '); // Added separator
      final articlesSnapshot = await _firestore.collection('articles').get();
      int fetchedArticleCount = articlesSnapshot.docs.length;
      debugPrint('[ContentSharingScreen] Fetched $fetchedArticleCount article documents.');
      List<Article> tempArticles = [];
       for (var doc in articlesSnapshot.docs) {
          final data = doc.data();
          // --> Add document ID to the map before parsing <--
          data['id'] = doc.id;
          // --> Log Raw Data <--
          debugPrint('[ContentSharingScreen] Raw Article Data (ID: ${doc.id}): $data');
          try {
             // --> Use Article.fromJson <--
             tempArticles.add(Article.fromJson(data));
          } catch (e) {
              debugPrint('[ContentSharingScreen] !! Error processing article ${doc.id}: $e. Provide default values or skip.');
              // Optionally add a default/placeholder article or skip
          }
       }
      debugPrint('[ContentSharingScreen] Processed ${tempArticles.length} articles.');


      if (mounted) {
        setState(() {
          // Store original unfiltered lists
          _originalCourses = List.from(tempCourses);
          _originalModules = List.from(tempModules);
          _originalArticles = List.from(tempArticles);

          // Log counts just before filtering
          debugPrint('[ContentSharingScreen] Setting state with -> Original Counts -> Courses: ${_originalCourses.length}, Modules: ${_originalModules.length}, Articles: ${_originalArticles.length}');

          // Apply initial filter (which might be empty, use controller text)
          _filterContent(_searchController.text, isInitialLoad: true);

          debugPrint('[ContentSharingScreen] Content loaded. Courses: ${_originalCourses.length}, Modules: ${_originalModules.length}, Articles: ${_originalArticles.length}');
        });
      }
    } catch (e, stackTrace) {
      debugPrint('[ContentSharingScreen] !! Error loading content: $e\n$stackTrace');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load content: $e';
          // Initialize lists separately on error too
          _originalCourses = [];
          _originalModules = [];
          _originalArticles = [];
          _filteredCourses = [];
          _filteredModules = [];
          _filteredArticles = [];
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          debugPrint('[ContentSharingScreen] Loading finished. isLoading: $_isLoading');
        });
      }
    }
  }

  void _filterContent(String query, {bool isInitialLoad = false}) {
      final lowercaseQuery = query.toLowerCase();
      // No need to set _searchQuery state variable here if using controller listener
      debugPrint('[ContentSharingScreen] Filtering content with query: "$query"');

      // Use original lists as the source for filtering
      List<Map<String, dynamic>> filteredCourses = List.from(_originalCourses);
      List<DailyAudio> filteredModules = List.from(_originalModules);
      List<Article> filteredArticles = List.from(_originalArticles);

      if (query.isNotEmpty) { // Use the query parameter directly
        // Filter courses
        filteredCourses = _originalCourses.where((course) {
          final title = (course['title'] ?? '').toString().toLowerCase();
          final description = (course['description'] ?? '').toString().toLowerCase();
          // Add other searchable fields for courses if necessary
          return title.contains(lowercaseQuery) || description.contains(lowercaseQuery);
        }).toList();

        // Filter modules
        filteredModules = _originalModules.where((module) {
           final title = (module.title ?? '').toString().toLowerCase(); // Use model property
           final description = (module.description ?? '').toString().toLowerCase(); // Use model property
           // final category = (module.category ?? '').toString().toLowerCase(); // Use model property
           return title.contains(lowercaseQuery) || description.contains(lowercaseQuery);
        }).toList();

        // Filter articles
        filteredArticles = _originalArticles.where((article) {
           final title = (article.title ?? '').toString().toLowerCase(); // Use model property
           final content = (article.content ?? '').toString().toLowerCase(); // Use model property (shortened?)
           // final authorName = (article.authorName ?? '').toString().toLowerCase(); // Use model property
           return title.contains(lowercaseQuery) || content.contains(lowercaseQuery);
        }).toList();
      }

      // Update the state only if it's not the initial load triggered from _loadContent
      // Or if it IS the initial load (to set the initial state)
      // The listener in initState will call setState via _filterContent
      // So we only need setState here if it's the initial load call.
      if (mounted && (isInitialLoad || !isInitialLoad)) { // Always update if mounted
         setState(() {
           _filteredCourses = filteredCourses;
           _filteredModules = filteredModules;
           _filteredArticles = filteredArticles;
           debugPrint('[ContentSharingScreen] Filtering complete. Filtered Counts -> Courses: ${_filteredCourses.length}, Modules: ${_filteredModules.length}, Articles: ${_filteredArticles.length}');
         });
      }
    }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Share Content',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextField(
                    controller: _searchController, // Assign the controller
                    decoration: InputDecoration(
                      hintText: 'Search content...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade200,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    // onChanged removed - listener in initState handles changes
                  ),
                ),
              ],
            ),
          ),
          
          // Tab Bar
          TabBar(
            controller: _tabController,
            indicatorColor: Theme.of(context).primaryColor,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'Courses'),
              Tab(text: 'Modules'),
              Tab(text: 'Articles'),
            ],
          ),
          
          // Tab Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildContentList(_filteredCourses, 'course'),
                      _buildContentList(_filteredModules, 'module'),
                      _buildContentList(_filteredArticles, 'article'),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildContentList(List<dynamic> items, String contentType) {
    debugPrint('[ContentSharingScreen] Building list for $contentType. Items: ${items.length}, isLoading: $_isLoading');

    if (_isLoading) {
      // Already handled by the main CircularProgressIndicator
      return const SizedBox.shrink(); // Don't show anything extra while loading initially
    }

    if (_errorMessage.isNotEmpty) {
      // Already handled by the main error message display
       return const SizedBox.shrink();
    }

    if (items.isEmpty) {
      // Use controller text for the message
      return Center(child: Text('No ${contentType}s found${_searchController.text.isNotEmpty ? ' matching "${_searchController.text}"' : ''}.'));
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        String title = 'Unnamed Content';
        String? thumbnailUrl = ''; // Default empty string
        String id = '';
        String description = ''; // For sharing context
        Map<String, dynamic> metadata = {};

        // --- Access data based on contentType and model/map ---
        if (contentType == 'course' && item is Map<String, dynamic>) {
          title = item['title'] as String? ?? 'Unnamed Course';
          id = item['id'] as String? ?? '';
          thumbnailUrl = item['thumbnailUrl'] as String?; // Can be null
          description = item['description'] as String? ?? '';
        } else if (contentType == 'module' && item is DailyAudio) {
          title = item.title ?? 'Unnamed Module';
          id = item.id;
          thumbnailUrl = item.thumbnail; // Access model property
          description = item.description ?? '';
        } else if (contentType == 'article' && item is Article) {
          title = item.title ?? 'Unnamed Article';
          id = item.id;
          thumbnailUrl = item.thumbnail; // Use thumbnail
          description = item.content ?? ''; // Use content as description for articles
          metadata = {
            'authorName': item.authorName,
            'readTime': item.readTimeMinutes,
          };
        } else {
           // Handle unexpected item type or structure
           debugPrint("[ContentSharingScreen] !! Warning: Unexpected item type in _buildContentList for $contentType: ${item.runtimeType}");
           return const ListTile(title: Text("Error displaying item"));
        }
        // --- End Data Access ---


        Widget leadingWidget;
        if (thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
           if (thumbnailUrl.toLowerCase().endsWith('.svg')) {
            leadingWidget = SvgPicture.network(
              thumbnailUrl,
              placeholderBuilder: (context) => const Icon(Icons.image, size: 40),
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            );
          } else {
            leadingWidget = CachedNetworkImage(
              imageUrl: thumbnailUrl,
              placeholder: (context, url) => const Icon(Icons.image, size: 40),
              errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 40),
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            );
          }
        } else {
          // Placeholder icon if no thumbnail URL
          leadingWidget = CircleAvatar(
            radius: 25,
            child: Icon(
              contentType == 'course' ? Icons.school :
              contentType == 'module' ? Icons.headset :
              Icons.article, // Default icon
              size: 25,
            ),
          );
        }


        return ListTile(
          leading: leadingWidget,
          title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
          trailing: ElevatedButton(
             onPressed: () => _shareContent(contentType, id, title, description, thumbnailUrl), // Pass model properties
            child: const Text('Share'),
          ),
          onTap: () => _shareContent(contentType, id, title, description, thumbnailUrl), // Also allow tapping the row
        );
      },
    );
  }
  
  void _shareContent(String type, String id, String title, String? description, String? thumbnailUrl) async {
    final sharedContent = SharedContent(
      contentId: id,
      contentType: type,
      title: title,
      description: description ?? '',
      thumbnailUrl: thumbnailUrl,
      metadata: {},
    );
    
    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      await chatProvider.sendMessageWithSharedContent(
        widget.chatId,
        '', // Empty content, will be replaced with default message
        sharedContent,
      );
      
      if (mounted) {
          Navigator.pop(context); // Close the sharing dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${type.capitalize()} shared successfully')),
          );
      }
    } catch (e) {
      if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error sharing content: $e')),
          );
      }
    }
  }
}

// Helper extension for capitalizing strings
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) {
      return "";
    }
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
} 