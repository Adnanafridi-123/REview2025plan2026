import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../providers/app_provider.dart';
import '../../services/video_generator_service.dart';
import '../../services/music_service.dart';
import '../../widgets/beautiful_back_button.dart';

class VideoPreviewScreen extends StatefulWidget {
  final GeneratedVideo video;
  
  const VideoPreviewScreen({
    super.key,
    required this.video,
  });

  @override
  State<VideoPreviewScreen> createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends State<VideoPreviewScreen> 
    with TickerProviderStateMixin {
  
  bool _isPlaying = false;
  bool _isSaving = false;
  bool _isSaved = false;
  String _saveMessage = '';
  int _currentImageIndex = 0;
  Timer? _slideTimer;
  
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  
  List<String> _imagePaths = [];
  
  @override
  void initState() {
    super.initState();
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
    
    _loadImages();
    
    Future.delayed(const Duration(milliseconds: 500), () {
      _startPreview();
    });
  }

  void _loadImages() {
    _imagePaths = widget.video.imagePaths;
    if (_imagePaths.isEmpty) {
      _imagePaths = [
        'https://picsum.photos/800/600?random=1',
        'https://picsum.photos/800/600?random=2',
        'https://picsum.photos/800/600?random=3',
        'https://picsum.photos/800/600?random=4',
      ];
    }
  }

  @override
  void dispose() {
    _slideTimer?.cancel();
    _scaleController.dispose();
    MusicService.stop();
    super.dispose();
  }

  void _startPreview() {
    if (_imagePaths.isEmpty) return;
    
    setState(() => _isPlaying = true);
    
    if (widget.video.backgroundMusic != null) {
      MusicService.play(widget.video.backgroundMusic!);
    }
    
    final msPerImage = (widget.video.durationSeconds * 1000) ~/ _imagePaths.length;
    final timePerImage = Duration(milliseconds: msPerImage.clamp(1500, 5000));
    
    _slideTimer = Timer.periodic(timePerImage, (timer) {
      if (mounted) {
        setState(() {
          _currentImageIndex = (_currentImageIndex + 1) % _imagePaths.length;
        });
        _scaleController.forward().then((_) => _scaleController.reverse());
      }
    });
    
    _scaleController.forward();
  }

  void _pausePreview() {
    _slideTimer?.cancel();
    _slideTimer = null;
    MusicService.pause();
    setState(() => _isPlaying = false);
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _pausePreview();
    } else {
      _startPreview();
    }
  }

