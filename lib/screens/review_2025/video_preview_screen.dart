import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

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
  
  // Animation Controllers for Professional Effects
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late AnimationController _kenBurnsController;
  late AnimationController _glowController;
  late AnimationController _particleController;
  late AnimationController _slideController;
  late AnimationController _rotateController;
  late AnimationController _blurController;
  
  late Animation<double> _fadeAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _particleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _blurAnimation;
  // Unused animations removed for cleaner code
  
  List<String> _imagePaths = [];
  
  // Professional visual effect settings
  final List<_ParticleData> _particles = [];
  final math.Random _random = math.Random();
  
  // Transition type for variety
  int _transitionType = 0;
  final int _totalTransitions = 6;
  
  // Style-specific effect config
  late Map<String, dynamic> _currentEffectConfig;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeEffects();
    _loadImages();
    
    Future.delayed(const Duration(milliseconds: 500), () {
      _startPreview();
    });
  }

  void _initializeAnimations() {
    // Scale animation controller (kept for compatibility, no zoom)
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    );
    
    // Fade animation for smooth transitions
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutQuart),
    );
    
    // Ken Burns controller (kept for compatibility, no pan)
    _kenBurnsController = AnimationController(
      duration: const Duration(milliseconds: 5000),
      vsync: this,
    );
    
    // Glow pulse animation
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    
    // Particle animation
    _particleController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
    _particleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_particleController);
    
    // NEW: Slide animation for slide transitions
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    
    // Rotate controller (kept for compatibility)
    _rotateController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    // NEW: Blur animation for dream-like transitions
    _blurController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _blurAnimation = Tween<double>(begin: 5.0, end: 0.0).animate(
      CurvedAnimation(parent: _blurController, curve: Curves.easeOut),
    );
  }

  void _initializeEffects() {
    // Generate particles based on style
    final styleName = widget.video.style.toString().split('.').last;
    _currentEffectConfig = _getStyleEffectConfig(styleName);
    
    // Generate floating particles
    for (int i = 0; i < 30; i++) {
      _particles.add(_ParticleData(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: 2 + _random.nextDouble() * 6,
        speed: 0.2 + _random.nextDouble() * 0.5,
        opacity: 0.3 + _random.nextDouble() * 0.4,
      ));
    }
  }

  Map<String, dynamic> _getStyleEffectConfig(String styleName) {
    switch (styleName.toLowerCase()) {
      case 'cinematic':
        return {
          'overlayColor': Colors.black.withValues(alpha: 0.2),
          'glowColor': const Color(0xFF8E2DE2),
          'particleColor': Colors.white,
          'vignetteIntensity': 0.4,
          'filmGrain': false,
          'letterbox': true,
        };
      case 'epic':
        return {
          'overlayColor': Colors.deepOrange.withValues(alpha: 0.15),
          'glowColor': const Color(0xFFFF6B6B),
          'particleColor': Colors.orange,
          'vignetteIntensity': 0.5,
          'filmGrain': false,
          'letterbox': true,
        };
      case 'romantic':
        return {
          'overlayColor': Colors.pink.withValues(alpha: 0.1),
          'glowColor': const Color(0xFFFF6B8A),
          'particleColor': Colors.pink.shade200,
          'vignetteIntensity': 0.3,
          'filmGrain': false,
          'letterbox': false,
        };
      case 'vintage':
        return {
          'overlayColor': const Color(0xFFD4A574).withValues(alpha: 0.2),
          'glowColor': const Color(0xFFB8860B),
          'particleColor': const Color(0xFFF5DEB3),
          'vignetteIntensity': 0.5,
          'filmGrain': true,
          'letterbox': false,
        };
      case 'neon':
        return {
          'overlayColor': Colors.purple.withValues(alpha: 0.15),
          'glowColor': const Color(0xFF00F5FF),
          'particleColor': const Color(0xFFFF00FF),
          'vignetteIntensity': 0.3,
          'filmGrain': false,
          'letterbox': false,
        };
      case 'party':
        return {
          'overlayColor': Colors.transparent,
          'glowColor': const Color(0xFFFFD700),
          'particleColor': Colors.yellow,
          'vignetteIntensity': 0.2,
          'filmGrain': false,
          'letterbox': false,
        };
      // NEW 5 STYLES
      case 'wedding':
        return {
          'overlayColor': Colors.white.withValues(alpha: 0.1),
          'glowColor': const Color(0xFFF8BBD9),
          'particleColor': Colors.white,
          'vignetteIntensity': 0.25,
          'filmGrain': false,
          'letterbox': false,
        };
      case 'birthday':
        return {
          'overlayColor': Colors.pink.withValues(alpha: 0.1),
          'glowColor': const Color(0xFFFF4081),
          'particleColor': Colors.yellow,
          'vignetteIntensity': 0.2,
          'filmGrain': false,
          'letterbox': false,
        };
      case 'family':
        return {
          'overlayColor': Colors.brown.withValues(alpha: 0.1),
          'glowColor': const Color(0xFF795548),
          'particleColor': const Color(0xFFD7CCC8),
          'vignetteIntensity': 0.35,
          'filmGrain': false,
          'letterbox': false,
        };
      case 'dosti':
        return {
          'overlayColor': Colors.cyan.withValues(alpha: 0.1),
          'glowColor': const Color(0xFF00BCD4),
          'particleColor': Colors.lightBlue,
          'vignetteIntensity': 0.2,
          'filmGrain': false,
          'letterbox': false,
        };
      case 'islamic':
        return {
          'overlayColor': Colors.green.withValues(alpha: 0.1),
          'glowColor': const Color(0xFF4CAF50),
          'particleColor': const Color(0xFFC8E6C9),
          'vignetteIntensity': 0.3,
          'filmGrain': false,
          'letterbox': false,
        };
      default:
        return {
          'overlayColor': Colors.black.withValues(alpha: 0.15),
          'glowColor': const Color(0xFF667EEA),
          'particleColor': Colors.white,
          'vignetteIntensity': 0.3,
          'filmGrain': false,
          'letterbox': false,
        };
    }
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
    _fadeController.dispose();
    _kenBurnsController.dispose();
    _glowController.dispose();
    _particleController.dispose();
    _slideController.dispose();
    _rotateController.dispose();
    _blurController.dispose();
    MusicService.stop();
    super.dispose();
  }

  void _startPreview() {
    if (_imagePaths.isEmpty) return;
    
    setState(() => _isPlaying = true);
    
    if (widget.video.backgroundMusic != null) {
      MusicService.play(widget.video.backgroundMusic!);
    }
    
    // Calculate time per image based on duration and number of images
    final msPerImage = (widget.video.durationSeconds * 1000) ~/ _imagePaths.length;
    final timePerImage = Duration(milliseconds: msPerImage.clamp(2000, 6000));
    
    // Start all animations
    _fadeController.forward();
    _scaleController.forward();
    _kenBurnsController.forward();
    
    _slideTimer = Timer.periodic(timePerImage, (timer) {
      if (mounted) {
        _transitionToNextImage();
      }
    });
  }

  void _transitionToNextImage() {
    // Cycle through different transition types for variety
    _transitionType = (_transitionType + 1) % _totalTransitions;
    
    // Reset all animations for smooth transition
    _fadeController.reset();
    _scaleController.reset();
    _kenBurnsController.reset();
    _slideController.reset();
    _rotateController.reset();
    _blurController.reset();
    
    setState(() {
      _currentImageIndex = (_currentImageIndex + 1) % _imagePaths.length;
    });
    
    // Start animations based on transition type
    _fadeController.forward();
    
    switch (_transitionType) {
      case 0: // Ken Burns zoom
        _scaleController.forward();
        _kenBurnsController.forward();
        break;
      case 1: // Slide from right
        _slideController.forward();
        _scaleController.forward();
        break;
      case 2: // Rotate + zoom
        _rotateController.forward();
        _scaleController.forward();
        break;
      case 3: // Blur fade
        _blurController.forward();
        _kenBurnsController.forward();
        break;
      case 4: // Scale + Ken Burns
        _scaleController.forward();
        _kenBurnsController.forward();
        break;
      case 5: // All combined
        _scaleController.forward();
        _slideController.forward();
        break;
    }
  }

  void _pausePreview() {
    _slideTimer?.cancel();
    _slideTimer = null;
    MusicService.pause();
    _scaleController.stop();
    _kenBurnsController.stop();
    setState(() => _isPlaying = false);
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _pausePreview();
    } else {
      _startPreview();
    }
  }

  // ========== SAVE VIDEO AS MP4 ==========
  Future<void> _saveDirectly() async {
    if (_isSaving) return;
    
    setState(() {
      _isSaving = true;
      _saveMessage = 'Preparing video...';
    });
    
    _pausePreview();
    
    try {
      // Check if this is a real video (MP4)
      if (widget.video.isRealVideo && widget.video.filePath.endsWith('.mp4')) {
        // Save actual video file
        final result = await VideoGeneratorService.saveVideoToDownloads(
          widget.video,
          onProgress: (progress, status) {
            if (mounted) {
              setState(() {
                _saveMessage = status;
              });
            }
          },
        );
        
        _showSaveResult(result.success, result.message);
        return;
      }
      
      // Fallback: Save as images if not a real video
      final saveDir = await _getDownloadFolder();
      
      if (saveDir == null) {
        _showSaveResult(false, 'Cannot access storage folder');
        return;
      }
      
      if (kDebugMode) {
        debugPrint('Save directory: $saveDir');
      }
      
      int savedCount = 0;
      
      for (int i = 0; i < _imagePaths.length; i++) {
        setState(() {
          _saveMessage = 'Saving ${i + 1}/${_imagePaths.length}...';
        });
        
        final url = _imagePaths[i];
        final fileName = 'memory_${i + 1}.jpg';
        final filePath = '$saveDir/$fileName';
        
        try {
          if (url.startsWith('http')) {
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
      final folderName = 'Memories_2025_$timestamp';
      
      if (Platform.isAndroid) {
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) {
          final basePath = extDir.parent.parent.parent.parent.path;
          
          final downloadPath = '$basePath/Download/$folderName';
          try {
            final dir = Directory(downloadPath);
            await dir.create(recursive: true);
            return downloadPath;
          } catch (e) {
            if (kDebugMode) debugPrint('Download folder failed: $e');
          }
          
          final picturesPath = '$basePath/Pictures/$folderName';
          try {
            final dir = Directory(picturesPath);
            await dir.create(recursive: true);
            return picturesPath;
          } catch (e) {
            if (kDebugMode) debugPrint('Pictures folder failed: $e');
          }
          
          final dcimPath = '$basePath/DCIM/$folderName';
          try {
            final dir = Directory(dcimPath);
            await dir.create(recursive: true);
            return dcimPath;
          } catch (e) {
            if (kDebugMode) debugPrint('DCIM folder failed: $e');
          }
          
          final appPath = '${extDir.path}/$folderName';
          final dir = Directory(appPath);
          await dir.create(recursive: true);
          return appPath;
        }
      }
      
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
        '2025 ki yaadein!\n'
        '${widget.video.photoCount} photos\n'
        'Reflect & Plan app se banaya',
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
    context.watch<AppProvider>();
    final hasLetterbox = _currentEffectConfig['letterbox'] as bool;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Professional Video Preview with Effects
          _buildProfessionalVideoPreview(),
          
          // Letterbox Effect (for cinematic/epic styles)
          if (hasLetterbox) _buildLetterboxEffect(),
          
          // Floating Particles Overlay
          _buildParticleOverlay(),
          
          // Vignette Effect
          _buildVignetteOverlay(),
          
          // Style-specific Color Overlay
          _buildColorOverlay(),
          
          // Gradient Overlay
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

  Widget _buildProfessionalVideoPreview() {
    if (_imagePaths.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return AnimatedBuilder(
      animation: Listenable.merge([
        _fadeAnimation, 
        _slideAnimation,
        _blurAnimation,
      ]),
      builder: (context, child) {
        Widget imageWidget = _buildImage(_imagePaths[_currentImageIndex]);
        
        // Apply subtle blur effect during transitions only
        if (_blurAnimation.value > 0.5) {
          imageWidget = ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: _blurAnimation.value * 0.5,
              sigmaY: _blurAnimation.value * 0.5,
            ),
            child: imageWidget,
          );
        }
        
        // SIMPLIFIED - NO ZOOM, NO PAN - Clear picture visibility
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 900),
          transitionBuilder: (Widget child, Animation<double> animation) {
            // SIMPLE, CLEAN transitions only - pictures perfectly visible
            switch (_transitionType % 3) {
              case 0:
                // Smooth fade transition
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              case 1:
                // Gentle slide from right
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.08, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: FadeTransition(opacity: animation, child: child),
                );
              default:
                // Simple crossfade
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
            }
          },
          child: Container(
            key: ValueKey(_currentImageIndex),
            child: imageWidget,
          ),
        );
      },
    );
  }

  Widget _buildLetterboxEffect() {
    return Column(
      children: [
        Container(
          height: MediaQuery.of(context).size.height * 0.08,
          color: Colors.black,
        ),
        const Spacer(),
        Container(
          height: MediaQuery.of(context).size.height * 0.08,
          color: Colors.black,
        ),
      ],
    );
  }

  Widget _buildParticleOverlay() {
    return AnimatedBuilder(
      animation: _particleAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: _ParticlePainter(
            particles: _particles,
            progress: _particleAnimation.value,
            color: _currentEffectConfig['particleColor'] as Color,
          ),
        );
      },
    );
  }

  Widget _buildVignetteOverlay() {
    final intensity = _currentEffectConfig['vignetteIntensity'] as double;
    
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: intensity * 0.3),
              Colors.black.withValues(alpha: intensity * 0.6),
              Colors.black.withValues(alpha: intensity),
            ],
            stops: const [0.0, 0.5, 0.75, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildColorOverlay() {
    final overlayColor = _currentEffectConfig['overlayColor'] as Color;
    
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  overlayColor.withValues(alpha: _glowAnimation.value * 0.2),
                  Colors.transparent,
                  (_currentEffectConfig['glowColor'] as Color).withValues(alpha: _glowAnimation.value * 0.15),
                ],
              ),
            ),
          );
        },
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
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    (_currentEffectConfig['glowColor'] as Color).withValues(alpha: 0.8),
                    (_currentEffectConfig['glowColor'] as Color).withValues(alpha: 0.6),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
            ),
            const SizedBox(height: 24),
            Text(
              _saveMessage,
              style: const TextStyle(
                color: Colors.white, 
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aapki yaadein save ho rahi hain...',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
            ),
          ],
        ),
      ),
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
            stops: const [0.0, 0.15, 0.7, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final glowColor = _currentEffectConfig['glowColor'] as Color;
    
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
          // Style Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [glowColor, glowColor.withValues(alpha: 0.7)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: glowColor.withValues(alpha: 0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text(
                  widget.video.style.toString().split('.').last.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white, 
                    fontSize: 11, 
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${widget.video.photoCount} photos • ${widget.video.durationSeconds}s',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    final glowColor = _currentEffectConfig['glowColor'] as Color;
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Progress dots with glow
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_imagePaths.length, (index) {
              final isActive = index == _currentImageIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isActive ? 24 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: isActive ? glowColor : Colors.white30,
                  boxShadow: isActive ? [
                    BoxShadow(
                      color: glowColor.withValues(alpha: 0.6),
                      blurRadius: 8,
                    ),
                  ] : null,
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          
          // Image counter
          Text(
            '${_currentImageIndex + 1} / ${_imagePaths.length}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          
          // Music info
          if (widget.video.backgroundMusic != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: glowColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: glowColor.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isPlaying ? Icons.music_note : Icons.music_off,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.video.backgroundMusic!.name,
                        style: const TextStyle(
                          color: Colors.white, 
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        widget.video.backgroundMusic!.artist,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6), 
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  if (_isPlaying) ...[
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [glowColor, glowColor.withValues(alpha: 0.7)]),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.graphic_eq, color: Colors.white, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'PLAYING',
                            style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          
          // Saved indicator
          if (_isSaved)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.withValues(alpha: 0.2), Colors.green.withValues(alpha: 0.1)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    _saveMessage,
                    style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600),
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
                color: glowColor,
              ),
              
              // Play/Pause - Main Button
              GestureDetector(
                onTap: _togglePlayPause,
                child: AnimatedBuilder(
                  animation: _glowAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [glowColor, glowColor.withValues(alpha: 0.7)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: glowColor.withValues(alpha: _glowAnimation.value * 0.8),
                            blurRadius: 25,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 42,
                      ),
                    );
                  },
                ),
              ),
              
              // Save
              _buildButton(
                icon: _isSaved ? Icons.check_rounded : Icons.download_rounded,
                label: _isSaved ? 'Saved!' : 'Save',
                onTap: _isSaving ? null : _saveDirectly,
                isSuccess: _isSaved,
                color: glowColor,
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
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: isSuccess 
                  ? const LinearGradient(colors: [Colors.green, Color(0xFF00C853)])
                  : null,
              color: isSuccess ? null : Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSuccess ? Colors.green : color.withValues(alpha: 0.4),
                width: 2,
              ),
              boxShadow: isSuccess ? [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.4),
                  blurRadius: 12,
                ),
              ] : null,
            ),
            child: Icon(
              icon,
              color: isSuccess ? Colors.white : color,
              size: 26,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isSuccess ? Colors.green : Colors.white,
              fontSize: 12,
              fontWeight: isSuccess ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Particle Data class for floating particles
class _ParticleData {
  double x;
  double y;
  final double size;
  final double speed;
  final double opacity;

  _ParticleData({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

// Custom painter for particle effects
class _ParticlePainter extends CustomPainter {
  final List<_ParticleData> particles;
  final double progress;
  final Color color;

  _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      // Update particle position (floating upward)
      final y = (particle.y + progress * particle.speed) % 1.0;
      final x = particle.x + math.sin(progress * math.pi * 2 + particle.x * 10) * 0.02;
      
      final paint = Paint()
        ..color = color.withValues(alpha: particle.opacity * (1 - y * 0.5))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      
      canvas.drawCircle(
        Offset(x * size.width, (1 - y) * size.height),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
