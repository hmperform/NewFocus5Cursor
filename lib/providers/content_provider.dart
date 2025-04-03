  // In a real app, this would fetch from API
  await Future.delayed(const Duration(milliseconds: 1500));
  
  // For demo purposes, using dummy data
  _courses = DummyData.dummyCourses;
  _audioModules = DummyData.dummyAudioModules;
  _articles = DummyData.dummyArticles;
  
  // Filter content based on university access if applicable 