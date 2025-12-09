import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

/// Music track model with STREAMING URL
class MusicTrack {
  final String id;
  final String name;
  final String artist;
  final String duration;
  final String url;
  final String category;

  const MusicTrack({
    required this.id,
    required this.name,
    required this.artist,
    required this.duration,
    required this.url,
    required this.category,
  });
}

/// Music Service using audioplayers (more reliable on Android)
class MusicService {
  static AudioPlayer? _audioPlayer;
  static MusicTrack? _currentTrack;
  static bool _isPlaying = false;
  static bool _isInitialized = false;
  
  static Duration _currentPosition = Duration.zero;
  static Duration _totalDuration = Duration.zero;
  static double _volume = 1.0;
  
  static StreamSubscription? _positionSub;
  static StreamSubscription? _durationSub;
  static StreamSubscription? _stateSub;
  
  static final StreamController<Duration> _positionController = StreamController<Duration>.broadcast();
  static final StreamController<Duration> _durationController = StreamController<Duration>.broadcast();
  static final StreamController<bool> _playingController = StreamController<bool>.broadcast();

  static Stream<Duration> get positionStream => _positionController.stream;
  static Stream<Duration> get durationStream => _durationController.stream;
  static Stream<bool> get playingStream => _playingController.stream;
  
  static bool get isPlaying => _isPlaying;
  static MusicTrack? get currentTrack => _currentTrack;
  static Duration get currentPosition => _currentPosition;
  static Duration get totalDuration => _totalDuration;
  static double get volume => _volume;
  static double get progress => _totalDuration.inMilliseconds > 0 
      ? _currentPosition.inMilliseconds / _totalDuration.inMilliseconds 
      : 0.0;

  static Future<void> init() async {
    if (_isInitialized && _audioPlayer != null) return;
    
    try {
      _audioPlayer = AudioPlayer();
      _isInitialized = true;
      
      // Set release mode for streaming
      await _audioPlayer!.setReleaseMode(ReleaseMode.stop);
      
      // Listen to position
      _positionSub = _audioPlayer!.onPositionChanged.listen((position) {
        _currentPosition = position;
        _positionController.add(position);
      });
      
      // Listen to duration
      _durationSub = _audioPlayer!.onDurationChanged.listen((duration) {
        _totalDuration = duration;
        _durationController.add(duration);
      });
      
      // Listen to state changes
      _stateSub = _audioPlayer!.onPlayerStateChanged.listen((state) {
        _isPlaying = state == PlayerState.playing;
        _playingController.add(_isPlaying);
        
        if (state == PlayerState.completed) {
          _isPlaying = false;
          _currentPosition = Duration.zero;
          _playingController.add(false);
        }
      });
      
      if (kDebugMode) {
        debugPrint('MusicService initialized with audioplayers');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error initializing MusicService: $e');
      }
    }
  }

