import 'dart:io'; // Restored import
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart'; // Restored import
// import '../../models/coach.dart'; // Commented out incorrect import
import '../../models/coach_model.dart'; // Corrected import path
import '../../providers/coach_provider.dart';
import 'coach_form_screen.dart';
import 'package:focus5/services/firebase_storage_service.dart'; // Restored import
// import 'package:focus5/services/image_service.dart'; // Still commented out (missing file)
// import 'package:focus5/utils/image_utils.dart'; // Still commented out (likely unused here)
// import 'package:focus5/widgets/custom_button.dart'; // Still commented out (unused here)

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
    await Provider.of<CoachProvider>(context, listen: false).loadCoaches();
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

          final coaches = coachProvider.coaches
              .where((coach) => _showInactiveCoaches || coach.isActive)
              .toList();

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

  Widget _buildCoachItem(BuildContext context, Coach coach) {
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
                image: coach.profileImageUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(coach.profileImageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: coach.profileImageUrl.isEmpty
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
                ],
              ),
            ),
            
            // Coach info
            Padding(
              padding: const EdgeInsets.all(16),
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
                  const SizedBox(height: 8),
                  Text(
                    coach.title,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (coach.specialization?.isNotEmpty ?? false)
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: coach.specialization!
                          .map((spec) => Chip(
                                label: Text(spec),
                                backgroundColor: const Color(0xFF2A2A2A),
                                labelStyle: const TextStyle(color: Colors.white),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                visualDensity: VisualDensity.compact,
                              ))
                          .toList(),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ID: ${coach.id}',
                        style: const TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Color(0xFFB4FF00), size: 20),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (ctx) => CoachFormScreen(coachId: coach.id),
                                ),
                              );
                            },
                            tooltip: 'Edit Coach',
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          IconButton(
                            icon: Icon(
                              coach.isActive ? Icons.toggle_on : Icons.toggle_off,
                              color: coach.isActive ? const Color(0xFFB4FF00) : Colors.grey,
                              size: 30,
                            ),
                            onPressed: () => _toggleCoachStatus(context, coach),
                            tooltip: coach.isActive ? 'Deactivate Coach' : 'Activate Coach',
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleCoachStatus(BuildContext context, Coach coach) async {
    final coachProvider = Provider.of<CoachProvider>(context, listen: false);
    final newStatus = !coach.isActive;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(newStatus ? 'Activate Coach?' : 'Deactivate Coach?', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to ${newStatus ? 'activate' : 'deactivate'} ${coach.name}?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          TextButton(
            child: Text(newStatus ? 'Activate' : 'Deactivate', style: TextStyle(color: const Color(0xFFB4FF00))),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await coachProvider.updateCoachStatus(coach.id, newStatus);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${coach.name} ${newStatus ? 'activated' : 'deactivated'}')),
        );
        _loadCoaches();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e')),
        );
      }
    }
  }
} 