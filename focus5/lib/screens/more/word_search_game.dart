import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/theme_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WordSearchGame extends StatefulWidget {
  const WordSearchGame({Key? key}) : super(key: key);

  @override
  State<WordSearchGame> createState() => _WordSearchGameState();
}

class _WordSearchGameState extends State<WordSearchGame> {
  // Game variables
  final List<WordData> WORD_BANK = [
    WordData(word: 'FOCUS', def: 'Concentration on a single point.'),
    WordData(word: 'GRIT', def: 'Persistence and determination.'),
    WordData(word: 'CALM', def: 'Peaceful and relaxed state.'),
    WordData(word: 'MIND', def: 'Element enabling thought.'),
    WordData(word: 'FLOW', def: 'State of total immersion.'),
    WordData(word: 'AIM', def: 'Directing efforts towards a goal.'),
    WordData(word: 'REST', def: 'Relaxation to restore energy.'),
    WordData(word: 'CORE', def: 'Essential central part.'),
    WordData(word: 'EASE', def: 'Absence of difficulty.'),
    WordData(word: 'ZONE', def: 'Mental state of optimal performance.'),
    WordData(word: 'WILL', def: 'Power to decide and act.'),
    WordData(word: 'POISE', def: 'Balanced, controlled composure.'),
    WordData(word: 'FAITH', def: 'Complete trust or confidence.'),
    WordData(word: 'HARDY', def: 'Capable of enduring hardship.'),
    WordData(word: 'LEVEL', def: 'Consistent, stable mental state.'),
    WordData(word: 'PEAK', def: 'Highest point of performance.'),
    WordData(word: 'FIRM', def: 'Strong and unyielding decision.'),
    WordData(word: 'RESILIENCE', def: 'Recover quickly from difficulties.'),
    WordData(word: 'MOTIVATION', def: 'Reasons for acting a certain way.'),
    WordData(word: 'CONFIDENCE', def: 'Self-assurance in abilities.'),
    WordData(word: 'VISUALIZATION', def: 'Mental images to improve performance.'),
    WordData(word: 'MINDFULNESS', def: 'Being fully present and aware.'),
    WordData(word: 'AROUSAL', def: 'State of being alert.'),
    WordData(word: 'SELFTALK', def: 'Internal dialogue shaping thoughts.'),
    WordData(word: 'PERSISTENCE', def: 'Continued effort despite difficulty.'),
    WordData(word: 'ADAPTABILITY', def: 'Ability to adjust to changes.'),
    WordData(word: 'DISCIPLINE', def: 'Controlled behavior for consistency.'),
    WordData(word: 'PREPARATION', def: 'Getting ready mentally/physically.'),
    WordData(word: 'SELFREGULATION', def: 'Managing emotions/actions toward goals.'),
    WordData(word: 'OPTIMISM', def: 'Hopefulness about the future.'),
    WordData(word: 'ANTICIPATION', def: 'Predicting and preparing.'),
    WordData(word: 'CLARITY', def: 'Mental sharpness and understanding.'),
    WordData(word: 'DETERMINATION', def: 'Firmness of purpose.'),
    WordData(word: 'IMAGERY', def: 'Mental pictures to enhance skills.'),
    WordData(word: 'REFRAMING', def: 'Changing perspective on challenges.'),
    WordData(word: 'PERSEVERANCE', def: 'Steady persistence despite difficulty.'),
    WordData(word: 'EMPATHY', def: 'Understanding others\' emotions.'),
    WordData(word: 'SELFCONFIDENCE', def: 'Belief in your own capabilities.'),
    WordData(word: 'COMPOSURE', def: 'Calmness and self-control.'),
    WordData(word: 'STAMINA', def: 'Ability to sustain effort.'),
    WordData(word: 'AGILITY', def: 'Ability to move quickly and easily.'),
    WordData(word: 'ENDURANCE', def: 'Withstand prolonged effort.'),
    WordData(word: 'ALERTNESS', def: 'Being watchful and ready.'),
    WordData(word: 'CALMNESS', def: 'State of being tranquil.'),
    WordData(word: 'STABILITY', def: 'Being steady and not easily upset.'),
    WordData(word: 'RESOLVE', def: 'Firm determination to do something.'),
    WordData(word: 'AWARENESS', def: 'Knowledge of a situation.'),
    WordData(word: 'BALANCE', def: 'Harmonious stability.'),
    WordData(word: 'CENTERING', def: 'Focusing on a stable point.'),
    WordData(word: 'BREATHING', def: 'Inhaling and exhaling.'),
  ];