  // ========== DIRECT SAVE FUNCTION ==========
  Future<void> _saveDirectly() async {
    if (_isSaving) return;
    
    setState(() {
      _isSaving = true;
      _saveMessage = 'Saving...';
    });
    
    _pausePreview();
    
    try {
      // Get save directory
      final saveDir = await _getDownloadFolder();
      
      if (saveDir == null) {
        _showSaveResult(false, 'Cannot access storage folder');
        return;
      }
      
      if (kDebugMode) {
        debugPrint('Save directory: $saveDir');
      }
      
      int savedCount = 0;
      
      // Save each image
      for (int i = 0; i < _imagePaths.length; i++) {
        setState(() {
          _saveMessage = 'Saving ${i + 1}/${_imagePaths.length}...';
        });
        
        final url = _imagePaths[i];
        final fileName = 'memory_${i + 1}.jpg';
        final filePath = '$saveDir/$fileName';
        
        try {
          if (url.startsWith('http')) {
            // Download network image
            final response = await http.get(Uri.parse(url)).timeout(
              const Duration(seconds: 20),
            );
            
            if (response.statusCode == 200) {
              final file = File(filePath);
              await file.writeAsBytes(response.bodyBytes);
              savedCount++;
              if (kDebugMode) {
                debugPrint('Saved: $fileName (${response.bodyBytes.length} bytes)');
              }
            }
          } else {
            // Copy local file
            final sourceFile = File(url);
            if (await sourceFile.exists()) {
              await sourceFile.copy(filePath);
              savedCount++;
            }
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Error saving $fileName: $e');
          }
        }
      }
      
      // Show result
      if (savedCount > 0) {
        _showSaveResult(true, 'Saved $savedCount images to Downloads');
      } else {
        _showSaveResult(false, 'Failed to save images');
      }
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Save error: $e');
      }
      _showSaveResult(false, 'Error: $e');
    }
  }
  
  Future<String?> _getDownloadFolder() async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final folderName = 'Memories_$timestamp';
      
      if (Platform.isAndroid) {
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) {
          final basePath = extDir.parent.parent.parent.parent.path;
          
          // Try Download folder first
          final downloadPath = '$basePath/Download/$folderName';
          try {
            final dir = Directory(downloadPath);
            await dir.create(recursive: true);
            return downloadPath;
          } catch (e) {
            if (kDebugMode) debugPrint('Download folder failed: $e');
          }
          
          // Try Pictures folder
          final picturesPath = '$basePath/Pictures/$folderName';
          try {
            final dir = Directory(picturesPath);
            await dir.create(recursive: true);
            return picturesPath;
          } catch (e) {
            if (kDebugMode) debugPrint('Pictures folder failed: $e');
          }
          
          // Try DCIM folder
          final dcimPath = '$basePath/DCIM/$folderName';
          try {
            final dir = Directory(dcimPath);
            await dir.create(recursive: true);
            return dcimPath;
          } catch (e) {
            if (kDebugMode) debugPrint('DCIM folder failed: $e');
          }
          
          // Use app external storage
          final appPath = '${extDir.path}/$folderName';
          final dir = Directory(appPath);
          await dir.create(recursive: true);
          return appPath;
        }
      }
      
      // Fallback to app documents
      final appDir = await getApplicationDocumentsDirectory();
      final fallbackPath = '${appDir.path}/$folderName';
      final dir = Directory(fallbackPath);
      await dir.create(recursive: true);
      return fallbackPath;
      
    } catch (e) {
      if (kDebugMode) debugPrint('Get folder error: $e');
      return null;
    }
  }
  
  void _showSaveResult(bool success, String message) {
    if (!mounted) return;
    
    setState(() {
      _isSaving = false;
      _isSaved = success;
      _saveMessage = message;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _shareVideo() async {
    try {
      await Share.share(
        'Check out my 2025 memories!\n'
        '${widget.video.photoCount} photos\n'
        'Created with Reflect & Plan app',
        subject: 'My 2025 Memories',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AppProvider>(); // Watch for theme changes
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video Preview
          _buildVideoPreview(),
          
          // Gradient
          _buildGradientOverlay(),
          
          // Saving overlay
          if (_isSaving) _buildSavingOverlay(),
          
          // Controls
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(context),
                const Spacer(),
                _buildBottomControls(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingOverlay() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 20),
            Text(
              _saveMessage,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPreview() {
    if (_imagePaths.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 800),
            child: _buildImage(_imagePaths[_currentImageIndex]),
          ),
        );
      },
    );
  }

  Widget _buildImage(String path) {
    if (path.startsWith('http')) {
      return Image.network(
        path,
        key: ValueKey(path),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            color: Colors.grey[900],
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white54),
            ),
          );
        },
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      );
    } else {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(
          file,
          key: ValueKey(path),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        );
      }
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[900],
      child: const Center(
        child: Icon(Icons.image, color: Colors.white24, size: 80),
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.5),
              Colors.transparent,
              Colors.transparent,
              Colors.black.withValues(alpha: 0.8),
            ],
            stops: const [0.0, 0.2, 0.7, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          BeautifulBackButton(
            isDarkMode: true,
            onTap: () {
              _pausePreview();
              Navigator.pop(context);
            },
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${widget.video.photoCount} photos • ${widget.video.durationSeconds}s',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Progress dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_imagePaths.length, (index) {
              return Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == _currentImageIndex 
                      ? Colors.white 
                      : Colors.white30,
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          
          // Music info
          if (widget.video.backgroundMusic != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.music_note, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    widget.video.backgroundMusic!.name,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  if (_isPlaying) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'PLAYING',
                        style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          
          // Saved indicator
          if (_isSaved)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    _saveMessage,
                    style: const TextStyle(color: Colors.green, fontSize: 12),
                  ),
                ],
              ),
            ),
          
          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Share
              _buildButton(
                icon: Icons.share,
                label: 'Share',
                onTap: _shareVideo,
              ),
              
              // Play/Pause
              GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8E2DE2).withValues(alpha: 0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 35,
                  ),
                ),
              ),
              
              // SAVE - Direct save button
              _buildButton(
                icon: _isSaved ? Icons.check : Icons.download,
                label: _isSaved ? 'Saved!' : 'Save',
                onTap: _isSaving ? null : _saveDirectly,
                isSuccess: _isSaved,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    bool isSuccess = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isSuccess ? Colors.green.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: isSuccess ? Border.all(color: Colors.green, width: 2) : null,
            ),
            child: Icon(
              icon,
              color: isSuccess ? Colors.green : Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isSuccess ? Colors.green : Colors.white,
              fontSize: 12,
              fontWeight: isSuccess ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
