import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:transparent_image/transparent_image.dart';

import '../../providers/theme_provider.dart';
import '../../providers/content_provider.dart';
import '../../models/content_models.dart';

class AllModulesScreen extends StatefulWidget {
  const AllModulesScreen({Key? key}) : super(key: key);

  @override
  State<AllModulesScreen> createState() => _AllModulesScreenState();
}

class _AllModulesScreenState extends State<AllModulesScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadModules();
  }
  
  Future<void> _loadModules() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Ensure modules are loaded in the provider
      final contentProvider = Provider.of<ContentProvider>(context, listen: false);
      if (contentProvider.courses.isEmpty) {
        await contentProvider.initContent(null);
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final contentProvider = Provider.of<ContentProvider>(context);
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).colorScheme.onBackground;
    
    final modules = contentProvider.getModules();
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Focus Areas',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: themeProvider.accentColor))
          : modules.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.category_outlined, size: 48, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'No Focus Areas Available',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Check back later for new content',
                        style: TextStyle(color: textColor.withOpacity(0.7)),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadModules,
                  color: themeProvider.accentColor,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.0,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: modules.length,
                    itemBuilder: (context, index) {
                      final module = modules[index];
                      return _buildModuleCard(module);
                    },
                  ),
                ),
    );
  }
  
  Widget _buildModuleCard(Module module) {
    final textColor = Theme.of(context).colorScheme.onBackground;
    
    return GestureDetector(
      onTap: () {
        // Navigate to module content - in the future we'll navigate to a ModuleDetailScreen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening ${module.title}...'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Module image
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: FadeInImage.memoryNetwork(
                placeholder: kTransparentImage,
                image: module.imageUrl,
                height: double.infinity,
                width: double.infinity,
                fit: BoxFit.cover,
                imageErrorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: double.infinity,
                    width: double.infinity,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image, color: Colors.grey),
                  );
                },
              ),
            ),
            
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
            
            // Module info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    module.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.headphones,
                        color: Colors.white70,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${module.audioCount} audio tracks',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 