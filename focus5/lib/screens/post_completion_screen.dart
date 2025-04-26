import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math'; // For Random
import 'package:focus5/models/content_models.dart';
import 'package:focus5/controllers/post_completion_controller.dart';
import 'package:focus5/widgets/multiple_choice_screen.dart';
import 'package:focus5/widgets/scale_screen.dart';
import 'package:focus5/widgets/fill_in_blank_screen.dart';
import 'package:focus5/providers/user_provider.dart';
import 'package:focus5/utils/level_utils.dart';
import 'dart:async';
import 'package:focus5/services/user_level_service.dart';
import 'package:focus5/screens/level_up_screen.dart';
import '../../main.dart'; // <-- Import navigatorKey

class PostCompletionScreen extends StatefulWidget {
  final dynamic module;
  final int xpGained;
  
  const PostCompletionScreen({
    Key? key,
    required this.module,
    required this.xpGained,
  }) : super(key: key);
  
  @override
  _PostCompletionScreenState createState() => _PostCompletionScreenState();
}

class _PostCompletionScreenState extends State<PostCompletionScreen> with TickerProviderStateMixin {
  late PostCompletionController controller;
  bool _isCompleted = false;

  // XP animation controller
  late AnimationController _xpAnimationController;
  late Animation<double> _xpBarAnimation = const AlwaysStoppedAnimation<double>(0.0);
  late Animation<int> _xpTextAnimation = const AlwaysStoppedAnimation<int>(0);
  int _currentLevel = 1;
  int _targetLevel = 1;

