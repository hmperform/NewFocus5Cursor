import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/coach_model.dart';
import '../../providers/coach_provider.dart';

class CoachFormScreen extends StatefulWidget {
  final String? coachId;

  const CoachFormScreen({Key? key, this.coachId}) : super(key: key);

  @override
  State<CoachFormScreen> createState() => _CoachFormScreenState();
}

class _CoachFormScreenState extends State<CoachFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _titleController = TextEditingController();
  final _bioController = TextEditingController();
  final _bookingUrlController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _instagramController = TextEditingController();
  final _twitterController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _websiteController = TextEditingController();
  
  final List<String> _specialties = [];
  final List<String> _credentials = [];
  
  bool _isVerified = false;
  bool _isActive = true;
  bool _isLoading = false;
  bool _isInit = false;
  
  File? _profileImage;
  File? _headerImage;
  String? _existingProfileUrl;
  String? _existingHeaderUrl;
  
  final _specialtyController = TextEditingController();
  final _credentialController = TextEditingController();
  
  CoachModel? _existingCoach;

  @override
  void initState() {
    super.initState();
  }
  
  @override
  void didChangeDependencies() {
    if (!_isInit) {
      if (widget.coachId != null) {
        _loadCoachData();
      }
      _isInit = true;
    }
    super.didChangeDependencies();
  }
  
  Future<void> _loadCoachData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final coachProvider = Provider.of<CoachProvider>(context, listen: false);
      final coach = await coachProvider.getCoachById(widget.coachId!);
      
      if (coach != null) {
        _existingCoach = coach;
        _nameController.text = coach.name;
        _titleController.text = coach.title;
        _bioController.text = coach.bio;
        _bookingUrlController.text = coach.bookingUrl;
        _emailController.text = coach.email ?? '';
        _phoneController.text = coach.phoneNumber ?? '';
        _instagramController.text = coach.instagramUrl ?? '';
        _twitterController.text = coach.twitterUrl ?? '';
        _linkedinController.text = coach.linkedinUrl ?? '';
        _websiteController.text = coach.websiteUrl ?? '';
        
        setState(() {
          _specialties.addAll(coach.specialties);
          _credentials.addAll(coach.credentials);
          _isVerified = coach.isVerified;
          _isActive = coach.isActive;
          _existingProfileUrl = coach.profileImageUrl;
          _existingHeaderUrl = coach.headerImageUrl;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading coach data: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _pickImage(bool isProfile) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: isProfile ? 500 : 1000,
        maxHeight: isProfile ? 500 : 500,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          if (isProfile) {
            _profileImage = File(pickedFile.path);
          } else {
            _headerImage = File(pickedFile.path);
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }
  
  void _addSpecialty() {
    final specialty = _specialtyController.text.trim();
    if (specialty.isNotEmpty && !_specialties.contains(specialty)) {
      setState(() {
        _specialties.add(specialty);
        _specialtyController.clear();
      });
    }
  }
  
  void _removeSpecialty(String specialty) {
    setState(() {
      _specialties.remove(specialty);
    });
  }
  
  void _addCredential() {
    final credential = _credentialController.text.trim();
    if (credential.isNotEmpty && !_credentials.contains(credential)) {
      setState(() {
        _credentials.add(credential);
        _credentialController.clear();
      });
    }
  }
  
  void _removeCredential(String credential) {
    setState(() {
      _credentials.remove(credential);
    });
  }
  
  Future<void> _saveCoach() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please correct the errors in the form')),
      );
      return;
    }
    
    if (_specialties.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one specialty')),
      );
      return;
    }
    
    if (_credentials.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one credential')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final coachProvider = Provider.of<CoachProvider>(context, listen: false);
      final coachId = await coachProvider.createOrUpdateCoach(
        id: widget.coachId,
        name: _nameController.text.trim(),
        title: _titleController.text.trim(),
        bio: _bioController.text.trim(),
        profileImage: _profileImage,
        headerImage: _headerImage,
        existingProfileUrl: _existingProfileUrl,
        existingHeaderUrl: _existingHeaderUrl,
        bookingUrl: _bookingUrlController.text.trim(),
        email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
        phoneNumber: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        instagramUrl: _instagramController.text.trim().isNotEmpty ? _instagramController.text.trim() : null,
        twitterUrl: _twitterController.text.trim().isNotEmpty ? _twitterController.text.trim() : null,
        linkedinUrl: _linkedinController.text.trim().isNotEmpty ? _linkedinController.text.trim() : null,
        websiteUrl: _websiteController.text.trim().isNotEmpty ? _websiteController.text.trim() : null,
        specialties: _specialties,
        credentials: _credentials,
        isVerified: _isVerified,
        isActive: _isActive,
      );
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.coachId == null
                ? 'Coach created successfully'
                : 'Coach updated successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving coach: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _bioController.dispose();
    _bookingUrlController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _instagramController.dispose();
    _twitterController.dispose();
    _linkedinController.dispose();
    _websiteController.dispose();
    _specialtyController.dispose();
    _credentialController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.coachId == null ? 'Add Coach' : 'Edit Coach',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : _saveCoach,
            icon: const Icon(Icons.save),
            label: const Text('SAVE'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFB4FF00),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFB4FF00),
              ),
            )
          : GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Images section
                      _buildImageSection(),
                      const SizedBox(height: 24),
                      
                      // Basic Info
                      const Text(
                        'Basic Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Name
                      TextFormField(
                        controller: _nameController,
                        decoration: _buildInputDecoration('Name'),
                        style: const TextStyle(color: Colors.white),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter coach name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Title
                      TextFormField(
                        controller: _titleController,
                        decoration: _buildInputDecoration('Title (e.g. Mental Performance Coach)'),
                        style: const TextStyle(color: Colors.white),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter coach title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Bio
                      TextFormField(
                        controller: _bioController,
                        decoration: _buildInputDecoration('Bio'),
                        style: const TextStyle(color: Colors.white),
                        maxLines: 5,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter coach bio';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      
                      // Booking URL
                      TextFormField(
                        controller: _bookingUrlController,
                        decoration: _buildInputDecoration('Booking URL'),
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.url,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter booking URL';
                          }
                          if (!Uri.parse(value).isAbsolute) {
                            return 'Please enter a valid URL';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      
                      // Specialties
                      _buildSpecialtiesSection(),
                      const SizedBox(height: 24),
                      
                      // Credentials
                      _buildCredentialsSection(),
                      const SizedBox(height: 24),
                      
                      // Contact Info
                      const Text(
                        'Contact Information (Optional)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Email
                      TextFormField(
                        controller: _emailController,
                        decoration: _buildInputDecoration('Email'),
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty) {
                            final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                            if (!emailRegex.hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Phone
                      TextFormField(
                        controller: _phoneController,
                        decoration: _buildInputDecoration('Phone Number'),
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 24),
                      
                      // Social Media
                      const Text(
                        'Social Media (Optional)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Instagram
                      TextFormField(
                        controller: _instagramController,
                        decoration: _buildInputDecoration('Instagram URL'),
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.url,
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty) {
                            if (!Uri.parse(value).isAbsolute) {
                              return 'Please enter a valid URL';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Twitter
                      TextFormField(
                        controller: _twitterController,
                        decoration: _buildInputDecoration('Twitter URL'),
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.url,
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty) {
                            if (!Uri.parse(value).isAbsolute) {
                              return 'Please enter a valid URL';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // LinkedIn
                      TextFormField(
                        controller: _linkedinController,
                        decoration: _buildInputDecoration('LinkedIn URL'),
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.url,
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty) {
                            if (!Uri.parse(value).isAbsolute) {
                              return 'Please enter a valid URL';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Website
                      TextFormField(
                        controller: _websiteController,
                        decoration: _buildInputDecoration('Website URL'),
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.url,
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty) {
                            if (!Uri.parse(value).isAbsolute) {
                              return 'Please enter a valid URL';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      
                      // Status
                      _buildStatusSection(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
  
  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Profile Images',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            // Profile Image
            Expanded(
              child: Column(
                children: [
                  const Text(
                    'Profile Image',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _pickImage(true),
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        shape: BoxShape.circle,
                        image: _profileImage != null
                            ? DecorationImage(
                                image: FileImage(_profileImage!),
                                fit: BoxFit.cover,
                              )
                            : _existingProfileUrl != null && _existingProfileUrl!.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(_existingProfileUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                      ),
                      child: _profileImage == null && (_existingProfileUrl == null || _existingProfileUrl!.isEmpty)
                          ? const Icon(
                              Icons.add_a_photo,
                              color: Colors.white70,
                              size: 32,
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            
            // Header Image
            Expanded(
              child: Column(
                children: [
                  const Text(
                    'Header Image',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _pickImage(false),
                    child: Container(
                      width: 160,
                      height: 90,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(12),
                        image: _headerImage != null
                            ? DecorationImage(
                                image: FileImage(_headerImage!),
                                fit: BoxFit.cover,
                              )
                            : _existingHeaderUrl != null && _existingHeaderUrl!.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(_existingHeaderUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                      ),
                      child: _headerImage == null && (_existingHeaderUrl == null || _existingHeaderUrl!.isEmpty)
                          ? const Icon(
                              Icons.add_a_photo,
                              color: Colors.white70,
                              size: 32,
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildSpecialtiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Specialties',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Add areas of expertise (e.g. Performance Anxiety, Focus, etc.)',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _specialtyController,
                decoration: _buildInputDecoration('Add specialty'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: _addSpecialty,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB4FF00),
                foregroundColor: Colors.black,
              ),
              child: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _specialties.map((specialty) {
            return Chip(
              label: Text(specialty),
              backgroundColor: const Color(0xFF2A2A2A),
              labelStyle: const TextStyle(color: Colors.white),
              deleteIconColor: Colors.white70,
              onDeleted: () => _removeSpecialty(specialty),
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildCredentialsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Credentials',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Add professional credentials (e.g. MBA, Ph.D., Former Athlete)',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _credentialController,
                decoration: _buildInputDecoration('Add credential'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: _addCredential,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB4FF00),
                foregroundColor: Colors.black,
              ),
              child: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _credentials.map((credential) {
            return Chip(
              label: Text(credential),
              backgroundColor: const Color(0xFF2A2A2A),
              labelStyle: const TextStyle(color: Colors.white),
              deleteIconColor: Colors.white70,
              onDeleted: () => _removeCredential(credential),
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Status',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        
        // Active Switch
        SwitchListTile(
          title: const Text(
            'Active',
            style: TextStyle(color: Colors.white),
          ),
          subtitle: const Text(
            'Inactive coaches will not be shown to users',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          value: _isActive,
          onChanged: (value) {
            setState(() {
              _isActive = value;
            });
          },
          activeColor: const Color(0xFFB4FF00),
          activeTrackColor: const Color(0xFF8BC34A).withOpacity(0.5),
          inactiveThumbColor: Colors.grey,
          inactiveTrackColor: Colors.grey.withOpacity(0.5),
        ),
        
        // Verified Switch
        SwitchListTile(
          title: const Text(
            'Verified',
            style: TextStyle(color: Colors.white),
          ),
          subtitle: const Text(
            'Verified coaches will display a verification badge',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          value: _isVerified,
          onChanged: (value) {
            setState(() {
              _isVerified = value;
            });
          },
          activeColor: const Color(0xFFB4FF00),
          activeTrackColor: const Color(0xFF8BC34A).withOpacity(0.5),
          inactiveThumbColor: Colors.grey,
          inactiveTrackColor: Colors.grey.withOpacity(0.5),
        ),
      ],
    );
  }
  
  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white60),
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      errorStyle: const TextStyle(color: Colors.red),
    );
  }
} 