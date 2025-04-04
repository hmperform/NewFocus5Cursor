import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

class WelcomeScreen extends StatefulWidget {
  final String userName;
  
  const WelcomeScreen({
    Key? key, 
    this.userName = 'Athlete',
  }) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  String? _selectedSport;
  
  @override
  void initState() {
    super.initState();
    _loadUserSelections();
  }
  
  Future<void> _loadUserSelections() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedSport = prefs.getString('selected_sport');
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accentColor = themeProvider.accentColor;
    final textColor = Colors.white;
    
    // Simplified welcome text
    String welcomeText = 'Welcome aboard, ${widget.userName}!';
    
    // Optional sport-specific tagline
    String tagline = _selectedSport != null && _selectedSport != 'Other'
        ? "Mental Training for $_selectedSport Athletes"
        : "Mental Training for Athletes";
    
    return Scaffold(
      backgroundColor: const Color(0xFF4527A0), // Deep purple background
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Welcome text
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        children: [
                          Text(
                            welcomeText,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'You are in the right place. Let\'s get started on your mental training journey!',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white70,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 60),
                    
                    // Lightbulb illustration
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Glow effect behind lightbulb
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: const Color(0xFFB4FF00).withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                        ),
                        
                        // Secondary glow
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            color: const Color(0xFFB4FF00).withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                        ),
                        
                        // Lightbulb base
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Lightbulb top (bulb part)
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: const Color(0xFFB4FF00),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFB4FF00).withOpacity(0.5),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.lightbulb,
                                  color: Colors.white.withOpacity(0.9),
                                  size: 50,
                                ),
                              ),
                            ),
                            
                            // Lightbulb bottom (screw part)
                            Container(
                              width: 25,
                              height: 20,
                              decoration: const BoxDecoration(
                                color: Color(0xFFD0D0D0),
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(5),
                                  bottomRight: Radius.circular(5),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        // Radiating light rays
                        Positioned(
                          left: 40,
                          top: 60,
                          child: _buildLightRay(40, -45),
                        ),
                        Positioned(
                          right: 40,
                          top: 60,
                          child: _buildLightRay(40, 45),
                        ),
                        Positioned(
                          top: 30,
                          child: _buildLightRay(40, 0),
                        ),
                        
                        // Ideas/thoughts around the lightbulb
                        Positioned(
                          right: 50,
                          top: 110,
                          child: _buildThoughtBubble("Focus", const Color(0xFFB4FF00)),
                        ),
                        Positioned(
                          left: 30,
                          bottom: 30,
                          child: _buildThoughtBubble("Growth", Colors.amber),
                        ),
                        Positioned(
                          right: 40,
                          bottom: 20,
                          child: _buildThoughtBubble("Resilience", Colors.deepPurpleAccent),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 60),
                    
                    // Tagline
                    Text(
                      tagline,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            
            // Get started button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed('/home');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB4FF00),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: const Text(
                    'LET\'S GO',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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
  
  Widget _buildLightRay(double length, double angle) {
    return Transform.rotate(
      angle: angle * 3.14159 / 180,
      child: Container(
        width: 4,
        height: length,
        decoration: BoxDecoration(
          color: const Color(0xFFB4FF00).withOpacity(0.7),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
  
  Widget _buildThoughtBubble(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
} 