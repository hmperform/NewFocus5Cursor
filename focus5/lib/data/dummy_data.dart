import 'package:focus5/models/content_models.dart';

class DummyData {
  // Mock courses data
  static List<Course> get dummyCourses {
    return [
      Course(
        id: 'course-001',
        title: 'Mental Toughness Training',
        description: 'Develop mental toughness to perform under pressure and overcome obstacles in your sport.',
        imageUrl: 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438',
        thumbnailUrl: 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438',
        creatorId: 'coach-001',
        creatorName: 'Dr. Sarah Johnson',
        creatorImageUrl: 'https://images.unsplash.com/photo-1571731956672-f2b94d7dd0cb',
        tags: ['Mental Toughness', 'Performance', 'Mindset'],
        focusAreas: ['Mental Toughness', 'Resilience', 'Pressure Management'],
        durationMinutes: 240, // 4 hours in minutes
        duration: 240,
        xpReward: 500,
        lessons: [],
        modules: [
          Module(
            id: 'module-001',
            title: 'Understanding Mental Toughness',
            description: 'Learn what mental toughness is and why it matters for athletes.',
            imageUrl: 'https://images.unsplash.com/photo-1526506118085-60ce8714f8c5',
            categories: ['Mental Toughness', 'Psychology'],
            type: ModuleType.video,
            videoUrl: 'https://storage.googleapis.com/focus-5-app.appspot.com/videos/mental_toughness_intro.mp4',
            durationMinutes: 22,
            sortOrder: 1,
            thumbnailUrl: 'https://images.unsplash.com/photo-1526506118085-60ce8714f8c5',
          ),
          Module(
            id: 'module-002',
            title: 'Building Resilience',
            description: 'Techniques to build resilience and bounce back from setbacks.',
            imageUrl: 'https://images.unsplash.com/photo-1541534741688-6078c6bfb5c5',
            categories: ['Resilience', 'Techniques'],
            type: ModuleType.video,
            videoUrl: 'https://storage.googleapis.com/focus-5-app.appspot.com/videos/resilience_training.mp4',
            durationMinutes: 19,
            sortOrder: 2,
            thumbnailUrl: 'https://images.unsplash.com/photo-1541534741688-6078c6bfb5c5',
          ),
          Module(
            id: 'module-003',
            title: 'Pressure Management',
            description: 'How to perform under pressure and manage stress effectively.',
            imageUrl: 'https://images.unsplash.com/photo-1486218119243-13883505764c',
            categories: ['Pressure', 'Stress Management'],
            type: ModuleType.video,
            videoUrl: 'https://storage.googleapis.com/focus-5-app.appspot.com/videos/pressure_management.mp4',
            durationMinutes: 24,
            sortOrder: 3,
            thumbnailUrl: 'https://images.unsplash.com/photo-1486218119243-13883505764c',
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        universityExclusive: false,
      ),
      Course(
        id: 'course-002',
        title: 'Focus Enhancement Training',
        description: 'Improve your concentration and attention control to stay present during competition.',
        imageUrl: 'https://images.unsplash.com/photo-1461896836934-ffe607ba8211',
        thumbnailUrl: 'https://images.unsplash.com/photo-1461896836934-ffe607ba8211',
        creatorId: 'coach-002',
        creatorName: 'Michael Chen',
        creatorImageUrl: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7',
        tags: ['Focus', 'Concentration', 'Attention'],
        focusAreas: ['Focus', 'Concentration', 'Mindfulness'],
        durationMinutes: 180, // 3 hours in minutes
        duration: 180,
        xpReward: 400,
        lessons: [],
        modules: [
          Module(
            id: 'module-101',
            title: 'Focus Fundamentals',
            description: 'Understanding the science of focus and concentration.',
            imageUrl: 'https://images.unsplash.com/photo-1506126613408-eca07ce68773',
            categories: ['Focus', 'Concentration'],
            type: ModuleType.video,
            videoUrl: 'https://storage.googleapis.com/focus-5-app.appspot.com/videos/focus_fundamentals.mp4',
            durationMinutes: 20,
            sortOrder: 1,
            thumbnailUrl: 'https://images.unsplash.com/photo-1506126613408-eca07ce68773',
          ),
          Module(
            id: 'module-102',
            title: 'Mindfulness for Athletes',
            description: 'Mindfulness techniques specifically designed for sports performance.',
            imageUrl: 'https://images.unsplash.com/photo-1534258936925-c58bed479fcb',
            categories: ['Mindfulness', 'Focus'],
            type: ModuleType.video,
            videoUrl: 'https://storage.googleapis.com/focus-5-app.appspot.com/videos/mindfulness_athletes.mp4',
            durationMinutes: 21,
            sortOrder: 2,
            thumbnailUrl: 'https://images.unsplash.com/photo-1534258936925-c58bed479fcb',
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        universityExclusive: false,
      ),
    ];
  }

  // Mock audio modules data
  static List<DailyAudio> get dummyAudioModules {
    return [
      DailyAudio(
        id: 'audio-001',
        title: 'Pre-Game Mental Preparation',
        description: 'A guided meditation to help you prepare mentally before competition.',
        category: 'Pre-Competition',
        imageUrl: 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b',
        audioUrl: 'https://storage.googleapis.com/focus-5-app.appspot.com/audio/pregame_preparation.mp3',
        durationMinutes: 10,
        creatorId: 'coach-001',
        creatorName: 'Dr. Sarah Johnson',
        datePublished: DateTime.now().subtract(const Duration(days: 2)),
        focusAreas: ['Focus', 'Calm', 'Confidence'],
        xpReward: 50,
        universityExclusive: false,
      ),
      DailyAudio(
        id: 'audio-002',
        title: 'Confidence Builder',
        description: 'Build unwavering confidence before your performance.',
        category: 'Confidence',
        imageUrl: 'https://images.unsplash.com/photo-1517963879433-6ad2b056d712',
        audioUrl: 'https://storage.googleapis.com/focus-5-app.appspot.com/audio/confidence_builder.mp3',
        durationMinutes: 8,
        creatorId: 'coach-002',
        creatorName: 'Michael Chen',
        datePublished: DateTime.now().subtract(const Duration(days: 5)),
        focusAreas: ['Confidence', 'Self-Talk', 'Mindset'],
        xpReward: 40,
        universityExclusive: false,
      ),
      DailyAudio(
        id: 'audio-003',
        title: 'Recovery Visualization',
        description: 'Accelerate recovery through guided visualization techniques.',
        category: 'Recovery',
        imageUrl: 'https://images.unsplash.com/photo-1549576490-b0b4831ef60a',
        audioUrl: 'https://storage.googleapis.com/focus-5-app.appspot.com/audio/recovery_visualization.mp3',
        durationMinutes: 12,
        creatorId: 'coach-003',
        creatorName: 'Emma Williams',
        datePublished: DateTime.now().subtract(const Duration(days: 1)),
        focusAreas: ['Recovery', 'Healing', 'Visualization'],
        xpReward: 60,
        universityExclusive: false,
      ),
    ];
  }

  // Mock articles data
  static List<Article> get dummyArticles {
    return [
      Article(
        id: 'article-001',
        title: 'The Science of Flow State in Athletes',
        authorId: 'author-001',
        authorName: 'Dr. James Anderson',
        authorImageUrl: 'https://images.unsplash.com/photo-1508214751196-bcfd4ca60f91',
        content: '''
# The Science of Flow State in Athletes

Flow state is that magical moment when everything clicks. Time seems to slow down, distractions fade away, and performance feels effortless. Athletes often describe it as being "in the zone."

## What is Flow State?

Flow state is a concept identified by psychologist Mihaly Csikszentmihalyi, describing a mental state where a person is fully immersed and engaged in an activity, with a feeling of energized focus and enjoyment in the process.

## The Neuroscience Behind Flow

During flow, your brain undergoes several changes:

1. **Transient hypofrontality**: The prefrontal cortex temporarily downregulates, reducing self-consciousness and inner critic.
2. **Increased dopamine and endorphins**: Creating feelings of pleasure and reward.
3. **Alpha-theta wave shifts**: Brain waves that promote relaxed focus and creativity.

## How to Trigger Flow State

Research suggests several triggers that can help athletes enter flow:

- **Clear goals**: Know exactly what you're trying to achieve.
- **Immediate feedback**: Get instant information about your performance.
- **Challenge-skill balance**: The task should be challenging but achievable.
- **Deep concentration**: Eliminate distractions and focus entirely on the task.
- **Present moment focus**: Stay in the now, not worrying about past or future.

## Training for Flow

Like any skill, entering flow state can be practiced:

1. **Mindfulness meditation**: Builds present-moment awareness.
2. **Visualization**: Mental rehearsal helps create neural pathways.
3. **Progressive challenge**: Gradually increase difficulty in training.
4. **Pre-performance routines**: Create consistent preparation patterns.

## Conclusion

Flow state isn't mystical—it's a natural psychological state that can be deliberately cultivated. By understanding its mechanisms and practicing the right techniques, athletes can experience flow more consistently, leading to peak performances when it matters most.
''',
        thumbnailUrl: 'https://images.unsplash.com/photo-1507034589631-9433cc6bc453',
        publishedDate: DateTime.now().subtract(const Duration(days: 7)),
        tags: ['Flow State', 'Performance', 'Mental Skills'],
        readTimeMinutes: 6,
        focusAreas: ['Focus', 'Performance', 'Mindset'],
        universityExclusive: false,
      ),
      Article(
        id: 'article-002',
        title: 'Visualization Techniques for Elite Performance',
        authorId: 'coach-003',
        authorName: 'Emma Williams',
        authorImageUrl: 'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f',
        content: '''
# Visualization Techniques for Elite Performance

Visualization, also known as mental imagery or mental rehearsal, is one of the most powerful techniques used by elite athletes. From Michael Phelps to Serena Williams, the world's top performers use this technique to prepare for competition and enhance their performance.

## The Science of Visualization

When you visualize an action, you activate many of the same neural pathways that fire during the actual physical performance. This creates stronger neural connections, essentially "programming" your brain for success before you even step onto the field or court.

Research shows that visualization can:
- Improve motor skills and technique
- Enhance confidence and reduce anxiety
- Accelerate recovery from injury
- Improve focus and concentration
- Reinforce optimal movement patterns

## Advanced Visualization Techniques

### 1. PETTLEP Model

The PETTLEP model (Physical, Environment, Task, Timing, Learning, Emotion, Perspective) is a comprehensive approach to visualization that ensures your mental practice is as effective as possible:

- **Physical**: Incorporate physical elements (wearing gear, holding equipment)
- **Environment**: Visualize in similar environments to where you'll perform
- **Task**: Focus on the specific skills needed for your sport
- **Timing**: Visualize at the same speed as the actual performance
- **Learning**: Update your visualizations as your skills improve
- **Emotion**: Include the emotional states you'll experience
- **Perspective**: Use both internal (through your eyes) and external (watching yourself) perspectives

### 2. Success Rehearsal

Mentally rehearse successful performances in detail:
- Visualize perfect execution of skills
- See yourself overcoming challenges
- Feel the emotions of success

### 3. Process Visualization

Focus on the process rather than just the outcome:
- Visualize your pre-performance routine
- Mental rehearsal of technical elements
- Visualize responses to different scenarios

## Implementing Visualization in Your Routine

To make visualization a regular part of your training:

1. **Start small**: Begin with 5-10 minute sessions
2. **Be consistent**: Practice daily
3. **Engage all senses**: What do you see, hear, feel, smell, and taste?
4. **Use triggers**: Create a ritual that helps you enter a focused state
5. **Combine with relaxation**: Start with deep breathing or progressive muscle relaxation

## Conclusion

Visualization is not just "positive thinking" or daydreaming—it's a structured mental training technique with proven benefits. By consistently practicing these advanced visualization techniques, you can enhance your performance, boost your confidence, and prepare yourself for success in competition.
''',
        thumbnailUrl: 'https://images.unsplash.com/photo-1551632811-561732d1e306',
        publishedDate: DateTime.now().subtract(const Duration(days: 14)),
        tags: ['Visualization', 'Mental Training', 'Elite Performance'],
        readTimeMinutes: 8,
        focusAreas: ['Visualization', 'Performance', 'Preparation'],
        universityExclusive: false,
      ),
    ];
  }

  // Mock coaches data
  static List<Map<String, dynamic>> get dummyCoaches {
    return [
      {
        'id': 'coach-001',
        'name': 'Dr. Sarah Johnson',
        'title': 'Sports Psychologist',
        'bio': 'Former Olympic athlete with a PhD in Sports Psychology. Specializes in mental toughness training and performance under pressure.',
        'imageUrl': 'https://images.unsplash.com/photo-1571731956672-f2b94d7dd0cb',
        'rating': 4.9,
        'reviewCount': 142,
        'specialization': 'Mental Toughness',
        'experience': '15+ years',
        'courses': ['course-001'],
      },
      {
        'id': 'coach-002',
        'name': 'Michael Chen',
        'title': 'Focus & Attention Coach',
        'bio': 'Mind training specialist who has worked with professional athletes across multiple sports. Expert in concentration and focus enhancement.',
        'imageUrl': 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7',
        'rating': 4.7,
        'reviewCount': 98,
        'specialization': 'Focus & Attention',
        'experience': '10+ years',
        'courses': ['course-002'],
      },
      {
        'id': 'coach-003',
        'name': 'Emma Williams',
        'title': 'Performance Coach',
        'bio': 'Certified mental performance consultant who specializes in visualization techniques and confidence building for athletes of all levels.',
        'imageUrl': 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2',
        'rating': 4.8,
        'reviewCount': 112,
        'specialization': 'Visualization & Confidence',
        'experience': '12+ years',
        'courses': [],
      },
    ];
  }
} 