import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math'; // For Random
import 'package:focus5/models/content_models.dart';
import 'package:focus5/controllers/post_completion_controller.dart';
import 'package:focus5/widgets/multiple_choice_screen.dart';
import 'package:focus5/widgets/scale_screen.dart';
import 'package:focus5/widgets/fill_in_blank_screen.dart';
import 'package:focus5/providers/user_provider.dart';
import 'package:focus5/utils/level_utils.dart'; // Re-enabled import
import 'dart:async';
import 'package:focus5/widgets/streak_celebration_popup.dart';

class PostCompletionScreen extends StatefulWidget {
  final DailyAudio module;
  
  const PostCompletionScreen({Key? key, required this.module}) : super(key: key);
  
  @override
  _PostCompletionScreenState createState() => _PostCompletionScreenState();
}

// Add TickerProviderStateMixin for AnimationController
class _PostCompletionScreenState extends State<PostCompletionScreen> with TickerProviderStateMixin {
  late PostCompletionController controller;
  late AnimationController _gradientController;
  List<Color> _gradientColors = [];
  List<Alignment> _gradientAlignments = [];
  // Add Tween animations for alignments
  late List<Animation<Alignment>> _alignmentAnimations;
  late List<Animation<Color?>> _colorAnimations; // Animate colors too

  final int numBlobs = 4; // Define numBlobs as a class member
  final Random _random = Random();
  bool _isCompleted = false; // State to track completion

  // Add XP animation controller
  late AnimationController _xpAnimationController;
  late Animation<double> _xpBarAnimation = const AlwaysStoppedAnimation<double>(0.0); // Default
  late Animation<int> _xpTextAnimation = const AlwaysStoppedAnimation<int>(0); // Default
  int xpGained = 50; // TODO: Get this dynamically from module/config
  int _currentLevel = 1;
  int _targetLevel = 1;

  bool _hasShownStreakCelebration = false; // Added to track streak celebration

