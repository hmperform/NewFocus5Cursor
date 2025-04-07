import 'package:flutter/material.dart';
import 'package:focus5/models/coach_model.dart';
import 'package:focus5/providers/theme_provider.dart';
import 'package:provider/provider.dart';
// Import other necessary widgets/services, e.g., CustomButton, url_launcher
import 'package:url_launcher/url_launcher.dart'; 
import '../../widgets/custom_button.dart';

class CoachProfileScreen extends StatefulWidget {
  final CoachModel coach;
  const CoachProfileScreen({super.key, required this.coach});

  @override
  State<CoachProfileScreen> createState() => _CoachProfileScreenState();
}

class _CoachProfileScreenState extends State<CoachProfileScreen> {
  // ... (State variables if needed)

  @override
  Widget build(BuildContext context) {
    final CoachModel coach = widget.coach;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final textColor = themeProvider.textColor;
    final backgroundColor = themeProvider.backgroundColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    // Use imageUrl
                    image: coach.imageUrl.isNotEmpty
                        ? NetworkImage(coach.imageUrl)
                        : const AssetImage('assets/images/default_coach_header.png') as ImageProvider,
                  ),
                ),
                // Optional Gradient Overlay
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),
              ),
              title: Text(coach.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              centerTitle: true,
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      coach.title, 
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: textColor),
                    ),
                    const SizedBox(height: 16),
                    // --- Bio Section (Placeholder) ---
                    Text(
                      'Bio',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(color: textColor),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Coach bio details will appear here. Fetch from Firestore.', // Placeholder for bio
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: textColor),
                    ),
                    const SizedBox(height: 24),
                    // --- Specialties Section (Placeholder) ---
                    Text(
                      'Specialties',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(color: textColor),
                    ),
                     const SizedBox(height: 8),
                    Text(
                      'Coach specialties (e.g., Mental Toughness, Focus) will appear here. Fetch from Firestore.', // Placeholder
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: textColor),
                    ),
                    const SizedBox(height: 24),
                    // --- Credentials Section (Placeholder) ---
                     Text(
                      'Credentials',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(color: textColor),
                    ),
                     const SizedBox(height: 8),
                     Text(
                      'Coach credentials will appear here. Fetch from Firestore.', // Placeholder
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: textColor),
                    ),
                     const SizedBox(height: 24),
                    // --- Booking Button (Placeholder) ---
                    // TODO: Check if coach has bookingUrl and enable button
                    // CustomButton(text: 'Book Session', onPressed: () => _launchURL(coach.bookingUrl!)), 
                    // --- Social Links (Placeholder) ---
                    // TODO: Fetch social links and display icons conditionally
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  // Helper to launch URL (requires url_launcher package)
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('Could not launch $urlString')),
       );
    }
  }
} 