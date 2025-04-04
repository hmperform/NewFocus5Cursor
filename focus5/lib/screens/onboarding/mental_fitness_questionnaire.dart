import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import 'mental_fitness_results.dart';

class MentalFitnessQuestionnaire extends StatefulWidget {
  const MentalFitnessQuestionnaire({Key? key}) : super(key: key);

  @override
  State<MentalFitnessQuestionnaire> createState() => _MentalFitnessQuestionnaireState();
}

class _MentalFitnessQuestionnaireState extends State<MentalFitnessQuestionnaire> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  // Goals selection
  final List<String> _goals = [
    'Better handling setbacks',
    'Consistent focus',
    'Managing anxiety',
    'Performing under pressure',
    'Building confidence',
    'Team leadership',
    'Maintaining motivation',
    'Pre-competition routine',
    'Achieving flow state',
    'Mental anchoring',
  ];
  
  final List<String> _selectedGoals = [];
  String? _customGoal;
  
  // Personality type
  String? _personalityType;
  final List<PersonalityQuestion> _personalityQuestions = [
    PersonalityQuestion(
      question: 'In team settings, I usually...',
      options: [
        'Take charge and motivate others',
        'Analyze the situation and provide strategic guidance',
        'Support teammates and maintain harmony',
        'Focus on my own performance first'
      ],
      personalityMapping: [
        'Motivator', 
        'Strategist', 
        'Team Player', 
        'Individual Performer'
      ],
    ),
    PersonalityQuestion(
      question: 'When facing a challenging situation, I typically...',
      options: [
        'Dive right in with confidence',
        'Take time to plan and prepare',
        'Seek advice from coaches or teammates',
        'Rely on my instincts and adaptability'
      ],
      personalityMapping: [
        'Confidence-Driven',
        'Methodical',
        'Collaborative',
        'Adaptive'
      ],
    ),
    PersonalityQuestion(
      question: 'After a setback or loss, I tend to...',
      options: [
        'Analyze what went wrong and create a plan',
        'Use it as fuel to work harder',
        'Talk it through with others',
        'Take some time to mentally reset'
      ],
      personalityMapping: [
        'Analytical',
        'Resilient',
        'Expressive',
        'Reflective'
      ],
    ),
  ];
  
  final Map<int, int> _personalityAnswers = {};
  
  // Stress & Pressure handling
  double _stressManagementScore = 0.5;
  String _pressureResponse = '';
  final List<String> _pressureResponses = [
    'I embrace it and perform better',
    'I use mental techniques to stay calm',
    'I sometimes struggle but push through',
    'It often affects my performance'
  ];
  
  // Learning preferences
  final List<String> _learningPreferences = [
    'Visual demonstrations',
    'Detailed explanations',
    'Hands-on practice',
    'Real-world examples',
    'Group discussions'
  ];
  final List<String> _selectedLearningPrefs = [];
  
  // Method to provide haptic feedback
  void _provideHapticFeedback() {
    HapticFeedback.mediumImpact();
  }

  void _nextPage() {
    if (_currentPage < 4) {  // 5 questions (0-indexed)
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeQuestionnaire();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _completeQuestionnaire() async {
    // Save responses to shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('mental_fitness_goals', _selectedGoals);
    if (_customGoal != null) {
      await prefs.setString('custom_mental_fitness_goal', _customGoal!);
    }
    
    // Determine personality type based on answers
    final Map<String, int> personalityScores = {};
    
    _personalityAnswers.forEach((questionIndex, answerIndex) {
      final personalityType = _personalityQuestions[questionIndex].personalityMapping[answerIndex];
      personalityScores[personalityType] = (personalityScores[personalityType] ?? 0) + 1;
    });
    
    // Find the dominant personality type
    String dominantPersonality = 'Balanced';
    int highestScore = 0;
    
    personalityScores.forEach((personality, score) {
      if (score > highestScore) {
        highestScore = score;
        dominantPersonality = personality;
      }
    });
    
    await prefs.setString('personality_type', dominantPersonality);
    await prefs.setDouble('stress_management_score', _stressManagementScore);
    await prefs.setString('pressure_response', _pressureResponse);
    await prefs.setStringList('learning_preferences', _selectedLearningPrefs);
    
    if (!mounted) return;
    
    // Navigate to results page
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MentalFitnessResults(
          goals: _selectedGoals,
          customGoal: _customGoal,
          personalityType: dominantPersonality,
          stressScore: _stressManagementScore,
          pressureResponse: _pressureResponse,
          learningPreferences: _selectedLearningPrefs,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accentColor = themeProvider.accentColor;
    
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _currentPage > 0 
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: _previousPage,
              )
            : null,
        title: const Text(
          'Mental Fitness Questionnaire',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _completeQuestionnaire,
            child: Text(
              'SKIP',
              style: TextStyle(
                color: accentColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: LinearProgressIndicator(
              value: (_currentPage + 1) / 5,  // 5 questions total
              backgroundColor: const Color(0xFF1E1E1E),
              color: const Color(0xFFB4FF00),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          
          // Question pages
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: [
                _buildGoalsPage(),
                _buildPersonalityTypePage(),
                _buildStressAndPressurePage(),
                _buildLearningPreferencesPage(),
                _buildSummaryPage(),
              ],
            ),
          ),
          
          // Navigation buttons
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _nextPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB4FF00),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _currentPage < 4 ? 'CONTINUE' : 'COMPLETE',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildGoalsPage() {
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        const Text(
          'Mental Training Goals',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Select what you want to improve:',
          style: TextStyle(
            fontSize: 18,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 24),
        
        // Grid of goals
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _goals.length,
          itemBuilder: (context, index) {
            final goal = _goals[index];
            final isSelected = _selectedGoals.contains(goal);
            
            return InkWell(
              onTap: () {
                _provideHapticFeedback();
                setState(() {
                  if (isSelected) {
                    _selectedGoals.remove(goal);
                  } else {
                    _selectedGoals.add(goal);
                  }
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF2A2A2A) : const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFB4FF00) : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      goal,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        
        const SizedBox(height: 24),
        
        // Custom goal input
        const Text(
          'Or tell us your own goal:',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          onChanged: (value) {
            setState(() {
              _customGoal = value.isEmpty ? null : value;
            });
          },
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter your mental fitness goal...',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF1E1E1E),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFB4FF00), width: 2),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildPersonalityTypePage() {
    return ListView.builder(
      padding: const EdgeInsets.all(24.0),
      itemCount: _personalityQuestions.length + 1, // +1 for the header
      itemBuilder: (context, index) {
        if (index == 0) {
          // Header
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Athlete Personality Type',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Understanding your mindset helps us personalize your training:',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                ),
              ),
              SizedBox(height: 24),
            ],
          );
        }
        
        // Question cards
        final questionIndex = index - 1;
        final question = _personalityQuestions[questionIndex];
        
        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                question.question,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              ...List.generate(question.options.length, (optionIndex) {
                final isSelected = _personalityAnswers[questionIndex] == optionIndex;
                
                return InkWell(
                  onTap: () {
                    _provideHapticFeedback();
                    setState(() {
                      _personalityAnswers[questionIndex] = optionIndex;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF2A2A2A) : const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? const Color(0xFFB4FF00) : const Color(0xFF2A2A2A),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            question.options[optionIndex],
                            style: TextStyle(
                              fontSize: 16,
                              color: isSelected ? Colors.white : Colors.white70,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFFB4FF00),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildStressAndPressurePage() {
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        const Text(
          'Stress & Pressure Management',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'How do you currently handle stress?',
          style: TextStyle(
            fontSize: 18,
            color: Colors.white70,
          ),
        ),
        
        const SizedBox(height: 32),
        
        // Pressure response options
        ...List.generate(_pressureResponses.length, (index) {
          final response = _pressureResponses[index];
          final isSelected = _pressureResponse == response;
          
          return GestureDetector(
            onTap: () {
              _provideHapticFeedback();
              setState(() {
                _pressureResponse = response;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF2A2A2A) : const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? const Color(0xFFB4FF00) : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      response,
                      style: TextStyle(
                        fontSize: 16,
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFFB4FF00),
                    ),
                ],
              ),
            ),
          );
        }),
        
        const SizedBox(height: 32),
        
        // Stress management slider
        const Text(
          'Rate your ability to stay calm under stress:',
          style: TextStyle(
            fontSize: 18,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 24),
        
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFFB4FF00),
            inactiveTrackColor: const Color(0xFF2A2A2A),
            thumbColor: Colors.white,
            trackHeight: 16,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 16),
          ),
          child: Slider(
            value: _stressManagementScore,
            onChanged: (value) {
              setState(() {
                _stressManagementScore = value;
              });
              _provideHapticFeedback();
            },
          ),
        ),
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSliderLabel('Needs\nWork', _stressManagementScore < 0.33),
              _buildSliderLabel('Average', _stressManagementScore >= 0.33 && _stressManagementScore < 0.66),
              _buildSliderLabel('Excellent', _stressManagementScore >= 0.66),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildSliderLabel(String label, bool isActive) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFB4FF00) : const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isActive ? Colors.black : Colors.white70,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
  
  Widget _buildLearningPreferencesPage() {
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        const Text(
          'Learning & Visualization',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'How do you learn most effectively?',
          style: TextStyle(
            fontSize: 18,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 32),
        
        // Learning preferences checkboxes
        ...List.generate(_learningPreferences.length, (index) {
          final preference = _learningPreferences[index];
          final isSelected = _selectedLearningPrefs.contains(preference);
          
          return GestureDetector(
            onTap: () {
              _provideHapticFeedback();
              setState(() {
                if (isSelected) {
                  _selectedLearningPrefs.remove(preference);
                } else {
                  _selectedLearningPrefs.add(preference);
                }
              });
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? const Color(0xFFB4FF00) : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFB4FF00) : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected ? const Color(0xFFB4FF00) : Colors.white38,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.black,
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      preference,
                      style: TextStyle(
                        fontSize: 16,
                        color: isSelected ? Colors.white : Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
  
  Widget _buildSummaryPage() {
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        const Text(
          'Almost there!',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'We\'ll use your responses to create a personalized mental fitness plan.',
          style: TextStyle(
            fontSize: 18,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 32),
        
        // Summary card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Responses',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFB4FF00),
                ),
              ),
              const SizedBox(height: 24),
              
              // Goals
              const Text(
                'Mental Fitness Goals:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedGoals.isEmpty 
                    ? (_customGoal != null ? _customGoal! : 'None selected')
                    : _selectedGoals.join(', ') + (_customGoal != null ? ', $_customGoal' : ''),
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 16),
              
              // Personality 
              const Text(
                'Personality Questions Answered:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_personalityAnswers.length} of ${_personalityQuestions.length}',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 16),
              
              // Pressure response
              const Text(
                'Pressure Response:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _pressureResponse.isEmpty ? 'Not selected' : _pressureResponse,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 16),
              
              // Learning preferences
              const Text(
                'Learning Preferences:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedLearningPrefs.isEmpty ? 'None selected' : _selectedLearningPrefs.join(', '),
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 32),
        const Center(
          child: Text(
            'Press COMPLETE to see your personalized results',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }
}

class PersonalityQuestion {
  final String question;
  final List<String> options;
  final List<String> personalityMapping;
  
  PersonalityQuestion({
    required this.question,
    required this.options,
    required this.personalityMapping,
  });
} 