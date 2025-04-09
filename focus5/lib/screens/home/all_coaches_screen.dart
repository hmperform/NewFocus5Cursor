import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/coach_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/coach_model.dart';
import 'coach_profile_screen.dart';

class AllCoachesScreen extends StatefulWidget {
  const AllCoachesScreen({Key? key}) : super(key: key);

  @override
  State<AllCoachesScreen> createState() => _AllCoachesScreenState();
}

class _AllCoachesScreenState extends State<AllCoachesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CoachProvider>().loadCoaches();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final textColor = Theme.of(context).colorScheme.onBackground;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'All Coaches',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<CoachProvider>(
        builder: (context, coachProvider, child) {
          if (coachProvider.isLoading) {
            return Center(
              child: CircularProgressIndicator(
                color: themeProvider.accentColor,
              ),
            );
          }

          if (coachProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading coaches',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    coachProvider.error!,
                    style: TextStyle(color: textColor.withOpacity(0.7)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final coaches = coachProvider.coaches;
          if (coaches.isEmpty) {
            return Center(
              child: Text(
                'No coaches available',
                style: TextStyle(color: textColor),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: coaches.length,
            itemBuilder: (context, index) {
              final coach = coaches[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(coach.profileImageUrl),
                    onBackgroundImageError: (e, s) => const Icon(Icons.person),
                  ),
                  title: Text(
                    coach.name,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    coach.title,
                    style: TextStyle(
                      color: textColor.withOpacity(0.7),
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    color: textColor.withOpacity(0.5),
                    size: 16,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CoachProfileScreen(
                          coachId: coach.id,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
} 