import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
    
    loadData();
    generateNumbers();
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

    List<Map<String, dynamic>> currentAttempts;
    int currentHighScore;
    int currentBestTime;
    
    if (isHyperMode) {
      currentAttempts = hyperAttempts;
      currentHighScore = hyperHighScore;
      currentBestTime = hyperBestTime;
    } else if (isHardMode) {
      currentAttempts = hardAttempts;
      currentHighScore = hardHighScore;
      currentBestTime = hardBestTime;
    } else {
      currentAttempts = attempts;
      currentHighScore = highScore;
      currentBestTime = bestTime;
    }

    currentAttempts.add({'score': currentScore, 'time': currentTimeTaken});

    // Check improvement
    bool improved = false;
    if (currentScore > currentHighScore || 
        (currentScore == currentHighScore && currentTimeTaken < currentBestTime)) {
      improved = true;
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

    // Check if hyper mode should unlock via Hard mode score
    if (isHardMode && currentScore >= 20 && !hyperUnlocked) {
      hyperUnlocked = true;
    }

    saveData();
    showEndMessage(improved);
    
    setState(() {
      gameOver = true;
      isGridBlurred = true;
    });
    
    generateNumbers();
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

  @override
  Widget build(BuildContext context) {
    final accentColor = const Color(0xFFB4FF00);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Concentration Grid',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
                
                // Leaderboards
                if (gameOver) buildLeaderboards(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildGrid() {
    final accentColor = const Color(0xFFB4FF00);
    
    Widget gridWidget = GridView.builder(
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
        bool isFound = nextNumber > numbers[index];
        return GestureDetector(
          onTap: () => cellClicked(numbers[index]),
          child: Container(
            decoration: BoxDecoration(
              color: isFound ? Colors.green.withOpacity(0.5) : const Color(0xFF1A1A1A),
              border: Border.all(color: Colors.grey.shade800),
            ),
            child: Center(
              child: Text(
                numbers[index].toString().padLeft(2, '0'),
                style: TextStyle(
                  color: isFound ? Colors.white : Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );

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
        child: gridWidget,
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
        child: gridWidget,
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade800),
          borderRadius: BorderRadius.circular(8),
        ),
        child: isGridBlurred
          ? ImageFiltered(
              imageFilter: ColorFilter.matrix([
                1, 0, 0, 0, 0,
                0, 1, 0, 0, 0,
                0, 0, 1, 0, 0,
                0, 0, 0, 5, -5, // Last value controls blur amount
              ]),
              child: gridWidget,
            )
          : gridWidget,
      );
    }
  }

  Widget buildLeaderboards() {
    return Column(
      children: [
        const Text(
          'Leaderboards',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        if (attempts.isNotEmpty) 
          buildLeaderboardSection('Easy Mode', attempts),
          
        if (hardAttempts.isNotEmpty)
          buildLeaderboardSection('Hard Mode', hardAttempts),
          
        if (hyperUnlocked && hyperAttempts.isNotEmpty)
          buildLeaderboardSection('Hyper Mode', hyperAttempts),
      ],
    );
  }

  Widget buildLeaderboardSection(String title, List<Map<String, dynamic>> modeAttempts) {
    // Sort attempts
    List<Map<String, dynamic>> sorted = List.from(modeAttempts);
    sorted.sort((a, b) {
      if (b['score'] != a['score']) return b['score'] - a['score'];
      return a['time'] - b['time'];
    });
    
    // Take top 5
    if (sorted.length > 5) {
      sorted = sorted.sublist(0, 5);
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Headers
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  // Only attach the listener for easy mode
                  onTap: title == 'Easy Mode' ? handleRankHeaderClick : null,
                  child: const SizedBox(
                    width: 60,
                    child: Text(
                      'Rank',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Score',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 80,
                  child: Text(
                    'Time (s)',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          // Rows
          ...List.generate(sorted.length, (index) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: index % 2 == 0 ? Colors.transparent : Colors.black.withOpacity(0.2),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${sorted[index]['score']}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: Text(
                      '${sorted[index]['time']}',
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
} 