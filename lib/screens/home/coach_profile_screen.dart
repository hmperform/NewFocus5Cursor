import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:provider/provider.dart';
import '../../providers/content_provider.dart';
import '../../models/content_models.dart';
import '../../widgets/article/article_card.dart';
import '../home/articles_list_screen.dart';
import 'package:focus5/models/coach_model.dart';
import 'package:focus5/providers/theme_provider.dart';
import 'package:focus5/widgets/article/article_card.dart';
import 'package:focus5/models/content_models.dart';
import 'all_articles_screen.dart';

class CoachProfileScreen extends StatefulWidget {
  final CoachModel coach;
  const CoachProfileScreen({Key? key, required this.coach}) : super(key: key);

  @override
  _CoachProfileScreenState createState() => _CoachProfileScreenState();
}

class _CoachProfileScreenState extends State<CoachProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final CoachModel _coach = widget.coach;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final textColor = themeProvider.textColor;
    final accentColor = themeProvider.accentColor;
    final backgroundColor = themeProvider.backgroundColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: _coach.profileImageUrl.isNotEmpty
                        ? NetworkImage(_coach.profileImageUrl)
                        : const AssetImage('assets/images/default_coach_header.png') as ImageProvider,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),
              ),
              title: Text(_coach.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              centerTitle: true,
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _coach.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: textColor),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Bio',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(color: textColor),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'TODO: Fetch coach bio from Firestore',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: textColor),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ArticlesListScreen(
                            tag: widget.coach['name'],
                          ),
                        ),
                      );