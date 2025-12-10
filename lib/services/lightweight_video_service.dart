import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;
import 'package:hive/hive.dart';
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
  final bool isRealVideo;
  final String outputType; // 'slideshow', 'images'

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
    this.outputType = 'slideshow',
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

/// ULTRA-LIGHTWEIGHT Video Generator Service
/// NO GIF ENCODING - Just processes and saves images quickly
/// This approach is CRASH-FREE and memory efficient
class LightweightVideoService {
  static GeneratedVideo? _lastGeneratedVideo;
  static bool _isGenerating = false;
  
  static GeneratedVideo? get lastGeneratedVideo => _lastGeneratedVideo;
  static bool get isGenerating => _isGenerating;
  
  // Output settings - smaller for faster processing
  static const int _outputWidth = 540;  // Reduced for speed
  static const int _outputHeight = 960; // 9:16 aspect ratio
  static const int _maxImages = 20;     // Limit images to prevent memory issues
  
  // Demo image URLs for when user has no photos
  static const List<String> _demoImages = [
    'https://picsum.photos/540/960?random=1',
    'https://picsum.photos/540/960?random=2',
    'https://picsum.photos/540/960?random=3',
    'https://picsum.photos/540/960?random=4',
    'https://picsum.photos/540/960?random=5',
    'https://picsum.photos/540/960?random=6',
  ];

