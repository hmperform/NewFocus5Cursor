import 'package:firebase_storage/firebase_storage.dart';

class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // Get the download URL for a video path in Firebase Storage
  Future<String> getVideoUrl(String videoPath) async {
    try {
      // If it's already a full URL, return it as is
      if (videoPath.startsWith('http')) {
        return videoPath;
      }
      
      // Handle gs:// URLs
      if (videoPath.startsWith('gs://')) {
        // Extract the path after the bucket name
        final uri = Uri.parse(videoPath);
        final bucketName = uri.authority;
        String objectPath = uri.path;
        
        // Remove leading slash if present
        if (objectPath.startsWith('/')) {
          objectPath = objectPath.substring(1);
        }
        
        // Use the specific bucket instance
        final storageRef = FirebaseStorage.instanceFor(
          bucket: 'gs://$bucketName'
        ).ref(objectPath);
        
        return await storageRef.getDownloadURL();
      }
      
      // Standard path reference
      return await _storage.ref(videoPath).getDownloadURL();
    } catch (e) {
      print('Error getting video URL: $e');
      return '';
    }
  }
  
  // Get multiple download URLs at once
  Future<Map<String, String>> getMultipleVideoUrls(List<String> videoPaths) async {
    final Map<String, String> results = {};
    
    for (final path in videoPaths) {
      try {
        final url = await getVideoUrl(path);
        if (url.isNotEmpty) {
          results[path] = url;
        }
      } catch (e) {
        print('Error getting URL for $path: $e');
      }
    }
    
    return results;
  }
} 