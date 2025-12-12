import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import '../models/goal.dart';
import '../models/habit.dart';

class HomeWidgetService {
  static const String appGroupId = 'group.com.reflectplan.plan';
  static const String androidWidgetName = 'GoalProgressWidget';
  static const String iOSWidgetName = 'GoalProgressWidget';

  static Future<void> initialize() async {
    await HomeWidget.setAppGroupId(appGroupId);
  }

  /// Update the home widget with goal progress data
  static Future<void> updateGoalWidget({
    required List<Goal> goals,
    required List<Habit> habits,
  }) async {
    try {
      // Calculate overall stats
      final totalGoals = goals.length;
      final completedGoals = goals.where((g) => g.isCompleted).length;
      final activeGoals = totalGoals - completedGoals;
      
      // Get top goal (highest progress that's not complete)
      Goal? topGoal;
      if (goals.isNotEmpty) {
        final activeGoalsList = goals.where((g) => !g.isCompleted).toList();
        if (activeGoalsList.isNotEmpty) {
          activeGoalsList.sort((a, b) => b.progress.compareTo(a.progress));
          topGoal = activeGoalsList.first;
        }
      }
      
      // Calculate habit stats
      final totalHabits = habits.length;
      final completedToday = habits.where((h) => h.isCompletedToday()).length;
      final habitProgress = totalHabits > 0 ? (completedToday / totalHabits * 100).toInt() : 0;
      
      // Save data to widget
      await HomeWidget.saveWidgetData<int>('total_goals', totalGoals);
      await HomeWidget.saveWidgetData<int>('completed_goals', completedGoals);
      await HomeWidget.saveWidgetData<int>('active_goals', activeGoals);
      
      await HomeWidget.saveWidgetData<String>('top_goal_name', topGoal?.name ?? 'No active goals');
      await HomeWidget.saveWidgetData<int>('top_goal_progress', topGoal?.progress.toInt() ?? 0);
      await HomeWidget.saveWidgetData<String>('top_goal_category', topGoal?.category ?? '');
      
      await HomeWidget.saveWidgetData<int>('habit_progress', habitProgress);
      await HomeWidget.saveWidgetData<int>('habits_completed', completedToday);
      await HomeWidget.saveWidgetData<int>('habits_total', totalHabits);
      
      // Update the widget
      await HomeWidget.updateWidget(
        name: androidWidgetName,
        iOSName: iOSWidgetName,
      );
      
      debugPrint('Home widget updated successfully');
    } catch (e) {
      debugPrint('Error updating home widget: $e');
    }
  }

  /// Register callback for widget click
  static Future<void> registerInteractivityCallback() async {
    await HomeWidget.registerInteractivityCallback(backgroundCallback);
  }
}

/// Background callback for widget interactions
@pragma('vm:entry-point')
Future<void> backgroundCallback(Uri? uri) async {
  if (uri != null) {
    if (uri.host == 'open_goals') {
      // Will be handled by the app when it opens
      debugPrint('Widget clicked: open goals');
    } else if (uri.host == 'open_habits') {
      debugPrint('Widget clicked: open habits');
    }
  }
}
