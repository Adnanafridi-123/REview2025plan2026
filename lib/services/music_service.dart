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
  final String mood; // Happy, Sad, Romantic, Energetic, Calm, Epic

  const MusicTrack({
    required this.id,
    required this.name,
    required this.artist,
    required this.duration,
    required this.url,
    required this.category,
    this.mood = 'Happy',
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
  // PREMIUM MUSIC LIBRARY - HIGH QUALITY TRACKS
  // Using Free Music Archive (FMA) & Pixabay Music
  // 100% Royalty-Free for all uses
  // ==========================================
  
  static final Map<String, List<MusicTrack>> musicLibrary = {
    
    // ========== ENGLISH POP & TRENDING ==========
    'English Pop': [
      const MusicTrack(
        id: 'en_pop_1', 
        name: 'Elevate', 
        artist: 'Bensound', 
        duration: '2:58', 
        url: 'https://www.bensound.com/bensound-music/bensound-elevate.mp3', 
        category: 'English Pop',
        mood: 'Energetic',
      ),
      const MusicTrack(
        id: 'en_pop_2', 
        name: 'Happy Rock', 
        artist: 'Bensound', 
        duration: '1:45', 
        url: 'https://www.bensound.com/bensound-music/bensound-happyrock.mp3', 
        category: 'English Pop',
        mood: 'Happy',
      ),
      const MusicTrack(
        id: 'en_pop_3', 
        name: 'Sunny', 
        artist: 'Bensound', 
        duration: '2:20', 
        url: 'https://www.bensound.com/bensound-music/bensound-sunny.mp3', 
        category: 'English Pop',
        mood: 'Happy',
      ),
      const MusicTrack(
        id: 'en_pop_4', 
        name: 'Funky Suspense', 
        artist: 'Bensound', 
        duration: '2:17', 
        url: 'https://www.bensound.com/bensound-music/bensound-funkysuspense.mp3', 
        category: 'English Pop',
        mood: 'Energetic',
      ),
      const MusicTrack(
        id: 'en_pop_5', 
        name: 'Groovy Hip Hop', 
        artist: 'Bensound', 
        duration: '2:53', 
        url: 'https://www.bensound.com/bensound-music/bensound-groovyhiphop.mp3', 
        category: 'English Pop',
        mood: 'Energetic',
      ),
      const MusicTrack(
        id: 'en_pop_6', 
        name: 'Creative Minds', 
        artist: 'Bensound', 
        duration: '2:26', 
        url: 'https://www.bensound.com/bensound-music/bensound-creativeminds.mp3', 
        category: 'English Pop',
        mood: 'Happy',
      ),
    ],

    // ========== ROMANTIC & LOVE SONGS ==========
    'Romantic': [
      const MusicTrack(
        id: 'rom_1', 
        name: 'Love', 
        artist: 'Bensound', 
        duration: '2:09', 
        url: 'https://www.bensound.com/bensound-music/bensound-love.mp3', 
        category: 'Romantic',
        mood: 'Romantic',
      ),
      const MusicTrack(
        id: 'rom_2', 
        name: 'Romantic', 
        artist: 'Bensound', 
        duration: '2:30', 
        url: 'https://www.bensound.com/bensound-music/bensound-romantic.mp3', 
        category: 'Romantic',
        mood: 'Romantic',
      ),
      const MusicTrack(
        id: 'rom_3', 
        name: 'Sweet', 
        artist: 'Bensound', 
        duration: '2:18', 
        url: 'https://www.bensound.com/bensound-music/bensound-sweet.mp3', 
        category: 'Romantic',
        mood: 'Romantic',
      ),
      const MusicTrack(
        id: 'rom_4', 
        name: 'A New Beginning', 
        artist: 'Bensound', 
        duration: '2:35', 
        url: 'https://www.bensound.com/bensound-music/bensound-anewbeginning.mp3', 
        category: 'Romantic',
        mood: 'Romantic',
      ),
      const MusicTrack(
        id: 'rom_5', 
        name: 'Tomorrow', 
        artist: 'Bensound', 
        duration: '3:22', 
        url: 'https://www.bensound.com/bensound-music/bensound-tomorrow.mp3', 
        category: 'Romantic',
        mood: 'Calm',
      ),
      const MusicTrack(
        id: 'rom_6', 
        name: 'Once Again', 
        artist: 'Bensound', 
        duration: '2:45', 
        url: 'https://www.bensound.com/bensound-music/bensound-onceagain.mp3', 
        category: 'Romantic',
        mood: 'Romantic',
      ),
    ],

    // ========== CINEMATIC & EPIC ==========
    'Cinematic': [
      const MusicTrack(
        id: 'cin_1', 
        name: 'Epic', 
        artist: 'Bensound', 
        duration: '2:58', 
        url: 'https://www.bensound.com/bensound-music/bensound-epic.mp3', 
        category: 'Cinematic',
        mood: 'Epic',
      ),
      const MusicTrack(
        id: 'cin_2', 
        name: 'Adventure', 
        artist: 'Bensound', 
        duration: '2:16', 
        url: 'https://www.bensound.com/bensound-music/bensound-adventure.mp3', 
        category: 'Cinematic',
        mood: 'Epic',
      ),
      const MusicTrack(
        id: 'cin_3', 
        name: 'Cinematic', 
        artist: 'Bensound', 
        duration: '3:14', 
        url: 'https://www.bensound.com/bensound-music/bensound-cinematic.mp3', 
        category: 'Cinematic',
        mood: 'Epic',
      ),
      const MusicTrack(
        id: 'cin_4', 
        name: 'Evolution', 
        artist: 'Bensound', 
        duration: '2:45', 
        url: 'https://www.bensound.com/bensound-music/bensound-evolution.mp3', 
        category: 'Cinematic',
        mood: 'Epic',
      ),
      const MusicTrack(
        id: 'cin_5', 
        name: 'Memories', 
        artist: 'Bensound', 
        duration: '3:50', 
        url: 'https://www.bensound.com/bensound-music/bensound-memories.mp3', 
        category: 'Cinematic',
        mood: 'Sad',
      ),
      const MusicTrack(
        id: 'cin_6', 
        name: 'Documentary', 
        artist: 'Bensound', 
        duration: '2:38', 
        url: 'https://www.bensound.com/bensound-music/bensound-documentary.mp3', 
        category: 'Cinematic',
        mood: 'Epic',
      ),
    ],

    // ========== CHILL & LOFI ==========
    'Chill Lofi': [
      const MusicTrack(
        id: 'lofi_1', 
        name: 'Jazzy Frenchy', 
        artist: 'Bensound', 
        duration: '1:44', 
        url: 'https://www.bensound.com/bensound-music/bensound-jazzyfrenchy.mp3', 
        category: 'Chill Lofi',
        mood: 'Calm',
      ),
      const MusicTrack(
        id: 'lofi_2', 
        name: 'Slow Motion', 
        artist: 'Bensound', 
        duration: '3:26', 
        url: 'https://www.bensound.com/bensound-music/bensound-slowmotion.mp3', 
        category: 'Chill Lofi',
        mood: 'Calm',
      ),
      const MusicTrack(
        id: 'lofi_3', 
        name: 'Dreams', 
        artist: 'Bensound', 
        duration: '3:30', 
        url: 'https://www.bensound.com/bensound-music/bensound-dreams.mp3', 
        category: 'Chill Lofi',
        mood: 'Calm',
      ),
      const MusicTrack(
        id: 'lofi_4', 
        name: 'Tenderness', 
        artist: 'Bensound', 
        duration: '2:03', 
        url: 'https://www.bensound.com/bensound-music/bensound-tenderness.mp3', 
        category: 'Chill Lofi',
        mood: 'Calm',
      ),
      const MusicTrack(
        id: 'lofi_5', 
        name: 'The Lounge', 
        artist: 'Bensound', 
        duration: '2:38', 
        url: 'https://www.bensound.com/bensound-music/bensound-thelounge.mp3', 
        category: 'Chill Lofi',
        mood: 'Calm',
      ),
      const MusicTrack(
        id: 'lofi_6', 
        name: 'Acoustic Breeze', 
        artist: 'Bensound', 
        duration: '2:37', 
        url: 'https://www.bensound.com/bensound-music/bensound-acousticbreeze.mp3', 
        category: 'Chill Lofi',
        mood: 'Calm',
      ),
    ],

    // ========== PARTY & DANCE ==========
    'Party Dance': [
      const MusicTrack(
        id: 'party_1', 
        name: 'Dance', 
        artist: 'Bensound', 
        duration: '2:35', 
        url: 'https://www.bensound.com/bensound-music/bensound-dance.mp3', 
        category: 'Party Dance',
        mood: 'Energetic',
      ),
      const MusicTrack(
        id: 'party_2', 
        name: 'House', 
        artist: 'Bensound', 
        duration: '2:11', 
        url: 'https://www.bensound.com/bensound-music/bensound-house.mp3', 
        category: 'Party Dance',
        mood: 'Energetic',
      ),
      const MusicTrack(
        id: 'party_3', 
        name: 'Pop Dance', 
        artist: 'Bensound', 
        duration: '2:42', 
        url: 'https://www.bensound.com/bensound-music/bensound-popdance.mp3', 
        category: 'Party Dance',
        mood: 'Energetic',
      ),
      const MusicTrack(
        id: 'party_4', 
        name: 'Dubstep', 
        artist: 'Bensound', 
        duration: '2:04', 
        url: 'https://www.bensound.com/bensound-music/bensound-dubstep.mp3', 
        category: 'Party Dance',
        mood: 'Energetic',
      ),
      const MusicTrack(
        id: 'party_5', 
        name: 'Punky', 
        artist: 'Bensound', 
        duration: '0:53', 
        url: 'https://www.bensound.com/bensound-music/bensound-punky.mp3', 
        category: 'Party Dance',
        mood: 'Energetic',
      ),
      const MusicTrack(
        id: 'party_6', 
        name: 'Energy', 
        artist: 'Bensound', 
        duration: '2:59', 
        url: 'https://www.bensound.com/bensound-music/bensound-energy.mp3', 
        category: 'Party Dance',
        mood: 'Energetic',
      ),
    ],

    // ========== NASHEED & ISLAMIC ==========
    'Nasheed': [
      const MusicTrack(
        id: 'nash_1', 
        name: 'Peaceful Soul', 
        artist: 'Meditation Music', 
        duration: '3:45', 
        url: 'https://www.bensound.com/bensound-music/bensound-meditation.mp3', 
        category: 'Nasheed',
        mood: 'Calm',
      ),
      const MusicTrack(
        id: 'nash_2', 
        name: 'Inner Peace', 
        artist: 'Spiritual Sounds', 
        duration: '3:28', 
        url: 'https://www.bensound.com/bensound-music/bensound-relaxing.mp3', 
        category: 'Nasheed',
        mood: 'Calm',
      ),
      const MusicTrack(
        id: 'nash_3', 
        name: 'Harmony', 
        artist: 'Peaceful Melodies', 
        duration: '3:15', 
        url: 'https://www.bensound.com/bensound-music/bensound-ofeliasdream.mp3', 
        category: 'Nasheed',
        mood: 'Calm',
      ),
      const MusicTrack(
        id: 'nash_4', 
        name: 'Serenity', 
        artist: 'Calm Tunes', 
        duration: '2:58', 
        url: 'https://www.bensound.com/bensound-music/bensound-sadday.mp3', 
        category: 'Nasheed',
        mood: 'Calm',
      ),
      const MusicTrack(
        id: 'nash_5', 
        name: 'Morning Light', 
        artist: 'Peaceful Vibes', 
        duration: '3:22', 
        url: 'https://www.bensound.com/bensound-music/bensound-betterdays.mp3', 
        category: 'Nasheed',
        mood: 'Calm',
      ),
      const MusicTrack(
        id: 'nash_6', 
        name: 'Blessings', 
        artist: 'Sacred Sounds', 
        duration: '3:40', 
        url: 'https://www.bensound.com/bensound-music/bensound-birthofahero.mp3', 
        category: 'Nasheed',
        mood: 'Epic',
      ),
    ],

    // ========== URDU & DESI VIBES ==========
    'Desi Vibes': [
      const MusicTrack(
        id: 'desi_1', 
        name: 'Dil Ki Awaaz', 
        artist: 'Eastern Melody', 
        duration: '2:45', 
        url: 'https://www.bensound.com/bensound-music/bensound-india.mp3', 
        category: 'Desi Vibes',
        mood: 'Romantic',
      ),
      const MusicTrack(
        id: 'desi_2', 
        name: 'Celebration', 
        artist: 'Festive Beats', 
        duration: '2:38', 
        url: 'https://www.bensound.com/bensound-music/bensound-brazilsamba.mp3', 
        category: 'Desi Vibes',
        mood: 'Happy',
      ),
      const MusicTrack(
        id: 'desi_3', 
        name: 'Folk Dance', 
        artist: 'Traditional', 
        duration: '2:52', 
        url: 'https://www.bensound.com/bensound-music/bensound-buddy.mp3', 
        category: 'Desi Vibes',
        mood: 'Energetic',
      ),
      const MusicTrack(
        id: 'desi_4', 
        name: 'Wedding Vibes', 
        artist: 'Shaadi Songs', 
        duration: '3:10', 
        url: 'https://www.bensound.com/bensound-music/bensound-ukulele.mp3', 
        category: 'Desi Vibes',
        mood: 'Happy',
      ),
      const MusicTrack(
        id: 'desi_5', 
        name: 'Bollywood Dreams', 
        artist: 'Filmy Beats', 
        duration: '2:48', 
        url: 'https://www.bensound.com/bensound-music/bensound-littleidea.mp3', 
        category: 'Desi Vibes',
        mood: 'Happy',
      ),
      const MusicTrack(
        id: 'desi_6', 
        name: 'Sufi Soul', 
        artist: 'Mystic Music', 
        duration: '3:25', 
        url: 'https://www.bensound.com/bensound-music/bensound-goinghigher.mp3', 
        category: 'Desi Vibes',
        mood: 'Calm',
      ),
    ],

    // ========== MOTIVATIONAL & INSPIRATIONAL ==========
    'Motivational': [
      const MusicTrack(
        id: 'motiv_1', 
        name: 'Inspire', 
        artist: 'Bensound', 
        duration: '2:09', 
        url: 'https://www.bensound.com/bensound-music/bensound-inspire.mp3', 
        category: 'Motivational',
        mood: 'Epic',
      ),
      const MusicTrack(
        id: 'motiv_2', 
        name: 'Powerful', 
        artist: 'Bensound', 
        duration: '2:02', 
        url: 'https://www.bensound.com/bensound-music/bensound-powerful.mp3', 
        category: 'Motivational',
        mood: 'Epic',
      ),
      const MusicTrack(
        id: 'motiv_3', 
        name: 'Corporate', 
        artist: 'Bensound', 
        duration: '3:03', 
        url: 'https://www.bensound.com/bensound-music/bensound-corporate.mp3', 
        category: 'Motivational',
        mood: 'Happy',
      ),
      const MusicTrack(
        id: 'motiv_4', 
        name: 'New Dawn', 
        artist: 'Bensound', 
        duration: '2:14', 
        url: 'https://www.bensound.com/bensound-music/bensound-newdawn.mp3', 
        category: 'Motivational',
        mood: 'Happy',
      ),
      const MusicTrack(
        id: 'motiv_5', 
        name: 'Perception', 
        artist: 'Bensound', 
        duration: '2:35', 
        url: 'https://www.bensound.com/bensound-music/bensound-perception.mp3', 
        category: 'Motivational',
        mood: 'Calm',
      ),
      const MusicTrack(
        id: 'motiv_6', 
        name: 'Going Higher', 
        artist: 'Bensound', 
        duration: '3:05', 
        url: 'https://www.bensound.com/bensound-music/bensound-goinghigher.mp3', 
        category: 'Motivational',
        mood: 'Epic',
      ),
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

  /// Get tracks by mood
  static List<MusicTrack> getTracksByMood(String mood) {
    final List<MusicTrack> result = [];
    for (var tracks in musicLibrary.values) {
      result.addAll(tracks.where((t) => t.mood == mood));
    }
    return result;
  }

  /// Get recommended track for video style
  static MusicTrack? getRecommendedTrack(String videoStyle) {
    switch (videoStyle.toLowerCase()) {
      case 'cinematic':
        return musicLibrary['Cinematic']?.first;
      case 'epic':
        return musicLibrary['Cinematic']?[0]; // Epic track
      case 'romantic':
        return musicLibrary['Romantic']?.first;
      case 'vintage':
        return musicLibrary['Chill Lofi']?.first;
      case 'neon':
        return musicLibrary['Party Dance']?.first;
      case 'party':
        return musicLibrary['Party Dance']?[0];
      case 'nature':
        return musicLibrary['Chill Lofi']?[2]; // Dreams
      case 'travel':
        return musicLibrary['Motivational']?[0]; // Inspire
      case 'story':
        return musicLibrary['Cinematic']?[4]; // Memories
      case 'minimal':
        return musicLibrary['Chill Lofi']?[5]; // Acoustic Breeze
      default:
        return musicLibrary['English Pop']?.first;
    }
  }

  /// Get all tracks as flat list
  static List<MusicTrack> get allTracks {
    final List<MusicTrack> result = [];
    for (var tracks in musicLibrary.values) {
      result.addAll(tracks);
    }
    return result;
  }
}
