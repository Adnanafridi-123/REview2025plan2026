import 'package:hive_flutter/hive_flutter.dart';
import '../models/journal_entry.dart';
import '../models/goal.dart';
import '../models/habit.dart';
import '../models/achievement.dart';
import '../models/screenshot_item.dart';
import '../models/weekly_review.dart';
import '../models/badge.dart';

class StorageService {
  static const String journalBox = 'journals';
  static const String goalsBox = 'goals';
  static const String habitsBox = 'habits';
  static const String achievementsBox = 'achievements';
  static const String screenshotsBox = 'screenshots';
  static const String weeklyReviewsBox = 'weekly_reviews';
  static const String badgesBox = 'badges';
  static const String progressBox = 'progress';
  
  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Register adapters
    Hive.registerAdapter(JournalEntryAdapter());
    Hive.registerAdapter(GoalAdapter());
    Hive.registerAdapter(MilestoneAdapter());
    Hive.registerAdapter(HabitAdapter());
    Hive.registerAdapter(AchievementAdapter());
    Hive.registerAdapter(ScreenshotItemAdapter());
    Hive.registerAdapter(WeeklyReviewAdapter());
    Hive.registerAdapter(UserBadgeAdapter());
    Hive.registerAdapter(UserProgressAdapter());
    
    // Open boxes
    await Hive.openBox<JournalEntry>(journalBox);
    await Hive.openBox<Goal>(goalsBox);
    await Hive.openBox<Habit>(habitsBox);
    await Hive.openBox<Achievement>(achievementsBox);
    await Hive.openBox<ScreenshotItem>(screenshotsBox);
    await Hive.openBox<WeeklyReview>(weeklyReviewsBox);
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
  
  // Journal methods
  static Box<JournalEntry> get journals => Hive.box<JournalEntry>(journalBox);
  
  static Future<void> addJournal(JournalEntry entry) async {
    await journals.put(entry.id, entry);
    await _addPoints(10);
    await _checkBadges();
  }
  
  static Future<void> updateJournal(JournalEntry entry) async {
    await journals.put(entry.id, entry);
  }
  
  static Future<void> deleteJournal(String id) async {
    await journals.delete(id);
  }
  
  static List<JournalEntry> getAllJournals() {
    return journals.values.toList()..sort((a, b) => b.date.compareTo(a.date));
  }
  
