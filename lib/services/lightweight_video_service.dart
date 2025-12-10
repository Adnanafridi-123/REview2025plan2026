import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;
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
  final String outputType; // 'gif', 'images', 'slideshow'

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
    this.outputType = 'images',
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

/// LIGHTWEIGHT Video Generator Service - NO CRASHES, SMOOTH OPERATION
/// Uses simple image processing instead of heavy video encoders
class LightweightVideoService {
  static GeneratedVideo? _lastGeneratedVideo;
  static bool _isGenerating = false;
  
  static GeneratedVideo? get lastGeneratedVideo => _lastGeneratedVideo;
  static bool get isGenerating => _isGenerating;
  
  // Output settings
  static const int _outputWidth = 720;
  static const int _outputHeight = 1280;
  static const int _gifFps = 8; // Lower FPS for smaller file size
  
  // Demo image URLs for when user has no photos
  static const List<String> _demoImages = [
    'https://picsum.photos/720/1280?random=1',
    'https://picsum.photos/720/1280?random=2',
    'https://picsum.photos/720/1280?random=3',
    'https://picsum.photos/720/1280?random=4',
    'https://picsum.photos/720/1280?random=5',
    'https://picsum.photos/720/1280?random=6',
  ];

  /// Generate a lightweight video (animated GIF or processed images)
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
      final gifFileName = 'memory_video_$timestamp.gif';
      final thumbnailFileName = 'thumbnail_$timestamp.jpg';
      
      final gifPath = '${videoDir.path}/$gifFileName';
      final thumbnailPath = '${videoDir.path}/$thumbnailFileName';

      onProgress?.call(10, 'Photos load ho rahe hain...');

      // Load and process all images
      List<img.Image> processedImages = [];
      
      for (int i = 0; i < finalImagePaths.length; i++) {
        final progress = 10 + ((i / finalImagePaths.length) * 40).toInt();
        onProgress?.call(progress, 'Photo ${i + 1}/${finalImagePaths.length} process ho rahi hai...');
        
        final imagePath = finalImagePaths[i];
        
        try {
          Uint8List? imageBytes;
          
          if (imagePath.startsWith('http')) {
            // Download from URL with timeout
            final response = await http.get(Uri.parse(imagePath)).timeout(
              const Duration(seconds: 15),
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
            // Decode and resize image using 'image' package (lightweight)
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
              processedImages.add(styledImage);
              
              // Save first image as thumbnail
              if (processedImages.length == 1) {
                final thumbnailBytes = img.encodeJpg(styledImage, quality: 85);
                await File(thumbnailPath).writeAsBytes(thumbnailBytes);
              }
            }
          }
        } catch (e) {
          if (kDebugMode) debugPrint('Error processing image $i: $e');
          // Continue with other images - don't crash!
        }
        
        // Small delay to prevent memory overload
        await Future.delayed(const Duration(milliseconds: 50));
      }

      if (processedImages.isEmpty) {
        if (kDebugMode) debugPrint('No images could be processed');
        _isGenerating = false;
        return null;
      }

      onProgress?.call(55, 'Video create ho rahi hai...');

      // Calculate frames per image for smooth playback
      final totalGifFrames = durationSeconds * _gifFps;
      final framesPerImage = (totalGifFrames / processedImages.length).ceil();
      
      // Create animated GIF using the image package
      // Note: img.Animation is created automatically when encoding GIF with multiple frames
      final List<img.Image> gifFrames = [];
      
      // Frame delay in 1/100th of a second (e.g., 12 = 120ms = ~8fps)
      final frameDelay = (100 / _gifFps).round();
      
      onProgress?.call(60, 'Animation create ho rahi hai...');
      
      for (int imgIndex = 0; imgIndex < processedImages.length; imgIndex++) {
        final progress = 60 + ((imgIndex / processedImages.length) * 30).toInt();
        onProgress?.call(progress, 'Frame ${imgIndex + 1}/${processedImages.length} add ho raha hai...');
        
        final currentImage = processedImages[imgIndex];
        
        // Add main frames for this image
        final mainFrames = framesPerImage > 2 ? framesPerImage - 2 : framesPerImage;
        for (int f = 0; f < mainFrames; f++) {
          final frame = currentImage.clone();
          frame.frameDuration = frameDelay;
          gifFrames.add(frame);
        }
        
        // Add simple crossfade transition frames (if not last image)
        if (imgIndex < processedImages.length - 1) {
          final nextImage = processedImages[imgIndex + 1];
          
          // Create 2 transition frames
          for (int t = 1; t <= 2; t++) {
            final blendFactor = t / 3.0;
            final transitionFrame = _blendImages(currentImage, nextImage, blendFactor);
            transitionFrame.frameDuration = frameDelay;
            gifFrames.add(transitionFrame);
          }
        }
        
        // Release memory periodically
        if (imgIndex % 3 == 0) {
          await Future.delayed(const Duration(milliseconds: 10));
        }
      }
      
