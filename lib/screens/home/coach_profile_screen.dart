import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:provider/provider.dart';
import '../../providers/content_provider.dart';
import '../../models/content_models.dart';
import '../../widgets/article/article_card.dart';
import '../home/articles_list_screen.dart';

// ... existing code ...

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ArticlesListScreen(
                            tag: widget.coach['name'],
                          ),
                        ),
                      );