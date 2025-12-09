import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import '../services/music_service.dart';


/// Video style effects - Premium Styles (15 Best Styles)
enum VideoStyle {
  cinematic,   // Hollywood-style look
  epic,        // Dramatic & powerful
  romantic,    // Soft & dreamy
  vintage,     // Classic retro look
  neon,        // Vibrant neon glow
  minimal,     // Clean & elegant
  party,       // Fun & energetic
  nature,      // Calm & peaceful
  travel,      // Adventure style
  story,       // Narrative style
  // NEW 5 STYLES (User Requested)
  wedding,     // Shaadi ki yaadein
  birthday,    // Birthday celebration
  family,      // Ghar ki yaadein
  dosti,       // Dosti ke pal
  islamic,     // Deeni yaadein
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
  final bool isRealVideo; // true if actual MP4, false if slideshow

  GeneratedVideo({
    required this.filePath,
    required this.thumbnailPath,
    required this.durationSeconds,
    required this.style,
    this.backgroundMusic,
    required this.photoCount,
    required this.createdAt,
    required this.imagePaths,
    this.isRealVideo = false,
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

/// Video Generator Service - Creates video slideshows from photos
class VideoGeneratorService {
  static GeneratedVideo? _lastGeneratedVideo;
  static bool _isGenerating = false;
  
  static GeneratedVideo? get lastGeneratedVideo => _lastGeneratedVideo;
  static bool get isGenerating => _isGenerating;

  // Demo image URLs for when user has no photos
  static const List<String> _demoImages = [
    'https://picsum.photos/1280/720?random=1',
    'https://picsum.photos/1280/720?random=2',
    'https://picsum.photos/1280/720?random=3',
    'https://picsum.photos/1280/720?random=4',
    'https://picsum.photos/1280/720?random=5',
    'https://picsum.photos/1280/720?random=6',
    'https://picsum.photos/1280/720?random=7',
    'https://picsum.photos/1280/720?random=8',
  ];

  /// Generate a video slideshow from photos
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

      // Temp directory for processing
      final tempDir = Directory('${directory.path}/temp_video');
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
      await tempDir.create(recursive: true);

      onProgress?.call(10, 'Processing ${finalImagePaths.length} photos...');

      // Download/copy images to temp directory
      List<String> processedImages = [];
      for (int i = 0; i < finalImagePaths.length; i++) {
        final progress = 10 + ((i / finalImagePaths.length) * 60).toInt();
        onProgress?.call(progress, 'Processing image ${i + 1}/${finalImagePaths.length}...');
        
        final imagePath = finalImagePaths[i];
        final outputPath = '${tempDir.path}/img_${i.toString().padLeft(4, '0')}.jpg';
        
        try {
          if (imagePath.startsWith('http')) {
            // Download from URL
            final response = await http.get(Uri.parse(imagePath)).timeout(
              const Duration(seconds: 30),
            );
            if (response.statusCode == 200) {
              await File(outputPath).writeAsBytes(response.bodyBytes);
              processedImages.add(outputPath);
            }
          } else {
            // Copy local file
            final sourceFile = File(imagePath);
            if (await sourceFile.exists()) {
              await sourceFile.copy(outputPath);
              processedImages.add(outputPath);
            }
          }
        } catch (e) {
          if (kDebugMode) debugPrint('Error processing image $i: $e');
        }
      }

      if (processedImages.isEmpty) {
        _isGenerating = false;
        return null;
      }

      // Create unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final videoFileName = 'memory_slideshow_$timestamp.slideshow';
      final thumbnailFileName = 'thumbnail_$timestamp.jpg';
      
      final videoPath = '${videoDir.path}/$videoFileName';
      final thumbnailPath = '${videoDir.path}/$thumbnailFileName';

      onProgress?.call(75, 'Creating slideshow with ${_getStyleName(style)} style...');

      // Save slideshow metadata (list of image paths)
      final slideshowData = processedImages.join('\n');
      await File(videoPath).writeAsString(slideshowData);

      onProgress?.call(90, 'Creating thumbnail...');

      // Create thumbnail from first image
      if (processedImages.isNotEmpty) {
        try {
          await File(processedImages[0]).copy(thumbnailPath);
        } catch (e) {
          if (kDebugMode) debugPrint('Error creating thumbnail: $e');
        }
      }

      onProgress?.call(100, 'Video created successfully!');

      _lastGeneratedVideo = GeneratedVideo(
        filePath: videoPath,
        thumbnailPath: thumbnailPath,
        durationSeconds: durationSeconds,
        style: style,
        backgroundMusic: backgroundMusic,
        photoCount: processedImages.length,
        createdAt: DateTime.now(),
        imagePaths: processedImages,
        isRealVideo: false, // This is a slideshow
      );

      _isGenerating = false;
      
      if (kDebugMode) {
        debugPrint('Slideshow generated successfully at: $videoPath');
        debugPrint('Photo count: ${processedImages.length}');
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
      if (Platform.isAndroid) {
        var photosStatus = await Permission.photos.status;
        if (!photosStatus.isGranted) {
          photosStatus = await Permission.photos.request();
        }
        
        var storageStatus = await Permission.storage.status;
        if (!storageStatus.isGranted) {
          storageStatus = await Permission.storage.request();
        }
        
        var manageStatus = await Permission.manageExternalStorage.status;
        if (!manageStatus.isGranted && !manageStatus.isPermanentlyDenied) {
          manageStatus = await Permission.manageExternalStorage.request();
        }
        
        return photosStatus.isGranted || storageStatus.isGranted || manageStatus.isGranted;
      }
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('Permission error: $e');
      return true;
    }
  }

  /// Get the best download directory path
  static Future<String?> _getDownloadDirectory() async {
    try {
      if (Platform.isAndroid) {
        final List<String> possiblePaths = [];
        
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) {
          final downloadPath = '${extDir.parent.parent.parent.parent.path}/Download';
          possiblePaths.add(downloadPath);
          
          final picturesPath = '${extDir.parent.parent.parent.parent.path}/Pictures';
          possiblePaths.add(picturesPath);
          
          final dcimPath = '${extDir.parent.parent.parent.parent.path}/DCIM';
          possiblePaths.add(dcimPath);
        }
        
        final appExtDir = await getExternalStorageDirectory();
        if (appExtDir != null) {
          possiblePaths.add(appExtDir.path);
        }
        
        for (String path in possiblePaths) {
          try {
            final dir = Directory(path);
            if (await dir.exists()) {
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
        
        final appDir = await getApplicationDocumentsDirectory();
        if (kDebugMode) debugPrint('Using fallback path: ${appDir.path}');
        return appDir.path;
      }
      
      final dir = await getApplicationDocumentsDirectory();
      return dir.path;
    } catch (e) {
      if (kDebugMode) debugPrint('Error getting download directory: $e');
      return null;
    }
  }

  /// Save generated slideshow images to Downloads folder
  static Future<SaveResult> saveVideoToDownloads(GeneratedVideo video, {
    Function(int progress, String status)? onProgress,
  }) async {
    try {
      onProgress?.call(10, 'Requesting permissions...');
      await _requestStoragePermission();
      
      onProgress?.call(30, 'Finding save location...');
      final basePath = await _getDownloadDirectory();
      if (basePath == null) {
        return SaveResult(
          success: false,
          message: 'Storage access denied. Check permissions.',
          savedCount: 0,
          totalCount: video.imagePaths.length,
        );
      }
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final folderName = 'Memories_2025_$timestamp';
      final saveDir = Directory('$basePath/$folderName');
      
      if (!await saveDir.exists()) {
        await saveDir.create(recursive: true);
      }
      
      onProgress?.call(40, 'Saving ${video.imagePaths.length} photos...');
      
      int savedCount = 0;
      for (int i = 0; i < video.imagePaths.length; i++) {
        final progress = 40 + ((i / video.imagePaths.length) * 55).toInt();
        onProgress?.call(progress, 'Saving photo ${i + 1}/${video.imagePaths.length}...');
        
        try {
          final sourceFile = File(video.imagePaths[i]);
          if (await sourceFile.exists()) {
            final fileName = 'Memory_${i + 1}.jpg';
            final destPath = '${saveDir.path}/$fileName';
            await sourceFile.copy(destPath);
            savedCount++;
          }
        } catch (e) {
          if (kDebugMode) debugPrint('Error saving image $i: $e');
        }
      }
      
      onProgress?.call(100, 'Photos saved!');
      
      if (savedCount > 0) {
        return SaveResult(
          success: true,
          savedPath: saveDir.path,
          message: '$savedCount photos saved to $folderName',
          savedCount: savedCount,
          totalCount: video.imagePaths.length,
        );
      } else {
        return SaveResult(
          success: false,
          message: 'Failed to save photos',
          savedCount: 0,
          totalCount: video.imagePaths.length,
        );
      }
      
    } catch (e) {
      if (kDebugMode) debugPrint('Save error: $e');
      return SaveResult(
        success: false,
        message: 'Error: ${e.toString()}',
        savedCount: 0,
        totalCount: video.imagePaths.length,
      );
    }
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
      case VideoStyle.wedding:
        return 'Wedding';
      case VideoStyle.birthday:
        return 'Birthday';
      case VideoStyle.family:
        return 'Family';
      case VideoStyle.dosti:
        return 'Dosti';
      case VideoStyle.islamic:
        return 'Islamic';
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
      case 'wedding':
        return VideoStyle.wedding;
      case 'birthday':
        return VideoStyle.birthday;
      case 'family':
        return VideoStyle.family;
      case 'dosti':
        return VideoStyle.dosti;
      case 'islamic':
        return VideoStyle.islamic;
      default:
        return VideoStyle.cinematic;
    }
  }
  
  /// Get style description
  static String getStyleDescription(VideoStyle style) {
    switch (style) {
      case VideoStyle.cinematic:
        return 'Hollywood-style with vignette and color grade';
      case VideoStyle.epic:
        return 'High contrast, dramatic look';
      case VideoStyle.romantic:
        return 'Soft glow with warm pink tones';
      case VideoStyle.vintage:
        return 'Classic sepia tone';
      case VideoStyle.neon:
        return 'Vibrant, high saturation colors';
      case VideoStyle.minimal:
        return 'Clean and simple, perfectly clear';
      case VideoStyle.party:
        return 'Bright and colorful celebration';
      case VideoStyle.nature:
        return 'Calm green tones';
      case VideoStyle.travel:
        return 'Warm adventure look';
      case VideoStyle.story:
        return 'Letterbox cinematic format';
      case VideoStyle.wedding:
        return 'Soft white, elegant, golden glow';
      case VideoStyle.birthday:
        return 'Colorful, festive, party vibes';
      case VideoStyle.family:
        return 'Warm, nostalgic, cozy feel';
      case VideoStyle.dosti:
        return 'Fun, energetic, bright colors';
      case VideoStyle.islamic:
        return 'Peaceful, elegant, green tones';
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
