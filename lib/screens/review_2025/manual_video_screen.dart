import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import '../../widgets/beautiful_back_button.dart';

class ManualVideoScreen extends StatefulWidget {
  const ManualVideoScreen({super.key});

  @override
  State<ManualVideoScreen> createState() => _ManualVideoScreenState();
}

class _ManualVideoScreenState extends State<ManualVideoScreen> with TickerProviderStateMixin {
  bool _isLoading = true;
  bool _isGenerating = false;
  bool _isPlaying = false;
  bool _isSaving = false;
  int _currentPhotoIndex = 0;
  
  List<AssetEntity> _allPhotos = [];
  List<AssetEntity> _selectedPhotos = [];
  Set<String> _selectedIds = {};
  Uint8List? _currentImage;
  String _selectedMonth = 'All';
  
  Timer? _slideTimer;
  late AnimationController _fadeController;
  late AnimationController _zoomController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _zoomAnimation;
  
  // Audio player for background music
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isMusicPlaying = false;
  int _selectedSongIndex = 0;
  
  // Available songs
  final List<Map<String, dynamic>> _songs = [
    {'name': 'No Music', 'icon': '🔇', 'asset': null},
    {'name': 'Memories', 'icon': '🎵', 'asset': 'assets/audio/memories.mp3'},
    {'name': 'Emotional', 'icon': '💕', 'asset': 'assets/audio/emotional.mp3'},
    {'name': 'Happy', 'icon': '🎉', 'asset': 'assets/audio/happy.mp3'},
    {'name': 'Peaceful', 'icon': '🌸', 'asset': 'assets/audio/peaceful.mp3'},
    {'name': 'Epic', 'icon': '🎬', 'asset': 'assets/audio/epic.mp3'},
  ];

