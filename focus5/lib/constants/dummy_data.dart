import '../models/user_model.dart';
import '../models/content_models.dart';

class DummyData {
  // Focus areas
  static final List<String> focusAreas = [
    'Confidence',
    'Anxiety Management',
    'Performance Under Pressure',
    'Focus & Concentration',
    'Motivation',
    'Resilience',
    'Team Dynamics',
    'Leadership',
    'Goal Setting',
    'Mental Toughness',
    'Pre-Competition Preparation',
    'Post-Competition Recovery',
  ];

  // Sports
  static final List<String> sports = [
    'Basketball',
    'Soccer',
    'Football',
    'Baseball',
    'Volleyball',
    'Tennis',
    'Swimming',
    'Track & Field',
    'Golf',
    'Hockey',
    'Lacrosse',
    'Rugby',
    'Cycling',
    'Wrestling',
    'Gymnastics',
    'Martial Arts',
    'Cross Country',
    'Rowing',
    'Skiing',
    'Other',
  ];

  // Dummy lessons
  static final List<Lesson> dummyLessons = [
    Lesson(
      id: 'lesson1',
      title: 'Mental Toughness',
      description: 'Develop mental toughness for athletic performance',
      imageUrl: 'https://source.unsplash.com/random/?mental,athlete',
      categories: ['Mental', 'Performance'],
      durationMinutes: 15,
    ),
    Lesson(
      id: 'lesson2',
      title: 'Focus Training',
      description: 'Improve your concentration and focus',
      imageUrl: 'https://source.unsplash.com/random/?focus,mind',
      categories: ['Focus', 'Training'],
      durationMinutes: 12,
    ),
    Lesson(
      id: 'lesson3',
      title: 'Visualization',
      description: 'Master the art of visualization for better performance',
      imageUrl: 'https://source.unsplash.com/random/?visualization',
      categories: ['Visualization', 'Mental'],
      durationMinutes: 10,
    ),
    Lesson(
      id: 'lesson4',
      title: 'Recovery',
      description: 'Mental techniques for faster recovery',
      imageUrl: 'https://source.unsplash.com/random/?recovery,relax',
      categories: ['Recovery', 'Relax'],
      premium: true,
      durationMinutes: 18,
    ),
  ];

  // Universities
  static final Map<String, String> universities = {
    'UCLA': 'UCLA001',
    'Stanford': 'STAN001',
    'Ohio State': 'OHST001',
    'Michigan': 'MICH001',
    'Duke': 'DUKE001',
    'UNC': 'UNC001',
    'Texas': 'TEX001',
    'USC': 'USC001',
    'Florida': 'FLA001',
    'LSU': 'LSU001',
  };

  // Dummy badges
  static final List<AppBadge> dummyBadges = [
    AppBadge(
      id: 'badge1',
      name: 'First Steps',
      description: 'Complete your first audio session',
      imageUrl: 'assets/images/badges/first_steps.png',
      earnedAt: DateTime.now().subtract(const Duration(days: 30)),
      xpValue: 50,
    ),
    AppBadge(
      id: 'badge2',
      name: 'Focus Master',
      description: 'Complete 5 focus training sessions',
      imageUrl: 'assets/images/badges/focus_master.png',
      earnedAt: DateTime.now().subtract(const Duration(days: 15)),
      xpValue: 100,
    ),
    AppBadge(
      id: 'badge3',
      name: 'Week Streak',
      description: 'Complete at least one session every day for a week',
      imageUrl: 'assets/images/badges/week_streak.png',
      earnedAt: DateTime.now().subtract(const Duration(days: 5)),
      xpValue: 150,
    ),
  ];

  // Dummy user
  static final User dummyUser = User(
    id: 'user1',
    email: 'athlete@example.com',
    fullName: 'Alex Johnson',
    username: 'athlete1',
    profileImageUrl: 'assets/images/profiles/athlete1.jpg',
    sport: sports[0],
    university: null,
    universityCode: null,
    isIndividual: true,
    focusAreas: [focusAreas[0], focusAreas[3], focusAreas[9]],
    xp: 750,
    badges: dummyBadges,
    completedCourses: ['course1', 'course3'],
    completedAudios: ['audio1', 'audio2', 'audio5'],
    streak: 7,
    createdAt: DateTime.now().subtract(const Duration(days: 30)),
    lastLoginDate: DateTime.now(),
  );

  // Dummy university user
  static final User dummyUniversityUser = User(
    id: 'user2',
    email: 'student@university.edu',
    fullName: 'Jordan Smith',
    username: 'student1',
    profileImageUrl: 'assets/images/profiles/student1.jpg',
    sport: sports[2],
    university: 'Ohio State',
    universityCode: 'OHST001',
    isIndividual: false,
    focusAreas: [focusAreas[1], focusAreas[4], focusAreas[7]],
    xp: 1250,
    badges: dummyBadges,
    completedCourses: ['course1', 'course2', 'course5'],
    completedAudios: ['audio1', 'audio3', 'audio4', 'audio6'],
    streak: 14,
    createdAt: DateTime.now().subtract(const Duration(days: 60)),
    lastLoginDate: DateTime.now(),
  );

