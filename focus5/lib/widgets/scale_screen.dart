import 'package:flutter/material.dart';
import 'dart:ui'; // Import for ImageFilter
import '../controllers/post_completion_controller.dart';

class ScaleScreen extends StatefulWidget {
  final PostCompletionController controller;
  
  const ScaleScreen({Key? key, required this.controller}) : super(key: key);
  
  @override
  _ScaleScreenState createState() => _ScaleScreenState();
}

class _ScaleScreenState extends State<ScaleScreen> {
  int? selectedValue;
  
  @override
  Widget build(BuildContext context) {
    final data = widget.controller.module.postCompletionScreens?['scaledesign'];
    final prompt = data?['scaleprompt'] ?? "Rate on the scale";
    final minLabel = data?['minlabelname'] ?? "Low";
    final maxLabel = data?['maxlabelname'] ?? "High";
    final steps = (data?['steps'] ?? 5) as int;
    final primaryColor = Theme.of(context).primaryColor;
    
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Question Container (Glassmorphic)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryColor.withOpacity(0.3)),
                ),
                child: Text(
                  prompt,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // White text for contrast
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Labels
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Add Emoji for Min Label
                      Column(
                        children: [
                          Text('😩', style: TextStyle(fontSize: 36)), // Example Emoji
                          SizedBox(height: 4),
                          Text(
                            minLabel,
                            style: TextStyle(fontWeight: FontWeight.w500, color: Colors.white70),
                          ),
                        ],
                      ),
                      Text(
                        "or",
                        style: TextStyle(fontWeight: FontWeight.w500, color: Colors.white70),
                      ),
                      // Add Emoji for Max Label
                      Column(
                        children: [
                          Text('🤩', style: TextStyle(fontSize: 36)), // Example Emoji
                          SizedBox(height: 4),
                          Text(
                            maxLabel,
                            style: TextStyle(fontWeight: FontWeight.w500, color: Colors.white70),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 20), // Adjusted spacing
                
                // Scale selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(steps, (index) {
                    final value = index + 1;
                    final isSelected = selectedValue == value;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedValue = value;
                        });
                      },
                      child: ClipRRect( // Clip for filter
                        borderRadius: BorderRadius.circular(20), // Half of width/height
                        child: BackdropFilter( // Glass effect for circles
                          filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? primaryColor.withOpacity(0.5) // Semi-transparent primary when selected
                                  : Colors.white.withOpacity(0.1), // Very transparent white otherwise
                              border: Border.all(
                                color: isSelected
                                    ? primaryColor
                                    : primaryColor.withOpacity(0.3), // Neon border
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? Icon(Icons.check, color: Colors.white) // White check for contrast
                                : null,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                
                SizedBox(height: 10),
                
                // Scale labels
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(steps, (index) {
                    final value = index + 1;
                    final isSelected = selectedValue == value;
                    return SizedBox(
                      width: 40,
                      child: Text(
                        "$value",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected ? Colors.white : Colors.white70, // Highlight selected number
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          
          // Next button
          ElevatedButton(
            onPressed: selectedValue == null
                ? null
                : () {
                    widget.controller.saveResponse(selectedValue.toString());
                    widget.controller.nextScreen();
                  },
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              backgroundColor: primaryColor,
              disabledBackgroundColor: Colors.grey.shade600,
              foregroundColor: Colors.black,
            ),
            child: Text(
              "Next",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
} 