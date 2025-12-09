import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../utils/app_theme.dart';
import '../../services/music_service.dart';
import '../../services/video_generator_service.dart';
import '../../providers/app_provider.dart';
import '../../providers/media_cache_provider.dart';
import '../../widgets/beautiful_back_button.dart';
import 'video_preview_screen.dart';

class VideoMemoriesScreen extends StatefulWidget {
  final List<String>? selectedPhotoIds;
  final List<String>? selectedVideoIds;
  
  const VideoMemoriesScreen({
    super.key,
    this.selectedPhotoIds,
    this.selectedVideoIds,
  });

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
  
  // Selected media from gallery
  List<AssetEntity> _selectedPhotos = [];
  List<AssetEntity> _selectedVideos = [];
  bool _isLoadingMedia = true;
  
  // Music playback state
  bool _isPlayingPreview = false;
  String? _currentlyPlayingTrackId;
  
  // Subscriptions
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<bool>? _playingSub;
  
  // Animation Controllers
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  // Video Styles
  final List<Map<String, dynamic>> _videoStyles = [
    {'name': 'Cinematic', 'icon': Icons.movie_filter, 'color': const Color(0xFF8E2DE2)},
    {'name': 'Slideshow', 'icon': Icons.photo_library, 'color': const Color(0xFF00C9FF)},
    {'name': 'Dynamic', 'icon': Icons.speed, 'color': const Color(0xFFFF5E62)},
    {'name': 'Highlights', 'icon': Icons.star, 'color': const Color(0xFFFFD200)},
    {'name': 'Memories', 'icon': Icons.favorite, 'color': const Color(0xFFFF6B8A)},
    {'name': 'Modern', 'icon': Icons.auto_awesome, 'color': const Color(0xFF4ECDC4)},
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
    
    _initMusicService();
    _loadSelectedMedia();
  }
  
  /// Load selected photos and videos from MediaCacheProvider
  Future<void> _loadSelectedMedia() async {
    setState(() => _isLoadingMedia = true);
    
    try {
      final cache = MediaCacheProvider();
      
      // Get selected photos by IDs
      if (widget.selectedPhotoIds != null && widget.selectedPhotoIds!.isNotEmpty) {
        final allPhotos = cache.getAllPhotosFlat();
        _selectedPhotos = allPhotos.where((photo) => 
          widget.selectedPhotoIds!.contains(photo.id)
        ).toList();
      }
      
      // Get selected videos by IDs
      if (widget.selectedVideoIds != null && widget.selectedVideoIds!.isNotEmpty) {
        final allVideos = cache.getAllVideosFlat();
        _selectedVideos = allVideos.where((video) => 
          widget.selectedVideoIds!.contains(video.id)
        ).toList();
      }
      
      // Auto-select random music
      if (_selectedPhotos.isNotEmpty || _selectedVideos.isNotEmpty) {
        _autoSelectRandomMusic();
      }
      
    } catch (e) {
      debugPrint('Error loading selected media: $e');
    }
    
    if (mounted) {
      setState(() => _isLoadingMedia = false);
    }
  }
  
  void _autoSelectRandomMusic() {
    final allTracks = <MusicTrack>[];
    for (final category in MusicService.categories) {
      allTracks.addAll(MusicService.getTracksByCategory(category));
    }
    
    if (allTracks.isNotEmpty) {
      final random = math.Random();
      final randomTrack = allTracks[random.nextInt(allTracks.length)];
      setState(() {
        _selectedMusicTrack = randomTrack;
        _selectedMusicCategory = randomTrack.category;
      });
    }
  }

