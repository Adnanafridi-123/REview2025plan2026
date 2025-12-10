import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hive/hive.dart';
import 'package:flutter_quick_video_encoder/flutter_quick_video_encoder.dart';
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
    this.outputType = 'mp4',
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

/// REAL MP4 VIDEO SERVICE - Uses Native Hardware Encoder
/// 
/// Key Features:
/// 1. Native h264 encoder (MediaCodec on Android)
/// 2. No FFmpeg - lightweight and fast
/// 3. Memory efficient - processes one frame at a time
/// 4. Real MP4 output - plays in gallery, shareable
class RealVideoService {
  static GeneratedVideo? _lastGeneratedVideo;
  static bool _isGenerating = false;
  
  static GeneratedVideo? get lastGeneratedVideo => _lastGeneratedVideo;
  static bool get isGenerating => _isGenerating;
  
  // Video settings - optimized for mobile
  static const int _videoWidth = 720;
  static const int _videoHeight = 1280;
  static const int _fps = 1; // 1 frame per second for slideshow
  static const int _videoBitrate = 2000000; // 2 Mbps
  static const int _maxImages = 15;

  /// Generate REAL MP4 Video using native encoder
  static Future<GeneratedVideo?> generateVideo({
    required List<String> imagePaths,
    required VideoStyle style,
    required int durationSeconds,
    MusicTrack? backgroundMusic,
    Function(int progress, String status)? onProgress,
  }) async {
    if (_isGenerating) {
      if (kDebugMode) debugPrint('Already generating...');
      return null;
    }

    _isGenerating = true;

    try {
      onProgress?.call(5, 'Video shuru ho raha hai...');
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Limit images
      List<String> finalPaths = imagePaths;
      if (finalPaths.length > _maxImages) {
        finalPaths = finalPaths.sublist(0, _maxImages);
        onProgress?.call(8, 'Maximum $_maxImages photos use ho rahi hain');
      }
      
      if (finalPaths.isEmpty) {
        _isGenerating = false;
        return null;
      }

      onProgress?.call(10, 'Video file setup ho raha hai...');

      // Get output directory
      final directory = await getApplicationDocumentsDirectory();
      final videoDir = Directory('${directory.path}/videos');
      if (!await videoDir.exists()) {
        await videoDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final styleName = getStyleName(style).toLowerCase();
      final outputPath = '${videoDir.path}/memory_${styleName}_$timestamp.mp4';
      final thumbnailPath = '${videoDir.path}/thumb_$timestamp.jpg';

      onProgress?.call(15, 'Encoder setup ho raha hai...');

      // Calculate frames needed
      // Each image shows for (durationSeconds / imageCount) seconds
      final secondsPerImage = (durationSeconds / finalPaths.length).ceil();
      final framesPerImage = secondsPerImage * _fps;
      // Total frames: finalPaths.length * framesPerImage

      // Setup video encoder
      try {
        await FlutterQuickVideoEncoder.setup(
          width: _videoWidth,
          height: _videoHeight,
          fps: _fps,
          videoBitrate: _videoBitrate,
          profileLevel: ProfileLevel.any,
          audioChannels: 0, // No audio for now (simpler)
          audioBitrate: 0,
          sampleRate: 0,
          filepath: outputPath,
        );
      } catch (e) {
        if (kDebugMode) debugPrint('Encoder setup failed: $e');
        _isGenerating = false;
        onProgress?.call(0, 'Encoder setup fail: $e');
        return null;
      }

      onProgress?.call(20, 'Photos process ho rahi hain...');

      // Process each image and add frames
      bool firstImageSaved = false;
      
      for (int i = 0; i < finalPaths.length; i++) {
        final progress = 20 + ((i / finalPaths.length) * 70).toInt();
        onProgress?.call(progress, 'Photo ${i + 1}/${finalPaths.length} encode ho rahi hai...');
        
        try {
          // Load and convert image to RGBA
          final rgbaData = await _loadImageAsRGBA(finalPaths[i], style);
          
          if (rgbaData != null) {
            // Save first image as thumbnail
            if (!firstImageSaved) {
              await _saveThumbnail(finalPaths[i], thumbnailPath);
              firstImageSaved = true;
            }
            
            // Add multiple frames for this image (to create duration)
            for (int f = 0; f < framesPerImage; f++) {
              await FlutterQuickVideoEncoder.appendVideoFrame(rgbaData);
              
              // Small delay to prevent overwhelming
              if (f % 5 == 0) {
                await Future.delayed(const Duration(milliseconds: 10));
              }
            }
          }
        } catch (e) {
          if (kDebugMode) debugPrint('Frame $i error: $e');
          // Continue with next image
        }
        
        // Give UI time to update
        await Future.delayed(const Duration(milliseconds: 50));
      }

      onProgress?.call(92, 'Video finalize ho raha hai...');

      // Finish encoding
      try {
        await FlutterQuickVideoEncoder.finish();
      } catch (e) {
        if (kDebugMode) debugPrint('Finish error: $e');
      }

      // Verify output file exists
      final outputFile = File(outputPath);
      if (!await outputFile.exists()) {
        _isGenerating = false;
        onProgress?.call(0, 'Video create nahi ho saki');
        return null;
      }

      final fileSize = await outputFile.length();
      if (fileSize < 1000) {
        _isGenerating = false;
        onProgress?.call(0, 'Video file bahut chhoti hai');
        return null;
      }

      onProgress?.call(98, 'Almost done...');

      _lastGeneratedVideo = GeneratedVideo(
        filePath: outputPath,
        thumbnailPath: thumbnailPath,
        durationSeconds: durationSeconds,
        style: style,
        backgroundMusic: backgroundMusic,
        photoCount: finalPaths.length,
        createdAt: DateTime.now(),
        imagePaths: finalPaths,
        isRealVideo: true,
        outputType: 'mp4',
      );

      await _incrementVideosCreated();
      
      onProgress?.call(100, 'Video tayar hai! 🎬');
      
      _isGenerating = false;
      return _lastGeneratedVideo;

    } catch (e) {
      if (kDebugMode) debugPrint('Generate error: $e');
      onProgress?.call(0, 'Error: $e');
      _isGenerating = false;
      return null;
    }
  }

  /// Load image and convert to RGBA format for video encoder
  static Future<Uint8List?> _loadImageAsRGBA(String path, VideoStyle style) async {
    try {
      Uint8List? imageBytes;
      
      // Load image bytes
      if (path.startsWith('http')) {
        // Skip network images for now - too slow
        return null;
      } else {
        final file = File(path);
        if (await file.exists()) {
          imageBytes = await file.readAsBytes();
        }
      }
      
      if (imageBytes == null) return null;

      // Decode image using Flutter's built-in decoder
      final codec = await ui.instantiateImageCodec(
        imageBytes,
        targetWidth: _videoWidth,
        targetHeight: _videoHeight,
      );
      final frameInfo = await codec.getNextFrame();
      final image = frameInfo.image;

      // Convert to RGBA bytes
      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      
      if (byteData == null) return null;
      
      Uint8List rgbaData = byteData.buffer.asUint8List();
      
      // Apply style color filter (simple tint)
      rgbaData = _applyStyleFilter(rgbaData, style);
      
      return rgbaData;
      
    } catch (e) {
      if (kDebugMode) debugPrint('Load image error: $e');
      return null;
    }
  }

  /// Apply simple style color filter
  static Uint8List _applyStyleFilter(Uint8List rgba, VideoStyle style) {
    // For performance, only apply simple color adjustments
    final filtered = Uint8List.fromList(rgba);
    
    int rAdjust = 0, gAdjust = 0, bAdjust = 0;
    
    switch (style) {
      case VideoStyle.romantic:
        rAdjust = 15; gAdjust = 5; bAdjust = 10;
        break;
      case VideoStyle.vintage:
        rAdjust = 20; gAdjust = 15; bAdjust = -10;
        break;
      case VideoStyle.neon:
        rAdjust = 10; gAdjust = 0; bAdjust = 20;
        break;
      case VideoStyle.nature:
        rAdjust = -5; gAdjust = 15; bAdjust = 0;
        break;
      case VideoStyle.wedding:
        rAdjust = 10; gAdjust = 10; bAdjust = 15;
        break;
      case VideoStyle.islamic:
        rAdjust = -5; gAdjust = 20; bAdjust = 10;
        break;
      case VideoStyle.family:
        rAdjust = 15; gAdjust = 10; bAdjust = 0;
        break;
      case VideoStyle.birthday:
        rAdjust = 20; gAdjust = 5; bAdjust = 15;
        break;
      case VideoStyle.dosti:
        rAdjust = 0; gAdjust = 15; bAdjust = 20;
        break;
      default:
        // No filter for cinematic, epic, minimal, etc.
        return filtered;
    }
    
    // Apply adjustments (RGBA format: R, G, B, A, R, G, B, A, ...)
    for (int i = 0; i < filtered.length; i += 4) {
      filtered[i] = (filtered[i] + rAdjust).clamp(0, 255);     // R
      filtered[i + 1] = (filtered[i + 1] + gAdjust).clamp(0, 255); // G
      filtered[i + 2] = (filtered[i + 2] + bAdjust).clamp(0, 255); // B
      // Alpha stays same
    }
    
    return filtered;
  }

  /// Save thumbnail from first image
  static Future<void> _saveThumbnail(String sourcePath, String destPath) async {
    try {
      final sourceFile = File(sourcePath);
      if (await sourceFile.exists()) {
        await sourceFile.copy(destPath);
      }
    } catch (e) {
      // Ignore thumbnail errors
    }
  }

  /// Save video to Downloads folder
  static Future<SaveResult> saveVideoToGallery(GeneratedVideo video, {
    Function(int progress, String status)? onProgress,
  }) async {
    try {
      onProgress?.call(5, 'Permission check ho raha hai...');
      
      // Request permissions
      await [
        Permission.photos,
        Permission.storage,
        Permission.manageExternalStorage,
      ].request();

      onProgress?.call(15, 'Save location dhoond raha hai...');

      // Get external storage path
      String? basePath;
      
      try {
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) {
          basePath = extDir.parent.parent.parent.parent.path;
        }
      } catch (e) {
        if (kDebugMode) debugPrint('External storage error: $e');
      }

      // Fallback paths
      if (basePath == null || !await Directory(basePath).exists()) {
        for (final testPath in ['/storage/emulated/0', '/sdcard']) {
          if (await Directory(testPath).exists()) {
            basePath = testPath;
            break;
          }
        }
      }

      if (basePath == null) {
        return SaveResult(
          success: false, 
          message: 'Storage location nahi mili',
        );
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final styleName = getStyleName(video.style);
      
      // Try different folders
      for (final folder in ['Download', 'Movies', 'DCIM', 'Pictures']) {
        try {
          final parentDir = Directory('$basePath/$folder');
          if (!await parentDir.exists()) continue;

          final fileName = 'Memories_${styleName}_$timestamp.mp4';
          final destPath = '$basePath/$folder/$fileName';

          onProgress?.call(40, '$folder mein save ho raha hai...');

          // Copy video file
          final sourceFile = File(video.filePath);
          if (await sourceFile.exists()) {
            await sourceFile.copy(destPath);
            
            // Verify copy
            final destFile = File(destPath);
            if (await destFile.exists()) {
              final size = await destFile.length();
              final sizeMB = (size / (1024 * 1024)).toStringAsFixed(1);
              
              onProgress?.call(100, 'Video save ho gayi!');
              
              return SaveResult(
                success: true,
                savedPath: destPath,
                message: '🎬 Video save ho gayi!\n\n📁 $folder/$fileName\n📊 Size: ${sizeMB}MB\n\nGallery mein dekh sakte ho!',
                savedCount: 1,
                totalCount: 1,
              );
            }
          }
        } catch (e) {
          if (kDebugMode) debugPrint('Save to $folder failed: $e');
        }
      }

      // Last resort: save to app documents
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'Memories_${styleName}_$timestamp.mp4';
        final destPath = '${appDir.path}/$fileName';
        
        final sourceFile = File(video.filePath);
        await sourceFile.copy(destPath);
        
        return SaveResult(
          success: true,
          savedPath: destPath,
          message: '🎬 Video app folder mein save ho gayi.\n\nNote: File manager se access kar sakte ho.',
          savedCount: 1,
          totalCount: 1,
        );
      } catch (e) {
        if (kDebugMode) debugPrint('App folder save failed: $e');
      }

      return SaveResult(
        success: false, 
        message: 'Video save nahi ho saki.\n\nStorage permission check karein.',
      );

    } catch (e) {
      if (kDebugMode) debugPrint('Save error: $e');
      return SaveResult(
        success: false, 
        message: 'Error: $e',
      );
    }
  }

