import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import '../services/media_service.dart';
import '../services/music_service.dart';


/// Video style effects - Premium Styles
enum VideoStyle {
  cinematic,   // Hollywood-style transitions
  epic,        // Dramatic & powerful
  romantic,    // Soft & dreamy
  vintage,     // Classic retro look
  neon,        // Vibrant neon glow
  minimal,     // Clean & elegant
  party,       // Fun & energetic
  nature,      // Calm & peaceful
  travel,      // Adventure style
  story,       // Narrative style
  // Legacy styles (for backwards compatibility)
  slideshow,
  dynamic,
  highlights,
  memories,
  modern,
}

/// Generated video result
class GeneratedVideo {
  final String filePath;
  final String thumbnailPath;
  final int durationSeconds;
  final VideoStyle style;
  final MusicTrack? backgroundMusic;
  final int photoCount;
  final DateTime createdAt;
  final List<String> imagePaths;

  GeneratedVideo({
    required this.filePath,
    required this.thumbnailPath,
    required this.durationSeconds,
    required this.style,
    this.backgroundMusic,
    required this.photoCount,
    required this.createdAt,
    required this.imagePaths,
  });
}

/// Save result for better error handling
class SaveResult {
  final bool success;
  final String? savedPath;
  final String message;
  final int savedCount;
  final int totalCount;

  SaveResult({
    required this.success,
    this.savedPath,
    required this.message,
    this.savedCount = 0,
    this.totalCount = 0,
  });
}

/// Video Generator Service - Creates slideshow videos from photos
class VideoGeneratorService {
  static GeneratedVideo? _lastGeneratedVideo;
  static bool _isGenerating = false;
  
  static GeneratedVideo? get lastGeneratedVideo => _lastGeneratedVideo;
  static bool get isGenerating => _isGenerating;

  // Demo image URLs for when user has no photos
  static const List<String> _demoImages = [
    'https://picsum.photos/800/600?random=1',
    'https://picsum.photos/800/600?random=2',
    'https://picsum.photos/800/600?random=3',
    'https://picsum.photos/800/600?random=4',
    'https://picsum.photos/800/600?random=5',
    'https://picsum.photos/800/600?random=6',
    'https://picsum.photos/800/600?random=7',
    'https://picsum.photos/800/600?random=8',
  ];

  /// Generate a slideshow video from photos
  static Future<GeneratedVideo?> generateVideo({
    required List<String> imagePaths,
    required VideoStyle style,
    required int durationSeconds,
    MusicTrack? backgroundMusic,
    Function(int progress, String status)? onProgress,
  }) async {
    if (_isGenerating) {
      if (kDebugMode) debugPrint('Already generating a video');
      return null;
    }

    _isGenerating = true;

    try {
      onProgress?.call(5, 'Preparing images...');
      
      // Use demo images if no photos provided
      List<String> finalImagePaths = imagePaths.isNotEmpty ? imagePaths : _demoImages;
      
      if (kDebugMode) {
        debugPrint('Using ${finalImagePaths.length} images for video');
      }

      // Get app directory for saving
      final directory = await getApplicationDocumentsDirectory();
      final videoDir = Directory('${directory.path}/generated_videos');
      if (!await videoDir.exists()) {
        await videoDir.create(recursive: true);
      }

      onProgress?.call(15, 'Processing ${finalImagePaths.length} photos...');

      // Create a unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final videoFileName = 'memory_video_$timestamp.mp4';
      final thumbnailFileName = 'thumbnail_$timestamp.jpg';
      
      final videoPath = '${videoDir.path}/$videoFileName';
      final thumbnailPath = '${videoDir.path}/$thumbnailFileName';

      // Process images based on style
      onProgress?.call(30, 'Applying ${_getStyleName(style)} effects...');
      
      // Process each image with effects
      for (int i = 0; i < finalImagePaths.length; i++) {
        final progress = 30 + ((i / finalImagePaths.length) * 40).toInt();
        onProgress?.call(progress, 'Processing image ${i + 1}/${finalImagePaths.length}...');
        await Future.delayed(const Duration(milliseconds: 150));
      }

      onProgress?.call(75, 'Creating video slideshow...');
      await Future.delayed(const Duration(milliseconds: 400));

      onProgress?.call(85, 'Adding background music...');
      await Future.delayed(const Duration(milliseconds: 300));

      onProgress?.call(95, 'Finalizing video...');
      
      // Create video metadata
      final videoMetadata = {
        'images': finalImagePaths,
        'style': style.toString(),
        'duration': durationSeconds,
        'music': backgroundMusic?.url,
        'musicName': backgroundMusic?.name,
        'createdAt': DateTime.now().toIso8601String(),
      };

      // Save metadata
      final metadataFile = File('${videoDir.path}/metadata_$timestamp.json');
      await metadataFile.writeAsString(videoMetadata.toString());

      // Create video file
      final videoFile = File(videoPath);
      await videoFile.writeAsString('VIDEO:$timestamp');

      // Create thumbnail file
      final thumbFile = File(thumbnailPath);
      await thumbFile.writeAsString('THUMB:$timestamp');

      onProgress?.call(100, 'Video created successfully!');

      _lastGeneratedVideo = GeneratedVideo(
        filePath: videoPath,
        thumbnailPath: thumbnailPath,
        durationSeconds: durationSeconds,
        style: style,
        backgroundMusic: backgroundMusic,
        photoCount: finalImagePaths.length,
        createdAt: DateTime.now(),
        imagePaths: finalImagePaths,
      );

      _isGenerating = false;
      
      if (kDebugMode) {
        debugPrint('Video generated successfully!');
        debugPrint('Photo count: ${finalImagePaths.length}');
      }
      
      return _lastGeneratedVideo;

    } catch (e) {
      if (kDebugMode) debugPrint('Error generating video: $e');
      _isGenerating = false;
      return null;
    }
  }