      if (gifFrames.isEmpty) {
        if (kDebugMode) debugPrint('No frames generated');
        _isGenerating = false;
        return null;
      }
      
      onProgress?.call(92, 'GIF save ho rahi hai...');
      
      // Encode and save GIF using the frames list
      try {
        // Create GIF encoder with proper settings
        final encoder = img.GifEncoder(repeat: 0); // repeat=0 means loop forever
        for (final frame in gifFrames) {
          encoder.addFrame(frame, duration: frameDelay);
        }
        final gifBytes = encoder.finish();
        if (gifBytes != null) {
          await File(gifPath).writeAsBytes(gifBytes);
        } else {
          throw Exception('GIF encoding returned null');
        }
      } catch (e) {
        if (kDebugMode) debugPrint('GIF encoding error: $e');
        // Fallback to saving images only
        _isGenerating = false;
        return await _saveImagesOnlyFallback(
          processedImages: processedImages,
          originalPaths: finalImagePaths,
          style: style,
          durationSeconds: durationSeconds,
          backgroundMusic: backgroundMusic,
          onProgress: onProgress,
        );
      }
      
      // Verify output
      final outputFile = File(gifPath);
      if (!await outputFile.exists()) {
        if (kDebugMode) debugPrint('GIF file not created');
        _isGenerating = false;
        return null;
      }
      
      final fileSize = await outputFile.length();
      if (kDebugMode) {
        debugPrint('GIF created successfully!');
        debugPrint('   Path: $gifPath');
        debugPrint('   Size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');
        debugPrint('   Frames: ${gifFrames.length}');
      }

      onProgress?.call(100, 'Video tayar hai! ✨');