  final List<String> _monthNames = [
    'All', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

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
  
  // Show song selection dialog
  void _showSongSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF1a1a2e), Color(0xFF16213e)]),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🎵 Select Background Music', 
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ...List.generate(_songs.length, (index) {
              final song = _songs[index];
              final isSelected = _selectedSongIndex == index;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedSongIndex = index);
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
                      Text(song['icon'], style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 16),
                      Text(song['name'], style: TextStyle(
                        color: isSelected ? const Color(0xFFFFD700) : Colors.white,
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      )),
                      const Spacer(),
                      if (isSelected)
                        const Icon(Icons.check_circle, color: Color(0xFFFFD700)),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
  
  // Save current photo to gallery in HD
  Future<void> _saveCurrentPhoto() async {
    if (_currentImage == null) return;
    
    setState(() => _isSaving = true);
    
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/memory_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await file.writeAsBytes(_currentImage!);
      
      await Gal.putImage(file.path, album: '2025 Memories');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Photo saved to gallery! 📸'),
            ]),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }
  
  // Generate and save HD video to gallery
  Future<void> _saveAllPhotosToGallery() async {
    if (_selectedPhotos.isEmpty) return;
    
    setState(() => _isSaving = true);
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
      
      // Clean up old frames
      if (await framesDir.exists()) {
        await framesDir.delete(recursive: true);
      }
      await framesDir.create(recursive: true);
      
      // Save frames as numbered images
      _updateDialogProgress('Preparing photos...', 0.1);
      
      for (int i = 0; i < _selectedPhotos.length; i++) {
        final asset = _selectedPhotos[i];
        final data = await asset.thumbnailDataWithSize(
          const ThumbnailSize(1920, 1080),
          quality: 95,
        );
        if (data != null) {
          final framePath = '${framesDir.path}/frame_${i.toString().padLeft(5, '0')}.jpg';
          await File(framePath).writeAsBytes(data);
        }
        
        _updateDialogProgress(
          'Processing photo ${i + 1}/${_selectedPhotos.length}',
          0.1 + (0.4 * (i + 1) / _selectedPhotos.length),
        );
      }
      
      // Generate video with FFmpeg
      _updateDialogProgress('Creating HD video...', 0.6);
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = '${tempDir.path}/custom_video_$timestamp.mp4';
      
      // FFmpeg command: 4 seconds per image, HD quality
      final ffmpegCommand = '-framerate 1/4 -i "${framesDir.path}/frame_%05d.jpg" '
          '-c:v libx264 -r 30 -pix_fmt yuv420p -vf "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2,setsar=1" '
          '-preset medium -crf 23 "$outputPath"';
      
      final session = await FFmpegKit.execute(ffmpegCommand);
      final returnCode = await session.getReturnCode();
      
      if (ReturnCode.isSuccess(returnCode)) {
        _updateDialogProgress('Saving to gallery...', 0.9);
        
        // Save video to gallery
        await Gal.putVideo(outputPath, album: '2025 Memories');
        
        // Clean up
        await framesDir.delete(recursive: true);
        await File(outputPath).delete();
        
        _updateDialogProgress('Done!', 1.0);
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('HD Video saved! (${_selectedPhotos.length} photos) 🎬'),
              ]),
              backgroundColor: const Color(0xFF4CAF50),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } else {
        throw Exception('FFmpeg failed');
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isSaving = false);
      if (wasPlaying) _togglePlayPause();
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

      // Sort by date
      allAssets.sort((a, b) => b.createDateTime.compareTo(a.createDateTime));

      setState(() {
        _allPhotos = allAssets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<AssetEntity> _getFilteredPhotos() {
    if (_selectedMonth == 'All') return _allPhotos;
    
    final monthIndex = _monthNames.indexOf(_selectedMonth);
    return _allPhotos.where((p) => p.createDateTime.month == monthIndex).toList();
  }

  void _toggleSelection(AssetEntity asset) {
    setState(() {
      if (_selectedIds.contains(asset.id)) {
        _selectedIds.remove(asset.id);
        _selectedPhotos.removeWhere((p) => p.id == asset.id);
      } else {
        _selectedIds.add(asset.id);
        _selectedPhotos.add(asset);
      }
    });
  }

  void _selectAll() {
    final filtered = _getFilteredPhotos();
    setState(() {
      for (var photo in filtered) {
        if (!_selectedIds.contains(photo.id)) {
          _selectedIds.add(photo.id);
          _selectedPhotos.add(photo);
        }
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedIds.clear();
      _selectedPhotos.clear();
    });
  }

  void _generateVideo() {
    if (_selectedPhotos.isEmpty) {
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

    // Sort selected photos by date
    _selectedPhotos.sort((a, b) => a.createDateTime.compareTo(b.createDateTime));
    
    setState(() {
      _isGenerating = true;
      _currentPhotoIndex = 0;
    });

    _loadCurrentImage();
    _startSlideshow();
  }

  void _startSlideshow() {
    _slideTimer?.cancel();
    setState(() => _isPlaying = true);
    
    _slideTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      _nextSlide();
    });
  }

  void _nextSlide() {
    if (_selectedPhotos.isEmpty) return;

    setState(() {
      _currentPhotoIndex++;
      if (_currentPhotoIndex >= _selectedPhotos.length) {
        _currentPhotoIndex = 0;
      }
    });
    
    _loadCurrentImage();
  }

  void _previousSlide() {
    if (_selectedPhotos.isEmpty) return;

    setState(() {
      _currentPhotoIndex--;
      if (_currentPhotoIndex < 0) {
        _currentPhotoIndex = _selectedPhotos.length - 1;
      }
    });
    
    _loadCurrentImage();
  }

  Future<void> _loadCurrentImage() async {
    if (_selectedPhotos.isEmpty || _currentPhotoIndex >= _selectedPhotos.length) return;
    
    _fadeController.reset();
    _zoomController.reset();
    
    final asset = _selectedPhotos[_currentPhotoIndex];
    final data = await asset.thumbnailDataWithSize(
      const ThumbnailSize(1080, 1920),
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

  void _exitVideoMode() {
    _slideTimer?.cancel();
    setState(() {
      _isGenerating = false;
      _isPlaying = false;
      _currentImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_isGenerating) {
      return _buildVideoPlayer();
    }

    return _buildSelectionScreen();
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Color(0xFFFFD700)),
              ),
              SizedBox(height: 24),
              Text('Loading photos...', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionScreen() {
    final filteredPhotos = _getFilteredPhotos();
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const BeautifulBackButton(),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Select Photos',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Selection count badge
                    if (_selectedPhotos.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_selectedPhotos.length} selected',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              // Month filter chips
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _monthNames.length,
                  itemBuilder: (context, index) {
                    final month = _monthNames[index];
                    final isSelected = _selectedMonth == month;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(month),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() => _selectedMonth = month);
                        },
                        backgroundColor: Colors.white12,
                        selectedColor: const Color(0xFFFFD700),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        checkmarkColor: Colors.black,
                      ),
                    );
                  },
                ),
              ),
              
              // Selection buttons
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _selectAll,
                        icon: const Icon(Icons.select_all, size: 18),
                        label: const Text('Select All'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white38),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _clearSelection,
                        icon: const Icon(Icons.clear_all, size: 18),
                        label: const Text('Clear'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white38),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Photo Grid
              Expanded(
                child: filteredPhotos.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.photo_library_outlined, size: 64, color: Colors.white.withValues(alpha: 0.3)),
                            const SizedBox(height: 16),
                            Text('No photos found', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                        ),
                        itemCount: filteredPhotos.length,
                        itemBuilder: (context, index) {
                          final photo = filteredPhotos[index];
                          final isSelected = _selectedIds.contains(photo.id);
                          
                          return _PhotoTile(
                            asset: photo,
                            isSelected: isSelected,
                            selectionIndex: isSelected 
                                ? _selectedPhotos.indexWhere((p) => p.id == photo.id) + 1 
                                : null,
                            onTap: () => _toggleSelection(photo),
                          );
                        },
                      ),
              ),
              
              // Generate Button
              if (_selectedPhotos.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _generateVideo,
                      icon: const Icon(Icons.play_circle_filled, size: 28),
                      label: Text(
                        'Generate Video (${_selectedPhotos.length} photos)',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD700),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
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
                  Colors.black.withValues(alpha: 0.4),
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
                  // Back/Exit Button
                  GestureDetector(
                    onTap: () {
                      _stopMusic();
                      _exitVideoMode();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.close, color: Colors.white),
                    ),
                  ),
                  const Spacer(),
                  // Photo counter
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentPhotoIndex + 1} / ${_selectedPhotos.length}',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom Controls
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Column(
                children: [
                  // Date info
                  if (_selectedPhotos.isNotEmpty && _currentPhotoIndex < _selectedPhotos.length)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        _formatDate(_selectedPhotos[_currentPhotoIndex].createDateTime),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(color: Colors.black54, blurRadius: 10)],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  
                  // Progress bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (_currentPhotoIndex + 1) / _selectedPhotos.length,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation(Color(0xFFFFD700)),
                        minHeight: 4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Controls with Music & Save
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Music Button
                        _buildControlButton(
                          icon: _selectedSongIndex > 0 ? Icons.music_note : Icons.music_off,
                          onTap: _showSongSelector,
                          isActive: _selectedSongIndex > 0,
                        ),
                        // Previous
                        _buildControlButton(
                          icon: Icons.skip_previous,
                          onTap: _previousSlide,
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
                        // Save Button
                        _buildControlButton(
                          icon: _isSaving ? Icons.hourglass_top : Icons.save_alt,
                          onTap: _isSaving ? null : _saveCurrentPhoto,
                          onLongPress: _isSaving ? null : _saveAllPhotosToGallery,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
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

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
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

class _PhotoTile extends StatefulWidget {
  final AssetEntity asset;
  final bool isSelected;
  final int? selectionIndex;
  final VoidCallback onTap;

  const _PhotoTile({
    required this.asset,
    required this.isSelected,
    required this.onTap,
    this.selectionIndex,
  });

  @override
  State<_PhotoTile> createState() => _PhotoTileState();
}

class _PhotoTileState extends State<_PhotoTile> {
  Uint8List? _thumbnail;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    final data = await widget.asset.thumbnailDataWithSize(
      const ThumbnailSize(300, 300),
      quality: 80,
    );
    if (mounted) {
      setState(() => _thumbnail = data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _thumbnail != null
                ? Image.memory(_thumbnail!, fit: BoxFit.cover)
                : Container(
                    color: Colors.grey[800],
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
          ),
          
          // Selection overlay
          if (widget.isSelected)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFD700), width: 3),
                color: Colors.black.withValues(alpha: 0.3),
              ),
            ),
          
          // Selection badge
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: widget.isSelected ? const Color(0xFFFFD700) : Colors.black45,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: widget.isSelected && widget.selectionIndex != null
                  ? Center(
                      child: Text(
                        '${widget.selectionIndex}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : const Icon(Icons.check, color: Colors.white, size: 16),
            ),
          ),
        ],
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
