import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/journal_model.dart';
import '../../providers/journal_provider.dart';
import '../../widgets/journal/journal_entry_card.dart';
import 'journal_entry_screen.dart';

class JournalSearchScreen extends StatefulWidget {
  final String initialQuery;
  final bool isTagSearch;
  final DateTime? searchDate;
  final MoodLevel? searchMood;
  
  const JournalSearchScreen({
    Key? key,
    this.initialQuery = '',
    this.isTagSearch = false,
    this.searchDate,
    this.searchMood,
  }) : super(key: key);

  @override
  State<JournalSearchScreen> createState() => _JournalSearchScreenState();
}

class _JournalSearchScreenState extends State<JournalSearchScreen> {
  late TextEditingController _searchController;
  late String _searchQuery;
  List<JournalEntry> _filteredEntries = [];
  List<String> _availableTags = [];
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    _searchQuery = widget.initialQuery;
    
    // Initialize search results
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performSearch();
      if (widget.isTagSearch) {
        _loadAvailableTags();
      }
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  void _loadAvailableTags() {
    final journalProvider = Provider.of<JournalProvider>(context, listen: false);
    final entries = journalProvider.entries;
    
    final Set<String> uniqueTags = {};
    for (var entry in entries) {
      uniqueTags.addAll(entry.tags);
    }
    
    setState(() {
      _availableTags = uniqueTags.toList()..sort();
    });
  }
  
  void _performSearch() {
    setState(() {
      _isLoading = true;
    });
    
    final journalProvider = Provider.of<JournalProvider>(context, listen: false);
    List<JournalEntry> results = [];
    
    if (widget.searchDate != null) {
      // Search by date
      final date = widget.searchDate!;
      results = journalProvider.getEntriesForDate(date);
      
    } else if (widget.searchMood != null) {
      // Search by mood
      results = journalProvider.entries.where((entry) => 
        entry is JournalEntry && entry.mood == widget.searchMood
      ).toList();
      
    } else if (widget.isTagSearch && _searchQuery.isNotEmpty) {
      // Search by selected tag
      results = journalProvider.getEntriesByTag(_searchQuery);
      
    } else {
      // Normal content search
      results = journalProvider.searchEntries(_searchQuery);
    }
    
    setState(() {
      _filteredEntries = results;
      _isLoading = false;
    });
  }
  
  String _getScreenTitle() {
    if (widget.searchDate != null) {
      return DateFormat('MMMM d, y').format(widget.searchDate!);
    } else if (widget.searchMood != null) {
      return '${widget.searchMood!.emoji} ${widget.searchMood!.name} Entries';
    } else if (widget.isTagSearch) {
      return _searchQuery.isEmpty ? 'Browse Tags' : '#$_searchQuery';
    } else {
      return 'Search Results';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _getScreenTitle(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          if (!widget.isTagSearch && widget.searchDate == null && widget.searchMood == null)
            _buildSearchBar(),
          if (widget.isTagSearch && _searchQuery.isEmpty)
            _buildTagSelector()
          else
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFB4FF00)),
                      ),
                    )
                  : _filteredEntries.isEmpty
                      ? _buildNoResultsFound()
                      : _buildSearchResults(),
            ),
        ],
      ),
    );
  }
  
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Search journal entries...',
            hintStyle: TextStyle(color: Colors.grey),
            border: InputBorder.none,
            prefixIcon: Icon(
              Icons.search,
              color: Colors.grey,
            ),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
            _performSearch();
          },
        ),
      ),
    );
  }
  
  Widget _buildTagSelector() {
    return Expanded(
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFB4FF00)),
              ),
            )
          : _availableTags.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.tag,
                        color: Colors.grey,
                        size: 48,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No tags found',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Add tags to your journal entries to organize them',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.0,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _availableTags.length,
                  itemBuilder: (context, index) {
                    final tag = _availableTags[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _searchQuery = tag;
                        });
                        _performSearch();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '#$tag',
                              style: const TextStyle(
                                color: Color(0xFFB4FF00),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_getEntryCountForTag(tag)} entries',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
  
  int _getEntryCountForTag(String tag) {
    final journalProvider = Provider.of<JournalProvider>(context, listen: false);
    return journalProvider.getEntriesByTag(tag).length;
  }
  
  Widget _buildNoResultsFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off,
            color: Colors.grey,
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            'No results found',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.isTagSearch
                ? 'No entries with the tag #$_searchQuery'
                : 'Try a different search term',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSearchResults() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredEntries.length,
      itemBuilder: (context, index) {
        final entry = _filteredEntries[index];
        return JournalEntryCard(
          entry: entry,
          onTap: () => _navigateToEntryDetails(entry),
          highlightText: widget.isTagSearch ? null : _searchQuery,
        );
      },
    );
  }
  
  void _navigateToEntryDetails(JournalEntry entry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JournalEntryScreen(
          existingEntry: entry,
        ),
      ),
    ).then((_) {
      // Refresh search results when coming back
      _performSearch();
    });
  }
} 