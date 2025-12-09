import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_theme.dart';
import '../../services/media_service.dart';
import '../../services/music_service.dart';
import '../../services/video_generator_service.dart';
import '../../providers/app_provider.dart';
import '../../widgets/beautiful_back_button.dart';
import 'video_preview_screen.dart';

class VideoMemoriesScreen extends StatefulWidget {
  const VideoMemoriesScreen({super.key});

  @override
  State<VideoMemoriesScreen> createState() => _VideoMemoriesScreenState();
}

class _VideoMemoriesScreenState extends State<VideoMemoriesScreen> with TickerProviderStateMixin {
  String _selectedStyle = 'Cinematic';
  String _selectedDuration = '30s';
  MusicTrack? _selectedMusicTrack;
  String _selectedMusicCategory = 'English';
  bool _isGenerating = false;
  bool _isGenerated = false;
  int _generationProgress = 0;
  String _generationStatus = '';
  GeneratedVideo? _generatedVideo;
  
  // Music playback state
  bool _isPlayingPreview = false;
  String? _currentlyPlayingTrackId;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  double _volume = 1.0;
  
  // Subscriptions
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<bool>? _playingSub;
  
  // Animation Controllers
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late AnimationController _waveController;

  // Video Styles with descriptions
  final List<Map<String, dynamic>> _videoStyles = [
    {
      'name': 'Cinematic',
      'icon': Icons.movie_filter,
      'description': 'Film-like transitions with dramatic effects',
      'color': const Color(0xFF8E2DE2),
    },
    {
      'name': 'Slideshow',
      'icon': Icons.photo_library,
      'description': 'Classic photo slideshow with smooth fades',
      'color': const Color(0xFF00C9FF),
    },
    {
      'name': 'Dynamic',
      'icon': Icons.speed,
      'description': 'Fast-paced with energetic transitions',
      'color': const Color(0xFFFF5E62),
    },
    {
      'name': 'Highlights',
      'icon': Icons.star,
      'description': 'Best moments with spotlight effects',
      'color': const Color(0xFFFFD200),
    },
    {
      'name': 'Memories',
      'icon': Icons.favorite,
      'description': 'Nostalgic style with soft filters',
      'color': const Color(0xFFFF6B8A),
    },
    {
      'name': 'Modern',
      'icon': Icons.auto_awesome,
      'description': 'Trendy effects with stylish animations',
      'color': const Color(0xFF4ECDC4),
    },
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );
    _animController.forward();
    
