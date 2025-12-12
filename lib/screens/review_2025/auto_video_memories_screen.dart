import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:photo_manager/photo_manager.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import '../../widgets/beautiful_back_button.dart';

class AutoVideoMemoriesScreen extends StatefulWidget {
  const AutoVideoMemoriesScreen({super.key});

  @override
  State<AutoVideoMemoriesScreen> createState() => _AutoVideoMemoriesScreenState();
}

class _AutoVideoMemoriesScreenState extends State<AutoVideoMemoriesScreen> with TickerProviderStateMixin {
  bool _isLoading = true;
  bool _isPlaying = false;
  bool _isSaving = false;
  int _currentPhotoIndex = 0;
  int _currentMonthIndex = 0;
  
  Map<String, List<AssetEntity>> _photosByMonth = {};
  List<String> _months = [];
  List<AssetEntity> _currentMonthPhotos = [];
  Uint8List? _currentImage;
  
  Timer? _slideTimer;
  late AnimationController _fadeController;
  late AnimationController _zoomController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _zoomAnimation;
  
  // Audio player for background music
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isMusicPlaying = false;
  int _selectedSongIndex = 0;
  String _selectedMusicCategory = 'All';
  
  // Video Style
  int _selectedStyleIndex = 0;
  
  // Video Animation/Transition
  int _selectedAnimationIndex = 0;
  
  // Animation Options - xfade transitions that work on mobile
  final List<Map<String, dynamic>> _videoAnimations = [
    {'name': 'None', 'icon': '⏹️', 'transition': 'fade', 'description': 'Simple fade'},
    {'name': 'Fade', 'icon': '🌫️', 'transition': 'fade', 'description': 'Smooth fade'},
    {'name': 'Wipe Left', 'icon': '⬅️', 'transition': 'wipeleft', 'description': 'Wipe left'},
    {'name': 'Wipe Right', 'icon': '➡️', 'transition': 'wiperight', 'description': 'Wipe right'},
    {'name': 'Wipe Up', 'icon': '⬆️', 'transition': 'wipeup', 'description': 'Wipe up'},
    {'name': 'Wipe Down', 'icon': '⬇️', 'transition': 'wipedown', 'description': 'Wipe down'},
    {'name': 'Slide Left', 'icon': '📱', 'transition': 'slideleft', 'description': 'Slide left'},
    {'name': 'Slide Right', 'icon': '📲', 'transition': 'slideright', 'description': 'Slide right'},
    {'name': 'Circle Open', 'icon': '⭕', 'transition': 'circleopen', 'description': 'Circle open'},
    {'name': 'Dissolve', 'icon': '💫', 'transition': 'dissolve', 'description': 'Dissolve effect'},
  ];
  
  // Video Styles - simple EQ filters that work on mobile FFmpeg
  final List<Map<String, dynamic>> _videoStyles = [
    {'name': 'Classic', 'icon': '📷', 'filter': '', 'description': 'Original photos'},
    {'name': 'Cinematic', 'icon': '🎬', 'filter': 'eq=contrast=1.2:brightness=0.06:saturation=1.3', 'description': 'Movie look'},
    {'name': 'Vintage', 'icon': '📜', 'filter': 'eq=brightness=0.06:saturation=0.7,hue=h=15', 'description': 'Retro style'},
    {'name': 'Warm', 'icon': '🌅', 'filter': 'eq=brightness=0.05:saturation=1.2,hue=h=10', 'description': 'Warm tones'},
    {'name': 'Cool', 'icon': '❄️', 'filter': 'eq=brightness=0.05:saturation=1.1,hue=h=-15', 'description': 'Cool tones'},
    {'name': 'B&W', 'icon': '🖤', 'filter': 'eq=saturation=0', 'description': 'Black & White'},
    {'name': 'Vibrant', 'icon': '🌈', 'filter': 'eq=saturation=1.6:contrast=1.2', 'description': 'Colorful'},
    {'name': 'Bright', 'icon': '☀️', 'filter': 'eq=brightness=0.15:contrast=1.1', 'description': 'Bright look'},
  ];
  
  // Music Categories
  final List<String> _musicCategories = ['All', 'English', 'Urdu', 'Pashto', 'Naat/Nasheed', 'Instrumental'];
  
