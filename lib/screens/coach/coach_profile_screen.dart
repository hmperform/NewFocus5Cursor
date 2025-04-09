import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; 
import 'package:focus5/providers/theme_provider.dart';
import 'package:provider/provider.dart';
// Import other necessary widgets/services, e.g., CustomButton, url_launcher
import '../../widgets/custom_button.dart';

class CoachProfileScreen extends StatefulWidget {
  final Map<String, dynamic> coach;

  const CoachProfileScreen({
    Key? key,
    required this.coach,
  }) : super(key: key);

  @override
  _CoachProfileScreenState createState() => _CoachProfileScreenState();
}

class _CoachProfileScreenState extends State<CoachProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final coach = widget.coach;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(coach['name'] ?? 'Coach Profile'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Coach header with Hero animation
            Hero(
              tag: coach['id'] ?? coach['name'],
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(coach['imageUrl'] ?? ''),
                    fit: BoxFit.cover,
                    onError: (exception, stackTrace) {
                      print('Error loading coach image: $exception');
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coach['name'] ?? 'Unknown Coach',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  if (coach['bio'] != null && coach['bio'].isNotEmpty)
                    Text(
                      coach['bio'],
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  const SizedBox(height: 16),
                  if (coach['website'] != null && coach['website'].isNotEmpty)
                    TextButton(
                      onPressed: () async {
                        final url = Uri.parse(coach['website']);
                        try {
                          if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                            print('Could not launch ${coach['website']}');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Could not launch ${coach['website']}')),
                            );
                          }
                        } catch (e) {
                          print('Error launching URL: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error launching URL: $e')),
                          );
                        }
                      },
                      child: const Text('Visit Website'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 