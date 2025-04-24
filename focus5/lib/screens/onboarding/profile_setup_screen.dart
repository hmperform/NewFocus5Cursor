import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'commitment_screen.dart';
import 'package:provider/provider.dart';
import '../welcome_screen.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/focus_button.dart';
import '../../providers/theme_provider.dart';
import '../../constants/sports.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../screens/main_navigation_screen.dart';
import 'champion_setup_screen.dart';
import 'coach_setup_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  static const routeName = '/profile_setup';
  final bool fromOnboarding;

  const ProfileSetupScreen({
    Key? key,
    this.fromOnboarding = false,
  }) : super(key: key);

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _universityController = TextEditingController();
  final TextEditingController _universityCodeController = TextEditingController();
  final FocusNode _universityFocusNode = FocusNode();
  final FocusNode _universityCodeFocusNode = FocusNode();
  bool _isUniversityValid = false;
  String? _selectedSport;
  String? _selectedUniversity;
  bool _isIndividual = true;
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  late AnimationController _animationController;
  
  // Focus areas that users can select
  final List<String> _focusAreas = [
    'Confidence', 'Anxiety', 'Focus', 'Pressure', 
    'Motivation', 'Discipline', 'Team Dynamics', 'Leadership',
    'Performance Anxiety', 'Visualization', 'Goal Setting'
  ];
  
  final List<String> _selectedFocusAreas = [];
  
  // List of universities
  final List<String> _universities = [
    'University of Florida',
    'Ohio State University',
    'Michigan State University',
    'University of Texas',
    'University of Alabama',
    'Stanford University',
    'Other'
  ];
  
  // Map of university codes (for verification)
  Map<String, String> _universityCodes = {};
  bool _isLoadingCodes = true;

  @override
  void initState() {
    super.initState();
    _loadPreSelectedSport();
    _loadUniversityCodes();
    _checkAuthStatus();
    
    // Initialize the animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _universityController.addListener(_validateInputs);
  }
  
  Future<void> _loadPreSelectedSport() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedSport = prefs.getString('selected_sport');
    });
  }
  
  Future<void> _loadUniversityCodes() async {
    setState(() {
      _isLoadingCodes = true;
    });
    
    try {
      // Load universities from Firestore
      final querySnapshot = await FirebaseFirestore.instance.collection('universities').get();
      
      Map<String, String> codes = {};
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        if (data.containsKey('name') && data.containsKey('code')) {
          codes[data['name']] = data['code'];
        }
      }
      
      setState(() {
        _universityCodes = codes;
        _isLoadingCodes = false;
      });
    } catch (e) {
      print('Error loading university codes: $e');
      setState(() {
        _isLoadingCodes = false;
      });
    }
  }
  
  Future<void> _checkAuthStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    await authProvider.checkAuthStatus();
    
    // Get profile setup status
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('is_first_launch') ?? true;
    
    // Only redirect to login if we're not in the initial profile setup flow
    if (authProvider.status != AuthStatus.authenticated && widget.fromOnboarding && !isFirstLaunch) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
      return;
    }
    
    // Ensure user data is loaded
    if (userProvider.user == null) {
      await userProvider.loadUserData(authProvider.currentUser?.id);
    }
  }
  
  void _validateInputs() {
    setState(() {
      _isUniversityValid = _universityController.text.trim().isNotEmpty;
    });
  }
  
  @override
  void dispose() {
    _universityController.dispose();
    _universityCodeController.dispose();
    _universityFocusNode.dispose();
    _universityCodeFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }
  
  // Method to provide haptic feedback
  void _provideHapticFeedback() {
    HapticFeedback.mediumImpact();
  }
  
  void _toggleFocusArea(String area) {
    _provideHapticFeedback();
    setState(() {
      if (_selectedFocusAreas.contains(area)) {
        _selectedFocusAreas.remove(area);
      } else {
        if (_selectedFocusAreas.length < 3) {
          _selectedFocusAreas.add(area);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You can select up to 3 focus areas')),
          );
        }
      }
    });
  }
  
  Future<bool> _handleCodeVerification(DocumentSnapshot doc, String code, bool isChampion, bool isCoach) async {
    try {
      final universityData = doc.data() as Map<String, dynamic>;
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      // Ensure we have a valid authenticated user
      if (authProvider.status != AuthStatus.authenticated || authProvider.currentUser == null) {
        print('User not properly authenticated');
        _showError('Please log in again');
        return false;
      }

      print('Verifying university code: $code - Is champion: $isChampion, Is coach: $isCoach');
      print('University document reference: ${doc.reference.path}');

      // Create profile update data with university as a document reference
      final success = await userProvider.updateUserProfile(
        isIndividual: false,
        university: doc.reference, // Pass the document reference
        universityCode: code.toUpperCase(),
        isPartnerChampion: isChampion,
        isPartnerCoach: isCoach,
      );

      if (!success) {
        print('Failed to update user profile with university data');
        _showError('Failed to update profile with university information');
        return false;
      }

      // Save to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('profile_setup_complete', true);
      await prefs.setString('university_code', code.toUpperCase());

      // Navigate based on role if verification was successful
      if (!mounted) return true;

      final user = userProvider.user;
      if (user == null) {
        _showError('User data not found');
        return false;
      }

      if (isChampion) {
        print('Navigating to ChampionSetupScreen');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ChampionSetupScreen(
              userName: user.fullName,
              universityCode: code.toUpperCase(),
            ),
          ),
        );
      } else if (isCoach) {
        print('Navigating to CoachSetupScreen');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => CoachSetupScreen(
              userName: user.fullName,
              universityCode: code.toUpperCase(),
            ),
          ),
        );
      } else {
        print('Navigating to CommitmentScreen');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => CommitmentScreen(
              userName: user.fullName,
              isIndividual: false,
              universityCode: code.toUpperCase(),
            ),
          ),
        );
      }

      return true;
    } catch (e) {
      print('Error in _handleCodeVerification: $e');
      _showError('An error occurred while verifying the code');
      setState(() => _isLoading = false); // Ensure loading state is reset on error
      return false;
    }
  }

  Future<bool> _verifyUniversityCode(String code) async {
    if (code.isEmpty) {
      _showError('Please enter a university code');
      return false;
    }

    try {
      print('Verifying university code: $code');
      
      // Check if the code is "MIACHAMP" (special champion code)
      if (code.toUpperCase() == "MIACHAMP") {
        print('Special MIACHAMP code detected');
        // Look for the matching university
        final universityQuery = await FirebaseFirestore.instance
            .collection('universities')
            .where('championCode', isEqualTo: code.toUpperCase())
            .get();
            
        if (universityQuery.docs.isNotEmpty) {
          print('Found university with champion code: ${universityQuery.docs.first.id}');
          return await _handleCodeVerification(universityQuery.docs.first, code, true, false);
        }
      }
      
      // Regular check for normal university code
      final querySnapshot = await FirebaseFirestore.instance
          .collection('universities')
          .where('code', isEqualTo: code.toUpperCase())
          .get();

      // Also check for champion and coach codes
      if (querySnapshot.docs.isEmpty) {
        print('No direct match found, checking champion codes');
        // Try finding by champion code
        final championQuery = await FirebaseFirestore.instance
            .collection('universities')
            .where('championCode', isEqualTo: code.toUpperCase())
            .get();

        if (championQuery.docs.isNotEmpty) {
          print('Found match with champion code');
          return await _handleCodeVerification(championQuery.docs.first, code, true, false);
        }

        print('No champion match, checking coach codes');
        // Try finding by coach code
        final coachQuery = await FirebaseFirestore.instance
            .collection('universities')
            .where('codeToJoinAsCoach', isEqualTo: code.toUpperCase())
            .get();

        if (coachQuery.docs.isNotEmpty) {
          print('Found match with coach code');
          return await _handleCodeVerification(coachQuery.docs.first, code, false, true);
        }

        print('No university found with code: $code');
        _showError('Invalid university code');
        return false;
      }

      // Handle regular university code
      print('Found regular university match');
      return await _handleCodeVerification(querySnapshot.docs.first, code, false, false);

    } catch (e) {
      print('Error verifying university code: $e');
      _showError('Error verifying code: $e');
      setState(() => _isLoading = false); // Ensure loading state is reset on error
      return false;
    }
  }

  // Add validation method for the university code field
  void _validateUniversityCode() async {
    final code = _universityCodeController.text.trim();
    if (code.isEmpty) {
      _showError('Please enter an organization code');
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    final isValid = await _verifyUniversityCode(code);
    
    if (!isValid) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Invalid organization code. Please check and try again.';
      });
    }
    // Note: We don't set _isLoading = false here if validation succeeded,
    // as the navigation in _handleCodeVerification will replace this screen
  }

  void _showError(String message) {
    setState(() {
      _hasError = true;
      _errorMessage = message;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSportSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Your Sport'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: sports.map((sport) => 
              ListTile(
                title: Text(sport),
                onTap: () async {
                  setState(() {
                    _selectedSport = sport;
                  });
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('selected_sport', sport);
                  Navigator.of(context).pop();
                },
              )
            ).toList(),
          ),
        ),
      ),
    );
  }

  Future<void> _handleContinue() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      print("_handleContinue: Starting with isIndividual = $_isIndividual");
      
      // For individual users, update profile
      if (_isIndividual) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        print("_handleContinue: Updating user profile for individual user");
        
        final success = await userProvider.updateUserProfile(
          isIndividual: true,
          isPartnerChampion: false,
          isPartnerCoach: false,
          university: null,
          universityCode: null,
        );

        if (!success) {
          print("_handleContinue: Failed to update profile");
          _showError('Failed to update profile');
          setState(() => _isLoading = false);
          return;
        }

        // Mark profile setup as complete
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('profile_setup_complete', true);

        if (!mounted) return;

        final user = userProvider.user;
        if (user == null) {
          print("_handleContinue: User data not found");
          _showError('User data not found');
          setState(() => _isLoading = false);
          return;
        }

        print("_handleContinue: Navigating to commitment screen");
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => CommitmentScreen(
              userName: user.fullName,
              isIndividual: true,
              universityCode: '',
            ),
          ),
        );
      } else {
        // For organization users, verify code
        final code = _universityCodeController.text.trim();
        print("_handleContinue: Verifying university code: $code");
        
        if (code.isEmpty) {
          print("_handleContinue: Empty university code");
          _showError('Please enter an organization code');
          setState(() => _isLoading = false);
          return;
        }
        
        final codeVerified = await _verifyUniversityCode(code);
        if (!codeVerified) {
          print("_handleContinue: Code verification failed");
          setState(() => _isLoading = false);
        }
        // Note: _verifyUniversityCode will handle setting _isLoading = false if needed
      }
    } catch (e) {
      print('Error in _handleContinue: $e');
      _showError('An error occurred. Please try again.');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final textColor = Theme.of(context).colorScheme.onBackground;
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Complete Your Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            // Main content section
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Almost There!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Complete your profile to personalize your mental training journey${_selectedSport != null ? " for $_selectedSport" : ""}.',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // Profile avatar placeholder
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A2A2A),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFB4FF00),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.person,
                              size: 64,
                              color: Colors.white70,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFFB4FF00),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.edit,
                                size: 20,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // Organization Type Selection
                    Text(
                      'I am a:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _isIndividual = true;
                                _selectedUniversity = null;
                                _universityCodeController.clear();
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _isIndividual
                                    ? const Color(0xFFB4FF00)
                                    : Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _isIndividual
                                      ? const Color(0xFFB4FF00)
                                      : Colors.grey.withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.person,
                                    color: _isIndividual
                                        ? Colors.black
                                        : textColor.withOpacity(0.7),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Individual',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _isIndividual
                                          ? Colors.black
                                          : textColor.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _isIndividual = false;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: !_isIndividual
                                    ? const Color(0xFFB4FF00)
                                    : Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: !_isIndividual
                                      ? const Color(0xFFB4FF00)
                                      : Colors.grey.withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.school,
                                    color: !_isIndividual
                                        ? Colors.black
                                        : textColor.withOpacity(0.7),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Partner/University',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: !_isIndividual
                                          ? Colors.black
                                          : textColor.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    // Organization code field (if Partner/University is selected)
                    if (!_isIndividual) ...[
                        const SizedBox(height: 24),
                        Text(
                          'Enter your organization code:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          controller: _universityCodeController,
                          hintText: 'Organization Code',
                          prefixIcon: Icons.vpn_key_outlined,
                          textCapitalization: TextCapitalization.characters,
                          helpText: _isLoadingCodes 
                              ? 'Loading organization codes...' 
                              : 'Enter the code provided by your organization',
                          onChanged: (value) {
                            if (_hasError) {
                              setState(() {
                                _hasError = false;
                                _errorMessage = '';
                              });
                            }
                          },
                          onSubmitted: (value) => _validateUniversityCode(),
                          suffix: IconButton(
                            icon: const Icon(Icons.check_circle_outline),
                            onPressed: _validateUniversityCode,
                            color: _selectedUniversity != null ? Colors.green : Colors.grey,
                          ),
                        ),
                    ],
                    
                    // Show error message if any
                    if (_hasError) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage,
                                style: const TextStyle(
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 32),
                    
                    // Sport display (if selected)
                    if (_selectedSport != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF2A2A2A),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Selected Sport',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white38,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.sports,
                                  color: Color(0xFFB4FF00),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _selectedSport!,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: 32),
                    
                    // Focus Areas Selection
                    const Text(
                      'Select Up to 3 Focus Areas',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'These help us personalize your mental training experience',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _focusAreas.map((area) {
                        final isSelected = _selectedFocusAreas.contains(area);
                        return GestureDetector(
                          onTap: () => _toggleFocusArea(area),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFB4FF00) : const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? const Color(0xFFB4FF00) : const Color(0xFF2A2A2A),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              area,
                              style: TextStyle(
                                color: isSelected ? Colors.black : Colors.white,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            
            // Continue button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FocusButton(
                  onPressed: _isLoading ? null : _handleContinue,
                  backgroundColor: themeProvider.accentColor,
                  child: _isLoading
                      ? CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDark ? Colors.black : Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Continue',
                              style: TextStyle(
                                color: isDark ? Colors.black : Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward,
                              color: isDark ? Colors.black : Colors.white,
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 