  // Dummy coaches
  static final List<Map<String, dynamic>> dummyCoaches = [
    {
      'id': 'coach1',
      'name': 'Brooklyn Simmons',
      'specialization': 'Discipline',
      'imageUrl': 'https://picsum.photos/500/500?random=101',
      'location': 'New York City, NY',
      'experience': '12 years of coaching elite athletes',
      'bio': 'Expert in mental resilience and high-performance mindset. Helping individuals break barriers and achieve their full potential for over a decade.',
      'podcasts': [
        {
          'id': 'pod1',
          'title': 'The Power of Mental Resilience',
          'duration': '45 min',
          'imageUrl': 'https://picsum.photos/100/100?random=201',
        },
        {
          'id': 'pod2',
          'title': 'Discipline Equals Freedom',
          'duration': '32 min',
          'imageUrl': 'https://picsum.photos/100/100?random=202',
        }
      ],
      'lessons': [
        {
          'id': 'les1',
          'title': 'Mind Mastery',
          'count': 8,
        },
      ],
      'articles': [
        {
          'id': 'art1',
          'title': 'Finding Your Edge: Mental Toughness',
          'preview': 'Discover the techniques I use with Olympic athletes to develop unbreakable mental toughness...',
          'date': 'May 15, 2023',
        }
      ],
      'courses': [
        {
          'id': 'course1',
          'title': 'Elite Mental Performance',
          'duration': '4 weeks',
          'lessons': 16,
          'imageUrl': 'https://picsum.photos/400/200?random=301',
        }
      ]
    },
    {
      'id': 'coach2',
      'name': 'Annette Black',
      'specialization': 'Motivation',
      'imageUrl': 'https://picsum.photos/500/500?random=102',
      'location': 'Los Angeles, California',
      'experience': '10 years of mindset transformation',
      'bio': 'Expert in mental resilience and high-performance mindset. Helping individuals break barriers and achieve their full potential for over a decade.',
      'podcasts': [
        {
          'id': 'pod3',
          'title': 'Breaking Your Limits',
          'duration': '38 min',
          'imageUrl': 'https://picsum.photos/100/100?random=203',
        }
      ],
      'lessons': [
        {
          'id': 'les2',
          'title': 'Growth Path',
          'count': 5,
        },
        {
          'id': 'les3',
          'title': 'Motivation Mastery',
          'count': 7,
        }
      ],
      'articles': [
        {
          'id': 'art2',
          'title': 'The Science of Self-Motivation',
          'preview': 'Learn how to tap into your intrinsic motivational drivers and maintain consistency...',
          'date': 'April 3, 2023',
        }
      ],
      'courses': [
        {
          'id': 'course2',
          'title': 'Unstoppable Mindset',
          'duration': '6 weeks',
          'lessons': 24,
          'imageUrl': 'https://picsum.photos/400/200?random=302',
        }
      ]
    },
    {
      'id': 'coach3',
      'name': 'Devon Lane',
      'specialization': 'Focus',
      'imageUrl': 'https://picsum.photos/500/500?random=103',
      'location': 'Chicago, Illinois',
      'experience': '15 years in performance psychology',
      'bio': 'Performance psychologist specializing in attention training and focus enhancement for competitive athletes. Former Division I athlete with a passion for helping others achieve peak mental performance.',
      'podcasts': [
        {
          'id': 'pod4',
          'title': 'The Art of Deep Focus',
          'duration': '51 min',
          'imageUrl': 'https://picsum.photos/100/100?random=204',
        }
      ],
      'lessons': [
        {
          'id': 'les4',
          'title': 'Attention Training',
          'count': 9,
        }
      ],
      'articles': [
        {
          'id': 'art3',
          'title': 'Focus in the Age of Distraction',
          'preview': 'Practical strategies to improve your ability to concentrate in high-pressure situations...',
          'date': 'June 22, 2023',
        }
      ],
      'courses': [
        {
          'id': 'course3',
          'title': 'Focus Under Pressure',
          'duration': '3 weeks',
          'lessons': 12,
          'imageUrl': 'https://picsum.photos/400/200?random=303',
        }
      ]
    },
    {
      'id': 'coach4',
      'name': 'Cameron Wilson',
      'specialization': 'Leadership',
      'imageUrl': 'https://picsum.photos/500/500?random=104',
      'location': 'Seattle, Washington',
      'experience': '8 years coaching team captains',
      'bio': 'Former professional soccer player turned leadership coach. Specializing in helping athletes develop the mindset and communication skills needed to lead effectively both on and off the field.',
      'podcasts': [
        {
          'id': 'pod5',
          'title': 'Leading from Within',
          'duration': '42 min',
          'imageUrl': 'https://picsum.photos/100/100?random=205',
        }
      ],
      'lessons': [
        {
          'id': 'les5',
          'title': 'Team Leadership',
          'count': 6,
        }
      ],
      'articles': [],
      'courses': [
        {
          'id': 'course4',
          'title': "Captain's Mindset",
          'duration': '5 weeks',
          'lessons': 20,
          'imageUrl': 'https://picsum.photos/400/200?random=304',
        }
      ]
    },
    {
      'id': 'coach5',
      'name': 'Morgan Taylor',
      'specialization': 'Resilience',
      'imageUrl': 'https://picsum.photos/500/500?random=105',
      'location': 'Denver, Colorado',
      'experience': '11 years in mental conditioning',
      'bio': 'Specializing in helping athletes overcome setbacks and build mental resilience. Worked with Olympic medalists and professional teams to develop comeback strategies and mental toughness.',
      'podcasts': [],
      'lessons': [
        {
          'id': 'les6',
          'title': 'Bounce Back',
          'count': 8,
        },
        {
          'id': 'les7',
          'title': 'Mental Toughness',
          'count': 7,
        }
      ],
      'articles': [
        {
          'id': 'art4',
          'title': "The Champion's Response to Failure",
          'preview': 'Learn the exact process elite athletes use to transform setbacks into comebacks...',
          'date': 'July 11, 2023',
        }
      ],
      'courses': [
        {
          'id': 'course5',
          'title': 'Resilient Athlete Program',
          'duration': '8 weeks',
          'lessons': 32,
          'imageUrl': 'https://picsum.photos/400/200?random=305',
        }
      ]
    }
  ];