  // Helper methods
  static String getStyleName(VideoStyle style) {
    const names = [
      'Cinematic', 'Epic', 'Romantic', 'Vintage', 'Neon', 'Minimal', 
      'Party', 'Nature', 'Travel', 'Story', 'Wedding', 'Birthday', 
      'Family', 'Dosti', 'Islamic'
    ];
    return names[style.index];
  }

  static VideoStyle getStyleFromName(String name) {
    const map = {
      'cinematic': VideoStyle.cinematic,
      'epic': VideoStyle.epic,
      'romantic': VideoStyle.romantic,
      'vintage': VideoStyle.vintage,
      'neon': VideoStyle.neon,
      'minimal': VideoStyle.minimal,
      'party': VideoStyle.party,
      'nature': VideoStyle.nature,
      'travel': VideoStyle.travel,
      'story': VideoStyle.story,
      'wedding': VideoStyle.wedding,
      'birthday': VideoStyle.birthday,
      'family': VideoStyle.family,
      'dosti': VideoStyle.dosti,
      'islamic': VideoStyle.islamic,
    };
    return map[name.toLowerCase()] ?? VideoStyle.cinematic;
  }

  static String getStyleDescription(VideoStyle style) {
    const desc = [
      'Hollywood-style',
      'Dramatic & powerful',
      'Soft & dreamy',
      'Classic sepia',
      'Vibrant glow',
      'Clean & elegant',
      'Bright & colorful',
      'Calm green',
      'Adventure style',
      'Narrative',
      'Shaadi ki yaadein',
      'Birthday celebration',
      'Ghar ki yaadein',
      'Dosti ke pal',
      'Deeni yaadein'
    ];
    return desc[style.index];
  }

  static String formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  static Future<void> deleteGeneratedVideo() async {
    if (_lastGeneratedVideo != null) {
      try {
        final file = File(_lastGeneratedVideo!.filePath);
        if (await file.exists()) {
          await file.delete();
        }
        _lastGeneratedVideo = null;
      } catch (e) {
        if (kDebugMode) debugPrint('Delete error: $e');
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
