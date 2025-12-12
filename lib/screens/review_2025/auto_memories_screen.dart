import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../widgets/beautiful_back_button.dart';

class AutoMemoriesScreen extends StatefulWidget {
  const AutoMemoriesScreen({super.key});

  @override
  State<AutoMemoriesScreen> createState() => _AutoMemoriesScreenState();
}

class _AutoMemoriesScreenState extends State<AutoMemoriesScreen> {
  bool _isLoading = true;
  Map<String, List<AssetEntity>> _memoriesByMonth = {};
  List<String> _months = [];
  int _totalPhotos = 0;
  int _totalVideos = 0;
  List<AssetEntity> _onThisDayMemories = [];
  String? _errorMessage;

  final List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  final Map<int, Map<String, dynamic>> _monthThemes = {
    1: {'emoji': '❄️', 'color': 0xFF5C6BC0, 'theme': 'New Beginnings'},
    2: {'emoji': '💕', 'color': 0xFFEC407A, 'theme': 'Love & Connection'},
    3: {'emoji': '🌸', 'color': 0xFF66BB6A, 'theme': 'Spring Awakening'},
    4: {'emoji': '🌧️', 'color': 0xFF29B6F6, 'theme': 'April Showers'},
    5: {'emoji': '🌻', 'color': 0xFFFFCA28, 'theme': 'Blooming Days'},
    6: {'emoji': '☀️', 'color': 0xFFFF7043, 'theme': 'Summer Vibes'},
    7: {'emoji': '🏖️', 'color': 0xFF26A69A, 'theme': 'Adventure Time'},
    8: {'emoji': '🌴', 'color': 0xFF4CAF50, 'theme': 'Peak Summer'},
    9: {'emoji': '🍂', 'color': 0xFFFFB300, 'theme': 'Golden Days'},
    10: {'emoji': '🎃', 'color': 0xFFFF5722, 'theme': 'Autumn Magic'},
    11: {'emoji': '🍁', 'color': 0xFF8D6E63, 'theme': 'Gratitude'},
    12: {'emoji': '🎄', 'color': 0xFF42A5F5, 'theme': 'Year End Magic'},
  };

  @override
  void initState() {
    super.initState();
    _loadMemories();
  }

