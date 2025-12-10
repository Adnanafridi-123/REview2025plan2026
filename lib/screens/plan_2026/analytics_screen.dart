import 'package:flutter/material.dart';
import '../../widgets/beautiful_back_button.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/gamification_widgets.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> with TickerProviderStateMixin {
  int _selectedTab = 0;
  final List<String> _tabs = ['Overview', 'Goals', 'Habits', 'Insights'];
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
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
              _buildAppBar(context),
              Expanded(
                child: Consumer<AppProvider>(
                  builder: (context, provider, _) {
                    final totalGoals = provider.goals.length;
                    final completedGoals = provider.completedGoals.length;
                    final totalHabits = provider.habits.length;
                    final avgHabitStreak = totalHabits > 0 
                        ? provider.habits.fold(0, (sum, h) => sum + h.currentStreak) ~/ totalHabits 
                        : 0;
                    
                    return ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(AppTheme.screenPadding),
                      children: [
                        // Header with animated title
                        _buildAnimatedHeader(),
                        const SizedBox(height: 20),
                        
                        // Stats Row with animations
                        _buildStatsRow(totalGoals, completedGoals, totalHabits, avgHabitStreak),
                        const SizedBox(height: 20),
                        
                        // Tabs
                        _buildTabs(),
                        const SizedBox(height: 20),
                        
                        // Tab Content with animations
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _buildTabContent(provider),
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

  Widget _buildAnimatedHeader() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Row(
          children: [
            const Text(
              'Analytics',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.textWhite,
              ),
            ),
            const SizedBox(width: 10),
            Transform.rotate(
              angle: _animationController.value * 0.5,
              child: const Text('📊', style: TextStyle(fontSize: 26)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          const BeautifulBackButton(),
        ],
      ),
    );
  }

  Widget _buildStatsRow(int totalGoals, int completed, int habits, int avgStreak) {
    return Row(
      children: [
        Expanded(
          child: _AnimatedStatCard(
            label: 'Total Goals',
            value: totalGoals.toString(),
            color: AppTheme.primaryPurple,
            icon: Icons.flag,
            delay: 0,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _AnimatedStatCard(
            label: 'Completed',
            value: completed.toString(),
            color: AppTheme.primaryGreen,
            icon: Icons.check_circle,
            delay: 100,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _AnimatedStatCard(
            label: 'Avg Streak',
            value: '$avgStreak days',
            color: Colors.orange,
            icon: Icons.local_fire_department,
            delay: 200,
          ),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: _tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          final isSelected = _selectedTab == index;
          
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: isSelected 
                      ? const LinearGradient(
                          colors: [Color(0xFF4DB6AC), Color(0xFF26A69A)],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: AppTheme.primaryTeal.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ] : null,
                ),
                child: Center(
                  child: Text(
                    tab,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabContent(AppProvider provider) {
    switch (_selectedTab) {
      case 0:
        return _buildOverviewTab(provider);
      case 1:
        return _buildGoalsTab(provider);
      case 2:
        return _buildHabitsTab(provider);
      case 3:
        return _buildInsightsTab(provider);
      default:
        return _buildOverviewTab(provider);
    }
  }

  Widget _buildOverviewTab(AppProvider provider) {
    final totalGoals = provider.goals.length;
    final completedGoals = provider.completedGoals.length;
    final successRate = totalGoals > 0 ? (completedGoals / totalGoals * 100) : 0.0;
    final habits = provider.habits;
    final completedToday = habits.where((h) => h.isCompletedToday()).length;
    
    return Column(
      key: const ValueKey('overview'),
      children: [
        // Success Rate Card with animation
        _buildSuccessRateCard(successRate),
        const SizedBox(height: 16),
        
        // Today's Summary
        _buildTodaySummaryCard(completedToday, habits.length, provider),
        const SizedBox(height: 16),
        
        // Progress Chart
        _buildProgressChartCard(),
        const SizedBox(height: 16),
        
        // Quick Stats Grid
        _buildQuickStatsGrid(provider),
      ],
    );
  }

  Widget _buildSuccessRateCard(double successRate) {
    final color = successRate >= 70 
        ? AppTheme.primaryGreen 
        : successRate >= 40 
            ? Colors.orange 
            : Colors.red;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.7)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.emoji_events,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Success Rate',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF636E72),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        successRate >= 70 ? 'Excellent!' : successRate >= 40 ? 'Good' : 'Needs Work',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: successRate),
                  duration: const Duration(milliseconds: 1500),
                  builder: (context, value, child) {
                    return Text(
                      '${value.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // Progress ring
          SizedBox(
            width: 70,
            height: 70,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: successRate / 100),
              duration: const Duration(milliseconds: 1500),
              builder: (context, value, child) {
                return Stack(
                  children: [
                    CircularProgressIndicator(
                      value: 1,
                      strokeWidth: 8,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation(Colors.grey[200]),
                    ),
                    CircularProgressIndicator(
                      value: value,
                      strokeWidth: 8,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation(color),
                      strokeCap: StrokeCap.round,
                    ),
                    Center(
                      child: Icon(
                        successRate >= 70 ? Icons.trending_up : Icons.trending_flat,
                        color: color,
                        size: 24,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaySummaryCard(int completedHabits, int totalHabits, AppProvider provider) {
    final activeGoals = provider.activeGoals.length;
    final reviews = provider.weeklyReviews.length;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF667EEA).withValues(alpha: 0.15),
            const Color(0xFF764BA2).withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF667EEA).withValues(alpha: 0.3),
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
                  color: const Color(0xFF667EEA).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.today, color: Color(0xFF667EEA), size: 22),
              ),
              const SizedBox(width: 14),
              const Text(
                "Today's Summary",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3436),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildSummaryItem(
                Icons.check_circle,
                '$completedHabits/$totalHabits',
                'Habits Done',
                AppTheme.primaryGreen,
              ),
              _buildSummaryItem(
                Icons.flag,
                '$activeGoals',
                'Active Goals',
                AppTheme.primaryPurple,
              ),
              _buildSummaryItem(
                Icons.rate_review,
                '$reviews',
                'Reviews',
                AppTheme.primaryPink,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressChartCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Weekly Progress',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3436),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.primaryTeal.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.trending_up, size: 14, color: AppTheme.primaryTeal),
                    const SizedBox(width: 4),
                    Text(
                      '+12%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryTeal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: _AnimatedBarChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsGrid(AppProvider provider) {
    final habits = provider.habits;
    final bestStreak = habits.isEmpty ? 0 : habits.map((h) => h.bestStreak).reduce(math.max);
    final totalCompletions = habits.fold(0, (sum, h) => sum + h.completionDates.length);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Stats',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textWhite,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickStatCard(
                '🔥',
                '$bestStreak',
                'Best Streak',
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickStatCard(
                '✅',
                '$totalCompletions',
                'Total Check-ins',
                AppTheme.primaryGreen,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickStatCard(String emoji, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsTab(AppProvider provider) {
    final categoryStats = <String, Map<String, int>>{};
    for (var goal in provider.goals) {
      if (!categoryStats.containsKey(goal.category)) {
        categoryStats[goal.category] = {'total': 0, 'completed': 0};
      }
      categoryStats[goal.category]!['total'] = categoryStats[goal.category]!['total']! + 1;
      if (goal.isCompleted) {
        categoryStats[goal.category]!['completed'] = categoryStats[goal.category]!['completed']! + 1;
      }
    }
    
    if (categoryStats.isEmpty) {
      return _buildEmptyContent('No goal data', 'Add goals to see category breakdown');
    }
    
    return Column(
      key: const ValueKey('goals'),
      children: [
        // Category breakdown
        ...categoryStats.entries.map((entry) {
          final color = AppTheme.categoryColors[entry.key] ?? AppTheme.primaryPurple;
          final total = provider.goals.length;
          final percentage = total > 0 ? (entry.value['total']! / total * 100) : 0.0;
          final completion = entry.value['total']! > 0 
              ? (entry.value['completed']! / entry.value['total']! * 100) 
              : 0.0;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color, color.withValues(alpha: 0.7)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        _getCategoryIcon(entry.key),
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3436),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${entry.value['completed']}/${entry.value['total']} completed',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${percentage.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        Text(
                          'of goals',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Completion progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: completion / 100),
                    duration: const Duration(milliseconds: 800),
                    builder: (context, value, child) {
                      return Stack(
                        children: [
                          Container(
                            height: 6,
                            color: Colors.grey[200],
                          ),
                          FractionallySizedBox(
                            widthFactor: value,
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [color, color.withValues(alpha: 0.7)],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildHabitsTab(AppProvider provider) {
    final habits = provider.habits;
    final completedToday = habits.where((h) => h.isCompletedToday()).length;
    final total = habits.length;
    final percentage = total > 0 ? (completedToday / total * 100).toInt() : 0;
    
    // Calculate best and worst days
    final dayCompletion = <String, int>{
      'Mon': 0, 'Tue': 0, 'Wed': 0, 'Thu': 0, 'Fri': 0, 'Sat': 0, 'Sun': 0
    };
    final dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    
    for (var habit in habits) {
      for (var date in habit.completionDates) {
        dayCompletion[dayNames[date.weekday % 7]] = 
            (dayCompletion[dayNames[date.weekday % 7]] ?? 0) + 1;
      }
    }
    
    String bestDay = 'Monday';
    String worstDay = 'Sunday';
    int maxCount = 0;
    int minCount = double.maxFinite.toInt();
    
    dayCompletion.forEach((day, count) {
      if (count > maxCount) {
        maxCount = count;
        bestDay = day;
      }
      if (count < minCount) {
        minCount = count;
        worstDay = day;
      }
    });
    
    return Column(
      key: const ValueKey('habits'),
      children: [
        // Today's Completion - Animated donut
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                "Today's Completion",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3436),
                ),
              ),
              const SizedBox(height: 20),
              ProgressRing(
                progress: total > 0 ? completedToday / total : 0,
                size: 130,
                color: AppTheme.primaryTeal,
                centerText: '$percentage%',
                subtitle: '$completedToday of $total',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Best Day / Needs Work Row
        Row(
          children: [
            Expanded(
              child: _buildDayCard(
                icon: Icons.thumb_up,
                iconColor: AppTheme.primaryGreen,
                label: 'Best Day',
                value: bestDay,
                emoji: '🏆',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDayCard(
                icon: Icons.trending_down,
                iconColor: Colors.red,
                label: 'Needs Work',
                value: worstDay,
                emoji: '💪',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Habit Streaks Overview
        if (habits.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Habit Streaks',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3436),
                  ),
                ),
                const SizedBox(height: 12),
                ...habits.take(5).map((habit) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            habit.name,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: habit.currentStreak > 0 
                                ? Colors.orange.withValues(alpha: 0.15)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.local_fire_department,
                                size: 14,
                                color: habit.currentStreak > 0 ? Colors.orange : Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${habit.currentStreak}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: habit.currentStreak > 0 ? Colors.orange : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDayCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String emoji,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 8),
              Text(emoji, style: const TextStyle(fontSize: 24)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3436),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsTab(AppProvider provider) {
    final insights = _generateInsights(provider);
    
    return Column(
      key: const ValueKey('insights'),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF667EEA).withValues(alpha: 0.15),
                const Color(0xFF764BA2).withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF667EEA).withValues(alpha: 0.3),
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
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Smart Insights',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3436),
                          ),
                        ),
                        Text(
                          'AI-powered recommendations',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF636E72),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00C853), Color(0xFF69F0AE)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'AI',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ...insights.asMap().entries.map((entry) {
                final index = entry.key;
                final insight = entry.value;
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 400 + (index * 200)),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(20 * (1 - value), 0),
                        child: _buildInsightCard(insight),
                      ),
                    );
                  },
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInsightCard(Map<String, dynamic> insight) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (insight['color'] as Color).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                insight['emoji'] as String,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight['title'] as String,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: insight['color'] as Color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight['text'] as String,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _generateInsights(AppProvider provider) {
    final insights = <Map<String, dynamic>>[];
    final goals = provider.goals;
    final habits = provider.habits;
    final completedGoals = provider.completedGoals;
    
    // Check habits completion pattern
    final completedToday = habits.where((h) => h.isCompletedToday()).length;
    if (habits.isNotEmpty) {
      if (completedToday == habits.length) {
        insights.add({
          'emoji': '🎉',
          'title': 'Perfect Day!',
          'text': 'You\'ve completed all your habits today. Keep this momentum going for a powerful streak!',
          'color': AppTheme.primaryGreen,
        });
      } else if (completedToday == 0 && DateTime.now().hour > 12) {
        insights.add({
          'emoji': '⚡',
          'title': 'Time to Act',
          'text': 'No habits completed yet today. Start with just one habit to build momentum!',
          'color': Colors.orange,
        });
      }
    }
    
    // Check streaks
    if (habits.isNotEmpty) {
      final avgStreak = habits.fold(0, (sum, h) => sum + h.currentStreak) / habits.length;
      if (avgStreak >= 7) {
        insights.add({
          'emoji': '🔥',
          'title': 'Streak Master',
          'text': 'Your average streak is ${avgStreak.toStringAsFixed(1)} days! You\'re building strong habits.',
          'color': Colors.orange,
        });
      }
    }
    
    // Check goal progress
    if (goals.isNotEmpty) {
      final successRate = completedGoals.length / goals.length;
      if (successRate >= 0.7) {
        insights.add({
          'emoji': '🏆',
          'title': 'Goal Crusher',
          'text': 'Amazing! You\'ve completed ${(successRate * 100).toInt()}% of your goals. Consider raising the bar!',
          'color': const Color(0xFF6C63FF),
        });
      }
      
      // Find goals near deadline
      final urgentGoals = provider.activeGoals.where((g) {
        final daysLeft = g.deadline.difference(DateTime.now()).inDays;
        return daysLeft <= 7 && daysLeft >= 0;
      }).toList();
      
      if (urgentGoals.isNotEmpty) {
        insights.add({
          'emoji': '⏰',
          'title': 'Deadline Alert',
          'text': '${urgentGoals.length} goal(s) due this week. Focus on "${urgentGoals.first.name}" first!',
          'color': Colors.red,
        });
      }
    }
    
    // Default insight if empty
    if (insights.isEmpty) {
      insights.add({
        'emoji': '💡',
        'title': 'Getting Started',
        'text': 'Add goals and habits to get personalized insights and recommendations!',
        'color': const Color(0xFF667EEA),
      });
    }
    
    return insights;
  }

  Widget _buildEmptyContent(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.analytics_outlined, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Career':
        return Icons.work_outline;
      case 'Health':
        return Icons.favorite_outline;
      case 'Finance':
        return Icons.attach_money;
      case 'Personal':
        return Icons.person_outline;
      default:
        return Icons.category;
    }
  }
}

// Animated stat card
class _AnimatedStatCard extends StatefulWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final int delay;

  const _AnimatedStatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.delay,
  });

  @override
  State<_AnimatedStatCard> createState() => _AnimatedStatCardState();
}

class _AnimatedStatCardState extends State<_AnimatedStatCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.forward();
      }
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
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(widget.icon, color: widget.color, size: 20),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: widget.color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Animated bar chart
class _AnimatedBarChart extends StatefulWidget {
  @override
  State<_AnimatedBarChart> createState() => _AnimatedBarChartState();
}

class _AnimatedBarChartState extends State<_AnimatedBarChart> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final values = [0.5, 0.7, 0.45, 0.85, 0.6, 0.3, 0.65];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..forward();
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
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: days.asMap().entries.map((entry) {
            final index = entry.key;
            final day = entry.value;
            final value = values[index];
            final isToday = DateTime.now().weekday - 1 == index;
            
            // Stagger the animation
            final delayedProgress = (_controller.value - (index * 0.1)).clamp(0.0, 1.0) / 0.9;
            
            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 32,
                  height: 100 * value * delayedProgress,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: isToday 
                          ? [const Color(0xFF4DB6AC), const Color(0xFF26A69A)]
                          : [const Color(0xFFE0E0E0), const Color(0xFFBDBDBD)],
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    boxShadow: isToday ? [
                      BoxShadow(
                        color: AppTheme.primaryTeal.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ] : null,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  day,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    color: isToday ? AppTheme.primaryTeal : Colors.grey[500],
                  ),
                ),
              ],
            );
          }).toList(),
        );
      },
    );
  }
}
