import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../providers/media_cache_provider.dart';
import '../../widgets/beautiful_back_button.dart';
import 'video_memories_screen.dart';

class PhotoGalleryScreen extends StatefulWidget {
  const PhotoGalleryScreen({super.key});

  @override
  State<PhotoGalleryScreen> createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends State<PhotoGalleryScreen> {
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
        await _cache.loadPhotos();
      } else {
        _hasPermission = false;
        _errorMessage = 'Gallery permission required to view your 2025 photos';
      }
    } catch (e) {
      _errorMessage = 'Error loading photos: $e';
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshPhotos() async {
    setState(() => _isLoading = true);
    await _cache.refreshPhotos();
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

  void _togglePhotoSelection(String assetId) {
    _cache.togglePhotoSelection(assetId);
    setState(() {});
  }

  void _createVideoFromSelection() {
    if (_cache.selectedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select at least one photo'),
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
          selectedPhotoIds: _cache.selectedPhotoIds.toList(),
        ),
      ),
    ).then((_) {
      // Clear selection after returning
      _cache.clearSelection();
      setState(() => _selectionMode = false);
    });
  }

  List<AssetEntity> _getFilteredPhotos() {
    if (_selectedMonth == 'All') {
      return _cache.getAllPhotosFlat();
    }
    return _cache.photosByMonth[_selectedMonth] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final photos = _getFilteredPhotos();
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF667EEA), Color(0xFF764BA2), Color(0xFFf093fb)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              _buildAppBar(),
              
              // Month Filter
              if (_hasPermission && _cache.photoMonths.isNotEmpty)
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
                              'Loading 2025 photos from gallery...',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      )
                    : !_hasPermission
                        ? _buildPermissionRequest()
                        : photos.isEmpty
                            ? _buildEmptyState()
                            : RefreshIndicator(
                                onRefresh: _refreshPhotos,
                                color: const Color(0xFF667EEA),
                                child: _buildPhotoGrid(photos),
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
              backgroundColor: const Color(0xFF8E2DE2),
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
                      : 'Photos 2025',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${_cache.totalPhotos} photos from your gallery',
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
            tooltip: _selectionMode ? 'Cancel Selection' : 'Select Photos',
          ),
          // Refresh Button
          IconButton(
            onPressed: _refreshPhotos,
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
        itemCount: _cache.photoMonths.length,
        itemBuilder: (context, index) {
          final month = _cache.photoMonths[index];
          final isSelected = _selectedMonth == month;
          final count = month == 'All' 
              ? _cache.totalPhotos 
              : (_cache.photosByMonth[month]?.length ?? 0);
          
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
                      color: isSelected ? const Color(0xFF667EEA) : Colors.white,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? const Color(0xFF667EEA).withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        color: isSelected ? const Color(0xFF667EEA) : Colors.white,
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
                Icons.photo_library,
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
              _errorMessage ?? 'We need access to your gallery to show your 2025 photos',
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
                foregroundColor: const Color(0xFF667EEA),
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
                Icons.photo_camera,
                size: 64,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No 2025 Photos Yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _selectedMonth == 'All'
                  ? 'Your 2025 photos will appear here automatically'
                  : 'No photos found for $_selectedMonth',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshPhotos,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF667EEA),
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

  Widget _buildPhotoGrid(List<AssetEntity> photos) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final photo = photos[index];
        final isSelected = _cache.isPhotoSelected(photo.id);
        
        return GestureDetector(
          onTap: () {
            if (_selectionMode) {
              _togglePhotoSelection(photo.id);
            } else {
              _openPhotoViewer(photos, index);
            }
          },
          onLongPress: () {
            if (!_selectionMode) {
              setState(() => _selectionMode = true);
            }
            _togglePhotoSelection(photo.id);
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Photo Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: FutureBuilder<Uint8List?>(
                  future: photo.thumbnailDataWithSize(const ThumbnailSize(300, 300)),
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
              
              // Selection Overlay
              if (_selectionMode)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: isSelected 
                          ? const Color(0xFF8E2DE2).withValues(alpha: 0.4)
                          : Colors.black.withValues(alpha: 0.2),
                      border: isSelected
                          ? Border.all(color: const Color(0xFF8E2DE2), width: 3)
                          : null,
                    ),
                  ),
                ),
              
              // Selection Checkbox
              if (_selectionMode)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? const Color(0xFF8E2DE2) 
                          : Colors.white.withValues(alpha: 0.8),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.grey,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                ),
              
              // Date Badge (when not in selection mode)
              if (!_selectionMode)
                Positioned(
                  bottom: 4,
                  left: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${photo.createDateTime.day}/${photo.createDateTime.month}',
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

  void _openPhotoViewer(List<AssetEntity> photos, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoViewerScreen(
          photos: photos,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}

// Full screen photo viewer
class PhotoViewerScreen extends StatefulWidget {
  final List<AssetEntity> photos;
  final int initialIndex;

  const PhotoViewerScreen({
    super.key,
    required this.photos,
    required this.initialIndex,
  });

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${_currentIndex + 1} / ${widget.photos.length}',
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.photos.length,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        itemBuilder: (context, index) {
          final photo = widget.photos[index];
          return FutureBuilder<Uint8List?>(
            future: photo.thumbnailDataWithSize(const ThumbnailSize(1080, 1080)),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                return InteractiveViewer(
                  child: Center(
                    child: Image.memory(
                      snapshot.data!,
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              }
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            },
          );
        },
      ),
    );
  }
}
