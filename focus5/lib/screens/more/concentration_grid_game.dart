import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/user_model.dart'; // <-- Import User model
import 'package:cloud_firestore/cloud_firestore.dart'; // <-- Import Firestore
import 'dart:ui'; // <-- Import dart:ui for ImageFilter

class ConcentrationGridGame extends StatefulWidget {
  const ConcentrationGridGame({Key? key}) : super(key: key);

  @override
  State<ConcentrationGridGame> createState() => _ConcentrationGridGameState();
}

class _ConcentrationGridGameState extends State<ConcentrationGridGame> with SingleTickerProviderStateMixin {
  // Game variables
  List<int> numbers = [];
  int nextNumber = 0;
  int timeLeft = 60;
  Timer? timerInterval;
  bool gameOver = true;

  // Mode variables
  bool isHardMode = false;
  bool isHyperMode = false;
  bool hyperUnlocked = false;

  // Counters for unlocking hyper mode
  int easyRankClickCount = 0;

  // Stats variables
  int highScore = 0;
  int bestTime = 60;
  List<Map<String, dynamic>> attempts = [];

  // Hard mode data
  int hardHighScore = 0;
  int hardBestTime = 60;
  List<Map<String, dynamic>> hardAttempts = [];

  // Hyper mode data
  int hyperHighScore = 0;
  int hyperBestTime = 60;
  List<Map<String, dynamic>> hyperAttempts = [];

  // Animation controller for hyper mode
  late AnimationController _animationController;
  
  // Encouraging and motivational messages
  final List<String> encouragingMessages = [
    "Outstanding! You're really getting better!",
    "Incredible work—keep pushing those limits!",
    "Bravo! You've just set a new personal record!",
    "Fantastic improvement! Your dedication is paying off.",
    "Amazing effort! You're on a roll.",
    "Remarkable progress! You're surpassing your own expectations.",
    "Excellent job! Every attempt makes you stronger.",
    "You nailed it! A new milestone achieved.",
    "You're unstoppable! Keep up the great work.",
    "Impressive! Your hard work just shone through.",
    "Way to go! You're leveling up with every attempt.",
    "Terrific! You just raised the bar for yourself.",
    "You're soaring higher than ever before!",
    "Kudos! Persistence is your secret weapon.",
    "Outstanding performance! This sets a whole new standard.",
    "Stellar job—you're clearly on an upward trajectory!",
    "Exceptional work! That improvement is something to be proud of.",
    "You keep breaking through barriers—amazing!",
    "Brilliant move! You're outdoing yourself again.",
    "Phenomenal progress! You're smashing your own records."
  ];

  final List<String> motivationalMessages = [
    "Don't worry—every setback is a setup for a comeback.",
    "Keep your head up; each attempt gets you closer.",
    "Stay strong—improvement takes time.",
    "No worries, practice makes perfect.",
    "This was just one step on the journey, keep going!",
    "Every effort counts—keep trying!",
    "It's all about progress, not perfection.",
    "Chin up! You can always try again.",
    "This is just the beginning—your best is yet to come.",
    "Keep pushing! You'll outdo yourself next time.",
    "Hard work never goes to waste—stay persistent.",
    "You learn more from failures than successes.",
    "Focus on growth, not just the results.",
    "Every attempt is a valuable lesson.",
    "Your determination will pay off in the long run.",
    "Don't give up—consistency breeds excellence.",
    "Each attempt makes you wiser, keep going.",
    "Challenges are opportunities in disguise.",
    "Your time will come—just keep pushing forward.",
    "Remember, slow progress is still progress."
  ];

  String currentMessage = "";
  bool isGridBlurred = true;

  // Leaderboard State
  List<User> _leaderboardData = [];
  bool _leaderboardLoading = false;
  String? _leaderboardError;
  String _leaderboardModeTitle = 'Easy Mode'; // Track which leaderboard is shown

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
    
