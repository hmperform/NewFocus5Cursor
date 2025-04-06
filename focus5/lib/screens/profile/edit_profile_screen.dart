import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _universityController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _universityFocusNode = FocusNode();
  bool _isNameValid = false;
  bool _isSaving = false;
  File? _imageFile;
  Uint8List? _webImageBytes;
  String? _currentImageUrl;
  bool _imageChanged = false;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
    _nameController.addListener(_validateInputs);
  }
  
  Future<void> _loadUserData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;
    
    if (user != null) {
      setState(() {
        _nameController.text = user.name ?? '';
        _universityController.text = user.university ?? '';
        _currentImageUrl = user.profileImageUrl;
      });
    }
    
    _validateInputs();
  }
  
  void _validateInputs() {
    setState(() {
      _isNameValid = _nameController.text.trim().length >= 2;
    });
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _universityController.dispose();
    _nameFocusNode.dispose();
    _universityFocusNode.dispose();
    super.dispose();
  }
  
  // Method to provide haptic feedback
  void _provideHapticFeedback() {
    HapticFeedback.mediumImpact();
  }
  
  Future<void> _pickImage() async {
    _provideHapticFeedback();
    
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    
    if (pickedFile != null) {
      setState(() {
        if (kIsWeb) {
          // For web, we need to use bytes
          pickedFile.readAsBytes().then((bytes) {
            setState(() {
              _webImageBytes = bytes;
              _imageChanged = true;
            });
          });
        } else {
          // For mobile, use File
          _imageFile = File(pickedFile.path);
          _imageChanged = true;
        }
      });
    }
  }
  
  Future<void> _saveProfile() async {
    if (!_isNameValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      // Update user profile with new values
      await userProvider.updateProfile(
        name: _nameController.text.trim(),
        university: _universityController.text.trim(),
        imageFile: !kIsWeb && _imageChanged ? _imageFile : null,
        imageBytes: kIsWeb && _imageChanged ? _webImageBytes : null,
      );
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
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
          'Edit Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
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
                    // Profile avatar
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
                            child: ClipOval(
                              child: _buildProfileImage(),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _pickImage,
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
                    
                    // University input field
                    const Text(
                      'University (Optional)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _universityController,
                      focusNode: _universityFocusNode,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Enter your university',
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
                        suffixIcon: _universityController.text.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  _universityController.clear();
                                },
                                icon: const Icon(Icons.clear, color: Colors.white38),
                              )
                            : null,
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // User Credentials (display only)
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        final user = authProvider.user;
                        return user != null
                            ? Container(
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
                                      'Account Info',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white38,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.email,
                                          color: Colors.white38,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            user.email ?? 'No email',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            // Save button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isNameValid && !_isSaving ? _saveProfile : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB4FF00),
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: Colors.grey.shade600,
                    disabledForegroundColor: Colors.grey.shade400,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 3,
                          ),
                        )
                      : const Text(
                          'SAVE CHANGES',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    if (kIsWeb && _webImageBytes != null) {
      return Image.memory(
        _webImageBytes!,
        width: 120,
        height: 120,
        fit: BoxFit.cover,
      );
    } else if (_imageFile != null) {
      return Image.file(
        _imageFile!,
        width: 120,
        height: 120,
        fit: BoxFit.cover,
      );
    } else if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) {
      return Image.network(
        _currentImageUrl!,
        width: 120,
        height: 120,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.person,
            size: 64,
            color: Colors.white70,
          );
        },
      );
    } else {
      return const Icon(
        Icons.person,
        size: 64,
        color: Colors.white70,
      );
    }
  }
} 