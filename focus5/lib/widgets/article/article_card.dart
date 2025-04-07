import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:transparent_image/transparent_image.dart';
import '../../models/content_models.dart';
import '../../screens/home/article_detail_screen.dart';
import '../../utils/image_utils.dart';
import '../../services/paywall_service.dart';

class ArticleCard extends StatelessWidget {
  final Article article;
  
  const ArticleCard({
    Key? key,
    required this.article,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('MMM d, yyyy').format(article.publishedDate);
    
    return GestureDetector(
      onTap: () async {
        // Check if user has access or show paywall
        final paywallService = PaywallService();
        final hasAccess = await paywallService.showPaywallIfNeeded(
          context,
          source: 'article',
        );
        
        // If user has access, navigate to article
        if (hasAccess && context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ArticleDetailScreen(articleId: article.id),
            ),
          );
        }
      },
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Article image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: ImageUtils.networkImageWithFallback(
                imageUrl: article.thumbnailUrl,
                width: 280,
                height: 140,
                fit: BoxFit.cover,
                backgroundColor: const Color(0xFF2A2A2A),
                errorColor: Colors.white54,
              ),
            ),
            
            // Article info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Author and date
                    Row(
                      children: [
                        ImageUtils.avatarWithFallback(
                          imageUrl: article.authorImageUrl,
                          radius: 14,
                          name: article.authorName,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            article.authorName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    
                    // Info row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${article.readTimeMinutes} min',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ArticleListCard extends StatelessWidget {
  final Article article;
  
  const ArticleListCard({
    Key? key,
    required this.article,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('MMM d, yyyy').format(article.publishedDate);
    
    return GestureDetector(
      onTap: () async {
        // Check if user has access or show paywall
        final paywallService = PaywallService();
        final hasAccess = await paywallService.showPaywallIfNeeded(
          context,
          source: 'article',
        );
        
        // If user has access, navigate to article
        if (hasAccess && context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ArticleDetailScreen(articleId: article.id),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Article image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: ImageUtils.networkImageWithFallback(
                imageUrl: article.thumbnailUrl,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                backgroundColor: const Color(0xFF2A2A2A),
                errorColor: Colors.white54,
              ),
            ),
            
            // Article info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Author
                    Row(
                      children: [
                        ImageUtils.avatarWithFallback(
                          imageUrl: article.authorImageUrl,
                          radius: 12,
                          name: article.authorName,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            article.authorName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Info row
                    Row(
                      children: [
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${article.readTimeMinutes} min',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 