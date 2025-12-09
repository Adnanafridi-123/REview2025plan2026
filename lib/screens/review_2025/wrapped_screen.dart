import 'package:flutter/material.dart';
import '../../widgets/beautiful_back_button.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';

class WrappedScreen extends StatefulWidget {
  const WrappedScreen({super.key});

  @override
  State<WrappedScreen> createState() => _WrappedScreenState();
}

class _WrappedScreenState extends State<WrappedScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isGenerated = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
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
                child: Consumer<AppProvider>(
                  builder: (context, provider, child) {
                    if (!_isGenerated) {
                      return _buildIntroScreen();
                    }

                    return Column(
                      children: [
                        // Page Indicator
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (index) {
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: _currentPage == index ? 28 : 10,
                                height: 10,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  color: _currentPage == index
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_currentPage + 1} of 5',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 13,
                          ),
                        ),

                        // Cards carousel
                        Expanded(
                          child: PageView(
                            controller: _pageController,
                            onPageChanged: (page) => setState(() => _currentPage = page),
                            children: [
                              _WrappedCard(
                                gradient: AppTheme.timelineGradient,
                                title: 'Your Year in Numbers',
                                child: _YearInNumbersContent(provider: provider),
                              ),
                              _WrappedCard(
                                gradient: AppTheme.journalGradient,
                                title: 'Top Mood',
                                child: _TopMoodContent(provider: provider),
                              ),
                              _WrappedCard(
                                gradient: AppTheme.videosGradient,
                                title: 'Most Active Month',
                                child: _MostActiveContent(provider: provider),
                              ),
                              _WrappedCard(
                                gradient: AppTheme.achievementsGradient,
                                title: 'Your Achievements',
                                child: _AchievementsContent(provider: provider),
                              ),
                              _WrappedCard(
                                gradient: AppTheme.statisticsGradient,
                                title: 'Until Next Year!',
                                child: _FinalContent(provider: provider),
                              ),
                            ],
                          ),
                        ),

                        // Navigation
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (_currentPage > 0)
                                GestureDetector(
                                  onTap: () {
                                    _pageController.previousPage(
                                      duration: const Duration(milliseconds: 400),
                                      curve: Curves.easeInOut,
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.arrow_back_ios,
                                            color: Colors.white, size: 16),
                                        SizedBox(width: 8),
                                        Text(
                                          'Previous',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                const SizedBox.shrink(),
                              if (_currentPage < 4)
                                GestureDetector(
                                  onTap: () {
                                    _pageController.nextPage(
                                      duration: const Duration(milliseconds: 400),
                                      curve: Curves.easeInOut,
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(25),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.1),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          'Next',
                                          style: TextStyle(
                                            color: AppTheme.wrappedGradient.colors.first,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(Icons.arrow_forward_ios,
                                            color: AppTheme.wrappedGradient.colors.first, size: 16),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                GestureDetector(
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('Sharing your 2025 Wrapped!'),
                                        backgroundColor: AppTheme.wrappedGradient.colors.first,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(25),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.1),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.share,
                                            color: AppTheme.wrappedGradient.colors.first, size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Share All',
                                          style: TextStyle(
                                            color: AppTheme.wrappedGradient.colors.first,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
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

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          const BeautifulBackButton(),
          const Spacer(),
          if (_isGenerated)
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Sharing all cards...'),
                    backgroundColor: AppTheme.wrappedGradient.colors.first,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.share,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIntroScreen() {
    return Center(
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated gift icon
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  gradient: AppTheme.wrappedGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.wrappedGradient.colors.first.withValues(alpha: 0.4),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 70,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 40),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.white, Color(0xFFE8D5F0)],
                ).createShader(bounds),
                child: const Text(
                  'Your 2025\nWrapped',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Get a personalized summary of\nyour amazing 2025 journey',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.85),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              GestureDetector(
                onTap: () => setState(() => _isGenerated = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: AppTheme.wrappedGradient.colors.first,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Create My Wrapped',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.wrappedGradient.colors.first,
                        ),
                      ),
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
}

class AnimatedBuilder extends StatelessWidget {
  final Animation<double> animation;
  final Widget Function(BuildContext, Widget?) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required this.animation,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedWidget2(
      animation: animation,
      builder: builder,
      child: child,
    );
  }
}

class AnimatedWidget2 extends AnimatedWidget {
  final Widget Function(BuildContext, Widget?) builder;
  final Widget? child;

  const AnimatedWidget2({
    super.key,
    required Animation<double> animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}

class _WrappedCard extends StatelessWidget {
  final LinearGradient gradient;
  final String title;
  final Widget child;

  const _WrappedCard({
    required this.gradient,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 50,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            // Content
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _YearInNumbersContent extends StatelessWidget {
  final AppProvider provider;

  const _YearInNumbersContent({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _NumberRow(
          icon: Icons.photo,
          label: 'Photos',
          value: provider.totalPhotos.toString(),
        ),
        const SizedBox(height: 20),
        _NumberRow(
          icon: Icons.videocam,
          label: 'Videos',
          value: provider.totalVideos.toString(),
        ),
        const SizedBox(height: 20),
        _NumberRow(
          icon: Icons.menu_book,
          label: 'Journal Entries',
          value: provider.totalJournals.toString(),
        ),
        const SizedBox(height: 20),
        _NumberRow(
          icon: Icons.emoji_events,
          label: 'Achievements',
          value: provider.totalAchievements.toString(),
        ),
      ],
    );
  }
}

class _NumberRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _NumberRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 26),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 16,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopMoodContent extends StatelessWidget {
  final AppProvider provider;

  const _TopMoodContent({required this.provider});

  @override
  Widget build(BuildContext context) {
    final moodDistribution = provider.getMoodDistribution();
    String topMood = '😊';
    int topCount = 0;

    moodDistribution.forEach((mood, count) {
      if (count > topCount) {
        topMood = mood;
        topCount = count;
      }
    });

    final moodName = {
      '😊': 'Happy',
      '😢': 'Sad',
      '😠': 'Angry',
      '😐': 'Neutral',
      '❤️': 'Love',
    }[topMood] ?? 'Happy';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              topMood,
              style: const TextStyle(fontSize: 80),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'You felt $moodName\nmost of the time!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.95),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Text(
            '$topCount entries',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _MostActiveContent extends StatelessWidget {
  final AppProvider provider;

  const _MostActiveContent({required this.provider});

  @override
  Widget build(BuildContext context) {
    final mostActiveMonth = provider.getMostActiveMonth();
    final monthName = DateFormat('MMMM').format(DateTime(2025, mostActiveMonth));
    final activity = provider.getMonthlyActivity();
    final count = activity[mostActiveMonth] ?? 0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.calendar_month, color: Colors.white, size: 40),
              const SizedBox(height: 4),
              Text(
                mostActiveMonth.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Text(
          monthName,
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'was your most active month!',
          style: TextStyle(
            fontSize: 18,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Text(
            '$count memories created',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _AchievementsContent extends StatelessWidget {
  final AppProvider provider;

  const _AchievementsContent({required this.provider});

  @override
  Widget build(BuildContext context) {
    final achievements = provider.achievements2025;
    final topAchievements = achievements.take(3).toList();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.emoji_events, color: Colors.white, size: 60),
        const SizedBox(height: 24),
        Text(
          '${achievements.length}',
          style: const TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          'Achievements Unlocked!',
          style: TextStyle(
            fontSize: 18,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: 32),
        ...topAchievements.map((achievement) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    achievement.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _FinalContent extends StatelessWidget {
  final AppProvider provider;

  const _FinalContent({required this.provider});

  @override
  Widget build(BuildContext context) {
    final total = provider.totalPhotos +
        provider.totalVideos +
        provider.totalJournals +
        provider.totalAchievements;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text(
              '🎉',
              style: TextStyle(fontSize: 50),
            ),
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'What a Year!',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'You created $total memories\nin 2025!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            color: Colors.white.withValues(alpha: 0.9),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            "Here's to an even better 2026! ✨",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
