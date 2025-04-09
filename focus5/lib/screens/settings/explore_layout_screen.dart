import 'package:flutter/material.dart';
import 'package:focus5/providers/theme_provider.dart';
import 'package:focus5/services/firebase_config_service.dart';
import 'package:provider/provider.dart';

class ExploreLayoutScreen extends StatefulWidget {
  const ExploreLayoutScreen({Key? key}) : super(key: key);

  @override
  State<ExploreLayoutScreen> createState() => _ExploreLayoutScreenState();
}

class _ExploreLayoutScreenState extends State<ExploreLayoutScreen> {
  final FirebaseConfigService _configService = FirebaseConfigService();
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  List<String> _sectionOrder = [];
  bool _hasChanges = false;

  // Map section IDs to user-friendly names
  final Map<String, String> _sectionNames = {
    'focus_areas': 'Focus Areas',
    'featured_courses': 'Featured Courses',
    'articles': 'Articles',
    'trending_courses': 'Trending Courses',
    'coaches': 'Coaches',
  };

  // Map section IDs to icons
  final Map<String, IconData> _sectionIcons = {
    'focus_areas': Icons.category,
    'featured_courses': Icons.star,
    'articles': Icons.article,
    'trending_courses': Icons.trending_up,
    'coaches': Icons.person,
  };

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final config = await _configService.getAppConfig();
      final List<dynamic> sectionOrder = 
        config['section_order'] as List<dynamic>? ?? 
        ['focus_areas', 'featured_courses', 'articles', 'trending_courses', 'coaches'];
      
      setState(() {
        _sectionOrder = sectionOrder.cast<String>();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load configuration: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final success = await _configService.updateExploreSectionOrder(_sectionOrder);
      
      if (mounted) {
        setState(() {
          _isSaving = false;
          _hasChanges = !success;
          
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Layout saved successfully')),
            );
          } else {
            _errorMessage = 'Failed to save changes. Please try again.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'Error: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).colorScheme.onBackground;
    final accentColor = themeProvider.accentColor;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Text(
          'Explore Screen Layout',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_hasChanges && !_isSaving)
            TextButton.icon(
              icon: Icon(Icons.save, color: accentColor),
              label: Text('SAVE', style: TextStyle(color: accentColor)),
              onPressed: _saveChanges,
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: accentColor,
              ),
            )
          : _buildContent(context, textColor, accentColor),
    );
  }

  Widget _buildContent(BuildContext context, Color textColor, Color accentColor) {
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: TextStyle(color: textColor.withOpacity(0.7)),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadConfig,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: accentColor,
                ),
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Drag and drop to reorder sections',
            style: TextStyle(
              fontSize: 16,
              color: textColor.withOpacity(0.7),
            ),
          ),
        ),
        Expanded(
          child: ReorderableListView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) {
                  newIndex -= 1;
                }
                final item = _sectionOrder.removeAt(oldIndex);
                _sectionOrder.insert(newIndex, item);
                _hasChanges = true;
              });
            },
            children: _sectionOrder.map((sectionId) {
              return _buildSectionItem(
                key: ValueKey(sectionId),
                sectionId: sectionId,
                textColor: textColor,
              );
            }).toList(),
          ),
        ),
        if (_isSaving)
          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: CircularProgressIndicator(
              color: accentColor,
            ),
          ),
      ],
    );
  }

  Widget _buildSectionItem({
    required Key key,
    required String sectionId,
    required Color textColor,
  }) {
    final sectionName = _sectionNames[sectionId] ?? 'Unknown Section';
    final sectionIcon = _sectionIcons[sectionId] ?? Icons.view_module;
    
    return Card(
      key: key,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        leading: Icon(
          sectionIcon,
          color: textColor,
        ),
        title: Text(
          sectionName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        trailing: ReorderableDragStartListener(
          index: _sectionOrder.indexOf(sectionId),
          child: Icon(
            Icons.drag_handle,
            color: textColor.withOpacity(0.5),
          ),
        ),
      ),
    );
  }
} 