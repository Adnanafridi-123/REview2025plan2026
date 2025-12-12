import 'package:flutter/material.dart';
import '../../widgets/beautiful_back_button.dart';
import 'auto_memories_screen.dart';
import 'auto_video_memories_screen.dart';
import 'manual_video_screen.dart';
import 'year_wrapped_screen.dart';

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
                    
                    // AUTO-GENERATED MEMORIES SECTION
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome, color: Color(0xFFFFD700), size: 16),
                          SizedBox(width: 6),
                          Text('AUTO-GENERATED', style: TextStyle(color: Color(0xFFFFD700), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // 1. Auto Memories - Facebook-style automatic memories
                    _ReviewCard(
                      emoji: '🎞️',
                      title: 'My 2025 Memories',
                      subtitle: 'Auto-curated from your gallery',
                      gradientColors: const [Color(0xFF667eea), Color(0xFF764ba2)],
                      onTap: () => _navigateTo(context, const AutoMemoriesScreen()),
                    ),
                    
                    // 2. Year Wrapped - Auto-generated Spotify-style
                    _ReviewCard(
                      emoji: '✨',
                      title: '2025 Wrapped',
                      subtitle: 'Your year in review - auto generated',
                      gradientColors: const [Color(0xFFDA22FF), Color(0xFF9733EE)],
                      onTap: () => _navigateTo(context, const YearWrappedScreen()),
                    ),
                    
                    // 3. Auto Video Memories - HD slideshow with music
                    _ReviewCard(
                      emoji: '🎬',
                      title: 'Auto Video',
                      subtitle: 'HD video with music from all photos',
                      gradientColors: const [Color(0xFFFF512F), Color(0xFFDD2476)],
                      onTap: () => _navigateTo(context, const AutoVideoMemoriesScreen()),
                    ),
                    
                    // 4. Manual Video Creation - Select photos manually
                    _ReviewCard(
                      emoji: '✂️',
                      title: 'Create Video',
                      subtitle: 'Select photos & create custom video',
                      gradientColors: const [Color(0xFF11998e), Color(0xFF38ef7d)],
                      onTap: () => _navigateTo(context, const ManualVideoScreen()),
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
