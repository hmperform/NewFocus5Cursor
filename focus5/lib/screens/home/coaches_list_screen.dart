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

          if (coachProvider.error != null) {
            return Center(
              child: Text(
                'Error: ${coachProvider.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final List<Coach> coaches = coachProvider.coaches;
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
                    radius: 30,
                    backgroundImage: NetworkImage(coach.profileImageUrl),
                    backgroundColor: Colors.grey[800],
                    onBackgroundImageError: (e, s) => const Icon(Icons.person),
                  ),
                  title: Text(coach.name),
                  subtitle: Text(coach.title),
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