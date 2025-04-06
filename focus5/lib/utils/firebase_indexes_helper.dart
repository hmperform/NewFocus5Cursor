import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Helper class for Firebase Firestore indexes information
class FirebaseIndexesHelper extends StatelessWidget {
  const FirebaseIndexesHelper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Indexes Helper'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Required Indexes for Focus5 App',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildIndexCard(
            context: context,
            collectionName: 'lessons',
            fields: ['courseId (Ascending)', 'sortOrder (Ascending)'],
            description: 'Required for loading course lessons in the correct order.',
            createUrl: 'https://console.firebase.google.com/v1/r/project/focus-5-app/firestore/indexes?create_composite=Cktwcm9qZWN0cy9mb2N1cy01LWFwcC9kYXRhYmFzZXMvKGRlZmF1bHQpL2NvbGxlY3Rpb25Hcm91cHMvbGVzc29ucy9pbmRleGVzL18QARoMCghjb3Vyc2VJZBABGg0KCXNvcnRPcmRlchABGgwKCF9fbmFtZV9fEAE',
          ),
          const SizedBox(height: 16),
          _buildIndexCard(
            context: context,
            collectionName: 'coaches',
            fields: ['isVerified (Ascending)', 'name (Ascending)'],
            description: 'Required for listing verified coaches sorted by name.',
            createUrl: 'https://console.firebase.google.com/v1/r/project/focus-5-app/firestore/indexes?create_composite=Cktwcm9qZWN0cy9mb2N1cy01LWFwcC9kYXRhYmFzZXMvKGRlZmF1bHQpL2NvbGxlY3Rpb25Hcm91cHMvY29hY2hlcy9pbmRleGVzL18QARoMCghpc1ZlcmlmaWVkEAEaCAoEbmFtZRABGgwKCF9fbmFtZV9fEAE',
          ),
          const SizedBox(height: 32),
          const Text(
            'Important Notes:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            '• When you rename collections in Firestore, you need to recreate the indexes for the new collection names.\n\n'
            '• If you\'ve migrated from "modules" to "lessons", create the index for the "lessons" collection using the links above.\n\n'
            '• After creating indexes, it may take several minutes for them to build and become active.\n\n'
            '• You can check the status of your indexes in the Firebase Console under Firestore > Indexes tab.'
          ),
        ],
      ),
    );
  }
  
  Widget _buildIndexCard({
    required BuildContext context,
    required String collectionName,
    required List<String> fields,
    required String description,
    required String createUrl,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Collection: $collectionName',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Fields: ${fields.join(', ')}'),
            const SizedBox(height: 8),
            Text('Description: $description'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final uri = Uri.parse(createUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not launch URL')),
                  );
                }
              },
              child: const Text('Create This Index'),
            ),
          ],
        ),
      ),
    );
  }
} 