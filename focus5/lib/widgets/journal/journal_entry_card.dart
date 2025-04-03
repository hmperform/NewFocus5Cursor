import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/journal_model.dart';

class JournalEntryCard extends StatelessWidget {
  final JournalEntry entry;
  final VoidCallback onTap;
  final String? highlightText;
  
  const JournalEntryCard({
    Key? key,
    required this.entry,
    required this.onTap,
    this.highlightText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Prepare content preview with trimming
    String contentPreview = entry.content;
    if (contentPreview.length > 100) {
      contentPreview = contentPreview.substring(0, 100) + '...';
    }
    
    // Highlight search text if provided
    Widget contentWidget;
    if (highlightText != null && highlightText!.isNotEmpty) {
      contentWidget = _buildHighlightedText(
        contentPreview, 
        highlightText!,
        const TextStyle(
          color: Colors.white70,
          fontSize: 14,
        ),
        const TextStyle(
          color: Color(0xFFB4FF00),
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      );
    } else {
      contentWidget = Text(
        contentPreview,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: const Color(0xFF1E1E1E),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date circle
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('d').format(entry.date),
                          style: const TextStyle(
                            color: Color(0xFFB4FF00),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          DateFormat('MMM').format(entry.date),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Entry content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              DateFormat('EEEE').format(entry.date),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              entry.mood.emoji,
                              style: const TextStyle(
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entry.prompt,
                          style: const TextStyle(
                            color: Color(0xFFB4FF00),
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        contentWidget,
                      ],
                    ),
                  ),
                ],
              ),
              if (entry.tags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: entry.tags.map((tag) => _buildTagChip(tag)).toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTagChip(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '#$tag',
        style: const TextStyle(
          color: Color(0xFFB4FF00),
          fontSize: 12,
        ),
      ),
    );
  }
  
  Widget _buildHighlightedText(
    String text,
    String highlight,
    TextStyle defaultStyle,
    TextStyle highlightStyle,
  ) {
    if (highlight.isEmpty) {
      return Text(
        text,
        style: defaultStyle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }
    
    final lowerText = text.toLowerCase();
    final lowerHighlight = highlight.toLowerCase();
    
    if (!lowerText.contains(lowerHighlight)) {
      return Text(
        text,
        style: defaultStyle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }
    
    final spans = <TextSpan>[];
    int start = 0;
    int indexOfHighlight;
    
    while (true) {
      indexOfHighlight = lowerText.indexOf(lowerHighlight, start);
      if (indexOfHighlight < 0) break;
      
      if (indexOfHighlight > start) {
        spans.add(TextSpan(
          text: text.substring(start, indexOfHighlight),
          style: defaultStyle,
        ));
      }
      
      spans.add(TextSpan(
        text: text.substring(indexOfHighlight, indexOfHighlight + highlight.length),
        style: highlightStyle,
      ));
      
      start = indexOfHighlight + highlight.length;
    }
    
    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: defaultStyle,
      ));
    }
    
    return RichText(
      text: TextSpan(
        children: spans,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
} 