import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/theme_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/user_permissions_service.dart';

class PartnerAdminScreen extends StatefulWidget {
  const PartnerAdminScreen({Key? key}) : super(key: key);

  @override
  State<PartnerAdminScreen> createState() => _PartnerAdminScreenState();
}

class _PartnerAdminScreenState extends State<PartnerAdminScreen> {
  final UserPermissionsService _permissionsService = UserPermissionsService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isLoading = true;
  String _statusMessage = '';
  String? _universityCode;
  String? _userSport;
  List<Map<String, dynamic>> _users = [];
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Loading...';
    });
    
    try {
      // Get current user's university code and sport
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
        _universityCode = userDoc.data()?['universityCode'];
        _userSport = userDoc.data()?['sport'];
        
        if (_universityCode != null) {
          // Get all users from the university
          final usersQuery = await _firestore
              .collection('users')
              .where('universityCode', isEqualTo: _universityCode)
              .get();
          
          _users = usersQuery.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'fullName': data['fullName'] ?? '',
              'email': data['email'] ?? '',
              'lastActive': data['lastActive'] ?? '',
              'badges': data['badges'] ?? [],
              'completedCourses': data['completedCourses'] ?? [],
              'sport': data['sport'] ?? '',
              'isPartnerCoach': data['isPartnerCoach'] ?? false,
              'isPartnerChampion': data['isPartnerChampion'] ?? false,
            };
          }).toList();
          
          // If user is a coach, filter by sport
          if (_userSport != null) {
            _users = _users.where((user) => user['sport'] == _userSport).toList();
          }
        }
      }
      
      setState(() {
        _isLoading = false;
        _statusMessage = '';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onBackground;
    final accentColor = themeProvider.accentColor;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Text(
          'Partner Admin',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: accentColor),
                  const SizedBox(height: 16),
                  Text(
                    _statusMessage,
                    style: TextStyle(color: textColor),
                  ),
                ],
              ),
            )
          : _users.isEmpty
              ? Center(
                  child: Text(
                    'No users found',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    return Card(
                      color: cardColor,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  user['fullName'],
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                if (user['isPartnerCoach'] || user['isPartnerChampion'])
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: accentColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      user['isPartnerChampion'] ? 'Champion' : 'Coach',
                                      style: TextStyle(
                                        color: accentColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              user['email'],
                              style: TextStyle(
                                color: textColor.withOpacity(0.7),
                              ),
                            ),
                            if (user['sport'] != null && user['sport'].isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Sport: ${user['sport']}',
                                style: TextStyle(
                                  color: textColor.withOpacity(0.7),
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildStatItem(
                                  context,
                                  'Badges',
                                  user['badges'].length.toString(),
                                  Icons.workspace_premium,
                                ),
                                _buildStatItem(
                                  context,
                                  'Courses',
                                  user['completedCourses'].length.toString(),
                                  Icons.school,
                                ),
                                _buildStatItem(
                                  context,
                                  'Last Active',
                                  _formatDate(user['lastActive']),
                                  Icons.access_time,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon) {
    final textColor = Theme.of(context).colorScheme.onBackground;
    return Column(
      children: [
        Icon(
          icon,
          color: textColor.withOpacity(0.7),
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: textColor.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'Never';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Invalid date';
    }
  }
} 