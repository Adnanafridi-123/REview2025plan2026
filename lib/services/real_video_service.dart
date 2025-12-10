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

/// Video style effects
enum VideoStyle {
  cinematic, epic, romantic, vintage, neon, minimal, party, nature, travel, story,
  wedding, birthday, family, dosti, islamic,
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
  final String outputType;

  GeneratedVideo({
    required this.filePath,
    required this.thumbnailPath,
    required this.durationSeconds,
    required this.style,
    this.backgroundMusic,
    required this.photoCount,
    required this.createdAt,
    required this.imagePaths,
    this.isRealVideo = true,
    this.outputType = 'gif',
  });
}

/// Save result
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

/// REAL VIDEO SERVICE - Creates animated GIF videos
/// GIF format is universally supported and plays like video
class RealVideoService {
  static GeneratedVideo? _lastGeneratedVideo;
  static bool _isGenerating = false;
  
  static GeneratedVideo? get lastGeneratedVideo => _lastGeneratedVideo;
  static bool get isGenerating => _isGenerating;
  
  // Output settings - optimized for quality and speed
  static const int _outputWidth = 480;
  static const int _outputHeight = 854; // 9:16 aspect ratio
  static const int _fps = 4; // Frames per second for GIF
  
  // Demo images
  static const List<String> _demoImages = [
    'https://picsum.photos/480/854?random=1',
    'https://picsum.photos/480/854?random=2',
    'https://picsum.photos/480/854?random=3',
    'https://picsum.photos/480/854?random=4',
    'https://picsum.photos/480/854?random=5',
  ];

  /// Generate REAL Animated GIF Video
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
      onProgress?.call(5, 'Video shuru ho rahi hai...');
      
      // Use demo images if no photos
      List<String> finalImagePaths = imagePaths.isNotEmpty ? imagePaths : _demoImages;
      
      // Limit images to prevent memory issues
      if (finalImagePaths.length > 12) {
        finalImagePaths = finalImagePaths.sublist(0, 12);
      }

      // Get directories
      final directory = await getApplicationDocumentsDirectory();
      final videoDir = Directory('${directory.path}/generated_videos');
      if (!await videoDir.exists()) await videoDir.create(recursive: true);

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final videoPath = '${videoDir.path}/memory_video_$timestamp.gif';
      final thumbnailPath = '${videoDir.path}/thumbnail_$timestamp.jpg';

      onProgress?.call(10, 'Photos load ho rahi hain...');

      // Process images
      List<img.Image> processedImages = [];
      
      for (int i = 0; i < finalImagePaths.length; i++) {
        final progress = 10 + ((i / finalImagePaths.length) * 50).toInt();
        onProgress?.call(progress, 'Photo ${i + 1}/${finalImagePaths.length} process ho rahi hai...');
        
        try {
          Uint8List? imageBytes;
          
          if (finalImagePaths[i].startsWith('http')) {
            final response = await http.get(Uri.parse(finalImagePaths[i])).timeout(
              const Duration(seconds: 12),
            );
            if (response.statusCode == 200) {
              imageBytes = response.bodyBytes;
            }
          } else {
            final file = File(finalImagePaths[i]);
            if (await file.exists()) {
              imageBytes = await file.readAsBytes();
            }
          }
          
          if (imageBytes != null) {
            final decoded = img.decodeImage(imageBytes);
            if (decoded != null) {
              // Resize
              final resized = img.copyResize(
                decoded,
                width: _outputWidth,
                height: _outputHeight,
                interpolation: img.Interpolation.linear,
              );
              
              // Apply style
              final styled = _applyStyleFilter(resized, style);
              processedImages.add(styled);
              
              // Thumbnail
              if (i == 0) {
                await File(thumbnailPath).writeAsBytes(img.encodeJpg(styled, quality: 85));
              }
            }
          }
        } catch (e) {
          if (kDebugMode) debugPrint('Error processing image $i: $e');
        }
        
        await Future.delayed(const Duration(milliseconds: 30));
      }

      if (processedImages.isEmpty) {
        _isGenerating = false;
        return null;
      }

      onProgress?.call(65, 'Video ban rahi hai...');

      // Calculate frames per image based on duration
      final totalFrames = durationSeconds * _fps;
      final framesPerImage = (totalFrames / processedImages.length).ceil();
      final frameDelay = (100 / _fps).round(); // Delay in 1/100th of second

