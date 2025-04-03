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
    }
  }
  
  void _loadEntry() {
    final journalProvider = Provider.of<JournalProvider>(context, listen: false);
    final entry = journalProvider.getEntryById(widget.entryId!);
    
    if (entry != null) {
      _initialEntry = entry;
      _contentController.text = entry.content;
      _selectedMood = entry.mood;
      _tags.addAll(entry.tags);
      _isFavorite = entry.isFavorite;
      setState(() {});
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
    if (_formKey.currentState!.validate()) {
      final journalProvider = Provider.of<JournalProvider>(context, listen: false);
      
      if (_isEditing && _initialEntry != null) {
        final updatedEntry = _initialEntry!.copyWith(
          content: _contentController.text.trim(),
          mood: _selectedMood,
          tags: _tags,
          isFavorite: _isFavorite,
        );
        
        journalProvider.updateEntry(updatedEntry);
      } else {
        journalProvider.addEntry(
          prompt: _promptController.text.trim(),
          content: _contentController.text.trim(),
          date: DateTime.now(),
          mood: _selectedMood,
          tags: _tags,
        );
      }
      
      Navigator.of(context).pop();
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text('Are you sure you want to delete this journal entry?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final journalProvider = Provider.of<JournalProvider>(context, listen: false);
              journalProvider.deleteEntry(widget.entryId!);
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Return to journal screen
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
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