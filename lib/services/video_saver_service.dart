import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Simple and direct video/image saver service
class VideoSaverService {
  
  /// Save images directly to Downloads folder - SIMPLE & DIRECT
  static Future<Map<String, dynamic>> saveImages(List<String> imageUrls) async {
    int savedCount = 0;
    String? savedPath;
    List<String> errors = [];
    
    try {
      // Get save directory
      final saveDir = await _getSaveDirectory();
      if (saveDir == null) {
        return {
          'success': false,
          'message': 'Cannot access storage',
          'savedCount': 0,
        };
      }
      
      savedPath = saveDir;
      
      if (kDebugMode) {
        debugPrint('Saving to: $saveDir');
      }
      
      // Save each image
      for (int i = 0; i < imageUrls.length; i++) {
        final url = imageUrls[i];
        final fileName = 'memory_${i + 1}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        
        try {
          if (url.startsWith('http')) {
            // Download from network
            final bytes = await _downloadFile(url);
            if (bytes != null) {
              final file = File('$saveDir/$fileName');
              await file.writeAsBytes(bytes);
              savedCount++;
              if (kDebugMode) {
                debugPrint('Saved: $fileName');
              }
            } else {
              errors.add('Failed to download image ${i + 1}');
            }
          } else {
            // Copy local file
            final sourceFile = File(url);
            if (await sourceFile.exists()) {
              final destFile = File('$saveDir/$fileName');
              await sourceFile.copy(destFile.path);
              savedCount++;
              if (kDebugMode) {
                debugPrint('Copied: $fileName');
              }
            } else {
              errors.add('File not found: ${i + 1}');
            }
          }
        } catch (e) {
          errors.add('Error saving image ${i + 1}');
          if (kDebugMode) {
            debugPrint('Error saving image $i: $e');
          }
        }
      }
      
      return {
        'success': savedCount > 0,
        'message': savedCount > 0 
            ? 'Saved $savedCount/${imageUrls.length} images' 
            : (errors.isNotEmpty ? errors.first : 'Failed to save'),
        'savedCount': savedCount,
        'totalCount': imageUrls.length,
        'savedPath': savedPath,
      };
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Save error: $e');
      }
      return {
        'success': false,
        'message': 'Error: $e',
        'savedCount': 0,
      };
    }
  }
  
  /// Get save directory - tries multiple paths
  static Future<String?> _getSaveDirectory() async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final folderName = 'Memories_$timestamp';
      
      if (Platform.isAndroid) {
        // Try external storage paths
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) {
          // Try Download folder
          final basePath = extDir.parent.parent.parent.parent.path;
          
          // Try these paths in order
          final paths = [
            '$basePath/Download/$folderName',
            '$basePath/Pictures/$folderName',
            '$basePath/DCIM/$folderName',
            '${extDir.path}/$folderName',
          ];
          
          for (final path in paths) {
            try {
              final dir = Directory(path);
              await dir.create(recursive: true);
              
              // Test write
              final testFile = File('$path/.test');
              await testFile.writeAsString('test');
              await testFile.delete();
              
              return path;
            } catch (e) {
              continue;
            }
          }
        }
      }
      
      // Fallback to app documents
      final appDir = await getApplicationDocumentsDirectory();
      final fallbackPath = '${appDir.path}/$folderName';
      final dir = Directory(fallbackPath);
      await dir.create(recursive: true);
      return fallbackPath;
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting save directory: $e');
      }
      return null;
    }
  }
  
  /// Download file from URL
  static Future<Uint8List?> _downloadFile(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 30),
      );
      
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        return response.bodyBytes;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Download error: $e');
      }
      return null;
    }
  }
}
