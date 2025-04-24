import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Added for logo

import '../../widgets/custom_text_field.dart';
import '../../widgets/focus_button.dart';
import '../../providers/theme_provider.dart';
import '../../constants/sports.dart'; // Keep for sport selection dialog
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../screens/main_navigation_screen.dart';
import '../../models/university_model.dart'; // Keep for University model

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
  final TextEditingController _organizationCodeController = TextEditingController();
  final FocusNode _organizationCodeFocusNode = FocusNode();
  String? _selectedSport;
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

  // University/Organization Validation State
  University? _verifiedUniversity; // Store verified university details
  String? _validatedCodeType; // 'regular', 'coach', 'champion'
  bool _isValidatingCode = false;

  @override
  void initState() {
    super.initState();
    // Initialize the animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _organizationCodeController.dispose();
    _organizationCodeFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

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

  Future<void> _validateOrganizationCode() async {
    final code = _organizationCodeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Please enter a code';
        _verifiedUniversity = null;
        _validatedCodeType = null;
      });
      return;
    }

    setState(() {
      _isValidatingCode = true;
      _isLoading = true; // Show general loading indicator as well
      _hasError = false;
      _errorMessage = '';
      _verifiedUniversity = null;
      _validatedCodeType = null;
    });

    try {
      // Check against regular code, champion code, and coach code
      final universitiesRef = FirebaseFirestore.instance.collection('universities');
      
      // Check regular code
      QuerySnapshot querySnapshot = await universitiesRef.where('code', isEqualTo: code).limit(1).get();
      
      if (querySnapshot.docs.isNotEmpty) {
        final universityDoc = querySnapshot.docs.first;
        setState(() {
          _verifiedUniversity = University.fromFirestore(universityDoc);
          _validatedCodeType = 'regular';
        });
      } else {
        // Check champion code
        querySnapshot = await universitiesRef.where('championCode', isEqualTo: code).limit(1).get();
        if (querySnapshot.docs.isNotEmpty) {
          final universityDoc = querySnapshot.docs.first;
          setState(() {
            _verifiedUniversity = University.fromFirestore(universityDoc);
            _validatedCodeType = 'champion';
          });
        } else {
          // Check coach code
          querySnapshot = await universitiesRef.where('codeToJoinAsCoach', isEqualTo: code).limit(1).get();
          if (querySnapshot.docs.isNotEmpty) {
             final universityDoc = querySnapshot.docs.first;
             setState(() {
               _verifiedUniversity = University.fromFirestore(universityDoc);
               _validatedCodeType = 'coach';
             });
          } else {
             // Code not found
            setState(() {
              _hasError = true;
              _errorMessage = 'Invalid organization code';
              _verifiedUniversity = null;
              _validatedCodeType = null;
            });
          }
        }
      }
      
    } catch (e) {
      print('Error validating organization code: $e');
      setState(() {
        _hasError = true;
        _errorMessage = 'Error validating code. Please try again.';
        _verifiedUniversity = null;
        _validatedCodeType = null;
      });
    } finally {
      setState(() {
        _isValidatingCode = false;
        _isLoading = false;
      });
      if (_verifiedUniversity != null) {
         HapticFeedback.mediumImpact(); // Success feedback
         // Clear the code input field after successful validation
         _organizationCodeController.clear();
         FocusScope.of(context).unfocus(); // Hide keyboard
      }
    }
  }


  void _handleContinue() async {
    _provideHapticFeedback();

    if (_selectedFocusAreas.isEmpty) {
      _showError('Please select at least one focus area');
      return;
    }
    
    if (!_isIndividual && _verifiedUniversity == null) {
       _showError('Please enter and validate your organization code');
       return;
    }

    if (_selectedSport == null) {
        _showSportSelectionDialog();
        return; 
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('focus_areas', _selectedFocusAreas);
    await prefs.setString('selected_sport', _selectedSport!);
    await prefs.setBool('is_individual', _isIndividual);
    if (!_isIndividual && _verifiedUniversity != null) {
        await prefs.setString('university_code', _verifiedUniversity!.code);
        await prefs.setString('validated_code_type', _validatedCodeType!);
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (authProvider.status == AuthStatus.authenticated) {
      try {
        final currentFullName = userProvider.user?.fullName ?? ''; 
        if (currentFullName.isEmpty) {
           _showError('Could not retrieve user name. Please try again.');
           setState(() => _isLoading = false);
           return;
        }
        
        await userProvider.updateUserProfile(
          fullName: currentFullName,
          focusAreas: _selectedFocusAreas,
          sport: _selectedSport,
          isIndividual: _isIndividual,
          university: _verifiedUniversity?.name,
          universityCode: _verifiedUniversity?.code,
          isPartnerCoach: _validatedCodeType == 'coach',
          isPartnerChampion: _validatedCodeType == 'champion',
        );
        
        if (!_isIndividual && _verifiedUniversity != null) {
            await FirebaseFirestore.instance
                .collection('universities')
                .doc(_verifiedUniversity!.code)
                .update({'currentUserCount': FieldValue.increment(1)});
        }

      } catch (e) {
        print('Error updating user profile: $e');
        _showError('Failed to save profile. Please try again.');
        setState(() => _isLoading = false);
        return;
      }
    } else {
       _showError('Authentication error. Please log in again.');
       setState(() => _isLoading = false);
       return;
    }

    if (widget.fromOnboarding) {
      await prefs.setBool('onboarding_complete', true);
    }

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const MainNavigationScreen(),
      ),
    );
  }
  
  void _showError(String message) {
     if (!mounted) return;
     ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
     );
  }
  
   // Dialog to select sport
  Future<void> _showSportSelectionDialog() async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final textColor = Theme.of(context).colorScheme.onBackground;
    
    final selected = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        String? tempSelectedSport = _selectedSport; // Use temporary state for the dialog
        return StatefulBuilder( // Use StatefulBuilder to update dialog state
          builder: (context, setDialogState) {
            return AlertDialog(
               backgroundColor: Theme.of(context).colorScheme.surface,
               title: Text('Select Your Sport', style: TextStyle(color: textColor)),
               content: SizedBox(
                 width: double.maxFinite,
                 child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: sportsList.length,
                    itemBuilder: (context, index) {
                      final sport = sportsList[index];
                      return RadioListTile<String>(
                        title: Text(sport, style: TextStyle(color: textColor)),
                        value: sport,
                        groupValue: tempSelectedSport,
                        activeColor: themeProvider.accentColor,
                        onChanged: (String? value) {
                          setDialogState(() { // Update dialog state
                            tempSelectedSport = value;
                          });
                        },
                      );
                    },
                 ),
               ),
               actions: <Widget>[
                 TextButton(
                    child: const Text('Cancel'),
                    onPressed: () {
                      Navigator.of(context).pop(); // Return null
                    },
                 ),
                 TextButton(
                    child: const Text('Confirm'),
                    onPressed: () {
                      if (tempSelectedSport != null) {
                         Navigator.of(context).pop(tempSelectedSport); // Return selected sport
                      } else {
                          _showError('Please select a sport');
                      }
                    },
                 ),
               ],
            );
          }
        );
      },
    );

    if (selected != null) {
      setState(() {
        _selectedSport = selected;
      });
      // After sport is selected, try to continue again
      _handleContinue();
    }
  }


  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final textColor = Theme.of(context).colorScheme.onBackground;
    final isDark = themeProvider.isDarkMode;
    final accentColor = themeProvider.accentColor;

    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Consider using theme background
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
        leading: widget.fromOnboarding ? null : IconButton( // Only show back button if not from onboarding
           icon: Icon(Icons.arrow_back, color: Colors.white),
           onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            // Loading Indicator Overlay
            if (_isLoading)
              const LinearProgressIndicator(),

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
                      'Complete your profile to personalize your mental training journey.',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Focus Area Selection
                    Text(
                      'Select your top 3 focus areas:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12.0,
                      runSpacing: 12.0,
                      children: _focusAreas.map((area) {
                        final isSelected = _selectedFocusAreas.contains(area);
                        return ChoiceChip(
                          label: Text(area),
                          selected: isSelected,
                          onSelected: (_) => _toggleFocusArea(area),
                          selectedColor: accentColor,
                          backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : textColor,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                               color: isSelected ? accentColor : Colors.transparent,
                               width: 1),
                          ),
                          showCheckmark: false,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),

                    // Individual or Organization Selection
                    Text(
                      'Are you joining as an individual or with a partner organization/university?',
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
                                _verifiedUniversity = null; // Reset validation if switching
                                _validatedCodeType = null;
                                _organizationCodeController.clear();
                                _hasError = false;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: _isIndividual
                                    ? accentColor
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
                                    ? accentColor
                                    : (isDark ? Colors.grey[800] : Colors.grey[200]),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.group, // Changed icon
                                    color: !_isIndividual
                                        ? Colors.white
                                        : textColor.withOpacity(0.7),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Organization', // Changed text
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

                   // Organization Code Input (Conditional)
                    if (!_isIndividual)
                      Padding(
                        padding: const EdgeInsets.only(top: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             // Show Welcome message if code validated
                             if (_verifiedUniversity != null)
                               Container(
                                 padding: const EdgeInsets.all(16),
                                 margin: const EdgeInsets.only(bottom: 16),
                                 decoration: BoxDecoration(
                                    color: accentColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: accentColor),
                                 ),
                                 child: Row(
                                    children: [
                                      if (_verifiedUniversity!.logoUrl != null && _verifiedUniversity!.logoUrl!.isNotEmpty) // Check if logo URL is not null or empty
                                         Padding(
                                           padding: const EdgeInsets.only(right: 12.0),
                                           child: ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: CachedNetworkImage(
                                                imageUrl: _verifiedUniversity!.logoUrl!,
                                                width: 40,
                                                height: 40,
                                                fit: BoxFit.contain,
                                                placeholder: (context, url) => const SizedBox(width: 40, height: 40, child: CircularProgressIndicator(strokeWidth: 2)),
                                                errorWidget: (context, url, error) => const Icon(Icons.business, size: 40),
                                              ),
                                           ),
                                         )
                                      else // Show placeholder if logoUrl is null or empty
                                         Padding(
                                           padding: const EdgeInsets.only(right: 12.0),
                                           child: const Icon(Icons.business, size: 40),
                                         ),
                                       Expanded(
                                         child: Column(
                                           crossAxisAlignment: CrossAxisAlignment.start,
                                           children: [
                                              Text(
                                                'Welcome to ${_verifiedUniversity!.name}!',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: textColor,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              if (_validatedCodeType != null)
                                                Text(
                                                  'Joining as: ${_validatedCodeType![0].toUpperCase()}${_validatedCodeType!.substring(1)}', // Capitalize first letter
                                                  style: TextStyle(color: textColor.withOpacity(0.8)),
                                                ),
                                           ],
                                         ),
                                       ),
                                       // Option to change code
                                       IconButton(
                                          icon: Icon(Icons.close, color: textColor.withOpacity(0.7)),
                                          tooltip: 'Change Code',
                                          onPressed: () {
                                            setState(() {
                                              _verifiedUniversity = null;
                                              _validatedCodeType = null;
                                              _organizationCodeController.clear();
                                            });
                                          },
                                       )
                                    ],
                                 ),
                               ),
                            
                            // Show code input only if not yet validated
                            if (_verifiedUniversity == null) ...[
                                Text(
                                  'Enter your organization code:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: CustomTextField(
                                        controller: _organizationCodeController,
                                        focusNode: _organizationCodeFocusNode,
                                        hintText: 'Organization Code',
                                        prefixIcon: Icons.vpn_key_outlined,
                                        textCapitalization: TextCapitalization.characters,
                                        helpText: 'Enter the code provided by your organization',
                                        onSubmitted: (_) => _validateOrganizationCode(), // Validate on submit
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      height: 58, // Match text field height approx
                                      child: ElevatedButton(
                                        onPressed: _isValidatingCode ? null : _validateOrganizationCode,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: accentColor,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                        ),
                                        child: _isValidatingCode
                                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                            : const Text('Validate'),
                                      ),
                                    ),
                                  ],
                                ),
                            ],

                            // Show error message if validation fails
                            if (_hasError && _errorMessage.isNotEmpty && _verifiedUniversity == null)
                               Padding(
                                 padding: const EdgeInsets.only(top: 8.0),
                                 child: Text(
                                   _errorMessage,
                                   style: const TextStyle(color: Colors.red, fontSize: 12),
                                 ),
                               ),
                          ],
                        ),
                     ),
                    const SizedBox(height: 40), // Spacing before button
                  ],
                ),
              ),
            ),

            // Continue Button Area
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: FocusButton(
                text: 'Complete Profile',
                onPressed: _isLoading ? null : _handleContinue,
                isLoading: _isLoading,
                isEnabled: _selectedFocusAreas.isNotEmpty && (_isIndividual || _verifiedUniversity != null),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper model for University data (can be moved to models folder)
class University {
  final String id;
  final String name;
  final String code;
  final String? logoUrl;
  final String? championCode;
  final String? codeToJoinAsCoach;

  University({
    required this.id,
    required this.name,
    required this.code,
    this.logoUrl,
    this.championCode,
    this.codeToJoinAsCoach,
  });

  factory University.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return University(
      id: doc.id,
      name: data['name'] ?? '',
      code: data['code'] ?? '',
      logoUrl: data['UniversityLogo'], // Corrected field name
      championCode: data['championCode'],
      codeToJoinAsCoach: data['codeToJoinAsCoach'],
    );
  }
} 