import 'package:flutter/material.dart';
import 'dart:ui'; // Import for ImageFilter
import '../controllers/post_completion_controller.dart';

class MultipleChoiceScreen extends StatefulWidget {
  final PostCompletionController controller;
  
  const MultipleChoiceScreen({Key? key, required this.controller}) : super(key: key);
  
  @override
  _MultipleChoiceScreenState createState() => _MultipleChoiceScreenState();
}

class _MultipleChoiceScreenState extends State<MultipleChoiceScreen> {
  String? selectedOption;
  
  @override
  Widget build(BuildContext context) {
    final data = widget.controller.module.postCompletionScreens?['multiplechoicedesign'];
    final prompt = data?['multiplechoiceprompt'] ?? "Select an option";
    final options = List<String>.from(data?['multiplechoicequestions'] ?? []);
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
                  color: Colors.white.withOpacity(0.1), // Semi-transparent white
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryColor.withOpacity(0.3)), // Neon accent border
                ),
                child: Text(
                  prompt,
                  style: TextStyle(
                    fontSize: 22, // Slightly smaller
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // Changed to white for contrast on dark bg
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          
          SizedBox(height: 24),
          
          // Options List
          Expanded(
            child: ListView.builder(
              itemCount: options.length,
              itemBuilder: (context, index) {
                final option = options[index];
                final isSelected = selectedOption == option;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: ClipRRect( // Clip for backdrop filter
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter( // Apply blur to background behind option
                      filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                      child: Material(
                        color: Colors.transparent, // Make material transparent
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              selectedOption = option;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              // Slightly more opaque white for options
                              color: isSelected ? primaryColor.withOpacity(0.3) : Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? primaryColor // Stronger border when selected
                                    : primaryColor.withOpacity(0.3), // Neon accent border
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    option,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      // White text, stands out better on glassmorphic bg
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                // Radio button style circle
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? primaryColor
                                          : Colors.white.withOpacity(0.5), // Lighter border when not selected
                                    ),
                                    // Fill color when selected
                                    color: isSelected
                                        ? primaryColor
                                        : Colors.transparent,
                                  ),
                                  child: isSelected
                                      ? Icon(
                                          Icons.check,
                                          size: 16,
                                          color: Colors.black, // Check color contrasting with primary
                                        )
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          SizedBox(height: 16),
          
          // Next button (Keep existing style for now)
          ElevatedButton(
            onPressed: selectedOption == null
                ? null
                : () {
                    widget.controller.saveResponse(selectedOption!);
                    // Navigation logic handled in PostCompletionScreen based on controller state
                    widget.controller.nextScreen();
                  },
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              backgroundColor: primaryColor,
              disabledBackgroundColor: Colors.grey.shade600, // Darker disabled color
              foregroundColor: Colors.black, // Text color on button
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