  Future<void> _initMusicService() async {
    await MusicService.init();
    
    _positionSub = MusicService.positionStream.listen((position) {
      if (mounted) setState(() {});
    });
    
    _durationSub = MusicService.durationStream.listen((duration) {
      if (mounted) setState(() {});
    });
    
    _playingSub = MusicService.playingStream.listen((isPlaying) {
      if (mounted) setState(() => _isPlayingPreview = isPlaying);
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _playingSub?.cancel();
    MusicService.stop();
    _animController.dispose();
    super.dispose();
  }

  int _getMediaCount() => _selectedPhotos.length + _selectedVideos.length;

  Future<void> _toggleMusicPreview(MusicTrack track) async {
    if (_currentlyPlayingTrackId == track.id && _isPlayingPreview) {
      await MusicService.pause();
      setState(() => _isPlayingPreview = false);
    } else if (_currentlyPlayingTrackId == track.id && !_isPlayingPreview) {
      await MusicService.resume();
      setState(() => _isPlayingPreview = true);
    } else {
      await MusicService.play(track);
      setState(() {
        _currentlyPlayingTrackId = track.id;
        _isPlayingPreview = true;
      });
    }
  }

  Future<void> _stopMusicPreview() async {
    await MusicService.stop();
    setState(() {
      _isPlayingPreview = false;
      _currentlyPlayingTrackId = null;
    });
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
              _buildAppBar(context, isDarkMode),
              Expanded(
                child: _isLoadingMedia
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: Colors.white),
                            SizedBox(height: 16),
                            Text('Loading selected media...', style: TextStyle(color: Colors.white70)),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(16),
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
                              mediaCount > 0
                                  ? 'Create video from $mediaCount selected items'
                                  : 'No items selected',
                              style: TextStyle(
                                fontSize: 14,
                                color: (isDarkMode ? Colors.white : AppTheme.textWhite).withValues(alpha: 0.7),
                              ),
                            ),
                            if (_selectedMusicTrack != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.iconGreen.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.music_note, color: AppTheme.iconGreen, size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Music: ${_selectedMusicTrack!.name}',
                                        style: const TextStyle(color: AppTheme.iconGreen, fontSize: 11, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            const SizedBox(height: 20),
                            
                            // Selected Photos Preview
                            if (_selectedPhotos.isNotEmpty) ...[
                              _buildSelectedPhotosGrid(isDarkMode),
                              const SizedBox(height: 24),
                            ],
                            
                            // No selection message
                            if (mediaCount == 0) ...[
                              _buildNoSelectionMessage(isDarkMode),
                              const SizedBox(height: 24),
                            ],
                            
                            // Video Generation Preview
                            if (mediaCount > 0) ...[
                              _buildPreviewArea(isDarkMode, mediaCount),
                              const SizedBox(height: 24),
                              _buildStyleSection(isDarkMode),
                              const SizedBox(height: 24),
                              _buildMusicSection(isDarkMode),
                              const SizedBox(height: 24),
                              _buildDurationSection(isDarkMode),
                              const SizedBox(height: 28),
                            ],
                            
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
              _stopMusicPreview();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedPhotosGrid(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.photo_library, color: isDarkMode ? Colors.white : AppTheme.textWhite, size: 20),
            const SizedBox(width: 8),
            Text(
              'Selected Photos (${_selectedPhotos.length})',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : AppTheme.textWhite,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: isDarkMode ? 0.1 : 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(8),
            itemCount: _selectedPhotos.length,
            itemBuilder: (context, index) {
              final photo = _selectedPhotos[index];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: FutureBuilder<Uint8List?>(
                    future: photo.thumbnailDataWithSize(const ThumbnailSize(200, 200)),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data != null) {
                        return Stack(
                          children: [
                            Image.memory(snapshot.data!, width: 100, height: 100, fit: BoxFit.cover),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                      return Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey[800],
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54)),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNoSelectionMessage(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: isDarkMode ? 0.1 : 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(Icons.photo_library_outlined, size: 64, color: Colors.white.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'No Photos Selected',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : AppTheme.textWhite),
          ),
          const SizedBox(height: 8),
          Text(
            'Go to Photos or Videos screen and select items to create your video',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: (isDarkMode ? Colors.white : AppTheme.textWhite).withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Go Back to Gallery'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.iconPink,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewArea(bool isDarkMode, int mediaCount) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: isDarkMode 
              ? const LinearGradient(colors: [Color(0xFF1A1A2E), Color(0xFF302B63)])
              : AppTheme.videoMemoriesGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: const Color(0xFF24243E).withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        child: _isGenerating
            ? _buildGeneratingState()
            : _isGenerated
                ? _buildGeneratedState()
                : _buildReadyState(mediaCount),
      ),
    );
  }

  Widget _buildReadyState(int mediaCount) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 60, height: 60,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
          child: const Icon(Icons.movie_creation, color: Colors.white, size: 30),
        ),
        const SizedBox(height: 12),
        const Text('Ready to Create', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        Text('$mediaCount photos/videos selected', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.7))),
      ],
    );
  }

