import 'package:flutter/material.dart';
import '../../widgets/beautiful_back_button.dart';
import 'timeline_screen.dart';
import 'photo_gallery_screen.dart';
import 'video_gallery_screen.dart';
import 'journal_screen.dart';
import 'screenshots_screen.dart';
import 'achievements_screen.dart';
import 'statistics_screen.dart';
import 'wrapped_screen.dart';
import 'video_memories_screen.dart';

class ReviewMenuScreen extends StatelessWidget {
  const ReviewMenuScreen({super.key});

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
              // App Bar
              _buildAppBar(context),
              
              // Menu List
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  children: [
                    // Header
                    const Text(
                      'Review 2025',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Look back at your amazing year',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF888888),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // 9 Menu Cards - EXACT from video
                    // 1. Timeline - Blue/Purple gradient
                    _ReviewCard(
                      emoji: '📅',
                      title: 'Timeline',
                      subtitle: 'Your year month by month',
                      gradientColors: const [Color(0xFF598BFF), Color(0xFF8C52FF)],
                      onTap: () => _navigateTo(context, const TimelineScreen()),
                    ),
                    
                    // 2. Photos - Pink/Rose gradient
                    _ReviewCard(
                      emoji: '📷',
                      title: 'Photos',
                      subtitle: 'All your 2025 memories',
                      gradientColors: const [Color(0xFFFF9966), Color(0xFFFF5E62)],
                      onTap: () => _navigateTo(context, const PhotoGalleryScreen()),
                    ),
                    
                    // 3. Videos - Teal/Mint gradient
                    _ReviewCard(
                      emoji: '🎬',
                      title: 'Videos',
                      subtitle: 'Relive your moments',
                      gradientColors: const [Color(0xFF00C9FF), Color(0xFF92FE9D)],
                      onTap: () => _navigateTo(context, const VideoGalleryScreen()),
                    ),
                    
                    // 4. Journal - Hot Pink/Magenta gradient
                    _ReviewCard(
                      emoji: '📝',
                      title: 'Journal',
                      subtitle: 'Your thoughts & moods',
                      gradientColors: const [Color(0xFFEC008C), Color(0xFFFC6767)],
                      onTap: () => _navigateTo(context, const JournalScreen()),
                    ),
                    
                    // 5. Screenshots - Orange gradient
                    _ReviewCard(
                      emoji: '📱',
                      title: 'Screenshots',
                      subtitle: 'Memorable captures',
                      gradientColors: const [Color(0xFFF2994A), Color(0xFFF2C94C)],
                      onTap: () => _navigateTo(context, const ScreenshotsScreen()),
                    ),
                    
                    // 6. Achievements - Gold/Yellow gradient
                    _ReviewCard(
                      emoji: '🏆',
                      title: 'Achievements',
                      subtitle: 'Your 2025 wins',
                      gradientColors: const [Color(0xFFFDC830), Color(0xFFF37335)],
                      onTap: () => _navigateTo(context, const AchievementsScreen()),
                    ),
                    
                    // 7. Statistics - Green gradient
                    _ReviewCard(
                      emoji: '📊',
                      title: 'Statistics',
                      subtitle: 'Your year in numbers',
                      gradientColors: const [Color(0xFF11998E), Color(0xFF38EF7D)],
                      onTap: () => _navigateTo(context, const StatisticsScreen()),
                    ),
                    
                    // 8. Generate Wrapped - Purple/Pink gradient
                    _ReviewCard(
                      emoji: '✨',
                      title: 'Generate Wrapped',
                      subtitle: 'Your 2025 Spotify-style recap',
                      gradientColors: const [Color(0xFFDA22FF), Color(0xFF9733EE)],
                      onTap: () => _navigateTo(context, const WrappedScreen()),
                    ),
                    
                    // 9. Video Memories - Dark Navy gradient
                    _ReviewCard(
                      emoji: '🎥',
                      title: 'Video Memories',
                      subtitle: 'Create 2-min video slideshow',
                      gradientColors: const [Color(0xFF24243E), Color(0xFF302B63)],
                      onTap: () => _navigateTo(context, const VideoMemoriesScreen()),
                    ),
                  ],
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
        ],
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}

// Review Menu Card - EXACT from video
class _ReviewCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _ReviewCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 85,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Emoji Icon Box
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 26)),
                ),
              ),
              const SizedBox(width: 14),
              // Title & Subtitle
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              // Arrow
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
