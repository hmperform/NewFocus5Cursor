import 'package:flutter/foundation.dart';
import 'package:focus5/models/content_models.dart';
import 'package:focus5/services/audio_module_service.dart';
import 'package:focus5/providers/user_provider.dart';
import 'package:flutter/material.dart';

class AudioModuleProvider with ChangeNotifier {
  final AudioModuleService _audioModuleService = AudioModuleService();
  UserProvider _userProvider;
  int _lastCheckedTotalLoginDays = -1; // Track the last value used to load

  DailyAudio? _currentAudioModule;
  bool _isLoading = false;
  String? _errorMessage;

  AudioModuleProvider(this._userProvider) {
    print('AudioModuleProvider: Constructor called. UserProvider has user: ${_userProvider.user != null}');
    _initializeOrUpdate();
  }

  DailyAudio? get currentAudioModule => _currentAudioModule;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Called by ProxyProvider's update callback
  void updateUserProvider(UserProvider newUserProvider) {
    print("AudioModuleProvider: updateUserProvider called.");
    _userProvider = newUserProvider; 
    _initializeOrUpdate();
  }

  // Internal method to check user and load/reload module if necessary
  void _initializeOrUpdate() {
     final currentUser = _userProvider.user;
     if (currentUser == null) {
       print('AudioModuleProvider [_initializeOrUpdate]: User is null. Clearing module.');
       if (_currentAudioModule != null || _isLoading) {
         clearCurrentAudioModule(); // Clear if user becomes null
         _lastCheckedTotalLoginDays = -1;
       }
       return;
     }

     final currentTotalLoginDays = currentUser.totalLoginDays;
     print('AudioModuleProvider [_initializeOrUpdate]: Current totalLoginDays: $currentTotalLoginDays, Last checked: $_lastCheckedTotalLoginDays');

     // Load only if totalLoginDays has changed since the last load
     if (currentTotalLoginDays != _lastCheckedTotalLoginDays) {
       print('AudioModuleProvider [_initializeOrUpdate]: totalLoginDays changed or initial load needed. Calling loadCurrentAudioModule.');
       loadCurrentAudioModule(); // Trigger load
     } else {
       print('AudioModuleProvider [_initializeOrUpdate]: totalLoginDays has not changed. No reload needed.');
     }
  }

  Future<void> loadCurrentAudioModule() async {
    print('>>> AudioModuleProvider: loadCurrentAudioModule EXECUTION STARTED <<<');
    
    final currentUser = _userProvider.user;
    if (currentUser == null) {
      print('AudioModuleProvider: Cannot load module, user is null in loadCurrentAudioModule.');
      _errorMessage = 'User not logged in.';
      _isLoading = false;
      _currentAudioModule = null;
      _lastCheckedTotalLoginDays = -1; // Reset last checked
      notifyListeners();
      return;
    }
    
    final totalLoginDays = currentUser.totalLoginDays;
    print('AudioModuleProvider: Loading current audio module using totalLoginDays: $totalLoginDays from UserProvider');
    
    _isLoading = true;
    _errorMessage = null;
    // Don't notify just for loading start if module already exists, prevents flicker
    if (_currentAudioModule == null) {
       notifyListeners();
    }
    
    try {
      _currentAudioModule = await _audioModuleService.getCurrentAudioModule(totalLoginDays);
      _lastCheckedTotalLoginDays = totalLoginDays; // Update last checked value *after* successful load
      print('AudioModuleProvider: Service returned module: ${_currentAudioModule?.title ?? 'None'}');
    } catch (e, stackTrace) {
      print('AudioModuleProvider: Error loading audio module: $e');
      print('AudioModuleProvider: StackTrace: $stackTrace');
      _errorMessage = 'Failed to load daily audio: $e';
      _currentAudioModule = null;
      _lastCheckedTotalLoginDays = -1; // Reset on error
    } finally {
      _isLoading = false;
      print('AudioModuleProvider: loadCurrentAudioModule FINISHED. isLoading: $_isLoading, Module: ${_currentAudioModule?.title ?? 'None'}');
      notifyListeners();
    }
  }

  void clearCurrentAudioModule() {
    print('AudioModuleProvider: Clearing current audio module.');
    _currentAudioModule = null;
    _errorMessage = null;
    _lastCheckedTotalLoginDays = -1; // Reset last checked
    if (mounted) { // Check if provider is still mounted
      notifyListeners();
    }
  }

  // Add mounted check helper (optional but good practice)
  bool _mounted = true;
  bool get mounted => _mounted;

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }


  Future<void> refreshAudioModule() async {
    print('AudioModuleProvider: Refreshing audio module...');
    _lastCheckedTotalLoginDays = -1; // Force reload on next check
    await loadCurrentAudioModule();
  }
} 