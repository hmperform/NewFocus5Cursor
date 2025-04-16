import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

import '../models/journal_model.dart';

class JournalProvider with ChangeNotifier {
  final String _userId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<JournalEntry> _entries = [];
  List<JournalPrompt> _prompts = [];
  bool _isLoading = false;
  String? _error;
  
  // Dummy prompts for fallback
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
    _initialize();
  }
  
  void _initialize() async {
    await fetchPrompts();
    await fetchEntries();
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
  
  // Fetch all journal entries for the user
  Future<void> fetchEntries() async {
    if (_userId == 'default_user') return; // Don't fetch for default user
    
    _setLoading(true);
    try {
      final querySnapshot = await _firestore
          .collection('journal_entries')
          .where('userId', isEqualTo: _userId)
          .orderBy('date', descending: true)
          .get();
      
      _entries = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return JournalEntry(
          id: doc.id,
          userId: data['userId'],
          prompt: data['prompt'],
          content: data['content'],
          date: (data['date'] as Timestamp).toDate(),
          mood: _parseMood(data['mood']),
          tags: List<String>.from(data['tags'] ?? []),
          createdAt: (data['createdWhen'] as Timestamp).toDate(),
          updatedAt: (data['updatedAt'] as Timestamp).toDate(),
          isFavorite: data['isFavorite'] ?? false,
        );
      }).toList();
      
      _setError(null);
    } catch (e) {
      _setError('Failed to load journal entries: ${e.toString()}');
      if (kDebugMode) {
        print('Error fetching journal entries: $e');
      }
    } finally {
      _setLoading(false);
    }
  }
  
  MoodLevel _parseMood(dynamic moodValue) {
    if (moodValue is int) {
      return MoodLevel.values[moodValue];
    } else if (moodValue is String) {
      switch (moodValue.toLowerCase()) {
        case 'terrible': return MoodLevel.terrible;
        case 'bad': return MoodLevel.bad;
        case 'okay': return MoodLevel.okay;
        case 'good': return MoodLevel.good;
        case 'awesome': return MoodLevel.awesome;
        default: return MoodLevel.okay;
      }
    }
    return MoodLevel.okay;
  }
  
  // Fetch prompts from Firestore
  Future<void> fetchPrompts() async {
    try {
      final querySnapshot = await _firestore
          .collection('prompts')
          .where('isActive', isEqualTo: true)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        _createDummyPrompts();
        return;
      }
      
      _prompts = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return JournalPrompt(
          id: doc.id,
          text: data['text'],
          categories: List<String>.from(data['categories'] ?? []),
        );
      }).toList();
      
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching prompts: $e');
      }
      _createDummyPrompts();
    }
  }
  
  // Get random prompt
  Future<String> getRandomPrompt() async {
    if (_prompts.isEmpty) {
      await fetchPrompts();
    }
    
    if (_prompts.isNotEmpty) {
      final random = Random();
      final randomIndex = random.nextInt(_prompts.length);
      return _prompts[randomIndex].text;
    } else {
      // Use dummy prompt if no prompts are loaded
      final random = Random();
      final randomIndex = random.nextInt(_dummyPrompts.length);
      return _dummyPrompts[randomIndex];
    }
  }
  
  // Get prompt by category
  Future<String> getPromptByCategory(String category) async {
    if (_prompts.isEmpty) {
      await fetchPrompts();
    }
    
    final categoryPrompts = _prompts.where(
      (prompt) => prompt.categories.contains(category)
    ).toList();
    
    if (categoryPrompts.isNotEmpty) {
      final random = Random();
      final randomIndex = random.nextInt(categoryPrompts.length);
      return categoryPrompts[randomIndex].text;
    } else {
      return getRandomPrompt();
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
      
      // Create the entry object
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
      
      // Add to Firestore
      if (_userId != 'default_user') {
        await _firestore.collection('journal_entries').doc(uuid).set({
          'userId': _userId,
          'prompt': prompt,
          'content': content,
          'date': Timestamp.fromDate(date),
          'mood': mood.name.toLowerCase(),
          'tags': processedTags,
          'createdWhen': Timestamp.fromDate(now),
          'updatedAt': Timestamp.fromDate(now),
          'isFavorite': false,
        });
      }
      
      // Add to local list
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
      final now = DateTime.now();
      
      // Update the updatedAt timestamp
      final entryWithUpdatedTime = updatedEntry.copyWith(
        updatedAt: now,
      );
      
      // Update in Firestore
      if (_userId != 'default_user') {
        await _firestore.collection('journal_entries').doc(updatedEntry.id).update({
          'prompt': updatedEntry.prompt,
          'content': updatedEntry.content,
          'date': Timestamp.fromDate(updatedEntry.date),
          'mood': updatedEntry.mood.name.toLowerCase(),
          'tags': updatedEntry.tags,
          'updatedAt': Timestamp.fromDate(now),
          'isFavorite': updatedEntry.isFavorite,
        });
      }
      
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
      // Delete from Firestore
      if (_userId != 'default_user') {
        await _firestore.collection('journal_entries').doc(entryId).delete();
      }
      
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
  
  // Toggle favorite status
  Future<bool> toggleFavorite(String id) async {
    try {
      final index = _entries.indexWhere((entry) => entry.id == id);
      if (index >= 0) {
        final entry = _entries[index];
        final newIsFavorite = !entry.isFavorite;
        
        // Update in Firestore
        if (_userId != 'default_user') {
          await _firestore.collection('journal_entries').doc(id).update({
            'isFavorite': newIsFavorite,
          });
        }
        
        // Update in local list
        _entries[index] = entry.copyWith(isFavorite: newIsFavorite);
        notifyListeners();
        
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error toggling favorite: $e');
      }
      return false;
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
    if (_entries.isEmpty && _userId == 'default_user') {
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
        content: "I'm working on improving my mental fitness by tracking my thoughts and feelings through this journal!",
        date: now.subtract(const Duration(days: 7)),
        mood: MoodLevel.okay,
        tags: ["goals", "mindset"],
      );
    }
  }
  
  // Refresh entries from Firestore
  Future<void> refreshEntries() async {
    if (_userId == 'default_user') {
      // Just simulate a refresh for the demo
      notifyListeners();
      return;
    }
    
    await fetchEntries();
  }

  List<JournalEntry> get recentEntries => 
      [..._entries]..sort((a, b) => b.date.compareTo(a.date));

  // Get a journal entry by its ID
  JournalEntry? getEntryById(String id) {
    try {
      return _entries.firstWhere((entry) => entry.id == id);
    } catch (e) {
      return null;
    }
  }
  
  // Get entries by mood - for backwards compatibility
  List<JournalEntry> getEntriesByMood(MoodLevel mood) {
    return _entries.where((entry) => entry.mood == mood).toList();
  }
      
  // Clean up resources when provider is disposed
  @override
  void dispose() {
    _entries.clear();
    _prompts.clear();
    _error = null;
    super.dispose();
  }
} 