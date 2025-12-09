import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:intl/intl.dart';
import '../../widgets/beautiful_back_button.dart';
import '../../providers/media_cache_provider.dart';
import '../../providers/app_provider.dart';
import 'package:provider/provider.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  final MediaCacheProvider _cache = MediaCacheProvider();
  String _selectedFilter = 'All';
  int? _expandedMonth;
  bool _isLoading = true;
  bool _hasPermission = false;

  // Month wise data
  Map<int, List<AssetEntity>> _photosByMonth = {};
  Map<int, List<AssetEntity>> _videosByMonth = {};
  int _totalPhotos = 0;
  int _totalVideos = 0;

  @override
  void initState() {
    super.initState();
    _loadMediaFromGallery();
  }

  Future<void> _loadMediaFromGallery() async {
    setState(() => _isLoading = true);

    try {
      final permission = await PhotoManager.requestPermissionExtend();
      
      if (permission.isAuth) {
        _hasPermission = true;
        
        // Load photos aur videos
        await _cache.loadPhotos();
        await _cache.loadVideos();
        
        // Month wise organize karo
        _organizeByMonth();
      } else {
        _hasPermission = false;
      }
    } catch (e) {
      debugPrint('Error loading media: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _organizeByMonth() {
    _photosByMonth = {};
    _videosByMonth = {};
    _totalPhotos = 0;
    _totalVideos = 0;

    // Photos ko month wise organize karo
    final allPhotos = _cache.getAllPhotosFlat();
    for (var photo in allPhotos) {
      final month = photo.createDateTime.month;
      _photosByMonth[month] ??= [];
      _photosByMonth[month]!.add(photo);
      _totalPhotos++;
    }

    // Videos ko month wise organize karo
    final allVideos = _cache.getAllVideosFlat();
    for (var video in allVideos) {
      final month = video.createDateTime.month;
      _videosByMonth[month] ??= [];
      _videosByMonth[month]!.add(video);
      _totalVideos++;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF0F5), Color(0xFFFFE4E1)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: Color(0xFF8C52FF)),
                            SizedBox(height: 16),
                            Text(
                              'Loading 2025 memories...',
                              style: TextStyle(color: Color(0xFF666666)),
                            ),
                          ],
                        ),
                      )
                    : !_hasPermission
                        ? _buildPermissionRequest()
                        : RefreshIndicator(
                            onRefresh: _loadMediaFromGallery,
                            color: const Color(0xFF8C52FF),
                            child: _buildContent(),
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
          const LightBackButton(),
          const Spacer(),
          IconButton(
            onPressed: _loadMediaFromGallery,
            icon: const Icon(Icons.refresh, color: Color(0xFF8C52FF)),
          ),
        ],
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
                color: const Color(0xFF8C52FF).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Text('📅', style: TextStyle(fontSize: 48)),
            ),
            const SizedBox(height: 24),
            const Text(
              'Gallery Permission Required',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Apni 2025 ki photos aur videos dekhne ke liye gallery permission dein',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadMediaFromGallery,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8C52FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final appProvider = context.watch<AppProvider>();
    
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      children: [
        // Header
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF598BFF).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('📅', style: TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Timeline 2025',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                Text(
                  'Apka 2025 ka safar month by month',
                  style: TextStyle(fontSize: 13, color: Color(0xFF888888)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        // Summary Stats
        _buildSummaryStats(appProvider),
        const SizedBox(height: 16),
        
        // Filter Tabs
        _buildFilterTabs(),
        const SizedBox(height: 16),
        
        // Month Cards (December se January tak)
        ...List.generate(12, (index) {
          final month = 12 - index;
          return _buildMonthCard(context, appProvider, month);
        }),
      ],
    );
  }

  Widget _buildSummaryStats(AppProvider provider) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            emoji: '📷',
            count: _totalPhotos,
            label: 'Photos',
            color: const Color(0xFFFF5E62),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            emoji: '🎬',
            count: _totalVideos,
            label: 'Videos',
            color: const Color(0xFF00C9FF),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            emoji: '📝',
            count: provider.totalJournals,
            label: 'Journals',
            color: const Color(0xFFFC6767),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterTabs() {
    final filters = ['All', 'Photos', 'Videos', 'Journals'];
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = filter),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF8C52FF) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                filter,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF666666),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMonthCard(BuildContext context, AppProvider provider, int month) {
    final monthName = DateFormat('MMMM').format(DateTime(2025, month));
    final isExpanded = _expandedMonth == month;
    
    // Get counts for this month
    final photos = _photosByMonth[month] ?? [];
    final videos = _videosByMonth[month] ?? [];
    final journals = provider.journals2025.where((j) => j.date.month == month).toList();
    
    final photoCount = photos.length;
    final videoCount = videos.length;
    final journalCount = journals.length;
    
    // Filter ke mutabiq check karo
    bool showThisMonth = false;
    if (_selectedFilter == 'All') {
      showThisMonth = photoCount > 0 || videoCount > 0 || journalCount > 0;
    } else if (_selectedFilter == 'Photos') {
      showThisMonth = photoCount > 0;
    } else if (_selectedFilter == 'Videos') {
      showThisMonth = videoCount > 0;
    } else if (_selectedFilter == 'Journals') {
      showThisMonth = journalCount > 0;
    }
    
    final hasContent = photoCount > 0 || videoCount > 0 || journalCount > 0;
    
    // Agar filter match nahi karta to hide karo
    if (_selectedFilter != 'All' && !showThisMonth) {
      return const SizedBox.shrink();
    }
    
    return Column(
      children: [
        GestureDetector(
          onTap: hasContent ? () {
            setState(() {
              _expandedMonth = isExpanded ? null : month;
            });
          } : null,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Month Number Box
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: hasContent 
                        ? const Color(0xFF8C52FF).withValues(alpha: 0.1)
                        : const Color(0xFFEEEEEE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      month.toString().padLeft(2, '0'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: hasContent ? const Color(0xFF8C52FF) : const Color(0xFF999999),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Month Name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        monthName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: hasContent ? const Color(0xFF333333) : const Color(0xFF999999),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Data Pills
                      Row(
                        children: [
                          if (photoCount > 0 && (_selectedFilter == 'All' || _selectedFilter == 'Photos'))
                            _DataPill(count: photoCount, emoji: '📷', color: const Color(0xFFFF5E62)),
                          if (videoCount > 0 && (_selectedFilter == 'All' || _selectedFilter == 'Videos'))
                            _DataPill(count: videoCount, emoji: '🎬', color: const Color(0xFF00C9FF)),
                          if (journalCount > 0 && (_selectedFilter == 'All' || _selectedFilter == 'Journals'))
                            _DataPill(count: journalCount, emoji: '📝', color: const Color(0xFFFC6767)),
                          if (!hasContent)
                            Text(
                              'Koi entry nahi',
                              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Expand Arrow
                if (hasContent)
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: const Color(0xFF8C52FF),
                  ),
              ],
            ),
          ),
        ),
        
        // Expanded Content
        if (isExpanded && hasContent)
          _buildExpandedContent(context, provider, month, photos, videos, journals),
      ],
    );
  }

  Widget _buildExpandedContent(
    BuildContext context, 
    AppProvider provider, 
    int month,
    List<AssetEntity> photos,
    List<AssetEntity> videos,
    List journals,
  ) {
    final monthName = DateFormat('MMMM').format(DateTime(2025, month));
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$monthName 2025 ki Memories',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 12),
          
          // Photos Section
          if (photos.isNotEmpty && (_selectedFilter == 'All' || _selectedFilter == 'Photos')) ...[
            Row(
              children: [
                const Text('📷', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  'Photos (${photos.length})',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFF5E62),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: photos.length > 10 ? 10 : photos.length,
                itemBuilder: (context, index) {
                  final photo = photos[index];
                  return FutureBuilder<Uint8List?>(
                    future: photo.thumbnailDataWithSize(const ThumbnailSize(200, 200)),
                    builder: (context, snapshot) {
                      return Container(
                        width: 90,
                        height: 90,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F0F0),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: snapshot.hasData && snapshot.data != null
                              ? Image.memory(snapshot.data!, fit: BoxFit.cover)
                              : const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFFFF5E62),
                                  ),
                                ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            if (photos.length > 10)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '+${photos.length - 10} aur photos',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
            const SizedBox(height: 16),
          ],
          
          // Videos Section
          if (videos.isNotEmpty && (_selectedFilter == 'All' || _selectedFilter == 'Videos')) ...[
            Row(
              children: [
                const Text('🎬', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  'Videos (${videos.length})',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF00C9FF),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: videos.length > 10 ? 10 : videos.length,
                itemBuilder: (context, index) {
                  final video = videos[index];
                  return FutureBuilder<Uint8List?>(
                    future: video.thumbnailDataWithSize(const ThumbnailSize(200, 200)),
                    builder: (context, snapshot) {
                      return Container(
                        width: 90,
                        height: 90,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F0F0),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              snapshot.hasData && snapshot.data != null
                                  ? Image.memory(snapshot.data!, fit: BoxFit.cover)
                                  : const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF00C9FF),
                                      ),
                                    ),
                              // Play icon overlay
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                              // Duration badge
                              Positioned(
                                bottom: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _formatDuration(video.duration),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            if (videos.length > 10)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '+${videos.length - 10} aur videos',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
            const SizedBox(height: 16),
          ],
          
          // Journals Section
          if (journals.isNotEmpty && (_selectedFilter == 'All' || _selectedFilter == 'Journals')) ...[
            Row(
              children: [
                const Text('📝', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  'Journals (${journals.length})',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFC6767),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...journals.take(3).map((journal) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFC6767).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFC6767).withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          journal.mood,
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('d MMM').format(journal.date),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      journal.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            }),
            if (journals.length > 3)
              Text(
                '+${journals.length - 3} aur journals',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
          ],
          
          // No content message
          if (photos.isEmpty && videos.isEmpty && journals.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Is month mein koi memory nahi hai',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

// Stat Card Widget
class _StatCard extends StatelessWidget {
  final String emoji;
  final int count;
  final String label;
  final Color color;

  const _StatCard({
    required this.emoji,
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 6),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF888888)),
          ),
        ],
      ),
    );
  }
}

// Data Pill Widget - Updated with emoji
class _DataPill extends StatelessWidget {
  final int count;
  final String emoji;
  final Color color;

  const _DataPill({required this.count, required this.emoji, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 3),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