    loadData();
    generateNumbers();
    // Fetch leaderboard for default mode (Easy) initially when game over is true
    if (gameOver) {
       _fetchLeaderboardForMode('ConcentrationGrid'); 
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    timerInterval?.cancel();
    super.dispose();
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Easy mode
    highScore = prefs.getInt('highScore') ?? 0;
    bestTime = prefs.getInt('bestTime') ?? 60;
    String? attemptsJson = prefs.getString('leaderboard');
    if (attemptsJson != null) {
      try {
        Iterable l = jsonDecode(attemptsJson);
        attempts = List<Map<String, dynamic>>.from(
          l.map((model) => Map<String, dynamic>.from(model))
        );
      } catch (e) {
        attempts = [];
      }
    }

    // Hard mode
    hardHighScore = prefs.getInt('highScoreHard') ?? 0;
    hardBestTime = prefs.getInt('bestTimeHard') ?? 60;
    attemptsJson = prefs.getString('leaderboardHard');
    if (attemptsJson != null) {
      try {
        Iterable l = jsonDecode(attemptsJson);
        hardAttempts = List<Map<String, dynamic>>.from(
          l.map((model) => Map<String, dynamic>.from(model))
        );
      } catch (e) {
        hardAttempts = [];
      }
    }

    // Hyper mode
    hyperHighScore = prefs.getInt('highScoreHyper') ?? 0;
    hyperBestTime = prefs.getInt('bestTimeHyper') ?? 60;
    attemptsJson = prefs.getString('leaderboardHyper');
    if (attemptsJson != null) {
      try {
        Iterable l = jsonDecode(attemptsJson);
        hyperAttempts = List<Map<String, dynamic>>.from(
          l.map((model) => Map<String, dynamic>.from(model))
        );
      } catch (e) {
        hyperAttempts = [];
      }
    }

    // Check if hyper mode is unlocked
    hyperUnlocked = prefs.getBool('hyperUnlocked') ?? false;

    setState(() {});
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Easy mode
    await prefs.setInt('highScore', highScore);
    await prefs.setInt('bestTime', bestTime);
    await prefs.setString('leaderboard', jsonEncode(attempts));
    
    // Hard mode
    await prefs.setInt('highScoreHard', hardHighScore);
    await prefs.setInt('bestTimeHard', hardBestTime);
    await prefs.setString('leaderboardHard', jsonEncode(hardAttempts));
    
    // Hyper mode
    await prefs.setInt('highScoreHyper', hyperHighScore);
    await prefs.setInt('bestTimeHyper', hyperBestTime);
    await prefs.setString('leaderboardHyper', jsonEncode(hyperAttempts));
    
    // Hyper unlocked
    await prefs.setBool('hyperUnlocked', hyperUnlocked);
  }

  void generateNumbers() {
    List<int> arr = List.generate(100, (i) => i);
    
    // Shuffle the numbers
    final random = Random();
    for (int i = arr.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final temp = arr[i];
      arr[i] = arr[j];
      arr[j] = temp;
    }
    
    setState(() {
      numbers = arr;
    });
  }

  void startGame(bool hardMode, bool hyperMode) {
    setState(() {
      gameOver = false;
      nextNumber = 0;
      timeLeft = 60;
      isHardMode = hardMode;
      isHyperMode = hyperMode;
      isGridBlurred = false;
      currentMessage = "";
    });
    
    startTimer();
  }