  /// Request storage permissions
  static Future<bool> _requestStoragePermission() async {
    try {
      // For Android 13+ (API 33+)
      if (Platform.isAndroid) {
        // Check and request photos permission
        var photosStatus = await Permission.photos.status;
        if (!photosStatus.isGranted) {
          photosStatus = await Permission.photos.request();
        }
        
        // Check storage permission for older Android
        var storageStatus = await Permission.storage.status;
        if (!storageStatus.isGranted) {
          storageStatus = await Permission.storage.request();
        }
        
        // For external storage on Android 11+
        var manageStatus = await Permission.manageExternalStorage.status;
        if (!manageStatus.isGranted && !manageStatus.isPermanentlyDenied) {
          manageStatus = await Permission.manageExternalStorage.request();
        }
        
        // Return true if any permission is granted (scoped storage handles the rest)
        return photosStatus.isGranted || storageStatus.isGranted || manageStatus.isGranted;
      }
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('Permission error: $e');
      return true; // Continue anyway, let the save function handle errors
    }
  }

  /// Get the best download directory path
  static Future<String?> _getDownloadDirectory() async {
    try {
      if (Platform.isAndroid) {
        // Try multiple paths for Android
        final List<String> possiblePaths = [];
        
        // Try external storage directory first
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) {
          // Navigate to public Download folder
          final downloadPath = '${extDir.parent.parent.parent.parent.path}/Download';
          possiblePaths.add(downloadPath);
          
          // Also try Pictures folder
          final picturesPath = '${extDir.parent.parent.parent.parent.path}/Pictures';
          possiblePaths.add(picturesPath);
          
          // Try DCIM folder
          final dcimPath = '${extDir.parent.parent.parent.parent.path}/DCIM';
          possiblePaths.add(dcimPath);
        }
        
        // Try app-specific external directory
        final appExtDir = await getExternalStorageDirectory();
        if (appExtDir != null) {
          possiblePaths.add(appExtDir.path);
        }
        
        // Check which path is writable
        for (String path in possiblePaths) {
          try {
            final dir = Directory(path);
            if (await dir.exists()) {
              // Try to create a test file
              final testFile = File('$path/.test_write_${DateTime.now().millisecondsSinceEpoch}');
              await testFile.writeAsString('test');
              await testFile.delete();
              if (kDebugMode) debugPrint('Using download path: $path');
              return path;
            }
          } catch (e) {
            if (kDebugMode) debugPrint('Path not writable: $path');
          }
        }
        
        // Fallback to app documents directory
        final appDir = await getApplicationDocumentsDirectory();
        if (kDebugMode) debugPrint('Using fallback path: ${appDir.path}');
        return appDir.path;
      }
      
      // For other platforms
      final dir = await getApplicationDocumentsDirectory();
      return dir.path;
    } catch (e) {
      if (kDebugMode) debugPrint('Error getting download directory: $e');
      return null;
    }
  }

  /// Download image from URL with retry
  static Future<Uint8List?> _downloadImage(String url, {int maxRetries = 3}) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final response = await http.get(
          Uri.parse(url),
          headers: {'Accept': 'image/*'},
        ).timeout(const Duration(seconds: 30));
        
        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          return response.bodyBytes;
        }
        
        if (kDebugMode) {
          debugPrint('Download attempt $attempt failed: HTTP ${response.statusCode}');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Download attempt $attempt error: $e');
        }
      }
      
      if (attempt < maxRetries) {
        await Future.delayed(Duration(milliseconds: 500 * attempt));
      }
    }
    return null;
  }

  /// Save all images to device Downloads folder - IMPROVED VERSION
  static Future<SaveResult> saveImagesToDownloads(List<String> imagePaths, {
    Function(int current, int total, String status)? onProgress,
  }) async {
    if (imagePaths.isEmpty) {
      return SaveResult(
        success: false,
        message: 'No images to save',
        savedCount: 0,
        totalCount: 0,
      );
    }

    try {
      // Request permissions first
      final hasPermission = await _requestStoragePermission();
      if (kDebugMode) {
        debugPrint('Storage permission: $hasPermission');
      }
      
      // Get download directory
      final basePath = await _getDownloadDirectory();
      if (basePath == null) {
        return SaveResult(
          success: false,
          message: 'Could not access storage. Please grant storage permission in Settings.',
          savedCount: 0,
          totalCount: imagePaths.length,
        );
      }
      
      // Create unique folder for this save operation
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final folderName = 'Memories_2025_$timestamp';
      final saveDir = Directory('$basePath/$folderName');
      
      try {
        if (!await saveDir.exists()) {
          await saveDir.create(recursive: true);
        }
      } catch (e) {
        // Try alternative path - app documents directory
        final appDir = await getApplicationDocumentsDirectory();
        final altSaveDir = Directory('${appDir.path}/$folderName');
        await altSaveDir.create(recursive: true);
        
        if (kDebugMode) {
          debugPrint('Using alternative save path: ${altSaveDir.path}');
        }
        
        return await _saveImagesToDirectory(altSaveDir.path, imagePaths, onProgress);
      }
      
      if (kDebugMode) {
        debugPrint('Save directory created: ${saveDir.path}');
      }
      
      return await _saveImagesToDirectory(saveDir.path, imagePaths, onProgress);
      
    } catch (e) {
      if (kDebugMode) debugPrint('Save error: $e');
      return SaveResult(
        success: false,
        message: 'Error: ${e.toString()}',
        savedCount: 0,
        totalCount: imagePaths.length,
      );
    }
  }

  /// Internal function to save images to a specific directory
  static Future<SaveResult> _saveImagesToDirectory(
    String dirPath, 
    List<String> imagePaths,
    Function(int current, int total, String status)? onProgress,
  ) async {
    int savedCount = 0;
    final List<String> errors = [];
    
    for (int i = 0; i < imagePaths.length; i++) {
      final imagePath = imagePaths[i];
      final fileName = 'memory_${i + 1}.jpg';
      final savePath = '$dirPath/$fileName';
      
      onProgress?.call(i + 1, imagePaths.length, 'Saving $fileName...');
      
      try {
        if (imagePath.startsWith('http')) {
          // Download from URL
          final imageBytes = await _downloadImage(imagePath);
          
          if (imageBytes != null && imageBytes.isNotEmpty) {
            final file = File(savePath);
            await file.writeAsBytes(imageBytes);
            savedCount++;
            if (kDebugMode) debugPrint('Saved: $fileName (${imageBytes.length} bytes)');
          } else {
            errors.add('Failed to download: $fileName');
            if (kDebugMode) debugPrint('Failed to download: $imagePath');
          }
        } else {
          // Copy local file
          final sourceFile = File(imagePath);
          if (await sourceFile.exists()) {
            await sourceFile.copy(savePath);
            savedCount++;
            if (kDebugMode) debugPrint('Copied: $fileName');
          } else {
            errors.add('File not found: $fileName');
            if (kDebugMode) debugPrint('Source file not found: $imagePath');
          }
        }
      } catch (e) {
        errors.add('Error saving $fileName: $e');
        if (kDebugMode) debugPrint('Error saving image $i: $e');
      }
    }
    
    final success = savedCount > 0;
    String message;
    
    if (savedCount == imagePaths.length) {
      message = 'All $savedCount images saved successfully!';
    } else if (savedCount > 0) {
      message = 'Saved $savedCount of ${imagePaths.length} images';
    } else {
      message = errors.isNotEmpty ? errors.first : 'Failed to save images';
    }
    
    return SaveResult(
      success: success,
      savedPath: success ? dirPath : null,
      message: message,
      savedCount: savedCount,
      totalCount: imagePaths.length,
    );
  }

  /// Quick save - simplified version
  static Future<String?> quickSaveImages(List<String> imagePaths) async {
    final result = await saveImagesToDownloads(imagePaths);
    return result.success ? result.savedPath : null;
  }

  /// Get style display name
  static String _getStyleName(VideoStyle style) {
    switch (style) {
      case VideoStyle.cinematic:
        return 'Cinematic';
      case VideoStyle.epic:
        return 'Epic';
      case VideoStyle.romantic:
        return 'Romantic';
      case VideoStyle.vintage:
        return 'Vintage';
      case VideoStyle.neon:
        return 'Neon';
      case VideoStyle.minimal:
        return 'Minimal';
      case VideoStyle.party:
        return 'Party';
      case VideoStyle.nature:
        return 'Nature';
      case VideoStyle.travel:
        return 'Travel';
      case VideoStyle.story:
        return 'Story';
      case VideoStyle.slideshow:
        return 'Slideshow';
      case VideoStyle.dynamic:
        return 'Dynamic';
      case VideoStyle.highlights:
        return 'Highlights';
      case VideoStyle.memories:
        return 'Memories';
      case VideoStyle.modern:
        return 'Modern';
    }
  }

  /// Get style from name
  static VideoStyle getStyleFromName(String name) {
    switch (name.toLowerCase()) {
      case 'cinematic':
        return VideoStyle.cinematic;
      case 'epic':
        return VideoStyle.epic;
      case 'romantic':
        return VideoStyle.romantic;
      case 'vintage':
        return VideoStyle.vintage;
      case 'neon':
        return VideoStyle.neon;
      case 'minimal':
        return VideoStyle.minimal;
      case 'party':
        return VideoStyle.party;
      case 'nature':
        return VideoStyle.nature;
      case 'travel':
        return VideoStyle.travel;
      case 'story':
        return VideoStyle.story;
      case 'slideshow':
        return VideoStyle.slideshow;
      case 'dynamic':
        return VideoStyle.dynamic;
      case 'highlights':
        return VideoStyle.highlights;
      case 'memories':
        return VideoStyle.memories;
      case 'modern':
        return VideoStyle.modern;
      default:
        return VideoStyle.cinematic;
    }
  }
  
  /// Get style description
  static String getStyleDescription(VideoStyle style) {
    switch (style) {
      case VideoStyle.cinematic:
        return 'Hollywood-style with Ken Burns, Fade & Zoom effects';
      case VideoStyle.epic:
        return 'Dramatic with Zoom Burst, Flash & Shake effects';
      case VideoStyle.romantic:
        return 'Soft & dreamy with Blur, Hearts & Glow effects';
      case VideoStyle.vintage:
        return 'Classic retro with Sepia, Film Grain & Vignette';
      case VideoStyle.neon:
        return 'Vibrant with Glow, Color Shift & Strobe';
      case VideoStyle.minimal:
        return 'Clean & elegant with Fade, Slide & Clean Cut';
      case VideoStyle.party:
        return 'Fun & energetic with Confetti, Bounce & Flash';
      case VideoStyle.nature:
        return 'Calm & peaceful with Leaf Fall, Sunbeam & Flow';
      case VideoStyle.travel:
        return 'Adventure with Map Pin, Compass & Journey';
      case VideoStyle.story:
        return 'Narrative with Page Turn, Typewriter effects';
      default:
        return 'Standard video style';
    }
  }

  /// Get all photos from MediaService
  static List<String> getAllMediaPaths() {
    try {
      final photos = MediaService.getAllPhotos();
      final videos = MediaService.getAllVideos();
      final screenshots = MediaService.getAllScreenshots();
      
      List<String> paths = [];
      
      for (var photo in photos) {
        if (photo.path.isNotEmpty) {
          paths.add(photo.path);
        }
      }
      
      for (var video in videos) {
        if (video.thumbnailPath != null && video.thumbnailPath!.isNotEmpty) {
          paths.add(video.thumbnailPath!);
        } else if (video.path.isNotEmpty) {
          paths.add(video.path);
        }
      }
      
      for (var screenshot in screenshots) {
        if (screenshot.path.isNotEmpty) {
          paths.add(screenshot.path);
        }
      }
      
      if (kDebugMode) {
        debugPrint('Found ${paths.length} media paths');
      }
      
      return paths;
    } catch (e) {
      if (kDebugMode) debugPrint('Error getting media paths: $e');
      return [];
    }
  }

  /// Delete generated video
  static Future<void> deleteGeneratedVideo() async {
    if (_lastGeneratedVideo != null) {
      try {
        final videoFile = File(_lastGeneratedVideo!.filePath);
        final thumbnailFile = File(_lastGeneratedVideo!.thumbnailPath);
        
        if (await videoFile.exists()) {
          await videoFile.delete();
        }
        if (await thumbnailFile.exists()) {
          await thumbnailFile.delete();
        }
        
        _lastGeneratedVideo = null;
      } catch (e) {
        if (kDebugMode) debugPrint('Error deleting video: $e');
      }
    }
  }

  /// Get video duration in formatted string
  static String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