    // Wave animation for audio visualization
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    
    // Initialize music service and listen to streams
    _initMusicService();
  }

  Future<void> _initMusicService() async {
    await MusicService.init();
    
    // Listen to position changes
    _positionSub = MusicService.positionStream.listen((position) {
      if (mounted) {
        setState(() => _currentPosition = position);
      }
    });
    
    // Listen to duration changes
    _durationSub = MusicService.durationStream.listen((duration) {
      if (mounted) {
        setState(() => _totalDuration = duration);
      }
    });
    
    // Listen to playing state changes
    _playingSub = MusicService.playingStream.listen((isPlaying) {
      if (mounted) {
        setState(() => _isPlayingPreview = isPlaying);
      }
    });
  }

  @override
  void dispose() {
    // Cancel subscriptions
    _positionSub?.cancel();
    _durationSub?.cancel();
    _playingSub?.cancel();
    
    // Stop music when leaving screen
    MusicService.stop();
    _animController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  int _getMediaCount() {
    final photos = MediaService.getAllPhotos().length;
    final videos = MediaService.getAllVideos().length;
    final screenshots = MediaService.getAllScreenshots().length;
    return photos + videos + screenshots;
  }

  // Toggle music preview playback
  Future<void> _toggleMusicPreview(MusicTrack track) async {
    if (_currentlyPlayingTrackId == track.id && _isPlayingPreview) {
      // Pause current track
      await MusicService.pause();
      setState(() {
        _isPlayingPreview = false;
      });
    } else if (_currentlyPlayingTrackId == track.id && !_isPlayingPreview) {
      // Resume current track
      await MusicService.resume();
      setState(() {
        _isPlayingPreview = true;
      });
    } else {
      // Play new track
      await MusicService.play(track);
      setState(() {
        _currentlyPlayingTrackId = track.id;
        _isPlayingPreview = true;
      });
    }
  }

  // Stop music preview
  Future<void> _stopMusicPreview() async {
    await MusicService.stop();
    setState(() {
      _isPlayingPreview = false;
      _currentlyPlayingTrackId = null;
      _currentPosition = Duration.zero;
      _totalDuration = Duration.zero;
    });
  }

  // Seek music by percentage
  Future<void> _seekMusic(double percent) async {
    await MusicService.seekByPercent(percent);
  }

  // Set volume
  Future<void> _setVolume(double vol) async {
    await MusicService.setVolume(vol);
    setState(() => _volume = vol);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<AppProvider>().isDarkMode;
    final mediaCount = _getMediaCount();
    
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF1A1A2E) : AppTheme.bgTop,
      body: Container(
        decoration: BoxDecoration(
          gradient: isDarkMode 
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
                )
              : AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar - Simple with just back button
              _buildAppBar(context, isDarkMode),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(AppTheme.screenPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Text(
                        'Video Memories',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : AppTheme.textWhite,
                        ),
                      ),
                      Text(
                        'Create a video from your 2025 moments',
                        style: TextStyle(
                          fontSize: 14,
                          color: (isDarkMode ? Colors.white : AppTheme.textWhite).withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Media Count Card
                      _buildMediaCountCard(mediaCount, isDarkMode),
                      const SizedBox(height: 24),
                      
                      // Preview Area
                      _buildPreviewArea(isDarkMode, mediaCount),
                      const SizedBox(height: 24),
                      
                      // Style Selection
                      _buildStyleSection(isDarkMode),
                      const SizedBox(height: 24),
                      
                      // Professional Music Selection with Player
                      _buildProfessionalMusicSection(isDarkMode),
                      const SizedBox(height: 24),
                      
                      // Duration Selection
                      _buildDurationSection(isDarkMode),
                      const SizedBox(height: 28),
                      
                      // Generate Button
                      _buildGenerateButton(mediaCount, isDarkMode),
                      const SizedBox(height: 16),
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

  Widget _buildAppBar(BuildContext context, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          BeautifulBackButton(
            isDarkMode: isDarkMode,
            onTap: () {
              // Stop music before leaving
              _stopMusicPreview();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMediaCountCard(int mediaCount, bool isDarkMode) {
    final photos = MediaService.getAllPhotos().length;
    final videos = MediaService.getAllVideos().length;
    final screenshots = MediaService.getAllScreenshots().length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: isDarkMode ? 0.1 : 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _MediaCountItem(icon: Icons.photo, count: photos, label: 'Photos', color: AppTheme.iconPink),
          _MediaCountItem(icon: Icons.videocam, count: videos, label: 'Videos', color: AppTheme.iconGreen),
          _MediaCountItem(icon: Icons.screenshot, count: screenshots, label: 'Screenshots', color: AppTheme.iconOrange),
        ],
      ),
    );
  }

  Widget _buildPreviewArea(bool isDarkMode, int mediaCount) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: isDarkMode 
              ? const LinearGradient(colors: [Color(0xFF1A1A2E), Color(0xFF302B63)])
              : AppTheme.videoMemoriesGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF24243E).withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: _isGenerating
            ? _buildGeneratingState()
            : _isGenerated
                ? _buildGeneratedState()
                : _buildInitialPreviewState(mediaCount),
      ),
    );
  }

  Widget _buildInitialPreviewState(int mediaCount) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.movie_creation,
            color: Colors.white,
            size: 35,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Your 2025 Movie',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          mediaCount == 0 
              ? 'Add photos/videos to create your video'
              : '$mediaCount media items ready to use',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildGeneratingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 60,
          height: 60,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: _generationProgress / 100,
                color: Colors.white,
                strokeWidth: 4,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
              ),
              Text(
                '$_generationProgress%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Creating Your Video...',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _generationStatus.isNotEmpty ? _generationStatus : 'Style: $_selectedStyle',
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
        if (_selectedMusicTrack != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Music: ${_selectedMusicTrack!.name}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGeneratedState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: const BoxDecoration(
            color: AppTheme.iconGreen,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check,
            color: Colors.white,
            size: 35,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Video Ready!',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        if (_generatedVideo != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${_generatedVideo!.photoCount} photos • ${_generatedVideo!.durationSeconds}s',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ActionChip(
              icon: Icons.play_circle_outline,
              label: 'Preview',
              onTap: _openVideoPreview,
            ),
            const SizedBox(width: 12),
            _ActionChip(
              icon: Icons.share,
              label: 'Share',
              onTap: () {
                if (_generatedVideo != null) {
                  _openVideoPreview();
                }
              },
            ),
            const SizedBox(width: 12),
            _ActionChip(
              icon: Icons.download,
              label: 'Save',
              onTap: () {
                if (_generatedVideo != null) {
                  _openVideoPreview();
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStyleSection(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Video Style',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : AppTheme.textWhite,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _videoStyles.length,
            itemBuilder: (context, index) {
              final style = _videoStyles[index];
              final isSelected = _selectedStyle == style['name'];
              return GestureDetector(
                onTap: () => setState(() => _selectedStyle = style['name'] as String),
                child: Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (style['color'] as Color)
                        : Colors.white.withValues(alpha: isDarkMode ? 0.1 : 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: isSelected
                        ? null
                        : Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        style['icon'] as IconData,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        style['name'] as String,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // Style description
        if (_selectedStyle.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _videoStyles.firstWhere((s) => s['name'] == _selectedStyle)['description'] as String,
              style: TextStyle(
                fontSize: 13,
                color: (isDarkMode ? Colors.white : AppTheme.textWhite).withValues(alpha: 0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  // ==========================================
  // PROFESSIONAL MUSIC SECTION
  // ==========================================
  
  Widget _buildProfessionalMusicSection(bool isDarkMode) {
    final categories = [...MusicService.categories, 'No Music'];
    final currentTracks = _selectedMusicCategory != 'No Music' 
        ? MusicService.getTracksByCategory(_selectedMusicCategory)
        : <MusicTrack>[];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.music_note, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Background Music',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : AppTheme.textWhite,
                  ),
                ),
              ],
            ),
            if (_selectedMusicTrack != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.iconGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, color: AppTheme.iconGreen, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Selected',
                      style: TextStyle(
                        color: AppTheme.iconGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Music Categories with better design
        Container(
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = _selectedMusicCategory == category;
              final Color categoryColor;
              final IconData categoryIcon;
              
              switch (category) {
                case 'English':
                  categoryColor = const Color(0xFF00C9FF);
                  categoryIcon = Icons.music_note;
                  break;
                case 'Urdu':
                  categoryColor = const Color(0xFF8C52FF);
                  categoryIcon = Icons.queue_music;
                  break;
                case 'Pashto':
                  categoryColor = const Color(0xFF4ECDC4);
                  categoryIcon = Icons.library_music;
                  break;
                case 'Nasheed':
                  categoryColor = const Color(0xFF26DE81);
                  categoryIcon = Icons.mosque;
                  break;
                case 'Instrumental':
                  categoryColor = const Color(0xFFFFB347);
                  categoryIcon = Icons.piano;
                  break;
                case 'No Music':
                  categoryColor = const Color(0xFF888888);
                  categoryIcon = Icons.music_off;
                  break;
                default:
                  categoryColor = AppTheme.iconPurple;
                  categoryIcon = Icons.music_note;
              }
              
              return GestureDetector(
                onTap: () {
                  if (_isPlayingPreview) {
                    _stopMusicPreview();
                  }
                  setState(() {
                    _selectedMusicCategory = category;
                    if (category == 'No Music') {
                      _selectedMusicTrack = null;
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [categoryColor, categoryColor.withValues(alpha: 0.7)],
                          )
                        : null,
                    color: isSelected ? null : Colors.white.withValues(alpha: isDarkMode ? 0.1 : 0.15),
                    borderRadius: BorderRadius.circular(22),
                    border: isSelected
                        ? null
                        : Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: categoryColor.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(categoryIcon, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        category,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        
        // Now Playing Mini Player (if music is playing)
        if (_isPlayingPreview && _currentlyPlayingTrackId != null)
          _buildMiniPlayer(isDarkMode),
        
        // Track List with professional design
        if (_selectedMusicCategory != 'No Music' && currentTracks.isNotEmpty)
          _buildTrackList(currentTracks, isDarkMode)
        else if (_selectedMusicCategory == 'No Music')
          _buildNoMusicState(isDarkMode),
          
        // Selected Track Display
        if (_selectedMusicTrack != null && !_isPlayingPreview)
          _buildSelectedTrackCard(isDarkMode),
      ],
    );
  }

  Widget _buildMiniPlayer(bool isDarkMode) {
    final currentTrack = MusicService.currentTrack;
    if (currentTrack == null) return const SizedBox.shrink();
    
    final progress = _totalDuration.inMilliseconds > 0 
        ? _currentPosition.inMilliseconds / _totalDuration.inMilliseconds 
        : 0.0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF8E2DE2).withValues(alpha: 0.9),
            const Color(0xFF4A00E0).withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8E2DE2).withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Album Art / Animation
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(Icons.music_note, color: Colors.white, size: 24),
                    // Animated waves
                    AnimatedBuilder(
                      animation: _waveController,
                      builder: (context, child) {
                        return CustomPaint(
                          size: const Size(56, 56),
                          painter: _AudioWavePainter(
                            progress: _waveController.value,
                            isPlaying: _isPlayingPreview,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Track Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isPlayingPreview ? Icons.volume_up : Icons.volume_mute,
                                color: Colors.white,
                                size: 10,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                _isPlayingPreview ? 'NOW PLAYING' : 'PAUSED',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentTrack.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      currentTrack.artist,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Controls
              Row(
                children: [
                  // Play/Pause
                  GestureDetector(
                    onTap: () => _toggleMusicPreview(currentTrack),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Icon(
                        _isPlayingPreview ? Icons.pause : Icons.play_arrow,
                        color: const Color(0xFF8E2DE2),
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Stop
                  GestureDetector(
                    onTap: _stopMusicPreview,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.stop,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress Bar
          Column(
            children: [
              GestureDetector(
                onTapDown: (details) {
                  final box = context.findRenderObject() as RenderBox;
                  final localPosition = box.globalToLocal(details.globalPosition);
                  final percent = (localPosition.dx - 12) / (box.size.width - 24);
                  _seekMusic(percent.clamp(0.0, 1.0));
                },
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Stack(
                    children: [
                      FractionallySizedBox(
                        widthFactor: progress.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    MusicService.formatDuration(_currentPosition),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    MusicService.formatDuration(_totalDuration),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Volume Control
          Row(
            children: [
              Icon(
                _volume == 0 ? Icons.volume_mute : Icons.volume_up,
                color: Colors.white.withValues(alpha: 0.7),
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
                    thumbColor: Colors.white,
                    overlayColor: Colors.white.withValues(alpha: 0.2),
                  ),
                  child: Slider(
                    value: _volume,
                    onChanged: (value) => _setVolume(value),
                    min: 0.0,
                    max: 1.0,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(_volume * 100).toInt()}%',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrackList(List<MusicTrack> tracks, bool isDarkMode) {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: isDarkMode ? 0.05 : 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8E2DE2).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.headphones,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${tracks.length} Tracks Available',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  'Tap to play',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // Track list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: tracks.length,
              itemBuilder: (context, index) {
                final track = tracks[index];
                final isSelected = _selectedMusicTrack?.id == track.id;
                final isPlaying = _currentlyPlayingTrackId == track.id && _isPlayingPreview;
                
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedMusicTrack = track);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: isPlaying
                          ? LinearGradient(
                              colors: [
                                const Color(0xFF8E2DE2).withValues(alpha: 0.3),
                                const Color(0xFF4A00E0).withValues(alpha: 0.3),
                              ],
                            )
                          : isSelected
                              ? LinearGradient(
                                  colors: [
                                    AppTheme.iconGreen.withValues(alpha: 0.3),
                                    AppTheme.iconGreen.withValues(alpha: 0.2),
                                  ],
                                )
                              : null,
                      color: (!isPlaying && !isSelected) ? Colors.transparent : null,
                      borderRadius: BorderRadius.circular(12),
                      border: isPlaying
                          ? Border.all(color: const Color(0xFF8E2DE2).withValues(alpha: 0.5), width: 1.5)
                          : isSelected
                              ? Border.all(color: AppTheme.iconGreen.withValues(alpha: 0.5), width: 1.5)
                              : null,
                    ),
                    child: Row(
                      children: [
                        // Track number / Play button
                        GestureDetector(
                          onTap: () => _toggleMusicPreview(track),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: isPlaying
                                  ? const LinearGradient(
                                      colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                                    )
                                  : null,
                              color: isPlaying 
                                  ? null 
                                  : isSelected
                                      ? AppTheme.iconGreen
                                      : Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Track info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                track.name,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: (isSelected || isPlaying) ? FontWeight.bold : FontWeight.w500,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                track.artist,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Duration & Status
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (isPlaying)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.equalizer, color: Colors.white, size: 12),
                                    SizedBox(width: 4),
                                    Text(
                                      'Playing',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Text(
                                track.duration,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 12,
                                ),
                              ),
                            if (isSelected && !isPlaying)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.iconGreen,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoMusicState(bool isDarkMode) {
    return Container(
      height: 100,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: isDarkMode ? 0.05 : 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.music_off,
                color: Colors.white.withValues(alpha: 0.5),
                size: 28,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Video will be created without background music',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedTrackCard(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.iconGreen.withValues(alpha: 0.2),
              AppTheme.iconGreen.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.iconGreen.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            // Play button
            GestureDetector(
              onTap: () => _toggleMusicPreview(_selectedMusicTrack!),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppTheme.iconGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Track info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.iconGreen.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'SELECTED FOR VIDEO',
                          style: TextStyle(
                            color: AppTheme.iconGreen,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedMusicTrack!.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _selectedMusicTrack!.artist,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Clear button
            GestureDetector(
              onTap: () {
                _stopMusicPreview();
                setState(() => _selectedMusicTrack = null);
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.red,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationSection(bool isDarkMode) {
    final durations = ['15s', '30s', '60s', '90s', '120s'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Video Duration',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : AppTheme.textWhite,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: durations.map((duration) {
            final isSelected = _selectedDuration == duration;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedDuration = duration),
                child: Container(
                  margin: EdgeInsets.only(right: duration != '120s' ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.iconPurple
                        : Colors.white.withValues(alpha: isDarkMode ? 0.1 : 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected 
                        ? null 
                        : Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Center(
                    child: Text(
                      duration,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGenerateButton(int mediaCount, bool isDarkMode) {
    final canGenerate = mediaCount > 0 && !_isGenerating;
    
    return GestureDetector(
      onTap: canGenerate ? _generateVideo : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: canGenerate 
              ? (isDarkMode 
                  ? const LinearGradient(colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)])
                  : AppTheme.videoMemoriesGradient)
              : LinearGradient(
                  colors: [Colors.grey[600]!, Colors.grey[700]!],
                ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: canGenerate
              ? [
                  BoxShadow(
                    color: const Color(0xFF24243E).withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isGenerating)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            else
              Icon(
                _isGenerated ? Icons.refresh : Icons.movie_creation,
                color: Colors.white,
                size: 22,
              ),
            const SizedBox(width: 12),
            Text(
              _isGenerating 
                  ? 'Creating Video...' 
                  : _isGenerated 
                      ? 'Create New Video'
                      : mediaCount > 0 
                          ? 'Generate Video ($mediaCount items)'
                          : 'Add Media First',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateVideo() async {
    final mediaCount = _getMediaCount();
    
    if (mediaCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please add photos or videos first from the gallery screens'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    // Stop music preview before generating
    await _stopMusicPreview();

    setState(() {
      _isGenerating = true;
      _isGenerated = false;
      _generationProgress = 0;
      _generationStatus = 'Starting...';
    });
    
    // Get all media paths
    final imagePaths = VideoGeneratorService.getAllMediaPaths();
    
    // Parse duration
    final durationStr = _selectedDuration.replaceAll('s', '');
    final durationSeconds = int.tryParse(durationStr) ?? 30;
    
    // Get video style
    final videoStyle = VideoGeneratorService.getStyleFromName(_selectedStyle);
    
    // Generate video with progress callback
    final video = await VideoGeneratorService.generateVideo(
      imagePaths: imagePaths,
      style: videoStyle,
      durationSeconds: durationSeconds,
      backgroundMusic: _selectedMusicTrack,
      onProgress: (progress, status) {
        if (mounted) {
          setState(() {
            _generationProgress = progress;
            _generationStatus = status;
          });
        }
      },
    );
    
    if (mounted) {
      if (video != null) {
        setState(() {
          _isGenerating = false;
          _isGenerated = true;
          _generatedVideo = video;
        });
        
        // Navigate to preview screen
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoPreviewScreen(video: video),
            ),
          );
        }
      } else {
        setState(() {
          _isGenerating = false;
          _isGenerated = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to generate video. Please try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _openVideoPreview() {
    if (_generatedVideo != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPreviewScreen(video: _generatedVideo!),
        ),
      );
    }
  }
}

// ==========================================
// HELPER WIDGETS
// ==========================================

class _MediaCountItem extends StatelessWidget {
  final IconData icon;
  final int count;
  final String label;
  final Color color;

  const _MediaCountItem({
    required this.icon,
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Audio Wave Painter for visual feedback
class _AudioWavePainter extends CustomPainter {
  final double progress;
  final bool isPlaying;
  
  _AudioWavePainter({required this.progress, required this.isPlaying});
  
  @override
  void paint(Canvas canvas, Size size) {
    if (!isPlaying) return;
    
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    
    final centerY = size.height / 2;
    final barWidth = 3.0;
    final maxHeight = size.height * 0.4;
    final barCount = 5;
    final spacing = (size.width - barCount * barWidth) / (barCount + 1);
    
    for (int i = 0; i < barCount; i++) {
      final x = spacing + i * (barWidth + spacing);
      final phase = (progress * 2 * math.pi) + (i * math.pi / 3);
      final height = maxHeight * (0.3 + 0.7 * ((math.sin(phase) + 1) / 2));
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(x + barWidth / 2, centerY),
            width: barWidth,
            height: height,
          ),
          const Radius.circular(1.5),
        ),
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(_AudioWavePainter oldDelegate) => 
      progress != oldDelegate.progress || isPlaying != oldDelegate.isPlaying;
}