  // Categorized Music Library - using actual available songs
  final List<Map<String, dynamic>> _songs = [
    {'name': 'No Music', 'icon': '🔇', 'asset': null, 'category': 'All'},
    // Available Songs
    {'name': 'Memories', 'icon': '🎵', 'asset': 'assets/audio/song1.mp3', 'category': 'English'},
    {'name': 'Happy Moments', 'icon': '😊', 'asset': 'assets/audio/song2.mp3', 'category': 'English'},
    {'name': 'Emotional', 'icon': '💕', 'asset': 'assets/audio/song3.mp3', 'category': 'Instrumental'},
    {'name': 'Epic Journey', 'icon': '🎬', 'asset': 'assets/audio/song4.mp3', 'category': 'Instrumental'},
    {'name': 'Peaceful', 'icon': '🌸', 'asset': 'assets/audio/song5.mp3', 'category': 'Instrumental'},
  ];
  
  // Get filtered songs by category
  List<Map<String, dynamic>> get _filteredSongs {
    if (_selectedMusicCategory == 'All') return _songs;
    return _songs.where((s) => s['category'] == 'All' || s['category'] == _selectedMusicCategory).toList();
  }

  final List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  final Map<int, Map<String, dynamic>> _monthThemes = {
    1: {'emoji': '❄️', 'gradient': [Color(0xFF667eea), Color(0xFF764ba2)]},
    2: {'emoji': '💕', 'gradient': [Color(0xFFf093fb), Color(0xFFf5576c)]},
    3: {'emoji': '🌸', 'gradient': [Color(0xFF4facfe), Color(0xFF00f2fe)]},
    4: {'emoji': '🌧️', 'gradient': [Color(0xFF43e97b), Color(0xFF38f9d7)]},
    5: {'emoji': '🌻', 'gradient': [Color(0xFFfa709a), Color(0xFFfee140)]},
    6: {'emoji': '☀️', 'gradient': [Color(0xFFf7971e), Color(0xFFffd200)]},
    7: {'emoji': '🏖️', 'gradient': [Color(0xFF11998e), Color(0xFF38ef7d)]},
    8: {'emoji': '🌴', 'gradient': [Color(0xFF00c6ff), Color(0xFF0072ff)]},
    9: {'emoji': '🍂', 'gradient': [Color(0xFFf2994a), Color(0xFFf2c94c)]},
    10: {'emoji': '🎃', 'gradient': [Color(0xFFeb3349), Color(0xFFf45c43)]},
    11: {'emoji': '🍁', 'gradient': [Color(0xFFDA22FF), Color(0xFF9733EE)]},
    12: {'emoji': '🎄', 'gradient': [Color(0xFF1a2a6c), Color(0xFFb21f1f)]},
  };

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _zoomController = AnimationController(duration: const Duration(seconds: 5), vsync: this);
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _zoomAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _zoomController, curve: Curves.easeInOut),
    );
    
    _loadPhotos();
  }

  @override
  void dispose() {
    _slideTimer?.cancel();
    _fadeController.dispose();
    _zoomController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
  
  // Play selected music
  Future<void> _playMusic() async {
    if (_selectedSongIndex == 0 || _songs[_selectedSongIndex]['asset'] == null) {
      await _audioPlayer.stop();
      setState(() => _isMusicPlaying = false);
      return;
    }
    
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource(_songs[_selectedSongIndex]['asset'].replaceFirst('assets/', '')));
      setState(() => _isMusicPlaying = true);
    } catch (e) {
      debugPrint('Error playing music: $e');
    }
  }
  
  // Stop music
  Future<void> _stopMusic() async {
    await _audioPlayer.stop();
    setState(() => _isMusicPlaying = false);
  }
  
  // Show animation selector dialog
  void _showAnimationSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF1a1a2e), Color(0xFF16213e)]),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('✨ Animation Effects', 
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Choose transition animation for video', 
              style: TextStyle(color: Colors.white54, fontSize: 14)),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.5,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _videoAnimations.length,
                itemBuilder: (context, index) {
                  final anim = _videoAnimations[index];
                  final isSelected = _selectedAnimationIndex == index;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedAnimationIndex = index);
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF00E5FF).withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF00E5FF) : Colors.white24,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(anim['icon'], style: const TextStyle(fontSize: 32)),
                          const SizedBox(height: 8),
                          Text(anim['name'], style: TextStyle(
                            color: isSelected ? const Color(0xFF00E5FF) : Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          )),
                          Text(anim['description'], style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                          )),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Show video style selector dialog
  void _showStyleSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF1a1a2e), Color(0xFF16213e)]),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🎬 Video Style', 
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Choose a style for your video', 
              style: TextStyle(color: Colors.white54, fontSize: 14)),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.5,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _videoStyles.length,
                itemBuilder: (context, index) {
                  final style = _videoStyles[index];
                  final isSelected = _selectedStyleIndex == index;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedStyleIndex = index);
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFFFD700).withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? const Color(0xFFFFD700) : Colors.white24,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(style['icon'], style: const TextStyle(fontSize: 32)),
                          const SizedBox(height: 8),
                          Text(style['name'], style: TextStyle(
                            color: isSelected ? const Color(0xFFFFD700) : Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          )),
                          Text(style['description'], style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                          )),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Show song selection dialog with categories
  void _showSongSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF1a1a2e), Color(0xFF16213e)]),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🎵 Background Music', 
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              // Category tabs
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _musicCategories.length,
                  itemBuilder: (context, index) {
                    final category = _musicCategories[index];
                    final isSelected = _selectedMusicCategory == category;
                    return GestureDetector(
                      onTap: () {
                        setModalState(() => _selectedMusicCategory = category);
                        setState(() {});
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFFFD700) : Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(category, style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        )),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Songs list
              Expanded(
                child: ListView.builder(
                  itemCount: _filteredSongs.length,
                  itemBuilder: (context, index) {
                    final song = _filteredSongs[index];
                    final globalIndex = _songs.indexOf(song);
                    final isSelected = _selectedSongIndex == globalIndex;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedSongIndex = globalIndex);
                        if (_isPlaying) _playMusic();
                        Navigator.pop(context);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFFFD700).withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFFFD700) : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(song['icon'], style: const TextStyle(fontSize: 28)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(song['name'], style: TextStyle(
                                    color: isSelected ? const Color(0xFFFFD700) : Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  )),
                                  if (song['category'] != 'All')
                                    Text(song['category'], style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    )),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle, color: Color(0xFFFFD700)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Generate and save current month's FULL HD video to gallery
  Future<void> _saveCurrentMonthVideo() async {
    if (_currentMonthPhotos.isEmpty || !mounted) return;
    
    if (mounted) setState(() => _isSaving = true);
    final wasPlaying = _isPlaying;
    if (_isPlaying) _togglePlayPause();
    
    // Show progress dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _VideoGenerationDialog(key: _dialogKey),
      );
    }
    
    try {
      final tempDir = await getTemporaryDirectory();
      final framesDir = Directory('${tempDir.path}/video_frames');
      
      if (await framesDir.exists()) {
        await framesDir.delete(recursive: true);
      }
      await framesDir.create(recursive: true);
      
      final monthName = _months[_currentMonthIndex];
      final photos = _currentMonthPhotos;
      
      _updateDialogProgress('Preparing $monthName...', 0.05);
      
      // Process photos sequentially for Full HD quality
      for (int i = 0; i < photos.length; i++) {
        if (!mounted) return;
        await _processFrameFullHD(photos[i], framesDir.path, i);
        _updateDialogProgress(
          'Processing ${i + 1}/${photos.length}',
          0.05 + (0.45 * (i + 1) / photos.length),
        );
      }
      
      if (!mounted) return;
      _updateDialogProgress('Creating video...', 0.6);
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = '${tempDir.path}/${monthName}_2025_$timestamp.mp4';
      
      // Copy music to temp if selected
      String? musicPath;
      if (_selectedSongIndex > 0 && _songs[_selectedSongIndex]['asset'] != null) {
        _updateDialogProgress('Adding music...', 0.65);
        musicPath = await _copyAudioToTemp(_songs[_selectedSongIndex]['asset']);
      }
      
      // Build FFmpeg command with style, animation, and music
      final ffmpegCommand = _buildFFmpegCommandWithMusic(framesDir.path, photos.length, outputPath, musicPath);
      
      _updateDialogProgress('Encoding video...', 0.75);
      final session = await FFmpegKit.execute(ffmpegCommand);
      final returnCode = await session.getReturnCode();
      
      if (ReturnCode.isSuccess(returnCode)) {
        _updateDialogProgress('Saving to gallery...', 0.95);
        await Gal.putVideo(outputPath, album: '2025 Memories');
        
        await framesDir.delete(recursive: true);
        await File(outputPath).delete();
        
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('$monthName Full HD video saved! 🎬'),
              ]),
              backgroundColor: const Color(0xFF4CAF50),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } else {
        throw Exception('Video creation failed');
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
        if (wasPlaying) _togglePlayPause();
      }
    }
  }
  
  // Process single frame in HD quality - simple and reliable
  Future<void> _processFrameFullHD(AssetEntity asset, String dirPath, int index) async {
    final data = await asset.thumbnailDataWithSize(
      const ThumbnailSize(1920, 1080),
      quality: 90,
    );
    if (data != null) {
      final framePath = '$dirPath/frame_${index.toString().padLeft(5, '0')}.jpg';
      await File(framePath).writeAsBytes(data);
    }
  }
  
  // Copy audio asset to temp file for FFmpeg
  Future<String?> _copyAudioToTemp(String assetPath) async {
    try {
      final byteData = await rootBundle.load(assetPath);
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_music.mp3');
      await tempFile.writeAsBytes(byteData.buffer.asUint8List());
      return tempFile.path;
    } catch (e) {
      debugPrint('Error copying audio: $e');
      return null;
    }
  }
  
  // Build FFmpeg command with xfade transitions for professional video
  String _buildFFmpegCommand(String framesDir, int photoCount, String outputPath) {
    final transition = _videoAnimations[_selectedAnimationIndex]['transition'] as String;
    final styleFilter = _videoStyles[_selectedStyleIndex]['filter'] as String;
    final photoDuration = 3; // seconds per photo
    final transitionDuration = 1; // 1 second transition
    
    // For simple approach without complex xfade (more reliable on mobile)
    // Use fade in/out on each frame with style filter
    String baseFilter = 'scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2:black';
    
    // Add style filter if selected
    if (styleFilter.isNotEmpty) {
      baseFilter += ',$styleFilter';
    }
    
    // Add fade effect based on selected animation
    if (_selectedAnimationIndex > 0) {
      baseFilter += ',fade=t=in:st=0:d=0.5,fade=t=out:st=2.5:d=0.5';
    }
    
    // Simple reliable command
    return '-framerate 1/$photoDuration -i "$framesDir/frame_%05d.jpg" '
        '-c:v libx264 -r 30 -pix_fmt yuv420p '
        '-vf "$baseFilter" '
        '-preset fast -crf 20 -movflags +faststart "$outputPath"';
  }
  
  // Build FFmpeg command with music
  String _buildFFmpegCommandWithMusic(String framesDir, int photoCount, String outputPath, String? musicPath) {
    final styleFilter = _videoStyles[_selectedStyleIndex]['filter'] as String;
    final photoDuration = 3;
    
    String baseFilter = 'scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2:black';
    
    if (styleFilter.isNotEmpty) {
      baseFilter += ',$styleFilter';
    }
    
    if (_selectedAnimationIndex > 0) {
      baseFilter += ',fade=t=in:st=0:d=0.5,fade=t=out:st=2.5:d=0.5';
    }
    
    if (musicPath != null) {
      // With music
      return '-framerate 1/$photoDuration -i "$framesDir/frame_%05d.jpg" '
          '-i "$musicPath" '
          '-c:v libx264 -c:a aac -r 30 -pix_fmt yuv420p '
          '-vf "$baseFilter" '
          '-shortest -preset fast -crf 20 -movflags +faststart "$outputPath"';
    } else {
      // Without music
      return '-framerate 1/$photoDuration -i "$framesDir/frame_%05d.jpg" '
          '-c:v libx264 -r 30 -pix_fmt yuv420p '
          '-vf "$baseFilter" '
          '-preset fast -crf 20 -movflags +faststart "$outputPath"';
    }
  }
  
  // Generate and save ALL months as separate Full HD videos
  Future<void> _saveAllMonthsVideos() async {
    if (!mounted) return;
    if (mounted) setState(() => _isSaving = true);
    final wasPlaying = _isPlaying;
    if (_isPlaying) _togglePlayPause();
    
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _VideoGenerationDialog(key: _dialogKey),
      );
    }
    
    try {
      final tempDir = await getTemporaryDirectory();
      int savedVideos = 0;
      
      for (int m = 0; m < _months.length; m++) {
        if (!mounted) return;
        final monthName = _months[m];
        final photos = _photosByMonth[monthName] ?? [];
        
        if (photos.isEmpty) continue;
        
        _updateDialogProgress('Creating $monthName (${m + 1}/${_months.length})...', (m + 0.5) / _months.length);
        
        final framesDir = Directory('${tempDir.path}/video_frames');
        if (await framesDir.exists()) {
          await framesDir.delete(recursive: true);
        }
        await framesDir.create(recursive: true);
        
        // Process frames sequentially for Full HD quality
        for (int i = 0; i < photos.length; i++) {
          if (!mounted) return;
          await _processFrameFullHD(photos[i], framesDir.path, i);
        }
        
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final outputPath = '${tempDir.path}/${monthName}_2025_$timestamp.mp4';
        
        // Copy music to temp if selected (only once for first month)
        String? musicPath;
        if (m == 0 && _selectedSongIndex > 0 && _songs[_selectedSongIndex]['asset'] != null) {
          musicPath = await _copyAudioToTemp(_songs[_selectedSongIndex]['asset']);
        }
        
        // Build FFmpeg command with style, animation, and music
        final ffmpegCommand = _buildFFmpegCommandWithMusic(framesDir.path, photos.length, outputPath, musicPath);
        
        final session = await FFmpegKit.execute(ffmpegCommand);
        final returnCode = await session.getReturnCode();
        
        if (ReturnCode.isSuccess(returnCode)) {
          await Gal.putVideo(outputPath, album: '2025 Memories');
          await File(outputPath).delete();
          savedVideos++;
        }
        
        await framesDir.delete(recursive: true);
      }
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text('$savedVideos monthly videos saved! 🎬'),
            ]),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
        if (wasPlaying) _togglePlayPause();
      }
    }
  }
  
  final GlobalKey<_VideoGenerationDialogState> _dialogKey = GlobalKey();
  
  void _updateDialogProgress(String message, double progress) {
    _dialogKey.currentState?.updateProgress(message, progress);
  }

  Future<void> _loadPhotos() async {
    try {
      final permission = await PhotoManager.requestPermissionExtend();
      if (!permission.isAuth) {
        setState(() => _isLoading = false);
        return;
      }

      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        filterOption: FilterOptionGroup(
          createTimeCond: DateTimeCond(
            min: DateTime(2025, 1, 1),
            max: DateTime(2025, 12, 31, 23, 59, 59),
          ),
        ),
      );

      if (albums.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final count = await albums.first.assetCountAsync;
      final allAssets = await albums.first.getAssetListRange(start: 0, end: count);

      Map<String, List<AssetEntity>> byMonth = {};
      Set<String> seenIds = {};

      for (final asset in allAssets) {
        if (seenIds.contains(asset.id)) continue;
        seenIds.add(asset.id);

        final date = asset.createDateTime;
        if (date.year == 2025) {
          final key = '${_monthNames[date.month - 1]} 2025';
          byMonth.putIfAbsent(key, () => []);
          byMonth[key]!.add(asset);
        }
      }

      // Sort each month's photos by date
      for (final month in byMonth.keys) {
        byMonth[month]!.sort((a, b) => a.createDateTime.compareTo(b.createDateTime));
      }

      // Sort months chronologically
      final sortedMonths = byMonth.keys.toList()
        ..sort((a, b) => _getMonthOrder(a).compareTo(_getMonthOrder(b)));

      setState(() {
        _photosByMonth = byMonth;
        _months = sortedMonths;
        _isLoading = false;
      });

      // Auto-start playing if photos exist
      if (_months.isNotEmpty) {
        _startAutoPlay();
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  int _getMonthOrder(String monthKey) {
    for (int i = 0; i < _monthNames.length; i++) {
      if (monthKey.startsWith(_monthNames[i])) return i;
    }
    return 0;
  }

  void _startAutoPlay() {
    if (_months.isEmpty) return;
    
    setState(() {
      _isPlaying = true;
      _currentMonthIndex = 0;
      _currentPhotoIndex = 0;
      _currentMonthPhotos = _photosByMonth[_months[0]] ?? [];
    });
    
    _loadCurrentImage();
    _startSlideshow();
  }

  void _startSlideshow() {
    _slideTimer?.cancel();
    _slideTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      _nextSlide();
    });
  }

  void _nextSlide() {
    if (_currentMonthPhotos.isEmpty) return;

    setState(() {
      _currentPhotoIndex++;
      
      // Move to next month if we've shown all photos in current month
      if (_currentPhotoIndex >= _currentMonthPhotos.length) {
        _currentPhotoIndex = 0;
        _currentMonthIndex++;
        
        // Loop back to first month if we've shown all months
        if (_currentMonthIndex >= _months.length) {
          _currentMonthIndex = 0;
        }
        
        _currentMonthPhotos = _photosByMonth[_months[_currentMonthIndex]] ?? [];
      }
    });
    
    _loadCurrentImage();
  }

  void _previousSlide() {
    if (_currentMonthPhotos.isEmpty) return;

    setState(() {
      _currentPhotoIndex--;
      
      if (_currentPhotoIndex < 0) {
        _currentMonthIndex--;
        if (_currentMonthIndex < 0) {
          _currentMonthIndex = _months.length - 1;
        }
        _currentMonthPhotos = _photosByMonth[_months[_currentMonthIndex]] ?? [];
        _currentPhotoIndex = _currentMonthPhotos.length - 1;
      }
    });
    
    _loadCurrentImage();
  }

  Future<void> _loadCurrentImage() async {
    if (_currentMonthPhotos.isEmpty || _currentPhotoIndex >= _currentMonthPhotos.length) return;
    
    _fadeController.reset();
    _zoomController.reset();
    
    final asset = _currentMonthPhotos[_currentPhotoIndex];
    final data = await asset.thumbnailDataWithSize(
      const ThumbnailSize(1080, 1920), // HD quality
      quality: 95,
    );
    
    if (mounted) {
      setState(() => _currentImage = data);
      _fadeController.forward();
      _zoomController.forward();
    }
  }

  void _togglePlayPause() {
    setState(() => _isPlaying = !_isPlaying);
    
    if (_isPlaying) {
      _startSlideshow();
      if (_selectedSongIndex > 0) _playMusic();
    } else {
      _slideTimer?.cancel();
      _stopMusic();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_months.isEmpty) {
      return _buildNoPhotosScreen();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image with Ken Burns Effect
          if (_currentImage != null)
            AnimatedBuilder(
              animation: _zoomAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _zoomAnimation.value,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Image.memory(
                      _currentImage!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                );
              },
            ),
          
          // Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.7),
                ],
                stops: const [0.0, 0.2, 0.6, 1.0],
              ),
            ),
          ),
          
          // Top Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const BeautifulBackButton(),
                  const Spacer(),
                  _buildMonthBadge(),
                ],
              ),
            ),
          ),
          
          // Bottom Controls & Info
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Column(
                children: [
                  // Month Title
                  _buildMonthTitle(),
                  const SizedBox(height: 16),
                  
                  // Progress Indicator
                  _buildProgressIndicator(),
                  const SizedBox(height: 16),
                  
                  // Main Controls Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Animation Button
                        _buildControlButton(
                          icon: Icons.animation,
                          onTap: _showAnimationSelector,
                          isActive: _selectedAnimationIndex > 0,
                        ),
                        // Style Button
                        _buildControlButton(
                          icon: Icons.auto_awesome,
                          onTap: _showStyleSelector,
                          isActive: _selectedStyleIndex > 0,
                        ),
                        // Music Button
                        _buildControlButton(
                          icon: _selectedSongIndex > 0 ? Icons.music_note : Icons.music_off,
                          onTap: _showSongSelector,
                          isActive: _selectedSongIndex > 0,
                        ),
                        // Play/Pause - Big Button
                        GestureDetector(
                          onTap: _togglePlayPause,
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _isPlaying 
                                    ? [const Color(0xFFFFD700), const Color(0xFFFFA500)]
                                    : [const Color(0xFF4CAF50), const Color(0xFF8BC34A)],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (_isPlaying ? const Color(0xFFFFD700) : const Color(0xFF4CAF50)).withValues(alpha: 0.5),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),
                        // Next
                        _buildControlButton(
                          icon: Icons.skip_next,
                          onTap: _nextSlide,
                        ),
                        // Save Video Button (tap = current month, long press = all months)
                        _buildControlButton(
                          icon: _isSaving ? Icons.hourglass_top : Icons.videocam,
                          onTap: _isSaving ? null : _saveCurrentMonthVideo,
                          onLongPress: _isSaving ? null : _saveAllMonthsVideos,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          
          // Tap anywhere to toggle (except controls area)
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            bottom: 200,
            child: GestureDetector(
              onTap: _togglePlayPause,
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity! < 0) {
                  _nextSlide();
                } else if (details.primaryVelocity! > 0) {
                  _previousSlide();
                }
              },
              child: Container(color: Colors.transparent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 80, height: 80,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Color(0xFFFFD700)),
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 32),
              const Text('🎬 Creating Your Memories Video...', 
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text('Auto-generating from your 2025 photos', 
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoPhotosScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: const [BeautifulBackButton()]),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_library_outlined, size: 80, color: Colors.white.withValues(alpha: 0.3)),
                      const SizedBox(height: 24),
                      const Text('No 2025 Photos Found', style: TextStyle(color: Colors.white70, fontSize: 18)),
                      const SizedBox(height: 8),
                      Text('Add photos to your gallery to create memories video', 
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthBadge() {
    if (_months.isEmpty) return const SizedBox();
    
    final monthIndex = _getMonthOrder(_months[_currentMonthIndex]) + 1;
    final theme = _monthThemes[monthIndex]!;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: theme['gradient'] as List<Color>),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(theme['emoji'] as String, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text('${_currentPhotoIndex + 1}/${_currentMonthPhotos.length}', 
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMonthTitle() {
    if (_months.isEmpty) return const SizedBox();
    
    final monthIndex = _getMonthOrder(_months[_currentMonthIndex]) + 1;
    final theme = _monthThemes[monthIndex]!;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(theme['emoji'] as String, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 8),
          Text(
            _months[_currentMonthIndex],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(color: Colors.black54, blurRadius: 10)],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_currentMonthPhotos.length} memories',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Month progress dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_months.length, (index) {
              final isActive = index == _currentMonthIndex;
              return Container(
                width: isActive ? 24 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFFFFD700) : Colors.white38,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          // Photo progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _currentMonthPhotos.isEmpty ? 0 : (_currentPhotoIndex + 1) / _currentMonthPhotos.length,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(Color(0xFFFFD700)),
              minHeight: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Previous Month
          _buildControlButton(
            icon: Icons.skip_previous,
            onTap: () {
              setState(() {
                _currentMonthIndex = (_currentMonthIndex - 1) % _months.length;
                if (_currentMonthIndex < 0) _currentMonthIndex = _months.length - 1;
                _currentMonthPhotos = _photosByMonth[_months[_currentMonthIndex]] ?? [];
                _currentPhotoIndex = 0;
              });
              _loadCurrentImage();
            },
          ),
          // Previous Photo
          _buildControlButton(
            icon: Icons.fast_rewind,
            onTap: _previousSlide,
          ),
          // Play/Pause
          _buildControlButton(
            icon: _isPlaying ? Icons.pause : Icons.play_arrow,
            size: 56,
            onTap: _togglePlayPause,
            isPrimary: true,
          ),
          // Next Photo
          _buildControlButton(
            icon: Icons.fast_forward,
            onTap: _nextSlide,
          ),
          // Next Month
          _buildControlButton(
            icon: Icons.skip_next,
            onTap: () {
              setState(() {
                _currentMonthIndex = (_currentMonthIndex + 1) % _months.length;
                _currentMonthPhotos = _photosByMonth[_months[_currentMonthIndex]] ?? [];
                _currentPhotoIndex = 0;
              });
              _loadCurrentImage();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    double size = 48,
    bool isPrimary = false,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isActive 
              ? const Color(0xFFFFD700).withValues(alpha: 0.3) 
              : (isPrimary ? const Color(0xFFFFD700) : Colors.white24),
          shape: BoxShape.circle,
          border: isActive ? Border.all(color: const Color(0xFFFFD700), width: 2) : null,
        ),
        child: Icon(
          icon,
          color: isActive ? const Color(0xFFFFD700) : (isPrimary ? Colors.black : Colors.white),
          size: size * 0.5,
        ),
      ),
    );
  }
}

// Video Generation Progress Dialog
class _VideoGenerationDialog extends StatefulWidget {
  const _VideoGenerationDialog({super.key});

  @override
  State<_VideoGenerationDialog> createState() => _VideoGenerationDialogState();
}

class _VideoGenerationDialogState extends State<_VideoGenerationDialog> {
  String _message = 'Starting...';
  double _progress = 0.0;

  void updateProgress(String message, double progress) {
    if (mounted) {
      setState(() {
        _message = message;
        _progress = progress;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '🎬 Creating HD Video',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            // Animated progress indicator
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: _progress,
                    strokeWidth: 8,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFFFD700)),
                  ),
                ),
                Text(
                  '${(_progress * 100).toInt()}%',
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              _message,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              '1920x1080 HD • 4 sec/photo',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
