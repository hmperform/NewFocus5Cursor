import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/coach_model.dart';
import '../../providers/coach_provider.dart';
import 'coach_form_screen.dart';

class CoachAdminScreen extends StatefulWidget {
  const CoachAdminScreen({Key? key}) : super(key: key);

  @override
  State<CoachAdminScreen> createState() => _CoachAdminScreenState();
}

class _CoachAdminScreenState extends State<CoachAdminScreen> {
  bool _isInit = false;
  bool _showInactiveCoaches = false;

  @override
  void didChangeDependencies() {
    if (!_isInit) {
      _loadCoaches();
      _isInit = true;
    }
    super.didChangeDependencies();
  }

  Future<void> _loadCoaches() async {
    await Provider.of<CoachProvider>(context, listen: false)
        .loadCoaches(activeOnly: !_showInactiveCoaches);
  }

  void _toggleShowInactive() {
    setState(() {
      _showInactiveCoaches = !_showInactiveCoaches;
    });
    _loadCoaches();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Coach Management',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Toggle to show inactive coaches
          IconButton(
            icon: Icon(
              _showInactiveCoaches ? Icons.visibility : Icons.visibility_off,
              color: Colors.white,
            ),
            onPressed: _toggleShowInactive,
            tooltip: _showInactiveCoaches
                ? 'Hide inactive coaches'
                : 'Show inactive coaches',
          ),
          // Add new coach button
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => const CoachFormScreen(),
                ),
              );
            },
            tooltip: 'Add new coach',
          ),
        ],
      ),
      body: Consumer<CoachProvider>(
        builder: (ctx, coachProvider, _) {
          if (coachProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFB4FF00),
              ),
            );
          }

          if (coachProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${coachProvider.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadCoaches,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB4FF00),
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final coaches = coachProvider.coaches;

          if (coaches.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'No coaches found',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => const CoachFormScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB4FF00),
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Add Coach'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadCoaches,
            color: const Color(0xFFB4FF00),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: coaches.length,
              itemBuilder: (ctx, index) {
                final coach = coaches[index];
                return _buildCoachItem(context, coach);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildCoachItem(BuildContext context, CoachModel coach) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => CoachFormScreen(coachId: coach.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Coach header with profile image
            Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                image: coach.headerImageUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(coach.headerImageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: coach.headerImageUrl.isEmpty
                    ? const Color(0xFF2A2A2A)
                    : null,
              ),
              child: Stack(
                children: [
                  // Status indicator
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: coach.isActive
                            ? const Color(0xFFB4FF00)
                            : Colors.grey,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        coach.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          color: coach.isActive ? Colors.black : Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // Verified badge
                  if (coach.isVerified)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Coach info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile image
                  ClipOval(
                    child: SizedBox(
                      width: 70,
                      height: 70,
                      child: coach.profileImageUrl.isNotEmpty
                          ? Image.network(
                              coach.profileImageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.white70,
                              ),
                            )
                          : Container(
                              color: const Color(0xFF2A2A2A),
                              child: const Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.white70,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Coach details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          coach.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          coach.title,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[300],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: coach.specialties
                              .take(3)
                              .map(
                                (specialty) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2A2A2A),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    specialty,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Action buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Edit button
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => CoachFormScreen(coachId: coach.id),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFB4FF00),
                      side: const BorderSide(color: Color(0xFFB4FF00)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Delete button
                  OutlinedButton.icon(
                    onPressed: () => _showDeleteConfirmation(context, coach),
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(
      BuildContext context, CoachModel coach) async {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'Delete Coach',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete ${coach.name}? This action cannot be undone.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await Provider.of<CoachProvider>(
                context,
                listen: false,
              ).deleteCoach(coach.id);
              
              if (!mounted) return;
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? 'Coach deleted successfully'
                        : 'Failed to delete coach',
                  ),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
} 