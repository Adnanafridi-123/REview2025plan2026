import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';
import '../../providers/media_cache_provider.dart';
import '../../widgets/beautiful_back_button.dart';
import 'video_memories_screen.dart';

class VideoGalleryScreen extends StatefulWidget {
  const VideoGalleryScreen({super.key});

  @override
  State<VideoGalleryScreen> createState() => _VideoGalleryScreenState();
}

class _VideoGalleryScreenState extends State<VideoGalleryScreen> {
  final MediaCacheProvider _cache = MediaCacheProvider();
  String _selectedMonth = 'All';
  bool _isLoading = true;
  bool _selectionMode = false;
  bool _hasPermission = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _requestPermissionAndLoad();
  }

  Future<void> _requestPermissionAndLoad() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Request permission
      final permission = await PhotoManager.requestPermissionExtend();
      
      if (permission.isAuth) {
        _hasPermission = true;
        await _cache.loadVideos();
      } else {
        _hasPermission = false;
        _errorMessage = 'Gallery permission required to view your 2025 videos';
      }
    } catch (e) {
      _errorMessage = 'Error loading videos: $e';
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshVideos() async {
    setState(() => _isLoading = true);
    await _cache.refreshVideos();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _selectionMode = !_selectionMode;
      if (!_selectionMode) {
        _cache.clearSelection();
      }
    });
  }

  void _toggleVideoSelection(String assetId) {
    _cache.toggleVideoSelection(assetId);
    setState(() {});
  }

  void _createVideoFromSelection() {
    if (_cache.selectedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select at least one video'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoMemoriesScreen(
          selectedVideoIds: _cache.selectedVideoIds.toList(),
        ),
      ),
    ).then((_) {
      // Clear selection after returning
      _cache.clearSelection();
      setState(() => _selectionMode = false);
    });
  }

  List<AssetEntity> _getFilteredVideos() {
    if (_selectedMonth == 'All') {
      return _cache.getAllVideosFlat();
    }
    return _cache.videosByMonth[_selectedMonth] ?? [];
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final videos = _getFilteredVideos();
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF11998E), Color(0xFF38EF7D), Color(0xFF56CCF2)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              _buildAppBar(),
              
              // Month Filter
              if (_hasPermission && _cache.videoMonths.isNotEmpty)
                _buildMonthFilter(),
              
              // Content
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: Colors.white),
                            SizedBox(height: 16),
                            Text(
                              'Loading 2025 videos from gallery...',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      )
                    : !_hasPermission
                        ? _buildPermissionRequest()
                        : videos.isEmpty
                            ? _buildEmptyState()
                            : RefreshIndicator(
                                onRefresh: _refreshVideos,
                                color: const Color(0xFF11998E),
                                child: _buildVideoGrid(videos),
                              ),
              ),
            ],
          ),
        ),
      ),
      // Create Video FAB
      floatingActionButton: _selectionMode && _cache.selectedCount > 0
          ? FloatingActionButton.extended(
              onPressed: _createVideoFromSelection,
              backgroundColor: const Color(0xFF11998E),
              icon: const Icon(Icons.movie_creation, color: Colors.white),
              label: Text(
                'Create Video (${_cache.selectedCount})',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          BeautifulBackButton(
            isDarkMode: false,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectionMode 
                      ? '${_cache.selectedCount} Selected'
                      : 'Videos 2025',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${_cache.totalVideos} videos from your gallery',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          // Selection Mode Toggle
          IconButton(
            onPressed: _toggleSelectionMode,
            icon: Icon(
              _selectionMode ? Icons.close : Icons.checklist,
              color: Colors.white,
              size: 26,
            ),
            tooltip: _selectionMode ? 'Cancel Selection' : 'Select Videos',
          ),
          // Refresh Button
          IconButton(
            onPressed: _refreshVideos,
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildMonthFilter() {
    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _cache.videoMonths.length,
        itemBuilder: (context, index) {
          final month = _cache.videoMonths[index];
          final isSelected = _selectedMonth == month;
          final count = month == 'All' 
              ? _cache.totalVideos 
              : (_cache.videosByMonth[month]?.length ?? 0);
          
          return GestureDetector(
            onTap: () => setState(() => _selectedMonth = month),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected 
                    ? Colors.white 
                    : Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    month == 'All' ? 'All' : month.split(' ')[0],
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF11998E) : Colors.white,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? const Color(0xFF11998E).withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        color: isSelected ? const Color(0xFF11998E) : Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPermissionRequest() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.video_library,
                size: 64,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Gallery Access Required',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'We need access to your gallery to show your 2025 videos',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                await openAppSettings();
              },
              icon: const Icon(Icons.settings),
              label: const Text('Open Settings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF11998E),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _requestPermissionAndLoad,
              child: const Text(
                'Try Again',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.videocam,
                size: 64,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No 2025 Videos Yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _selectedMonth == 'All'
                  ? 'Your 2025 videos will appear here automatically'
                  : 'No videos found for $_selectedMonth',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshVideos,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF11998E),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoGrid(List<AssetEntity> videos) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 16 / 9,
      ),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = videos[index];
        final isSelected = _cache.isVideoSelected(video.id);
        final duration = video.duration;
        
        return GestureDetector(
          onTap: () {
            if (_selectionMode) {
              _toggleVideoSelection(video.id);
            } else {
              _playVideo(video);
            }
          },
          onLongPress: () {
            if (!_selectionMode) {
              setState(() => _selectionMode = true);
            }
            _toggleVideoSelection(video.id);
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Video Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FutureBuilder<Uint8List?>(
                  future: video.thumbnailDataWithSize(const ThumbnailSize(400, 225)),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null) {
                      return Image.memory(
                        snapshot.data!,
                        fit: BoxFit.cover,
                      );
                    }
                    return Container(
                      color: Colors.grey[800],
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white54,
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Dark Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Selection Overlay
              if (_selectionMode)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: isSelected 
                          ? const Color(0xFF11998E).withValues(alpha: 0.4)
                          : Colors.black.withValues(alpha: 0.2),
                      border: isSelected
                          ? Border.all(color: const Color(0xFF11998E), width: 3)
                          : null,
                    ),
                  ),
                ),
              
              // Play Icon (when not in selection mode)
              if (!_selectionMode)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Color(0xFF11998E),
                      size: 28,
                    ),
                  ),
                ),
              
              // Selection Checkbox
              if (_selectionMode)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? const Color(0xFF11998E) 
                          : Colors.white.withValues(alpha: 0.8),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.grey,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                ),
              
              // Duration Badge
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _formatDuration(duration),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              
              // Date Badge
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${video.createDateTime.day}/${video.createDateTime.month}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _playVideo(AssetEntity video) async {
    final file = await video.file;
    if (file != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPlayerScreen(videoFile: file),
        ),
      );
    }
  }
}

// Video Player Screen
class VideoPlayerScreen extends StatefulWidget {
  final dynamic videoFile;

  const VideoPlayerScreen({super.key, required this.videoFile});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _controller = VideoPlayerController.file(widget.videoFile);
    await _controller.initialize();
    await _controller.play();
    if (mounted) {
      setState(() => _isInitialized = true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: _isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    VideoPlayer(_controller),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_controller.value.isPlaying) {
                            _controller.pause();
                          } else {
                            _controller.play();
                          }
                        });
                      },
                      child: Container(
                        color: Colors.transparent,
                        child: Center(
                          child: AnimatedOpacity(
                            opacity: _controller.value.isPlaying ? 0.0 : 1.0,
                            duration: const Duration(milliseconds: 300),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _controller.value.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : const CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}
