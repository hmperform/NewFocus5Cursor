import 'package:flutter/material.dart';
import 'package:focus5/models/content_models.dart';
import 'package:focus5/screens/coach/coach_profile_screen.dart';

class ArticleDetailScreen extends StatelessWidget {
  final MediaItem article;

  const ArticleDetailScreen({
    Key? key,
    required this.article,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(article.title),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (article.imageUrl.isNotEmpty)
              Image.network(
                article.imageUrl,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CoachProfileScreen(
                            coach: {
                              'id': article.creatorId,
                              'name': article.creatorName,
                              'imageUrl': article.creatorImageUrl,
                            },
                          ),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: NetworkImage(article.creatorImageUrl),
                        ),
                        const SizedBox(width: 8),
                        Text(article.creatorName),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    article.description,
                    style: Theme.of(context).textTheme.bodyLarge,
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