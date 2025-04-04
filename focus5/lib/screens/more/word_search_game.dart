import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/theme_provider.dart';

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
  List<int> bestTimes = [];

  @override
  void initState() {
    super.initState();
    loadTimes();
    generateRandomLetterGrid();
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
          bestTimes = List<int>.from(decodedTimes);
        });
      } catch (e) {
        setState(() {
          bestTimes = [];
        });
      }
    }
  }

  Future<void> recordTime(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    bestTimes.add(seconds);
    bestTimes.sort();
    // Keep only the best 10 times
    if (bestTimes.length > 10) {
      bestTimes = bestTimes.sublist(0, 10);
    }
    await prefs.setString('wordSearchTimes', jsonEncode(bestTimes));
    
    // Show completion dialog with best times
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Congratulations!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('You completed the word search in $timer seconds!'),
            const SizedBox(height: 16),
            const Text('Your Best Times:'),
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
          // Mark cells as selected temporarily
          for (var pos in line) {
            grid[pos[0]][pos[1]].selected = true;
          }

          // Collect letters to form a word
          String wordFormed = line.map((pos) => grid[pos[0]][pos[1]].letter).join('');
          String reversed = wordFormed.split('').reversed.join('');
          
          // Check if the word is in our list
          String? foundWord;
          for (var word in chosenWords) {
            if (word.word == wordFormed || word.word == reversed) {
              foundWord = word.word;
              word.found = true;
              break;
            }
          }

          if (foundWord != null) {
            // Mark cells as found
            for (var pos in line) {
              grid[pos[0]][pos[1]].selected = false;
              grid[pos[0]][pos[1]].found = true;
            }
            
            foundCount++;
            
            // Show definition
            showDefinition(foundWord);
            
            // Check for game completion
            if (foundCount == chosenWords.length) {
              stopTimer();
              recordTime(timer);
            }
          } else {
            // Clear selections if word not found
            clearSelections();
          }
        } else {
          clearSelections();
        }
        
        startCell = null;
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
    
    // Check if it's a straight line (horizontal, vertical, or diagonal)
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
              // Game info
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
                        'Best: ${bestTimes[0]} s',
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
              
              // Instructions
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Tap the first letter of the word you want to find, then tap the last letter of that word. No dragging needed!',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),

              // Game buttons
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
              
              // Game grid and word bank
              Column(
                children: [
                  // Grid - full width
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
                                          ? Colors.grey.shade700
                                          : surfaceColor,
                                ),
                                child: Center(
                                  child: Text(
                                    cell.letter,
                                    style: TextStyle(
                                      color: cell.found
                                          ? Colors.black
                                          : cell.selected
                                              ? Colors.white
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
                      ),
                    ),
                  ),
                  
                  // Word bank - below grid
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
              
              // Your times section
              if (bestTimes.isNotEmpty && !isGridBlurred) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Best Times',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Table(
                        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                        columnWidths: const {
                          0: IntrinsicColumnWidth(),
                          1: IntrinsicColumnWidth(),
                        },
                        children: [
                          TableRow(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey.shade700,
                                  width: 1,
                                ),
                              ),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  'Rank',
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  'Time (s)',
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          ...bestTimes.asMap().entries.take(5).map((entry) {
                            return TableRow(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    '${entry.key + 1}',
                                    style: TextStyle(
                                      color: textColor,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    '${entry.value}',
                                    style: TextStyle(
                                      color: textColor,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
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