  @override
  void initState() {
    super.initState();
    controller = PostCompletionController(widget.module);
    controller.addListener(_checkCompletion);

    _xpAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  Future<void> _checkCompletion() async {
    if (!controller.hasNextScreen && !_isCompleted) {
      if (controller.userResponses.containsKey(controller.currentScreenType)) {
        if (!mounted) return;
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final user = userProvider.user;
        final userId = user?.id;

        if (userId == null) {
          debugPrint('[PostCompletionScreen] User ID is null, cannot proceed with completion.');
          return;
        }

        final initialXp = user?.xp ?? 0;
        final initialLevel = UserLevelService.getUserLevel(initialXp);
        final initialProgress = LevelUtils.calculateXpProgress(initialXp);
        final int xpEarned = widget.xpGained;
        
        // Safely get title based on module type
        String moduleTitle = "Module"; // Default title
        if (widget.module is DailyAudio) {
          moduleTitle = (widget.module as DailyAudio).title;
        } else if (widget.module is Lesson) {
          moduleTitle = (widget.module as Lesson).title;
        } // Add more types if needed

        await userProvider.addXp(
          userId,
          xpEarned,
          "Reflection: $moduleTitle", // Use safe title
        );
        
        await Future.delayed(const Duration(milliseconds: 200)); 
        if (!mounted) return;

        final finalUser = Provider.of<UserProvider>(context, listen: false).user;
        final finalXp = finalUser?.xp ?? (initialXp + xpEarned);
        final finalLevel = UserLevelService.getUserLevel(finalXp);
        final finalProgress = UserLevelService.getLevelProgress(finalXp);

        if (finalLevel > initialLevel) {
          debugPrint("[PostCompletionScreen] Level Up detected ($initialLevel -> $finalLevel)! Navigating to LevelUpScreen.");
          navigatorKey.currentState?.pushReplacement(
             MaterialPageRoute(
               builder: (context) => LevelUpScreen(newLevel: finalLevel),
             ),
          );
          return;
        }

        setState(() {
          _isCompleted = true;
        });

        await _setupAndTriggerXpAnimation(
            initialXp: initialXp, 
            targetXp: finalXp,
            initialLevel: initialLevel, 
            targetLevel: finalLevel,
            initialProgress: initialProgress, 
            targetProgress: finalProgress,
            xpValueToAnimate: xpEarned
        );
      }
    }
  }

  Future<void> _setupAndTriggerXpAnimation({
    required int initialXp,
    required int targetXp,
    required int initialLevel,
    required int targetLevel,
    required double initialProgress,
    required double targetProgress,
    required int xpValueToAnimate,
  }) async {
    if (!mounted) return;

    _currentLevel = initialLevel;
    _targetLevel = targetLevel;

    _xpBarAnimation = Tween<double>(begin: initialProgress, end: targetProgress)
        .animate(CurvedAnimation(parent: _xpAnimationController, curve: Curves.easeInOut));

    _xpTextAnimation = IntTween(begin: 0, end: xpValueToAnimate)
        .animate(CurvedAnimation(parent: _xpAnimationController, curve: Curves.easeIn));

    _xpAnimationController.forward(from: 0.0); 
  }

  @override
  void dispose() {
    _xpAnimationController.dispose();
    controller.removeListener(_checkCompletion);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return WillPopScope(
      onWillPop: () async {
        if (_isCompleted) {
          Navigator.of(context).pop();
          return true;
        }
        return false;
      },
      child: ChangeNotifierProvider.value(
        value: controller,
        child: Scaffold(
          backgroundColor: Colors.grey[900],
          body: Stack(
            children: [
              // Main Content SafeArea
              SafeArea(
                child: Consumer<PostCompletionController>(
                  builder: (context, controller, _) {
                    // Show completion screen if isCompleted is true
                    if (_isCompleted) {
                      return _buildCompletionScreen(context, _currentLevel, _targetLevel);
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
                                  IconButton(
                                    icon: Icon(Icons.arrow_back, color: Colors.grey[700]),
                                    onPressed: null,
                                  ),
                                  Expanded(
                                    child: Text(
                                      !_isCompleted 
                                        ? "Question ${controller.currentScreenIndex + 1} of ${controller.totalScreens}"
                                        : "Reflection Complete",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white, 
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.close, color: Colors.grey[700]),
                                    onPressed: null,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: controller.progressPercentage,
                                backgroundColor: Colors.white.withOpacity(0.3),
                                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                                minHeight: 6,
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
    if (_isCompleted) {
      return _buildCompletionScreen(context, _currentLevel, _targetLevel);
    }

    switch (controller.currentScreenType) {
      case 'multiple_choice':
        return MultipleChoiceScreen(controller: controller);
      case 'fill_in_blank':
        return FillInBlankScreen(controller: controller);
      case 'scale':
        return ScaleScreen(controller: controller);
      default:
        return Center(child: Text("Unknown screen type", style: TextStyle(color: Colors.white)));
    }
  }
  
  Widget _buildCompletionScreen(BuildContext context, int displayCurrentLevel, int displayTargetLevel) {
    final primaryColor = Theme.of(context).primaryColor;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;
    final currentLevelForDisplay = UserLevelService.getUserLevel(user?.xp ?? 0);
    final xpForNextLevel = UserLevelService.getXpForNextLevel(user?.xp ?? 0);
    final currentLevelXpBase = UserLevelService.levelThresholds[currentLevelForDisplay] ?? 0;
    final nextLevelXp = UserLevelService.levelThresholds[currentLevelForDisplay + 1] ?? xpForNextLevel + currentLevelXpBase;
    final currentXpInLevel = (user?.xp ?? 0) - currentLevelXpBase;
    final totalXpInLevel = nextLevelXp - currentLevelXpBase;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline, color: primaryColor, size: 60),
              SizedBox(height: 15),
              Text(
                "Reflection Complete!",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 25),
              
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
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Level $currentLevelForDisplay", style: TextStyle(color: Colors.white70, fontSize: 14)),
                  Text("Level ${currentLevelForDisplay + 1}", style: TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
              SizedBox(height: 8),
              AnimatedBuilder(
                animation: _xpBarAnimation,
                builder: (context, child) {
                  return LinearProgressIndicator(
                    value: _xpBarAnimation.value,
                    minHeight: 12,
                    backgroundColor: Colors.grey[700],
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    borderRadius: BorderRadius.circular(6),
                  );
                },
              ),
              SizedBox(height: 8),
              Text(
                "${currentXpInLevel} / ${totalXpInLevel} XP", 
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false),
                child: Text("Continue"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
} 