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
  
  // Initialize media boxes
  static Future<void> init() async {
    await Hive.openBox<Map>(photosBox);
    await Hive.openBox<Map>(videosBox);
    await Hive.openBox<Map>(screenshotsBox);
  }
  
  // ==========================================
  // PHOTO OPERATIONS
  // ==========================================
  
  /// Pick photo from gallery
  static Future<MediaItem?> pickPhotoFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (image != null) {
        return await _savePhoto(image);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error picking photo from gallery: $e');
      }
    }
    return null;
  }
  
  /// Take photo with camera
  static Future<MediaItem?> takePhotoWithCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (image != null) {
        return await _savePhoto(image);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error taking photo: $e');
      }
    }
    return null;
  }
  
  /// Pick multiple photos from gallery
  static Future<List<MediaItem>> pickMultiplePhotos() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
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
    }
    return [];
  }
  
  /// Save photo to app storage
  static Future<MediaItem?> _savePhoto(XFile file) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final photosDir = Directory('${appDir.path}/photos');
      if (!await photosDir.exists()) {
        await photosDir.create(recursive: true);
      }
      
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final savedPath = '${photosDir.path}/$fileName';
      
      // Copy file to app directory
      if (!kIsWeb) {
        await File(file.path).copy(savedPath);
      }
      
      final mediaItem = MediaItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        path: kIsWeb ? file.path : savedPath,
        type: MediaType.photo,
        date: DateTime.now(),
      );
      
      // Save to Hive
      final box = Hive.box<Map>(photosBox);
      await box.put(mediaItem.id, {
        'id': mediaItem.id,
        'path': mediaItem.path,
        'type': 'photo',
        'date': mediaItem.date.toIso8601String(),
      });
      
      return mediaItem;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error saving photo: $e');
      }
    }
    return null;
  }
  
  /// Get all saved photos
  static List<MediaItem> getAllPhotos() {
    try {
      final box = Hive.box<Map>(photosBox);
      return box.values.map((map) {
        return MediaItem(
          id: map['id'] as String,
          path: map['path'] as String,
          type: MediaType.photo,
          date: DateTime.parse(map['date'] as String),
        );
      }).toList()..sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting photos: $e');
      }
    }
    return [];
  }
  
  /// Delete photo
  static Future<void> deletePhoto(String id) async {
    try {
      final box = Hive.box<Map>(photosBox);
      final photoData = box.get(id);
      
      if (photoData != null && !kIsWeb) {
        final file = File(photoData['path'] as String);
        if (await file.exists()) {
          await file.delete();
        }
      }
      
      await box.delete(id);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting photo: $e');
      }
    }
  }
  
  // ==========================================
  // VIDEO OPERATIONS
  // ==========================================
  
  /// Pick video from gallery
  static Future<MediaItem?> pickVideoFromGallery() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 10),
      );
      
      if (video != null) {
        return await _saveVideo(video);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error picking video from gallery: $e');
      }
    }
    return null;
  }
  
  /// Record video with camera
  static Future<MediaItem?> recordVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 5),
      );
      
      if (video != null) {
        return await _saveVideo(video);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error recording video: $e');
      }
    }
    return null;
  }
  
  /// Save video to app storage
  static Future<MediaItem?> _saveVideo(XFile file) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final videosDir = Directory('${appDir.path}/videos');
      if (!await videosDir.exists()) {
        await videosDir.create(recursive: true);
      }
      
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final savedPath = '${videosDir.path}/$fileName';
      
      // Copy file to app directory
      if (!kIsWeb) {
        await File(file.path).copy(savedPath);
      }
      
      final mediaItem = MediaItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        path: kIsWeb ? file.path : savedPath,
        type: MediaType.video,
        date: DateTime.now(),
        duration: 0, // Would need video_info package for actual duration
      );
      
      // Save to Hive
      final box = Hive.box<Map>(videosBox);
      await box.put(mediaItem.id, {
        'id': mediaItem.id,
        'path': mediaItem.path,
        'type': 'video',
        'date': mediaItem.date.toIso8601String(),
        'duration': mediaItem.duration ?? 0,
      });
      
      return mediaItem;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error saving video: $e');
      }
    }
    return null;
  }
  
  /// Get all saved videos
  static List<MediaItem> getAllVideos() {
    try {
      final box = Hive.box<Map>(videosBox);
      return box.values.map((map) {
        return MediaItem(
          id: map['id'] as String,
          path: map['path'] as String,
          type: MediaType.video,
          date: DateTime.parse(map['date'] as String),
          duration: map['duration'] as int?,
        );
      }).toList()..sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting videos: $e');
      }
    }
    return [];
  }
  
  /// Delete video
  static Future<void> deleteVideo(String id) async {
    try {
      final box = Hive.box<Map>(videosBox);
      final videoData = box.get(id);
      
      if (videoData != null && !kIsWeb) {
        final file = File(videoData['path'] as String);
        if (await file.exists()) {
          await file.delete();
        }
      }
      
      await box.delete(id);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting video: $e');
      }
    }
  }
  
  // ==========================================
  // SCREENSHOT OPERATIONS
  // ==========================================
  
  /// Pick screenshot from gallery
  static Future<MediaItem?> pickScreenshot() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );
      
      if (image != null) {
        return await _saveScreenshot(image);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error picking screenshot: $e');
      }
    }
    return null;
  }
  
  /// Save screenshot to app storage
  static Future<MediaItem?> _saveScreenshot(XFile file) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final screenshotsDir = Directory('${appDir.path}/screenshots');
      if (!await screenshotsDir.exists()) {
        await screenshotsDir.create(recursive: true);
      }
      
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final savedPath = '${screenshotsDir.path}/$fileName';
      
      // Copy file to app directory
      if (!kIsWeb) {
        await File(file.path).copy(savedPath);
      }
      
      final mediaItem = MediaItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        path: kIsWeb ? file.path : savedPath,
        type: MediaType.photo,
        date: DateTime.now(),
      );
      
      // Save to Hive
      final box = Hive.box<Map>(screenshotsBox);
      await box.put(mediaItem.id, {
        'id': mediaItem.id,
        'path': mediaItem.path,
        'type': 'screenshot',
        'date': mediaItem.date.toIso8601String(),
      });
      
      return mediaItem;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error saving screenshot: $e');
      }
    }
    return null;
  }
  
  /// Get all saved screenshots
  static List<MediaItem> getAllScreenshots() {
    try {
      final box = Hive.box<Map>(screenshotsBox);
      return box.values.map((map) {
        return MediaItem(
          id: map['id'] as String,
          path: map['path'] as String,
          type: MediaType.photo,
          date: DateTime.parse(map['date'] as String),
        );
      }).toList()..sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting screenshots: $e');
      }
    }
    return [];
  }
  
  /// Delete screenshot
  static Future<void> deleteScreenshot(String id) async {
    try {
      final box = Hive.box<Map>(screenshotsBox);
      final data = box.get(id);
      
      if (data != null && !kIsWeb) {
        final file = File(data['path'] as String);
        if (await file.exists()) {
          await file.delete();
        }
      }
      
      await box.delete(id);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting screenshot: $e');
      }
    }
  }
  
  // ==========================================
  // STATS & UTILITIES
  // ==========================================
  
  /// Get media counts
  static Map<String, int> getMediaCounts() {
    return {
      'photos': Hive.box<Map>(photosBox).length,
      'videos': Hive.box<Map>(videosBox).length,
      'screenshots': Hive.box<Map>(screenshotsBox).length,
    };
  }
  
  /// Clear all media
  static Future<void> clearAllMedia() async {
    await Hive.box<Map>(photosBox).clear();
    await Hive.box<Map>(videosBox).clear();
    await Hive.box<Map>(screenshotsBox).clear();
  }
}
