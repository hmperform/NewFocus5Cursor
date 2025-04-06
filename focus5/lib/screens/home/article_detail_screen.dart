import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/content_models.dart';
import '../../providers/content_provider.dart';
import '../../providers/theme_provider.dart';
import 'coach_profile_screen.dart';
import '../../utils/image_utils.dart';

class ArticleDetailScreen extends StatelessWidget {
  final String articleId;
  
  const ArticleDetailScreen({
    Key? key,
    required this.articleId,
  }) : super(key: key);

  Future<void> _shareArticle(BuildContext context, Article article) async {
    await Share.share(
      'Check out this article: ${article.title}\n\nhttps://focus5app.com/articles/${article.id}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final contentProvider = Provider.of<ContentProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final article = contentProvider.getArticleById(articleId);
    
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onBackground;
    final secondaryTextColor = themeProvider.secondaryTextColor;
    final accentColor = themeProvider.accentColor;
    
    if (article == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: textColor),
        ),
        body: Center(
          child: Text(
            'Article not found',
            style: TextStyle(color: textColor),
          ),
        ),
      );
    }
    
    final formattedDate = DateFormat('MMMM d, yyyy').format(article.publishedDate);
    
    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          // App bar with image
          SliverAppBar(
            expandedHeight: 240,
            floating: false,
            pinned: true,
            backgroundColor: surfaceColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Article image
                  SizedBox(
                    height: MediaQuery.of(context).size.width * 0.7,
                    width: double.infinity,
                    child: article.thumbnailUrl.isNotEmpty
                        ? ImageUtils.networkImageWithFallback(
                            imageUrl: article.thumbnailUrl,
                            width: double.infinity,
                            height: MediaQuery.of(context).size.width * 0.7,
                            fit: BoxFit.cover,
                            backgroundColor: const Color(0xFF2A2A2A),
                            errorColor: Colors.white54,
                          )
                        : Container(
                            color: const Color(0xFF2A2A2A),
                            child: const Icon(
                              Icons.image_not_supported,
                              color: Colors.white54,
                              size: 50,
                            ),
                          ),
                  ),
                  // Gradient overlay for better visibility of title
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
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: surfaceColor.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: textColor),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: surfaceColor.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(Icons.share, color: textColor),
                  onPressed: () => _shareArticle(context, article),
                ),
              ),
            ],
          ),
          
          // Article content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and metadata
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        article.title,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Author info and date
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CoachProfileScreen(
                                coachId: article.authorId,
                              ),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            ImageUtils.avatarWithFallback(
                              imageUrl: article.authorImageUrl,
                              radius: 20,
                              name: article.authorName,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  article.authorName,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                Text(
                                  formattedDate,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: secondaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: secondaryTextColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${article.readTimeMinutes} min read',
                            style: TextStyle(
                              fontSize: 14,
                              color: secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: article.tags.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: surfaceColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                fontSize: 12,
                                color: accentColor,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      Divider(color: surfaceColor),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                
                // Article content in Markdown
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: MarkdownBody(
                    data: article.content,
                    styleSheet: MarkdownStyleSheet(
                      h1: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        height: 1.4,
                      ),
                      h2: TextStyle(
                        fontSize: 20, 
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        height: 1.4,
                      ),
                      h3: TextStyle(
                        fontSize: 18, 
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        height: 1.4,
                      ),
                      p: TextStyle(
                        fontSize: 16,
                        color: textColor,
                        height: 1.6,
                      ),
                      strong: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      em: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: secondaryTextColor,
                      ),
                      blockquote: TextStyle(
                        fontSize: 16,
                        color: secondaryTextColor,
                        fontStyle: FontStyle.italic,
                      ),
                      a: TextStyle(
                        color: accentColor,
                        decoration: TextDecoration.underline,
                      ),
                      code: TextStyle(
                        backgroundColor: surfaceColor,
                        color: accentColor,
                        fontSize: 14,
                      ),
                      codeblockPadding: const EdgeInsets.all(16),
                      codeblockDecoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onTapLink: (text, href, title) async {
                      if (href != null) {
                        final url = Uri.parse(href);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        }
                      }
                    },
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Related articles
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'More from ${article.authorName}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildRelatedArticles(context, contentProvider, article),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedArticles(BuildContext context, ContentProvider contentProvider, Article currentArticle) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onBackground;
    final secondaryTextColor = themeProvider.secondaryTextColor;
    
    final relatedArticles = contentProvider.getArticlesByAuthor(currentArticle.authorId)
        .where((article) => article.id != currentArticle.id)
        .toList();
    
    if (relatedArticles.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'No other articles from this author yet.',
          style: TextStyle(color: secondaryTextColor),
        ),
      );
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: relatedArticles.length > 3 ? 3 : relatedArticles.length,
      itemBuilder: (context, index) {
        final article = relatedArticles[index];
        final formattedDate = DateFormat('MMM d, yyyy').format(article.publishedDate);
        
        return GestureDetector(
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ArticleDetailScreen(articleId: article.id),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: FadeInImage.memoryNetwork(
                    placeholder: kTransparentImage,
                    image: article.thumbnailUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    imageErrorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 80,
                        color: surfaceColor,
                        child: Icon(
                          Icons.image_not_supported,
                          color: secondaryTextColor,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        article.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${article.readTimeMinutes} min read',
                        style: TextStyle(
                          fontSize: 12,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
} 