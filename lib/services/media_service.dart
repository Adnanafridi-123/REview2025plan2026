import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/media_item.dart';

class MediaService {
  static const String photosBox = 'user_photos';
  static const String videosBox = 'user_videos';
  static const String screenshotsBox = 'user_screenshots';
  
  static final ImagePicker _picker = ImagePicker();
  static bool _isInitialized = false;
  
  // Initialize media boxes - MUST be called before using any media functions
  static Future<void> init() async {
    if (_isInitialized) return;
    
    try {
      // Open all media boxes with dynamic type to handle Map data
      if (!Hive.isBoxOpen(photosBox)) {
        await Hive.openBox<dynamic>(photosBox);
      }
      if (!Hive.isBoxOpen(videosBox)) {
        await Hive.openBox<dynamic>(videosBox);
      }
      if (!Hive.isBoxOpen(screenshotsBox)) {
        await Hive.openBox<dynamic>(screenshotsBox);
      }
      _isInitialized = true;
      if (kDebugMode) {
        debugPrint('MediaService initialized successfully!');
        debugPrint('Photos box open: ${Hive.isBoxOpen(photosBox)}');
        debugPrint('Videos box open: ${Hive.isBoxOpen(videosBox)}');
        debugPrint('Screenshots box open: ${Hive.isBoxOpen(screenshotsBox)}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error initializing media boxes: $e');
      }
      // Reset flag to allow retry
      _isInitialized = false;
    }
  }
  