      _lastGeneratedVideo = GeneratedVideo(
        filePath: gifPath,
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

      _isGenerating = false;
      return _lastGeneratedVideo;

    } catch (e) {
      if (kDebugMode) debugPrint('Error generating video: $e');
      _isGenerating = false;
      return null;
    }
  }

  /// Apply style filter to image
  static img.Image _applyStyleFilter(img.Image image, VideoStyle style) {
    switch (style) {
      case VideoStyle.cinematic:
        // Desaturate slightly, add contrast
        img.adjustColor(image, saturation: 0.9, contrast: 1.1);
        img.vignette(image, start: 0.4, end: 0.9);
        return image;
        
      case VideoStyle.epic:
        // High contrast, slight desaturation
        img.adjustColor(image, contrast: 1.3, saturation: 0.85);
        return image;
        
      case VideoStyle.romantic:
        // Warm pink tones, soft
        img.adjustColor(image, saturation: 1.1, gamma: 1.1);
        img.colorOffset(image, red: 15, green: 5, blue: -5);
        return image;
        
      case VideoStyle.vintage:
        // Sepia effect
        img.sepia(image);
        return image;
        
      case VideoStyle.neon:
        // High saturation, vibrant
        img.adjustColor(image, saturation: 1.5, contrast: 1.2);
        return image;
        
      case VideoStyle.minimal:
        // Clean, no changes needed
        return image;
        
      case VideoStyle.party:
        // Bright, colorful
        img.adjustColor(image, saturation: 1.3, brightness: 1.1);
        return image;
        
      case VideoStyle.nature:
        // Green tint, calm
        img.colorOffset(image, red: -10, green: 10, blue: -5);
        return image;
        
      case VideoStyle.travel:
        // Warm adventure look
        img.adjustColor(image, saturation: 1.15, contrast: 1.05);
        img.colorOffset(image, red: 10, green: 5, blue: -10);
        return image;
        
      case VideoStyle.story:
        // Slight vignette, letterbox effect simulation
        img.vignette(image, start: 0.5, end: 0.95);
        return image;
        
      case VideoStyle.wedding:
        // Soft white, golden glow
        img.adjustColor(image, brightness: 1.05, saturation: 0.95);
        img.colorOffset(image, red: 10, green: 8, blue: 0);
        return image;
        
      case VideoStyle.birthday:
        // Colorful, festive
        img.adjustColor(image, saturation: 1.25, brightness: 1.1);
        return image;
        
      case VideoStyle.family:
        // Warm, nostalgic
        img.adjustColor(image, saturation: 0.95, gamma: 1.05);
        img.colorOffset(image, red: 8, green: 4, blue: -5);
        return image;
        
      case VideoStyle.dosti:
        // Fun, bright
        img.adjustColor(image, saturation: 1.2, contrast: 1.1);
        return image;
        
      case VideoStyle.islamic:
        // Peaceful, elegant green tones
        img.adjustColor(image, saturation: 0.9);
        img.colorOffset(image, red: -5, green: 10, blue: 5);
        return image;
    }
  }

  /// Blend two images for crossfade transition
  static img.Image _blendImages(img.Image image1, img.Image image2, double factor) {
    final result = img.Image(width: image1.width, height: image1.height);
    
    final f1 = 1.0 - factor;
    final f2 = factor;
    
    for (int y = 0; y < image1.height; y++) {
      for (int x = 0; x < image1.width; x++) {
        final pixel1 = image1.getPixel(x, y);
        final pixel2 = image2.getPixel(x, y);
        
        final r = ((pixel1.r * f1) + (pixel2.r * f2)).clamp(0, 255).toInt();
        final g = ((pixel1.g * f1) + (pixel2.g * f2)).clamp(0, 255).toInt();
        final b = ((pixel1.b * f1) + (pixel2.b * f2)).clamp(0, 255).toInt();
        
        result.setPixelRgba(x, y, r, g, b, 255);
      }
    }
    
    return result;
  }

  /// Fallback: Save processed images when GIF creation fails
  static Future<GeneratedVideo?> _saveImagesOnlyFallback({
    required List<img.Image> processedImages,
    required List<String> originalPaths,
    required VideoStyle style,
    required int durationSeconds,
    MusicTrack? backgroundMusic,
    Function(int progress, String status)? onProgress,
  }) async {
    try {
      onProgress?.call(90, 'Images save ho rahi hain...');
      
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

      // Save processed images
      List<String> savedPaths = [];
      for (int i = 0; i < processedImages.length; i++) {
        final imagePath = '$slideshowPath/frame_${i.toString().padLeft(3, '0')}.jpg';
        final bytes = img.encodeJpg(processedImages[i], quality: 90);
        await File(imagePath).writeAsBytes(bytes);
        savedPaths.add(imagePath);
      }

      // Save thumbnail
      if (processedImages.isNotEmpty) {
        final thumbnailBytes = img.encodeJpg(processedImages[0], quality: 85);
        await File(thumbnailPath).writeAsBytes(thumbnailBytes);
      }

      onProgress?.call(100, 'Photos save ho gayi hain! ✨');

      _lastGeneratedVideo = GeneratedVideo(
        filePath: slideshowPath,
        thumbnailPath: thumbnailPath,
        durationSeconds: durationSeconds,
        style: style,
        backgroundMusic: backgroundMusic,
        photoCount: processedImages.length,
        createdAt: DateTime.now(),
        imagePaths: savedPaths,
        isRealVideo: false,
        outputType: 'images',
      );

      _isGenerating = false;
      return _lastGeneratedVideo;
    } catch (e) {
      if (kDebugMode) debugPrint('Fallback save error: $e');
      _isGenerating = false;
      return null;
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

  /// Save generated video to Downloads folder
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
      
      // Handle GIF output
      if (video.outputType == 'gif' && video.filePath.endsWith('.gif')) {
        onProgress?.call(40, 'GIF copy ho rahi hai...');
        
        final sourceFile = File(video.filePath);
        if (await sourceFile.exists()) {
          final destPath = '${saveDir.path}/Memory_Video.gif';
          await sourceFile.copy(destPath);
          
          // Verify
          final destFile = File(destPath);
          if (await destFile.exists()) {
            final fileSize = await destFile.length();
            final sizeInMB = (fileSize / 1024 / 1024).toStringAsFixed(2);
            
            onProgress?.call(100, 'Video save ho gayi! ✨');
            
            return SaveResult(
              success: true,
              savedPath: destPath,
              message: 'Video save ho gayi! ($sizeInMB MB)\nLocation: $folderName',
              savedCount: 1,
              totalCount: 1,
            );
          }
        }
      }
      
      // Save all images (for slideshow or if GIF failed)
      onProgress?.call(30, 'Photos save ho rahi hain...');
      
      for (int i = 0; i < video.imagePaths.length; i++) {
        final progress = 30 + ((i / video.imagePaths.length) * 65).toInt();
        onProgress?.call(progress, 'Photo ${i + 1}/${video.imagePaths.length} save ho rahi hai...');
        
        try {
          final sourcePath = video.imagePaths[i];
          final fileName = 'Memory_${(i + 1).toString().padLeft(2, '0')}.jpg';
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
        final filePath = _lastGeneratedVideo!.filePath;
        
        if (filePath.endsWith('.gif')) {
          final file = File(filePath);
          if (await file.exists()) await file.delete();
        } else {
          final dir = Directory(filePath);
          if (await dir.exists()) await dir.delete(recursive: true);
        }
        
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
}
