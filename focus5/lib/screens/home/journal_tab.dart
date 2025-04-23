import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/journal_model.dart';
import '../../providers/journal_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../constants/theme.dart';
import '../../widgets/journal/journal_entry_card.dart';
import '../../widgets/journal/journal_empty_state.dart';
import 'journal_entry_screen.dart';
import 'journal_search_screen.dart';

class JournalTab extends StatefulWidget {
  const JournalTab({Key? key}) : super(key: key);

  @override
  State<JournalTab> createState() => _JournalTabState();
}

class _JournalTabState extends State<JournalTab> {
  bool _isSelectionMode = false;
  Set<String> _selectedEntries = {};
  String _searchQuery = '';
  bool _showFavoritesOnly = false;
  bool _showSearchBar = false;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Add a post-frame callback to fetch entries after the first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final journalProvider = Provider.of<JournalProvider>(context, listen: false);
      
      // Refresh entries from Firestore
      journalProvider.refreshEntries();
      
      // Add sample entries if needed (for demo)
      journalProvider.addSampleEntries();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedEntries.clear();
      }
    });
  }

  void _toggleEntrySelection(String entryId) {
    setState(() {
      if (_selectedEntries.contains(entryId)) {
        _selectedEntries.remove(entryId);
      } else {
        _selectedEntries.add(entryId);
      }
    });
  }

  Future<void> _deleteSelectedEntries(JournalProvider journalProvider) async {
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${_selectedEntries.length} Entries'),
        content: Text('Are you sure you want to delete ${_selectedEntries.length} journal entries? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    bool hasError = false;
    for (String entryId in _selectedEntries) {
      final success = await journalProvider.deleteEntry(entryId);
      if (!success) {
        hasError = true;
      }
    }

    if (mounted) {
      if (hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Some entries could not be deleted')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selected entries deleted')),
        );
      }
      setState(() {
        _isSelectionMode = false;
        _selectedEntries.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accentColor = themeProvider.accentColor;

    return Consumer<JournalProvider>(
      builder: (context, journalProvider, _) {
        final entries = journalProvider.entries
            .where((entry) => _showFavoritesOnly ? entry.isFavorite : true)
            .where((entry) => 
              _searchQuery.isEmpty ||
              entry.content.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              entry.prompt.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              entry.tags.any((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()))
            )
            .toList();

        return Scaffold(
          appBar: AppBar(
            title: _showSearchBar
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search journals...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                    ),
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  )
                : const Text('Journal'),
            actions: [
              if (_isSelectionMode) ...[
                Text(
                  '${_selectedEntries.length} selected',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _selectedEntries.isEmpty 
                      ? null 
                      : () => _deleteSelectedEntries(journalProvider),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _toggleSelectionMode,
                ),
              ] else ...[
                IconButton(
                  icon: Icon(
                    _showFavoritesOnly ? Icons.favorite : Icons.favorite_border,
                    color: _showFavoritesOnly ? Colors.red : null,
                  ),
                  onPressed: () {
                    setState(() => _showFavoritesOnly = !_showFavoritesOnly);
                  },
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'select') {
                      _toggleSelectionMode();
                    } else if (value == 'search') {
                      setState(() {
                        _showSearchBar = !_showSearchBar;
                        if (!_showSearchBar) {
                          _searchQuery = '';
                          _searchController.clear();
                        }
                      });
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'select',
                      child: Row(
                        children: [
                          Icon(Icons.checklist),
                          SizedBox(width: 8),
                          Text('Select'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'search',
                      child: Row(
                        children: [
                          Icon(Icons.search),
                          SizedBox(width: 8),
                          Text('Search'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          body: entries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.book_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _showFavoritesOnly
                            ? 'No favorite entries yet'
                            : _searchQuery.isNotEmpty
                                ? 'No entries match your search'
                                : 'No journal entries yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return JournalEntryCard(
                      entry: entry,
                      highlightText: _searchQuery,
                      isSelectionMode: _isSelectionMode,
                      isSelected: _selectedEntries.contains(entry.id),
                      onTap: () {
                        if (_isSelectionMode) {
                          _toggleEntrySelection(entry.id);
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => JournalEntryScreen(
                                entry: entry,
                              ),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
          floatingActionButton: _isSelectionMode
              ? null
              : FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const JournalEntryScreen(),
                      ),
                    );
                  },
                  backgroundColor: accentColor,
                  child: const Icon(Icons.add),
                ),
        );
      },
    );
  }

  void _showFilterOptions(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final surfaceColor = Theme.of(context).colorScheme.surface;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter Journal Entries',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              _buildFilterOption(
                context, 
                'All Entries', 
                Icons.article_outlined,
                () => Navigator.pop(context),
              ),
              _buildFilterOption(
                context, 
                'Browse by Tags', 
                Icons.tag,
                () {
                  Navigator.pop(context);
                  Navigator.push(
                    context, 
                    MaterialPageRoute(
                      builder: (context) => const JournalSearchScreen(
                        isTagSearch: true,
                      ),
                    ),
                  );
                },
              ),
              _buildFilterOption(
                context, 
                'Browse by Date', 
                Icons.calendar_today,
                () {
                  Navigator.pop(context);
                  _selectDate(context);
                },
              ),
              _buildFilterOption(
                context, 
                'Mood Entries', 
                Icons.emoji_emotions,
                () {
                  Navigator.pop(context);
                  _selectMood(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterOption(
    BuildContext context, 
    String title, 
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Icon(
              icon,
              color: const Color(0xFFB4FF00),
              size: 24,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white54,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFB4FF00),
              onPrimary: Colors.black,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      // Search entries for the selected date
      final dateStr = DateFormat('yyyy-MM-dd').format(picked);
      Navigator.push(
        context, 
        MaterialPageRoute(
          builder: (context) => JournalSearchScreen(
            initialQuery: dateStr,
            searchDate: picked,
          ),
        ),
      );
    }
  }

  void _selectMood(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter by Mood',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMoodOption(context, MoodLevel.terrible),
                  _buildMoodOption(context, MoodLevel.bad),
                  _buildMoodOption(context, MoodLevel.okay),
                  _buildMoodOption(context, MoodLevel.good),
                  _buildMoodOption(context, MoodLevel.awesome),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMoodOption(BuildContext context, MoodLevel mood) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context, 
          MaterialPageRoute(
            builder: (context) => JournalSearchScreen(
              initialQuery: 'mood:${mood.name}',
              searchMood: mood,
            ),
          ),
        );
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              mood.emoji,
              style: const TextStyle(fontSize: 24),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            mood.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
} 