  Future<void> _loadMemories() async {
    setState(() => _isLoading = true);

    try {
      final permission = await PhotoManager.requestPermissionExtend();
      if (!permission.isAuth) {
        setState(() {
          _errorMessage = 'Please grant photo access to see your memories';
          _isLoading = false;
        });
        return;
      }

      // Load ALL media from 2025
      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.common,
        filterOption: FilterOptionGroup(
          createTimeCond: DateTimeCond(
            min: DateTime(2025, 1, 1),
            max: DateTime(2025, 12, 31, 23, 59, 59),
          ),
        ),
      );

      if (albums.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No 2025 memories found';
        });
        return;
      }

      final mainAlbum = albums.first;
      final count = await mainAlbum.assetCountAsync;
      final allAssets = await mainAlbum.getAssetListRange(start: 0, end: count);

      Map<String, List<AssetEntity>> byMonth = {};
      Set<String> seenIds = {};
      int photos = 0, videos = 0;

      for (final asset in allAssets) {
        if (seenIds.contains(asset.id)) continue;
        seenIds.add(asset.id);

        final date = asset.createDateTime;
        if (date.year == 2025) {
          final key = '${_monthNames[date.month - 1]} 2025';
          byMonth.putIfAbsent(key, () => []);
          byMonth[key]!.add(asset);
          
          if (asset.type == AssetType.image) photos++;
          if (asset.type == AssetType.video) videos++;
        }
      }

      // Sort each month's assets by date
      for (final month in byMonth.keys) {
        byMonth[month]!.sort((a, b) => b.createDateTime.compareTo(a.createDateTime));
      }

      // Sort months
      final sortedMonths = byMonth.keys.toList()
        ..sort((a, b) => _getMonthOrder(b).compareTo(_getMonthOrder(a)));

      // Load "On This Day" memories
      await _loadOnThisDay();

      setState(() {
        _memoriesByMonth = byMonth;
        _months = sortedMonths;
        _totalPhotos = photos;
        _totalVideos = videos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading memories: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadOnThisDay() async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(2025, now.month, now.day);
      final todayEnd = DateTime(2025, now.month, now.day, 23, 59, 59);

      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.common,
        filterOption: FilterOptionGroup(
          createTimeCond: DateTimeCond(min: todayStart, max: todayEnd),
        ),
      );

      if (albums.isNotEmpty) {
        final count = await albums.first.assetCountAsync;
        if (count > 0) {
          _onThisDayMemories = await albums.first.getAssetListRange(start: 0, end: count);
        }
      }
    } catch (e) {
      debugPrint('Error loading on this day: $e');
    }
  }

  int _getMonthOrder(String monthKey) {
    for (int i = 0; i < _monthNames.length; i++) {
      if (monthKey.startsWith(_monthNames[i])) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? _buildLoading()
              : _errorMessage != null
                  ? _buildError()
                  : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 60, height: 60,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Color(0xFFFFD700)),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          const Text('Loading your 2025 memories...', style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 8),
          Text('Scanning your photos & videos', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined, size: 80, color: Colors.white.withValues(alpha: 0.3)),
            const SizedBox(height: 24),
            Text(_errorMessage!, style: const TextStyle(color: Colors.white70, fontSize: 16), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadMemories,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD700)),
              icon: const Icon(Icons.refresh, color: Colors.black),
              label: const Text('Try Again', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Header
        SliverToBoxAdapter(child: _buildHeader()),
        
        // Stats Card
        SliverToBoxAdapter(child: _buildStatsCard()),
        
        // On This Day Section (if any)
        if (_onThisDayMemories.isNotEmpty)
          SliverToBoxAdapter(child: _buildOnThisDay()),
        
        // Monthly Memories
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: Row(
              children: [
                const Text('Your 2025 Journey', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text('${_months.length} months', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ),
              ],
            ),
          ),
        ),
        
        // Month Cards
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildMonthCard(_months[index]),
            childCount: _months.length,
          ),
        ),
        
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const BeautifulBackButton(),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your 2025 Memories', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('Automatically curated from your gallery', style: TextStyle(fontSize: 12, color: Colors.white70)),
              ],
            ),
          ),
          IconButton(
            onPressed: _loadMemories,
            icon: const Icon(Icons.refresh, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFF8C00)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFFFFD700).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          const Text('2025 At A Glance', style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('📸', _totalPhotos.toString(), 'Photos'),
              Container(width: 1, height: 40, color: Colors.black26),
              _buildStatItem('🎬', _totalVideos.toString(), 'Videos'),
              Container(width: 1, height: 40, color: Colors.black26),
              _buildStatItem('📅', _months.length.toString(), 'Months'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
      ],
    );
  }

  Widget _buildOnThisDay() {
    final now = DateTime.now();
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                child: const Text('📅', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('On This Day', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('${now.day} ${_monthNames[now.month - 1]} 2025', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              Text('${_onThisDayMemories.length} memories', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _onThisDayMemories.length.clamp(0, 10),
              itemBuilder: (context, index) {
                final asset = _onThisDayMemories[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FutureBuilder<Uint8List?>(
                    future: asset.thumbnailDataWithSize(const ThumbnailSize(150, 150)),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)));
                      return GestureDetector(
                        onTap: () => _showFullImage(asset),
                        child: Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(image: MemoryImage(snapshot.data!), fit: BoxFit.cover),
                          ),
                          child: asset.type == AssetType.video
                              ? Container(
                                  decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(12)),
                                  child: const Icon(Icons.play_circle_fill, color: Colors.white, size: 30),
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthCard(String monthKey) {
    final assets = _memoriesByMonth[monthKey] ?? [];
    final monthIndex = _getMonthOrder(monthKey) + 1;
    final theme = _monthThemes[monthIndex] ?? _monthThemes[1]!;
    final color = Color(theme['color'] as int);
    final photos = assets.where((a) => a.type == AssetType.image).length;
    final videos = assets.where((a) => a.type == AssetType.video).length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Text(theme['emoji'] as String, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(monthKey, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(theme['theme'] as String, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$photos 📸', style: const TextStyle(color: Colors.white, fontSize: 13)),
                    Text('$videos 🎬', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          
          // Photos Grid Preview
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: assets.length.clamp(0, 10),
                itemBuilder: (context, index) {
                  final asset = assets[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FutureBuilder<Uint8List?>(
                      future: asset.thumbnailDataWithSize(const ThumbnailSize(200, 200)),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Container(
                            width: 100, height: 100,
                            decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                          );
                        }
                        return GestureDetector(
                          onTap: () => _showFullImage(asset),
                          child: Container(
                            width: 100, height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(image: MemoryImage(snapshot.data!), fit: BoxFit.cover),
                            ),
                            child: asset.type == AssetType.video
                                ? Container(
                                    decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(12)),
                                    child: const Icon(Icons.play_circle_fill, color: Colors.white, size: 36),
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
          
          // View All Button
          if (assets.length > 10)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: GestureDetector(
                onTap: () => _showMonthGallery(monthKey, assets),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                  child: Center(
                    child: Text('View all ${assets.length} memories →', style: TextStyle(color: color, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showFullImage(AssetEntity asset) async {
    final file = await asset.file;
    if (file == null) return;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(file, fit: BoxFit.contain),
            ),
            Positioned(
              top: 8, right: 8,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMonthGallery(String monthKey, List<AssetEntity> assets) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _MonthGalleryScreen(monthKey: monthKey, assets: assets),
      ),
    );
  }
}

class _MonthGalleryScreen extends StatelessWidget {
  final String monthKey;
  final List<AssetEntity> assets;

  const _MonthGalleryScreen({required this.monthKey, required this.assets});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const BeautifulBackButton(),
                    const SizedBox(width: 16),
                    Text(monthKey, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text('${assets.length} memories', style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 4, mainAxisSpacing: 4),
                  itemCount: assets.length,
                  itemBuilder: (context, index) {
                    final asset = assets[index];
                    return FutureBuilder<Uint8List?>(
                      future: asset.thumbnailDataWithSize(const ThumbnailSize(300, 300)),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return Container(color: Colors.white10);
                        return GestureDetector(
                          onTap: () async {
                            final file = await asset.file;
                            if (file == null) return;
                            showDialog(
                              context: context,
                              builder: (context) => Dialog(
                                backgroundColor: Colors.transparent,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(file, fit: BoxFit.contain),
                                ),
                              ),
                            );
                          },
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.memory(snapshot.data!, fit: BoxFit.cover),
                              if (asset.type == AssetType.video)
                                const Center(child: Icon(Icons.play_circle_fill, color: Colors.white70, size: 32)),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
