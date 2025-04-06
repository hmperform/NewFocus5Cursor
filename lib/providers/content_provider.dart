  // In a real app, this would fetch from API
  await Future.delayed(const Duration(milliseconds: 1500));
  
  // For demo purposes, using dummy data
  _courses = DummyData.dummyCourses;
  _audioModules = DummyData.dummyAudioModules;
  _articles = DummyData.dummyArticles;
  
  // Filter content based on university access if applicable 

  // Initialize content, optionally filtering by university code
  Future<void> initContent(String? universityCode) async {
    if (_isLoading) return; // Prevent multiple initializations
    
    _errorMessage = null;
    _universityCode = universityCode;
    
    // Use post-frame callback to avoid setState during build
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      _isLoading = true;
      notifyListeners();
  
      try {
        // Fix module organization first to ensure consistency
        await _contentService.fixModuleOrganization();
        
        // Load courses from Firebase
        await loadCourses();
        
        // Load audio modules from Firebase
        await loadAudioModules();
        
        // Load daily lesson assignment
        await loadDailyLesson();
        
        // Load articles from Firebase
        await loadArticles();
        
        _isLoading = false;
        _errorMessage = null;
      } catch (e) {
        _isLoading = false;
        _errorMessage = 'Failed to load content: ${e.toString()}';
        debugPrint('Error in initContent: ${e.toString()}');
      }
      
      notifyListeners();
    });
  } 