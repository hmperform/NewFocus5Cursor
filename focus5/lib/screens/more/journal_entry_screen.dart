import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/journal_model.dart';
import '../../providers/journal_provider.dart';

class JournalEntryScreen extends StatefulWidget {
  final String? entryId;
  final MoodLevel? initialMood;

  const JournalEntryScreen({
    Key? key,
    this.entryId,
    this.initialMood,
  }) : super(key: key);

  @override
  State<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends State<JournalEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  final _tagController = TextEditingController();
  final _promptController = TextEditingController();
  
  late MoodLevel _selectedMood;
  final List<String> _tags = [];
  bool _isFavorite = false;
  
  bool _isEditing = false;
  JournalEntry? _initialEntry;

  @override
  void initState() {
    super.initState();
    _selectedMood = widget.initialMood ?? MoodLevel.good;
    
    if (widget.entryId != null) {
      _isEditing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadEntry();
      });
    } else {
      // Fetch a random prompt for new entries
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchRandomPrompt();
      });
    }
  }
  
  void _loadEntry() {
    final journalProvider = Provider.of<JournalProvider>(context, listen: false);
    final entry = journalProvider.getEntryById(widget.entryId!);
    
    if (entry != null) {
      _initialEntry = entry;
      _contentController.text = entry.content;
      _promptController.text = entry.prompt;
      _selectedMood = entry.mood;
      _tags.addAll(entry.tags);
      _isFavorite = entry.isFavorite;
      setState(() {});
    }
  }
  
  Future<void> _fetchRandomPrompt() async {
    try {
      final journalProvider = Provider.of<JournalProvider>(context, listen: false);
      final prompt = await journalProvider.getRandomPrompt();
      
      setState(() {
        _promptController.text = prompt;
      });
    } catch (e) {
      // If there's an error, use a default prompt
      setState(() {
        _promptController.text = "What's on your mind today?";
      });
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _tagController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Journal Entry' : 'New Journal Entry'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _confirmDelete,
            ),
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : null,
            ),
            onPressed: () {
              setState(() {
                _isFavorite = !_isFavorite;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveEntry,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildDateSection(),
            const SizedBox(height: 16),
            _buildMoodSelector(),
            const SizedBox(height: 24),
            _buildPromptField(),
            const SizedBox(height: 16),
            _buildContentField(),
            const SizedBox(height: 24),
            _buildTagsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSection() {
    final now = DateTime.now();
    final date = _initialEntry?.date ?? now;
    
    return Row(
      children: [
        Icon(
          Icons.calendar_today,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          _formatDate(date),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const Spacer(),
        TextButton.icon(
          icon: const Icon(Icons.access_time),
          label: Text(_formatTime(date)),
          onPressed: () async {
            // Optional: Allow changing the time
          },
        ),
      ],
    );
  }

  Widget _buildMoodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How are you feeling?',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildMoodOption(MoodLevel.terrible, '😢', 'Terrible'),
            _buildMoodOption(MoodLevel.bad, '😕', 'Bad'),
            _buildMoodOption(MoodLevel.okay, '😐', 'Okay'),
            _buildMoodOption(MoodLevel.good, '🙂', 'Good'),
            _buildMoodOption(MoodLevel.awesome, '😁', 'Great'),
          ],
        ),
      ],
    );
  }

  Widget _buildMoodOption(MoodLevel mood, String emoji, String label) {
    final isSelected = _selectedMood == mood;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMood = mood;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
          ),
        ),
        child: Column(
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Prompt',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Spacer(),
            if (!_isEditing)
              IconButton(
                icon: Icon(
                  Icons.refresh,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onPressed: _fetchRandomPrompt,
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextFormField(
            controller: _promptController,
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: const InputDecoration(
              hintText: 'What are you thinking about?',
              border: InputBorder.none,
            ),
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildContentField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Write your thoughts',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _contentController,
          decoration: InputDecoration(
            hintText: 'What\'s on your mind?',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
          ),
          maxLines: 8,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter some content';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _tagController,
                decoration: InputDecoration(
                  hintText: 'Add a tag',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addTag,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tag in _tags)
              Chip(
                label: Text(tag),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  setState(() {
                    _tags.remove(tag);
                  });
                },
              ),
          ],
        ),
      ],
    );
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _saveEntry() {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return;
    }
    
    final journalProvider = Provider.of<JournalProvider>(context, listen: false);
    final content = _contentController.text.trim();
    
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write something before saving')),
      );
      return;
    }
    
    // Save to Firestore
    if (_isEditing && _initialEntry != null) {
      // Update existing entry
      final updatedEntry = _initialEntry!.copyWith(
        content: content,
        mood: _selectedMood,
        tags: _tags,
        isFavorite: _isFavorite,
        updatedAt: DateTime.now(),
      );
      
      journalProvider.updateEntry(updatedEntry).then((success) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Journal entry updated')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(journalProvider.error ?? 'Failed to update entry')),
          );
        }
      });
    } else {
      // Create new entry
      final now = DateTime.now();
      final prompt = _promptController.text.trim().isNotEmpty 
          ? _promptController.text.trim() 
          : 'Journal Entry';
          
      journalProvider.addEntry(
        prompt: prompt,
        content: content,
        date: now,
        mood: _selectedMood,
        tags: _tags,
      ).then((entry) {
        if (entry != null) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Journal entry saved')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(journalProvider.error ?? 'Failed to save entry')),
          );
        }
      });
    }
  }
  
  void _confirmDelete() {
    if (_initialEntry == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text('Are you sure you want to delete this journal entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _deleteEntry();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
  
  void _deleteEntry() {
    if (_initialEntry == null) return;
    
    final journalProvider = Provider.of<JournalProvider>(context, listen: false);
    
    journalProvider.deleteEntry(_initialEntry!.id).then((success) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Journal entry deleted')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(journalProvider.error ?? 'Failed to delete entry')),
        );
      }
    });
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today';
    } else if (date.year == now.year && date.month == now.month && date.day == now.day - 1) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
} 