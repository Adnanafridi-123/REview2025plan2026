// Media items for photos and videos from device
class MediaItem {
  final String id;
  final String path;
  final MediaType type;
  final DateTime date;
  final int? duration; // For videos, in seconds
  final String? thumbnailPath;
  
  MediaItem({
    required this.id,
    required this.path,
    required this.type,
    required this.date,
    this.duration,
    this.thumbnailPath,
  });
  
  bool get isPhoto => type == MediaType.photo;
  bool get isVideo => type == MediaType.video;
  
  String get durationFormatted {
    if (duration == null) return '';
    final minutes = duration! ~/ 60;
    final seconds = duration! % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

enum MediaType { photo, video }

// Empty media data - no mock/dummy data
class MockMediaData {
  // Return empty lists - no dummy data
  static List<MediaItem> getMockPhotos() {
    return [];
  }
  
  static List<MediaItem> getMockVideos() {
    return [];
  }
}
