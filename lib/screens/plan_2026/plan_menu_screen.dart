import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:math' as math;
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/beautiful_back_button.dart';
import '../../widgets/gamification_widgets.dart';
import '../../services/notification_service.dart';
import '../../models/reminder.dart';
import 'goals_dashboard_screen.dart';
import 'habit_tracker_screen.dart';
import 'analytics_screen.dart';
import 'weekly_review_screen.dart';

class PlanMenuScreen extends StatefulWidget {
  const PlanMenuScreen({super.key});

  @override
  State<PlanMenuScreen> createState() => _PlanMenuScreenState();
}

class _PlanMenuScreenState extends State<PlanMenuScreen> with TickerProviderStateMixin {
  late Box<Reminder> _remindersBox;
  List<Reminder> _reminders = [];
  bool _isLoading = true;
  late AnimationController _pulseController;
  
  // Motivational quotes
  final List<Map<String, String>> _quotes = [
    {'quote': 'Success is not final, failure is not fatal: it is the courage to continue that counts.', 'author': 'Winston Churchill'},
    {'quote': 'The only way to do great work is to love what you do.', 'author': 'Steve Jobs'},
    {'quote': 'Believe you can and you\'re halfway there.', 'author': 'Theodore Roosevelt'},
    {'quote': 'It does not matter how slowly you go as long as you do not stop.', 'author': 'Confucius'},
    {'quote': 'The future belongs to those who believe in the beauty of their dreams.', 'author': 'Eleanor Roosevelt'},
    {'quote': 'Your limitation—it\'s only your imagination.', 'author': 'Unknown'},
    {'quote': 'Push yourself, because no one else is going to do it for you.', 'author': 'Unknown'},
    {'quote': 'Great things never come from comfort zones.', 'author': 'Unknown'},
  ];
  
