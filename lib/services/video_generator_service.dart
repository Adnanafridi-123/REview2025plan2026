// DEPRECATED: This file is kept for backward compatibility
// All video generation now uses LightweightVideoService
// See: lib/services/lightweight_video_service.dart

import 'lightweight_video_service.dart';

export 'lightweight_video_service.dart' show VideoStyle, GeneratedVideo, SaveResult;

/// Backward compatibility wrapper - delegates to LightweightVideoService
class VideoGeneratorService {
  static GeneratedVideo? get lastGeneratedVideo => LightweightVideoService.lastGeneratedVideo;
  static bool get isGenerating => LightweightVideoService.isGenerating;
  
  static Future<GeneratedVideo?> generateVideo({
    required List<String> imagePaths,
    required VideoStyle style,
    required int durationSeconds,
    dynamic backgroundMusic,
    Function(int progress, String status)? onProgress,
  }) => LightweightVideoService.generateVideo(
    imagePaths: imagePaths,
    style: style,
    durationSeconds: durationSeconds,
    backgroundMusic: backgroundMusic,
    onProgress: onProgress,
  );
  
  static Future<SaveResult> saveVideoToDownloads(GeneratedVideo video, {
    Function(int progress, String status)? onProgress,
  }) => LightweightVideoService.saveVideoToDownloads(video, onProgress: onProgress);
  
  static String getStyleName(VideoStyle style) => LightweightVideoService.getStyleName(style);
  static String getStyleDescription(VideoStyle style) => LightweightVideoService.getStyleDescription(style);
  static VideoStyle getStyleFromName(String name) => LightweightVideoService.getStyleFromName(name);
  static Future<void> deleteGeneratedVideo() => LightweightVideoService.deleteGeneratedVideo();
  static String formatDuration(int seconds) => LightweightVideoService.formatDuration(seconds);
}
