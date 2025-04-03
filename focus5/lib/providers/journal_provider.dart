import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/journal_model.dart';

class JournalProvider with ChangeNotifier {
  final String _userId;
  
  List<JournalEntry> _entries = [];
  List<JournalPrompt> _prompts = [];
  bool _isLoading = false;
  String? _error;
  
  // Dummy prompts for initial development
  final List<String> _dummyPrompts = [
    "What are you grateful for today?",
    "What's one thing that challenged you today and what did you learn from it?",
    "How did you practice mindfulness today?",
    "What's one goal you're working towards?",
    "Describe a moment that made you smile today.",
    "What's something you're looking forward to?",
    "How did you take care of your mental health today?",
    "What boundaries did you set or maintain today?",
    "Describe your energy levels throughout the day.",
    "What's one thing you'd like to improve about tomorrow?",
  ];
  
  JournalProvider(this._userId) {
    // Initialize with dummy data
    _createDummyPrompts();
  }
  
  // Getters
  List<JournalEntry> get entries => [..._entries];
  List<JournalPrompt> get prompts => [..._prompts];
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Get entries for a specific date
  List<JournalEntry> getEntriesForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1)).subtract(const Duration(microseconds: 1));
    
    return _entries.where((entry) => 
      entry.date.isAfter(startOfDay) && 
      entry.date.isBefore(endOfDay)
    ).toList();
  }
  
  // Get entries by tag
  List<JournalEntry> getEntriesByTag(String tag) {
    return _entries.where((entry) => 
      entry.tags.contains(tag.toLowerCase())
    ).toList();
  }
  
  // Get random prompt
  String getRandomPrompt() {
    if (_prompts.isNotEmpty) {
      _prompts.shuffle();
      return _prompts.first.text;
    } else {
      // Use dummy prompt if no prompts are loaded
      _dummyPrompts.shuffle();
      return _dummyPrompts.first;
    }
  }
  
  // Create dummy prompts
  void _createDummyPrompts() {
    _prompts = _dummyPrompts.map((text) => 
      JournalPrompt(
        id: const Uuid().v4(),
        text: text,
        categories: ['general'],
      )
    ).toList();
  }
  
  // Add a new journal entry
  Future<JournalEntry?> addEntry({
    required String prompt,
    required String content,
    required DateTime date,
    required MoodLevel mood,
    List<String> tags = const [],
  }) async {
    _setLoading(true);
    try {
      final now = DateTime.now();
      final uuid = const Uuid().v4();
      
      // Process tags (lowercase and trim)
      final processedTags = tags.map((tag) => tag.toLowerCase().trim()).toList();
      
      final newEntry = JournalEntry(
        id: uuid,
        userId: _userId,
        prompt: prompt,
        content: content,
        date: date,
        mood: mood,
        tags: processedTags,
        createdAt: now,
        updatedAt: now,
      );
      
      // Add to local list (in-memory only)
      _entries.insert(0, newEntry);
      notifyListeners();
      
      _setError(null);
      return newEntry;
    } catch (e) {
      _setError('Failed to add journal entry: ${e.toString()}');
      if (kDebugMode) {
        print('Error adding journal entry: $e');
      }
      return null;
    } finally {
      _setLoading(false);
    }
  }
  
  // Update an existing journal entry
  Future<bool> updateEntry(JournalEntry updatedEntry) async {
    _setLoading(true);
    try {
      // Update the updatedAt timestamp
      final entryWithUpdatedTime = updatedEntry.copyWith(
        updatedAt: DateTime.now(),
      );
      
      // Update in local list
      final index = _entries.indexWhere((entry) => entry.id == updatedEntry.id);
      if (index >= 0) {
        _entries[index] = entryWithUpdatedTime;
        notifyListeners();
      }
      
      _setError(null);
      return true;
    } catch (e) {
      _setError('Failed to update journal entry: ${e.toString()}');
      if (kDebugMode) {
        print('Error updating journal entry: $e');
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Delete a journal entry
  Future<bool> deleteEntry(String entryId) async {
    _setLoading(true);
    try {
      // Remove from local list
      _entries.removeWhere((entry) => entry.id == entryId);
      notifyListeners();
      
      _setError(null);
      return true;
    } catch (e) {
      _setError('Failed to delete journal entry: ${e.toString()}');
      if (kDebugMode) {
        print('Error deleting journal entry: $e');
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Search entries by content
  List<JournalEntry> searchEntries(String query) {
    final lowerQuery = query.toLowerCase();
    return _entries.where((entry) => 
      entry.content.toLowerCase().contains(lowerQuery) ||
      entry.prompt.toLowerCase().contains(lowerQuery) ||
      entry.tags.any((tag) => tag.toLowerCase().contains(lowerQuery))
    ).toList();
  }
  
  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String? errorMessage) {
    _error = errorMessage;
    if (errorMessage != null) {
      notifyListeners();
    }
  }
  
  // Reset error message
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  // For dummy data - add some sample entries
  void addSampleEntries() {
    if (_entries.isEmpty) {
      final now = DateTime.now();
      
      addEntry(
        prompt: "What are you grateful for today?",
        content: "I'm grateful for the opportunity to learn new things and grow my skills.",
        date: now.subtract(const Duration(days: 1)),
        mood: MoodLevel.good,
        tags: ["gratitude", "learning"],
      );
      
      addEntry(
        prompt: "How did you practice mindfulness today?",
        content: "I took a 10-minute walk outside without my phone and just paid attention to my surroundings.",
        date: now.subtract(const Duration(days: 3)),
        mood: MoodLevel.awesome,
        tags: ["mindfulness", "nature"],
      );
      
      addEntry(
        prompt: "What's one goal you're working towards?",
        content: "I'm working on improving my Flutter development skills by building this journaling app!",
        date: now.subtract(const Duration(days: 7)),
        mood: MoodLevel.okay,
        tags: ["goals", "coding"],
      );
    }
  }
  
  // Refresh entries (just a mock for now)
  Future<void> refreshEntries() async {
    // In a real app with backend, we'd fetch from API here
    // For now, we'll just notify listeners to refresh UI
    notifyListeners();
  }
} 