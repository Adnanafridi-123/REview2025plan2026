import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_theme.dart';
import '../../services/media_service.dart';
import '../../services/music_service.dart';
import '../../providers/app_provider.dart';
import '../../widgets/beautiful_back_button.dart';

class VideoMemoriesScreen extends StatefulWidget {
  const VideoMemoriesScreen({super.key});

  @override
  State<VideoMemoriesScreen> createState() => _VideoMemoriesScreenState();
}

class _VideoMemoriesScreenState extends State<VideoMemoriesScreen> with SingleTickerProviderStateMixin {
  String _selectedStyle = 'Cinematic';
  String _selectedDuration = '30s';
  MusicTrack? _selectedMusicTrack;
  String _selectedMusicCategory = 'English';
  bool _isGenerating = false;
  bool _isGenerated = false;
  int _generationProgress = 0;
  
  // Music playback state
  bool _isPlayingPreview = false;
  String? _currentlyPlayingTrackId;
  
  // Animation
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

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
    
    // Initialize music service
    MusicService.init();
  }

  @override
  void dispose() {
    // Stop music when leaving screen
    MusicService.stop();
    _animController.dispose();
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
                      
                      // Music Selection - Complete Library with Play/Pause
                      _buildMusicSection(isDarkMode),
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
          'Style: $_selectedStyle • Music: ${_selectedMusicTrack?.name ?? 'No Music'}',
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.7),
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
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ActionChip(
              icon: Icons.play_circle_outline,
              label: 'Preview',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Opening video preview...'),
                    backgroundColor: AppTheme.iconPurple,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            _ActionChip(
              icon: Icons.share,
              label: 'Share',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Sharing your video...'),
                    backgroundColor: AppTheme.iconGreen,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            _ActionChip(
              icon: Icons.download,
              label: 'Save',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Saving video to gallery...'),
                    backgroundColor: AppTheme.iconGreen,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
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

  Widget _buildMusicSection(bool isDarkMode) {
    final categories = [...MusicService.categories, 'No Music'];
    final currentTracks = _selectedMusicCategory != 'No Music' 
        ? MusicService.getTracksByCategory(_selectedMusicCategory)
        : <MusicTrack>[];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Background Music',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : AppTheme.textWhite,
              ),
            ),
            // Music preview controls
            if (_isPlayingPreview)
              GestureDetector(
                onTap: _stopMusicPreview,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.stop, color: Colors.red, size: 14),
                      SizedBox(width: 4),
                      Text('Stop', style: TextStyle(color: Colors.red, fontSize: 12)),
                    ],
                  ),
                ),
              )
            else if (_selectedMusicTrack != null)
              GestureDetector(
                onTap: () => setState(() => _selectedMusicTrack = null),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.music_off, color: Colors.red, size: 14),
                      SizedBox(width: 4),
                      Text('Clear', style: TextStyle(color: Colors.red, fontSize: 12)),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Music Categories
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: categories.map((category) {
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
                  // Stop any playing preview when changing category
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
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? categoryColor
                        : Colors.white.withValues(alpha: isDarkMode ? 0.1 : 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: isSelected
                        ? null
                        : Border.all(color: Colors.white.withValues(alpha: 0.2)),
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
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        
        // Track List with Play/Pause buttons
        if (_selectedMusicCategory != 'No Music' && currentTracks.isNotEmpty)
          Container(
            height: 240,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: isDarkMode ? 0.05 : 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                // Header with play instruction
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.headphones,
                        color: Colors.white.withValues(alpha: 0.7),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tap play button to preview music',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Track list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: currentTracks.length,
                    itemBuilder: (context, index) {
                      final track = currentTracks[index];
                      final isSelected = _selectedMusicTrack?.id == track.id;
                      final isPlaying = _currentlyPlayingTrackId == track.id && _isPlayingPreview;
                      
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedMusicTrack = track);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.iconGreen.withValues(alpha: 0.3)
                                : isPlaying
                                    ? AppTheme.iconPurple.withValues(alpha: 0.2)
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: isPlaying && !isSelected
                                ? Border.all(color: AppTheme.iconPurple.withValues(alpha: 0.5))
                                : null,
                          ),
                          child: Row(
                            children: [
                              // Play/Pause Button
                              GestureDetector(
                                onTap: () => _toggleMusicPreview(track),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: isPlaying
                                        ? AppTheme.iconPurple
                                        : isSelected
                                            ? AppTheme.iconGreen
                                            : Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    isPlaying ? Icons.pause : Icons.play_arrow,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            track.name,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: isSelected || isPlaying ? FontWeight.bold : FontWeight.normal,
                                              fontSize: 14,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (isPlaying)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppTheme.iconPurple,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.volume_up, color: Colors.white, size: 10),
                                                SizedBox(width: 2),
                                                Text(
                                                  'Playing',
                                                  style: TextStyle(color: Colors.white, fontSize: 9),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
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
                              const SizedBox(width: 8),
                              // Duration
                              Text(
                                track.duration,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 12,
                                ),
                              ),
                              // Selection indicator
                              if (isSelected) ...[
                                const SizedBox(width: 8),
                                Container(
                                  width: 24,
                                  height: 24,
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
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          )
        else if (_selectedMusicCategory == 'No Music')
          Container(
            height: 80,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: isDarkMode ? 0.05 : 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.music_off, color: Colors.white.withValues(alpha: 0.5), size: 24),
                  const SizedBox(width: 10),
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
          ),
          
        // Selected track indicator with play button
        if (_selectedMusicTrack != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.iconGreen.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.iconGreen.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  // Play/pause for selected track
                  GestureDetector(
                    onTap: () => _toggleMusicPreview(_selectedMusicTrack!),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _currentlyPlayingTrackId == _selectedMusicTrack?.id && _isPlayingPreview
                            ? AppTheme.iconPurple
                            : AppTheme.iconGreen,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _currentlyPlayingTrackId == _selectedMusicTrack?.id && _isPlayingPreview
                            ? Icons.pause
                            : Icons.play_arrow,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Selected for video:',
                          style: TextStyle(
                            color: AppTheme.iconGreen,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${_selectedMusicTrack!.name} - ${_selectedMusicTrack!.artist}',
                          style: const TextStyle(
                            color: AppTheme.iconGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
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
                    child: Icon(
                      Icons.close,
                      color: AppTheme.iconGreen.withValues(alpha: 0.7),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
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
    });
    
    // Simulate video generation with progress
    for (int i = 0; i <= 100; i += 5) {
      await Future.delayed(const Duration(milliseconds: 150));
      if (mounted) {
        setState(() => _generationProgress = i);
      }
    }
    
    if (mounted) {
      setState(() {
        _isGenerating = false;
        _isGenerated = true;
      });
      
      // Show success message with music URL info
      final musicInfo = _selectedMusicTrack != null 
          ? '${_selectedMusicTrack!.name} (${_selectedMusicTrack!.artist})'
          : 'No Music';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Video Created Successfully!',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '$_selectedStyle style • $_selectedDuration • $musicInfo',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.iconGreen,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }
}

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
