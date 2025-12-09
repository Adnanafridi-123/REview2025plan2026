import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../widgets/beautiful_back_button.dart';
import 'goals_dashboard_screen.dart';
import 'habit_tracker_screen.dart';
import 'calendar_screen.dart';
import 'analytics_screen.dart';
import 'badges_screen.dart';
import 'weekly_review_screen.dart';
import 'vision_board_screen.dart';
import 'health_tracker_screen.dart';
import 'financial_goals_screen.dart';
import 'bucket_list_screen.dart';
import 'gratitude_journal_screen.dart';

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
              // App Bar
              _buildAppBar(context),
              
              // Menu List
              Expanded(
                child: ListView(
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
                    const SizedBox(height: 24),
                    
                    // ⭐ NEW: Vision Board
                    _PlanMenuCard(
                      emoji: '📌',
                      title: 'Vision Board',
                      subtitle: 'Apne khwab visualize karein',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      ),
                      onTap: () => _navigateTo(context, const VisionBoardScreen()),
                    ),
                    
                    // ⭐ NEW: Health Tracker
                    _PlanMenuCard(
                      emoji: '🏃',
                      title: 'Health Tracker',
                      subtitle: 'Paani, neend, exercise track karein',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00C9FF), Color(0xFF92FE9D)],
                      ),
                      onTap: () => _navigateTo(context, const HealthTrackerScreen()),
                    ),
                    
                    // ⭐ NEW: Financial Goals
                    _PlanMenuCard(
                      emoji: '💰',
                      title: 'Financial Goals',
                      subtitle: 'Savings aur budget track karein',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
                      ),
                      onTap: () => _navigateTo(context, const FinancialGoalsScreen()),
                    ),
                    
                    // ⭐ NEW: Bucket List
                    _PlanMenuCard(
                      emoji: '✨',
                      title: 'Bucket List',
                      subtitle: 'Zindagi ke khwab poore karein',
                      gradient: const LinearGradient(
                        colors: [Color(0xFFf857a6), Color(0xFFff5858)],
                      ),
                      onTap: () => _navigateTo(context, const BucketListScreen()),
                    ),
                    
                    // ⭐ NEW: Gratitude Journal
                    _PlanMenuCard(
                      emoji: '🙏',
                      title: 'Gratitude Journal',
                      subtitle: 'Rozana shukar guzar hon',
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFA726), Color(0xFFFF7043)],
                      ),
                      onTap: () => _navigateTo(context, const GratitudeJournalScreen()),
                    ),
                    
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Expanded(child: Divider(color: Colors.white24)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'Core Features',
                              style: TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.white24)),
                        ],
                      ),
                    ),
                    
                    // 1. Goals
                    _PlanMenuCard(
                      emoji: '🎯',
                      title: 'Goals',
                      subtitle: 'Set and track your targets',
                      gradient: AppTheme.goalsGradient,
                      onTap: () => _navigateTo(context, const GoalsDashboardScreen()),
                    ),
                    // 2. Habits
                    _PlanMenuCard(
                      emoji: '🔄',
                      title: 'Habits',
                      subtitle: 'Build daily routines',
                      gradient: AppTheme.habitsGradient,
                      onTap: () => _navigateTo(context, const HabitTrackerScreen()),
                    ),
                    // 3. Calendar
                    _PlanMenuCard(
                      emoji: '📅',
                      title: 'Calendar',
                      subtitle: 'View your schedule',
                      gradient: AppTheme.calendarGradient,
                      onTap: () => _navigateTo(context, const CalendarScreen()),
                    ),
                    // 4. Analytics
                    _PlanMenuCard(
                      emoji: '📊',
                      title: 'Analytics',
                      subtitle: 'Track your progress',
                      gradient: AppTheme.analyticsGradient,
                      onTap: () => _navigateTo(context, const AnalyticsScreen()),
                    ),
                    // 5. Badges
                    _PlanMenuCard(
                      emoji: '🏆',
                      title: 'Badges',
                      subtitle: 'Earn rewards',
                      gradient: AppTheme.badgesGradient,
                      onTap: () => _navigateTo(context, const BadgesScreen()),
                    ),
                    // 6. Weekly Review
                    _PlanMenuCard(
                      emoji: '📝',
                      title: 'Weekly Review',
                      subtitle: 'Reflect and plan ahead',
                      gradient: AppTheme.weeklyReviewGradient,
                      onTap: () => _navigateTo(context, const WeeklyReviewScreen()),
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

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}

// Menu Card Widget - Updated with emoji support
class _PlanMenuCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _PlanMenuCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: AppTheme.menuCardHeight,
        margin: const EdgeInsets.only(bottom: AppTheme.cardSpacing),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
              const SizedBox(width: 16),
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
                        color: AppTheme.textWhite,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textWhite.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              // Arrow
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
      ),
    );
  }
}
