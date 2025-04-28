import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/theme_provider.dart';
import '../../models/user_model.dart'; // Assuming User model exists

enum GameLeaderboardType { concentrationGrid, concentrationGridHard, wordSearch }

class GameLeaderboardScreen extends StatefulWidget {
  final GameLeaderboardType gameType;

  const GameLeaderboardScreen({Key? key, required this.gameType}) : super(key: key);

  @override
  _GameLeaderboardScreenState createState() => _GameLeaderboardScreenState();
}

class _GameLeaderboardScreenState extends State<GameLeaderboardScreen> {
  List<User> _leaderboard = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  String get _gameTitle {
    switch (widget.gameType) {
      case GameLeaderboardType.concentrationGrid:
        return 'Concentration Grid';
      case GameLeaderboardType.concentrationGridHard:
        return 'Concentration Grid (Hard)';
      case GameLeaderboardType.wordSearch:
        return 'Word Search';
    }
  }

  String get _scoreField {
    switch (widget.gameType) {
      case GameLeaderboardType.concentrationGrid:
        return 'highScoreGrid';
      case GameLeaderboardType.concentrationGridHard:
        return 'highScoreGridHard';
      case GameLeaderboardType.wordSearch:
        return 'highScoreWordSearch';
    }
  }

  bool get _orderByDescending {
    // Order descending for score-based games (higher is better)
    return widget.gameType == GameLeaderboardType.concentrationGrid ||
           widget.gameType == GameLeaderboardType.concentrationGridHard;
  }

  Future<void> _fetchLeaderboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final firestore = FirebaseFirestore.instance;
      final query = firestore
          .collection('users')
          .where(_scoreField, isGreaterThan: 0) // Only include users who have played
          .orderBy(_scoreField, descending: _orderByDescending)
          .limit(20); // Limit to top 20 for example

      final snapshot = await query.get();

      final users = snapshot.docs
          .map((doc) {
              try {
                // Make sure your User.fromFirestore handles potential nulls gracefully
                return User.fromFirestore(doc); 
              } catch (e) {
                 print("Error parsing user data for leaderboard: ${doc.id}, Error: $e");
                 return null; // Return null for users that fail parsing
              }
            })
          .where((user) => user != null) // Filter out nulls from parsing errors
          .cast<User>() // Cast to User type
          .toList();

      setState(() {
        _leaderboard = users;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching leaderboard: $e");
      setState(() {
        _isLoading = false;
        _errorMessage = "Failed to load leaderboard.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final textColor = Theme.of(context).colorScheme.onBackground;

    return Scaffold(
      appBar: AppBar(
        title: Text('$_gameTitle Leaderboard'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchLeaderboard,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(child: Text(_errorMessage!, style: TextStyle(color: Colors.red)))
                : _leaderboard.isEmpty
                    ? Center(child: Text('No scores recorded yet!', style: TextStyle(color: textColor)))
                    : ListView.builder(
                        itemCount: _leaderboard.length,
                        itemBuilder: (context, index) {
                          final user = _leaderboard[index];
                          
                          // Get the score dynamically based on game type
                          int? score;
                          switch (widget.gameType) {
                            case GameLeaderboardType.concentrationGrid:
                              score = user.highScoreGrid;
                              break;
                            case GameLeaderboardType.concentrationGridHard:
                              score = user.highScoreGridHard;
                              break;
                            case GameLeaderboardType.wordSearch:
                              score = user.highScoreWordSearch; // Already an int
                              break;
                          }
                          
                          final scoreDisplay = score != null 
                             ? (widget.gameType == GameLeaderboardType.wordSearch ? '$score s' : score.toString())
                             : '-';


                          return ListTile(
                            leading: CircleAvatar(
                              child: Text('${index + 1}'), // Rank
                            ),
                            title: Text(user.fullName ?? 'Unknown User', style: TextStyle(color: textColor)),
                            // Add profile image if available: user.profileImageUrl
                            trailing: Text(
                              scoreDisplay,
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
} 