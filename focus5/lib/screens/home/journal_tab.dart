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
  bool _isSearching = false;
  String _searchQuery = '';
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

  @override
  Widget build(BuildContext context) {
    final journalProvider = Provider.of<JournalProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    final entries = journalProvider.entries;
    final isLoading = journalProvider.isLoading;
    final error = journalProvider.error;
    
    // Get theme-aware colors
    final accentColor = themeProvider.accentColor;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final surfaceColor = Theme.of(context).colorScheme.surface;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: null,
      body: RefreshIndicator(
        onRefresh: () => journalProvider.refreshEntries(),
        color: accentColor,
        backgroundColor: surfaceColor,
        child: isLoading && entries.isEmpty
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                ),
              )
            : error != null && entries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.orange,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load entries',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => journalProvider.refreshEntries(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : entries.isEmpty
                    ? const JournalEmptyState()
                    : _buildJournalList(entries, context),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToNewEntry(context),
        backgroundColor: accentColor,
        child: Icon(
          Icons.add,
          color: themeProvider.accentTextColor,
        ),
      ),
    );
  }

  Widget _buildJournalList(List<JournalEntry> entries, BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final accentColor = themeProvider.accentColor;
    
    // Group entries by month
    final groupedEntries = <String, List<JournalEntry>>{};
    
    for (var entry in entries) {
      final monthYear = DateFormat('MMMM yyyy').format(entry.date);
      if (!groupedEntries.containsKey(monthYear)) {
        groupedEntries[monthYear] = [];
      }
      groupedEntries[monthYear]!.add(entry);
    }
    
    // Sort the keys (month-year) in descending order
    final sortedMonths = groupedEntries.keys.toList()
      ..sort((a, b) {
        // Parse the month-year string back to date for comparison
        final dateA = DateFormat('MMMM yyyy').parse(a);
        final dateB = DateFormat('MMMM yyyy').parse(b);
        return dateB.compareTo(dateA); // Descending order
      });
    
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: sortedMonths.length,
      itemBuilder: (context, index) {
        final monthYear = sortedMonths[index];
        final monthEntries = groupedEntries[monthYear]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                monthYear,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: monthEntries.length,
              itemBuilder: (context, entryIndex) {
                final entry = monthEntries[entryIndex];
                return JournalEntryCard(
                  entry: entry,
                  onTap: () => _navigateToEntryDetails(context, entry),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _navigateToNewEntry(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const JournalEntryScreen(),
      ),
    );
  }

  void _navigateToEntryDetails(BuildContext context, JournalEntry entry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JournalEntryScreen(
          existingEntry: entry,
        ),
      ),
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