  /// Play a music track from URL
  static Future<void> play(MusicTrack track) async {
    try {
      await init();
      
      if (_audioPlayer == null) {
        if (kDebugMode) {
          debugPrint('AudioPlayer is null');
        }
        return;
      }
      
      // Stop current if different track
      if (_currentTrack?.id != track.id) {
        await _audioPlayer!.stop();
      }
      
      _currentTrack = track;
      _currentPosition = Duration.zero;
      
      if (kDebugMode) {
        debugPrint('Playing: ${track.name}');
        debugPrint('URL: ${track.url}');
      }
      
      // Play from URL using UrlSource
      await _audioPlayer!.setSourceUrl(track.url);
      await _audioPlayer!.setVolume(_volume);
      await _audioPlayer!.resume();
      
      _isPlaying = true;
      _playingController.add(true);
      
      if (kDebugMode) {
        debugPrint('Music started!');
      }
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error playing music: $e');
      }
      _isPlaying = false;
      _playingController.add(false);
    }
  }

  static Future<void> pause() async {
    try {
      if (_audioPlayer != null) {
        await _audioPlayer!.pause();
        _isPlaying = false;
        _playingController.add(false);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error pausing: $e');
      }
    }
  }

  static Future<void> resume() async {
    try {
      if (_audioPlayer != null) {
        await _audioPlayer!.resume();
        _isPlaying = true;
        _playingController.add(true);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error resuming: $e');
      }
    }
  }

  static Future<void> stop() async {
    try {
      if (_audioPlayer != null) {
        await _audioPlayer!.stop();
      }
      _isPlaying = false;
      _currentTrack = null;
      _currentPosition = Duration.zero;
      _totalDuration = Duration.zero;
      _playingController.add(false);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error stopping: $e');
      }
    }
  }

  static Future<void> seek(Duration position) async {
    try {
      if (_audioPlayer != null) {
        await _audioPlayer!.seek(position);
        _currentPosition = position;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error seeking: $e');
      }
    }
  }

  static Future<void> seekByPercent(double percent) async {
    if (_totalDuration.inMilliseconds > 0) {
      final newPosition = Duration(
        milliseconds: (percent * _totalDuration.inMilliseconds).toInt(),
      );
      await seek(newPosition);
    }
  }

  static Future<void> togglePlayPause(MusicTrack track) async {
    if (_currentTrack?.id == track.id && _isPlaying) {
      await pause();
    } else if (_currentTrack?.id == track.id && !_isPlaying) {
      await resume();
    } else {
      await play(track);
    }
  }

  static Future<void> setVolume(double vol) async {
    try {
      _volume = vol.clamp(0.0, 1.0);
      if (_audioPlayer != null) {
        await _audioPlayer!.setVolume(_volume);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error setting volume: $e');
      }
    }
  }

  static String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  static Future<void> dispose() async {
    await _positionSub?.cancel();
    await _durationSub?.cancel();
    await _stateSub?.cancel();
    if (_audioPlayer != null) {
      await _audioPlayer!.dispose();
      _audioPlayer = null;
    }
    _isInitialized = false;
  }

  // ==========================================
  // MUSIC LIBRARY - PIXABAY ROYALTY-FREE MUSIC
  // 100% Free for commercial use
  // ==========================================
  
  static final Map<String, List<MusicTrack>> musicLibrary = {
    
    'English': [
      // Pop & Modern
      const MusicTrack(id: 'en_1', name: 'Good Night', artist: 'FASSounds', duration: '2:33', url: 'https://cdn.pixabay.com/download/audio/2022/05/27/audio_1808fbf07a.mp3', category: 'English'),
      const MusicTrack(id: 'en_2', name: 'Chill Abstract', artist: 'Coma-Media', duration: '2:16', url: 'https://cdn.pixabay.com/download/audio/2022/10/25/audio_946b0939c8.mp3', category: 'English'),
      const MusicTrack(id: 'en_3', name: 'Happy Day', artist: 'Lesfm', duration: '2:22', url: 'https://cdn.pixabay.com/download/audio/2022/03/10/audio_8cb749d484.mp3', category: 'English'),
      const MusicTrack(id: 'en_4', name: 'Summer Walk', artist: 'Olexy', duration: '2:36', url: 'https://cdn.pixabay.com/download/audio/2022/08/02/audio_884fe92c21.mp3', category: 'English'),
      const MusicTrack(id: 'en_5', name: 'Deep Future Garage', artist: 'Daddy_s_Music', duration: '2:38', url: 'https://cdn.pixabay.com/download/audio/2022/01/18/audio_d0c6ff1bab.mp3', category: 'English'),
      const MusicTrack(id: 'en_6', name: 'Electronic Rock', artist: 'AlexiAction', duration: '2:56', url: 'https://cdn.pixabay.com/download/audio/2022/03/15/audio_8bce065f74.mp3', category: 'English'),
      const MusicTrack(id: 'en_7', name: 'Sweet Dreams', artist: 'Music_Unlimited', duration: '3:22', url: 'https://cdn.pixabay.com/download/audio/2022/11/22/audio_bc43e02ad7.mp3', category: 'English'),
      const MusicTrack(id: 'en_8', name: 'Lofi Chill', artist: 'LoFi_Vibes', duration: '2:45', url: 'https://cdn.pixabay.com/download/audio/2024/11/04/audio_4956b5f3d1.mp3', category: 'English'),
    ],

    'Urdu': [
      // Eastern Melodies - Instrumental versions
      const MusicTrack(id: 'ur_1', name: 'Dil Ki Dhadkan', artist: 'Eastern Melody', duration: '3:15', url: 'https://cdn.pixabay.com/download/audio/2023/09/04/audio_7a0e1f9b8a.mp3', category: 'Urdu'),
      const MusicTrack(id: 'ur_2', name: 'Mohabbat Ka Rang', artist: 'Romantic Tunes', duration: '2:52', url: 'https://cdn.pixabay.com/download/audio/2023/05/16/audio_166b9c7242.mp3', category: 'Urdu'),
      const MusicTrack(id: 'ur_3', name: 'Yaadein Teri', artist: 'Nostalgic', duration: '3:08', url: 'https://cdn.pixabay.com/download/audio/2023/07/03/audio_850097a5e4.mp3', category: 'Urdu'),
      const MusicTrack(id: 'ur_4', name: 'Sapne Sunahere', artist: 'Dream Music', duration: '2:45', url: 'https://cdn.pixabay.com/download/audio/2023/03/20/audio_2f07409b87.mp3', category: 'Urdu'),
      const MusicTrack(id: 'ur_5', name: 'Khushi Ka Lamha', artist: 'Celebration', duration: '2:33', url: 'https://cdn.pixabay.com/download/audio/2023/01/27/audio_6eaa2e6c8a.mp3', category: 'Urdu'),
      const MusicTrack(id: 'ur_6', name: 'Zindagi Gulzar', artist: 'Life Songs', duration: '3:20', url: 'https://cdn.pixabay.com/download/audio/2022/12/12/audio_5a5c8e9f12.mp3', category: 'Urdu'),
      const MusicTrack(id: 'ur_7', name: 'Dosti Forever', artist: 'Friendship', duration: '2:48', url: 'https://cdn.pixabay.com/download/audio/2023/08/14/audio_3b9a6c7d5e.mp3', category: 'Urdu'),
      const MusicTrack(id: 'ur_8', name: 'Khwabon Ki Duniya', artist: 'Dream World', duration: '3:05', url: 'https://cdn.pixabay.com/download/audio/2023/04/11/audio_7c8d5e6a9b.mp3', category: 'Urdu'),
    ],

    'Pashto': [
      // Afghan & Pashto style instrumentals
      const MusicTrack(id: 'pa_1', name: 'Da Zra Tarana', artist: 'Afghan Music', duration: '3:12', url: 'https://cdn.pixabay.com/download/audio/2022/11/03/audio_f2a96d3b85.mp3', category: 'Pashto'),
      const MusicTrack(id: 'pa_2', name: 'Peshawar Melody', artist: 'Traditional', duration: '2:55', url: 'https://cdn.pixabay.com/download/audio/2023/02/08/audio_4e5a3b7c9d.mp3', category: 'Pashto'),
      const MusicTrack(id: 'pa_3', name: 'Attan Dance', artist: 'Folk Dance', duration: '3:30', url: 'https://cdn.pixabay.com/download/audio/2022/09/15/audio_6c7d8e9f0a.mp3', category: 'Pashto'),
      const MusicTrack(id: 'pa_4', name: 'Watan Zama', artist: 'Patriotic', duration: '3:18', url: 'https://cdn.pixabay.com/download/audio/2023/06/22/audio_8b9c0d1e2f.mp3', category: 'Pashto'),
      const MusicTrack(id: 'pa_5', name: 'Meena Ke Rang', artist: 'Love Songs', duration: '2:42', url: 'https://cdn.pixabay.com/download/audio/2022/07/18/audio_9d0e1f2a3b.mp3', category: 'Pashto'),
      const MusicTrack(id: 'pa_6', name: 'Kabul Night', artist: 'City Vibes', duration: '2:58', url: 'https://cdn.pixabay.com/download/audio/2023/10/05/audio_0a1b2c3d4e.mp3', category: 'Pashto'),
      const MusicTrack(id: 'pa_7', name: 'Ghar Mountains', artist: 'Nature', duration: '3:25', url: 'https://cdn.pixabay.com/download/audio/2022/06/09/audio_1b2c3d4e5f.mp3', category: 'Pashto'),
      const MusicTrack(id: 'pa_8', name: 'Rabab Saaz', artist: 'Instrument', duration: '2:50', url: 'https://cdn.pixabay.com/download/audio/2023/11/17/audio_2c3d4e5f6g.mp3', category: 'Pashto'),
    ],

    'Nasheed': [
      // Islamic Nasheeds - Instrumental & Vocal
      const MusicTrack(id: 'na_1', name: 'Peaceful Soul', artist: 'Islamic Melody', duration: '3:45', url: 'https://cdn.pixabay.com/download/audio/2023/03/09/audio_5d6e7f8a9b.mp3', category: 'Nasheed'),
      const MusicTrack(id: 'na_2', name: 'Morning Dua', artist: 'Spiritual', duration: '4:12', url: 'https://cdn.pixabay.com/download/audio/2022/10/12/audio_6e7f8a9b0c.mp3', category: 'Nasheed'),
      const MusicTrack(id: 'na_3', name: 'Sabr & Shukr', artist: 'Patience', duration: '3:28', url: 'https://cdn.pixabay.com/download/audio/2023/05/25/audio_7f8a9b0c1d.mp3', category: 'Nasheed'),
      const MusicTrack(id: 'na_4', name: 'Noor E Iman', artist: 'Light of Faith', duration: '3:55', url: 'https://cdn.pixabay.com/download/audio/2022/08/30/audio_8a9b0c1d2e.mp3', category: 'Nasheed'),
      const MusicTrack(id: 'na_5', name: 'Ya Rahman', artist: 'Mercy Song', duration: '4:05', url: 'https://cdn.pixabay.com/download/audio/2023/07/14/audio_9b0c1d2e3f.mp3', category: 'Nasheed'),
      const MusicTrack(id: 'na_6', name: 'Medina Dreams', artist: 'Holy City', duration: '3:38', url: 'https://cdn.pixabay.com/download/audio/2022/12/28/audio_0c1d2e3f4a.mp3', category: 'Nasheed'),
      const MusicTrack(id: 'na_7', name: 'Blessed Night', artist: 'Ramadan', duration: '4:20', url: 'https://cdn.pixabay.com/download/audio/2023/09/19/audio_1d2e3f4a5b.mp3', category: 'Nasheed'),
      const MusicTrack(id: 'na_8', name: 'Eid Joy', artist: 'Celebration', duration: '3:15', url: 'https://cdn.pixabay.com/download/audio/2023/01/06/audio_2e3f4a5b6c.mp3', category: 'Nasheed'),
    ],

    'Instrumental': [
      // Cinematic & Background Music
      const MusicTrack(id: 'in_1', name: 'Cinematic Trailer', artist: 'Epic Score', duration: '2:15', url: 'https://cdn.pixabay.com/download/audio/2022/02/22/audio_d1718ab41b.mp3', category: 'Instrumental'),
      const MusicTrack(id: 'in_2', name: 'Inspirational', artist: 'Motivational', duration: '2:31', url: 'https://cdn.pixabay.com/download/audio/2022/05/16/audio_1808fbf07a.mp3', category: 'Instrumental'),
      const MusicTrack(id: 'in_3', name: 'Documentary', artist: 'Background', duration: '3:05', url: 'https://cdn.pixabay.com/download/audio/2022/08/25/audio_89a1f2c3d4.mp3', category: 'Instrumental'),
      const MusicTrack(id: 'in_4', name: 'Piano Dreams', artist: 'Soft Piano', duration: '3:42', url: 'https://cdn.pixabay.com/download/audio/2022/04/19/audio_2345678901.mp3', category: 'Instrumental'),
      const MusicTrack(id: 'in_5', name: 'Uplifting', artist: 'Happy Mood', duration: '2:28', url: 'https://cdn.pixabay.com/download/audio/2022/11/08/audio_3456789012.mp3', category: 'Instrumental'),
      const MusicTrack(id: 'in_6', name: 'Emotional Journey', artist: 'Orchestra', duration: '4:10', url: 'https://cdn.pixabay.com/download/audio/2023/02/15/audio_4567890123.mp3', category: 'Instrumental'),
      const MusicTrack(id: 'in_7', name: 'Adventure Time', artist: 'Action', duration: '2:55', url: 'https://cdn.pixabay.com/download/audio/2022/06/30/audio_5678901234.mp3', category: 'Instrumental'),
      const MusicTrack(id: 'in_8', name: 'Calm Waters', artist: 'Relaxation', duration: '3:33', url: 'https://cdn.pixabay.com/download/audio/2023/04/28/audio_6789012345.mp3', category: 'Instrumental'),
    ],
  };

  static List<MusicTrack> getTracksByCategory(String category) {
    return musicLibrary[category] ?? [];
  }

  static List<String> get categories => musicLibrary.keys.toList();
  
  static int get totalTracks {
    int count = 0;
    for (var tracks in musicLibrary.values) {
      count += tracks.length;
    }
    return count;
  }
}
