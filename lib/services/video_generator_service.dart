import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import '../services/media_service.dart';
import '../services/music_service.dart';


/// Video style effects - Professional Styles 2025
enum VideoStyle {
  wrapped,     // 🔥 Spotify Wrapped 2025 style
  cinematic,   // Ken Burns zoom & pan
  reels,       // Instagram Reels style
  tiktok,      // TikTok viral transitions
  glass,       // ✨ Glassmorphism
  gradient,    // 🌈 Gradient flow
  y2k,         // 📼 Y2K retro
  vintage,     // Retro film aesthetic
  polaroid,    // 🖼️ Polaroid frames
  dynamic,     // Fast-paced energy
  aesthetic,   // 💫 Soft dreamy
  memories,    // Emotional storytelling
  neon,        // Cyberpunk glow
  glitch,      // 🎭 Digital distortion
  luxury,      // 🏆 Golden luxury
  minimal,     // 🎯 Clean & simple
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

  /// Generate a high-quality slideshow video from photos
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
      
      // Filter and collect valid local files
      List<String> localImages = [];
      for (final path in finalImagePaths) {
        if (!path.startsWith('http') && File(path).existsSync()) {
          localImages.add(path);
        }
      }
      
      if (localImages.isEmpty) {
        if (kDebugMode) debugPrint('No local images found');
        _isGenerating = false;
        return null;
      }
      
      if (kDebugMode) {
        debugPrint('Using ${localImages.length} images for video');
      }

      // Get app directory for saving
      final directory = await getApplicationDocumentsDirectory();
      final videoDir = Directory('${directory.path}/generated_videos');
      if (!await videoDir.exists()) {
        await videoDir.create(recursive: true);
      }

      onProgress?.call(10, 'Processing ${localImages.length} photos...');

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final framesDir = '${videoDir.path}/frames_$timestamp';
      await Directory(framesDir).create(recursive: true);
      
      final videoPath = '${videoDir.path}/memory_video_$timestamp.mp4';
      final thumbnailPath = '${videoDir.path}/thumbnail_$timestamp.jpg';
      
      // HD vertical video resolution
      const int targetWidth = 720;
      const int targetHeight = 1280;
      
      // Calculate duration per image
      final double secondsPerImage = durationSeconds / localImages.length;
      
      onProgress?.call(15, 'Creating video frames...');
      
      List<String> framePaths = [];
      
      // Process each image
      for (int i = 0; i < localImages.length; i++) {
        try {
          final progress = 15 + ((i / localImages.length) * 60).toInt();
          onProgress?.call(progress, 'Processing photo ${i + 1}/${localImages.length}...');
          
          await Future.delayed(const Duration(milliseconds: 20));
          
          final file = File(localImages[i]);
          final bytes = await file.readAsBytes();
          
          // Process image in background
          final processedFrame = await compute(_processImageForVideo, {
            'bytes': bytes,
            'targetWidth': targetWidth,
            'targetHeight': targetHeight,
            'styleIndex': style.index,
          });
          
          if (processedFrame != null) {
            final framePath = '$framesDir/frame_${i.toString().padLeft(4, '0')}.jpg';
            await File(framePath).writeAsBytes(processedFrame);
            framePaths.add(framePath);
            
            // Save first as thumbnail
            if (i == 0) {
              await File(thumbnailPath).writeAsBytes(processedFrame);
            }
          }
          
        } catch (e) {
          if (kDebugMode) debugPrint('Error processing image $i: $e');
        }
      }
      
      if (framePaths.isEmpty) {
        _isGenerating = false;
        return null;
      }
      
      onProgress?.call(78, 'Creating MP4 video...');
      
      // Create FFmpeg concat file
      final concatFile = '$framesDir/input.txt';
      final concatLines = framePaths.map((p) => 
        "file '$p'\nduration $secondsPerImage"
      ).join('\n');
      await File(concatFile).writeAsString("$concatLines\nfile '${framePaths.last}'");
      
      // FFmpeg command - create real MP4 video
      final cmd = '-y -f concat -safe 0 -i "$concatFile" '
          '-vf "fps=30,format=yuv420p" '
          '-c:v libx264 -preset fast -crf 23 '
          '-movflags +faststart "$videoPath"';
      
      if (kDebugMode) debugPrint('FFmpeg: $cmd');
      
      onProgress?.call(85, 'Encoding MP4...');
      
      final session = await FFmpegKit.execute(cmd);
      final returnCode = await session.getReturnCode();
      
      if (!ReturnCode.isSuccess(returnCode)) {
        if (kDebugMode) {
          final logs = await session.getAllLogsAsString();
          debugPrint('FFmpeg error: $logs');
        }
        _isGenerating = false;
        return null;
      }
      
