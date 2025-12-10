// This file now delegates to RealVideoService for REAL MP4 video creation
// Keeping this file for backward compatibility with existing imports

export 'real_video_service.dart' show VideoStyle, GeneratedVideo, SaveResult;
import 'real_video_service.dart';

/// LightweightVideoService - Now creates REAL MP4 videos!
/// Delegates all calls to RealVideoService which uses FFmpeg
class LightweightVideoService {
  static GeneratedVideo? get lastGeneratedVideo => RealVideoService.lastGeneratedVideo;
  static bool get isGenerating => RealVideoService.isGenerating;
  
  /// Generate REAL MP4 Video
  static Future<GeneratedVideo?> generateVideo({
    required List<String> imagePaths,
    required VideoStyle style,
    required int durationSeconds,
    dynamic backgroundMusic,
    Function(int progress, String status)? onProgress,
  }) => RealVideoService.generateVideo(
    imagePaths: imagePaths,
    style: style,
    durationSeconds: durationSeconds,
    backgroundMusic: backgroundMusic,
    onProgress: onProgress,
  );
  
  /// Save video to gallery
  static Future<SaveResult> saveVideoToDownloads(GeneratedVideo video, {
    Function(int progress, String status)? onProgress,
  }) => RealVideoService.saveVideoToGallery(video, onProgress: onProgress);
  
  static String getStyleName(VideoStyle style) => RealVideoService.getStyleName(style);
  static String getStyleDescription(VideoStyle style) => RealVideoService.getStyleDescription(style);
  static VideoStyle getStyleFromName(String name) => RealVideoService.getStyleFromName(name);
  static Future<void> deleteGeneratedVideo() => RealVideoService.deleteGeneratedVideo();
  static String formatDuration(int seconds) => RealVideoService.formatDuration(seconds);
  static Future<int> getVideosCreatedCount() => RealVideoService.getVideosCreatedCount();
}
