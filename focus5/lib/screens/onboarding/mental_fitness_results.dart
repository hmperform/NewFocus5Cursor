import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'profile_setup_screen.dart';

class MentalFitnessResults extends StatefulWidget {
  final List<String> goals;
  final String? customGoal;
  final String personalityType;
  final double stressScore;
  final String pressureResponse;
  final List<String> learningPreferences;

  const MentalFitnessResults({
    Key? key,
    required this.goals,
    this.customGoal,
    required this.personalityType,
    required this.stressScore,
    required this.pressureResponse,
    required this.learningPreferences,
  }) : super(key: key);

  @override
  State<MentalFitnessResults> createState() => _MentalFitnessResultsState();
}

class _MentalFitnessResultsState extends State<MentalFitnessResults> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _userName = "Athlete";
  String? _sport;
  String? _position;
  
  // Story sections
  String _strengthsNarrative = '';
  String _growthNarrative = '';
  String _recommendationNarrative = '';
  
  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    
    _loadUserData();
    _generatePersonalizedStory();
    
    _animationController.forward();
  }
  
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? "Athlete";
      _sport = prefs.getString('selected_sport');
      _position = prefs.getString('selected_position');
    });
  }
  
  void _generatePersonalizedStory() {
    // Generate strengths narrative based on personality type
    switch (widget.personalityType) {
      case 'Motivator':
        _strengthsNarrative = "As a natural motivator, your ability to inspire others and maintain a positive mindset gives you a distinctive edge. This leadership quality helps you navigate challenges with confidence and brings out the best in your teammates.";
        break;
      case 'Strategist':
        _strengthsNarrative = "Your analytical mind sets you apart as a strategic thinker who excels at planning and anticipating scenarios. This thoughtful approach allows you to see patterns and opportunities that others might miss.";
        break;
      case 'Team Player':
        _strengthsNarrative = "Your collaborative nature makes you an exceptional team player who thrives in group settings. The trust you build with teammates creates a foundation for collective success and personal growth.";
        break;
      case 'Individual Performer':
        _strengthsNarrative = "Your self-directed focus gives you remarkable discipline and determination. This independent drive allows you to maintain high standards and push yourself beyond perceived limitations.";
        break;
      case 'Confidence-Driven':
        _strengthsNarrative = "Your natural confidence is a powerful asset that helps you face challenges head-on. This self-assurance creates a positive feedback loop that enhances performance under pressure.";
        break;
      case 'Methodical':
        _strengthsNarrative = "Your methodical approach to challenges gives you exceptional consistency. This structured mindset helps you build reliable routines that deliver results even in high-pressure situations.";
        break;
      case 'Adaptive':
        _strengthsNarrative = "Your adaptability is an incredible strength that helps you thrive in changing circumstances. This flexibility allows you to adjust tactics and mindset as situations evolve.";
        break;
      case 'Analytical':
        _strengthsNarrative = "Your analytical approach to setbacks transforms them into valuable learning experiences. This problem-solving mindset helps you continuously refine your mental and physical game.";
        break;
      case 'Resilient':
        _strengthsNarrative = "Your resilience is remarkable – you bounce back from setbacks stronger than before. This tenacity allows you to maintain momentum through highs and lows in your athletic journey.";
        break;
      case 'Expressive':
        _strengthsNarrative = "Your expressive nature helps you process emotions effectively and build strong connections. This emotional intelligence supports both your well-being and your ability to perform under pressure.";
        break;
      case 'Reflective':
        _strengthsNarrative = "Your reflective mindset gives you exceptional self-awareness and learning capacity. This introspective quality helps you continuously refine your mental approach to challenges.";
        break;
      default:
        _strengthsNarrative = "Your balanced approach to mental fitness gives you adaptability across different situations. This well-rounded mindset helps you draw on various strengths as circumstances require.";
    }
    
    // Generate growth narrative based on goals and stress handling
    if (widget.goals.isNotEmpty || widget.customGoal != null) {
      String goalFocus = '';
      if (widget.goals.contains('Better handling setbacks') || widget.goals.contains('Resilience')) {
        goalFocus = 'building resilience';
      } else if (widget.goals.contains('Consistent focus') || widget.goals.contains('Performing under pressure')) {
        goalFocus = 'strengthening your focus';
      } else if (widget.goals.contains('Managing anxiety')) {
        goalFocus = 'managing pre-competition anxiety';
      } else if (widget.goals.contains('Building confidence')) {
        goalFocus = 'developing unshakable confidence';
      } else if (widget.customGoal != null) {
        goalFocus = 'working on ${widget.customGoal!.toLowerCase()}';
      } else {
        goalFocus = 'enhancing your mental performance';
      }
      
      // Stress score narrative
      String stressNarrative = '';
      if (widget.stressScore < 0.33) {
        stressNarrative = "While you've identified stress management as an area for improvement, this awareness itself is a significant step forward. With dedicated training,";
      } else if (widget.stressScore < 0.66) {
        stressNarrative = "You already have solid fundamentals in managing pressure, and with focused practice,";
      } else {
        stressNarrative = "Your excellent stress management skills give you a strong foundation, and with continued refinement,";
      }
      
      _growthNarrative = "Your journey ahead focuses on $goalFocus, which will amplify your overall performance. $stressNarrative you'll develop the mental tools to perform with greater consistency and confidence.";
    } else {
      _growthNarrative = "Your mental fitness journey will focus on building a well-rounded psychological toolkit that complements your physical training. As you develop these mental skills, you'll notice improvements in your consistency, confidence, and enjoyment of your sport.";
    }
    
    // Generate recommendations based on learning preferences
    String learningApproach = '';
    if (widget.learningPreferences.isEmpty) {
      learningApproach = "We'll use a balanced approach of guided exercises, visualization techniques, and practical applications";
    } else if (widget.learningPreferences.contains('Visual demonstrations')) {
      learningApproach = "We'll emphasize visual learning through demonstrations, video analysis, and visualization exercises";
    } else if (widget.learningPreferences.contains('Detailed explanations')) {
      learningApproach = "We'll provide in-depth explanations of mental techniques and their scientific foundations";
    } else if (widget.learningPreferences.contains('Hands-on practice')) {
      learningApproach = "We'll focus on practical exercises and real-time applications of mental techniques";
    } else {
      learningApproach = "We'll use your preferred learning approaches with customized content delivery";
    }
    
    _recommendationNarrative = "To support your development, $learningApproach that align with your learning preferences. Each day, you'll have access to tailored content designed to incrementally build your mental fitness.";
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    String sportSpecificText = '';
    if (_sport != null) {
      sportSpecificText = _position != null 
          ? ", as a $_position $_sport athlete"
          : ", as a $_sport athlete"; 
    }
    
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with personality type
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2A2A2A), Color(0xFF1E1E1E)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "YOUR ATHLETE MENTAL STORY",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFB4FF00),
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFB4FF00).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _getPersonalityIcon(),
                                    color: const Color(0xFFB4FF00),
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "The $_userName Profile",
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Personality Type: ${widget.personalityType}",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Personalized narrative
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Your Mental Fitness Story$sportSpecificText",
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // Strengths section
                          _buildStorySection(
                            "Your Strengths",
                            _strengthsNarrative,
                            Icons.star,
                            const Color(0xFFB4FF00),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Growth opportunities section
                          _buildStorySection(
                            "Your Growth Path",
                            _growthNarrative,
                            Icons.trending_up,
                            Colors.amber,
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Recommendations section
                          _buildStorySection(
                            "Your Training Plan",
                            _recommendationNarrative,
                            Icons.psychology,
                            Colors.lightBlueAccent,
                          ),
                          
                          const SizedBox(height: 30),
                          
                          // Mental Journey Map
                          _buildMentalJourneyMap(),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Continue button
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => const ProfileSetupScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB4FF00),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                          ),
                          child: const Text(
                            "BEGIN YOUR JOURNEY",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildStorySection(String title, String content, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
  
  IconData _getPersonalityIcon() {
    switch (widget.personalityType) {
      case 'Motivator':
        return Icons.emoji_people;
      case 'Strategist':
        return Icons.lightbulb;
      case 'Team Player':
        return Icons.groups;
      case 'Individual Performer':
        return Icons.person;
      case 'Confidence-Driven':
        return Icons.speed;
      case 'Methodical':
        return Icons.checklist;
      case 'Adaptive':
        return Icons.change_circle;
      case 'Analytical':
        return Icons.analytics;
      case 'Resilient':
        return Icons.fitness_center;
      case 'Expressive':
        return Icons.record_voice_over;
      case 'Reflective':
        return Icons.psychology;
      default:
        return Icons.stars;
    }
  }
  
  Widget _buildMentalJourneyMap() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.purple.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.map,
                  color: Colors.purple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Your Mental Journey Map',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color(0xFF1E1E1E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: const Text(
                        'Mental Journey Map',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      content: const Text(
                        'This visualization shows your starting point and where our training will take you. The journey from foundation to mastery follows a personalized path based on your goals and profile.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text(
                            'Got it',
                            style: TextStyle(
                              color: Color(0xFFB4FF00),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.purple,
                      width: 1,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.question_mark,
                      size: 14,
                      color: Colors.purple,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Journey map visualization
          SizedBox(
            height: 120,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Journey line
                Positioned(
                  left: 0,
                  right: 0,
                  top: 50,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.grey.shade700,
                          Colors.blue.shade300,
                          Colors.purple,
                          const Color(0xFFB4FF00),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                
                // Starting point
                Positioned(
                  left: 0,
                  top: 40,
                  child: Column(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade700,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            '🧱',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Foundation',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Current position - dynamically calculated based on personality type and stress score
                Positioned(
                  left: _calculateJourneyPosition(),
                  top: 30,
                  child: Column(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade300,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.shade300.withOpacity(0.5),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            '👤',
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade900.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'YOU ARE HERE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Goal point - positioned based on goals
                Positioned(
                  right: 0,
                  top: 40,
                  child: Column(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: const Color(0xFFB4FF00),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            '🚀',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Mastery',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Milestones along the journey
                if (widget.goals.isNotEmpty)
                  ...List.generate(
                    widget.goals.length > 3 ? 3 : widget.goals.length,
                    (index) {
                      final double position = (index + 1) * (MediaQuery.of(context).size.width - 112) / 4;
                      return Positioned(
                        left: position,
                        top: 68,
                        child: Column(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.7),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              width: 80,
                              child: Text(
                                widget.goals[index],
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white70,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          Text(
            'This personalized map represents your mental training journey. Starting with foundational skills and progressing through ${widget.goals.isEmpty ? "key milestones" : _getGoalsList()} toward mastery.',
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper method to format goals list
  String _getGoalsList() {
    if (widget.goals.length == 1) {
      return widget.goals[0].toLowerCase();
    } else if (widget.goals.length == 2) {
      return "${widget.goals[0].toLowerCase()} and ${widget.goals[1].toLowerCase()}";
    } else {
      return "${widget.goals[0].toLowerCase()}, ${widget.goals[1].toLowerCase()}, and more";
    }
  }
  
  // Helper method to calculate journey position
  double _calculateJourneyPosition() {
    // Base position is affected by personality type and stress score
    double basePosition = 0;
    
    // Confidence-based personality types start further ahead
    if (['Confidence-Driven', 'Resilient', 'Adaptive'].contains(widget.personalityType)) {
      basePosition += 30;
    }
    
    // Stress management score affects position
    basePosition += (widget.stressScore * 40);
    
    // Scale to the width of the container minus padding and point width
    final availableWidth = MediaQuery.of(context).size.width - 100; // Adjust for container padding
    return (basePosition / 100) * availableWidth;
  }
} 