  /// Generate a lightweight slideshow (processed images only - NO ENCODING)
  /// This method is CRASH-FREE and memory efficient
  static Future<GeneratedVideo?> generateVideo({
    required List<String> imagePaths,
    required VideoStyle style,
    required int durationSeconds,
    MusicTrack? backgroundMusic,
    Function(int progress, String status)? onProgress,
  }) async {
    if (_isGenerating) {
      if (kDebugMode) debugPrint('Already generating');
      return null;
    }

    _isGenerating = true;

    try {
      onProgress?.call(5, 'Shuru ho raha hai...');
      
      // Use demo images if no photos provided
      List<String> finalImagePaths = imagePaths.isNotEmpty ? imagePaths : _demoImages;
      
      // Limit number of images to prevent memory issues
      if (finalImagePaths.length > _maxImages) {
        finalImagePaths = finalImagePaths.sublist(0, _maxImages);
      }
      
      if (kDebugMode) {
        debugPrint('Creating slideshow from ${finalImagePaths.length} images');
      }

      // Get app directory for saving
      final directory = await getApplicationDocumentsDirectory();
      final videoDir = Directory('${directory.path}/generated_videos');
      if (!await videoDir.exists()) {
        await videoDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final slideshowPath = '${videoDir.path}/memory_slideshow_$timestamp';
      final thumbnailPath = '${videoDir.path}/thumbnail_$timestamp.jpg';
      
      // Create slideshow directory
      final slideshowDir = Directory(slideshowPath);
      await slideshowDir.create(recursive: true);

      onProgress?.call(10, 'Photos load ho rahe hain...');

      // Process images one by one (memory efficient)
      List<String> savedPaths = [];
      Uint8List? thumbnailBytes;
      
      for (int i = 0; i < finalImagePaths.length; i++) {
        final progress = 10 + ((i / finalImagePaths.length) * 80).toInt();
        onProgress?.call(progress, 'Photo ${i + 1}/${finalImagePaths.length} process ho rahi hai...');
        
        final imagePath = finalImagePaths[i];
        
        try {
          Uint8List? imageBytes;
          
          if (imagePath.startsWith('http')) {
            // Download from URL with timeout
            final response = await http.get(Uri.parse(imagePath)).timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                throw TimeoutException('Image download timeout');
              },
            );
            if (response.statusCode == 200) {
              imageBytes = response.bodyBytes;
            }
          } else {
            // Load from file
            final sourceFile = File(imagePath);
            if (await sourceFile.exists()) {
              imageBytes = await sourceFile.readAsBytes();
            }
          }
          
          if (imageBytes != null) {
            // Decode image
            final decodedImage = img.decodeImage(imageBytes);
            if (decodedImage != null) {
              // Resize to target dimensions
              final resizedImage = img.copyResize(
                decodedImage,
                width: _outputWidth,
                height: _outputHeight,
                interpolation: img.Interpolation.linear,
              );
              
              // Apply style filter
              final styledImage = _applyStyleFilter(resizedImage, style);
              
              // Save processed image
              final outputPath = '$slideshowPath/frame_${i.toString().padLeft(3, '0')}.jpg';
              final processedBytes = img.encodeJpg(styledImage, quality: 85);
              await File(outputPath).writeAsBytes(processedBytes);
              savedPaths.add(outputPath);
              
              // Save first image as thumbnail
              if (i == 0) {
                thumbnailBytes = processedBytes;
                await File(thumbnailPath).writeAsBytes(processedBytes);
              }
              
              // Clear memory
              imageBytes = null;
            }
          }
        } catch (e) {
          if (kDebugMode) debugPrint('Error processing image $i: $e');
          // Continue with other images - don't crash!
        }
        
        // Small delay to prevent memory overload
        await Future.delayed(const Duration(milliseconds: 30));
      }

      if (savedPaths.isEmpty) {
        if (kDebugMode) debugPrint('No images could be processed');
        _isGenerating = false;
        return null;
      }

      onProgress?.call(95, 'Finalize ho raha hai...');

      // Verify output
      final outputDir = Directory(slideshowPath);
      if (!await outputDir.exists()) {
        if (kDebugMode) debugPrint('Output directory not created');
        _isGenerating = false;
        return null;
      }

      onProgress?.call(100, 'Slideshow tayar hai! ✨');

      _lastGeneratedVideo = GeneratedVideo(
        filePath: slideshowPath,
        thumbnailPath: thumbnailPath,
        durationSeconds: durationSeconds,
        style: style,
        backgroundMusic: backgroundMusic,
        photoCount: savedPaths.length,
        createdAt: DateTime.now(),
        imagePaths: savedPaths,
        isRealVideo: false,
        outputType: 'slideshow',
      );
      
      // Track videos created count for statistics
      await _incrementVideosCreated();

      _isGenerating = false;
      return _lastGeneratedVideo;

    } catch (e) {
      if (kDebugMode) debugPrint('Error generating video: $e');
      _isGenerating = false;
      return null;
    }
  }

  /// Apply style filter to image - OPTIMIZED for speed
  static img.Image _applyStyleFilter(img.Image image, VideoStyle style) {
    switch (style) {
      case VideoStyle.cinematic:
        img.adjustColor(image, saturation: 0.9, contrast: 1.1);
        return image;
        
      case VideoStyle.epic:
        img.adjustColor(image, contrast: 1.25, saturation: 0.85);
        return image;
        
      case VideoStyle.romantic:
        img.adjustColor(image, saturation: 1.1, gamma: 1.1);
        img.colorOffset(image, red: 12, green: 5, blue: -3);
        return image;
        
      case VideoStyle.vintage:
        img.sepia(image);
        return image;
        
      case VideoStyle.neon:
        img.adjustColor(image, saturation: 1.4, contrast: 1.15);
        return image;
        
      case VideoStyle.minimal:
        // Clean, no changes needed
        return image;
        
      case VideoStyle.party:
        img.adjustColor(image, saturation: 1.25, brightness: 1.08);
        return image;
        
      case VideoStyle.nature:
        img.colorOffset(image, red: -8, green: 10, blue: -3);
        return image;
        
      case VideoStyle.travel:
        img.adjustColor(image, saturation: 1.12, contrast: 1.05);
        img.colorOffset(image, red: 8, green: 4, blue: -8);
        return image;
        
      case VideoStyle.story:
        img.adjustColor(image, contrast: 1.05);
        return image;
        
      case VideoStyle.wedding:
        img.adjustColor(image, brightness: 1.04, saturation: 0.95);
        img.colorOffset(image, red: 8, green: 6, blue: 0);
        return image;
        
      case VideoStyle.birthday:
        img.adjustColor(image, saturation: 1.2, brightness: 1.08);
        return image;
        
      case VideoStyle.family:
        img.adjustColor(image, saturation: 0.95, gamma: 1.04);
        img.colorOffset(image, red: 6, green: 3, blue: -4);
        return image;
        
      case VideoStyle.dosti:
        img.adjustColor(image, saturation: 1.15, contrast: 1.08);
        return image;
        
      case VideoStyle.islamic:
        img.adjustColor(image, saturation: 0.9);
        img.colorOffset(image, red: -4, green: 8, blue: 4);
        return image;
    }
  }

  /// Request storage permissions
  static Future<bool> _requestStoragePermission() async {
    try {
      if (Platform.isAndroid) {
        // Request all relevant permissions
        final statuses = await [
          Permission.photos,
          Permission.storage,
          Permission.manageExternalStorage,
        ].request();
        
        return statuses.values.any((status) => status.isGranted);
      }
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('Permission error: $e');
      return true; // Assume permission granted to continue
    }
  }

  /// Get the best download directory path
  static Future<String?> _getDownloadDirectory() async {
    try {
      if (Platform.isAndroid) {
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) {
          final basePath = extDir.parent.parent.parent.parent.path;
          
          // Try paths in order of preference
          final paths = [
            '$basePath/Download',
            '$basePath/Pictures',
            '$basePath/DCIM',
            extDir.path,
          ];
          
          for (String path in paths) {
            try {
              final dir = Directory(path);
              if (await dir.exists()) {
                // Test write permission
                final testFile = File('$path/.test_${DateTime.now().millisecondsSinceEpoch}');
                await testFile.writeAsString('test');
                await testFile.delete();
                return path;
              }
            } catch (e) {
              continue;
            }
          }
        }
        
        // Fallback
        final appDir = await getApplicationDocumentsDirectory();
        return appDir.path;
      }
      
      final dir = await getApplicationDocumentsDirectory();
      return dir.path;
    } catch (e) {
      if (kDebugMode) debugPrint('Error getting download directory: $e');
      return null;
    }
  }

  /// Save generated slideshow to Downloads folder
  static Future<SaveResult> saveVideoToDownloads(GeneratedVideo video, {
    Function(int progress, String status)? onProgress,
  }) async {
    try {
      onProgress?.call(5, 'Permission check ho raha hai...');
      await _requestStoragePermission();
      
      onProgress?.call(15, 'Save location dhoond rahe hain...');
      final basePath = await _getDownloadDirectory();
      if (basePath == null) {
        return SaveResult(
          success: false,
          message: 'Storage access denied. Permission check karein.',
          savedCount: 0,
          totalCount: 1,
        );
      }
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final folderName = 'Memories_2025_$timestamp';
      final saveDir = Directory('$basePath/$folderName');
      
      if (!await saveDir.exists()) {
        await saveDir.create(recursive: true);
      }

      int savedCount = 0;
      
      onProgress?.call(30, 'Photos save ho rahi hain...');
      
      for (int i = 0; i < video.imagePaths.length; i++) {
        final progress = 30 + ((i / video.imagePaths.length) * 65).toInt();
        onProgress?.call(progress, 'Photo ${i + 1}/${video.imagePaths.length} save ho rahi hai...');
        
        try {
          final sourcePath = video.imagePaths[i];
          final fileName = 'Memory_${(i + 1).toString().padLeft(2, '0')}.jpg';
          final destPath = '${saveDir.path}/$fileName';
          
          final sourceFile = File(sourcePath);
          if (await sourceFile.exists()) {
            await sourceFile.copy(destPath);
            savedCount++;
          }
        } catch (e) {
          if (kDebugMode) debugPrint('Error saving image $i: $e');
          // Continue with other images - don't stop!
        }
      }
      
      onProgress?.call(100, 'Photos save ho gayi hain! ✨');
      
      if (savedCount > 0) {
        return SaveResult(
          success: true,
          savedPath: saveDir.path,
          message: '$savedCount photos save ho gayi hain!\nLocation: $folderName',
          savedCount: savedCount,
          totalCount: video.imagePaths.length,
        );
      } else {
        return SaveResult(
          success: false,
          message: 'Photos save nahi ho saki. Dobara try karein.',
          savedCount: 0,
          totalCount: video.imagePaths.length,
        );
      }
      
    } catch (e) {
      if (kDebugMode) debugPrint('Save error: $e');
      return SaveResult(
        success: false,
        message: 'Error: ${e.toString().split('\n').first}',
        savedCount: 0,
        totalCount: video.imagePaths.length,
      );
    }
  }

  /// Get style display name
  static String getStyleName(VideoStyle style) {
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
  
  /// Get style description
  static String getStyleDescription(VideoStyle style) {
    switch (style) {
      case VideoStyle.cinematic:
        return 'Hollywood-style with vignette';
      case VideoStyle.epic:
        return 'Dramatic & powerful';
      case VideoStyle.romantic:
        return 'Soft & dreamy';
      case VideoStyle.vintage:
        return 'Classic sepia tone';
      case VideoStyle.neon:
        return 'Vibrant neon glow';
      case VideoStyle.minimal:
        return 'Clean & elegant';
      case VideoStyle.party:
        return 'Bright & colorful';
      case VideoStyle.nature:
        return 'Calm green tones';
      case VideoStyle.travel:
        return 'Adventure style';
      case VideoStyle.story:
        return 'Narrative style';
      case VideoStyle.wedding:
        return 'Shaadi ki yaadein';
      case VideoStyle.birthday:
        return 'Birthday celebration';
      case VideoStyle.family:
        return 'Ghar ki yaadein';
      case VideoStyle.dosti:
        return 'Dosti ke pal';
      case VideoStyle.islamic:
        return 'Deeni yaadein';
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

  /// Delete generated video
  static Future<void> deleteGeneratedVideo() async {
    if (_lastGeneratedVideo != null) {
      try {
        final dir = Directory(_lastGeneratedVideo!.filePath);
        if (await dir.exists()) await dir.delete(recursive: true);
        
        final thumbnailFile = File(_lastGeneratedVideo!.thumbnailPath);
        if (await thumbnailFile.exists()) await thumbnailFile.delete();
        
        _lastGeneratedVideo = null;
      } catch (e) {
        if (kDebugMode) debugPrint('Error deleting video: $e');
      }
    }
  }

  /// Format duration
  static String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
  
  /// Increment videos created count for statistics
  static Future<void> _incrementVideosCreated() async {
    try {
      final box = await Hive.openBox('video_stats');
      final currentCount = box.get('videos_created', defaultValue: 0);
      await box.put('videos_created', currentCount + 1);
      if (kDebugMode) {
        debugPrint('Videos created count: ${currentCount + 1}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error tracking video count: $e');
    }
  }
  
  /// Get videos created count
  static Future<int> getVideosCreatedCount() async {
    try {
      final box = await Hive.openBox('video_stats');
      return box.get('videos_created', defaultValue: 0);
    } catch (e) {
      return 0;
    }
  }
}
