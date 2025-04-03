import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

class ArticleDetailScreen extends StatelessWidget {
  final String title;
  final String imageUrl;
  final String? content;

  const ArticleDetailScreen({
    Key? key,
    required this.title,
    required this.imageUrl,
    this.content,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).colorScheme.onBackground;
    final secondaryTextColor = themeProvider.secondaryTextColor;
    
    // Generate dummy content if none provided
    final articleContent = content ?? _generateDummyContent();

    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240.0,
            floating: false,
            pinned: true,
            backgroundColor: backgroundColor,
            iconTheme: IconThemeData(color: textColor),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
                  // Gradient overlay for better text visibility
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                        stops: const [0.6, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author and date
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: NetworkImage(
                          'https://i.pravatar.cc/150?img=3',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dr. Sarah Johnson',
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Performance Psychologist • May 15, 2023',
                            style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Article content
                  Text(
                    articleContent,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Tags
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildTag(context, 'Mental Performance'),
                      _buildTag(context, 'Athletes'),
                      _buildTag(context, 'Focus'),
                      _buildTag(context, 'Mindfulness'),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Related articles
                  Text(
                    'Related Articles',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Related articles list
                  SizedBox(
                    height: 180,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildRelatedArticle(
                          context,
                          'Visualization Techniques for Athletes',
                          'https://picsum.photos/seed/article1/300/200',
                        ),
                        _buildRelatedArticle(
                          context,
                          'How to Maintain Focus During Competition',
                          'https://picsum.photos/seed/article2/300/200',
                        ),
                        _buildRelatedArticle(
                          context,
                          'Recovery Strategies for Mental Fatigue',
                          'https://picsum.photos/seed/article3/300/200',
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.bookmark_border),
                    onPressed: () {},
                    color: textColor,
                  ),
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () {},
                    color: textColor,
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.headphones),
                label: const Text('Listen'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeProvider.accentColor,
                  foregroundColor: themeProvider.accentTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTag(BuildContext context, String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Text(
        '#$tag',
        style: TextStyle(
          color: Theme.of(context).colorScheme.secondary,
          fontSize: 12,
        ),
      ),
    );
  }
  
  Widget _buildRelatedArticle(BuildContext context, String title, String imageUrl) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              imageUrl,
              height: 120,
              width: 200,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 120,
                  width: 200,
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.image_not_supported, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onBackground,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
  
  String _generateDummyContent() {
    return '''
Mental focus is a crucial skill for athletes at all levels. Whether you're preparing for a championship game or simply trying to improve your personal best, the ability to concentrate fully on your performance can make the difference between success and frustration.

In this article, we'll explore five effective techniques to enhance your mental focus and concentration during training and competition.

1. Mindfulness Training

Mindfulness involves deliberately paying attention to the present moment without judgment. Regular mindfulness practice can significantly improve your ability to maintain focus during high-pressure situations.

Start with just 5 minutes daily of focused breathing. Sit comfortably, close your eyes, and direct your attention to your breath. When your mind wanders (which it will), gently bring your attention back to your breathing without frustration or judgment.

2. Visualization

Elite athletes regularly use visualization techniques to mentally rehearse their performance. By creating detailed mental images of successful execution, you're training your brain for the actual event.

Spend 10-15 minutes daily visualizing yourself performing with perfect technique. Engage all your senses – how it looks, feels, sounds, and even smells. Imagine overcoming obstacles and maintaining composure under pressure.

3. Establish Pre-Performance Routines

A consistent pre-performance routine helps signal to your brain that it's time to focus. This routine creates mental triggers that automatically shift your attention to the task at hand.

Develop a specific sequence of actions you perform before training or competition. This might include physical warm-ups, mental preparation, equipment checks, or motivational cues. The key is consistency.

4. Strategic Goal Setting

Having clear, specific goals helps direct your focus toward what matters most. Without defined objectives, your attention is more likely to scatter.

Establish both process and outcome goals. Process goals focus on execution (maintain proper form), while outcome goals relate to results (achieve a specific time). During performance, concentrate primarily on process goals, as these are within your direct control.

5. Distraction Management

Rather than trying to eliminate distractions (which is often impossible), develop strategies to manage them effectively.

Identify your common distractions and create specific plans to address them. For external distractions, consider environmental modifications. For internal distractions like self-doubt, develop trigger words or phrases that help you refocus.

Conclusion

Mental focus isn't an innate talent – it's a skill that improves with deliberate practice. By incorporating these techniques into your regular training regimen, you'll develop the concentration abilities needed for peak performance.

Remember that focus, like physical fitness, develops gradually. Be patient with yourself as you build this crucial mental skill, and you'll soon notice improvements both in your ability to concentrate and in your overall athletic performance.
    ''';
  }
} 