  final int WORD_COUNT = 6;
  final int GRID_SIZE = 12;
  
  List<WordData> chosenWords = [];
  Map<String, String> definitionsMap = {};
  List<List<Cell>> grid = [];
  int foundCount = 0;
  int timer = 0;
  Timer? timerInterval;
  bool isGameActive = false;
  bool isGridBlurred = true;
  Cell? startCell;
  Cell? endCell;
  List<List<int>> currentDragLine = [];
  List<int> bestTimes = [];

  // Leaderboard State
  List<User> _leaderboardData = [];
  bool _leaderboardLoading = false;
  String? _leaderboardError;

  @override
  void initState() {
    super.initState();
    loadTimes();
    generateRandomLetterGrid();
    _fetchLeaderboard();
  }

  @override
  void dispose() {
    timerInterval?.cancel();
    super.dispose();
  }

  Future<void> loadTimes() async {
    final prefs = await SharedPreferences.getInstance();
    String? timesJson = prefs.getString('wordSearchTimes');
    if (timesJson != null) {
      try {
        List<dynamic> decodedTimes = jsonDecode(timesJson);
        setState(() {
          bestTimes = List<int>.from(decodedTimes.whereType<int>());
        });
      } catch (e) {
        setState(() {
          bestTimes = [];
        });
      }
    }
  }

