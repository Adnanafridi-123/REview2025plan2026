import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';
import '../../providers/media_cache_provider.dart';
import '../../widgets/beautiful_back_button.dart';
import 'auto_video_memories_screen.dart';

class VideoGalleryScreen extends StatefulWidget {
  const VideoGalleryScreen({super.key});

  @override
  State<VideoGalleryScreen> createState() => _VideoGalleryScreenState();
}

class _VideoGalleryScreenState extends State<VideoGalleryScreen> with TickerProviderStateMixin {
  final MediaCacheProvider _cache = MediaCacheProvider();
  String _selectedMonth = 'All';
  bool _isLoading = true;
  bool _selectionMode = false;
  bool _hasPermission = false;
  String? _errorMessage;
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _requestPermissionAndLoad();
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
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
        builder: (context) => const AutoVideoMemoriesScreen(),
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
    final totalDuration = videos.fold<int>(0, (sum, v) => sum + v.duration);
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0f0c29),
              Color(0xFF302b63),
              Color(0xFF24243e),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 🔥 Pro App Bar
              _buildProAppBar(),
              
              // 📊 Stats Dashboard
              if (_hasPermission && !_isLoading)
                _buildStatsDashboard(totalDuration),
              
              // 🗓️ Month Filter
              if (_hasPermission && _cache.videoMonths.isNotEmpty)
                _buildProMonthFilter(),
              
              // Content
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : !_hasPermission
                        ? _buildPermissionRequest()
                        : videos.isEmpty
                            ? _buildEmptyState()
                            : RefreshIndicator(
                                onRefresh: _refreshVideos,
                                color: const Color(0xFF667eea),
                                child: _buildProVideoGrid(videos),
                              ),
              ),
            ],
          ),
        ),
      ),
      // 🎬 Create Video FAB
      floatingActionButton: _selectionMode && _cache.selectedCount > 0
          ? ScaleTransition(
              scale: _pulseAnimation,
              child: FloatingActionButton.extended(
                onPressed: _createVideoFromSelection,
                backgroundColor: const Color(0xFF667eea),
                icon: const Icon(Icons.movie_creation, color: Colors.white),
                label: Text(
                  'Create Video (${_cache.selectedCount})',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            )
          : null,
    );
  }
  
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667eea).withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Loading 2025 Videos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Scanning your gallery...',
            style: TextStyle(color: Colors.white.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatsDashboard(int totalDuration) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Expanded(child: _buildStatItem('🎬', _cache.totalVideos, 'Videos', const Color(0xFF4ECDC4))),
          _buildDivider(),
          Expanded(child: _buildStatItem('⏱️', totalDuration ~/ 60, 'Minutes', const Color(0xFFFFE66D))),
          _buildDivider(),
          Expanded(child: _buildStatItem('📅', _cache.videoMonths.length - 1, 'Months', const Color(0xFFFF6B6B))),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(String emoji, int value, String label, Color color) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
  
  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.white.withOpacity(0.1),
    );
  }

  Widget _buildProAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _selectionMode 
                          ? '${_cache.selectedCount} Selected'
                          : '🎬 Videos 2025',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (!_selectionMode) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'PRO',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  'Your cinematic memories',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          // Selection Mode Toggle
          _buildActionButton(
            icon: _selectionMode ? Icons.close : Icons.checklist,
            color: _selectionMode ? const Color(0xFFFF6B6B) : const Color(0xFF4ECDC4),
            onTap: _toggleSelectionMode,
          ),
          const SizedBox(width: 8),
          // Refresh Button
          _buildActionButton(
            icon: Icons.refresh,
            color: const Color(0xFFFFE66D),
            onTap: _refreshVideos,
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButton({required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _buildProMonthFilter() {
    return Container(
      height: 50,
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
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: isSelected 
                    ? const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)])
                    : null,
                color: isSelected ? null : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.2),
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: const Color(0xFF667eea).withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ] : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    month == 'All' ? '✨ All' : '📅 ${month.split(' ')[0]}',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? Colors.white.withOpacity(0.2)
                          : Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        color: Colors.white.withOpacity(isSelected ? 1.0 : 0.7),
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
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF667eea).withOpacity(0.3),
                    const Color(0xFF764ba2).withOpacity(0.3),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF667eea).withOpacity(0.5), width: 2),
              ),
              child: const Center(
                child: Text('🔐', style: TextStyle(fontSize: 50)),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Gallery Access Required',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'We need access to your gallery\nto show your 2025 videos',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.7),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: () async => await openAppSettings(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF667eea).withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.settings, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Open Settings',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _requestPermissionAndLoad,
              child: Text(
                'Try Again',
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
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
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF4ECDC4).withOpacity(0.3),
                    const Color(0xFF44A08D).withOpacity(0.3),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF4ECDC4).withOpacity(0.5), width: 2),
              ),
              child: const Center(
                child: Text('🎬', style: TextStyle(fontSize: 50)),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'No 2025 Videos Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _selectedMonth == 'All'
                  ? 'Your 2025 videos will appear\nhere automatically'
                  : 'No videos found for $_selectedMonth',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.7),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: _refreshVideos,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4ECDC4).withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Refresh',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProVideoGrid(List<AssetEntity> videos) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 16 / 10,
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
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: isSelected
                  ? Border.all(color: const Color(0xFF667eea), width: 3)
                  : Border.all(color: Colors.white.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: isSelected 
                      ? const Color(0xFF667eea).withOpacity(0.3)
                      : Colors.black.withOpacity(0.2),
                  blurRadius: isSelected ? 15 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Video Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: FutureBuilder<Uint8List?>(
                    future: video.thumbnailDataWithSize(const ThumbnailSize(400, 250)),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data != null) {
                        return Image.memory(
                          snapshot.data!,
                          fit: BoxFit.cover,
                        );
                      }
                      return Container(
                        color: const Color(0xFF1a1a2e),
                        child: Center(
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF667eea),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                // Gradient Overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Selection Overlay
                if (_selectionMode && isSelected)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: const Color(0xFF667eea).withOpacity(0.3),
                      ),
                    ),
                  ),
                
                // Play Button (center)
                if (!_selectionMode)
                  Center(
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF667eea).withOpacity(0.5),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.play_arrow, color: Colors.white, size: 30),
                    ),
                  ),
                
                // Selection Checkbox
                if (_selectionMode)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        gradient: isSelected 
                            ? const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)])
                            : null,
                        color: isSelected ? null : Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.grey.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                          : null,
                    ),
                  ),
                
                // Bottom Info Bar
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(14),
                        bottomRight: Radius.circular(14),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
                        ],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Date
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 10, color: Colors.white.withOpacity(0.7)),
                            const SizedBox(width: 4),
                            Text(
                              '${video.createDateTime.day}/${video.createDateTime.month}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        // Duration
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF667eea).withOpacity(0.8),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.play_circle_fill, size: 10, color: Colors.white),
                              const SizedBox(width: 3),
                              Text(
                                _formatDuration(duration),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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