  static List<JournalEntry> getJournalsFor2025() {
    return journals.values
        .where((j) => j.date.year == 2025)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
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
  
  // Achievements methods
  static Box<Achievement> get achievements => Hive.box<Achievement>(achievementsBox);
  
  static Future<void> addAchievement(Achievement achievement) async {
    await achievements.put(achievement.id, achievement);
    await _addPoints(20);
    await _checkBadges();
  }
  
  static Future<void> updateAchievement(Achievement achievement) async {
    await achievements.put(achievement.id, achievement);
  }
  
  static Future<void> deleteAchievement(String id) async {
    await achievements.delete(id);
  }
  
  static List<Achievement> getAllAchievements() {
    return achievements.values.toList()..sort((a, b) => b.date.compareTo(a.date));
  }
  
  static List<Achievement> getAchievementsFor2025() {
    return achievements.values
        .where((a) => a.date.year == 2025)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }
  
  // Screenshots methods
  static Box<ScreenshotItem> get screenshots => Hive.box<ScreenshotItem>(screenshotsBox);
  
  static Future<void> addScreenshot(ScreenshotItem screenshot) async {
    await screenshots.put(screenshot.id, screenshot);
  }
  
  static Future<void> deleteScreenshot(String id) async {
    await screenshots.delete(id);
  }
  
  static List<ScreenshotItem> getAllScreenshots() {
    return screenshots.values.toList()..sort((a, b) => b.date.compareTo(a.date));
  }
  
  // Weekly Reviews methods
  static Box<WeeklyReview> get weeklyReviews => Hive.box<WeeklyReview>(weeklyReviewsBox);
  
  static Future<void> addWeeklyReview(WeeklyReview review) async {
    await weeklyReviews.put(review.id, review);
    await _addPoints(25);
    await _checkBadges();
  }
  
  static Future<void> updateWeeklyReview(WeeklyReview review) async {
    await weeklyReviews.put(review.id, review);
  }
  
  static List<WeeklyReview> getAllWeeklyReviews() {
    return weeklyReviews.values.toList()..sort((a, b) => b.weekEnding.compareTo(a.weekEnding));
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
    final journalCount = journals.length;
    final goalCount = goals.length;
    final habitCount = habits.length;
    final achievementCount = achievements.length;
    final reviewCount = weeklyReviews.length;
    final maxStreak = habits.values.isEmpty 
        ? 0 
        : habits.values.map((h) => h.currentStreak).reduce((a, b) => a > b ? a : b);
    final completedGoals = goals.values.where((g) => g.isCompleted).length;
    
    final badgeChecks = {
      'first_journal': journalCount >= 1,
      'ten_journals': journalCount >= 10,
      'first_goal': goalCount >= 1,
      'five_goals': goalCount >= 5,
      'first_habit': habitCount >= 1,
      'week_streak': maxStreak >= 7,
      'month_streak': maxStreak >= 30,
      'first_achievement': achievementCount >= 1,
      'goal_complete': completedGoals >= 1,
      'weekly_reviewer': reviewCount >= 1,
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
  
  // Statistics helpers
  static Map<String, int> getMoodDistribution() {
    final moods = <String, int>{};
    for (var entry in journals.values) {
      moods[entry.mood] = (moods[entry.mood] ?? 0) + 1;
    }
    return moods;
  }
  
  static Map<int, int> getMonthlyActivity() {
    final activity = <int, int>{};
    for (int i = 1; i <= 12; i++) {
      activity[i] = 0;
    }
    
    for (var entry in journals.values.where((j) => j.date.year == 2025)) {
      activity[entry.date.month] = (activity[entry.date.month] ?? 0) + 1;
    }
    
    return activity;
  }
  
  static int getMostActiveMonth() {
    final activity = getMonthlyActivity();
    int maxMonth = 1;
    int maxCount = 0;
    
    activity.forEach((month, count) {
      if (count > maxCount) {
        maxCount = count;
        maxMonth = month;
      }
    });
    
    return maxMonth;
  }
  
  /// Clear ALL user data from all storage boxes
  /// This removes journals, goals, habits, achievements, screenshots,
  /// weekly reviews, and resets badges/progress to defaults
  static Future<void> clearAllData() async {
    // Clear all data boxes
    await journals.clear();
    await goals.clear();
    await habits.clear();
    await achievements.clear();
    await screenshots.clear();
    await weeklyReviews.clear();
    
    // Reset badges to defaults (clear earned status)
    await badges.clear();
    final defaultBadges = BadgeDefinitions.getDefaultBadges();
    for (var badge in defaultBadges) {
      await badges.put(badge.id, badge);
    }
    
    // Reset progress
    await progress.clear();
    await progress.put('user', UserProgress());
  }
  
  /// Clear specific data type only
  static Future<void> clearJournals() async {
    await journals.clear();
  }
  
  static Future<void> clearGoals() async {
    await goals.clear();
  }
  
  static Future<void> clearHabits() async {
    await habits.clear();
  }
  
  static Future<void> clearAchievements() async {
    await achievements.clear();
  }
  
  static Future<void> clearScreenshots() async {
    await screenshots.clear();
  }
  
  static Future<void> clearWeeklyReviews() async {
    await weeklyReviews.clear();
  }
  
  /// Get counts for all data types (for display/debugging)
  static Map<String, int> getDataCounts() {
    return {
      'journals': journals.length,
      'goals': goals.length,
      'habits': habits.length,
      'achievements': achievements.length,
      'screenshots': screenshots.length,
      'weeklyReviews': weeklyReviews.length,
      'badges': badges.length,
      'earnedBadges': badges.values.where((b) => b.isEarned).length,
    };
  }
}
