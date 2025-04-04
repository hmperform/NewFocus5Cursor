import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

class WelcomeScreen extends StatelessWidget {
  final String userName;
  
  const WelcomeScreen({
    Key? key, 
    this.userName = 'Jen',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accentColor = themeProvider.accentColor;
    final textColor = Colors.white;
    
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
                            'Welcome aboard, $userName!',
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
                    const Text(
                      "Mental Training for Athletes",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Bottom button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFB4FF00),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFB4FF00).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextButton(
                  onPressed: () => _navigateToHome(context),
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: const Text(
                    'Let\'s go',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF121212),
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
      angle: angle * 3.14 / 180,
      child: Container(
        width: 4,
        height: length,
        decoration: BoxDecoration(
          color: const Color(0xFFB4FF00),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
  
  Widget _buildThoughtBubble(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5), width: 1.5),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }
  
  void _navigateToHome(BuildContext context) async {
    // Mark onboarding as completed
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_first_launch', false);
    
    Navigator.of(context).pushReplacementNamed('/home');
  }
} 