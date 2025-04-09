import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/coach_provider.dart';
import '../../models/coach_model.dart';
import 'coach_detail_screen.dart';

class CoachesListScreen extends StatefulWidget {
  const CoachesListScreen({Key? key}) : super(key: key);

  @override
  State<CoachesListScreen> createState() => _CoachesListScreenState();
}

class _CoachesListScreenState extends State<CoachesListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CoachProvider>().loadCoaches();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coaches'),
      ),
      body: Consumer<CoachProvider>(
        builder: (context, coachProvider, child) {
          if (coachProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (coachProvider.errorMessage != null) {
            return Center(
              child: Text(
                'Error: ${coachProvider.errorMessage}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final coaches = coachProvider.coaches;
          if (coaches.isEmpty) {
            return const Center(
              child: Text('No coaches available'),
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
                  title: Text(coach.name),
                  subtitle: Text(coach.title),
                  trailing: coach.rating > 0
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(coach.rating.toStringAsFixed(1)),
                            const Icon(Icons.star, color: Colors.amber),
                          ],
                        )
                      : null,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/coach',
                      arguments: coach.id,
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