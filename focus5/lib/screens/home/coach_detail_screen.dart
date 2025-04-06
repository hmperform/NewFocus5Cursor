import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/coach_model.dart';

class CoachDetailScreen extends StatelessWidget {
  final CoachModel coach;
  
  const CoachDetailScreen({
    Key? key,
    required this.coach,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final backgroundColor = themeProvider.backgroundColor;
    final textColor = themeProvider.textColor;
    final accentColor = themeProvider.accentColor;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: Text(
          'About ${coach.name}',
          style: TextStyle(color: textColor),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Coach details
            Text(
              'Background',
              style: TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              coach.bio,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            
            // Coach credentials
            Text(
              'Credentials',
              style: TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildCredential(
              icon: Icons.school,
              title: 'Education',
              description: coach.education ?? 'Ph.D. in Sports Psychology',
              textColor: textColor,
            ),
            _buildCredential(
              icon: Icons.workspace_premium,
              title: 'Certifications',
              description: coach.certifications ?? 'Certified Mental Performance Consultant',
              textColor: textColor,
            ),
            _buildCredential(
              icon: Icons.history_edu,
              title: 'Experience',
              description: coach.experience ?? '15+ years of experience',
              textColor: textColor,
            ),
            
            const SizedBox(height: 24),
            
            // Coaching approach
            Text(
              'Coaching Approach',
              style: TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              coach.approach ?? 'My coaching approach focuses on building mental resilience, improving focus, and developing strategies to perform under pressure. I combine evidence-based techniques with practical exercises tailored to your specific needs and goals.',
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCredential({
    required IconData icon,
    required String title,
    required String description,
    required Color textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: textColor, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 