import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:transparent_image/transparent_image.dart';

import '../../providers/theme_provider.dart';
import '../home/coach_profile_screen.dart';

class CoachesListScreen extends StatefulWidget {
  const CoachesListScreen({Key? key}) : super(key: key);

  @override
  State<CoachesListScreen> createState() => _CoachesListScreenState();
}

class _CoachesListScreenState extends State<CoachesListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _coaches = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _loadCoaches();
  }
  
  Future<void> _loadCoaches() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      final QuerySnapshot coachesSnapshot = await _firestore
          .collection('coaches')
          .where('isActive', isEqualTo: true)
          .get();
      
      final List<Map<String, dynamic>> loadedCoaches = coachesSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Unknown Coach',
          'title': data['title'] ?? 'Mental Performance Coach',
          'specialization': data['specialization'] ?? 'Performance',
          'description': data['description'] ?? 'No description available',
          'bio': data['bio'] ?? 'Former Olympic athlete with a PhD in Sports Psychology. Specializes in mental toughness training and performance under pressure.',
          'imageUrl': data['imageUrl'] ?? 'https://via.placeholder.com/300',
          'rating': data['rating'] ?? 4.9,
          'reviews': data['reviews'] ?? 142,
          'location': data['location'] ?? 'Remote',
          'experience': data['experience'] ?? '15+ years',
          'price': data['price'] ?? 99,
          'isActive': data['isActive'] ?? true,
        };
      }).toList();
      
      setState(() {
        _coaches = loadedCoaches;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load coaches: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).colorScheme.onBackground;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Coaches',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: themeProvider.accentColor))
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Error',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: textColor),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadCoaches,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : _coaches.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_off, size: 48, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            'No Coaches Available',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Check back later for new coaches',
                            style: TextStyle(color: textColor.withOpacity(0.7)),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _coaches.length,
                      itemBuilder: (context, index) {
                        final coach = _coaches[index];
                        return _buildCoachListItem(coach, textColor, themeProvider);
                      },
                    ),
    );
  }
  
  Widget _buildCoachListItem(Map<String, dynamic> coach, Color textColor, ThemeProvider themeProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CoachProfileScreen(
                coachId: coach['id'],
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Coach image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FadeInImage.memoryNetwork(
                  placeholder: kTransparentImage,
                  image: coach['imageUrl'] ?? 'https://via.placeholder.com/80x80',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  imageErrorBuilder: (context, error, stackTrace) {
                    debugPrint('Coach image error: $error');
                    return Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(Icons.person, size: 40),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              // Coach details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      coach['name'] ?? 'Unknown Coach',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      coach['title'] ?? 'Mental Performance Coach',
                      style: TextStyle(
                        fontSize: 14,
                        color: textColor.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Rating
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${coach['rating'] ?? 5.0}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${coach['reviews'] ?? 0} reviews)',
                          style: TextStyle(
                            fontSize: 14,
                            color: textColor.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // View profile button
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CoachProfileScreen(
                                coachId: coach['id'],
                              ),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: themeProvider.accentColor,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text('View Profile'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 