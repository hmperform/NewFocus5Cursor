import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../main_navigation_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChampionSetupScreen extends StatefulWidget {
  final String userName;
  final String universityCode;

  const ChampionSetupScreen({
    Key? key,
    required this.userName,
    required this.universityCode,
  }) : super(key: key);

  @override
  State<ChampionSetupScreen> createState() => _ChampionSetupScreenState();
}

class _ChampionSetupScreenState extends State<ChampionSetupScreen> {
  String? _universityName;
  String? _universityLogoUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUniversityData();
  }

  Future<void> _loadUniversityData() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('universities')
          .where('code', isEqualTo: widget.universityCode)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data();
        setState(() {
          _universityName = data['name'] as String?;
          _universityLogoUrl = data['logoUrl'] as String?;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading university data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _navigateToMain() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const MainNavigationScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accentColor = themeProvider.accentColor;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_universityLogoUrl != null)
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            _universityLogoUrl!,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    const SizedBox(height: 40),
                    Text(
                      'Welcome, Champion ${widget.userName}!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Thank you for being a Mental Performance Champion at ${_universityName ?? 'your university'}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 40),
                    const Text(
                      'As a Champion, you will:\n• Lead mental performance initiatives\n• Support athlete well-being\n• Foster a positive team culture',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        height: 1.8,
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _navigateToMain,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Get Started',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 