      // Create GIF encoder
      final encoder = img.GifEncoder(repeat: 0); // Loop forever
      
      onProgress?.call(70, 'Frames add ho rahe hain...');

      for (int imgIndex = 0; imgIndex < processedImages.length; imgIndex++) {
        final progress = 70 + ((imgIndex / processedImages.length) * 25).toInt();
        onProgress?.call(progress, 'Frame ${imgIndex + 1}/${processedImages.length} encode ho raha hai...');
        
        final currentImage = processedImages[imgIndex];
        
        // Add frames for this image (creates slideshow effect)
        for (int f = 0; f < framesPerImage; f++) {
          encoder.addFrame(currentImage, duration: frameDelay);
        }
        
        // Memory management
        if (imgIndex % 3 == 0) {
          await Future.delayed(const Duration(milliseconds: 20));
        }
      }
      
      onProgress?.call(96, 'Video save ho rahi hai...');

      // Encode and save GIF
      final gifBytes = encoder.finish();
      if (gifBytes != null) {
        await File(videoPath).writeAsBytes(gifBytes);
        
        // Verify file created
        final videoFile = File(videoPath);
        if (await videoFile.exists()) {
          final fileSize = await videoFile.length();
          if (kDebugMode) {
            debugPrint('Video created! Size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');
          }

          onProgress?.call(100, 'Video tayar hai! 🎬');

          _lastGeneratedVideo = GeneratedVideo(
            filePath: videoPath,
            thumbnailPath: thumbnailPath,
            durationSeconds: durationSeconds,
            style: style,
            backgroundMusic: backgroundMusic,
            photoCount: processedImages.length,
            createdAt: DateTime.now(),
            imagePaths: finalImagePaths,
            isRealVideo: true,
            outputType: 'gif',
          );
          
          await _incrementVideosCreated();
          _isGenerating = false;
          return _lastGeneratedVideo;
        }
      }
      
