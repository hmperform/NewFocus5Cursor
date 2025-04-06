import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/user_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/user_model.dart';
import '../../constants/theme.dart';
import '../../utils/image_utils.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _availableFocusAreas = [
    'Confidence',
    'Pressure Situations',
    'Game Day Preparation',
    'Mental Toughness',
    'Performance Anxiety',
    'Focus & Concentration',
    'Visualization',
    'Goal Setting',
    'Team Dynamics',
    'Leadership',
    'Recovery',
  ];

  List<String> _selectedFocusAreas = [];
  File? _profileImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initUserData();
  }

  void _initUserData() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;
    if (user != null) {
      _fullNameController.text = user.fullName;
      _selectedFocusAreas = List<String>.from(user.focusAreas);
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
      );

      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.user == null) {
        throw Exception('User not logged in');
      }

      final success = await userProvider.updateUserProfile(
        fullName: _fullNameController.text.trim(),
        profileImageUrl: _profileImage != null ? _profileImage!.path : null,
        focusAreas: _selectedFocusAreas,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userProvider.errorMessage ?? 'Failed to update profile')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _toggleFocusArea(String area) {
    setState(() {
      if (_selectedFocusAreas.contains(area)) {
        _selectedFocusAreas.remove(area);
      } else {
        _selectedFocusAreas.add(area);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = userProvider.user;
    
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    // Use theme-aware colors
    final accentColor = themeProvider.isDarkMode 
        ? AppColors.accentDark 
        : AppColors.accentLight;
    final textColor = Theme.of(context).colorScheme.onBackground;
    final secondaryTextColor = themeProvider.isDarkMode 
        ? Colors.grey[400] 
        : Colors.grey[700];
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: textColor,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: accentColor,
                    ),
                  )
                : Text(
                    'Save',
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Profile Image
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: themeProvider.isDarkMode 
                              ? Colors.white30
                              : Colors.black26,
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: _profileImage != null
                            ? Image.file(
                                _profileImage!,
                                fit: BoxFit.cover,
                              )
                            : ImageUtils.avatarWithFallback(
                                imageUrl: user.profileImageUrl,
                                radius: 60,
                                name: user.fullName,
                                backgroundColor: themeProvider.isDarkMode 
                                    ? Colors.grey[800]!
                                    : Colors.grey[300]!,
                                textColor: themeProvider.isDarkMode 
                                    ? Colors.white54
                                    : Colors.black38,
                              ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: accentColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            color: themeProvider.isDarkMode ? Colors.black : Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Full Name
              TextFormField(
                controller: _fullNameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  labelStyle: TextStyle(color: secondaryTextColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: themeProvider.isDarkMode
                          ? Colors.white30
                          : Colors.black26,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: accentColor),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 32),
              
              // Focus Areas
              Text(
                'Focus Areas (select up to 5)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 16),
              
              Wrap(
                spacing: 8,
                runSpacing: 12,
                children: _availableFocusAreas.map((area) {
                  final isSelected = _selectedFocusAreas.contains(area);
                  return FilterChip(
                    label: Text(area),
                    selected: isSelected,
                    onSelected: (_) {
                      if (!isSelected && _selectedFocusAreas.length >= 5) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('You can select up to 5 focus areas')),
                        );
                        return;
                      }
                      _toggleFocusArea(area);
                    },
                    backgroundColor: themeProvider.isDarkMode
                        ? Colors.grey[800]
                        : Colors.grey[200],
                    selectedColor: accentColor.withOpacity(0.3),
                    checkmarkColor: accentColor,
                    showCheckmark: true,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    labelStyle: TextStyle(
                      color: isSelected ? accentColor : textColor,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
} 