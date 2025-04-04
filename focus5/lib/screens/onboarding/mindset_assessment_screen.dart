import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'welcome_screen.dart';

class MindsetAssessmentScreen extends StatefulWidget {
  const MindsetAssessmentScreen({Key? key}) : super(key: key);

  @override
  State<MindsetAssessmentScreen> createState() => _MindsetAssessmentScreenState();
}

class _MindsetAssessmentScreenState extends State<MindsetAssessmentScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _assessmentComplete = false;
  
  // Store assessment responses
  double _stressManagementScore = 0.5;  // Default to middle value
  String _focusUnderPressureChoice = '';
  double _confidenceScore = 0.5;  // Default to middle value
  String _resilienceChoice = '';
  List<String> _motivationRanking = [];
  List<String> _motivationOptions = [
    '🏆 Achieve elite performance',
    '🌱 Grow as a person',
    '🤝 Support and uplift the team',
    '💪 Prove something to yourself'
  ];

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
      _completeAssessment();
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

  void _completeAssessment() async {
    // Save assessment responses to shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('stress_management_score', _stressManagementScore);
    await prefs.setString('focus_under_pressure', _focusUnderPressureChoice);
    await prefs.setDouble('confidence_score', _confidenceScore);
    await prefs.setString('resilience_choice', _resilienceChoice);
    await prefs.setStringList('motivation_ranking', _motivationRanking);
    
    setState(() {
      _assessmentComplete = true;
    });
    
    // Delay to show completion message before navigating
    Future.delayed(const Duration(seconds: 1), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const WelcomeScreen(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
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
          'Mindset Assessment',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/signup');
            },
            child: const Text(
              'SKIP',
              style: TextStyle(
                color: Color(0xFFB4FF00),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: _assessmentComplete 
          ? _buildCompletionScreen() 
          : _buildAssessmentPages(),
    );
  }

  Widget _buildCompletionScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle,
            color: Color(0xFFB4FF00),
            size: 80,
          ),
          const SizedBox(height: 24),
          const Text(
            'Assessment Complete!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'We\'ll personalize your experience based on your responses.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFB4FF00)),
          ),
        ],
      ),
    );
  }

  Widget _buildAssessmentPages() {
    return Column(
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
              _buildStressManagementPage(),
              _buildFocusUnderPressurePage(),
              _buildConfidenceReflectionPage(),
              _buildResilienceAfterSetbacksPage(),
              _buildMotivationRankingPage(),
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
                _currentPage < 4 ? 'NEXT' : 'COMPLETE',
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
    );
  }

  // 1. Stress Management Check
  Widget _buildStressManagementPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Stress Management',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Rate your pre-competition nerves right before the event.',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 48),
          
          // Emoji slider
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '😨',
                      style: TextStyle(fontSize: 42),
                    ),
                    const Text(
                      '😌',
                      style: TextStyle(fontSize: 42),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: _getStressColor(),
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
              
              // Midpoint marker
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: double.infinity,
                    height: 2,
                    color: Colors.transparent,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Your ideal zone is here →',
                          style: TextStyle(
                            fontSize: 14,
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
          
          const SizedBox(height: 32),
          
          // Color guide
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildColorLabel('Too anxious', Colors.red),
              _buildColorLabel('Ideal zone', Colors.amber),
              _buildColorLabel('Too calm', Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorLabel(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Color _getStressColor() {
    if (_stressManagementScore < 0.4) {
      return Colors.red;
    } else if (_stressManagementScore < 0.6) {
      return Colors.amber;
    } else {
      return Colors.green;
    }
  }

  // 2. Focus Under Pressure
  Widget _buildFocusUnderPressurePage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Focus Under Pressure',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'You\'re about to perform under pressure. The crowd is loud. You…',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 32),
          
          // Background with stadium-like animation
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              image: const DecorationImage(
                image: NetworkImage('https://picsum.photos/400/200?random=301'),
                fit: BoxFit.cover,
                opacity: 0.4,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.people,
                size: 60,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Thought bubble options
          _buildThoughtBubble(
            '🧠 Visualize your perfect execution.',
            'Visualization',
            _focusUnderPressureChoice == 'Visualization',
          ),
          
          const SizedBox(height: 16),
          
          _buildThoughtBubble(
            '🎧 Rely on your performance routine.',
            'Ritual',
            _focusUnderPressureChoice == 'Ritual',
          ),
          
          const SizedBox(height: 16),
          
          _buildThoughtBubble(
            '💥 Use the energy to fuel your drive.',
            'Emotional Fuel',
            _focusUnderPressureChoice == 'Emotional Fuel',
          ),
        ],
      ),
    );
  }

  Widget _buildThoughtBubble(String text, String value, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _focusUnderPressureChoice = value;
        });
        _provideHapticFeedback();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2A2A2A) : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFB4FF00) : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFB4FF00).withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 8,
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
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
  }

  // 3. Confidence Reflection
  Widget _buildConfidenceReflectionPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Confidence Reflection',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'How often do you visualize success?',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 48),
          
          // Visual analog slider with milestone labels
          Column(
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: const Color(0xFFB4FF00),
                  inactiveTrackColor: const Color(0xFF2A2A2A),
                  thumbColor: Colors.white,
                  trackHeight: 16,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 16),
                ),
                child: Slider(
                  value: _confidenceScore,
                  onChanged: (value) {
                    setState(() {
                      _confidenceScore = value;
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
                    _buildMilestoneLabel('🚫\nNever', _confidenceScore < 0.33),
                    _buildMilestoneLabel('📅\nWeekly', _confidenceScore >= 0.33 && _confidenceScore < 0.66),
                    _buildMilestoneLabel('⭐️\nDaily', _confidenceScore >= 0.66),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 48),
          
          // Visualization stars animation
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                double threshold = index * 0.2;
                bool isActive = _confidenceScore >= threshold;
                return Icon(
                  Icons.star,
                  size: 40,
                  color: isActive
                      ? const Color(0xFFB4FF00)
                      : const Color(0xFF2A2A2A),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneLabel(String label, bool isActive) {
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

  // 4. Resilience After Setbacks
  Widget _buildResilienceAfterSetbacksPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resilience After Setbacks',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'After a setback, I typically…',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 32),
          
          // Multiple choice with expandable pro tips
          _buildResilienceOption(
            '📉 Replay the frustration over and over.',
            'Rumination',
            'Try setting a time limit for negative emotions, then deliberately shift your focus.',
          ),
          
          const SizedBox(height: 16),
          
          _buildResilienceOption(
            '📊 Analyze what went wrong and adjust.',
            'Analysis',
            'Top athletes journal after setbacks to learn and grow from their experiences.',
          ),
          
          const SizedBox(height: 16),
          
          _buildResilienceOption(
            '🧘 Take time to reset mentally.',
            'Reset',
            'Studies show that brief mindfulness after setbacks can improve future performance.',
          ),
        ],
      ),
    );
  }

  Widget _buildResilienceOption(String text, String value, String proTip) {
    bool isSelected = _resilienceChoice == value;
    bool isExpanded = isSelected;

    return GestureDetector(
      onTap: () {
        setState(() {
          _resilienceChoice = value;
        });
        _provideHapticFeedback();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2A2A2A) : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFB4FF00) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    text,
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
            if (isExpanded) ...[
              const SizedBox(height: 16),
              const Divider(color: Colors.white24),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb,
                    color: Color(0xFFB4FF00),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pro Tip: $proTip',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 5. Motivation Ranking
  Widget _buildMotivationRankingPage() {
    // Initialize motivation ranking if empty
    if (_motivationRanking.isEmpty) {
      _motivationRanking = List.from(_motivationOptions);
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Motivation Ranking',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'What drives you? Rank your top motivators.',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 32),
          
          // Draggable priority sort list
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }
                final item = _motivationRanking.removeAt(oldIndex);
                _motivationRanking.insert(newIndex, item);
              });
              _provideHapticFeedback();
            },
            children: List.generate(_motivationRanking.length, (index) {
              return _buildDraggableItem(
                _motivationRanking[index],
                index,
                key: Key('drag-item-$index'),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggableItem(String text, int index, {required Key key}) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: index == 0 ? const Color(0xFFB4FF00) : Colors.transparent,
          width: 2,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            color: index == 0 ? Colors.white : Colors.white70,
            fontWeight: index == 0 ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: const Icon(
          Icons.drag_handle,
          color: Colors.white54,
        ),
      ),
    );
  }
} 