import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../widgets/beautiful_back_button.dart';
import 'goals_dashboard_screen.dart';
import 'habit_tracker_screen.dart';
import 'calendar_screen.dart';
import 'analytics_screen.dart';
import 'badges_screen.dart';
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
              // App Bar - EXACT from video
              _buildAppBar(context),
              
              // Menu List
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(AppTheme.screenPadding),
                  children: [
                    // Header - EXACT from video
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
                      'Set goals and build habits',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textWhite.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // 6 Menu Cards - EXACT from video
                    // 1. Goals
                    _PlanMenuCard(
                      icon: Icons.gps_fixed,
                      title: 'Goals',
                      subtitle: 'Set and track your targets',
                      gradient: AppTheme.goalsGradient,
                      onTap: () => _navigateTo(context, const GoalsDashboardScreen()),
                    ),
                    // 2. Habits
                    _PlanMenuCard(
                      icon: Icons.refresh,
                      title: 'Habits',
                      subtitle: 'Build daily routines',
                      gradient: AppTheme.habitsGradient,
                      onTap: () => _navigateTo(context, const HabitTrackerScreen()),
                    ),
                    // 3. Calendar
                    _PlanMenuCard(
                      icon: Icons.calendar_month,
                      title: 'Calendar',
                      subtitle: 'View your schedule',
                      gradient: AppTheme.calendarGradient,
                      onTap: () => _navigateTo(context, const CalendarScreen()),
                    ),
                    // 4. Analytics
                    _PlanMenuCard(
                      icon: Icons.show_chart,
                      title: 'Analytics',
                      subtitle: 'Track your progress',
                      gradient: AppTheme.analyticsGradient,
                      onTap: () => _navigateTo(context, const AnalyticsScreen()),
                    ),
                    // 5. Badges
                    _PlanMenuCard(
                      icon: Icons.workspace_premium,
                      title: 'Badges',
                      subtitle: 'Earn rewards',
                      gradient: AppTheme.badgesGradient,
                      onTap: () => _navigateTo(context, const BadgesScreen()),
                    ),
                    // 6. Weekly Review
                    _PlanMenuCard(
                      icon: Icons.rate_review,
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

// Menu Card Widget - EXACT from video (same style as Review 2025 cards)
class _PlanMenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _PlanMenuCard({
    required this.icon,
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
              // Icon - EXACT from video
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.textWhite,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              // Title & Subtitle - EXACT from video
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
              // Arrow - EXACT from video
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
