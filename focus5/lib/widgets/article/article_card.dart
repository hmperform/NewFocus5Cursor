import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:transparent_image/transparent_image.dart';
import '../../models/content_models.dart';
import '../../providers/user_provider.dart';
import '../../screens/home/article_detail_screen.dart';
import '../../services/paywall_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ArticleCard extends StatelessWidget {
  final Article article;
  
  const ArticleCard({
    Key? key,
    required this.article,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('MMM d, yyyy').format(article.publishedDate);
    final userProvider = Provider.of<UserProvider>(context);
    final isCompleted = userProvider.completedArticleIds.contains(article.id);
    
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
        width: MediaQuery.of(context).size.width * 0.85,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: isCompleted 
              ? Border.all(color: Colors.green, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Article image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: article.thumbnail,
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: const Color(0xFF2A2A2A),
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2.0, color: Colors.white54)),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: const Color(0xFF2A2A2A),
                      child: const Icon(Icons.broken_image, color: Colors.white54),
                    ),
                  ),
                ),
                if (isCompleted)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'COMPLETED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            
            // Article info
            Padding(
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
                      CachedNetworkImage(
                        imageUrl: article.authorImageUrl ?? '',
                        imageBuilder: (context, imageProvider) => CircleAvatar(
                          backgroundImage: imageProvider,
                          radius: 14,
                        ),
                        placeholder: (context, url) => const CircleAvatar(
                          radius: 14,
                          child: Icon(Icons.person, size: 16),
                        ),
                        errorWidget: (context, url, error) => const CircleAvatar(
                          radius: 14,
                          child: Icon(Icons.person, size: 16),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          article.authorName ?? 'Unknown Author',
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
    final userProvider = Provider.of<UserProvider>(context);
    final isCompleted = userProvider.completedArticleIds.contains(article.id);
    
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
          border: isCompleted 
              ? Border.all(color: Colors.green, width: 2)
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Article image - Simplified for square testing
            SizedBox( // Constrain the size to be square
              width: 100, 
              height: 100,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                ),
                child: CachedNetworkImage(
                  imageUrl: article.thumbnail,
                  width: 100, 
                  height: 100,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: const Color(0xFF2A2A2A),
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2.0, color: Colors.white54)),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: const Color(0xFF2A2A2A),
                    child: const Icon(Icons.broken_image, color: Colors.white54),
                  ),
                ),
              ),
            ),
            
            // Article info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title with completion status
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
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
                        ),
                        if (isCompleted)
                          const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Icon(
                              Icons.check_box,
                              color: Colors.green,
                              size: 20,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Author
                    Row(
                      children: [
                        CachedNetworkImage(
                          imageUrl: article.authorImageUrl ?? '',
                          imageBuilder: (context, imageProvider) => CircleAvatar(
                            backgroundImage: imageProvider,
                            radius: 12,
                          ),
                          placeholder: (context, url) => const CircleAvatar(
                            radius: 12, 
                            child: Icon(Icons.person, size: 14),
                          ),
                          errorWidget: (context, url, error) => const CircleAvatar(
                            radius: 12, 
                            child: Icon(Icons.person, size: 14),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            article.authorName ?? 'Unknown Author',
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

class HorizontalArticleCard extends StatelessWidget {
  final Article article;
  
  const HorizontalArticleCard({
    Key? key,
    required this.article,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('MMM d, yyyy').format(article.publishedDate);
    final userProvider = Provider.of<UserProvider>(context);
    final isCompleted = userProvider.completedArticleIds.contains(article.id);
    
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
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: isCompleted 
              ? Border.all(color: Colors.green, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Article image - make it a bit taller for horizontal cards
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: article.thumbnail,
                    width: double.infinity,
                    height: 160,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: const Color(0xFF2A2A2A),
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2.0, color: Colors.white54)),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: const Color(0xFF2A2A2A),
                      child: const Icon(Icons.broken_image, color: Colors.white54),
                    ),
                  ),
                ),
                if (isCompleted)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
              ],
            ),
            
            // Article info
            Padding(
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
                  
                  // Author with image
                  Row(
                    children: [
                      CachedNetworkImage(
                        imageUrl: article.authorImageUrl ?? '',
                        imageBuilder: (context, imageProvider) => CircleAvatar(
                          backgroundImage: imageProvider,
                          radius: 12,
                        ),
                        placeholder: (context, url) => const CircleAvatar(
                          radius: 12,
                          child: Icon(Icons.person, size: 14),
                        ),
                        errorWidget: (context, url, error) => const CircleAvatar(
                          radius: 12,
                          child: Icon(Icons.person, size: 14),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          article.authorName ?? 'Unknown Author',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Info row with date and read time
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 4),
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
                        '${article.readTimeMinutes} min read',
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
          ],
        ),
      ),
    );
  }
} 