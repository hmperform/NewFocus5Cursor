import 'package:flutter/material.dart';

class JournalTagSelector extends StatefulWidget {
  final List<String> selectedTags;
  final Function(List<String>) onTagsChanged;
  
  const JournalTagSelector({
    Key? key,
    required this.selectedTags,
    required this.onTagsChanged,
  }) : super(key: key);

  @override
  State<JournalTagSelector> createState() => _JournalTagSelectorState();
}

class _JournalTagSelectorState extends State<JournalTagSelector> {
  final TextEditingController _tagController = TextEditingController();
  final FocusNode _tagFocusNode = FocusNode();
  final List<String> _commonTags = [
    'gratitude',
    'mindfulness',
    'goals',
    'challenge',
    'meditation',
    'health',
    'workout',
    'reflection',
    'growth',
    'learning',
    'relationships',
    'work',
    'family',
    'stress',
    'anxiety',
    'happiness',
    'success',
    'failure',
    'inspiration',
    'motivation',
  ];
  
  late List<String> _selectedTags;
  bool _isAddingTag = false;
  
  @override
  void initState() {
    super.initState();
    _selectedTags = List.from(widget.selectedTags);
  }
  
  @override
  void dispose() {
    _tagController.dispose();
    _tagFocusNode.dispose();
    super.dispose();
  }
  
  void _addTag(String tag) {
    if (tag.trim().isEmpty) return;
    
    final processedTag = tag.trim().toLowerCase();
    if (!_selectedTags.contains(processedTag)) {
      setState(() {
        _selectedTags.add(processedTag);
        _isAddingTag = false;
        _tagController.clear();
      });
      widget.onTagsChanged(_selectedTags);
    }
  }
  
  void _removeTag(String tag) {
    setState(() {
      _selectedTags.remove(tag);
    });
    widget.onTagsChanged(_selectedTags);
  }
  
  List<String> _getUnselectedCommonTags() {
    return _commonTags.where((tag) => !_selectedTags.contains(tag)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Tags',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (!_isAddingTag)
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _isAddingTag = true;
                  });
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    FocusScope.of(context).requestFocus(_tagFocusNode);
                  });
                },
                icon: const Icon(
                  Icons.add,
                  color: Color(0xFFB4FF00),
                  size: 16,
                ),
                label: const Text(
                  'Add Tag',
                  style: TextStyle(
                    color: Color(0xFFB4FF00),
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_isAddingTag)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    focusNode: _tagFocusNode,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Add a tag...',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      prefixIcon: Icon(
                        Icons.tag,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ),
                    onSubmitted: (value) {
                      _addTag(value);
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.add_circle,
                    color: Color(0xFFB4FF00),
                  ),
                  onPressed: () {
                    _addTag(_tagController.text);
                  },
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _isAddingTag = false;
                      _tagController.clear();
                    });
                  },
                ),
              ],
            ),
          ),
        if (_selectedTags.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'No tags added yet',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedTags.map((tag) => _buildTagChip(tag)).toList(),
          ),
        const SizedBox(height: 16),
        const Text(
          'Suggested Tags',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _getUnselectedCommonTags()
              .take(8)
              .map((tag) => _buildSuggestedTag(tag))
              .toList(),
        ),
      ],
    );
  }
  
  Widget _buildTagChip(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '#$tag',
            style: const TextStyle(
              color: Color(0xFFB4FF00),
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => _removeTag(tag),
            child: const Icon(
              Icons.close,
              color: Colors.grey,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSuggestedTag(String tag) {
    return GestureDetector(
      onTap: () => _addTag(tag),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[700]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '#$tag',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.add,
              color: Colors.grey,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
} 