  void startTimer() {
    timerInterval?.cancel();
    timerInterval = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        timeLeft--;
        if (timeLeft <= 0) {
          endGame();
        }
      });
    });
  }

  void cellClicked(int clickedNum) {
    if (gameOver) return;
    
    if (clickedNum == nextNumber) {
      setState(() {
        nextNumber++;
        if (nextNumber == 100) {
          endGame();
        }
      });
    }
  }

  void endGame() {
    timerInterval?.cancel();
    
    int currentScore = nextNumber;
    int currentTimeTaken = 60 - timeLeft;

    // ... (logic to determine currentAttempts, currentHighScore, currentBestTime, gameCriteriaType) ...
    String gameCriteriaType; // Declare here
    int currentHighScore;    // Declare here
    int currentBestTime;     // Declare here
    List<Map<String, dynamic>> currentAttempts; // Declare here

    if (isHyperMode) {
      currentAttempts = hyperAttempts;
      currentHighScore = hyperHighScore;
      currentBestTime = hyperBestTime;
      gameCriteriaType = 'ConcentrationGridHyper'; 
    } else if (isHardMode) {
      currentAttempts = hardAttempts;
      currentHighScore = hardHighScore;
      currentBestTime = hardBestTime;
      gameCriteriaType = 'ConcentrationGridHard';
    } else {
      currentAttempts = attempts;
      currentHighScore = highScore;
      currentBestTime = bestTime;
      gameCriteriaType = 'ConcentrationGrid';
    }
    // Add current attempt to local list
    currentAttempts.add({'score': currentScore, 'time': currentTimeTaken});

    // Check improvement for local storage
    bool improvedLocally = false;
    if (currentScore > currentHighScore || 
        (currentScore == currentHighScore && currentTimeTaken < currentBestTime)) {
      improvedLocally = true;
      // ... (update local high scores: hyperHighScore, hardHighScore, highScore) ...
      if (isHyperMode) {
        hyperHighScore = currentScore;
        hyperBestTime = currentTimeTaken;
      } else if (isHardMode) {
        hardHighScore = currentScore;
        hardBestTime = currentTimeTaken;
      } else {
        highScore = currentScore;
        bestTime = currentTimeTaken;
      }
    }

    // Save local data (attempts history, personal best, unlock status)
    saveData();

    // ---- Update Firestore High Score and Check Badges ----
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      userProvider.updateGameHighScore(gameCriteriaType, currentScore, context: context);
      print('ConcentrationGridGame: Called updateGameHighScore for $gameCriteriaType with score $currentScore');
    } catch (e) {
       print('ConcentrationGridGame: Error getting UserProvider: $e');
    }
    // ----------------------------------------------------

    // --- Fetch Global Leaderboard for the finished mode ---
    // Fetch leaderboard AFTER saving the score
    _fetchLeaderboardForMode(gameCriteriaType);
    // ------------------------------------------------------

    // Check if hyper mode should unlock via Hard mode score
    if (isHardMode && currentScore >= 20 && !hyperUnlocked) {
      hyperUnlocked = true;
      saveData(); // Save unlock status locally again just in case
    }

    showEndMessage(improvedLocally); // Show message based on local improvement
    
    setState(() {
      gameOver = true;
      isGridBlurred = true;
    });
    
    generateNumbers(); // Prepare grid for next game
  }

  void showEndMessage(bool improved) {
    final random = Random();
    String message;
    
    if (improved) {
      message = encouragingMessages[random.nextInt(encouragingMessages.length)];
    } else {
      message = motivationalMessages[random.nextInt(motivationalMessages.length)];
    }
    
    setState(() {
      currentMessage = message;
    });
  }

  void handleRankHeaderClick() {
    easyRankClickCount++;
    if (easyRankClickCount >= 3 && !hyperUnlocked) {
      setState(() {
        hyperUnlocked = true;
      });
      saveData();
    }
  }

  // --- Fetch Global Leaderboard Data ---
  Future<void> _fetchLeaderboardForMode(String criteriaType) async {
    // Skip fetch for hyper mode for now, or implement if needed
    if (criteriaType == 'ConcentrationGridHyper') {
      setState(() {
        _leaderboardData = [];
        _leaderboardLoading = false;
        _leaderboardError = 'Hyper Mode Leaderboard Not Available Yet.';
        _leaderboardModeTitle = 'Hyper Mode';
      });
      return;
    }

    setState(() {
      _leaderboardLoading = true;
      _leaderboardError = null;
      _leaderboardModeTitle = criteriaType == 'ConcentrationGridHard' ? 'Hard Mode' : 'Easy Mode';
    });

    String scoreField;
    bool descending;

    switch (criteriaType) {
      case 'ConcentrationGridHard':
        scoreField = 'highScoreGridHard';
        descending = true;
        break;
      case 'ConcentrationGrid':
      default:
        scoreField = 'highScoreGrid';
        descending = true;
        break;
    }

    try {
      final firestore = FirebaseFirestore.instance;
      final query = firestore
          .collection('users')
          .where(scoreField, isGreaterThan: 0) // Only users who have played
          .orderBy(scoreField, descending: descending)
          .limit(10); // Limit to top 10

      final snapshot = await query.get();

      final users = snapshot.docs
          .map((doc) {
              try {
                return User.fromFirestore(doc);
              } catch (e) {
                 print("Error parsing user data for leaderboard: ${doc.id}, Error: $e");
                 return null;
              }
            })
          .where((user) => user != null)
          .cast<User>()
          .toList();

      if (mounted) {
          setState(() {
            _leaderboardData = users;
            _leaderboardLoading = false;
          });
      }
    } catch (e) {
      print("Error fetching leaderboard for $criteriaType: $e");
      if (mounted) {
          setState(() {
            _leaderboardLoading = false;
            _leaderboardError = "Failed to load leaderboard.";
          });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onBackground;
    final secondaryTextColor = themeProvider.secondaryTextColor;
    final accentColor = themeProvider.accentColor;

    return WillPopScope(
      onWillPop: () async {
        if (gameOver) {
          return true;
        } else {
          _showExitConfirmationDialog();
          return false;
        }
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: backgroundColor,
          elevation: 0,
          title: Text(
            'Concentration Grid',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
            onPressed: () {
              if (gameOver) {
                Navigator.of(context).pop();
              } else {
                _showExitConfirmationDialog();
              }
            },
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.help_outline, color: textColor),
              onPressed: _showInstructions,
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Mode selection buttons
                  if (gameOver)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () => startGame(false, false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Start (Easy)', 
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () => startGame(true, false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Hard Mode', 
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        if (hyperUnlocked) ...[
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () => startGame(false, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Hyper Mode', 
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                  
                  // Game info
                  if (!gameOver) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Time left: $timeLeft seconds',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Next: ${nextNumber.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  color: accentColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your best: ${isHyperMode ? hyperHighScore : (isHardMode ? hardHighScore : highScore)} numbers, in ${isHyperMode ? hyperBestTime : (isHardMode ? hardBestTime : bestTime)} s',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  
                  // Grid
                  buildGrid(),
                  
                  const SizedBox(height: 20),
                  
                  // Message
                  if (currentMessage.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: accentColor, width: 1),
                      ),
                      child: Text(
                        currentMessage,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // --- Global Leaderboard Display (Replaces local leaderboards) ---
                  if (gameOver) _buildGlobalLeaderboard(),
                  // --------------------------------------------------------------
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildGrid() {
    final accentColor = const Color(0xFFB4FF00);
    
    // The actual GridView widget
    Widget gridViewWidget = GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 10,
        childAspectRatio: 1.0,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
      ),
      itemCount: 100,
      itemBuilder: (context, index) {
        int num = numbers[index];
        bool isVisible = num < nextNumber; // Number already found
        
        return GestureDetector(
          onTap: () => cellClicked(num),
          child: Container(
            decoration: BoxDecoration(
              color: isVisible 
                  ? Colors.grey.shade800 // Dim color for found numbers
                  : Theme.of(context).colorScheme.surface, 
              border: Border.all(
                color: isVisible ? Colors.transparent : Colors.grey.shade500,
                width: 1
              ),
            ),
            child: Center(
              child: isVisible
                ? null // Hide text for found numbers
                : Text(
                    num.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
            ),
          ),
        );
      },
    );

    // Apply animations if game is active
    if (isHyperMode && !gameOver) {
      return AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          final value = _animationController.value;
          final colors = [
            Colors.redAccent.withOpacity(0.3),
            Colors.blueAccent.withOpacity(0.3),
            Colors.greenAccent.withOpacity(0.3),
            Colors.yellowAccent.withOpacity(0.3),
            Colors.purpleAccent.withOpacity(0.3),
            Colors.orangeAccent.withOpacity(0.3),
          ];
          
          final colorIndex = (value * colors.length).floor() % colors.length;
          final nextColorIndex = (colorIndex + 1) % colors.length;
          final colorPercent = (value * colors.length) - colorIndex;
          
          final color = Color.lerp(
            colors[colorIndex], 
            colors[nextColorIndex], 
            colorPercent,
          ) ?? Colors.transparent;
          
          final angle = sin(value * 2 * pi) * 0.1;
          
          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateZ(angle)
              ..scale(0.98 + sin(value * 2 * pi) * 0.04),
            alignment: Alignment.center,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: child,
            ),
          );
        },
        child: gridViewWidget,
      );
    } else if (isHardMode && !gameOver) {
      return AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          final value = _animationController.value;
          final angle = sin(value * 2 * pi) * 0.1;
          
          return Transform(
            transform: Matrix4.identity()..rotateZ(angle),
            alignment: Alignment.center,
            child: child,
          );
        },
        child: gridViewWidget,
      );
    } else {
      // Default state: Apply blur if game is over/not started
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade800),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect( // Clip the blur effect to the rounded corners
           borderRadius: BorderRadius.circular(7), // Slightly smaller than container radius
           child: ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: isGridBlurred ? 5 : 0, // Apply blur based on state
              sigmaY: isGridBlurred ? 5 : 0, 
            ),
            child: gridViewWidget, // The actual grid
          ),
        ),
      );
    }
  }

  // --- New Widget to Display Global Leaderboard ---
  Widget _buildGlobalLeaderboard() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final textColor = Theme.of(context).colorScheme.onBackground;
    final secondaryTextColor = themeProvider.secondaryTextColor;
    final surfaceColor = Theme.of(context).colorScheme.surface;

    return Column(
      children: [
         Text(
          '$_leaderboardModeTitle Leaderboard',
          style: TextStyle(
            color: textColor,
            fontSize: 20, // Slightly smaller than before maybe
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // Loading Indicator
              if (_leaderboardLoading)
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(),
                ),
                
              // Error Message
              if (!_leaderboardLoading && _leaderboardError != null)
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    _leaderboardError!,
                    style: TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
                
              // No Scores Message
              if (!_leaderboardLoading && _leaderboardError == null && _leaderboardData.isEmpty)
                 Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    'No scores recorded yet! Be the first!',
                    style: TextStyle(color: secondaryTextColor, fontSize: 16),
                     textAlign: TextAlign.center,
                  ),
                ),
              
              // Leaderboard List
              if (!_leaderboardLoading && _leaderboardError == null && _leaderboardData.isNotEmpty)
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _leaderboardData.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: Colors.grey.shade700,
                    indent: 16,
                    endIndent: 16,
                  ),
                  itemBuilder: (context, index) {
                    final user = _leaderboardData[index];
                    
                    // Determine score based on the title (which reflects the fetched mode)
                    int? score = _leaderboardModeTitle == 'Hard Mode'
                                  ? user.highScoreGridHard
                                  : user.highScoreGrid;
                                      
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 15,
                        child: Text('${index + 1}'), // Rank
                      ),
                      title: Text(
                        user.fullName ?? 'Focus User', 
                        style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(
                        score?.toString() ?? '-',
                        style: TextStyle(
                          color: themeProvider.accentColor, // Highlight score
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
  // --- End Global Leaderboard Widget ---

  void _showInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to Play Concentration Grid'),
        content: const SingleChildScrollView(
          child: Text(
            'Tap the numbers on the grid in sequence, starting from 0.\n\n'
            'Find as many numbers as you can before the 60-second timer runs out.\n\n'
            'Modes:\n'
            '- Easy: Standard 60-second challenge.\n'
            '- Hard: The grid layout changes frequently!\n'
            '- Hyper: Unlockable challenge! Find 20 in Hard Mode or ???\n\n'
            'Your score is the highest number you tapped correctly.'
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  void _showExitConfirmationDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final textColor = Theme.of(context).colorScheme.onBackground;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(
          'Exit Game?',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to exit? Your progress will be lost.',
          style: TextStyle(color: textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: themeProvider.secondaryTextColor,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Exit game
            },
            child: Text(
              'Exit',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 