  // Dummy courses
  static final List<Course> dummyCourses = [
    Course(
      id: 'course1',
      title: 'Mental Toughness Development',
      description: 'Learn to develop mental toughness that will help you overcome challenges in sports and life. This comprehensive course covers resilience building, stress management, and performance under pressure.',
      imageUrl: 'https://picsum.photos/800/400?random=1',
      thumbnailUrl: 'https://picsum.photos/800/400?random=1',
      creatorId: 'coach1',
      creatorName: 'Brooklyn Simmons',
      creatorImageUrl: 'https://picsum.photos/500/500?random=101',
      tags: ['Mental Toughness', 'Resilience', 'Performance'],
      focusAreas: ['Mental Toughness', 'Resilience', 'Performance Under Pressure'],
      durationMinutes: 240,
      duration: 240,
      xpReward: 500,
      lessonsList: [
        Lesson(
          id: 'lesson1_1',
          title: 'Understanding Mental Toughness',
          description: 'Learn the core components of mental toughness and how it affects performance.',
          imageUrl: 'https://picsum.photos/800/400?random=21',
          categories: ['Mental Toughness', 'Psychology'],
          type: LessonType.video,
          videoUrl: 'https://example.com/videos/mental_toughness_intro.mp4',
          durationMinutes: 15,
          sortOrder: 1,
        ),
        Lesson(
          id: 'lesson1_2',
          title: 'Building Resilience',
          description: 'Discover practices to build resilience in the face of challenges.',
          imageUrl: 'https://picsum.photos/800/400?random=22',
          categories: ['Resilience', 'Techniques'],
          type: LessonType.video,
          videoUrl: 'https://example.com/videos/building_resilience.mp4',
          durationMinutes: 20,
          sortOrder: 2,
        ),
        Lesson(
          id: 'lesson1_3',
          title: 'Daily Mental Strength Exercises',
          description: 'A collection of daily exercises to build mental strength.',
          imageUrl: 'https://picsum.photos/800/400?random=23',
          categories: ['Mental Strength', 'Exercises'],
          type: LessonType.audio,
          audioUrl: 'https://example.com/audio/daily_mental_exercises.mp3',
          durationMinutes: 25,
          sortOrder: 3,
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      universityExclusive: false,
    ),
    
    Course(
      id: 'course2',
      title: 'Focus and Concentration Training',
      description: 'Enhance your ability to concentrate during critical moments. This course provides techniques to improve focus, eliminate distractions, and maintain attention when it matters most.',
      imageUrl: 'https://picsum.photos/800/400?random=2',
      thumbnailUrl: 'https://picsum.photos/800/400?random=2',
      creatorId: 'coach3',
      creatorName: 'Devon Lane',
      creatorImageUrl: 'https://picsum.photos/500/500?random=103',
      tags: ['Focus', 'Concentration', 'Attention'],
      focusAreas: ['Focus Training', 'Concentration', 'Attention'],
      durationMinutes: 180,
      duration: 180,
      xpReward: 450,
      lessonsList: [
        Lesson(
          id: 'lesson2_1',
          title: 'The Science of Focus',
          description: 'Understand how your brain focuses and what causes distractions.',
          imageUrl: 'https://picsum.photos/800/400?random=24',
          categories: ['Focus', 'Science'],
          type: LessonType.video,
          videoUrl: 'https://example.com/videos/science_of_focus.mp4',
          durationMinutes: 18,
          sortOrder: 1,
        ),
        Lesson(
          id: 'lesson2_2',
          title: 'Mindfulness for Athletes',
          description: 'Learn mindfulness techniques specifically designed for athletes.',
          imageUrl: 'https://picsum.photos/800/400?random=25',
          categories: ['Mindfulness', 'Techniques'],
          type: LessonType.video,
          videoUrl: 'https://example.com/videos/mindfulness_athletes.mp4',
          durationMinutes: 22,
          sortOrder: 2,
        ),
        Lesson(
          id: 'lesson2_3',
          title: 'Focus Under Pressure',
          description: 'Techniques to maintain focus during high-pressure situations.',
          imageUrl: 'https://picsum.photos/800/400?random=26',
          categories: ['Focus', 'Pressure'],
          type: LessonType.video,
          videoUrl: 'https://example.com/videos/focus_under_pressure.mp4',
          durationMinutes: 20,
          sortOrder: 3,
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
      universityExclusive: false,
    ),
    
    Course(
      id: 'course3',
      title: 'Motivation Mastery',
      description: 'Unlock your internal motivation and learn to stay driven through challenges and setbacks. This course covers motivation psychology, goal-setting, and maintaining consistency.',
      imageUrl: 'https://picsum.photos/800/400?random=3',
      thumbnailUrl: 'https://picsum.photos/800/400?random=3',
      creatorId: 'coach2',
      creatorName: 'Annette Black',
      creatorImageUrl: 'https://picsum.photos/500/500?random=102',
      tags: ['Motivation', 'Goals', 'Consistency'],
      focusAreas: ['Motivation', 'Goal Setting', 'Mental Edge'],
      durationMinutes: 210,
      duration: 210,
      xpReward: 475,
      lessonsList: [
        Lesson(
          id: 'lesson3_1',
          title: 'Understanding Your Motivational Drivers',
          description: 'Discover what truly motivates you as an individual.',
          imageUrl: 'https://picsum.photos/800/400?random=21',
          categories: ['Motivation', 'Psychology'],
          type: LessonType.video,
          videoUrl: 'https://example.com/videos/motivational_drivers.mp4',
          durationMinutes: 25,
          sortOrder: 1,
        ),
        Lesson(
          id: 'lesson3_2',
          title: 'Effective Goal Setting',
          description: 'Learn how to set goals that keep you motivated.',
          imageUrl: 'https://picsum.photos/800/400?random=22',
          categories: ['Goals', 'Planning'],
          type: LessonType.video,
          videoUrl: 'https://example.com/videos/effective_goal_setting.mp4',
          durationMinutes: 20,
          sortOrder: 2,
        ),
        Lesson(
          id: 'lesson3_3',
          title: 'Overcoming Motivation Slumps',
          description: 'Strategies for maintaining motivation during challenging periods.',
          imageUrl: 'https://picsum.photos/800/400?random=23',
          categories: ['Motivation', 'Resilience'],
          type: LessonType.audio,
          audioUrl: 'https://example.com/audio/motivation_slumps.mp3',
          durationMinutes: 18,
          sortOrder: 3,
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
      universityExclusive: false,
    ),
    
    Course(
      id: 'course4',
      title: 'Power Mindset Development',
      description: 'Develop the mindset of champions with this comprehensive course on mental power. Learn from elite performers about how to think, prepare, and execute at your highest level.',
      imageUrl: 'https://picsum.photos/800/400?random=4',
      thumbnailUrl: 'https://picsum.photos/800/400?random=4',
      creatorId: 'coach1',
      creatorName: 'Brooklyn Simmons',
      creatorImageUrl: 'https://picsum.photos/500/500?random=101',
      tags: ['Mindset', 'Power', 'Success'],
      focusAreas: ['Mental Toughness', 'Mindset'],
      durationMinutes: 190,
      duration: 190,
      xpReward: 425,
      lessonsList: [
        Lesson(
          id: 'lesson4_1',
          title: 'The Champion\'s Mindset',
          description: 'Understanding how elite athletes think before, during, and after competition.',
          imageUrl: 'https://picsum.photos/800/400?random=27',
          categories: ['Mindset', 'Psychology'],
          type: LessonType.video,
          videoUrl: 'https://example.com/videos/champions_mindset.mp4',
          durationMinutes: 22,
          sortOrder: 1,
        ),
        Lesson(
          id: 'lesson4_2',
          title: 'Mental Preparation Routines',
          description: 'Learn pre-competition mental routines used by Olympic athletes.',
          imageUrl: 'https://picsum.photos/800/400?random=28',
          categories: ['Preparation', 'Routines'],
          type: LessonType.video,
          videoUrl: 'https://example.com/videos/mental_preparation.mp4',
          durationMinutes: 24,
          sortOrder: 2,
        ),
        Lesson(
          id: 'lesson4_3',
          title: 'Visualization Techniques',
          description: 'Master the art of visualization to enhance performance.',
          imageUrl: 'https://picsum.photos/800/400?random=29',
          categories: ['Visualization', 'Techniques'],
          type: LessonType.audio,
          audioUrl: 'https://example.com/audio/visualization.mp3',
          durationMinutes: 20,
          sortOrder: 3,
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 75)),
      universityExclusive: false,
    ),
    
    Course(
      id: 'course5',
      title: 'Team Cohesion & Leadership',
      description: 'Learn how to build team unity and lead effectively in team environments. This course is ideal for team captains, coaches, and athletes wanting to improve team dynamics.',
      imageUrl: 'https://picsum.photos/800/400?random=5',
      thumbnailUrl: 'https://picsum.photos/800/400?random=5',
      creatorId: 'coach2',
      creatorName: 'Annette Black',
      creatorImageUrl: 'https://picsum.photos/500/500?random=102',
      tags: ['Team', 'Leadership', 'Cohesion'],
      focusAreas: ['Team Dynamics', 'Leadership', 'Communication'],
      durationMinutes: 220,
      duration: 220,
      xpReward: 480,
      lessonsList: [
        Lesson(
          id: 'lesson5_1',
          title: 'Understanding Team Dynamics',
          description: 'Learn the psychological factors that influence team performance.',
          imageUrl: 'https://picsum.photos/800/400?random=31',
          categories: ['Team Dynamics', 'Psychology'],
          type: LessonType.video,
          videoUrl: 'https://example.com/videos/team_dynamics.mp4',
          durationMinutes: 25,
          sortOrder: 1,
        ),
        Lesson(
          id: 'lesson5_2',
          title: 'Effective Communication in Teams',
          description: 'Master techniques for clear and supportive team communication.',
          imageUrl: 'https://picsum.photos/800/400?random=32',
          categories: ['Communication', 'Team'],
          type: LessonType.video,
          videoUrl: 'https://example.com/videos/team_communication.mp4',
          durationMinutes: 22,
          sortOrder: 2,
        ),
        Lesson(
          id: 'lesson5_3',
          title: 'Building Team Identity',
          description: 'Strategies for creating a strong, unified team culture.',
          imageUrl: 'https://picsum.photos/800/400?random=33',
          categories: ['Team', 'Identity'],
          type: LessonType.video,
          videoUrl: 'https://example.com/videos/team_identity.mp4',
          durationMinutes: 20,
          sortOrder: 3,
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
      universityExclusive: false,
    ),
  ];

  // Dummy daily audio modules
  static final List<DailyAudio> dummyAudioModules = [
    DailyAudio(
      id: 'audio1',
      title: 'Morning Confidence Boost',
      description: 'Start your day with this confidence-building exercise',
      audioUrl: 'assets/audio/morning_confidence.mp3',
      imageUrl: 'https://picsum.photos/500/300?random=10',
      creatorId: 'coach1',
      creatorName: 'Dr. Michael Brown',
      durationMinutes: 10,
      focusAreas: [focusAreas[0]],
      xpReward: 20,
      datePublished: DateTime.now().subtract(const Duration(days: 8)),
      universityExclusive: false,
      universityAccess: null,
      category: 'Focus',
    ),
    DailyAudio(
      id: 'audio2',
      title: 'Pre-Game Anxiety Relief',
      description: 'Use this audio before competition to calm nerves',
      audioUrl: 'assets/audio/pregame_anxiety.mp3',
      imageUrl: 'https://picsum.photos/500/300?random=11',
      creatorId: 'coach2',
      creatorName: 'Sarah Wilson',
      durationMinutes: 15,
      focusAreas: [focusAreas[1], focusAreas[2]],
      xpReward: 25,
      datePublished: DateTime.now().subtract(const Duration(days: 7)),
      universityExclusive: false,
      universityAccess: null,
      category: 'Breathing',
    ),
    DailyAudio(
      id: 'audio3',
      title: 'Focus Sharpening Session',
      description: 'Sharpen your focus before practice or competition',
      audioUrl: 'assets/audio/focus_sharp.mp3',
      imageUrl: 'https://picsum.photos/500/300?random=12',
      creatorId: 'coach1',
      creatorName: 'Dr. Michael Brown',
      durationMinutes: 12,
      focusAreas: [focusAreas[3]],
      xpReward: 20,
      datePublished: DateTime.now().subtract(const Duration(days: 6)),
      universityExclusive: false,
      universityAccess: null,
      category: 'Focus',
    ),
    DailyAudio(
      id: 'audio4',
      title: 'Motivation Booster',
      description: 'Listen when you need a motivation boost for training',
      audioUrl: 'assets/audio/motivation.mp3',
      imageUrl: 'https://picsum.photos/500/300?random=13',
      creatorId: 'coach2',
      creatorName: 'Sarah Wilson',
      durationMinutes: 10,
      focusAreas: [focusAreas[4]],
      xpReward: 20,
      datePublished: DateTime.now().subtract(const Duration(days: 5)),
      universityExclusive: false,
      universityAccess: null,
      category: 'Mindfulness',
    ),
    DailyAudio(
      id: 'audio5',
      title: 'Resilience Builder',
      description: 'Build mental resilience for overcoming challenges',
      audioUrl: 'assets/audio/resilience.mp3',
      imageUrl: 'https://picsum.photos/500/300?random=14',
      creatorId: 'coach1',
      creatorName: 'Dr. Michael Brown',
      durationMinutes: 15,
      focusAreas: [focusAreas[5]],
      xpReward: 25,
      datePublished: DateTime.now().subtract(const Duration(days: 4)),
      universityExclusive: false,
      universityAccess: null,
      category: 'Mindfulness',
    ),
    DailyAudio(
      id: 'audio6',
      title: 'Team Cohesion Visualization',
      description: 'Visualization exercise for improving team dynamics',
      audioUrl: 'assets/audio/team_cohesion.mp3',
      imageUrl: 'https://picsum.photos/500/300?random=15',
      creatorId: 'coach2',
      creatorName: 'Sarah Wilson',
      durationMinutes: 12,
      focusAreas: [focusAreas[6]],
      xpReward: 20,
      datePublished: DateTime.now().subtract(const Duration(days: 3)),
      universityExclusive: false,
      universityAccess: null,
      category: 'Visualization',
    ),
    DailyAudio(
      id: 'audio7',
      title: 'Leadership Development',
      description: 'For team captains and leaders to enhance leadership skills',
      audioUrl: 'assets/audio/leadership.mp3',
      imageUrl: 'https://picsum.photos/500/300?random=16',
      creatorId: 'coach3',
      creatorName: 'Coach James Davis',
      durationMinutes: 15,
      focusAreas: [focusAreas[7]],
      xpReward: 25,
      datePublished: DateTime.now().subtract(const Duration(days: 2)),
      universityExclusive: true,
      universityAccess: ['OHST001', 'MICH001'],
      category: 'Focus',
    ),
    DailyAudio(
      id: 'audio8',
      title: 'Game Day Mental Preparation',
      description: 'University athletes exclusive preparation for game day',
      audioUrl: 'assets/audio/gameday.mp3',
      imageUrl: 'https://picsum.photos/500/300?random=17',
      creatorId: 'coach3',
      creatorName: 'Coach James Davis',
      durationMinutes: 20,
      focusAreas: [focusAreas[10]],
      xpReward: 30,
      datePublished: DateTime.now().subtract(const Duration(days: 1)),
      universityExclusive: true,
      universityAccess: ['OHST001', 'MICH001'],
      category: 'Visualization',
    ),
    DailyAudio(
      id: 'audio9',
      title: 'Today\'s Focus Session',
      description: 'Daily focus training to improve concentration',
      audioUrl: 'assets/audio/today_focus.mp3',
      imageUrl: 'https://picsum.photos/500/300?random=18',
      creatorId: 'coach1',
      creatorName: 'Dr. Michael Brown',
      durationMinutes: 10,
      focusAreas: [focusAreas[3]],
      xpReward: 20,
      datePublished: DateTime.now(),
      universityExclusive: false,
      universityAccess: null,
      category: 'Focus',
    ),
  ];

  // Dummy journal entries
  static final List<JournalEntry> dummyJournalEntries = [
    JournalEntry(
      id: 'journal1',
      userId: 'user1',
      title: 'Pre-Competition Thoughts',
      content: 'Today I practiced the visualization techniques from the Focus Training course. I feel more prepared for tomorrow\'s competition and less anxious than usual.',
      tags: ['Competition', 'Anxiety', 'Focus'],
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      updatedAt: null,
    ),
    JournalEntry(
      id: 'journal2',
      userId: 'user1',
      title: 'Post-Game Reflection',
      content: 'We won today! I maintained my focus even when we were down in the second quarter. The breathing techniques really helped me stay calm under pressure.',
      tags: ['Reflection', 'Success', 'Techniques'],
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: null,
    ),
    JournalEntry(
      id: 'journal3',
      userId: 'user2',
      title: 'Team Dynamics',
      content: 'After today\'s practice, I feel like our team chemistry is improving. I\'ve been applying the leadership principles from Coach Davis\'s course and it seems to be helping.',
      tags: ['Team', 'Leadership', 'Practice'],
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      updatedAt: null,
    ),
  ];

  // Dummy articles
  static final List<Article> dummyArticles = [
    Article(
      id: 'article1',
      title: 'How to Be Motivated Every Day: Lessons Learned from Twyla Tharp',
      authorId: 'coach1',
      authorName: 'Brooklyn Simmons',
      authorImageUrl: 'https://picsum.photos/500/500?random=101',
      content: '''
This article is an excerpt from Atomic Habits, my New York Times bestselling book.

Twyla Tharp was born in Indiana and was named after the local "Pig Princess" at the Annual Muncie Fair, who went by Twila.

It wasn't the prettiest of starts, but Tharp turned it into something beautiful.

She is widely regarded as one of the greatest dancers and choreographers of the modern era. She is credited with choreographing the first crossover ballet and she has choreographed dances for the Paris Opera Ballet, The Royal Ballet, New York City Ballet, Boston Ballet, and many others. Her work has appeared on Broadway, on television, and in films. In 1992, she was awarded a MacArthur Fellowship, often referred to as the Genius Grant, and she has spent the bulk of her career touring the globe to perform her original works.

For years, Tharp has maintained the same morning routine. She wakes up at 5:30 a.m., puts on her workout clothes, and walks outside to hail a taxi to take her to the Pumping Iron gym at 91st Street and First Avenue, where she works out for two hours. When she returns home, she eats a hearty breakfast and gets to work.

"The ritual is not the stretching and weight training I put my body through each morning at the gym; the ritual is the cab," Tharp wrote. "The moment I tell the driver where to go I have completed the ritual."

"It's a simple act, but doing it the same way each morning habitualizes it—makes it repeatable, easy to do. It reduces the chance that I would skip it or do it differently. It is one more item in my arsenal of routines, and one less thing to think about."

As a dancer and choreographer, Tharp's greatest asset is her creativity. And yet, she cannot simply command creative energy to appear. But she can create daily habits that set the stage for her creative spirit to flourish.

"Creativity is a habit, and the best creativity is the result of good work habits. That's it in a nutshell."

It is not the moments of brilliant inspiration that seem to appear out of nowhere that create incredible art, but rather the everyday habits of the artist that lay the foundation for these breakthrough moments.

Creativity is not reserved for artists and musicians. Any role requiring problem-solving, innovation, or adaptation can benefit from cultivating creative habits. In sports psychology, creativity manifests as finding new approaches to training, visualizing success differently, or developing unique mental strategies for competition.

The power of habits can be summarized into one simple idea: success is not a sudden breakthrough but the product of daily disciplines. Your daily routines are the building blocks of excellence.

''',
      thumbnailUrl: 'https://picsum.photos/600/300?random=401',
      publishedDate: DateTime.now().subtract(const Duration(days: 5)),
      tags: ['Motivation', 'Discipline', 'Habits'],
      readTimeMinutes: 8,
      focusAreas: ['Motivation', 'Discipline'],
      universityExclusive: false,
      universityAccess: null,
    ),
    Article(
      id: 'article2',
      title: 'The Science of Self-Motivation: Why Traditional Approaches Fail',
      authorId: 'coach2',
      authorName: 'Annette Black',
      authorImageUrl: 'https://picsum.photos/500/500?random=102',
      content: '''
# The Science of Self-Motivation: Why Traditional Approaches Fail

Many athletes struggle with motivation, particularly during challenging training periods or after setbacks. The traditional approach of using external rewards or punishments often creates short-term compliance but fails to generate lasting motivation.

## The Motivation Paradox

Research in sports psychology reveals a fascinating paradox: the more you try to force motivation, the more elusive it becomes. This phenomenon, known as motivational crowding-out, explains why many conventional motivation techniques eventually fail.

When external pressures become the primary driver for action, intrinsic motivation—the natural desire to engage in an activity for its own sake—tends to diminish. This explains why athletes who once loved their sport can burn out when external pressures mount.

## The Self-Determination Framework

Instead of focusing solely on outcomes, research suggests building motivation around three core psychological needs:

1. **Autonomy**: Having meaningful choices and a sense of control
2. **Competence**: Experiencing growth and mastery
3. **Relatedness**: Feeling connected to others and part of something bigger

When these needs are met, intrinsic motivation naturally flourishes.

## Practical Applications for Athletes

Here are science-backed techniques that can transform your relationship with motivation:

### 1. Set process goals, not just outcome goals
Instead of focusing exclusively on winning or performance metrics, establish goals around the process of improvement itself. This shifts attention to factors within your control and creates more opportunities for positive reinforcement.

### 2. Create implementation intentions
Instead of vague intentions ("I'll train harder"), create specific if-then plans ("If it's Monday at 6 AM, then I'll do my sprint workout"). Research shows this approach dramatically increases follow-through.

### 3. Use identity-based motivation
Frame actions in terms of identity rather than outcomes. Instead of "I need to train today," try "I'm an athlete, and this is what athletes do." This subtle shift can make motivation more resilient to temporary discomfort.

The most sustainable motivation comes not from external pressure but from aligning your athletic pursuits with your values, identity, and sense of purpose. By understanding the science of motivation, you can transform your relationship with your sport and achieve the consistency that leads to excellence.
''',
      thumbnailUrl: 'https://picsum.photos/600/300?random=402',
      publishedDate: DateTime.now().subtract(const Duration(days: 14)),
      tags: ['Motivation', 'Psychology', 'Training'],
      readTimeMinutes: 6,
      focusAreas: ['Motivation', 'Mental Toughness'],
      universityExclusive: false,
      universityAccess: null,
    ),
    Article(
      id: 'article3',
      title: 'The Art of Deep Focus: Techniques from Elite Performers',
      authorId: 'coach3',
      authorName: 'Devon Lane',
      authorImageUrl: 'https://picsum.photos/500/500?random=103',
      content: '''
# The Art of Deep Focus: Techniques from Elite Performers

In the world of high-performance athletics, the ability to achieve and maintain deep focus can be the difference between victory and defeat. Elite performers across all domains have developed specialized techniques to enter states of profound concentration—techniques that you can adapt and apply to your own training and competition.

## Understanding Focus as a Skill

Focus isn't just a mental state; it's a trainable skill with specific components:

- **Selective attention**: The ability to attend to relevant stimuli while filtering out distractions
- **Sustained attention**: The capacity to maintain concentration over time
- **Divided attention**: The skill of managing multiple relevant inputs simultaneously
- **Attentional flexibility**: The capability to shift focus appropriately as circumstances change

## The Physiology of Focus

Research shows that peak focus states are characterized by:

- Increased blood flow to the prefrontal cortex
- Moderate increases in stress hormones like cortisol and norepinephrine
- A shift toward mid-range alpha and theta brainwaves
- Reduced activity in the default mode network (the brain's "mind-wandering" system)

## Focus Training Techniques from Elite Performers

### 1. The Pre-Performance Routine

Olympic gold medalist Michael Phelps famously used a meticulously crafted pre-race routine that included visualization, specific physical movements, and controlled breathing. This routine served as a trigger that primed his mind and body for deep focus.

**Application:** Develop your own pre-performance sequence that incorporates:
- 60 seconds of controlled breathing (4-second inhale, 6-second exhale)
- Physical cues (specific movements that signal readiness)
- Mental cues (a focusing phrase or image)

### 2. The Attention Anchor

Elite marathon runners often use "attention anchors"—specific focal points that prevent mind-wandering during grueling races. These might include focusing on breathing rhythm, foot strike, or even a mantra.

**Application:** Identify 2-3 attention anchors relevant to your sport. Practice returning to these anchors whenever your mind begins to wander during training.

### 3. The Distraction Inoculation Method

Used by military special forces and professional athletes alike, this technique involves deliberately practicing under increasingly distracting conditions to build focus resilience.

**Application:** Gradually introduce distractions into your training environment. Begin with minor disruptions (like background noise) and progressively increase the challenge as your focus muscles strengthen.

### 4. The 5-Minute Focus Reset

Even the most focused performers experience attentional drift. Top chess grandmasters and other cognitive athletes use structured reset protocols to quickly recalibrate their attention.

**Application:** When you notice your focus has drifted, implement this 30-second reset:
1. Take 3 deep breaths
2. Name 3 things you can observe in your immediate environment
3. Restate your primary performance objective
4. Return to your attention anchor

The ability to achieve deep focus isn't mystical or available only to a select few. By understanding the science behind peak attention and implementing these elite-tested techniques, you can dramatically enhance your capacity for sustained, high-quality focus in both training and competition.
''',
      thumbnailUrl: 'https://picsum.photos/600/300?random=403',
      publishedDate: DateTime.now().subtract(const Duration(days: 20)),
      tags: ['Focus', 'Concentration', 'Performance'],
      readTimeMinutes: 7,
      focusAreas: ['Focus & Concentration', 'Performance Under Pressure'],
      universityExclusive: false,
      universityAccess: null,
    ),
    Article(
      id: 'article4',
      title: 'Game Day Mental Preparation: A Step-by-Step Guide',
      authorId: 'coach1',
      authorName: 'Brooklyn Simmons',
      authorImageUrl: 'https://picsum.photos/500/500?random=101',
      content: '''
# Game Day Mental Preparation: A Step-by-Step Guide

The moments before competition often determine the quality of your performance. While physical preparation is vital, mental readiness is equally crucial yet frequently overlooked. This guide outlines a proven mental preparation framework used by elite athletes to consistently perform at their peak when it matters most.

## The Night Before: Setting the Foundation

### 1. Visualization Session (15 minutes)
Conduct a detailed visualization session where you mentally rehearse your ideal performance. Focus on:
- The key moments you'll likely encounter
- Your emotional responses to both success and challenges
- The specific feeling of executing your skills perfectly

Research shows that visualization activates many of the same neural pathways as physical practice, reinforcing skill execution and building confidence.

### 2. Prepare Your Game Day Checklist
Create a physical checklist of everything you'll need tomorrow. This simple act reduces cognitive load and prevents the anxiety that comes from last-minute scrambling.

### 3. Communication Boundary Setting
Decide when you'll stop checking messages and social media. Establish which people you will and won't communicate with before the competition.

## Morning of Competition: Activating Optimal Arousal

### 1. Morning Mindfulness (5-10 minutes)
Begin your day with a brief mindfulness practice focused on breathing and body awareness. This establishes a baseline of calm and presents an opportunity to notice and address any unusual tension.

### 2. Personalized Arousal Regulation
Different athletes require different arousal levels for optimal performance. Use your personalized techniques to achieve your ideal state:

- **For those who need to calm down**: Progressive muscle relaxation, extended exhale breathing (4-count in, 8-count out)
- **For those who need to energize**: Dynamic movement, motivational music, positive self-talk

## Pre-Competition: The Crucial Hour

### 1. Environment Management (45-60 minutes before)
Create your optimal preparation environment:
- Control noise exposure with headphones if necessary
- Find physical space that allows for your routine
- Limit interactions to supportive team members or coaches

### 2. Activation Routine (30-45 minutes before)
Engage in your sport-specific physical and mental activation routine:
- Dynamic movement patterns
- Skill visualization
- Technical cue review
- Mindset priming statements

### 3. Focus Narrowing (15-30 minutes before)
Progressively narrow your focus from broad to specific:
- Begin with general awareness of the environment
- Shift to awareness of your body and breathing
- Finally, focus exclusively on process goals and performance cues

## Final Moments: The Performance Trigger

In the final 5 minutes before competition, implement your performance trigger—a personalized sequence of thoughts, physical actions, and focus points that signal to your brain and body that it's time to perform.

A sample trigger sequence might include:
1. Three deep breaths
2. A physical gesture (like clapping hands twice)
3. A focusing phrase ("sharp and strong")
4. A final visualization of your first movement or action

By following this framework and adapting it to your individual needs, you create a mental preparation system that maximizes your chances of accessing your best skills when they count most. Remember that consistency is key—the more you practice this routine, the more automatic and effective it becomes.
''',
      thumbnailUrl: 'https://picsum.photos/600/300?random=404',
      publishedDate: DateTime.now().subtract(const Duration(days: 28)),
      tags: ['Game Day', 'Mental Preparation', 'Performance'],
      readTimeMinutes: 5,
      focusAreas: ['Pre-Competition Preparation', 'Performance Under Pressure'],
      universityExclusive: false,
      universityAccess: null,
    ),
  ];

  // Dummy media items (including video)
  static final List<MediaItem> dummyMediaItems = [
    MediaItem(
      id: 'video1',
      title: 'Is All Self-Criticism Bad?',
      description: 'Learn essential techniques to manage self-criticism and build mental resilience',
      mediaType: MediaType.video,
      mediaUrl: 'gs://focus-5-app.firebasestorage.app/modules/day3bouncebackcourse.mp4',
      imageUrl: 'https://picsum.photos/500/300?random=1',
      creatorId: 'coach5',
      creatorName: 'Morgan Taylor',
      durationMinutes: 5,
      focusAreas: [focusAreas[5], focusAreas[9]],
      xpReward: 30,
      datePublished: DateTime.now().subtract(const Duration(days: 1)),
      universityExclusive: false,
      universityAccess: null,
      category: 'Resilience',
    ),
    MediaItem(
      id: 'video2',
      title: 'Visualization Techniques for Athletes',
      description: 'Learn how visualization can enhance your athletic performance',
      mediaType: MediaType.video,
      mediaUrl: 'assets/videos/visualization_techniques.mp4',
      imageUrl: 'https://picsum.photos/500/300?random=2',
      creatorId: 'coach1',
      creatorName: 'Dr. Michael Brown',
      durationMinutes: 8,
      focusAreas: [focusAreas[0], focusAreas[4]],
      xpReward: 25,
      datePublished: DateTime.now().subtract(const Duration(days: 3)),
      universityExclusive: false,
      universityAccess: null,
      category: 'Visualization',
    ),
    MediaItem(
      id: 'audio1_media',
      title: 'Morning Confidence Boost',
      description: 'Start your day with this confidence-building exercise',
      mediaType: MediaType.audio,
      mediaUrl: 'assets/audio/morning_confidence.mp3',
      imageUrl: 'https://picsum.photos/500/300?random=3',
      creatorId: 'coach1',
      creatorName: 'Dr. Michael Brown',
      durationMinutes: 10,
      focusAreas: [focusAreas[0]],
      xpReward: 20,
      datePublished: DateTime.now().subtract(const Duration(days: 8)),
      universityExclusive: false,
      universityAccess: null,
      category: 'Focus',
    ),
  ];
} 