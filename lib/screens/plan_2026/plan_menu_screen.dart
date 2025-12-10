import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/beautiful_back_button.dart';
import 'goals_dashboard_screen.dart';
import 'habit_tracker_screen.dart';
import 'analytics_screen.dart';
import 'weekly_review_screen.dart';

class PlanMenuScreen extends StatelessWidget {
  const PlanMenuScreen({super.key});

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
                    // Calculate stats for overview
                    final activeGoals = provider.activeGoals.length;
                    final completedGoals = provider.completedGoals.length;
                    final habits = provider.habits;
                    final completedToday = habits.where((h) => h.isCompletedToday()).length;
                    final missedGoals = _getMissedGoalsCount(provider);
                    
                    return ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(AppTheme.screenPadding),
                      children: [
                        // Header
                        const Text(
                          'Plan 2026',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textWhite,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Apne khwab poore karein',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textWhite.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Quick Stats Overview
                        _buildQuickStats(activeGoals, completedGoals, completedToday, habits.length, missedGoals),
                        const SizedBox(height: 20),
                        
                        // Missed Goals Reminder (if any)
                        if (missedGoals > 0)
                          _buildMissedGoalsReminder(context, missedGoals),
                        
                        const SizedBox(height: 8),
                        
                        // Section Title
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'Features',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textWhite.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                        
                        // 1. Goals Tracker
                        _PlanMenuCard(
                          emoji: '🎯',
                          title: 'Goal Tracker',
                          subtitle: 'Set aur track karein apne goals',
                          stats: '$activeGoals active, $completedGoals completed',
                          gradient: AppTheme.goalsGradient,
                          onTap: () => _navigateTo(context, const GoalsDashboardScreen()),
                        ),
                        
                        // 2. Habit Tracker
                        _PlanMenuCard(
                          emoji: '🔄',
                          title: 'Habit Tracker',
                          subtitle: 'Daily habits aur streaks',
                          stats: '$completedToday/${habits.length} today',
                          gradient: AppTheme.habitsGradient,
                          onTap: () => _navigateTo(context, const HabitTrackerScreen()),
                        ),
                        
                        // 3. Weekly/Monthly Reports
                        _PlanMenuCard(
                          emoji: '📊',
                          title: 'Progress Reports',
                          subtitle: 'Weekly aur monthly summary',
                          stats: 'View your progress',
                          gradient: AppTheme.analyticsGradient,
                          onTap: () => _navigateTo(context, const AnalyticsScreen()),
                        ),
                        
                        // 4. Weekly Review
                        _PlanMenuCard(
                          emoji: '📝',
                          title: 'Weekly Review',
                          subtitle: 'Hafta review aur next week plan',
                          stats: 'Reflect & improve',
                          gradient: AppTheme.weeklyReviewGradient,
                          onTap: () => _navigateTo(context, const WeeklyReviewScreen()),
                        ),
                        
                        // 5. Reminders
                        _PlanMenuCard(
                          emoji: '🔔',
                          title: 'Reminders',
                          subtitle: 'Custom notifications set karein',
                          stats: 'Stay on track',
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                          ),
                          onTap: () => _showRemindersSheet(context),
                        ),
                        
                        const SizedBox(height: 20),
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

  int _getMissedGoalsCount(AppProvider provider) {
    int missed = 0;
    final now = DateTime.now();
    
    for (final goal in provider.activeGoals) {
      // Check if goal has deadline and is behind schedule
      final deadline = goal.deadline;
      if (deadline.isBefore(now)) {
        if (goal.currentValue < goal.targetValue) {
          missed++;
        }
      }
      // Also count goals with less than 20% progress that are older than 7 days
      final progress = goal.targetValue > 0 ? goal.currentValue / goal.targetValue : 0;
      if (progress < 0.2 && goal.createdAt.isBefore(now.subtract(const Duration(days: 7)))) {
        missed++;
      }
    }
    
    // Check habits not completed today
    for (final habit in provider.habits) {
      if (!habit.isCompletedToday() && habit.frequency == 'Daily') {
        // Count as missed if it's after noon
        if (now.hour >= 12) {
          missed++;
        }
      }
    }
    
    return missed;
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          const BeautifulBackButton(),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildQuickStats(int activeGoals, int completedGoals, int completedToday, int totalHabits, int missed) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.15),
            Colors.white.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _StatItem(
                icon: Icons.gps_fixed,
                value: '$activeGoals',
                label: 'Active Goals',
                color: AppTheme.primaryPurple,
              ),
              _StatItem(
                icon: Icons.check_circle,
                value: '$completedGoals',
                label: 'Completed',
                color: Colors.green,
              ),
              _StatItem(
                icon: Icons.local_fire_department,
                value: '$completedToday/$totalHabits',
                label: 'Habits Today',
                color: Colors.orange,
              ),
            ],
          ),
          if (missed > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.warning_amber, color: Colors.redAccent, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '$missed tasks need attention',
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
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

  Widget _buildMissedGoalsReminder(BuildContext context, int missedCount) {
    return GestureDetector(
      onTap: () => _showCatchUpDialog(context, missedCount),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6B6B).withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.notification_important, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Missed Tasks!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Aapne $missedCount tasks miss kiye. Catch up karein?',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Catch Up',
                style: TextStyle(
                  color: Color(0xFFFF6B6B),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCatchUpDialog(BuildContext context, int missedCount) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer<AppProvider>(
        builder: (context, provider, _) {
          final missedGoals = provider.activeGoals.where((g) {
            final progress = g.targetValue > 0 ? g.currentValue / g.targetValue : 0;
            return progress < 0.2;
          }).toList();
          
          final missedHabits = provider.habits.where((h) => 
            !h.isCompletedToday() && h.frequency == 'Daily'
          ).toList();
          
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                
                // Title
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Catch Up Time! 💪',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3436),
                    ),
                  ),
                ),
                
                // Content
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      if (missedGoals.isNotEmpty) ...[
                        const Text(
                          'Goals behind schedule:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF636E72),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...missedGoals.map((goal) => _buildCatchUpItem(
                          goal.name,
                          '${((goal.currentValue / goal.targetValue) * 100).toInt()}% complete',
                          Icons.gps_fixed,
                          AppTheme.categoryColors[goal.category] ?? AppTheme.primaryPurple,
                          () {
                            Navigator.pop(context);
                            _navigateTo(context, const GoalsDashboardScreen());
                          },
                        )),
                        const SizedBox(height: 20),
                      ],
                      
                      if (missedHabits.isNotEmpty) ...[
                        const Text(
                          'Habits not done today:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF636E72),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...missedHabits.map((habit) => _buildCatchUpItem(
                          habit.name,
                          '${habit.currentStreak} day streak at risk!',
                          Icons.loop,
                          AppTheme.primaryGreen,
                          () {
                            provider.toggleHabitCompletion(habit.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${habit.name} completed! 🎉'),
                                backgroundColor: AppTheme.primaryGreen,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        )),
                      ],
                      
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                
                // Close button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'Close',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF636E72),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCatchUpItem(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D3436),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Do Now',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRemindersSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            // Title
            const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Text('🔔', style: TextStyle(fontSize: 24)),
                  SizedBox(width: 10),
                  Text(
                    'Reminders',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3436),
                    ),
                  ),
                ],
              ),
            ),
            
            // Reminder Options
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildReminderOption(
                    '🌅',
                    'Morning Reminder',
                    'Subah 7 AM - Goals review',
                    true,
                    (val) {},
                  ),
                  _buildReminderOption(
                    '🏃',
                    'Exercise Reminder',
                    'Subah 8 AM - Workout time',
                    false,
                    (val) {},
                  ),
                  _buildReminderOption(
                    '📚',
                    'Study Reminder',
                    'Sham 6 PM - Learning time',
                    false,
                    (val) {},
                  ),
                  _buildReminderOption(
                    '🌙',
                    'Night Review',
                    'Raat 9 PM - Day review',
                    true,
                    (val) {},
                  ),
                  _buildReminderOption(
                    '📅',
                    'Weekly Check-in',
                    'Sunday 10 AM - Hafta review',
                    true,
                    (val) {},
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Custom Reminder
                  GestureDetector(
                    onTap: () => _showAddCustomReminder(context),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_circle_outline, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            'Add Custom Reminder',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderOption(String emoji, String title, String time, bool isEnabled, Function(bool) onChanged) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool enabled = isEnabled;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: enabled ? const Color(0xFFFF6B6B).withValues(alpha: 0.1) : Colors.grey[50],
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: enabled ? const Color(0xFFFF6B6B).withValues(alpha: 0.3) : Colors.grey[200]!,
            ),
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3436),
                      ),
                    ),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: enabled,
                onChanged: (val) {
                  setState(() => enabled = val);
                  onChanged(val);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(val ? '$title enabled' : '$title disabled'),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                activeTrackColor: const Color(0xFFFF6B6B).withValues(alpha: 0.5),
                thumbColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const Color(0xFFFF6B6B);
                  }
                  return Colors.grey;
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddCustomReminder(BuildContext context) {
    final titleController = TextEditingController();
    TimeOfDay selectedTime = TimeOfDay.now();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Custom Reminder'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Reminder Title',
                  hintText: 'e.g., Exercise, Study...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: Text('Time: ${selectedTime.format(context)}'),
                trailing: const Icon(Icons.edit),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: selectedTime,
                  );
                  if (time != null) {
                    setState(() => selectedTime = time);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  Navigator.pop(context);
                  Navigator.pop(context); // Close reminders sheet too
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Reminder set for ${selectedTime.format(context)}'),
                      backgroundColor: const Color(0xFFFF6B6B),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B6B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
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

// Stat Item Widget
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textWhite,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textWhite.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Menu Card Widget
class _PlanMenuCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final String stats;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _PlanMenuCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.stats,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 90,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Emoji Icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(14),
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
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textWhite,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textWhite.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stats,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textWhite.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              // Arrow
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios,
                  color: AppTheme.textWhite,
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