      // Cleanup frames
      try {
        await Directory(framesDir).delete(recursive: true);
      } catch (_) {}
      
      onProgress?.call(100, 'Video created!');

      _lastGeneratedVideo = GeneratedVideo(
        filePath: videoPath,
        thumbnailPath: thumbnailPath,
        durationSeconds: durationSeconds,
        style: style,
        backgroundMusic: backgroundMusic,
        photoCount: framePaths.length,
        createdAt: DateTime.now(),
        imagePaths: localImages,
      );

      _isGenerating = false;
      
      if (kDebugMode) {
        final videoFile = File(videoPath);
        if (await videoFile.exists()) {
          final fileSize = await videoFile.length();
          debugPrint('MP4 created: $videoPath (${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB)');
        }
      }
      
      return _lastGeneratedVideo;

    } catch (e) {
      if (kDebugMode) debugPrint('Error generating video: $e');
      _isGenerating = false;
      return null;
    }
  }
  
  /// Process image for MP4 video - runs in isolate
  static Uint8List? _processImageForVideo(Map<String, dynamic> params) {
    try {
      final Uint8List bytes = params['bytes'];
      final int targetWidth = params['targetWidth'];
      final int targetHeight = params['targetHeight'];
      final int styleIndex = params['styleIndex'];
      
      img.Image? image = img.decodeImage(bytes);
      if (image == null) return null;
      
      // Resize image to fill target dimensions
      image = _resizeToFill(image, targetWidth, targetHeight);
      
      // Apply professional style filter
      image = _applyStyleFilterStatic(image, VideoStyle.values[styleIndex]);
      
      // Encode as high quality JPG for video
      return Uint8List.fromList(img.encodeJpg(image, quality: 95));
    } catch (e) {
      return null;
    }
  }
  
  /// Resize image to FILL dimensions (may crop edges)
  static img.Image _resizeToFill(img.Image image, int targetWidth, int targetHeight) {
    final double scaleX = targetWidth / image.width;
    final double scaleY = targetHeight / image.height;
    final double scale = scaleX > scaleY ? scaleX : scaleY; // Use larger scale to fill
    
    final int newWidth = (image.width * scale).round();
    final int newHeight = (image.height * scale).round();
    
    img.Image resized = img.copyResize(image, width: newWidth, height: newHeight);
    
    // Crop to center if needed
    if (resized.width > targetWidth || resized.height > targetHeight) {
      final int cropX = ((resized.width - targetWidth) / 2).round().clamp(0, resized.width - targetWidth);
      final int cropY = ((resized.height - targetHeight) / 2).round().clamp(0, resized.height - targetHeight);
      resized = img.copyCrop(resized, x: cropX, y: cropY, width: targetWidth, height: targetHeight);
    }
    
    return resized;
  }
  
  /// Apply style filter (static version for isolate) - Professional 2025 Trending Styles
  static img.Image _applyStyleFilterStatic(img.Image image, VideoStyle style) {
    switch (style) {
      case VideoStyle.wrapped:
        // 🔥 Spotify Wrapped 2025: Bold, vibrant green tones with high contrast
        img.Image result = img.adjustColor(image, saturation: 1.2, contrast: 1.15, brightness: 1.05);
        result = img.colorOffset(result, red: -8, green: 15, blue: -5); // Spotify green tint
        return result;
        
      case VideoStyle.cinematic:
        // Hollywood film look: teal shadows, orange highlights
        img.Image result = img.adjustColor(image, contrast: 1.12, saturation: 0.92, brightness: 1.0);
        result = img.colorOffset(result, red: 5, green: -2, blue: -8); // Warm highlights
        return result;
        
      case VideoStyle.reels:
        // Instagram viral: bright, warm, high contrast
        img.Image result = img.adjustColor(image, saturation: 1.15, brightness: 1.08, contrast: 1.1);
        result = img.colorOffset(result, red: 8, green: 4, blue: -5);
        return result;
        
      case VideoStyle.tiktok:
        // TikTok trendy: vibrant, punchy colors with cyan-pink contrast
        img.Image result = img.adjustColor(image, saturation: 1.25, contrast: 1.15, brightness: 1.05);
        result = img.colorOffset(result, red: 5, green: 8, blue: 10); // Slight cyan
        return result;
        
      case VideoStyle.glass:
        // ✨ Glassmorphism: Soft, slightly desaturated with glow effect
        img.Image result = img.adjustColor(image, saturation: 0.9, contrast: 0.95, brightness: 1.1);
        result = img.colorOffset(result, red: 5, green: 5, blue: 15); // Cool soft tint
        return result;
        
      case VideoStyle.gradient:
        // 🌈 Gradient Flow: Vibrant colors with smooth transitions
        img.Image result = img.adjustColor(image, saturation: 1.2, contrast: 1.08, brightness: 1.05);
        result = img.colorOffset(result, red: 10, green: -2, blue: 8); // Pink-purple tint
        return result;
        
      case VideoStyle.y2k:
        // 📼 Y2K Retro: Chrome, holographic feel with high saturation
        img.Image result = img.adjustColor(image, saturation: 1.3, contrast: 1.1, brightness: 1.1);
        result = img.colorOffset(result, red: 15, green: -5, blue: 20); // Magenta-purple
        return result;
        
      case VideoStyle.vintage:
        // 🎞️ Retro film: warm sepia with grain feel
        img.Image result = img.sepia(image);
        result = img.adjustColor(result, brightness: 1.05, contrast: 0.95, saturation: 0.85);
        result = img.colorOffset(result, red: 15, green: 8, blue: -10);
        return result;
        
      case VideoStyle.polaroid:
        // 🖼️ Polaroid: Faded, warm with white border feel
        img.Image result = img.adjustColor(image, saturation: 0.85, contrast: 0.92, brightness: 1.08);
        result = img.colorOffset(result, red: 12, green: 10, blue: 5); // Warm yellow tint
        return result;
        
      case VideoStyle.dynamic:
        // ⚡ Action/Sports: high contrast, vivid
        img.Image result = img.adjustColor(image, contrast: 1.2, saturation: 1.15, brightness: 1.02);
        return result;
        
      case VideoStyle.aesthetic:
        // 💫 Soft Dreamy: Pastel, soft, slightly pink
        img.Image result = img.adjustColor(image, saturation: 0.8, contrast: 0.88, brightness: 1.12);
        result = img.colorOffset(result, red: 15, green: 8, blue: 12); // Soft pink-lavender
        return result;
        
      case VideoStyle.luxury:
        // 🏆 Luxury/Gold: Golden tones with elegant warmth
        img.Image result = img.adjustColor(image, brightness: 1.08, saturation: 0.92, contrast: 1.0);
        result = img.colorOffset(result, red: 18, green: 12, blue: -5); // Golden warm tone
        return result;
        
      case VideoStyle.memories:
        // 💖 Nostalgic: warm golden tones
        img.Image result = img.adjustColor(image, brightness: 1.05, saturation: 0.95, contrast: 1.05);
        result = img.colorOffset(result, red: 12, green: 6, blue: -5);
        return result;
        
      case VideoStyle.neon:
        // 🌙 Cyberpunk: cool vibrant, high saturation with neon glow
        img.Image result = img.adjustColor(image, saturation: 1.35, contrast: 1.18, brightness: 1.0);
        result = img.colorOffset(result, red: -5, green: 10, blue: 20); // Cool cyan-blue tint
        return result;
        
      case VideoStyle.glitch:
        // 🎭 Glitch Art: High contrast with RGB shift feel
        img.Image result = img.adjustColor(image, saturation: 1.25, contrast: 1.25, brightness: 1.0);
        result = img.colorOffset(result, red: 10, green: -5, blue: 5); // Slight RGB offset
        return result;
        
      case VideoStyle.minimal:
        // 🎯 Minimal Clean: Subtle adjustments, clean look
        img.Image result = img.adjustColor(image, saturation: 0.95, contrast: 1.02, brightness: 1.02);
        return result;
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

  /// Get style from name - Updated for 2025 styles
  static VideoStyle getStyleFromName(String name) {
    switch (name.toLowerCase()) {
      case 'wrapped':
        return VideoStyle.wrapped;
      case 'cinematic':
        return VideoStyle.cinematic;
      case 'reels':
        return VideoStyle.reels;
      case 'tiktok':
        return VideoStyle.tiktok;
      case 'glass':
        return VideoStyle.glass;
      case 'gradient':
        return VideoStyle.gradient;
      case 'y2k':
        return VideoStyle.y2k;
      case 'vintage':
        return VideoStyle.vintage;
      case 'polaroid':
        return VideoStyle.polaroid;
      case 'dynamic':
        return VideoStyle.dynamic;
      case 'aesthetic':
        return VideoStyle.aesthetic;
      case 'memories':
        return VideoStyle.memories;
      case 'neon':
        return VideoStyle.neon;
      case 'glitch':
        return VideoStyle.glitch;
      case 'luxury':
        return VideoStyle.luxury;
      case 'minimal':
        return VideoStyle.minimal;
      default:
        return VideoStyle.wrapped; // Default to trending Wrapped style
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
