import 'package:flutter/material.dart';
import 'dart:ui'; // Import for ImageFilter
import '../controllers/post_completion_controller.dart';
import '../utils/image_utils.dart';

class FillInBlankScreen extends StatefulWidget {
  final PostCompletionController controller;
  
  const FillInBlankScreen({Key? key, required this.controller}) : super(key: key);
  
  @override
  _FillInBlankScreenState createState() => _FillInBlankScreenState();
}

class _FillInBlankScreenState extends State<FillInBlankScreen> {
  final TextEditingController textController = TextEditingController();
  int minChars = 100;
  final FocusNode _focusNode = FocusNode(); // FocusNode for TextField
  
  @override
  void initState() {
    super.initState();
    final data = widget.controller.module.postCompletionScreens?['fillinblank'];
    minChars = (data?['minimumcharacters'] ?? 100) as int;
    // Request focus when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
       FocusScope.of(context).requestFocus(_focusNode);
    });
  }
  
  @override
  void dispose() {
    textController.dispose();
    _focusNode.dispose(); // Dispose FocusNode
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final data = widget.controller.module.postCompletionScreens?['fillinblank'];
    final prompt = data?['fillinblankquestion'] ?? "Your response";
    final currentLength = textController.text.length;
    final primaryColor = Theme.of(context).primaryColor;
    
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          
          SizedBox(height: 24),
          
          // Text field Container (Glassmorphic)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.4, // Example: 40% of screen height
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8), // Adjusted padding
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryColor.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: TextField(
                        focusNode: _focusNode,
                        controller: textController,
                        maxLines: null,
                        expands: true, // Keep expands true to fill Column
                        keyboardType: TextInputType.multiline,
                        style: TextStyle(color: Colors.white, fontSize: 16),
                        cursorColor: primaryColor,
                        decoration: InputDecoration(
                          hintText: "Type your response here...",
                          hintStyle: TextStyle(color: Colors.white54),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(8.0),
                        ),
                        onChanged: (_) {
                          setState(() {});
                        },
                      ),
                    ),
                    SizedBox(height: 4), // Small space before counter
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        "$currentLength/$minChars",
                        style: TextStyle(
                          fontSize: 12,
                          color: currentLength >= minChars
                              ? primaryColor // Use primary neon color
                              : Colors.white60,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          SizedBox(height: 16), // Spacing before module preview
          
          // Module Preview Section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05), // Subtle background
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: ImageUtils.networkImageWithFallback(
                    imageUrl: widget.controller.module.thumbnail,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(width: 12),
                // Title and Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.controller.module.title,
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        "From module: ${widget.controller.module.description}", // Or another relevant field
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Spacer to push button down
          Spacer(),
          
          SizedBox(height: 16),
          
          // Confirm button - Full Width
          SizedBox(
             width: double.infinity, // Make button full width
             child: ElevatedButton(
              onPressed: currentLength >= minChars
                  ? () {
                      FocusScope.of(context).unfocus(); 
                      widget.controller.saveResponse(textController.text);
                      widget.controller.nextScreen();
                    }
                  : null,
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
                "Confirm",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 