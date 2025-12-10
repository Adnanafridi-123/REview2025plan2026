import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show Uint8List, kDebugMode, debugPrint;

import 'package:flutter_quick_video_encoder/flutter_quick_video_encoder.dart';
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

/// Video Generator Service - Creates REAL MP4 videos from photos
class VideoGeneratorService {
  static GeneratedVideo? _lastGeneratedVideo;
  static bool _isGenerating = false;
  
  static GeneratedVideo? get lastGeneratedVideo => _lastGeneratedVideo;
  static bool get isGenerating => _isGenerating;
  
  // Video encoding settings
  static const int _videoWidth = 720;
  static const int _videoHeight = 1280;
  static const int _fps = 24;
  static const int _bitRate = 4000000; // 4 Mbps
  
  // Audio settings (required by encoder, even if no audio)
  static const int _audioChannels = 1;
  static const int _audioBitrate = 128000;
  static const int _sampleRate = 44100;

  // Demo image URLs for when user has no photos
  static const List<String> _demoImages = [
    'https://picsum.photos/720/1280?random=1',
    'https://picsum.photos/720/1280?random=2',
    'https://picsum.photos/720/1280?random=3',
    'https://picsum.photos/720/1280?random=4',
    'https://picsum.photos/720/1280?random=5',
    'https://picsum.photos/720/1280?random=6',
  ];

  /// Generate a REAL MP4 video from photos
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
      onProgress?.call(5, 'Initializing video encoder...');
      
      // Use demo images if no photos provided
      List<String> finalImagePaths = imagePaths.isNotEmpty ? imagePaths : _demoImages;
      
      if (kDebugMode) {
        debugPrint('Creating video from ${finalImagePaths.length} images');
      }

