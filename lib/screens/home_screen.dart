import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_theme.dart';
import '../providers/app_provider.dart';
import '../providers/media_cache_provider.dart';
import 'review_2025/review_menu_screen.dart';
import 'plan_2026/plan_menu_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _realPhotos = 0;
  int _realVideos = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRealMediaCounts();
  }

  Future<void> _loadRealMediaCounts() async {
    try {
      final mediaCache = MediaCacheProvider();
      await mediaCache.loadPhotos();
      await mediaCache.loadVideos();
      
      if (mounted) {
        setState(() {
          _realPhotos = mediaCache.totalPhotos;
          _realVideos = mediaCache.totalVideos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final isDarkMode = provider.isDarkMode;
        
        return Scaffold(
          backgroundColor: isDarkMode ? const Color(0xFF1A1A2E) : AppTheme.bgTop,
          body: Container(
            decoration: BoxDecoration(
              gradient: isDarkMode 
                  ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
                    )
                  : AppTheme.backgroundGradient,
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // ===== FIXED HEADER (Won't Scroll) =====
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Row with subtitle and Dark/Light toggle
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Your 2025',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                            // Dark/Light Mode Toggle
                            GestureDetector(
                              onTap: () => provider.toggleDarkMode(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isDarkMode 
                                      ? const Color(0xFFFFD700).withValues(alpha: 0.2)
                                      : Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isDarkMode 
                                        ? const Color(0xFFFFD700).withValues(alpha: 0.5)
                                        : Colors.white.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isDarkMode ? Icons.light_mode : Icons.dark_mode,
                                      color: isDarkMode ? const Color(0xFFFFD700) : Colors.white,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isDarkMode ? 'Light' : 'Dark',
                                      style: TextStyle(
                                        color: isDarkMode ? const Color(0xFFFFD700) : Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Main Title - FIXED, WON'T SCROLL
                        Text(
                          'Review 2025',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? const Color(0xFFFFD700) : AppTheme.textYellow,
                          ),
                        ),
                        const Text(
                          '& Plan 2026',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Reflect on your memories & plan your future',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // ===== SCROLLABLE CONTENT =====
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Review 2025 Card
                          _buildReview2025Card(context, isDarkMode),
                          const SizedBox(height: 14),
                          
                          // Plan 2026 Card
                          _buildPlan2026Card(context, isDarkMode),
                          const SizedBox(height: 24),
                          
                          // Quick Stats Section - IMPROVED
                          _buildQuickStatsSection(context, isDarkMode, provider),
                          const SizedBox(height: 24),
                          
                          // Activity Summary
                          _buildActivitySummary(isDarkMode, provider),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Review 2025 Card
  Widget _buildReview2025Card(BuildContext context, bool isDarkMode) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ReviewMenuScreen()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: isDarkMode 
              ? const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFFB8405E), Color(0xFFEE6F57)],
                )
              : const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFFE8A0B5), Color(0xFFF5C5D0)],
                ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Text('📸', style: TextStyle(fontSize: 30)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Review 2025',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Explore your memories',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  // Plan 2026 Card
  Widget _buildPlan2026Card(BuildContext context, bool isDarkMode) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PlanMenuScreen()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: isDarkMode 
              ? const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFF00917C), Color(0xFF00C9A7)],
                )
              : const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFF4ECDC4), Color(0xFF7BDDC8)],
                ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Text('🎯', style: TextStyle(fontSize: 30)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Plan 2026',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Set goals & build habits',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  // Quick Stats Section - IMPROVED & STANDARD
  Widget _buildQuickStatsSection(BuildContext context, bool isDarkMode, AppProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Quick Stats',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today, color: Colors.white.withValues(alpha: 0.8), size: 14),
                  const SizedBox(width: 4),
                  const Text(
                    '2025',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        
        // Stats Grid - 2x2 with REAL data
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.photo_library_rounded,
                iconBgColor: const Color(0xFFFF6B8A),
                label: 'Photos',
                value: _isLoading ? '...' : _realPhotos.toString(),
                subtitle: 'from gallery',
                isDarkMode: isDarkMode,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.videocam_rounded,
                iconBgColor: const Color(0xFF4ECDC4),
                label: 'Videos',
                value: _isLoading ? '...' : _realVideos.toString(),
                subtitle: 'from gallery',
                isDarkMode: isDarkMode,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.edit_note_rounded,
                iconBgColor: const Color(0xFFFFB347),
                label: 'Journal',
                value: provider.totalJournals.toString(),
                subtitle: 'entries',
                isDarkMode: isDarkMode,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.emoji_events_rounded,
                iconBgColor: const Color(0xFF9B59B6),
                label: 'Goals',
                value: provider.totalGoals.toString(),
                subtitle: 'set',
                isDarkMode: isDarkMode,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Activity Summary Section
  Widget _buildActivitySummary(bool isDarkMode, AppProvider provider) {
    final totalMemories = _realPhotos + _realVideos;
    
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode 
              ? [const Color(0xFF2D2D44), const Color(0xFF1F1F32)]
              : [Colors.white.withValues(alpha: 0.2), Colors.white.withValues(alpha: 0.1)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.insights_rounded, color: Color(0xFFFFD700), size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Your 2025 Summary',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Summary Items
          _SummaryRow(
            icon: Icons.collections,
            label: 'Total Memories',
            value: _isLoading ? '...' : totalMemories.toString(),
            color: const Color(0xFFFF6B8A),
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            icon: Icons.check_circle,
            label: 'Achievements',
            value: provider.totalAchievements.toString(),
            color: const Color(0xFF4ECDC4),
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            icon: Icons.repeat,
            label: 'Habits Tracked',
            value: provider.totalHabits.toString(),
            color: const Color(0xFFFFB347),
          ),
          
          if (totalMemories > 0 || provider.totalJournals > 0) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF4ECDC4).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Color(0xFF4ECDC4), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      totalMemories > 0 
                          ? 'You have $totalMemories memories from 2025! 🎉'
                          : 'Start capturing your 2025 memories!',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Stat Card Widget
class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final String label;
  final String value;
  final String subtitle;
  final bool isDarkMode;

  const _StatCard({
    required this.icon,
    required this.iconBgColor,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDarkMode 
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBgColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconBgColor, size: 20),
              ),
              const Spacer(),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

// Summary Row Widget
class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
