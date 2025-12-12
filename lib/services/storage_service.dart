import 'package:hive_flutter/hive_flutter.dart';
import '../models/goal.dart';
import '../models/habit.dart';
import '../models/badge.dart';

class StorageService {
  static const String goalsBox = 'goals';
  static const String habitsBox = 'habits';
  static const String badgesBox = 'badges';
  static const String progressBox = 'progress';
  
  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Register adapters
    Hive.registerAdapter(GoalAdapter());
    Hive.registerAdapter(MilestoneAdapter());
    Hive.registerAdapter(HabitAdapter());
    Hive.registerAdapter(UserBadgeAdapter());
    Hive.registerAdapter(UserProgressAdapter());
    
    // Open boxes
    await Hive.openBox<Goal>(goalsBox);
    await Hive.openBox<Habit>(habitsBox);
    await Hive.openBox<UserBadge>(badgesBox);
    await Hive.openBox<UserProgress>(progressBox);
    
    // Initialize default badges if empty
    final badgeBox = Hive.box<UserBadge>(badgesBox);
    if (badgeBox.isEmpty) {
      final defaultBadges = BadgeDefinitions.getDefaultBadges();
      for (var badge in defaultBadges) {
        await badgeBox.put(badge.id, badge);
      }
    }
    
    // Initialize progress if empty
    final progressBoxData = Hive.box<UserProgress>(progressBox);
    if (progressBoxData.isEmpty) {
      await progressBoxData.put('user', UserProgress());
    }
  }
  
  // Goals methods
  static Box<Goal> get goals => Hive.box<Goal>(goalsBox);
  
  static Future<void> addGoal(Goal goal) async {
    await goals.put(goal.id, goal);
    await _addPoints(10);
    await _checkBadges();
  }
  
  static Future<void> updateGoal(Goal goal) async {
    await goals.put(goal.id, goal);
    if (goal.isCompleted) {
      await _addPoints(50);
      await _checkBadges();
    }
  }
  
  static Future<void> deleteGoal(String id) async {
    await goals.delete(id);
  }
  
  static List<Goal> getAllGoals() {
    return goals.values.toList()..sort((a, b) => a.deadline.compareTo(b.deadline));
  }
  
  static List<Goal> getActiveGoals() {
    return goals.values.where((g) => !g.isCompleted).toList()
      ..sort((a, b) => a.deadline.compareTo(b.deadline));
  }
  
  static List<Goal> getCompletedGoals() {
    return goals.values.where((g) => g.isCompleted).toList();
  }
  
  // Habits methods
  static Box<Habit> get habits => Hive.box<Habit>(habitsBox);
  
  static Future<void> addHabit(Habit habit) async {
    await habits.put(habit.id, habit);
    await _addPoints(10);
    await _checkBadges();
  }
  
  static Future<void> updateHabit(Habit habit) async {
    await habits.put(habit.id, habit);
    if (habit.currentStreak >= 7) {
      await _checkBadges();
    }
  }
  
  static Future<void> deleteHabit(String id) async {
    await habits.delete(id);
  }
  
  static List<Habit> getAllHabits() {
    return habits.values.where((h) => h.isActive).toList();
  }
  
  // Badges & Progress methods
  static Box<UserBadge> get badges => Hive.box<UserBadge>(badgesBox);
  static Box<UserProgress> get progress => Hive.box<UserProgress>(progressBox);
  
  static UserProgress getUserProgress() {
    return progress.get('user') ?? UserProgress();
  }
  
  static List<UserBadge> getAllBadges() {
    return badges.values.toList();
  }
  
  static List<UserBadge> getEarnedBadges() {
    return badges.values.where((b) => b.isEarned).toList();
  }
  
  static Future<void> _addPoints(int points) async {
    final userProgress = getUserProgress();
    userProgress.totalPoints += points;
    
    // Level up logic
    while (userProgress.totalPoints >= userProgress.pointsToNextLevel) {
      userProgress.level++;
    }
    
    await progress.put('user', userProgress);
  }
  
  static Future<void> _checkBadges() async {
    final goalCount = goals.length;
    final habitCount = habits.length;
    final maxStreak = habits.values.isEmpty 
        ? 0 
        : habits.values.map((h) => h.currentStreak).reduce((a, b) => a > b ? a : b);
    final completedGoals = goals.values.where((g) => g.isCompleted).length;
    
    final badgeChecks = {
      'first_goal': goalCount >= 1,
      'five_goals': goalCount >= 5,
      'first_habit': habitCount >= 1,
      'week_streak': maxStreak >= 7,
      'month_streak': maxStreak >= 30,
      'goal_complete': completedGoals >= 1,
    };
    
    for (var entry in badgeChecks.entries) {
      final badge = badges.get(entry.key);
      if (badge != null && !badge.isEarned && entry.value) {
        final updatedBadge = badge.copyWith(
          isEarned: true,
          earnedAt: DateTime.now(),
        );
        await badges.put(entry.key, updatedBadge);
        
        // Add badge points
        await _addPoints(badge.pointsRequired);
      }
    }
  }
  
  /// Clear ALL user data from all storage boxes
  static Future<void> clearAllData() async {
    await goals.clear();
    await habits.clear();
    
    // Reset badges to defaults
    await badges.clear();
    final defaultBadges = BadgeDefinitions.getDefaultBadges();
    for (var badge in defaultBadges) {
      await badges.put(badge.id, badge);
    }
    
    // Reset progress
    await progress.clear();
    await progress.put('user', UserProgress());
  }
  
  static Future<void> clearGoals() async {
    await goals.clear();
  }
  
  static Future<void> clearHabits() async {
    await habits.clear();
  }
  
  /// Get counts for all data types
  static Map<String, int> getDataCounts() {
    return {
      'goals': goals.length,
      'habits': habits.length,
      'badges': badges.length,
      'earnedBadges': badges.values.where((b) => b.isEarned).length,
    };
  }
}
