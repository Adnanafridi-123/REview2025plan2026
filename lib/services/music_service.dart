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
  // 🎵 MUSIC LIBRARY 2025 - TRENDING & WOW
  // Premium Quality Background Music
  // ==========================================
  
  static final Map<String, List<MusicTrack>> musicLibrary = {
    
    // 🔥 TRENDING - Viral TikTok/Reels Music
    '🔥 Trending': [
      const MusicTrack(id: 'tr_1', name: 'Viral Beat Drop', artist: 'TikTok Hits', duration: '3:45', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3', category: '🔥 Trending'),
      const MusicTrack(id: 'tr_2', name: 'Aesthetic Vibes', artist: 'Reels Music', duration: '4:12', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3', category: '🔥 Trending'),
      const MusicTrack(id: 'tr_3', name: 'Mood Edit', artist: 'Viral Sounds', duration: '3:30', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3', category: '🔥 Trending'),
      const MusicTrack(id: 'tr_4', name: 'Phonk Racing', artist: 'Drift Music', duration: '3:58', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3', category: '🔥 Trending'),
      const MusicTrack(id: 'tr_5', name: 'Slowed Reverb', artist: 'Chill Edit', duration: '4:20', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3', category: '🔥 Trending'),
      const MusicTrack(id: 'tr_6', name: 'Bass Boosted', artist: 'Car Music', duration: '3:55', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3', category: '🔥 Trending'),
      const MusicTrack(id: 'tr_7', name: 'Sigma Edit', artist: 'Motivational', duration: '4:10', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-7.mp3', category: '🔥 Trending'),
      const MusicTrack(id: 'tr_8', name: 'Rizz Anthem', artist: 'Gen-Z Hits', duration: '3:42', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3', category: '🔥 Trending'),
      const MusicTrack(id: 'tr_9', name: 'Main Character', artist: 'Aesthetic', duration: '4:05', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-9.mp3', category: '🔥 Trending'),
      const MusicTrack(id: 'tr_10', name: 'Glow Up Beat', artist: 'Transformation', duration: '3:48', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-10.mp3', category: '🔥 Trending'),
    ],

    // 💖 MEMORIES - Emotional & Nostalgic
    '💖 Memories': [
      const MusicTrack(id: 'mem_1', name: 'Precious Moments', artist: 'Emotional', duration: '4:30', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-11.mp3', category: '💖 Memories'),
      const MusicTrack(id: 'mem_2', name: 'Flashback Dreams', artist: 'Nostalgic', duration: '5:15', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-12.mp3', category: '💖 Memories'),
      const MusicTrack(id: 'mem_3', name: 'Golden Days', artist: 'Memory Lane', duration: '4:45', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-13.mp3', category: '💖 Memories'),
      const MusicTrack(id: 'mem_4', name: 'Forever Young', artist: 'Youth Memories', duration: '4:20', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-14.mp3', category: '💖 Memories'),
      const MusicTrack(id: 'mem_5', name: 'Time Flies', artist: 'Reflection', duration: '5:00', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-15.mp3', category: '💖 Memories'),
      const MusicTrack(id: 'mem_6', name: 'Beautiful Life', artist: 'Gratitude', duration: '4:35', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-16.mp3', category: '💖 Memories'),
      const MusicTrack(id: 'mem_7', name: 'Tears of Joy', artist: 'Emotional', duration: '4:50', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-17.mp3', category: '💖 Memories'),
      const MusicTrack(id: 'mem_8', name: 'Family Love', artist: 'Heartfelt', duration: '5:10', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3', category: '💖 Memories'),
    ],

    // 🇵🇰 URDU - Pakistani Hits
    '🇵🇰 Urdu': [
      const MusicTrack(id: 'ur_1', name: 'Dil Ki Dharkan', artist: 'Pakistani Pop', duration: '4:25', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3', category: '🇵🇰 Urdu'),
      const MusicTrack(id: 'ur_2', name: 'Mohabbat Ka Safar', artist: 'Romantic', duration: '5:10', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3', category: '🇵🇰 Urdu'),
      const MusicTrack(id: 'ur_3', name: 'Yaadein Teri', artist: 'Nostalgic', duration: '4:45', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3', category: '🇵🇰 Urdu'),
      const MusicTrack(id: 'ur_4', name: 'Khwabon Ki Duniya', artist: 'Dreamy', duration: '4:30', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3', category: '🇵🇰 Urdu'),
      const MusicTrack(id: 'ur_5', name: 'Mera Pakistan', artist: 'Patriotic', duration: '4:55', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3', category: '🇵🇰 Urdu'),
      const MusicTrack(id: 'ur_6', name: 'Ishq Ka Rang', artist: 'Love Songs', duration: '5:20', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-7.mp3', category: '🇵🇰 Urdu'),
      const MusicTrack(id: 'ur_7', name: 'Zindagi Gulzar', artist: 'Happy Vibes', duration: '4:15', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3', category: '🇵🇰 Urdu'),
      const MusicTrack(id: 'ur_8', name: 'Dosti Ka Rishta', artist: 'Friendship', duration: '4:40', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-9.mp3', category: '🇵🇰 Urdu'),
      const MusicTrack(id: 'ur_9', name: 'Shaam Ki Raahein', artist: 'Evening Mood', duration: '5:00', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-10.mp3', category: '🇵🇰 Urdu'),
      const MusicTrack(id: 'ur_10', name: 'Khamoshi', artist: 'Soft Melody', duration: '4:35', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-11.mp3', category: '🇵🇰 Urdu'),
    ],

    // 🏔️ PASHTO - Traditional & Modern
    '🏔️ Pashto': [
      const MusicTrack(id: 'pa_1', name: 'Da Zra Nara', artist: 'Pashto Folk', duration: '4:50', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-12.mp3', category: '🏔️ Pashto'),
      const MusicTrack(id: 'pa_2', name: 'Attan Dance', artist: 'Traditional', duration: '5:30', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-13.mp3', category: '🏔️ Pashto'),
      const MusicTrack(id: 'pa_3', name: 'Meena Zorawara', artist: 'Love Song', duration: '4:25', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-14.mp3', category: '🏔️ Pashto'),
      const MusicTrack(id: 'pa_4', name: 'Peshawar Attan', artist: 'Dance Beat', duration: '5:15', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-15.mp3', category: '🏔️ Pashto'),
      const MusicTrack(id: 'pa_5', name: 'Watan Zama', artist: 'Patriotic', duration: '4:40', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-16.mp3', category: '🏔️ Pashto'),
      const MusicTrack(id: 'pa_6', name: 'Rabab Saaz', artist: 'Instrument', duration: '6:00', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-17.mp3', category: '🏔️ Pashto'),
      const MusicTrack(id: 'pa_7', name: 'Kabul Jan', artist: 'Afghan Classic', duration: '5:45', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3', category: '🏔️ Pashto'),
      const MusicTrack(id: 'pa_8', name: 'Ghara Rasha', artist: 'Modern Pashto', duration: '4:20', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3', category: '🏔️ Pashto'),
      const MusicTrack(id: 'pa_9', name: 'Da Khkulo Rang', artist: 'Nature Song', duration: '4:55', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3', category: '🏔️ Pashto'),
      const MusicTrack(id: 'pa_10', name: 'Malangi Dhol', artist: 'Wedding Beat', duration: '5:10', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3', category: '🏔️ Pashto'),
    ],

    // 🕌 NAAT - Islamic Nasheeds
    '🕌 Naat': [
      const MusicTrack(id: 'nt_1', name: 'Ya Rasool Allah', artist: 'Naat Khawan', duration: '5:30', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3', category: '🕌 Naat'),
      const MusicTrack(id: 'nt_2', name: 'Hasbi Rabbi', artist: 'Spiritual', duration: '4:45', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3', category: '🕌 Naat'),
      const MusicTrack(id: 'nt_3', name: 'Tala Al Badru', artist: 'Classical', duration: '5:15', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-7.mp3', category: '🕌 Naat'),
      const MusicTrack(id: 'nt_4', name: 'Ya Nabi Salam', artist: 'Praise', duration: '6:00', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3', category: '🕌 Naat'),
      const MusicTrack(id: 'nt_5', name: 'Maula Ya Salli', artist: 'Arabic Nasheed', duration: '4:50', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-9.mp3', category: '🕌 Naat'),
      const MusicTrack(id: 'nt_6', name: 'Subhan Allah', artist: 'Dhikr', duration: '5:20', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-10.mp3', category: '🕌 Naat'),
      const MusicTrack(id: 'nt_7', name: 'Allah Hu Allah', artist: 'Sufi', duration: '6:30', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-11.mp3', category: '🕌 Naat'),
      const MusicTrack(id: 'nt_8', name: 'Ramadan Special', artist: 'Blessed', duration: '5:00', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-12.mp3', category: '🕌 Naat'),
      const MusicTrack(id: 'nt_9', name: 'Eid Mubarak', artist: 'Celebration', duration: '4:30', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-13.mp3', category: '🕌 Naat'),
      const MusicTrack(id: 'nt_10', name: 'Dua-e-Khair', artist: 'Prayer', duration: '5:45', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-14.mp3', category: '🕌 Naat'),
    ],

    // 🎹 INSTRUMENTAL - No Vocals
    '🎹 Instrumental': [
      const MusicTrack(id: 'ins_1', name: 'Cinematic Epic', artist: 'Film Score', duration: '5:20', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-15.mp3', category: '🎹 Instrumental'),
      const MusicTrack(id: 'ins_2', name: 'Piano Dreams', artist: 'Solo Piano', duration: '4:45', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-16.mp3', category: '🎹 Instrumental'),
      const MusicTrack(id: 'ins_3', name: 'Guitar Sunrise', artist: 'Acoustic', duration: '4:30', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-17.mp3', category: '🎹 Instrumental'),
      const MusicTrack(id: 'ins_4', name: 'Violin Romance', artist: 'Classical', duration: '5:00', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3', category: '🎹 Instrumental'),
      const MusicTrack(id: 'ins_5', name: 'Orchestra Glory', artist: 'Symphony', duration: '6:15', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3', category: '🎹 Instrumental'),
      const MusicTrack(id: 'ins_6', name: 'Flute Serenity', artist: 'Meditation', duration: '5:30', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3', category: '🎹 Instrumental'),
      const MusicTrack(id: 'ins_7', name: 'Corporate Success', artist: 'Business', duration: '4:20', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3', category: '🎹 Instrumental'),
      const MusicTrack(id: 'ins_8', name: 'Inspiring Journey', artist: 'Motivational', duration: '5:10', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3', category: '🎹 Instrumental'),
      const MusicTrack(id: 'ins_9', name: 'Wedding March', artist: 'Celebration', duration: '4:55', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3', category: '🎹 Instrumental'),
      const MusicTrack(id: 'ins_10', name: 'Sad Violin', artist: 'Emotional', duration: '5:40', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-7.mp3', category: '🎹 Instrumental'),
    ],

    // 🎧 LO-FI - Chill & Study
    '🎧 Lo-Fi': [
      const MusicTrack(id: 'lf_1', name: 'Study Session', artist: 'Lo-Fi Beats', duration: '4:20', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3', category: '🎧 Lo-Fi'),
      const MusicTrack(id: 'lf_2', name: 'Rainy Night', artist: 'Chill Hop', duration: '5:00', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-9.mp3', category: '🎧 Lo-Fi'),
      const MusicTrack(id: 'lf_3', name: 'Coffee Shop', artist: 'Ambient', duration: '4:35', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-10.mp3', category: '🎧 Lo-Fi'),
      const MusicTrack(id: 'lf_4', name: 'Late Night Drive', artist: 'Chill', duration: '4:50', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-11.mp3', category: '🎧 Lo-Fi'),
      const MusicTrack(id: 'lf_5', name: 'Dreamy Clouds', artist: 'Relaxing', duration: '5:15', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-12.mp3', category: '🎧 Lo-Fi'),
      const MusicTrack(id: 'lf_6', name: 'Midnight Jazz', artist: 'Lo-Fi Jazz', duration: '4:40', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-13.mp3', category: '🎧 Lo-Fi'),
      const MusicTrack(id: 'lf_7', name: 'Sunset Vibes', artist: 'Golden Hour', duration: '4:25', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-14.mp3', category: '🎧 Lo-Fi'),
      const MusicTrack(id: 'lf_8', name: 'Vinyl Crackle', artist: 'Retro Lo-Fi', duration: '5:30', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-15.mp3', category: '🎧 Lo-Fi'),
    ],

    // 🎉 PARTY - Upbeat & Dance
    '🎉 Party': [
      const MusicTrack(id: 'pt_1', name: 'EDM Drop', artist: 'Electronic', duration: '4:00', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-16.mp3', category: '🎉 Party'),
      const MusicTrack(id: 'pt_2', name: 'Club Nights', artist: 'House Music', duration: '4:30', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-17.mp3', category: '🎉 Party'),
      const MusicTrack(id: 'pt_3', name: 'Bass Boosted', artist: 'Heavy Bass', duration: '3:55', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3', category: '🎉 Party'),
      const MusicTrack(id: 'pt_4', name: 'Festival Anthem', artist: 'Big Room', duration: '4:20', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3', category: '🎉 Party'),
      const MusicTrack(id: 'pt_5', name: 'Dance Floor', artist: 'Pop Dance', duration: '3:45', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3', category: '🎉 Party'),
      const MusicTrack(id: 'pt_6', name: 'Techno Rave', artist: 'Techno', duration: '5:10', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3', category: '🎉 Party'),
      const MusicTrack(id: 'pt_7', name: 'Summer Hit', artist: 'Beach Party', duration: '3:50', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3', category: '🎉 Party'),
      const MusicTrack(id: 'pt_8', name: 'Disco Fever', artist: 'Retro Dance', duration: '4:15', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3', category: '🎉 Party'),
    ],

    // 🎬 CINEMATIC - Epic & Dramatic
    '🎬 Cinematic': [
      const MusicTrack(id: 'cn_1', name: 'Epic Battle', artist: 'Action Score', duration: '5:30', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-7.mp3', category: '🎬 Cinematic'),
      const MusicTrack(id: 'cn_2', name: 'Hero Theme', artist: 'Adventure', duration: '4:45', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3', category: '🎬 Cinematic'),
      const MusicTrack(id: 'cn_3', name: 'Emotional Strings', artist: 'Drama', duration: '5:00', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-9.mp3', category: '🎬 Cinematic'),
      const MusicTrack(id: 'cn_4', name: 'Trailer Music', artist: 'Blockbuster', duration: '3:30', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-10.mp3', category: '🎬 Cinematic'),
      const MusicTrack(id: 'cn_5', name: 'Suspense Build', artist: 'Thriller', duration: '4:20', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-11.mp3', category: '🎬 Cinematic'),
      const MusicTrack(id: 'cn_6', name: 'Victory March', artist: 'Triumph', duration: '4:55', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-12.mp3', category: '🎬 Cinematic'),
      const MusicTrack(id: 'cn_7', name: 'Sad Ending', artist: 'Emotional', duration: '5:20', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-13.mp3', category: '🎬 Cinematic'),
      const MusicTrack(id: 'cn_8', name: 'Fantasy World', artist: 'Magic', duration: '5:10', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-14.mp3', category: '🎬 Cinematic'),
    ],

    // 🌙 AMBIENT - Relaxing & Calm
    '🌙 Ambient': [
      const MusicTrack(id: 'am_1', name: 'Ocean Waves', artist: 'Nature Sounds', duration: '6:00', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-15.mp3', category: '🌙 Ambient'),
      const MusicTrack(id: 'am_2', name: 'Forest Rain', artist: 'ASMR', duration: '5:30', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-16.mp3', category: '🌙 Ambient'),
      const MusicTrack(id: 'am_3', name: 'Meditation Bell', artist: 'Zen', duration: '7:00', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-17.mp3', category: '🌙 Ambient'),
      const MusicTrack(id: 'am_4', name: 'Space Journey', artist: 'Cosmic', duration: '6:30', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3', category: '🌙 Ambient'),
      const MusicTrack(id: 'am_5', name: 'Deep Sleep', artist: 'Relaxation', duration: '8:00', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3', category: '🌙 Ambient'),
      const MusicTrack(id: 'am_6', name: 'Healing Tones', artist: 'Therapy', duration: '5:45', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3', category: '🌙 Ambient'),
      const MusicTrack(id: 'am_7', name: 'Wind Chimes', artist: 'Peaceful', duration: '4:50', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3', category: '🌙 Ambient'),
      const MusicTrack(id: 'am_8', name: 'Tibetan Bowls', artist: 'Spiritual', duration: '6:15', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3', category: '🌙 Ambient'),
    ],

    // 💪 MOTIVATION - Workout & Gym
    '💪 Motivation': [
      const MusicTrack(id: 'mv_1', name: 'Workout Beast', artist: 'Gym Music', duration: '4:00', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3', category: '💪 Motivation'),
      const MusicTrack(id: 'mv_2', name: 'Never Give Up', artist: 'Inspirational', duration: '4:30', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-7.mp3', category: '💪 Motivation'),
      const MusicTrack(id: 'mv_3', name: 'Champion Rise', artist: 'Sports', duration: '3:55', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3', category: '💪 Motivation'),
      const MusicTrack(id: 'mv_4', name: 'Push Limits', artist: 'Training', duration: '4:15', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-9.mp3', category: '💪 Motivation'),
      const MusicTrack(id: 'mv_5', name: 'Victory Run', artist: 'Running', duration: '4:45', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-10.mp3', category: '💪 Motivation'),
      const MusicTrack(id: 'mv_6', name: 'Sigma Grindset', artist: 'Hustle', duration: '3:40', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-11.mp3', category: '💪 Motivation'),
      const MusicTrack(id: 'mv_7', name: 'Boss Mode', artist: 'Power', duration: '4:10', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-12.mp3', category: '💪 Motivation'),
      const MusicTrack(id: 'mv_8', name: 'Unstoppable', artist: 'Energy', duration: '4:25', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-13.mp3', category: '💪 Motivation'),
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