  @override
  void initState() {
    super.initState();
    controller = PostCompletionController(widget.module);
    controller.addListener(_checkCompletion); // Listen for completion

    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15), // Slightly longer duration
    )..repeat(reverse: true); // Repeat and reverse for smoother transitions

    // Listener to regenerate gradients at the start of each animation cycle
    _gradientController.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        _generateGradientsAndAnimations();
      }
    });

    // Initialize XP controller
    _xpAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // DO NOT Setup XP animation here anymore - wait for completion trigger
    // _setupXpAnimation();
  }

  // Renamed and accepts initial state parameters
  Future<void> _setupAndTriggerXpAnimation(int initialXp, int initialLevel, double initialProgress) async {
    if (!mounted) return;

    // Target state calculation
    int targetXp = initialXp + xpGained;
    _targetLevel = LevelUtils.calculateLevel(targetXp); // Use LevelUtils
    double targetXpProgress = LevelUtils.calculateXpProgress(targetXp); // Use LevelUtils

    // Current state (for display) is the initial state passed in
    _currentLevel = initialLevel;

    // Setup Animations
    _xpBarAnimation = Tween<double>(begin: initialProgress, end: targetXpProgress)
        .animate(CurvedAnimation(parent: _xpAnimationController, curve: Curves.easeInOut));

    _xpTextAnimation = IntTween(begin: 0, end: xpGained)
        .animate(CurvedAnimation(parent: _xpAnimationController, curve: Curves.easeIn));

    // Start the animation now that it's set up
    if (_xpAnimationController.status != AnimationStatus.forward &&
        _xpAnimationController.status != AnimationStatus.completed) {
       _xpAnimationController.forward(from: 0.0);
    } else {
       _xpAnimationController.forward(from: 0.0); // Restart if somehow already running
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Generate initial gradients and animations here
    if (_gradientColors.isEmpty) {
      _generateGradientsAndAnimations();
    }
    // Remove _setupXpAnimation call from here too
  }

  // Generate random metallic grey gradient colors and set up animations
  void _generateGradientsAndAnimations() {
    if (!mounted) return;
    // Use grey tones and maybe a hint of primary color for metallic feel
    // final primary = Theme.of(context).primaryColor; // Keep if you want a hint of primary
    int numBlobs = 4;

    List<Color> baseGreys = [
      Colors.grey[850]!, Colors.grey[800]!, Colors.grey[700]!, Colors.grey[600]!
    ];

    List<Color> nextColors = List.generate(numBlobs, (i) {
      // Blend base grey with another slightly lighter/darker grey or subtle color
      Color base = baseGreys[_random.nextInt(baseGreys.length)];
      Color blend = baseGreys[_random.nextInt(baseGreys.length)].withOpacity(0.5);
      // Optional: Add a slight hint of primary color
      // blend = Color.lerp(blend, primary.withOpacity(0.1), 0.2)!;
      return Color.lerp(base, blend, _random.nextDouble() * 0.6)!.withOpacity(0.55); // Adjust opacity
    });

    List<Alignment> nextAlignments = List.generate(
      numBlobs,
      (_) => Alignment(
        _random.nextDouble() * 3 - 1.5, // Wider range for movement
        _random.nextDouble() * 3 - 1.5,
      ),
    );

    // If first run, initialize directly
    if (_gradientColors.isEmpty) {
      _gradientColors = nextColors;
      _gradientAlignments = nextAlignments;
    }

    // Create animations
    _colorAnimations = List.generate(numBlobs, (i) {
      return ColorTween(
        begin: _gradientColors[i],
        end: nextColors[i],
      ).animate(_gradientController);
    });
    _alignmentAnimations = List.generate(numBlobs, (i) {
      return AlignmentTween(
        begin: _gradientAlignments[i],
        end: nextAlignments[i],
      ).animate(
        CurvedAnimation(
          parent: _gradientController,
          curve: Curves.easeInOut, // Smoother curve for alignment change
        ),
      );
    });

    // Update current colors/alignments for the next animation cycle
    _gradientColors = nextColors;
    _gradientAlignments = nextAlignments;

    // No need for setState here as AnimatedBuilder rebuilds
  }
  
  // Listener to check if the last screen is reached - now async
  Future<void> _checkCompletion() async { // Make async
    // Check if it's the final screen AND we haven't already marked as completed
    if (!controller.hasNextScreen && !_isCompleted) {
      // Ensure there's a response for the final screen type
      if (controller.userResponses.containsKey(controller.currentScreenType)) {

        // Fetch user provider and current user state BEFORE awarding XP
        if (!mounted) return; // Check mount status again
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final user = userProvider.user;
        final userId = user?.id;

        if (user == null || userId == null) {
          print("Error: Cannot award XP or setup animation, user data not available.");
          // Optionally show an error message to the user
          setState(() {
             _isCompleted = true; // Still go to completion screen, but without XP animation
             // Set default/error state animations
             _xpBarAnimation = const AlwaysStoppedAnimation<double>(0.0);
             _xpTextAnimation = const AlwaysStoppedAnimation<int>(0);
             _currentLevel = 1; // Default or fetch if possible
             _targetLevel = 1;
          });
          return; // Stop processing
        }

        // *** CALCULATE initial state *before* addXp ***
        int initialXp = user.xp;
        int initialLevel = LevelUtils.calculateLevel(initialXp); // Calculate based on initial XP
        double initialProgress = LevelUtils.calculateXpProgress(initialXp); // Calculate based on initial XP

        try {
          // Award XP - use await to ensure it completes (or fails) before proceeding
          await userProvider.addXp(userId, xpGained, "Reflection: ${widget.module.title}");

          // Mark as completed & Set up and trigger animation *after* XP is awarded
          if (!mounted) return;
          setState(() {
             _isCompleted = true;
             // Call the setup/trigger function with the PRE-CALCULATED initial state
             _setupAndTriggerXpAnimation(initialXp, initialLevel, initialProgress);
          });

        } catch (e) {
           print("Error awarding XP: $e");
           // Handle error - maybe still go to completion screen but show an error?
           if (!mounted) return;
           setState(() {
              _isCompleted = true; // Go to completion screen
              // Set error state animations using PRE-CALCULATED initial state
              _xpBarAnimation = AlwaysStoppedAnimation<double>(initialProgress); // Show calculated initial progress
              _xpTextAnimation = const AlwaysStoppedAnimation<int>(0); // Show 0 XP gained
              _currentLevel = initialLevel; // Show calculated initial level
              _targetLevel = initialLevel; // Show calculated initial level as target
           });
        }
      }
    }
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _xpAnimationController.dispose(); // Dispose XP controller
    controller.removeListener(_checkCompletion);
    controller.dispose(); // Dispose the controller itself if it's a ChangeNotifier
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    // Prevent back navigation until completed
    return WillPopScope(
      onWillPop: () async => _isCompleted, // Only allow pop if completed
      child: ChangeNotifierProvider.value(
        value: controller,
        child: Scaffold(
          backgroundColor: Colors.black, // Ensure scaffold bg is black
          body: Stack(
            children: [
              // Animated Gradient Background (using updated _generateGradients)
              AnimatedBuilder(
                animation: _gradientController,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 2.0,
                        colors: [
                          ..._colorAnimations.map((anim) => anim.value ?? Colors.transparent).toList(),
                          Colors.black,
                        ],
                        stops: List.generate(numBlobs + 1, (i) => i / numBlobs),
                        tileMode: TileMode.clamp,
                        transform: GradientRotation(_gradientController.value * 2 * pi),
                      ),
                    ),
                  );
                },
              ),
              // Main Content SafeArea
              SafeArea(
                child: Consumer<PostCompletionController>(
                  builder: (context, controller, _) {
                    // Show completion screen if isCompleted is true
                    if (_isCompleted) {
                      // Pass the calculated current level (before XP gain) for both initially
                      return _buildCompletionScreen(context, _currentLevel, _currentLevel);
                    }
                    
                    // Otherwise show the current question screen
                    return Column(
                      children: [
                        // Top Nav Area
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  // Back button - disabled until completion (handled by WillPopScope)
                                  IconButton(
                                    icon: Icon(Icons.arrow_back, color: _isCompleted ? Colors.white : Colors.grey[700]), // Grey out when disabled
                                    onPressed: _isCompleted ? () => Navigator.of(context).pop() : null, // Only allow pop if completed
                                  ),
                                  Expanded(
                                    child: Text(
                                      !_isCompleted 
                                        ? "Question ${controller.currentScreenIndex + 1} of ${controller.totalScreens}"
                                        : "Reflection Complete", // Show different title when done
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white, 
                                      ),
                                    ),
                                  ),
                                  // Close button - disabled until completion
                                  IconButton(
                                    icon: Icon(Icons.close, color: _isCompleted ? Colors.white : Colors.grey[700]), // Grey out when disabled
                                    onPressed: _isCompleted ? () => Navigator.of(context).pop() : null, // Only allow pop if completed
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: controller.progressPercentage,
                                backgroundColor: Colors.white.withOpacity(0.3), // Semi-transparent white
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  primaryColor, // Use primary color (neon)
                                ),
                                minHeight: 6, // Slightly thicker
                              ),
                            ],
                          ),
                        ),

                        // Screen content based on type
                        Expanded(
                          child: _buildCurrentScreen(controller),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildCurrentScreen(PostCompletionController controller) {
    // Add a check for completion state if needed, though handled by parent builder now
     if (_isCompleted) {
        return _buildCompletionScreen(context, _currentLevel, _currentLevel); // Should not be reached if logic is correct
     }

    switch (controller.currentScreenType) {
      case 'multiple_choice':
        return MultipleChoiceScreen(controller: controller);
      case 'fill_in_blank':
        // TODO: Apply similar glassmorphic styling to FillInBlankScreen if needed
        return FillInBlankScreen(controller: controller);
      case 'scale':
        return ScaleScreen(controller: controller);
      default:
        return Center(child: Text("Unknown screen type", style: TextStyle(color: Colors.white)));
    }
  }
  
  // Widget for the completion screen - Accepts levels as parameters
  Widget _buildCompletionScreen(BuildContext context, int displayCurrentLevel, int displayTargetLevel) {
    final primaryColor = Theme.of(context).primaryColor;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    // Schedule the streak celebration to show after a short delay
    if (!_hasShownStreakCelebration && userProvider.user != null) {
      _hasShownStreakCelebration = true; // Set flag to avoid showing multiple times
      
      // Show streak celebration after a short delay so it appears after this completion screen
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted && context.mounted) {
          // Get current streak from user
          final currentStreak = userProvider.user?.streak ?? 0;
          
          // Only show the celebration if streak is at least 1
          if (currentStreak >= 1) {
            debugPrint('PostCompletionScreen: Showing streak celebration for streak of $currentStreak days');
            context.showStreakCelebration(streakCount: currentStreak);
          } else {
            debugPrint('PostCompletionScreen: Not showing streak celebration, streak is $currentStreak');
          }
        }
      });
    }
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, color: primaryColor, size: 60), // Smaller icon
            SizedBox(height: 15),
            Text(
              "Reflection Complete!", // Changed text
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 25),
            
            // Animated XP Gain Text
            AnimatedBuilder(
              animation: _xpTextAnimation,
              builder: (context, child) {
                return Text(
                  "+${_xpTextAnimation.value} XP",
                  style: TextStyle(fontSize: 22, color: primaryColor, fontWeight: FontWeight.bold),
                );
              },
            ),
            SizedBox(height: 15),
            
            // XP Bar Area - Use levels passed as parameters
            Row(
              children: [
                // Use displayCurrentLevel passed to the function
                Text("Lv $displayCurrentLevel", style: TextStyle(color: Colors.white70, fontSize: 14)),
                SizedBox(width: 8),
                Expanded(
                  child: AnimatedBuilder(
                    animation: _xpBarAnimation,
                    builder: (context, child) {
                      return ClipRRect( // Clip the progress bar for rounded corners
                        borderRadius: BorderRadius.circular(4), 
                        child: LinearProgressIndicator(
                          value: _xpBarAnimation.value,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                          minHeight: 8, 
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(width: 8),
                // Display current level + 1 on the right
                Text("Lv ${displayCurrentLevel + 1}", style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
            
            SizedBox(height: 35),
            ElevatedButton(
              // Navigate to home screen route
              onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                backgroundColor: primaryColor,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text("Back to Home", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }
} 