  // Daily tips
  final List<Map<String, String>> _tips = [
    {'tip': 'Start your day by reviewing your goals for 5 minutes', 'category': '🎯 Goal Tip'},
    {'tip': 'Break big goals into smaller, manageable tasks', 'category': '📋 Productivity'},
    {'tip': 'Celebrate small wins to stay motivated', 'category': '🎉 Motivation'},
    {'tip': 'Track your habits at the same time each day', 'category': '⏰ Consistency'},
    {'tip': 'Review your progress weekly for better insights', 'category': '📊 Analytics'},
    {'tip': 'Focus on progress, not perfection', 'category': '💪 Mindset'},
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _initReminders();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initReminders() async {
    _remindersBox = await Hive.openBox<Reminder>('reminders');
    
    if (_remindersBox.isEmpty) {
      final defaults = PresetReminders.getDefaults();
      for (var reminder in defaults) {
        await _remindersBox.put(reminder.id, reminder);
      }
    }
    
    setState(() {
      _reminders = _remindersBox.values.toList();
      _isLoading = false;
    });
  }

  // Calculate XP and Level from user activity
  Map<String, int> _calculateXPAndLevel(AppProvider provider) {
    int xp = 0;
    
    // XP from completed goals (100 XP each)
    xp += provider.completedGoals.length * 100;
    
    // XP from habits completed today (20 XP each)
    xp += provider.habits.where((h) => h.isCompletedToday()).length * 20;
    
    // XP from habit streaks (5 XP per day streak)
    for (var habit in provider.habits) {
      xp += habit.currentStreak * 5;
    }
    
    // XP from weekly reviews (50 XP each)
    xp += provider.weeklyReviews.length * 50;
    
    // Calculate level (100 XP per level, increasing)
    int level = 1;
    int xpForNextLevel = 100;
    int remainingXP = xp;
    
    while (remainingXP >= xpForNextLevel) {
      remainingXP -= xpForNextLevel;
      level++;
      xpForNextLevel = level * 100;
    }
    
    return {
      'level': level,
      'currentXP': remainingXP,
      'xpForNextLevel': xpForNextLevel,
      'totalXP': xp,
    };
  }

  // Get today's motivational quote
  Map<String, String> _getTodaysQuote() {
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    return _quotes[dayOfYear % _quotes.length];
  }

  // Get today's tip
  Map<String, String> _getTodaysTip() {
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    return _tips[dayOfYear % _tips.length];
  }

  @override
  Widget build(BuildContext context) {
    final todaysQuote = _getTodaysQuote();
    final todaysTip = _getTodaysTip();
    
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
                    final xpData = _calculateXPAndLevel(provider);
                    final activeGoals = provider.activeGoals.length;
                    final completedGoals = provider.completedGoals.length;
                    final habits = provider.habits;
                    final completedToday = habits.where((h) => h.isCompletedToday()).length;
                    final missedGoals = _getMissedGoalsCount(provider);
                    final totalStreak = habits.fold(0, (sum, h) => sum + h.currentStreak);
                    final bestStreak = habits.isEmpty ? 0 : habits.map((h) => h.bestStreak).reduce(math.max);
                    
                    return ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(AppTheme.screenPadding),
                      children: [
                        // Animated Header
                        _buildAnimatedHeader(xpData['level']!),
                        const SizedBox(height: 16),
                        
                        // XP Progress Bar
                        XPProgressBar(
                          currentXP: xpData['currentXP']!,
                          xpForNextLevel: xpData['xpForNextLevel']!,
                          level: xpData['level']!,
                        ),
                        const SizedBox(height: 20),
                        
                        // Progress Rings Section
                        _buildProgressRings(
                          activeGoals,
                          completedGoals,
                          completedToday,
                          habits.length,
                          totalStreak,
                        ),
                        const SizedBox(height: 20),
                        
                        // Daily Tip
                        DailyTipCard(
                          tip: todaysTip['tip']!,
                          category: todaysTip['category']!,
                        ),
                        const SizedBox(height: 16),
                        
                        // Streak Fire Banner (if user has streaks)
                        if (bestStreak > 0)
                          _buildStreakBanner(bestStreak, totalStreak),
                        
                        // Missed Goals Reminder
                        if (missedGoals > 0) ...[
                          const SizedBox(height: 16),
                          _buildMissedGoalsReminder(context, missedGoals),
                        ],
                        
                        const SizedBox(height: 20),
                        
                        // Achievement Badges
                        _buildAchievementBadges(provider),
                        const SizedBox(height: 20),
                        
                        // Features Section Title
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              const Text(
                                'Features',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textWhite,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${xpData['totalXP']} XP Total',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Feature Cards
                        _PlanMenuCard(
                          emoji: '🎯',
                          title: 'Goal Tracker',
                          subtitle: 'Set aur track karein apne goals',
                          stats: '$activeGoals active, $completedGoals completed',
                          gradient: AppTheme.goalsGradient,
                          badge: completedGoals > 0 ? '+${completedGoals * 100} XP' : null,
                          onTap: () => _navigateTo(context, const GoalsDashboardScreen()),
                        ),
                        
                        _PlanMenuCard(
                          emoji: '🔄',
                          title: 'Habit Tracker',
                          subtitle: 'Daily habits with streak tracking',
                          stats: '$completedToday/${habits.length} today • 🔥 $bestStreak best streak',
                          gradient: AppTheme.habitsGradient,
                          badge: completedToday > 0 ? '+${completedToday * 20} XP' : null,
                          onTap: () => _navigateTo(context, const HabitTrackerScreen()),
                        ),
                        
                        _PlanMenuCard(
                          emoji: '📊',
                          title: 'Progress Reports',
                          subtitle: 'Analytics aur insights dekhen',
                          stats: 'Weekly & monthly summary',
                          gradient: AppTheme.analyticsGradient,
                          onTap: () => _navigateTo(context, const AnalyticsScreen()),
                        ),
                        
                        _PlanMenuCard(
                          emoji: '📝',
                          title: 'Weekly Review',
                          subtitle: 'Hafta review aur planning',
                          stats: '${provider.weeklyReviews.length} reviews • +50 XP each',
                          gradient: AppTheme.weeklyReviewGradient,
                          onTap: () => _navigateTo(context, const WeeklyReviewScreen()),
                        ),
                        
                        _PlanMenuCard(
                          emoji: '🔔',
                          title: 'Reminders',
                          subtitle: 'Smart notifications set karein',
                          stats: '${_reminders.where((r) => r.isEnabled).length} active reminders',
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                          ),
                          onTap: () => _showRemindersSheet(context),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Motivational Quote
                        MotivationalQuoteCard(
                          quote: todaysQuote['quote']!,
                          author: todaysQuote['author']!,
                        ),
                        
                        const SizedBox(height: 30),
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

  Widget _buildAnimatedHeader(int level) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Plan 2026',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textWhite,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Transform.scale(
                        scale: 1 + (_pulseController.value * 0.1),
                        child: Text(
                          _getLevelEmoji(level),
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Apne khwab poore karein 💫',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textWhite.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _getLevelEmoji(int level) {
    if (level >= 20) return '🏆';
    if (level >= 15) return '👑';
    if (level >= 10) return '💎';
    if (level >= 5) return '🔥';
    if (level >= 2) return '⭐';
    return '🌱';
  }

  Widget _buildProgressRings(int activeGoals, int completedGoals, int completedToday, int totalHabits, int totalStreak) {
    final goalProgress = (activeGoals + completedGoals) > 0 
        ? completedGoals / (activeGoals + completedGoals) 
        : 0.0;
    final habitProgress = totalHabits > 0 ? completedToday / totalHabits : 0.0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Today\'s Progress',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3436),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ProgressRing(
                progress: goalProgress,
                size: 90,
                color: const Color(0xFF6C63FF),
                centerText: '${(goalProgress * 100).toInt()}%',
                subtitle: 'Goals',
              ),
              ProgressRing(
                progress: habitProgress,
                size: 90,
                color: const Color(0xFF00C853),
                centerText: '$completedToday/$totalHabits',
                subtitle: 'Habits',
              ),
              Column(
                children: [
                  StreakFireIcon(streak: totalStreak, size: 50),
                  const SizedBox(height: 8),
                  Text(
                    '$totalStreak',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  Text(
                    'Total Streak',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStreakBanner(int bestStreak, int totalStreak) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const StreakFireIcon(streak: 10, size: 45),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'You\'re on Fire! 🔥',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Best streak: $bestStreak days • Total: $totalStreak days',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementBadges(AppProvider provider) {
    final completedGoals = provider.completedGoals.length;
    final habits = provider.habits;
    final bestStreak = habits.isEmpty ? 0 : habits.map((h) => h.bestStreak).reduce(math.max);
    final reviews = provider.weeklyReviews.length;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Achievements',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textWhite,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              AchievementBadge(
                emoji: '🎯',
                title: 'First Goal',
                isEarned: completedGoals >= 1,
                description: 'Complete your first goal',
              ),
              const SizedBox(width: 10),
              AchievementBadge(
                emoji: '🏆',
                title: '5 Goals',
                isEarned: completedGoals >= 5,
                description: 'Complete 5 goals',
              ),
              const SizedBox(width: 10),
              AchievementBadge(
                emoji: '🔥',
                title: '7 Day Streak',
                isEarned: bestStreak >= 7,
                description: '7 day habit streak',
              ),
              const SizedBox(width: 10),
              AchievementBadge(
                emoji: '💎',
                title: '30 Day Streak',
                isEarned: bestStreak >= 30,
                description: '30 day habit streak',
              ),
              const SizedBox(width: 10),
              AchievementBadge(
                emoji: '📝',
                title: 'Reviewer',
                isEarned: reviews >= 4,
                description: 'Complete 4 weekly reviews',
              ),
              const SizedBox(width: 10),
              AchievementBadge(
                emoji: '⭐',
                title: 'Superstar',
                isEarned: completedGoals >= 10 && bestStreak >= 14,
                description: '10 goals + 14 day streak',
              ),
            ],
          ),
        ),
      ],
    );
  }

  int _getMissedGoalsCount(AppProvider provider) {
    int missed = 0;
    final now = DateTime.now();
    
    for (final goal in provider.activeGoals) {
      final deadline = goal.deadline;
      if (deadline.isBefore(now)) {
        if (goal.currentValue < goal.targetValue) {
          missed++;
        }
      }
      final progress = goal.targetValue > 0 ? goal.currentValue / goal.targetValue : 0;
      if (progress < 0.2 && goal.createdAt.isBefore(now.subtract(const Duration(days: 7)))) {
        missed++;
      }
    }
    
    for (final habit in provider.habits) {
      if (!habit.isCompletedToday() && habit.frequency == 'Daily') {
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
                    'Catch Up Time! 💪',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$missedCount tasks need your attention',
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
                'Fix Now',
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
                                content: Text('${habit.name} completed! +20 XP 🎉'),
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

  Future<void> _toggleReminder(Reminder reminder, bool enabled) async {
    final notificationService = NotificationService();
    
    if (enabled) {
      final hasPermission = await notificationService.requestPermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enable notifications in settings'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
    }
    
    final updated = reminder.copyWith(isEnabled: enabled);
    await _remindersBox.put(reminder.id, updated);
    
    if (enabled) {
      if (reminder.frequency == 'weekly' && reminder.weekday != null) {
        await notificationService.scheduleWeeklyReminder(
          id: reminder.id,
          title: '${reminder.emoji} ${reminder.title}',
          body: reminder.description,
          weekday: reminder.weekday!,
          time: TimeOfDay(hour: reminder.hour, minute: reminder.minute),
          payload: 'reminder_${reminder.id}',
        );
      } else {
        await notificationService.scheduleDailyReminder(
          id: reminder.id,
          title: '${reminder.emoji} ${reminder.title}',
          body: reminder.description,
          time: TimeOfDay(hour: reminder.hour, minute: reminder.minute),
          payload: 'reminder_${reminder.id}',
        );
      }
      
      await notificationService.showNotification(
        id: 9999,
        title: '✅ Reminder Set!',
        body: '${reminder.title} - ${reminder.scheduleDescription}',
      );
    } else {
      await notificationService.cancelReminder(reminder.id);
    }
    
    setState(() {
      _reminders = _remindersBox.values.toList();
    });
  }

  Future<void> _deleteReminder(Reminder reminder) async {
    if (reminder.isPreset) return;
    
    await NotificationService().cancelReminder(reminder.id);
    await _remindersBox.delete(reminder.id);
    
    setState(() {
      _reminders = _remindersBox.values.toList();
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${reminder.title} deleted'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showRemindersSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text('🔔', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Smart Reminders',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3436),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C853).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_reminders.where((r) => r.isEnabled).length} active',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF00C853),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          ..._reminders.where((r) => r.isPreset).map((reminder) =>
                            _buildReminderOption(
                              reminder,
                              (enabled) async {
                                await _toggleReminder(reminder, enabled);
                                setSheetState(() {});
                              },
                            ),
                          ),
                          if (_reminders.any((r) => !r.isPreset)) ...[
                            const SizedBox(height: 16),
                            const Text(
                              'Custom Reminders',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF636E72),
                              ),
                            ),
                            const SizedBox(height: 12),
                            ..._reminders.where((r) => !r.isPreset).map((reminder) =>
                              _buildReminderOption(
                                reminder,
                                (enabled) async {
                                  await _toggleReminder(reminder, enabled);
                                  setSheetState(() {});
                                },
                                showDelete: true,
                                onDelete: () async {
                                  await _deleteReminder(reminder);
                                  setSheetState(() {});
                                },
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          GestureDetector(
                            onTap: () => _showAddCustomReminder(context, setSheetState),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF6C63FF).withValues(alpha: 0.1),
                                    const Color(0xFF6C63FF).withValues(alpha: 0.05),
                                  ],
                                ),
                                border: Border.all(color: const Color(0xFF6C63FF).withValues(alpha: 0.3)),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_circle, color: Color(0xFF6C63FF)),
                                  SizedBox(width: 8),
                                  Text(
                                    'Add Custom Reminder',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF6C63FF),
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
      ),
    );
  }

  Widget _buildReminderOption(
    Reminder reminder,
    Function(bool) onChanged, {
    bool showDelete = false,
    VoidCallback? onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: reminder.isEnabled ? const Color(0xFF6C63FF).withValues(alpha: 0.1) : Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: reminder.isEnabled ? const Color(0xFF6C63FF).withValues(alpha: 0.3) : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          Text(reminder.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3436),
                  ),
                ),
                Text(
                  reminder.scheduleDescription,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (showDelete && onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
              onPressed: onDelete,
            ),
          Switch(
            value: reminder.isEnabled,
            onChanged: (val) {
              onChanged(val);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(val 
                    ? '${reminder.title} enabled ✅'
                    : '${reminder.title} disabled'),
                  backgroundColor: val ? const Color(0xFF00C853) : Colors.grey,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            activeTrackColor: const Color(0xFF6C63FF).withValues(alpha: 0.5),
            thumbColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const Color(0xFF6C63FF);
              }
              return Colors.grey;
            }),
          ),
        ],
      ),
    );
  }

  void _showAddCustomReminder(BuildContext context, StateSetter setSheetState) {
    final titleController = TextEditingController();
    int selectedHour = TimeOfDay.now().hourOfPeriod;
    if (selectedHour == 0) selectedHour = 12;
    int selectedMinute = TimeOfDay.now().minute;
    bool isAM = TimeOfDay.now().period == DayPeriod.am;
    String selectedFrequency = 'daily';
    int? selectedWeekday;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Convert to TimeOfDay for saving
          TimeOfDay getSelectedTime() {
            int hour24 = selectedHour;
            if (selectedHour == 12) {
              hour24 = isAM ? 0 : 12;
            } else {
              hour24 = isAM ? selectedHour : selectedHour + 12;
            }
            return TimeOfDay(hour: hour24, minute: selectedMinute);
          }
          
          String getTimeString() {
            final h = selectedHour == 0 ? 12 : selectedHour;
            final m = selectedMinute.toString().padLeft(2, '0');
            return '$h:$m ${isAM ? "AM" : "PM"}';
          }
          
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
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
                  
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6C63FF), Color(0xFF5B52CC)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.alarm_add, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Create Reminder',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D3436),
                                ),
                              ),
                              Text(
                                'Set your perfect time',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF636E72),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const Divider(height: 1),
                  
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title Input
                        const Text(
                          'Reminder Name',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2D3436),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: titleController,
                          decoration: InputDecoration(
                            hintText: 'e.g., Exercise, Meditation, Study...',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            filled: true,
                            fillColor: const Color(0xFFF8F9FA),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
                            ),
                            prefixIcon: const Icon(Icons.edit_outlined, color: Color(0xFF6C63FF)),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Time Selection - Premium Design
                        const Text(
                          'Select Time',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2D3436),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Beautiful Time Picker
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFF6C63FF).withValues(alpha: 0.08),
                                const Color(0xFF6C63FF).withValues(alpha: 0.03),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            children: [
                              // Hour : Minute : AM/PM Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Hour Picker
                                  _buildTimePickerColumn(
                                    value: selectedHour,
                                    maxValue: 12,
                                    minValue: 1,
                                    onIncrease: () => setDialogState(() {
                                      selectedHour = selectedHour >= 12 ? 1 : selectedHour + 1;
                                    }),
                                    onDecrease: () => setDialogState(() {
                                      selectedHour = selectedHour <= 1 ? 12 : selectedHour - 1;
                                    }),
                                    label: 'Hour',
                                  ),
                                  
                                  // Colon
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8),
                                    child: Text(
                                      ':',
                                      style: TextStyle(
                                        fontSize: 40,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF6C63FF),
                                      ),
                                    ),
                                  ),
                                  
                                  // Minute Picker
                                  _buildTimePickerColumn(
                                    value: selectedMinute,
                                    maxValue: 59,
                                    minValue: 0,
                                    onIncrease: () => setDialogState(() {
                                      selectedMinute = selectedMinute >= 59 ? 0 : selectedMinute + 1;
                                    }),
                                    onDecrease: () => setDialogState(() {
                                      selectedMinute = selectedMinute <= 0 ? 59 : selectedMinute - 1;
                                    }),
                                    label: 'Minute',
                                    padZero: true,
                                  ),
                                  
                                  const SizedBox(width: 16),
                                  
                                  // AM/PM Toggle
                                  _buildAmPmToggle(
                                    isAM: isAM,
                                    onToggle: (val) => setDialogState(() => isAM = val),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 12),
                              
                              // Time Display
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6C63FF),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  getTimeString(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Frequency Selection
                        const Text(
                          'Repeat',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2D3436),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildFrequencyOption(
                                title: 'Daily',
                                emoji: '📅',
                                isSelected: selectedFrequency == 'daily',
                                onTap: () => setDialogState(() {
                                  selectedFrequency = 'daily';
                                  selectedWeekday = null;
                                }),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildFrequencyOption(
                                title: 'Weekly',
                                emoji: '🗓️',
                                isSelected: selectedFrequency == 'weekly',
                                onTap: () => setDialogState(() {
                                  selectedFrequency = 'weekly';
                                  selectedWeekday ??= DateTime.now().weekday;
                                }),
                              ),
                            ),
                          ],
                        ),
                        
                        // Weekday selector for weekly
                        if (selectedFrequency == 'weekly') ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Select Day',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D3436),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildWeekdayChip('Mon', 1, selectedWeekday, (d) => setDialogState(() => selectedWeekday = d)),
                                _buildWeekdayChip('Tue', 2, selectedWeekday, (d) => setDialogState(() => selectedWeekday = d)),
                                _buildWeekdayChip('Wed', 3, selectedWeekday, (d) => setDialogState(() => selectedWeekday = d)),
                                _buildWeekdayChip('Thu', 4, selectedWeekday, (d) => setDialogState(() => selectedWeekday = d)),
                                _buildWeekdayChip('Fri', 5, selectedWeekday, (d) => setDialogState(() => selectedWeekday = d)),
                                _buildWeekdayChip('Sat', 6, selectedWeekday, (d) => setDialogState(() => selectedWeekday = d)),
                                _buildWeekdayChip('Sun', 7, selectedWeekday, (d) => setDialogState(() => selectedWeekday = d)),
                              ],
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 24),
                        
                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (titleController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please enter a reminder name'),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                return;
                              }
                              Navigator.pop(sheetContext);
                              await _addCustomReminderWithFrequency(
                                titleController.text,
                                getSelectedTime(),
                                selectedFrequency,
                                selectedWeekday,
                              );
                              setSheetState(() {});
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6C63FF),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 4,
                              shadowColor: const Color(0xFF6C63FF).withValues(alpha: 0.4),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'Save Reminder',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Cancel Button
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildTimePickerColumn({
    required int value,
    required int maxValue,
    required int minValue,
    required VoidCallback onIncrease,
    required VoidCallback onDecrease,
    required String label,
    bool padZero = false,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onIncrease,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.keyboard_arrow_up, color: Color(0xFF6C63FF)),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 60,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            padZero ? value.toString().padLeft(2, '0') : value.toString(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3436),
            ),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onDecrease,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF6C63FF)),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }
  
  Widget _buildAmPmToggle({
    required bool isAM,
    required Function(bool) onToggle,
  }) {
    return Column(
      children: [
        const SizedBox(height: 24), // Align with time columns
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              GestureDetector(
                onTap: () => onToggle(true),
                child: Container(
                  width: 60,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: isAM
                        ? const LinearGradient(
                            colors: [Color(0xFF6C63FF), Color(0xFF5B52CC)],
                          )
                        : null,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                  ),
                  child: Text(
                    'AM',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isAM ? Colors.white : Colors.grey[400],
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => onToggle(false),
                child: Container(
                  width: 60,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: !isAM
                        ? const LinearGradient(
                            colors: [Color(0xFF6C63FF), Color(0xFF5B52CC)],
                          )
                        : null,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                  ),
                  child: Text(
                    'PM',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: !isAM ? Colors.white : Colors.grey[400],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Period',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }
  
  Widget _buildFrequencyOption({
    required String title,
    required String emoji,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF5B52CC)],
                )
              : null,
          color: isSelected ? null : const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF2D3436),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildWeekdayChip(String label, int day, int? selectedDay, Function(int) onSelect) {
    final isSelected = selectedDay == day;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => onSelect(day),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF5B52CC)],
                  )
                : null,
            color: isSelected ? null : const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? Colors.transparent : Colors.grey[300]!,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF2D3436),
            ),
          ),
        ),
      ),
    );
  }
  
  Future<void> _addCustomReminderWithFrequency(String title, TimeOfDay time, String frequency, int? weekday) async {
    final notificationService = NotificationService();
    
    final hasPermission = await notificationService.requestPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enable notifications in settings'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    
    final timeString = '${time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod}:${time.minute.toString().padLeft(2, '0')} ${time.period == DayPeriod.am ? 'AM' : 'PM'}';
    final id = 2000 + DateTime.now().millisecondsSinceEpoch % 1000;
    
    final reminder = Reminder(
      id: id,
      title: title,
      description: frequency == 'weekly' && weekday != null 
          ? 'Weekly reminder - $timeString'
          : 'Daily reminder - $timeString',
      hour: time.hour,
      minute: time.minute,
      isEnabled: true,
      emoji: '⏰',
      frequency: frequency,
      weekday: frequency == 'weekly' ? weekday : null,
      isPreset: false,
      createdAt: DateTime.now(),
    );
    
    await _remindersBox.put(id, reminder);
    
    if (frequency == 'weekly' && weekday != null) {
      await notificationService.scheduleWeeklyReminder(
        id: id,
        title: '⏰ $title',
        body: 'Time for: $title',
        weekday: weekday,
        time: time,
        payload: 'custom_reminder_$id',
      );
    } else {
      await notificationService.scheduleDailyReminder(
        id: id,
        title: '⏰ $title',
        body: 'Time for: $title',
        time: time,
        payload: 'custom_reminder_$id',
      );
    }
    
    final days = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    await notificationService.showNotification(
      id: 9998,
      title: '✅ Reminder Set!',
      body: frequency == 'weekly' && weekday != null
          ? '$title - ${days[weekday]} at $timeString'
          : '$title - Daily at $timeString',
    );
    
    setState(() {
      _reminders = _remindersBox.values.toList();
    });
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}

// Menu Card Widget with XP Badge
class _PlanMenuCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final String stats;
  final LinearGradient gradient;
  final VoidCallback onTap;
  final String? badge;

  const _PlanMenuCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.stats,
    required this.gradient,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 95,
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 28)),
                    ),
                  ),
                  const SizedBox(width: 16),
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
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios,
                      color: AppTheme.textWhite,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
            // XP Badge
            if (badge != null)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: gradient.colors.first,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
