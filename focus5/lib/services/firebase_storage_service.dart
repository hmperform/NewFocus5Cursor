import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

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

  // Upload a profile image to Firebase Storage and return the download URL
  Future<String?> uploadProfileImage(String userId, File imageFile) async {
    try {
      // Create a reference to the location where we'll store the file
      // Store profile images in a dedicated folder with user ID as filename
      final fileName = path.basename(imageFile.path);
      final fileExtension = path.extension(fileName);
      final storageRef = _storage.ref().child('profile_images/$userId$fileExtension');
      
      // Upload the file
      await storageRef.putFile(imageFile);
      
      // Get the download URL
      final downloadUrl = await storageRef.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      return null;
    }
  }

  // Upload a profile image from web (Uint8List)
  Future<String?> uploadProfileImageWeb(String userId, Uint8List imageData, String fileExtension) async {
    try {
      // Create a reference to the location where we'll store the file
      final storageRef = _storage.ref().child('profile_images/$userId$fileExtension');
      
      // Upload the file
      await storageRef.putData(
        imageData,
        SettableMetadata(contentType: 'image/$fileExtension'),
      );
      
      // Get the download URL
      final downloadUrl = await storageRef.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading profile image for web: $e');
      return null;
    }
  }

  // Delete a file from Firebase Storage
  Future<bool> deleteFile(String fileUrl) async {
    try {
      // If it's a direct URL, convert it to a storage reference
      if (fileUrl.startsWith('http')) {
        // Create a reference from the URL
        final ref = _storage.refFromURL(fileUrl);
        await ref.delete();
      } else {
        // It's a path
        await _storage.ref(fileUrl).delete();
      }
      
      return true;
    } catch (e) {
      debugPrint('Error deleting file: $e');
      return false;
    }
  }
} 