  Future<void> recordAndShowCompletion(int seconds) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      userProvider.updateGameHighScore('WordSearch', seconds, context: context);
      print('WordSearchGame: Called updateGameHighScore with time $seconds seconds');
    } catch (e) {
      print('WordSearchGame: Error getting UserProvider: $e');
    }
    
    final prefs = await SharedPreferences.getInstance();
    List<int> currentLocalBestTimes = List<int>.from(bestTimes);
    currentLocalBestTimes.add(seconds);
    currentLocalBestTimes.sort();
    if (currentLocalBestTimes.length > 10) {
      currentLocalBestTimes = currentLocalBestTimes.sublist(0, 10);
    }
    await prefs.setString('wordSearchTimes', jsonEncode(currentLocalBestTimes));
    setState(() {
      bestTimes = currentLocalBestTimes;
    });
    
    _fetchLeaderboard();
    
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Congratulations!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('You completed the word search in $seconds seconds!'),
              const SizedBox(height: 16),
              const Text('Your Best Times (Local):'),
              const SizedBox(height: 8),
              Container(
                height: 150,
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: bestTimes.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      dense: true,
                      title: Text(
                        '${index + 1}. ${bestTimes[index]} seconds',
                        style: const TextStyle(fontSize: 14),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                restartGame();
              },
              child: const Text('Play Again'),
            ),
          ],
        ),
      );
    }
  }

  void startTimer() {
    timer = 0;
    timerInterval = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        this.timer++;
      });
    });
  }

  void stopTimer() {
    timerInterval?.cancel();
    timerInterval = null;
  }

  void startGame() {
    setState(() {
      isGameActive = true;
      isGridBlurred = false;
      generatePuzzle();
      startTimer();
    });
  }

  void restartGame() {
    stopTimer();
    setState(() {
      isGameActive = true;
      isGridBlurred = false;
      foundCount = 0;
      generatePuzzle();
      startTimer();
    });
  }

  String randomLetter() {
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    return letters[Random().nextInt(letters.length)];
  }

  void generateRandomLetterGrid() {
    grid = List.generate(
      GRID_SIZE,
      (r) => List.generate(
        GRID_SIZE,
        (c) => Cell(letter: randomLetter(), found: false),
      ),
    );
  }

  void generatePuzzle() {
    foundCount = 0;
    
    // Choose words with no more than 2 words > 6 letters
    chosenWords = [];
    for (int attempt = 0; attempt < 100; attempt++) {
      List<WordData> temp = List.from(WORD_BANK);
      temp.shuffle();
      List<WordData> candidates = temp.take(WORD_COUNT).toList();
      int longCount = candidates.where((w) => w.word.length > 6).length;
      if (longCount <= 2) {
        chosenWords = candidates;
        break;
      }
    }

    // Fallback if not found (unlikely)
    if (chosenWords.isEmpty || chosenWords.length < WORD_COUNT) {
      chosenWords = pickWordsWithLimit();
    }

    definitionsMap = {};
    for (var word in chosenWords) {
      definitionsMap[word.word] = word.def;
    }

    // Initialize empty grid
    grid = List.generate(
      GRID_SIZE,
      (r) => List.generate(
        GRID_SIZE,
        (c) => Cell(letter: '', found: false),
      ),
    );

    List<List<int>> directions = [
      [0, 1], [0, -1], [1, 0], [-1, 0], [1, 1], [1, -1], [-1, 1], [-1, -1]
    ];

    // Place words on the grid
    for (var wordData in chosenWords) {
      if (!placeWordRandomly(wordData.word, directions, 500)) {
        simpleHorizontalPlacement(wordData.word);
      }
    }

    // Fill empty cells with random letters
    for (int r = 0; r < GRID_SIZE; r++) {
      for (int c = 0; c < GRID_SIZE; c++) {
        if (grid[r][c].letter.isEmpty) {
          grid[r][c].letter = randomLetter();
        }
      }
    }

    startCell = null;
    setState(() {
      isGridBlurred = false;
    });
  }

  List<WordData> pickWordsWithLimit() {
    List<WordData> words = List.from(WORD_BANK);
    words.shuffle();
    List<WordData> result = [];
    for (var word in words) {
      int longCount = result.where((w) => w.word.length > 6).length;
      if (word.word.length <= 6 || longCount < 2) {
        result.add(word);
        if (result.length == WORD_COUNT) break;
      }
    }
    return result;
  }

  bool placeWordRandomly(String word, List<List<int>> directions, int maxAttempts) {
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      List<int> dir = directions[Random().nextInt(directions.length)];
      int startR = Random().nextInt(GRID_SIZE);
      int startC = Random().nextInt(GRID_SIZE);
      if (canPlaceWord(word, startR, startC, dir[0], dir[1])) {
        placeWord(word, startR, startC, dir[0], dir[1]);
        return true;
      }
    }
    return false;
  }

  void simpleHorizontalPlacement(String word) {
    for (int r = 0; r < GRID_SIZE; r++) {
      for (int startC = 0; startC <= GRID_SIZE - word.length; startC++) {
        if (canPlaceWord(word, r, startC, 0, 1)) {
          placeWord(word, r, startC, 0, 1);
          return;
        }
      }
    }
  }

  bool canPlaceWord(String word, int r, int c, int dr, int dc) {
    for (int i = 0; i < word.length; i++) {
      int rr = r + dr * i;
      int cc = c + dc * i;
      if (rr < 0 || rr >= GRID_SIZE || cc < 0 || cc >= GRID_SIZE) return false;
      String letter = grid[rr][cc].letter;
      String needed = word[i];
      if (letter.isNotEmpty && letter != needed) return false;
    }
    return true;
  }

  void placeWord(String word, int r, int c, int dr, int dc) {
    for (int i = 0; i < word.length; i++) {
      int rr = r + dr * i;
      int cc = c + dc * i;
      grid[rr][cc].letter = word[i];
    }
  }

  void processLine(List<List<int>>? line) {
    if (line == null) {
      clearSelections();
      return;
    }

    String wordFormed = line.map((pos) => grid[pos[0]][pos[1]].letter).join('');
    String reversed = wordFormed.split('').reversed.join('');
    
    String? foundWord;
    int foundIndex = -1;
    for (int i = 0; i < chosenWords.length; i++) {
      if (chosenWords[i].found) continue; 
      
      if (chosenWords[i].word == wordFormed || chosenWords[i].word == reversed) {
        foundWord = chosenWords[i].word;
        foundIndex = i;
        break;
      }
    }

    if (foundWord != null && foundIndex != -1) {
      for (var pos in line) {
        grid[pos[0]][pos[1]].found = true;
        grid[pos[0]][pos[1]].selected = false;
      }
      
      chosenWords[foundIndex].found = true;
      foundCount++;
      
      showDefinition(foundWord);
      
      if (foundCount == chosenWords.length) {
        stopTimer();
        recordAndShowCompletion(timer);
      }
    } else {
      clearSelections(); 
    }
    
    startCell = null;
    endCell = null;
    currentDragLine = [];
  }

  void cellTapped(int r, int c) {
    if (!isGameActive) return;

    setState(() {
      if (startCell == null) {
        startCell = grid[r][c];
        startCell!.selected = true;
        startCell!.row = r;
        startCell!.col = c;
      } else {
        int startR = startCell!.row!;
        int startC = startCell!.col!;
        int endR = r;
        int endC = c;

        List<List<int>>? line = getLineOfCells(startR, startC, endR, endC);
        
        if (line != null) {
          for (var pos in line) {
            grid[pos[0]][pos[1]].selected = true;
          }
        }
        
        processLine(line);
      }
    });
  }

  void clearSelections() {
    for (int r = 0; r < GRID_SIZE; r++) {
      for (int c = 0; c < GRID_SIZE; c++) {
        grid[r][c].selected = false;
      }
    }
  }

  List<List<int>>? getLineOfCells(int r1, int c1, int r2, int c2) {
    int dr = r2 - r1;
    int dc = c2 - c1;
    
    if (dr != 0 && dc != 0 && dr.abs() != dc.abs()) return null;

    int length = max(dr.abs(), dc.abs()) + 1;
    int stepR = dr == 0 ? 0 : (dr > 0 ? 1 : -1);
    int stepC = dc == 0 ? 0 : (dc > 0 ? 1 : -1);
    
    List<List<int>> cells = [];
    int rr = r1, cc = c1;
    
    for (int i = 0; i < length; i++) {
      if (rr < 0 || rr >= GRID_SIZE || cc < 0 || cc >= GRID_SIZE) return null;
      cells.add([rr, cc]);
      rr += stepR;
      cc += stepC;
    }
    
    return cells;
  }

  void showDefinition(String word) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(word),
        content: Text(definitionsMap[word] ?? ''),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchLeaderboard() async {
     setState(() {
      _leaderboardLoading = true;
      _leaderboardError = null;
    });

    try {
      final firestore = FirebaseFirestore.instance;
      final query = firestore
          .collection('users')
          .where('highScoreWordSearch', isGreaterThan: 0)
          .orderBy('highScoreWordSearch', descending: false)
          .limit(10);

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
      print("Error fetching Word Search leaderboard: $e");
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
    final accentColor = themeProvider.accentColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Text(
          'Word Search',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Time: $timer s',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (bestTimes.isNotEmpty)
                      Text(
                        'Your Best: ${bestTimes[0]} s',
                        style: TextStyle(
                          color: textColor, 
                          fontSize: 18, 
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Find the words listed below. Tap the first and last letter OR drag across the word.',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!isGameActive) 
                    ElevatedButton(
                      onPressed: startGame,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                      ),
                      child: const Text('Start'),
                    )
                  else
                    ElevatedButton(
                      onPressed: restartGame,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                      ),
                      child: const Text('Restart'),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              
              Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey.shade700,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: ImageFiltered(
                        imageFilter: isGridBlurred
                            ? ImageFilter.blur(sigmaX: 5, sigmaY: 5)
                            : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            double cellWidth = constraints.maxWidth / GRID_SIZE;
                            double cellHeight = constraints.maxHeight / GRID_SIZE;

                            return GestureDetector(
                              onPanStart: (details) {
                                int startCol = (details.localPosition.dx / cellWidth).floor().clamp(0, GRID_SIZE - 1);
                                int startRow = (details.localPosition.dy / cellHeight).floor().clamp(0, GRID_SIZE - 1);
                                _onPanStart(details, startRow, startCol);
                              },
                              onPanUpdate: _onPanUpdate,
                              onPanEnd: _onPanEnd,
                              child: GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: GRID_SIZE,
                                  childAspectRatio: 1.0,
                                ),
                                itemCount: GRID_SIZE * GRID_SIZE,
                                itemBuilder: (context, index) {
                                  int row = index ~/ GRID_SIZE;
                                  int col = index % GRID_SIZE;
                                  Cell cell = grid[row][col];
                                  
                                  return GestureDetector(
                                    onTap: () => cellTapped(row, col),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.grey.shade500,
                                          width: 1,
                                        ),
                                        color: cell.found
                                            ? Colors.green
                                            : cell.selected
                                                ? Colors.blue.shade300
                                                : surfaceColor,
                                      ),
                                      child: Center(
                                        child: Text(
                                          cell.letter,
                                          style: TextStyle(
                                            color: cell.found || cell.selected
                                                ? Colors.black
                                                : textColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          }
                        ),
                      ),
                    ),
                  ),
                  
                  if (isGameActive) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Word Bank',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 16,
                            runSpacing: 8,
                            children: chosenWords.map((word) => Text(
                              word.word,
                              style: TextStyle(
                                color: textColor,
                                decoration: word.found 
                                    ? TextDecoration.lineThrough
                                    : null,
                                fontWeight: word.found
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                              ),
                            )).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),
              
              if (!isGameActive) _buildGlobalLeaderboard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlobalLeaderboard() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final textColor = Theme.of(context).colorScheme.onBackground;
    final secondaryTextColor = themeProvider.secondaryTextColor;
    final surfaceColor = Theme.of(context).colorScheme.surface;

    return Column(
      children: [
         Text(
          'Word Search Leaderboard',
          style: TextStyle(
            color: textColor,
            fontSize: 20,
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
              if (_leaderboardLoading)
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(),
                ),
                
              if (!_leaderboardLoading && _leaderboardError != null)
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    _leaderboardError!,
                    style: TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
                
              if (!_leaderboardLoading && _leaderboardError == null && _leaderboardData.isEmpty)
                 Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    'No scores recorded yet! Be the first!',
                    style: TextStyle(color: secondaryTextColor, fontSize: 16),
                     textAlign: TextAlign.center,
                  ),
                ),
              
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
                    final score = user.highScoreWordSearch;
                                      
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
                        score != null ? '$score s' : '-', // Display time in seconds
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

  void _onPanStart(DragStartDetails details, int r, int c) {
    if (!isGameActive || startCell != null) return;
    
    setState(() {
      clearSelections();
      startCell = grid[r][c];
      startCell!.selected = true;
      startCell!.row = r;
      startCell!.col = c;
      currentDragLine = [[r, c]];
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (startCell == null || !isGameActive) return;

    RenderBox? gridBox = context.findRenderObject() as RenderBox?;
    if (gridBox == null) return;

    Offset localPosition = gridBox.globalToLocal(details.globalPosition);

    double cellWidth = gridBox.size.width / GRID_SIZE;
    double cellHeight = gridBox.size.height / GRID_SIZE;

    int currentCol = (localPosition.dx / cellWidth).floor();
    int currentRow = (localPosition.dy / cellHeight).floor();

    currentRow = currentRow.clamp(0, GRID_SIZE - 1);
    currentCol = currentCol.clamp(0, GRID_SIZE - 1);

    if (endCell != null && endCell!.row == currentRow && endCell!.col == currentCol) {
      return;
    }

    setState(() {
      endCell = grid[currentRow][currentCol];
      endCell!.row = currentRow;
      endCell!.col = currentCol;

      currentDragLine = getLineOfCells(startCell!.row!, startCell!.col!, currentRow, currentCol) ?? [];

      clearSelections();
      for (var pos in currentDragLine) {
        grid[pos[0]][pos[1]].selected = true;
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (startCell == null || endCell == null || !isGameActive) return;
    
    setState(() {
      processLine(currentDragLine);
    });
  }
}

class WordData {
  final String word;
  final String def;
  bool found;

  WordData({
    required this.word,
    required this.def,
    this.found = false,
  });
}

class Cell {
  String letter;
  bool found;
  bool selected;
  int? row;
  int? col;

  Cell({
    required this.letter,
    this.found = false,
    this.selected = false,
    this.row,
    this.col,
  });
} 