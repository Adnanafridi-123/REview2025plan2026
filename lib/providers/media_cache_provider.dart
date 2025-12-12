import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

/// Global media cache provider to persist photos/videos data across screens
/// This prevents reloading when user goes back and returns
class MediaCacheProvider extends ChangeNotifier {
  // Singleton pattern
  static final MediaCacheProvider _instance = MediaCacheProvider._internal();
  factory MediaCacheProvider() => _instance;
  MediaCacheProvider._internal();

  // Photos cache
  Map<String, List<AssetEntity>> _photosByMonth = {};
  List<String> _photoMonths = [];
  int _totalPhotos = 0;
  bool _photosLoaded = false;

  // Videos cache
  Map<String, List<AssetEntity>> _videosByMonth = {};
  List<String> _videoMonths = [];
  int _totalVideos = 0;
  bool _videosLoaded = false;

  // Selected items for video creation
  final Set<String> _selectedPhotoIds = {};
  final Set<String> _selectedVideoIds = {};

  // Getters for photos
  Map<String, List<AssetEntity>> get photosByMonth => _photosByMonth;
  List<String> get photoMonths => _photoMonths;
  int get totalPhotos => _totalPhotos;
  bool get photosLoaded => _photosLoaded;

  // Getters for videos
  Map<String, List<AssetEntity>> get videosByMonth => _videosByMonth;
  List<String> get videoMonths => _videoMonths;
  int get totalVideos => _totalVideos;
  bool get videosLoaded => _videosLoaded;

  // Selection getters
  Set<String> get selectedPhotoIds => _selectedPhotoIds;
  Set<String> get selectedVideoIds => _selectedVideoIds;
  int get selectedCount => _selectedPhotoIds.length + _selectedVideoIds.length;
  bool get hasSelection => selectedCount > 0;

