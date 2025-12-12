import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../widgets/beautiful_back_button.dart';

class YearWrappedScreen extends StatefulWidget {
  const YearWrappedScreen({super.key});

  @override
  State<YearWrappedScreen> createState() => _YearWrappedScreenState();
}

class _YearWrappedScreenState extends State<YearWrappedScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = true;
  
  // Auto-generated stats
  int _totalPhotos = 0;
  int _totalVideos = 0;
  String _topMonth = '';
  int _topMonthCount = 0;
  Map<String, int> _monthlyStats = {};
  List<AssetEntity> _topPhotos = [];
  AssetEntity? _firstMemory;
  AssetEntity? _lastMemory;

  final List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    _loadWrappedData();
  }

  Future<void> _loadWrappedData() async {
    try {
      final permission = await PhotoManager.requestPermissionExtend();
      if (!permission.isAuth) {
        setState(() => _isLoading = false);
        return;
      }

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
        setState(() => _isLoading = false);
        return;
      }

      final count = await albums.first.assetCountAsync;
      final allAssets = await albums.first.getAssetListRange(start: 0, end: count);

      Map<String, int> monthCounts = {};
      int photos = 0, videos = 0;
      AssetEntity? first, last;

      for (final asset in allAssets) {
        final date = asset.createDateTime;
        if (date.year == 2025) {
          final monthKey = _monthNames[date.month - 1];
          monthCounts[monthKey] = (monthCounts[monthKey] ?? 0) + 1;
          
          if (asset.type == AssetType.image) photos++;
          if (asset.type == AssetType.video) videos++;

          if (first == null || date.isBefore(first.createDateTime)) first = asset;
          if (last == null || date.isAfter(last.createDateTime)) last = asset;
        }
      }

      // Find top month
      String topMonth = '';
      int topCount = 0;
      monthCounts.forEach((month, count) {
        if (count > topCount) {
          topMonth = month;
          topCount = count;
        }
      });

      // Get random top photos (first 5)
      final topPhotos = allAssets.where((a) => a.type == AssetType.image).take(5).toList();

      setState(() {
        _totalPhotos = photos;
        _totalVideos = videos;
        _topMonth = topMonth;
        _topMonthCount = topCount;
        _monthlyStats = monthCounts;
        _topPhotos = topPhotos;
        _firstMemory = first;
        _lastMemory = last;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF1a1a2e), Color(0xFF0f3460)])),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFFFFD700))),
                SizedBox(height: 24),
                Text('Generating Your 2025 Wrapped...', style: TextStyle(color: Colors.white70, fontSize: 16)),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (page) => setState(() => _currentPage = page),
            children: [
              _buildIntroSlide(),
              _buildTotalMemoriesSlide(),
              _buildTopMonthSlide(),
              _buildFirstMemorySlide(),
              _buildTopPhotosSlide(),
              _buildFinalSlide(),
            ],
          ),
          // Header
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const BeautifulBackButton(),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(16)),
                    child: Text('${_currentPage + 1}/6', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
          // Page Indicator
          Positioned(
            bottom: 50,
            left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) => Container(
                width: _currentPage == index ? 24 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: _currentPage == index ? Colors.white : Colors.white38,
                  borderRadius: BorderRadius.circular(4),
                ),
              )),
            ),
          ),
          // Navigation Hint
          Positioned(
            bottom: 100,
            left: 0, right: 0,
            child: Center(
              child: Text(
                _currentPage < 5 ? 'Swipe to continue →' : '🎉 Share your Wrapped!',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroSlide() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('✨', style: TextStyle(fontSize: 80)),
            const SizedBox(height: 24),
            const Text('Your', style: TextStyle(color: Colors.white70, fontSize: 24)),
            const Text('2025', style: TextStyle(color: Colors.white, fontSize: 72, fontWeight: FontWeight.bold)),
            const Text('Wrapped', style: TextStyle(color: Color(0xFFFFD700), fontSize: 48, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Text('Automatically generated from\nyour ${_totalPhotos + _totalVideos} memories', 
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalMemoriesSlide() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('You captured', style: TextStyle(color: Colors.white70, fontSize: 24)),
            const SizedBox(height: 16),
            Text('$_totalPhotos', style: const TextStyle(color: Colors.white, fontSize: 96, fontWeight: FontWeight.bold)),
            const Text('Photos', style: TextStyle(color: Colors.white, fontSize: 32)),
            const SizedBox(height: 32),
            const Text('and', style: TextStyle(color: Colors.white70, fontSize: 20)),
            const SizedBox(height: 16),
            Text('$_totalVideos', style: const TextStyle(color: Colors.white, fontSize: 64, fontWeight: FontWeight.bold)),
            const Text('Videos', style: TextStyle(color: Colors.white, fontSize: 24)),
            const SizedBox(height: 32),
            const Text('📸 🎬', style: TextStyle(fontSize: 40)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopMonthSlide() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Your busiest month was', style: TextStyle(color: Colors.white70, fontSize: 20)),
            const SizedBox(height: 24),
            const Text('🔥', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 16),
            Text(_topMonth, style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(24)),
              child: Text('$_topMonthCount memories captured!', style: const TextStyle(color: Colors.white, fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFirstMemorySlide() {
    if (_firstMemory == null) return Container(color: const Color(0xFF1a1a2e));
    
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Color(0xFF24243e), Color(0xFF302b63)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Your first memory of 2025', style: TextStyle(color: Colors.white70, fontSize: 18)),
            const SizedBox(height: 24),
            FutureBuilder<Uint8List?>(
              future: _firstMemory!.thumbnailDataWithSize(const ThumbnailSize(400, 400)),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Container(width: 250, height: 250, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)));
                return Container(
                  width: 250, height: 250,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    image: DecorationImage(image: MemoryImage(snapshot.data!), fit: BoxFit.cover),
                    boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 30, offset: const Offset(0, 15))],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              '${_firstMemory!.createDateTime.day} ${_monthNames[_firstMemory!.createDateTime.month - 1]}',
              style: const TextStyle(color: Color(0xFFFFD700), fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopPhotosSlide() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFFFF512F), Color(0xFFDD2476)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Some of your memories', style: TextStyle(color: Colors.white70, fontSize: 20)),
            const SizedBox(height: 32),
            SizedBox(
              height: 300,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 40),
                itemCount: _topPhotos.length,
                itemBuilder: (context, index) {
                  final asset = _topPhotos[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: FutureBuilder<Uint8List?>(
                      future: asset.thumbnailDataWithSize(const ThumbnailSize(300, 400)),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return Container(width: 180, height: 280, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(16)));
                        return Container(
                          width: 180, height: 280,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            image: DecorationImage(image: MemoryImage(snapshot.data!), fit: BoxFit.cover),
                            boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 15, offset: const Offset(0, 8))],
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
      ),
    );
  }

  Widget _buildFinalSlide() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 80)),
            const SizedBox(height: 24),
            const Text("That's a wrap!", style: TextStyle(color: Colors.black87, fontSize: 36, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text('${_totalPhotos + _totalVideos} memories', style: const TextStyle(color: Colors.black54, fontSize: 20)),
            Text('$_topMonth was your top month', style: const TextStyle(color: Colors.black54, fontSize: 16)),
            const SizedBox(height: 48),
            const Text("Here's to an amazing 2026! 🚀", style: TextStyle(color: Colors.black87, fontSize: 18)),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
