import 'package:flutter/foundation.dart';
import 'package:focus5/models/content_models.dart';
import 'package:focus5/services/audio_module_service.dart';
import 'package:focus5/providers/user_provider.dart';
import 'package:flutter/material.dart';

class AudioModuleProvider with ChangeNotifier {
  final AudioModuleService _audioModuleService = AudioModuleService();
  final UserProvider _userProvider;

  DailyAudio? _currentAudioModule;
  bool _isLoading = false;
  String? _errorMessage;

  AudioModuleProvider(this._userProvider) {
    print('AudioModuleProvider: Constructor called. UserProvider has user: ${_userProvider.user != null}');
    if (_userProvider.user != null) {
      print('AudioModuleProvider: User available in constructor, calling loadCurrentAudioModule.');
      loadCurrentAudioModule();
    } else {
      print('AudioModuleProvider: User not available in constructor, will wait for update.');
    }
  }

  DailyAudio? get currentAudioModule => _currentAudioModule;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadCurrentAudioModule() async {
    print('>>> AudioModuleProvider: loadCurrentAudioModule EXECUTION STARTED <<<');
    
    final currentUser = _userProvider.user;
    if (currentUser == null) {
      print('AudioModuleProvider: Cannot load module, user is null in loadCurrentAudioModule.');
      _errorMessage = 'User not logged in.';
      _isLoading = false;
      _currentAudioModule = null;
      notifyListeners();
      return;
    }
    
    final totalLoginDays = currentUser.totalLoginDays;
    print('AudioModuleProvider: Loading current audio module using totalLoginDays: $totalLoginDays from UserProvider');
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _currentAudioModule = await _audioModuleService.getCurrentAudioModule(totalLoginDays);
      print('AudioModuleProvider: Service returned module: ${_currentAudioModule?.title ?? 'None'}');
    } catch (e, stackTrace) {
      print('AudioModuleProvider: Error loading audio module: $e');
      print('AudioModuleProvider: StackTrace: $stackTrace');
      _errorMessage = 'Failed to load daily audio: $e';
      _currentAudioModule = null;
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
    notifyListeners();
  }

  Future<void> refreshAudioModule() async {
    print('AudioModuleProvider: Refreshing audio module...');
    await loadCurrentAudioModule();
  }
} 