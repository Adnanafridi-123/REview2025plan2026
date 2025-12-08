import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/review_app_bar.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ReviewGradientBackground(
      colors: [
        AppTheme.statisticsStart.withValues(alpha: 0.2),
        AppTheme.statisticsEnd.withValues(alpha: 0.12),
        Colors.white.withValues(alpha: 0.98),
      ],
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: ReviewAppBar(
          title: 'Statistics 2025',
          actions: [
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Sharing statistics...'),
                    backgroundColor: AppTheme.statisticsStart,
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
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
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
        body: Consumer<AppProvider>(
          builder: (context, provider, child) {
            final moodDistribution = provider.getMoodDistribution();
            final monthlyActivity = provider.getMonthlyActivity();
            final mostActiveMonth = provider.getMostActiveMonth();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    'Year Overview',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPurple,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your 2025 in numbers',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textPurple.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Summary cards
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.3,
                    children: [
                      _AnimatedStatCard(
                        title: 'Photos',
                        value: provider.totalPhotos.toString(),
                        icon: Icons.photo_library_outlined,
                        gradient: AppTheme.photosCardGradient,
                        delay: 0,
                      ),
                      _AnimatedStatCard(
                        title: 'Videos',
                        value: provider.totalVideos.toString(),
                        icon: Icons.videocam_outlined,
                        gradient: AppTheme.videosCardGradient,
                        delay: 100,
                      ),
                      _AnimatedStatCard(
                        title: 'Journal',
                        value: provider.totalJournals.toString(),
                        icon: Icons.menu_book_outlined,
                        gradient: AppTheme.journalCardGradient,
                        delay: 200,
                      ),
                      _AnimatedStatCard(
                        title: 'Achievements',
                        value: provider.totalAchievements.toString(),
                        icon: Icons.emoji_events_outlined,
                        gradient: AppTheme.achievementsCardGradient,
                        delay: 300,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Mood Distribution
                  _BeautifulChartCard(
                    title: 'Mood Distribution',
                    subtitle: 'How you felt throughout the year',
                    child: moodDistribution.isEmpty
                        ? _EmptyChartState(
                            icon: Icons.mood,
                            message: 'No mood data yet',
                          )
                        : Column(
                            children: [
                              SizedBox(
                                height: 200,
                                child: PieChart(
                                  PieChartData(
                                    sections: _buildMoodSections(moodDistribution),
                                    centerSpaceRadius: 50,
                                    sectionsSpace: 3,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Mood Legend
                              Wrap(
                                spacing: 12,
                                runSpacing: 8,
                                alignment: WrapAlignment.center,
                                children: moodDistribution.entries.map((entry) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.statisticsStart
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(entry.key,
                                            style: const TextStyle(fontSize: 18)),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${entry.value}',
                                          style: const TextStyle(
                                            color: AppTheme.textDark,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                  ),

                  const SizedBox(height: 20),

                  // Monthly Activity
                  _BeautifulChartCard(
                    title: 'Monthly Activity',
                    subtitle: 'Most active: ${DateFormat('MMMM').format(DateTime(2025, mostActiveMonth))}',
                    child: SizedBox(
                      height: 220,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: (monthlyActivity.values.isEmpty
                                  ? 10
                                  : monthlyActivity.values.reduce((a, b) => a > b ? a : b)) *
                              1.2,
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              fitInsideHorizontally: true,
                              fitInsideVertically: true,
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                final months = [
                                  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                                  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                                ];
                                return BarTooltipItem(
                                  '${months[group.x]}\n${rod.toY.toInt()} entries',
                                  const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                );
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  const months = [
                                    'J', 'F', 'M', 'A', 'M', 'J',
                                    'J', 'A', 'S', 'O', 'N', 'D'
                                  ];
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      months[value.toInt()],
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: 5,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: Colors.grey[200]!,
                                strokeWidth: 1,
                              );
                            },
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: List.generate(12, (index) {
                            final value = monthlyActivity[index + 1] ?? 0;
                            final isHighest = value ==
                                monthlyActivity.values.reduce(
                                    (a, b) => a > b ? a : b);
                            return BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: value.toDouble(),
                                  gradient: isHighest
                                      ? AppTheme.statisticsCardGradient
                                      : LinearGradient(
                                          colors: [
                                            AppTheme.statisticsStart
                                                .withValues(alpha: 0.5),
                                            AppTheme.statisticsEnd
                                                .withValues(alpha: 0.3),
                                          ],
                                        ),
                                  width: 20,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(6),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Highlights section
                  _BeautifulChartCard(
                    title: 'Highlights',
                    subtitle: 'Key moments from your year',
                    child: Column(
                      children: [
                        _HighlightRow(
                          icon: Icons.calendar_today,
                          label: 'Most Active Month',
                          value: DateFormat('MMMM').format(DateTime(2025, mostActiveMonth)),
                          color: AppTheme.statisticsStart,
                        ),
                        const SizedBox(height: 12),
                        _HighlightRow(
                          icon: Icons.photo,
                          label: 'Total Memories',
                          value: '${provider.totalPhotos + provider.totalVideos}',
                          color: AppTheme.photosStart,
                        ),
                        const SizedBox(height: 12),
                        _HighlightRow(
                          icon: Icons.edit_note,
                          label: 'Words Written',
                          value: '~${provider.totalJournals * 150}',
                          color: AppTheme.journalStart,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildMoodSections(Map<String, int> distribution) {
    final colors = {
      '😊': AppTheme.moodHappy,
      '😢': AppTheme.moodSad,
      '😠': AppTheme.moodAngry,
      '😐': AppTheme.moodNeutral,
      '❤️': AppTheme.moodLove,
    };

    final total = distribution.values.fold(0, (a, b) => a + b);

    return distribution.entries.map((entry) {
      final percentage = (entry.value / total * 100);
      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: '${percentage.toStringAsFixed(0)}%',
        color: colors[entry.key] ?? Colors.grey,
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }
}

class _AnimatedStatCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final LinearGradient gradient;
  final int delay;

  const _AnimatedStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
    this.delay = 0,
  });

  @override
  State<_AnimatedStatCard> createState() => _AnimatedStatCardState();
}

class _AnimatedStatCardState extends State<_AnimatedStatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: widget.gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: widget.gradient.colors.first.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                widget.icon,
                color: Colors.white,
                size: 22,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.value,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ],
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

class _BeautifulChartCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const _BeautifulChartCard({
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
              ),
            ),
          ],
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _EmptyChartState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyChartState({
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 48,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _HighlightRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _HighlightRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textDark,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