  // Ensure boxes are open before use - called before every operation
  static Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await init();
    }
    // Double check boxes are open
    if (!Hive.isBoxOpen(photosBox)) {
      await Hive.openBox<dynamic>(photosBox);
    }
    if (!Hive.isBoxOpen(videosBox)) {
      await Hive.openBox<dynamic>(videosBox);
    }
    if (!Hive.isBoxOpen(screenshotsBox)) {
      await Hive.openBox<dynamic>(screenshotsBox);
    }
  }
  
  // ==========================================
  // PHOTO OPERATIONS
  // ==========================================
  
  /// Pick photo from gallery
  static Future<MediaItem?> pickPhotoFromGallery() async {
    try {
      await _ensureInitialized();
      
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (image != null) {
        if (kDebugMode) {
          debugPrint('Photo picked: ${image.path}');
        }
        return await _savePhoto(image);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error picking photo from gallery: $e');
      }
      rethrow;
    }
    return null;
  }
  
  /// Take photo with camera
  static Future<MediaItem?> takePhotoWithCamera() async {
    try {
      await _ensureInitialized();
      
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (image != null) {
        if (kDebugMode) {
          debugPrint('Photo captured: ${image.path}');
        }
        return await _savePhoto(image);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error taking photo: $e');
      }
      rethrow;
    }
    return null;
  }
  
  /// Pick multiple photos from gallery
  static Future<List<MediaItem>> pickMultiplePhotos() async {
    try {
      await _ensureInitialized();
      
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (kDebugMode) {
        debugPrint('Picked ${images.length} photos');
      }
      
      List<MediaItem> mediaItems = [];
      for (var image in images) {
        final item = await _savePhoto(image);
        if (item != null) {
          mediaItems.add(item);
        }
      }
      return mediaItems;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error picking multiple photos: $e');
      }
      rethrow;
    }
  }
  
  /// Save photo to app storage
  static Future<MediaItem?> _savePhoto(XFile file) async {
    try {
      await _ensureInitialized();
      
      String savedPath = file.path;
      
      // On mobile, copy to app directory for persistence
      if (!kIsWeb) {
        final appDir = await getApplicationDocumentsDirectory();
        final photosDir = Directory('${appDir.path}/photos');
        if (!await photosDir.exists()) {
          await photosDir.create(recursive: true);
        }
        
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_photo.jpg';
        savedPath = '${photosDir.path}/$fileName';
        
        // Copy file to app directory
        final bytes = await file.readAsBytes();
        await File(savedPath).writeAsBytes(bytes);
        
        if (kDebugMode) {
          debugPrint('Photo file saved to: $savedPath');
        }
      }
      
      final mediaItem = MediaItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        path: savedPath,
        type: MediaType.photo,
        date: DateTime.now(),
      );
      
      // Save to Hive - use dynamic box type
      final box = Hive.box<dynamic>(photosBox);
      final dataMap = {
        'id': mediaItem.id,
        'path': mediaItem.path,
        'type': 'photo',
        'date': mediaItem.date.toIso8601String(),
      };
      await box.put(mediaItem.id, dataMap);
      
      if (kDebugMode) {
        debugPrint('✅ Photo metadata saved to Hive! Total photos: ${box.length}');
        debugPrint('Photo ID: ${mediaItem.id}');
      }
      
      return mediaItem;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error saving photo: $e');
      }
      rethrow;
    }
  }
  
  /// Get all saved photos
  static List<MediaItem> getAllPhotos() {
    try {
      if (!Hive.isBoxOpen(photosBox)) {
        if (kDebugMode) {
          debugPrint('Photos box not open, returning empty list');
        }
        return [];
      }
      
      final box = Hive.box<dynamic>(photosBox);
      final photos = <MediaItem>[];
      
      for (var value in box.values) {
        try {
          final map = value as Map;
          photos.add(MediaItem(
            id: map['id']?.toString() ?? '',
            path: map['path']?.toString() ?? '',
            type: MediaType.photo,
            date: DateTime.parse(map['date']?.toString() ?? DateTime.now().toIso8601String()),
          ));
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Error parsing photo item: $e');
          }
        }
      }
      
      photos.sort((a, b) => b.date.compareTo(a.date));
      
      if (kDebugMode) {
        debugPrint('✅ Loaded ${photos.length} photos from Hive');
      }
      
      return photos;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting photos: $e');
      }
    }
    return [];
  }
  
  /// Delete photo
  static Future<void> deletePhoto(String id) async {
    try {
      await _ensureInitialized();
      
      final box = Hive.box<dynamic>(photosBox);
      final photoData = box.get(id);
      
      if (photoData != null && !kIsWeb) {
        try {
          final map = photoData as Map;
          final file = File(map['path']?.toString() ?? '');
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Error deleting photo file: $e');
          }
        }
      }
      
      await box.delete(id);
      
      if (kDebugMode) {
        debugPrint('✅ Photo deleted: $id');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error deleting photo: $e');
      }
    }
  }
  
  // ==========================================
  // VIDEO OPERATIONS
  // ==========================================
  
  /// Pick video from gallery
  static Future<MediaItem?> pickVideoFromGallery() async {
    try {
      await _ensureInitialized();
      
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 10),
      );
      
      if (video != null) {
        if (kDebugMode) {
          debugPrint('Video picked: ${video.path}');
        }
        return await _saveVideo(video);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error picking video from gallery: $e');
      }
      rethrow;
    }
    return null;
  }
  
  /// Record video with camera
  static Future<MediaItem?> recordVideo() async {
    try {
      await _ensureInitialized();
      
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 5),
      );
      
      if (video != null) {
        if (kDebugMode) {
          debugPrint('Video recorded: ${video.path}');
        }
        return await _saveVideo(video);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error recording video: $e');
      }
      rethrow;
    }
    return null;
  }
  
  /// Save video to app storage
  static Future<MediaItem?> _saveVideo(XFile file) async {
    try {
      await _ensureInitialized();
      
      String savedPath = file.path;
      
      // On mobile, copy to app directory for persistence
      if (!kIsWeb) {
        final appDir = await getApplicationDocumentsDirectory();
        final videosDir = Directory('${appDir.path}/videos');
        if (!await videosDir.exists()) {
          await videosDir.create(recursive: true);
        }
        
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_video.mp4';
        savedPath = '${videosDir.path}/$fileName';
        
        // Copy file to app directory
        final bytes = await file.readAsBytes();
        await File(savedPath).writeAsBytes(bytes);
        
        if (kDebugMode) {
          debugPrint('Video file saved to: $savedPath');
        }
      }
      
      final mediaItem = MediaItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        path: savedPath,
        type: MediaType.video,
        date: DateTime.now(),
        duration: 0,
      );
      
      // Save to Hive - use dynamic box type
      final box = Hive.box<dynamic>(videosBox);
      final dataMap = {
        'id': mediaItem.id,
        'path': mediaItem.path,
        'type': 'video',
        'date': mediaItem.date.toIso8601String(),
        'duration': mediaItem.duration ?? 0,
      };
      await box.put(mediaItem.id, dataMap);
      
      if (kDebugMode) {
        debugPrint('✅ Video metadata saved to Hive! Total videos: ${box.length}');
        debugPrint('Video ID: ${mediaItem.id}');
      }
      
      return mediaItem;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error saving video: $e');
      }
      rethrow;
    }
  }
  
  /// Get all saved videos
  static List<MediaItem> getAllVideos() {
    try {
      if (!Hive.isBoxOpen(videosBox)) {
        if (kDebugMode) {
          debugPrint('Videos box not open, returning empty list');
        }
        return [];
      }
      
      final box = Hive.box<dynamic>(videosBox);
      final videos = <MediaItem>[];
      
      for (var value in box.values) {
        try {
          final map = value as Map;
          videos.add(MediaItem(
            id: map['id']?.toString() ?? '',
            path: map['path']?.toString() ?? '',
            type: MediaType.video,
            date: DateTime.parse(map['date']?.toString() ?? DateTime.now().toIso8601String()),
            duration: (map['duration'] as num?)?.toInt(),
          ));
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Error parsing video item: $e');
          }
        }
      }
      
      videos.sort((a, b) => b.date.compareTo(a.date));
      
      if (kDebugMode) {
        debugPrint('✅ Loaded ${videos.length} videos from Hive');
      }
      
      return videos;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting videos: $e');
      }
    }
    return [];
  }
  
  /// Delete video
  static Future<void> deleteVideo(String id) async {
    try {
      await _ensureInitialized();
      
      final box = Hive.box<dynamic>(videosBox);
      final videoData = box.get(id);
      
      if (videoData != null && !kIsWeb) {
        try {
          final map = videoData as Map;
          final file = File(map['path']?.toString() ?? '');
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Error deleting video file: $e');
          }
        }
      }
      
      await box.delete(id);
      
      if (kDebugMode) {
        debugPrint('✅ Video deleted: $id');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error deleting video: $e');
      }
    }
  }
  
  // ==========================================
  // SCREENSHOT OPERATIONS
  // ==========================================
  
  /// Pick screenshot from gallery
  static Future<MediaItem?> pickScreenshot() async {
    try {
      await _ensureInitialized();
      
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );
      
      if (image != null) {
        if (kDebugMode) {
          debugPrint('Screenshot picked: ${image.path}');
        }
        return await _saveScreenshot(image);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error picking screenshot: $e');
      }
      rethrow;
    }
    return null;
  }
  
  /// Pick multiple screenshots from gallery
  static Future<List<MediaItem>> pickMultipleScreenshots() async {
    try {
      await _ensureInitialized();
      
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );
      
      if (kDebugMode) {
        debugPrint('Picked ${images.length} screenshots');
      }
      
      List<MediaItem> mediaItems = [];
      for (var image in images) {
        final item = await _saveScreenshot(image);
        if (item != null) {
          mediaItems.add(item);
        }
      }
      return mediaItems;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error picking multiple screenshots: $e');
      }
      rethrow;
    }
  }
  
  /// Save screenshot to app storage
  static Future<MediaItem?> _saveScreenshot(XFile file) async {
    try {
      await _ensureInitialized();
      
      String savedPath = file.path;
      
      // On mobile, copy to app directory for persistence
      if (!kIsWeb) {
        final appDir = await getApplicationDocumentsDirectory();
        final screenshotsDir = Directory('${appDir.path}/screenshots');
        if (!await screenshotsDir.exists()) {
          await screenshotsDir.create(recursive: true);
        }
        
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_screenshot.jpg';
        savedPath = '${screenshotsDir.path}/$fileName';
        
        // Copy file to app directory
        final bytes = await file.readAsBytes();
        await File(savedPath).writeAsBytes(bytes);
        
        if (kDebugMode) {
          debugPrint('Screenshot file saved to: $savedPath');
        }
      }
      
      final mediaItem = MediaItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        path: savedPath,
        type: MediaType.photo,
        date: DateTime.now(),
      );
      
      // Save to Hive - use dynamic box type
      final box = Hive.box<dynamic>(screenshotsBox);
      final dataMap = {
        'id': mediaItem.id,
        'path': mediaItem.path,
        'type': 'screenshot',
        'date': mediaItem.date.toIso8601String(),
      };
      await box.put(mediaItem.id, dataMap);
      
      if (kDebugMode) {
        debugPrint('✅ Screenshot metadata saved to Hive! Total screenshots: ${box.length}');
        debugPrint('Screenshot ID: ${mediaItem.id}');
      }
      
      return mediaItem;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error saving screenshot: $e');
      }
      rethrow;
    }
  }
  
  /// Get all saved screenshots
  static List<MediaItem> getAllScreenshots() {
    try {
      if (!Hive.isBoxOpen(screenshotsBox)) {
        if (kDebugMode) {
          debugPrint('Screenshots box not open, returning empty list');
        }
        return [];
      }
      
      final box = Hive.box<dynamic>(screenshotsBox);
      final screenshots = <MediaItem>[];
      
      for (var value in box.values) {
        try {
          final map = value as Map;
          screenshots.add(MediaItem(
            id: map['id']?.toString() ?? '',
            path: map['path']?.toString() ?? '',
            type: MediaType.photo,
            date: DateTime.parse(map['date']?.toString() ?? DateTime.now().toIso8601String()),
          ));
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Error parsing screenshot item: $e');
          }
        }
      }
      
      screenshots.sort((a, b) => b.date.compareTo(a.date));
      
      if (kDebugMode) {
        debugPrint('✅ Loaded ${screenshots.length} screenshots from Hive');
      }
      
      return screenshots;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting screenshots: $e');
      }
    }
    return [];
  }
  
  /// Delete screenshot
  static Future<void> deleteScreenshot(String id) async {
    try {
      await _ensureInitialized();
      
      final box = Hive.box<dynamic>(screenshotsBox);
      final data = box.get(id);
      
      if (data != null && !kIsWeb) {
        try {
          final map = data as Map;
          final file = File(map['path']?.toString() ?? '');
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Error deleting screenshot file: $e');
          }
        }
      }
      
      await box.delete(id);
      
      if (kDebugMode) {
        debugPrint('✅ Screenshot deleted: $id');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error deleting screenshot: $e');
      }
    }
  }
  
  // ==========================================
  // STATS & UTILITIES
  // ==========================================
  
  /// Get media counts
  static Map<String, int> getMediaCounts() {
    try {
      return {
        'photos': Hive.isBoxOpen(photosBox) ? Hive.box<dynamic>(photosBox).length : 0,
        'videos': Hive.isBoxOpen(videosBox) ? Hive.box<dynamic>(videosBox).length : 0,
        'screenshots': Hive.isBoxOpen(screenshotsBox) ? Hive.box<dynamic>(screenshotsBox).length : 0,
      };
    } catch (e) {
      return {'photos': 0, 'videos': 0, 'screenshots': 0};
    }
  }
  
  /// Clear all media
  static Future<void> clearAllMedia() async {
    try {
      await _ensureInitialized();
      
      if (Hive.isBoxOpen(photosBox)) {
        await Hive.box<dynamic>(photosBox).clear();
      }
      if (Hive.isBoxOpen(videosBox)) {
        await Hive.box<dynamic>(videosBox).clear();
      }
      if (Hive.isBoxOpen(screenshotsBox)) {
        await Hive.box<dynamic>(screenshotsBox).clear();
      }
      
      if (kDebugMode) {
        debugPrint('✅ All media cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error clearing media: $e');
      }
    }
  }
}