  Widget _buildGeneratingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 60, height: 60,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(value: _generationProgress / 100, color: Colors.white, strokeWidth: 4, backgroundColor: Colors.white.withValues(alpha: 0.2)),
              Text('$_generationProgress%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('Creating Your Video...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        Text(_generationStatus.isNotEmpty ? _generationStatus : 'Style: $_selectedStyle', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.7)), textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildGeneratedState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 60, height: 60,
          decoration: const BoxDecoration(color: AppTheme.iconGreen, shape: BoxShape.circle),
          child: const Icon(Icons.check, color: Colors.white, size: 35),
        ),
        const SizedBox(height: 14),
        const Text('Video Ready!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        if (_generatedVideo != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('${_generatedVideo!.photoCount} photos • ${_generatedVideo!.durationSeconds}s', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.7))),
          ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildActionChip(Icons.play_circle_outline, 'Preview', _openVideoPreview),
            const SizedBox(width: 12),
            _buildActionChip(Icons.share, 'Share', _openVideoPreview),
            const SizedBox(width: 12),
            _buildActionChip(Icons.download, 'Save', _openVideoPreview),
          ],
        ),
      ],
    );
  }

  Widget _buildActionChip(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildStyleSection(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Video Style', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.white : AppTheme.textWhite)),
        const SizedBox(height: 12),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _videoStyles.length,
            itemBuilder: (context, index) {
              final style = _videoStyles[index];
              final isSelected = _selectedStyle == style['name'];
              return GestureDetector(
                onTap: () => setState(() => _selectedStyle = style['name']),
                child: Container(
                  width: 80,
                  margin: EdgeInsets.only(right: index < _videoStyles.length - 1 ? 12 : 0),
                  decoration: BoxDecoration(
                    gradient: isSelected ? LinearGradient(colors: [style['color'], style['color'].withValues(alpha: 0.7)]) : null,
                    color: isSelected ? null : Colors.white.withValues(alpha: isDarkMode ? 0.1 : 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isSelected ? style['color'] : Colors.white.withValues(alpha: 0.2), width: isSelected ? 2 : 1),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(style['icon'], color: isSelected ? Colors.white : style['color'], size: 28),
                      const SizedBox(height: 8),
                      Text(style['name'], style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? Colors.white : (isDarkMode ? Colors.white : AppTheme.textWhite))),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMusicSection(bool isDarkMode) {
    final categories = MusicService.categories;
    final currentTracks = MusicService.getTracksByCategory(_selectedMusicCategory);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Background Music', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.white : AppTheme.textWhite)),
            if (_selectedMusicTrack != null)
              GestureDetector(
                onTap: () { _stopMusicPreview(); setState(() => _selectedMusicTrack = null); },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.close, color: Colors.red, size: 14), SizedBox(width: 4), Text('Clear', style: TextStyle(color: Colors.red, fontSize: 12))]),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        // Category Tabs
        SizedBox(
          height: 36,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = _selectedMusicCategory == category;
              return GestureDetector(
                onTap: () => setState(() => _selectedMusicCategory = category),
                child: Container(
                  margin: EdgeInsets.only(right: index < categories.length - 1 ? 8 : 0),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.iconPink : Colors.white.withValues(alpha: isDarkMode ? 0.1 : 0.15),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: isSelected ? AppTheme.iconPink : Colors.white.withValues(alpha: 0.2)),
                  ),
                  alignment: Alignment.center,
                  child: Text(category, style: TextStyle(color: isSelected ? Colors.white : (isDarkMode ? Colors.white70 : AppTheme.textWhite), fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, fontSize: 13)),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Music Tracks
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: isDarkMode ? 0.1 : 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: currentTracks.length,
            itemBuilder: (context, index) {
              final track = currentTracks[index];
              final isSelected = _selectedMusicTrack?.id == track.id;
              final isPlaying = _currentlyPlayingTrackId == track.id && _isPlayingPreview;
              return GestureDetector(
                onTap: () => setState(() => _selectedMusicTrack = track),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.iconPink.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? AppTheme.iconPink : Colors.transparent, width: isSelected ? 2 : 0),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => _toggleMusicPreview(track),
                        child: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(color: isPlaying ? AppTheme.iconPink : Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                          child: Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 18),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(track.name, style: TextStyle(color: isDarkMode ? Colors.white : AppTheme.textWhite, fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text('${track.artist} • ${track.duration}', style: TextStyle(color: (isDarkMode ? Colors.white : AppTheme.textWhite).withValues(alpha: 0.6), fontSize: 11)),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: AppTheme.iconGreen, shape: BoxShape.circle),
                          child: const Icon(Icons.check, color: Colors.white, size: 12),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDurationSection(bool isDarkMode) {
    final durations = ['15s', '30s', '60s', '90s'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Video Duration', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.white : AppTheme.textWhite)),
        const SizedBox(height: 12),
        Row(
          children: durations.map((duration) {
            final isSelected = _selectedDuration == duration;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedDuration = duration),
                child: Container(
                  margin: EdgeInsets.only(right: duration != durations.last ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: isSelected ? const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]) : null,
                    color: isSelected ? null : Colors.white.withValues(alpha: isDarkMode ? 0.1 : 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? Colors.transparent : Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Text(duration, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : (isDarkMode ? Colors.white : AppTheme.textWhite), fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, fontSize: 15)),
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
              ? (isDarkMode ? const LinearGradient(colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)]) : AppTheme.videoMemoriesGradient)
              : LinearGradient(colors: [Colors.grey[600]!, Colors.grey[700]!]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: canGenerate ? [BoxShadow(color: const Color(0xFF24243E).withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 6))] : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isGenerating)
              const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            else
              Icon(_isGenerated ? Icons.refresh : Icons.movie_creation, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Text(
              _isGenerating ? 'Creating Video...' : _isGenerated ? 'Create New Video' : mediaCount > 0 ? 'Generate Video ($mediaCount items)' : 'Select Photos First',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateVideo() async {
    if (_getMediaCount() == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Please select photos or videos first'), backgroundColor: Colors.orange, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      );
      return;
    }

    await _stopMusicPreview();

    setState(() {
      _isGenerating = true;
      _isGenerated = false;
      _generationProgress = 0;
      _generationStatus = 'Starting...';
    });
    
    // Get actual file paths from selected photos
    List<String> imagePaths = [];
    for (final photo in _selectedPhotos) {
      final file = await photo.file;
      if (file != null && file.existsSync()) {
        imagePaths.add(file.path);
      }
    }
    
    final durationStr = _selectedDuration.replaceAll('s', '');
    final durationSeconds = int.tryParse(durationStr) ?? 30;
    final videoStyle = VideoGeneratorService.getStyleFromName(_selectedStyle);
    
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
        
        if (mounted) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => VideoPreviewScreen(video: video)));
        }
      } else {
        setState(() {
          _isGenerating = false;
          _isGenerated = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Failed to generate video. Please try again.'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        );
      }
    }
  }

  void _openVideoPreview() {
    if (_generatedVideo != null) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => VideoPreviewScreen(video: _generatedVideo!)));
    }
  }
}