      // Get app directory for saving
      final directory = await getApplicationDocumentsDirectory();
      final videoDir = Directory('${directory.path}/generated_videos');
      if (!await videoDir.exists()) {
        await videoDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final videoFileName = 'memory_video_$timestamp.mp4';
      final thumbnailFileName = 'thumbnail_$timestamp.jpg';
      
      final videoPath = '${videoDir.path}/$videoFileName';
      final thumbnailPath = '${videoDir.path}/$thumbnailFileName';

      onProgress?.call(10, 'Loading and processing images...');

      // Load all images as RGBA bytes
      List<Uint8List> processedImages = [];
      
      for (int i = 0; i < finalImagePaths.length; i++) {
        final progress = 10 + ((i / finalImagePaths.length) * 40).toInt();
        onProgress?.call(progress, 'Processing image ${i + 1}/${finalImagePaths.length}...');
        
        final imagePath = finalImagePaths[i];
        
        try {
          Uint8List? imageBytes;
          
          if (imagePath.startsWith('http')) {
            final response = await http.get(Uri.parse(imagePath)).timeout(
              const Duration(seconds: 30),
            );
            if (response.statusCode == 200) {
              imageBytes = response.bodyBytes;
            }
          } else {
            final sourceFile = File(imagePath);
            if (await sourceFile.exists()) {
              imageBytes = await sourceFile.readAsBytes();
            }
          }
          
          if (imageBytes != null) {
            // Save first image as thumbnail
            if (processedImages.isEmpty) {
              await File(thumbnailPath).writeAsBytes(imageBytes);
            }
            
            // Convert to RGBA and resize
            final rgbaBytes = await _convertToRGBA(imageBytes);
            if (rgbaBytes != null) {
              processedImages.add(rgbaBytes);
            }
          }
        } catch (e) {
          if (kDebugMode) debugPrint('Error processing image $i: $e');
        }
      }

      if (processedImages.isEmpty) {
        if (kDebugMode) debugPrint('No images could be processed');
        _isGenerating = false;
        return null;
      }

      onProgress?.call(55, 'Initializing H.264 encoder...');

      // Initialize video encoder using STATIC methods
      try {
        // Disable logging for production
        await FlutterQuickVideoEncoder.setLogLevel(LogLevel.none);
        
        await FlutterQuickVideoEncoder.setup(
          width: _videoWidth,
          height: _videoHeight,
          fps: _fps,
          videoBitrate: _bitRate,
          profileLevel: ProfileLevel.any,
          audioChannels: _audioChannels,
          audioBitrate: _audioBitrate,
          sampleRate: _sampleRate,
          filepath: videoPath,
        );
      } catch (e) {
        if (kDebugMode) debugPrint('Encoder setup failed: $e');
        // Fallback to slideshow
        return await _generateSlideshowFallback(
          processedImagePaths: finalImagePaths,
          style: style,
          durationSeconds: durationSeconds,
          backgroundMusic: backgroundMusic,
          onProgress: onProgress,
        );
      }

      onProgress?.call(60, 'Creating professional video...');

      // Calculate frames per image
      final totalFrames = durationSeconds * _fps;
      final framesPerImage = totalFrames ~/ processedImages.length;
      final transitionFrames = (_fps * 0.4).toInt(); // 0.4 second crossfade
      
      int currentFrame = 0;
      
      for (int imageIndex = 0; imageIndex < processedImages.length; imageIndex++) {
        final progress = 60 + ((imageIndex / processedImages.length) * 35).toInt();
        onProgress?.call(progress, 'Encoding ${imageIndex + 1}/${processedImages.length}...');
        
        final imageBytes = processedImages[imageIndex];
        final nextImageBytes = imageIndex < processedImages.length - 1 
            ? processedImages[imageIndex + 1] 
            : null;
        
        // Main frames for this image
        final mainFrames = framesPerImage - (nextImageBytes != null ? transitionFrames : 0);
        
        for (int f = 0; f < mainFrames; f++) {
          try {
            // Use STATIC method
            await FlutterQuickVideoEncoder.appendVideoFrame(imageBytes);
            currentFrame++;
          } catch (e) {
            if (kDebugMode) debugPrint('Frame append error: $e');
          }
        }
        
        // Crossfade transition to next image
        if (nextImageBytes != null) {
          for (int t = 0; t < transitionFrames; t++) {
            try {
              final blendFactor = t / transitionFrames;
              final transitionFrame = _blendFrames(imageBytes, nextImageBytes, blendFactor);
              // Use STATIC method
              await FlutterQuickVideoEncoder.appendVideoFrame(transitionFrame);
              currentFrame++;
            } catch (e) {
              if (kDebugMode) debugPrint('Transition frame error: $e');
            }
          }
        }
      }

      onProgress?.call(96, 'Finalizing video...');

      // Finish encoding - Use STATIC method
      try {
        await FlutterQuickVideoEncoder.finish();
      } catch (e) {
        if (kDebugMode) debugPrint('Finish error: $e');
      }
      
      // Verify output
      final outputFile = File(videoPath);
      bool isRealVideo = false;
      
      if (await outputFile.exists()) {
        final fileSize = await outputFile.length();
        if (fileSize > 10000) { // At least 10KB
          isRealVideo = true;
          if (kDebugMode) {
            debugPrint('MP4 Video created successfully!');
            debugPrint('   Path: $videoPath');
            debugPrint('   Size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');
            debugPrint('   Frames: $currentFrame');
          }
        }
      }
      
      // Fallback to slideshow if video failed
      if (!isRealVideo) {
        if (kDebugMode) debugPrint('Video encoding failed, using slideshow fallback');
        return await _generateSlideshowFallback(
          processedImagePaths: finalImagePaths,
          style: style,
          durationSeconds: durationSeconds,
          backgroundMusic: backgroundMusic,
          onProgress: onProgress,
        );
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
        imagePaths: finalImagePaths,
        isRealVideo: true,
      );

      _isGenerating = false;
      return _lastGeneratedVideo;

    } catch (e) {
      if (kDebugMode) debugPrint('Error generating video: $e');
      _isGenerating = false;
      return null;
    }
  }

  /// Convert image bytes to RGBA format and resize to video dimensions
  static Future<Uint8List?> _convertToRGBA(Uint8List imageBytes) async {
    try {
      final codec = await ui.instantiateImageCodec(
        imageBytes,
        targetWidth: _videoWidth,
        targetHeight: _videoHeight,
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;
      
      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) return null;
      
      return byteData.buffer.asUint8List();
    } catch (e) {
      if (kDebugMode) debugPrint('RGBA conversion error: $e');
      return null;
    }
  }

  /// Blend two RGBA frames for crossfade transition
  static Uint8List _blendFrames(Uint8List frame1, Uint8List frame2, double factor) {
    if (frame1.length != frame2.length) {
      return frame1;
    }
    
    final result = Uint8List(frame1.length);
    final f1 = 1.0 - factor;
    final f2 = factor;
    
    for (int i = 0; i < frame1.length; i++) {
      result[i] = ((frame1[i] * f1) + (frame2[i] * f2)).clamp(0, 255).toInt();
    }
    
    return result;
  }

  /// Fallback slideshow generator (if video encoding fails)
  static Future<GeneratedVideo?> _generateSlideshowFallback({
    required List<String> processedImagePaths,
    required VideoStyle style,
    required int durationSeconds,
    MusicTrack? backgroundMusic,
    Function(int progress, String status)? onProgress,
  }) async {
    try {
      onProgress?.call(90, 'Creating slideshow backup...');
      
      final directory = await getApplicationDocumentsDirectory();
      final videoDir = Directory('${directory.path}/generated_videos');
      if (!await videoDir.exists()) {
        await videoDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final videoFileName = 'memory_slideshow_$timestamp.slideshow';
      final thumbnailFileName = 'thumbnail_$timestamp.jpg';
      
      final videoPath = '${videoDir.path}/$videoFileName';
      final thumbnailPath = '${videoDir.path}/$thumbnailFileName';

      // Save slideshow data
      final slideshowData = processedImagePaths.join('\n');
      await File(videoPath).writeAsString(slideshowData);

      // Create thumbnail
      if (processedImagePaths.isNotEmpty) {
        final firstImagePath = processedImagePaths[0];
        if (firstImagePath.startsWith('http')) {
          final response = await http.get(Uri.parse(firstImagePath));
          if (response.statusCode == 200) {
            await File(thumbnailPath).writeAsBytes(response.bodyBytes);
          }
        } else {
          final file = File(firstImagePath);
          if (await file.exists()) {
            await file.copy(thumbnailPath);
          }
        }
      }

      onProgress?.call(100, 'Slideshow created!');

      _lastGeneratedVideo = GeneratedVideo(
        filePath: videoPath,
        thumbnailPath: thumbnailPath,
        durationSeconds: durationSeconds,
        style: style,
        backgroundMusic: backgroundMusic,
        photoCount: processedImagePaths.length,
        createdAt: DateTime.now(),
        imagePaths: processedImagePaths,
        isRealVideo: false,
      );

      _isGenerating = false;
      return _lastGeneratedVideo;
    } catch (e) {
      if (kDebugMode) debugPrint('Slideshow fallback error: $e');
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

  /// Save generated video to Downloads folder
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
          totalCount: 1,
        );
      }
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      // If it's a REAL MP4 video
      if (video.isRealVideo && video.filePath.endsWith('.mp4')) {
        onProgress?.call(50, 'Copying video file...');
        
        final sourceFile = File(video.filePath);
        if (!await sourceFile.exists()) {
          return SaveResult(
            success: false,
            message: 'Video file not found',
            savedCount: 0,
            totalCount: 1,
          );
        }
        
        // Create destination folder
        final destDir = Directory('$basePath/Memories_2025');
        if (!await destDir.exists()) {
          await destDir.create(recursive: true);
        }
        
        final destPath = '${destDir.path}/Memory_Video_$timestamp.mp4';
        await sourceFile.copy(destPath);
        
        // Verify
        final destFile = File(destPath);
        if (await destFile.exists()) {
          final fileSize = await destFile.length();
          final sizeInMB = (fileSize / 1024 / 1024).toStringAsFixed(2);
          
          onProgress?.call(100, 'Video saved!');
          
          return SaveResult(
            success: true,
            savedPath: destPath,
            message: 'Video saved ($sizeInMB MB)',
            savedCount: 1,
            totalCount: 1,
          );
        }
      }
      
      // Fallback: Save slideshow images
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
          final sourcePath = video.imagePaths[i];
          final fileName = 'Memory_${i + 1}.jpg';
          final destPath = '${saveDir.path}/$fileName';
          
          if (sourcePath.startsWith('http')) {
            final response = await http.get(Uri.parse(sourcePath)).timeout(
              const Duration(seconds: 20),
            );
            if (response.statusCode == 200) {
              await File(destPath).writeAsBytes(response.bodyBytes);
              savedCount++;
            }
          } else {
            final sourceFile = File(sourcePath);
            if (await sourceFile.exists()) {
              await sourceFile.copy(destPath);
              savedCount++;
            }
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
