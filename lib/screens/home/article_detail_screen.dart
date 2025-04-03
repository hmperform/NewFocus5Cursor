                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CoachProfileScreen(
                                    coach: {'id': article.authorId, 'name': article.authorName, 'imageUrl': article.authorImageUrl},
                                  ),
                                ),
                              ); 