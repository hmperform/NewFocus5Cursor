import 'package:flutter/material.dart';
import 'package:focus5/models/content_models.dart';

class ArticleCard extends StatelessWidget {
  final Article article;
  final VoidCallback onTap;

  const ArticleCard({
    Key? key,
    required this.article,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: Implement a proper Article Card UI
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Placeholder for image
              Container(
                width: 80,
                height: 80,
                color: Colors.grey[300],
                child: article.imageUrl.isNotEmpty 
                  ? Image.network(article.imageUrl, fit: BoxFit.cover)
                  : const Icon(Icons.article, size: 40, color: Colors.grey),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(article.title, style: Theme.of(context).textTheme.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text('By ${article.authorName}', style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 4),
                    Text('${article.readTimeMinutes} min read', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 