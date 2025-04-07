import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'profile_setup_screen.dart';

class SportSelectionScreen extends StatefulWidget {
  const SportSelectionScreen({Key? key}) : super(key: key);

  @override
  State<SportSelectionScreen> createState() => _SportSelectionScreenState();
}

class _SportSelectionScreenState extends State<SportSelectionScreen> with SingleTickerProviderStateMixin {
  String? _selectedSport;
  late AnimationController _animationController;
  int? _selectedSportIndex;
  
  // Sports list with emojis
  final Map<String, String> _sportEmojis = {
    'Basketball': '🏀',
    'Soccer': '⚽',
    'Football': '🏈',
    'Baseball': '⚾',
    'Volleyball': '🏐',
    'Tennis': '🎾',
    'Swimming': '🏊‍♀️',
    'Track & Field': '🏃‍♂️',
    'Golf': '⛳',
    'Hockey': '🏒',
    'Lacrosse': '🥍',
    'Rugby': '🏉',
    'Cycling': '🚴‍♀️',
    'Wrestling': '🤼‍♂️',
    'Gymnastics': '🤸‍♀️',
    'Martial Arts': '🥋',
    'Cross Country': '🏞️',
    'Rowing': '🚣‍♀️',
    'Skiing': '⛷️',
    'Other': '🏆',
  };
  
  // Sports list
  late List<String> _sports;
  
  @override
  void initState() {
    super.initState();
    _sports = _sportEmojis.keys.toList();
    
    // Initialize the animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    // Check if sport is already selected in signup
    _checkExistingSport();
  }
  
  Future<void> _checkExistingSport() async {
    final prefs = await SharedPreferences.getInstance();
    final existingSport = prefs.getString('selected_sport');
    
    // If a sport is already selected (from signup) and we're in onboarding flow
    if (existingSport != null && (prefs.getBool('from_onboarding_flow') ?? false)) {
      // Skip this screen and go directly to profile setup
      if (!mounted) return;
      
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const ProfileSetupScreen(fromOnboarding: true),
        ),
      );
    } else if (existingSport != null) {
      // If sport exists but we're not in onboarding, just set it
      setState(() {
        _selectedSport = existingSport;
        _selectedSportIndex = _sports.indexOf(existingSport);
      });
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  // Method to provide haptic feedback
  void _provideHapticFeedback() {
    HapticFeedback.mediumImpact();
  }
  
  void _selectSport(String sport, int index) {
    _provideHapticFeedback();
    setState(() {
      _selectedSport = sport;
      _selectedSportIndex = index;
      _animationController.reset();
      _animationController.forward();
    });
  }
  
  Future<void> _continueToNextScreen() async {
    if (_selectedSport == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a sport to continue')),
      );
      return;
    }
    
    // Save selected sport to shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_sport', _selectedSport!);
    
    // Check if we're in the onboarding flow
    final bool fromOnboardingFlow = prefs.getBool('from_onboarding_flow') ?? false;
    
    if (!mounted) return;
    
    if (fromOnboardingFlow) {
      // Continue to profile setup directly, skipping questionnaire
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const ProfileSetupScreen(fromOnboarding: true),
        ),
      );
    } else {
      // Navigate directly to home if not from onboarding
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Select Your Sport',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              // Save a default sport value when skipping
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('selected_sport', 'Other');
              
              if (!mounted) return;
              
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const ProfileSetupScreen(fromOnboarding: true),
                ),
              );
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
      body: Column(
        children: [
          // Header section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: const [
                Text(
                  'Select Your Sport',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'This helps us customize your mental training',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          // Main content section - sport grid
          Expanded(
            child: _buildSportGrid(),
          ),
          
          // Continue button
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _selectedSport != null ? _continueToNextScreen : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB4FF00),
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: Colors.grey.shade600,
                  disabledForegroundColor: Colors.grey.shade400,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'CONTINUE',
                  style: TextStyle(
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
  
  Widget _buildSportGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
      ),
      itemCount: _sports.length,
      itemBuilder: (context, index) {
        final sport = _sports[index];
        final isSelected = sport == _selectedSport;
        
        return GestureDetector(
          onTap: () => _selectSport(sport, index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF2A2A2A) : const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _sportEmojis[sport] ?? '🏆',
                  style: const TextStyle(
                    fontSize: 32,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  sport,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
} 