  /// Load photos from gallery (with caching) - FIXED: No duplicates
  Future<void> loadPhotos({bool forceRefresh = false}) async {
    // Return cached data if available and not forcing refresh
    if (_photosLoaded && !forceRefresh) {
      return;
    }

    // Completely reset cache
    _photosByMonth = {};
    _photoMonths = [];
    _totalPhotos = 0;
    _photosLoaded = false;

    try {
      final permission = await PhotoManager.requestPermissionExtend();
      if (!permission.isAuth) {
        debugPrint('Photo permission denied');
        return;
      }

      // Get ONLY the "Recent" or first album to avoid duplicates from multiple albums
      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        filterOption: FilterOptionGroup(
          imageOption: const FilterOption(
            sizeConstraint: SizeConstraint(ignoreSize: true),
          ),
          createTimeCond: DateTimeCond(
            min: DateTime(2025, 1, 1),
            max: DateTime(2025, 12, 31, 23, 59, 59),
          ),
        ),
      );

      if (albums.isEmpty) {
        _photosLoaded = true;
        notifyListeners();
        return;
      }

      // Use only the first album (usually "Recent" or "All Photos") to avoid duplicates
      final mainAlbum = albums.first;
      final int count = await mainAlbum.assetCountAsync;
      
      if (count == 0) {
        _photosLoaded = true;
        notifyListeners();
        return;
      }

      final List<AssetEntity> allAssets = await mainAlbum.getAssetListRange(
        start: 0,
        end: count,
      );

      Map<String, List<AssetEntity>> photosByMonth = {};
      Set<String> addedIds = {};
      int totalCount = 0;

      for (final asset in allAssets) {
        // Double-check for duplicates using ID
        if (addedIds.contains(asset.id)) continue;
        
        final date = asset.createDateTime;
        if (date.year == 2025) {
          final monthKey = _getMonthKey(date);
          photosByMonth.putIfAbsent(monthKey, () => []);
          photosByMonth[monthKey]!.add(asset);
          addedIds.add(asset.id);
          totalCount++;
        }
      }
      
      debugPrint('✓ Loaded $totalCount unique photos from ${mainAlbum.name}');

      // Sort photos within each month (newest first)
      for (final month in photosByMonth.keys) {
        photosByMonth[month]!.sort((a, b) => 
          b.createDateTime.compareTo(a.createDateTime));
      }

      // Sort months (newest first)
      final sortedMonths = photosByMonth.keys.toList()
        ..sort((a, b) => _monthOrder(b).compareTo(_monthOrder(a)));

      _photosByMonth = photosByMonth;
      _photoMonths = ['All', ...sortedMonths];
      _totalPhotos = totalCount;
      _photosLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading photos: $e');
    }
  }

  /// Load videos from gallery (with caching) - FIXED: No duplicates
  Future<void> loadVideos({bool forceRefresh = false}) async {
    if (_videosLoaded && !forceRefresh) {
      return;
    }

    // Completely reset cache
    _videosByMonth = {};
    _videoMonths = [];
    _totalVideos = 0;
    _videosLoaded = false;

    try {
      final permission = await PhotoManager.requestPermissionExtend();
      if (!permission.isAuth) {
        debugPrint('Video permission denied');
        return;
      }

      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.video,
        filterOption: FilterOptionGroup(
          videoOption: const FilterOption(
            sizeConstraint: SizeConstraint(ignoreSize: true),
          ),
          createTimeCond: DateTimeCond(
            min: DateTime(2025, 1, 1),
            max: DateTime(2025, 12, 31, 23, 59, 59),
          ),
        ),
      );

      if (albums.isEmpty) {
        _videosLoaded = true;
        notifyListeners();
        return;
      }

      // Use only the first album to avoid duplicates
      final mainAlbum = albums.first;
      final int count = await mainAlbum.assetCountAsync;
      
      if (count == 0) {
        _videosLoaded = true;
        notifyListeners();
        return;
      }

      final List<AssetEntity> allAssets = await mainAlbum.getAssetListRange(
        start: 0,
        end: count,
      );

      Map<String, List<AssetEntity>> videosByMonth = {};
      Set<String> addedIds = {};
      int totalCount = 0;

      for (final asset in allAssets) {
        if (addedIds.contains(asset.id)) continue;
        
        final date = asset.createDateTime;
        if (date.year == 2025) {
          final monthKey = _getMonthKey(date);
          videosByMonth.putIfAbsent(monthKey, () => []);
          videosByMonth[monthKey]!.add(asset);
          addedIds.add(asset.id);
          totalCount++;
        }
      }
      
      debugPrint('✓ Loaded $totalCount unique videos from ${mainAlbum.name}');

      // Sort videos within each month
      for (final month in videosByMonth.keys) {
        videosByMonth[month]!.sort((a, b) => 
          b.createDateTime.compareTo(a.createDateTime));
      }

      // Sort months
      final sortedMonths = videosByMonth.keys.toList()
        ..sort((a, b) => _monthOrder(b).compareTo(_monthOrder(a)));

      _videosByMonth = videosByMonth;
      _videoMonths = ['All', ...sortedMonths];
      _totalVideos = totalCount;
      _videosLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading videos: $e');
    }
  }

  /// Refresh photos (check for new ones)
  Future<void> refreshPhotos() async {
    await loadPhotos(forceRefresh: true);
  }

  /// Refresh videos (check for new ones)
  Future<void> refreshVideos() async {
    await loadVideos(forceRefresh: true);
  }

  /// Toggle photo selection
  void togglePhotoSelection(String assetId) {
    if (_selectedPhotoIds.contains(assetId)) {
      _selectedPhotoIds.remove(assetId);
    } else {
      _selectedPhotoIds.add(assetId);
    }
    notifyListeners();
  }

  /// Toggle video selection
  void toggleVideoSelection(String assetId) {
    if (_selectedVideoIds.contains(assetId)) {
      _selectedVideoIds.remove(assetId);
    } else {
      _selectedVideoIds.add(assetId);
    }
    notifyListeners();
  }

  /// Check if photo is selected
  bool isPhotoSelected(String assetId) => _selectedPhotoIds.contains(assetId);

  /// Check if video is selected
  bool isVideoSelected(String assetId) => _selectedVideoIds.contains(assetId);

  /// Clear all selections
  void clearSelection() {
    _selectedPhotoIds.clear();
    _selectedVideoIds.clear();
    notifyListeners();
  }

  /// Get all selected photo assets
  List<AssetEntity> getSelectedPhotos() {
    List<AssetEntity> selected = [];
    for (final photos in _photosByMonth.values) {
      for (final photo in photos) {
        if (_selectedPhotoIds.contains(photo.id)) {
          selected.add(photo);
        }
      }
    }
    return selected;
  }

  /// Get all selected video assets
  List<AssetEntity> getSelectedVideos() {
    List<AssetEntity> selected = [];
    for (final videos in _videosByMonth.values) {
      for (final video in videos) {
        if (_selectedVideoIds.contains(video.id)) {
          selected.add(video);
        }
      }
    }
    return selected;
  }

  /// Get selected photo files
  Future<List<File>> getSelectedPhotoFiles() async {
    List<File> files = [];
    final selectedPhotos = getSelectedPhotos();
    for (final photo in selectedPhotos) {
      final file = await photo.file;
      if (file != null) {
        files.add(file);
      }
    }
    return files;
  }

  /// Get all photos as flat list (with duplicate removal)
  List<AssetEntity> getAllPhotosFlat() {
    List<AssetEntity> all = [];
    Set<String> seenIds = {};
    
    for (final photos in _photosByMonth.values) {
      for (final photo in photos) {
        // Only add if not already seen
        if (!seenIds.contains(photo.id)) {
          all.add(photo);
          seenIds.add(photo.id);
        }
      }
    }
    all.sort((a, b) => b.createDateTime.compareTo(a.createDateTime));
    return all;
  }

  /// Get all videos as flat list (with duplicate removal)
  List<AssetEntity> getAllVideosFlat() {
    List<AssetEntity> all = [];
    Set<String> seenIds = {};
    
    for (final videos in _videosByMonth.values) {
      for (final video in videos) {
        // Only add if not already seen
        if (!seenIds.contains(video.id)) {
          all.add(video);
          seenIds.add(video.id);
        }
      }
    }
    all.sort((a, b) => b.createDateTime.compareTo(a.createDateTime));
    return all;
  }

  String _getMonthKey(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} 2025';
  }

  int _monthOrder(String monthKey) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    for (int i = 0; i < months.length; i++) {
      if (monthKey.startsWith(months[i])) return i;
    }
    return 0;
  }
}
