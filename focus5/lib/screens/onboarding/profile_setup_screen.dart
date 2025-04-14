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
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _universityController = TextEditingController();
  final TextEditingController _universityCodeController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _universityFocusNode = FocusNode();
  final FocusNode _universityCodeFocusNode = FocusNode();
  bool _isNameValid = false;
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
    
    // Initialize the animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _nameController.addListener(_validateInputs);
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
  
  void _validateInputs() {
    setState(() {
      _isNameValid = _nameController.text.trim().length >= 2;
      _isUniversityValid = _universityController.text.trim().isNotEmpty;
    });
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _universityController.dispose();
    _universityCodeController.dispose();
    _nameFocusNode.dispose();
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
  
  Future<bool> _verifyUniversityCode(String code) async {
    if (_selectedUniversity == 'Other') return true;
    
    try {
      // Check if the university exists with this code
      final docSnapshot = await FirebaseFirestore.instance
          .collection('universities')
          .doc(code)
          .get();
      
      return docSnapshot.exists;
    } catch (e) {
      print('Error verifying university code: $e');
      return false;
    }
  }

  void _handleContinue() async {
    HapticFeedback.mediumImpact();
    
    if (!_isNameValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }
    
    if (_selectedFocusAreas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one focus area')),
      );
      return;
    }
    
    if (!_isIndividual && _selectedUniversity == null) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Please select your university';
      });
      return;
    }
    
    if (!_isIndividual && _selectedUniversity != 'Other' && _universityCodeController.text.trim().isEmpty) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Please enter your university code';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    
    // Verify university code if not individual
    if (!_isIndividual && _selectedUniversity != 'Other') {
      final code = _universityCodeController.text.trim();
      final isValidCode = await _verifyUniversityCode(code);
      
      if (!isValidCode) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Invalid university code';
        });
        return;
      }
    }
    
    _provideHapticFeedback();
    
    // Save profile to shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _nameController.text.trim());
    
    if (_universityController.text.isNotEmpty) {
      await prefs.setString('university', _universityController.text.trim());
    }
    
    if (_universityCodeController.text.isNotEmpty) {
      await prefs.setString('university_code', _universityCodeController.text.trim());
    }
    
    await prefs.setStringList('focus_areas', _selectedFocusAreas);
    
    // If we came from onboarding, clear the flag as we're done with the flow
    if (widget.fromOnboarding) {
      await prefs.remove('from_onboarding_flow');
    }
    
    // Save to user provider if logged in
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    if (authProvider.status == AuthStatus.authenticated) {
      try {
        await userProvider.updateUserProfile(
          fullName: _nameController.text.trim(),
          sport: _selectedSport,
          isIndividual: _isIndividual,
          university: !_isIndividual ? _selectedUniversity : null,
          universityCode: (!_isIndividual && _selectedUniversity != 'Other') 
              ? _universityCodeController.text.trim() 
              : null,
        );
      } catch (e) {
        print('Error updating user profile: $e');
        // Continue anyway since we saved to shared preferences
      }
    }
    
    setState(() {
      _isLoading = false;
    });
    
    if (!mounted) return;
    
    // Always navigate to main screen after profile setup is complete
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const MainNavigationScreen(),
      ),
    );
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
                    
                    // Name input field
                    const Text(
                      'Your Name',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nameController,
                      focusNode: _nameFocusNode,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Enter your name',
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
                        suffixIcon: _nameController.text.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  _nameController.clear();
                                  _validateInputs();
                                },
                                icon: const Icon(Icons.clear, color: Colors.white38),
                              )
                            : null,
                      ),
                      onChanged: (value) {
                        _validateInputs();
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Individual or team selection
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
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: _isIndividual
                                    ? themeProvider.accentColor
                                    : (isDark ? Colors.grey[800] : Colors.grey[200]),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.person,
                                    color: _isIndividual
                                        ? Colors.white
                                        : textColor.withOpacity(0.7),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Individual',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _isIndividual
                                          ? Colors.white
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
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: !_isIndividual
                                    ? themeProvider.accentColor
                                    : (isDark ? Colors.grey[800] : Colors.grey[200]),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.school,
                                    color: !_isIndividual
                                        ? Colors.white
                                        : textColor.withOpacity(0.7),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'University',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: !_isIndividual
                                          ? Colors.white
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
                    
                    // University selection (conditional)
                    if (!_isIndividual) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Select your university:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.3),
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedUniversity,
                            hint: Text(
                              'Select University',
                              style: TextStyle(
                                color: textColor.withOpacity(0.5),
                              ),
                            ),
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: textColor.withOpacity(0.7),
                            ),
                            style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                            ),
                            dropdownColor: Theme.of(context).colorScheme.surface,
                            items: _universities.map((String university) {
                              return DropdownMenuItem<String>(
                                value: university,
                                child: Text(university),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedUniversity = newValue;
                                
                                // Clear university code if changing universities
                                _universityCodeController.clear();
                              });
                            },
                          ),
                        ),
                      ),
                      
                      // University code field (if university is selected and not "Other")
                      if (_selectedUniversity != null && _selectedUniversity != 'Other') ...[
                        const SizedBox(height: 24),
                        Text(
                          'Enter your university code:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          controller: _universityCodeController,
                          hintText: 'University Code',
                          prefixIcon: Icons.vpn_key_outlined,
                          textCapitalization: TextCapitalization.characters,
                          helpText: _isLoadingCodes 
                              ? 'Loading university codes...' 
                              : 'Enter the code provided by your university',
                        ),
                      ],
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