import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/journal_model.dart';
import '../../providers/journal_provider.dart';
import '../../widgets/journal/journal_tag_selector.dart';
import '../../providers/theme_provider.dart';

class JournalEntryScreen extends StatefulWidget {
  final JournalEntry? existingEntry;
  
  const JournalEntryScreen({
    Key? key,
    this.existingEntry,
  }) : super(key: key);

  @override
  State<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends State<JournalEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  MoodLevel _selectedMood = MoodLevel.okay;
  List<String> _selectedTags = [];
  String _prompt = '';
  bool _isEditing = false;
  bool _isSaving = false;
  
  @override
  void initState() {
    super.initState();
    _isEditing = widget.existingEntry != null;
    
    if (_isEditing) {
      // Initialize form with existing entry data
      _contentController.text = widget.existingEntry!.content;
      _selectedDate = widget.existingEntry!.date;
      _selectedMood = widget.existingEntry!.mood;
      _selectedTags = List.from(widget.existingEntry!.tags);
      _prompt = widget.existingEntry!.prompt;
    } else {
      // Initialize with current date for new entries
      _selectedDate = DateTime.now();
      
      // Get a random prompt for a new entry
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final journalProvider = Provider.of<JournalProvider>(context, listen: false);
        setState(() {
          _prompt = journalProvider.getRandomPrompt();
        });
      });
    }
  }
  
  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accentColor = themeProvider.accentColor;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).colorScheme.onBackground;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _isEditing ? 'Edit Journal Entry' : 'New Journal Entry',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveEntry,
            child: Text(
              'Save',
              style: TextStyle(
                color: _isSaving ? Colors.grey : accentColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: _isSaving
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              ),
            )
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDateSelector(),
                    const SizedBox(height: 16),
                    _buildMoodSelector(),
                    const SizedBox(height: 24),
                    _buildPromptSection(),
                    const SizedBox(height: 16),
                    _buildContentEditor(),
                    const SizedBox(height: 24),
                    _buildTagSelector(),
                    const SizedBox(height: 40),
                    if (_isEditing) _buildDeleteButton(),
                  ],
                ),
              ),
            ),
    );
  }
  
  Widget _buildDateSelector() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accentColor = themeProvider.accentColor;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onBackground;
    
    return GestureDetector(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: accentColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                DateFormat('EEEE, MMMM d, y').format(_selectedDate),
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                ),
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: textColor.withOpacity(0.7),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _selectDate() async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final accentColor = themeProvider.accentColor;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onBackground;
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: accentColor,
              onPrimary: Colors.black,
              surface: surfaceColor,
              onSurface: textColor,
            ),
            dialogBackgroundColor: surfaceColor,
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }
  
  Widget _buildMoodSelector() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accentColor = themeProvider.accentColor;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onBackground;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How are you feeling?',
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: MoodLevel.values.map((mood) {
            final isSelected = mood == _selectedMood;
            return GestureDetector(
              onTap: () => setState(() => _selectedMood = mood),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? accentColor : surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      border: isSelected
                          ? Border.all(color: accentColor, width: 2)
                          : null,
                    ),
                    child: Text(
                      mood.emoji,
                      style: TextStyle(
                        fontSize: 24,
                        color: isSelected ? Colors.black : textColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    mood.name,
                    style: TextStyle(
                      color: isSelected ? accentColor : textColor,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildPromptSection() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accentColor = themeProvider.accentColor;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onBackground;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Prompt',
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (!_isEditing)
              TextButton(
                onPressed: _getNewPrompt,
                child: Row(
                  children: [
                    Icon(
                      Icons.refresh,
                      color: accentColor,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'New Prompt',
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _prompt,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }
  
  void _getNewPrompt() {
    final journalProvider = Provider.of<JournalProvider>(context, listen: false);
    setState(() {
      _prompt = journalProvider.getRandomPrompt();
    });
  }
  
  Widget _buildContentEditor() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onBackground;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Journal Entry',
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextFormField(
            controller: _contentController,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: 'Write your thoughts here...',
              hintStyle: TextStyle(color: Colors.grey),
              border: InputBorder.none,
            ),
            maxLines: 10,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your journal entry';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildTagSelector() {
    return JournalTagSelector(
      selectedTags: _selectedTags,
      onTagsChanged: (tags) {
        setState(() {
          _selectedTags = tags;
        });
      },
    );
  }
  
  Widget _buildDeleteButton() {
    return Center(
      child: TextButton.icon(
        onPressed: _confirmDelete,
        icon: const Icon(
          Icons.delete_outline,
          color: Colors.redAccent,
        ),
        label: const Text(
          'Delete Entry',
          style: TextStyle(
            color: Colors.redAccent,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
  
  void _confirmDelete() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onBackground;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        title: Text(
          'Delete Journal Entry',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this journal entry? This action cannot be undone.',
          style: TextStyle(
            color: textColor.withOpacity(0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: textColor,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteEntry();
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.redAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _deleteEntry() async {
    if (widget.existingEntry == null) return;
    
    setState(() {
      _isSaving = true;
    });
    
    final journalProvider = Provider.of<JournalProvider>(context, listen: false);
    final success = await journalProvider.deleteEntry(widget.existingEntry!.id);
    
    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Journal entry deleted'),
          backgroundColor: Color(0xFF333333),
        ),
      );
    } else {
      setState(() {
        _isSaving = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(journalProvider.error ?? 'Failed to delete entry'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
  
  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isSaving = true;
    });
    
    final journalProvider = Provider.of<JournalProvider>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final content = _contentController.text.trim();
    
    bool success = false;
    
    if (_isEditing && widget.existingEntry != null) {
      // Update existing entry
      final updatedEntry = widget.existingEntry!.copyWith(
        prompt: _prompt,
        content: content,
        date: _selectedDate,
        mood: _selectedMood,
        tags: _selectedTags,
      );
      
      success = await journalProvider.updateEntry(updatedEntry);
    } else {
      // Create new entry
      final newEntry = await journalProvider.addEntry(
        prompt: _prompt,
        content: content,
        date: _selectedDate,
        mood: _selectedMood,
        tags: _selectedTags,
      );
      
      success = newEntry != null;
    }
    
    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Journal entry saved'),
            backgroundColor: surfaceColor,
          ),
        );
      } else {
        setState(() {
          _isSaving = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(journalProvider.error ?? 'Failed to save entry'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
} 