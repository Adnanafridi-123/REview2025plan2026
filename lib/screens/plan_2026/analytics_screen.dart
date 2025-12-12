import 'package:flutter/material.dart';
import '../../widgets/beautiful_back_button.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _selectedTab = 0;
  final List<String> _tabs = ['Overview', 'Categories', 'Habits'];

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // App Bar - EXACT from video
              _buildAppBar(context),
              
              // Content
              Expanded(
                child: Consumer<AppProvider>(
                  builder: (context, provider, _) {
                    final totalGoals = provider.goals.length;
                    final completedGoals = provider.completedGoals.length;
                    final totalHabits = provider.habits.length;
                    
                    return ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(AppTheme.screenPadding),
                      children: [
                        // Header - EXACT from video
                        const Text(
                          'Analytics',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textWhite,
                          ),
                        ),
                        Text(
                          'Track your progress',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textWhite.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Stats Row - EXACT from video (3 white cards)
                        _buildStatsRow(totalGoals, completedGoals, totalHabits),
                        const SizedBox(height: 20),
                        
                        // Tabs - EXACT from video
                        _buildTabs(),
                        const SizedBox(height: 20),
                        
                        // Tab Content
                        if (_selectedTab == 0) _buildOverviewTab(provider),
                        if (_selectedTab == 1) _buildCategoriesTab(provider),
                        if (_selectedTab == 2) _buildHabitsTab(provider),
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
        ],
      ),
    );
  }

  // Stats Row - EXACT from video (3 white cards: Total Goals, Completed, Habits)
  Widget _buildStatsRow(int totalGoals, int completed, int habits) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Total Goals',
            value: totalGoals.toString(),
            color: AppTheme.primaryPurple,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Completed',
            value: completed.toString(),
            color: AppTheme.primaryGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Habits',
            value: habits.toString(),
            color: AppTheme.primaryOrange,
          ),
        ),
      ],
    );
  }

  // Tabs - EXACT from video
  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
                  color: isSelected ? AppTheme.primaryTeal : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    tab,
                    style: TextStyle(
                      fontSize: 14,
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

  // Overview Tab - EXACT from video (Success Rate card + Progress chart)
  Widget _buildOverviewTab(AppProvider provider) {
    final totalGoals = provider.goals.length;
    final completedGoals = provider.completedGoals.length;
    final successRate = totalGoals > 0 ? (completedGoals / totalGoals * 100) : 0.0;
    
    return Column(
      children: [
        // Success Rate Card - EXACT from video
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
          child: Row(
            children: [
              // Trophy icon - EXACT from video
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: AppTheme.primaryGreen,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Success Rate',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF636E72),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${successRate.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Progress Over Time Card - EXACT from video
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Progress Over Time',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3436),
                ),
              ),
              const SizedBox(height: 20),
              // Simple line chart visualization - Now with REAL data
              SizedBox(
                height: 150,
                child: _buildSimpleChart(provider),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleChart(AppProvider provider) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final values = _calculateWeeklyHabitCompletion(provider);
    
    return Column(
      children: [
        // Y-axis labels
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Y-axis
              SizedBox(
                width: 35,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: ['100%', '50%', '0%']
                      .map((label) => Text(
                            label,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[400],
                            ),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(width: 8),
              // Chart area
              Expanded(
                child: values.every((v) => v == 0)
                    ? Center(
                        child: Text(
                          'Complete habits to see progress',
                          style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                        ),
                      )
                    : CustomPaint(
                        painter: _LineChartPainter(values, AppTheme.primaryTeal),
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // X-axis labels - EXACT from video
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            const SizedBox(width: 43), // Offset for Y-axis
            ...days.map((day) => Text(
                  day,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[400],
                  ),
                )),
          ],
        ),
      ],
    );
  }

  // Categories Tab
  Widget _buildCategoriesTab(AppProvider provider) {
    final categoryStats = <String, int>{};
    for (var goal in provider.goals) {
      categoryStats[goal.category] = (categoryStats[goal.category] ?? 0) + 1;
    }
    
    if (categoryStats.isEmpty) {
      return _buildEmptyContent('No category data', 'Add goals to see category breakdown');
    }
    
    return Column(
      children: categoryStats.entries.map((entry) {
        final color = AppTheme.categoryColors[entry.key] ?? AppTheme.primaryPurple;
        final total = provider.goals.length;
        final percentage = total > 0 ? (entry.value / total * 100) : 0.0;
        
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
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getCategoryIcon(entry.key),
                  color: color,
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
                      '${entry.value} goals',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Habits Tab - EXACT from video (Today's Completion donut + Best Day / Needs Work cards)
  Widget _buildHabitsTab(AppProvider provider) {
    final habits = provider.habits;
    final completedToday = habits.where((h) => h.isCompletedToday()).length;
    final total = habits.length;
    final percentage = total > 0 ? (completedToday / total * 100).toInt() : 0;
    
    // Calculate best and worst days from real data
    final dayStats = _calculateDayStats(provider);
    final bestDay = dayStats['best'] ?? 'N/A';
    final worstDay = dayStats['worst'] ?? 'N/A';
    
    return Column(
      children: [
        // Today's Completion - Donut chart (EXACT from video)
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
              // Donut chart - EXACT from video
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(
                        value: total > 0 ? completedToday / total : 0,
                        strokeWidth: 12,
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation(AppTheme.primaryTeal),
                      ),
                    ),
                    Center(
                      child: Text(
                        '$percentage%',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryTeal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Best Day / Needs Work Row - Now with REAL data
        Row(
          children: [
            Expanded(
              child: _buildDayCard(
                icon: Icons.thumb_up,
                iconColor: AppTheme.primaryGreen,
                label: 'Best Day',
                value: bestDay,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDayCard(
                icon: Icons.trending_down,
                iconColor: Colors.red,
                label: 'Needs Work',
                value: worstDay,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Calculate weekly habit completion percentages for each day
  List<double> _calculateWeeklyHabitCompletion(AppProvider provider) {
    final habits = provider.habits;
    if (habits.isEmpty) return List.filled(7, 0.0);
    
    final now = DateTime.now();
    final values = <double>[];
    
    // Get last 7 days starting from Monday
    final currentWeekday = now.weekday; // 1 = Monday, 7 = Sunday
    final startOfWeek = now.subtract(Duration(days: currentWeekday - 1));
    
    for (int i = 0; i < 7; i++) {
      final day = startOfWeek.add(Duration(days: i));
      final dayStart = DateTime(day.year, day.month, day.day);
      
      int completedCount = 0;
      for (var habit in habits) {
        if (habit.isCompletedOnDate(dayStart)) {
          completedCount++;
        }
      }
      
      final percentage = (completedCount / habits.length * 100).clamp(0.0, 100.0);
      values.add(percentage);
    }
    
    return values;
  }

  // Calculate best and worst days from habit data
  Map<String, String> _calculateDayStats(AppProvider provider) {
    final habits = provider.habits;
    if (habits.isEmpty) return {'best': 'N/A', 'worst': 'N/A'};
    
    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final dayCounts = List.filled(7, 0); // Index 0 = Monday
    
    // Count completions for each day of the week
    for (var habit in habits) {
      for (var date in habit.completionDates) {
        final weekday = date.weekday - 1; // Convert to 0-indexed
        if (weekday >= 0 && weekday < 7) {
          dayCounts[weekday]++;
        }
      }
    }
    
    // Find best and worst
    int maxIndex = 0;
    int minIndex = 0;
    int maxCount = dayCounts[0];
    int minCount = dayCounts[0];
    bool hasAnyData = dayCounts.any((c) => c > 0);
    
    if (!hasAnyData) {
      return {'best': 'N/A', 'worst': 'N/A'};
    }
    
    for (int i = 1; i < 7; i++) {
      if (dayCounts[i] > maxCount) {
        maxCount = dayCounts[i];
        maxIndex = i;
      }
      if (dayCounts[i] < minCount) {
        minCount = dayCounts[i];
        minIndex = i;
      }
    }
    
    return {
      'best': dayNames[maxIndex],
      'worst': dayNames[minIndex],
    };
  }

  Widget _buildDayCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
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
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 12),
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
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3436),
            ),
          ),
        ],
      ),
    );
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

// Simple stat card - EXACT from video
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Simple line chart painter
class _LineChartPainter extends CustomPainter {
  final List<double> values;
  final Color color;

  _LineChartPainter(this.values, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final path = Path();
    final width = size.width;
    final height = size.height;
    final stepX = width / (values.length - 1);
    
    for (int i = 0; i < values.length; i++) {
      final x = i * stepX;
      final y = height - (values[i] / 100 * height);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      
      // Draw dots
      canvas.drawCircle(Offset(x, y), 4, dotPaint);
    }
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