      _isGenerating = false;
      return null;

    } catch (e) {
      if (kDebugMode) debugPrint('Error generating video: $e');
      _isGenerating = false;
      return null;
    }
  }

  /// Apply style filter
  static img.Image _applyStyleFilter(img.Image image, VideoStyle style) {
    switch (style) {
      case VideoStyle.cinematic:
        img.adjustColor(image, saturation: 0.9, contrast: 1.1);
        img.vignette(image, start: 0.4, end: 0.9);
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

  /// Save video to Downloads folder
  static Future<SaveResult> saveVideoToGallery(GeneratedVideo video, {
    Function(int progress, String status)? onProgress,
  }) async {
    try {
      onProgress?.call(10, 'Permission check ho raha hai...');
      
      // Request permissions
      await [
        Permission.photos,
        Permission.storage,
        Permission.manageExternalStorage,
      ].request();

      onProgress?.call(30, 'Video save ho rahi hai...');

      final videoFile = File(video.filePath);
      if (!await videoFile.exists()) {
        return SaveResult(
          success: false,
          message: 'Video file nahi mili!',
        );
      }

      // Get Downloads directory
      final extDir = await getExternalStorageDirectory();
      if (extDir != null) {
        final basePath = extDir.parent.parent.parent.parent.path;
        
        // Try multiple locations
        final locations = [
          '$basePath/Download',
          '$basePath/Pictures',
          '$basePath/DCIM',
          '$basePath/Movies',
        ];

        for (final location in locations) {
          try {
            final dir = Directory(location);
            if (await dir.exists()) {
              final timestamp = DateTime.now().millisecondsSinceEpoch;
              final destPath = '$location/Memory_Video_$timestamp.gif';
              
              onProgress?.call(60, 'Video copy ho rahi hai...');
              await videoFile.copy(destPath);
              
              // Verify
              final destFile = File(destPath);
              if (await destFile.exists()) {
                final size = await destFile.length();
                final sizeMB = (size / 1024 / 1024).toStringAsFixed(2);
                
                onProgress?.call(100, 'Video save ho gayi! 🎬');
                
                return SaveResult(
                  success: true,
                  savedPath: destPath,
                  message: 'Video save ho gayi! 🎬\nSize: $sizeMB MB\nFolder: ${location.split('/').last}',
                  savedCount: 1,
                  totalCount: 1,
                );
              }
            }
          } catch (e) {
            continue;
          }
        }
      }

      // Fallback: App documents
      final appDir = await getApplicationDocumentsDirectory();
      final fallbackPath = '${appDir.path}/Memory_Video_${DateTime.now().millisecondsSinceEpoch}.gif';
      await videoFile.copy(fallbackPath);
      
      return SaveResult(
        success: true,
        savedPath: fallbackPath,
        message: 'Video app folder mein save ho gayi!',
        savedCount: 1,
        totalCount: 1,
      );

    } catch (e) {
      if (kDebugMode) debugPrint('Save error: $e');
      return SaveResult(
        success: false,
        message: 'Error: ${e.toString().split('\n').first}',
      );
    }
  }

  /// Get style name
  static String getStyleName(VideoStyle style) {
    switch (style) {
      case VideoStyle.cinematic: return 'Cinematic';
      case VideoStyle.epic: return 'Epic';
      case VideoStyle.romantic: return 'Romantic';
      case VideoStyle.vintage: return 'Vintage';
      case VideoStyle.neon: return 'Neon';
      case VideoStyle.minimal: return 'Minimal';
      case VideoStyle.party: return 'Party';
      case VideoStyle.nature: return 'Nature';
      case VideoStyle.travel: return 'Travel';
      case VideoStyle.story: return 'Story';
      case VideoStyle.wedding: return 'Wedding';
      case VideoStyle.birthday: return 'Birthday';
      case VideoStyle.family: return 'Family';
      case VideoStyle.dosti: return 'Dosti';
      case VideoStyle.islamic: return 'Islamic';
    }
  }

  /// Get style from name
  static VideoStyle getStyleFromName(String name) {
    switch (name.toLowerCase()) {
      case 'cinematic': return VideoStyle.cinematic;
      case 'epic': return VideoStyle.epic;
      case 'romantic': return VideoStyle.romantic;
      case 'vintage': return VideoStyle.vintage;
      case 'neon': return VideoStyle.neon;
      case 'minimal': return VideoStyle.minimal;
      case 'party': return VideoStyle.party;
      case 'nature': return VideoStyle.nature;
      case 'travel': return VideoStyle.travel;
      case 'story': return VideoStyle.story;
      case 'wedding': return VideoStyle.wedding;
      case 'birthday': return VideoStyle.birthday;
      case 'family': return VideoStyle.family;
      case 'dosti': return VideoStyle.dosti;
      case 'islamic': return VideoStyle.islamic;
      default: return VideoStyle.cinematic;
    }
  }

  static String getStyleDescription(VideoStyle style) {
    switch (style) {
      case VideoStyle.cinematic: return 'Hollywood-style';
      case VideoStyle.epic: return 'Dramatic & powerful';
      case VideoStyle.romantic: return 'Soft & dreamy';
      case VideoStyle.vintage: return 'Classic sepia';
      case VideoStyle.neon: return 'Vibrant glow';
      case VideoStyle.minimal: return 'Clean & elegant';
      case VideoStyle.party: return 'Bright & colorful';
      case VideoStyle.nature: return 'Calm green';
      case VideoStyle.travel: return 'Adventure style';
      case VideoStyle.story: return 'Narrative';
      case VideoStyle.wedding: return 'Shaadi ki yaadein';
      case VideoStyle.birthday: return 'Birthday celebration';
      case VideoStyle.family: return 'Ghar ki yaadein';
      case VideoStyle.dosti: return 'Dosti ke pal';
      case VideoStyle.islamic: return 'Deeni yaadein';
    }
  }

  static String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  static Future<void> deleteGeneratedVideo() async {
    if (_lastGeneratedVideo != null) {
      try {
        final file = File(_lastGeneratedVideo!.filePath);
        if (await file.exists()) await file.delete();
        final thumb = File(_lastGeneratedVideo!.thumbnailPath);
        if (await thumb.exists()) await thumb.delete();
        _lastGeneratedVideo = null;
      } catch (e) {
        if (kDebugMode) debugPrint('Error deleting: $e');
      }
    }
  }

  static Future<void> _incrementVideosCreated() async {
    try {
      final box = await Hive.openBox('video_stats');
      final count = box.get('videos_created', defaultValue: 0);
      await box.put('videos_created', count + 1);
    } catch (e) {
      // Ignore
    }
  }

  static Future<int> getVideosCreatedCount() async {
    try {
      final box = await Hive.openBox('video_stats');
      return box.get('videos_created', defaultValue: 0);
    } catch (e) {
      return 0;
    }
  }
}
