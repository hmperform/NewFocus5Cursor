import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/journal_model.dart';
import '../../providers/journal_provider.dart';
import '../../widgets/journal/journal_entry_card.dart';
import 'journal_entry_screen.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({Key? key}) : super(key: key);

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  bool _isSelectionMode = false;
  Set<String> _selectedEntries = {};

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

  Future<void> _deleteSelectedEntries(BuildContext context, JournalProvider journalProvider) async {
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
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: _isSelectionMode
            ? Text('${_selectedEntries.length} selected')
            : const Text('Journal'),
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _selectedEntries.isEmpty 
                  ? null 
                  : () => _deleteSelectedEntries(context, Provider.of<JournalProvider>(context, listen: false)),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _toggleSelectionMode,
            ),
          ] else ...[
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'select') {
                  _toggleSelectionMode();
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
              ],
            ),
          ],
        ],
      ),
      body: Consumer<JournalProvider>(
        builder: (context, journalProvider, _) {
          final entries = journalProvider.entries;
          
          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.book_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No journal entries yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start tracking your thoughts and feelings',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add Entry'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const JournalEntryScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          }
          
          return Column(
            children: [
              _buildMoodTracker(context),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Entries',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    TextButton(
                      onPressed: () {
                        // View all entries
                      },
                      child: const Text('View All'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return JournalEntryCard(
                      entry: entry,
                      isSelectionMode: _isSelectionMode,
                      isSelected: _selectedEntries.contains(entry.id),
                      onTap: () {
                        if (_isSelectionMode) {
                          _toggleEntrySelection(entry.id);
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => JournalEntryScreen(entryId: entry.id),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const JournalEntryScreen(),
                  ),
                );
              },
              child: const Icon(Icons.add),
            ),
    );
  }

  Widget _buildMoodTracker(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How are you feeling today?',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMoodOption(context, MoodLevel.awesome, '😁', 'Great'),
              _buildMoodOption(context, MoodLevel.good, '🙂', 'Good'),
              _buildMoodOption(context, MoodLevel.okay, '😐', 'Okay'),
              _buildMoodOption(context, MoodLevel.bad, '😕', 'Bad'),
              _buildMoodOption(context, MoodLevel.terrible, '😢', 'Terrible'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMoodOption(
    BuildContext context,
    MoodLevel mood,
    String emoji,
    String label,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => JournalEntryScreen(initialMood: mood),
          ),
        );
      },
      child: Column(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildJournalEntry(BuildContext context, JournalEntry entry) {
    Color moodColor;
    switch (entry.mood) {
      case MoodLevel.awesome:
        moodColor = Colors.green;
        break;
      case MoodLevel.good:
        moodColor = Colors.lightGreen;
        break;
      case MoodLevel.okay:
        moodColor = Colors.amber;
        break;
      case MoodLevel.bad:
        moodColor = Colors.orange;
        break;
      case MoodLevel.terrible:
        moodColor = Colors.red;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => JournalEntryScreen(entryId: entry.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDate(entry.date),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: moodColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getMoodLabel(entry.mood),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: Icon(
                          entry.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color:
                              entry.isFavorite ? Colors.red : Colors.grey[400],
                        ),
                        onPressed: () {
                          Provider.of<JournalProvider>(context, listen: false)
                              .toggleFavorite(entry.id);
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                entry.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (entry.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: entry.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      child: Text(
                        '#$tag',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text('Favorites'),
              onTap: () {
                Navigator.pop(context);
                // Filter by favorites
              },
            ),
            ListTile(
              leading: const Icon(Icons.mood),
              title: const Text('By Mood'),
              onTap: () {
                Navigator.pop(context);
                _showMoodFilterOptions(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.tag),
              title: const Text('By Tag'),
              onTap: () {
                Navigator.pop(context);
                // Show tag filter options
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('By Date'),
              onTap: () {
                Navigator.pop(context);
                // Show date filter options
              },
            ),
          ],
        );
      },
    );
  }

  void _showMoodFilterOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filter by Mood'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Text('😁', style: TextStyle(fontSize: 24)),
                title: const Text('Great'),
                onTap: () {
                  Navigator.pop(context);
                  // Filter by great mood
                },
              ),
              ListTile(
                leading: const Text('🙂', style: TextStyle(fontSize: 24)),
                title: const Text('Good'),
                onTap: () {
                  Navigator.pop(context);
                  // Filter by good mood
                },
              ),
              ListTile(
                leading: const Text('😐', style: TextStyle(fontSize: 24)),
                title: const Text('Okay'),
                onTap: () {
                  Navigator.pop(context);
                  // Filter by okay mood
                },
              ),
              ListTile(
                leading: const Text('😕', style: TextStyle(fontSize: 24)),
                title: const Text('Bad'),
                onTap: () {
                  Navigator.pop(context);
                  // Filter by bad mood
                },
              ),
              ListTile(
                leading: const Text('😢', style: TextStyle(fontSize: 24)),
                title: const Text('Terrible'),
                onTap: () {
                  Navigator.pop(context);
                  // Filter by terrible mood
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getMoodLabel(MoodLevel mood) {
    switch (mood) {
      case MoodLevel.awesome:
        return 'Great';
      case MoodLevel.good:
        return 'Good';
      case MoodLevel.okay:
        return 'Okay';
      case MoodLevel.bad:
        return 'Bad';
      case MoodLevel.terrible:
        return 'Terrible';
      default:
        return 'Unknown';
    }
  }
} 