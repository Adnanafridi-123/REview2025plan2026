import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../models/media_item.dart';
import '../../services/media_service.dart';

class VideoMemoriesScreen extends StatefulWidget {
  const VideoMemoriesScreen({super.key});

  @override
  State<VideoMemoriesScreen> createState() => _VideoMemoriesScreenState();
}

class _VideoMemoriesScreenState extends State<VideoMemoriesScreen> with SingleTickerProviderStateMixin {
  String _selectedStyle = 'Cinematic';
  String _selectedDuration = '30s';
  String _selectedMusic = 'Uplifting';
  bool _isGenerating = false;
  bool _isGenerated = false;
  int _generationProgress = 0;
  
  // Selected media for video
  List<MediaItem> _selectedMedia = [];
  
  // Animation
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

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
    
    // Auto-select all media
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllMedia();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _loadAllMedia() {
    try {
      final photos = MediaService.getAllPhotos();
      final videos = MediaService.getAllVideos();
      final screenshots = MediaService.getAllScreenshots();
      
      setState(() {
        _selectedMedia = [...photos, ...videos, ...screenshots];
        _selectedMedia.sort((a, b) => a.date.compareTo(b.date));
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading media: $e');
      }
    }
  }

  void _toggleMediaSelection(MediaItem item) {
    setState(() {
      if (_selectedMedia.any((m) => m.id == item.id)) {
        _selectedMedia.removeWhere((m) => m.id == item.id);
      } else {
        _selectedMedia.add(item);
      }
    });
  }

  Future<void> _addMoreMedia() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Add More Media',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.close, color: Colors.grey[600], size: 20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Options
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _AddMediaOption(
                    icon: Icons.photo_library,
                    title: 'From Photo Gallery',
                    subtitle: 'Select photos from your device',
                    color: const Color(0xFF8C52FF),
                    onTap: () async {
                      Navigator.pop(context);
                      final photos = await MediaService.pickMultiplePhotos();
                      if (photos.isNotEmpty) {
                        setState(() {
                          for (var photo in photos) {
                            if (!_selectedMedia.any((m) => m.id == photo.id)) {
                              _selectedMedia.add(photo);
                            }
                          }
                        });
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${photos.length} photos added'),
                              backgroundColor: AppTheme.iconGreen,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  _AddMediaOption(
                    icon: Icons.video_library,
                    title: 'From Video Gallery',
                    subtitle: 'Select videos from your device',
                    color: AppTheme.iconGreen,
                    onTap: () async {
                      Navigator.pop(context);
                      final video = await MediaService.pickVideoFromGallery();
                      if (video != null) {
                        setState(() {
                          if (!_selectedMedia.any((m) => m.id == video.id)) {
                            _selectedMedia.add(video);
                          }
                        });
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Video added'),
                              backgroundColor: AppTheme.iconGreen,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  _AddMediaOption(
                    icon: Icons.screenshot,
                    title: 'From Screenshots',
                    subtitle: 'Select screenshots from your device',
                    color: const Color(0xFFF2994A),
                    onTap: () async {
                      Navigator.pop(context);
                      final screenshot = await MediaService.pickScreenshot();
                      if (screenshot != null) {
                        setState(() {
                          if (!_selectedMedia.any((m) => m.id == screenshot.id)) {
                            _selectedMedia.add(screenshot);
                          }
                        });
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Screenshot added'),
                              backgroundColor: AppTheme.iconGreen,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  _AddMediaOption(
                    icon: Icons.camera_alt,
                    title: 'Take New Photo',
                    subtitle: 'Capture a new photo now',
                    color: const Color(0xFF00C9FF),
                    onTap: () async {
                      Navigator.pop(context);
                      final photo = await MediaService.takePhotoWithCamera();
                      if (photo != null) {
                        setState(() {
                          _selectedMedia.add(photo);
                        });
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Photo captured and added'),
                              backgroundColor: AppTheme.iconGreen,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  _AddMediaOption(
                    icon: Icons.videocam,
                    title: 'Record New Video',
                    subtitle: 'Record a new video now',
                    color: const Color(0xFFFF5E62),
                    onTap: () async {
                      Navigator.pop(context);
                      final video = await MediaService.recordVideo();
                      if (video != null) {
                        setState(() {
                          _selectedMedia.add(video);
                        });
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Video recorded and added'),
                              backgroundColor: AppTheme.iconGreen,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // App Bar
              _buildAppBar(context),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(AppTheme.screenPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      const Text(
                        'Video Memories',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textWhite,
                        ),
                      ),
                      Text(
                        'Create a video from your 2025 moments',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textWhite.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Selected Media Preview
                      _buildMediaPreview(),
                      const SizedBox(height: 24),
                      
                      // Preview Area
                      _buildPreviewArea(),
                      const SizedBox(height: 24),
                      
                      // Style Selection
                      _buildStyleSection(),
                      const SizedBox(height: 20),
                      
                      // Music Selection
                      _buildMusicSection(),
                      const SizedBox(height: 20),
                      
                      // Duration Selection
                      _buildDurationSection(),
                      const SizedBox(height: 28),
                      
                      // Generate Button
                      _buildGenerateButton(),
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

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: AppTheme.textWhite,
                size: 20,
              ),
            ),
          ),
          const Spacer(),
          // Reset button
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedMedia.clear();
                _isGenerated = false;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.refresh, color: Colors.white.withValues(alpha: 0.8), size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Reset',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selected Media',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textWhite,
                  ),
                ),
                Text(
                  '${_selectedMedia.length} items selected',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textWhite.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: _addMoreMedia,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.iconPurple,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add, color: Colors.white, size: 18),
                    SizedBox(width: 4),
                    Text(
                      'Add More',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Media thumbnails
        if (_selectedMedia.isEmpty)
          Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate, 
                  color: Colors.white.withValues(alpha: 0.5), size: 36),
                const SizedBox(height: 8),
                Text(
                  'No media selected. Tap "Add More" to start!',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedMedia.length,
              itemBuilder: (context, index) {
                final item = _selectedMedia[index];
                return GestureDetector(
                  onTap: () => _toggleMediaSelection(item),
                  child: Container(
                    width: 80,
                    height: 80,
                    margin: EdgeInsets.only(right: index < _selectedMedia.length - 1 ? 10 : 0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: kIsWeb
                              ? Container(
                                  color: item.isVideo 
                                      ? AppTheme.iconGreen.withValues(alpha: 0.3)
                                      : AppTheme.iconPurple.withValues(alpha: 0.3),
                                  child: Center(
                                    child: Icon(
                                      item.isVideo ? Icons.videocam : Icons.photo,
                                      color: Colors.white.withValues(alpha: 0.7),
                                      size: 30,
                                    ),
                                  ),
                                )
                              : Image.file(
                                  File(item.thumbnailPath ?? item.path),
                                  fit: BoxFit.cover,
                                  width: 80,
                                  height: 80,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: Colors.grey[800],
                                    child: Icon(
                                      item.isVideo ? Icons.videocam : Icons.photo,
                                      color: Colors.white54,
                                    ),
                                  ),
                                ),
                        ),
                        // Type indicator
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: item.isVideo ? AppTheme.iconGreen : AppTheme.iconPurple,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              item.isVideo ? Icons.videocam : Icons.photo,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                        // Remove button
                        Positioned(
                          top: 2,
                          right: 2,
                          child: GestureDetector(
                            onTap: () => _toggleMediaSelection(item),
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 12),
                            ),
                          ),
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

  Widget _buildPreviewArea() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: AppTheme.videoMemoriesGradient,
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
                : _buildInitialPreviewState(),
      ),
    );
  }

  Widget _buildInitialPreviewState() {
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
          _selectedMedia.isEmpty 
              ? 'Add media to create your video'
              : '${_selectedMedia.length} media items ready',
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
          'Processing ${_selectedMedia.length} media items',
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
          decoration: BoxDecoration(
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

  Widget _buildStyleSection() {
    final styles = [
      {'name': 'Cinematic', 'icon': Icons.movie_filter},
      {'name': 'Slideshow', 'icon': Icons.photo_library},
      {'name': 'Dynamic', 'icon': Icons.speed},
      {'name': 'Highlights', 'icon': Icons.star},
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Video Style',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textWhite,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: styles.map((style) {
              final isSelected = _selectedStyle == style['name'];
              return GestureDetector(
                onTap: () => setState(() => _selectedStyle = style['name'] as String),
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.iconPurple
                        : Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: isSelected
                        ? null
                        : Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(style['icon'] as IconData, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        style['name'] as String,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMusicSection() {
    final musicOptions = ['Uplifting', 'Calm', 'Energetic', 'Nostalgic', 'No Music'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Background Music',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textWhite,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: musicOptions.map((music) {
            final isSelected = _selectedMusic == music;
            return GestureDetector(
              onTap: () => setState(() => _selectedMusic = music),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.iconGreen
                      : Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: isSelected
                      ? null
                      : Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Text(
                  music,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDurationSection() {
    final durations = ['15s', '30s', '60s', '120s'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Video Duration',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textWhite,
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
                  margin: EdgeInsets.only(right: duration != '120s' ? 10 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.iconPurple
                        : Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      duration,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14,
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

  Widget _buildGenerateButton() {
    final canGenerate = _selectedMedia.isNotEmpty && !_isGenerating;
    
    return GestureDetector(
      onTap: canGenerate ? _generateVideo : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: canGenerate 
              ? AppTheme.videoMemoriesGradient
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
                      : 'Generate Video (${_selectedMedia.length} items)',
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
    if (_selectedMedia.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please add some media first'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

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
                      '$_selectedStyle style • $_selectedDuration • $_selectedMusic music',
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

class _AddMediaOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _AddMediaOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 18),
          ],
        ),
      ),
    );
  }
}
