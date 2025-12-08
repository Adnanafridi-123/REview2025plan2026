import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/journal_entry.dart';
import '../models/goal.dart';
import '../models/habit.dart';
import '../models/achievement.dart';
import '../models/screenshot_item.dart';
import '../models/weekly_review.dart';
import '../models/badge.dart';
import '../models/media_item.dart';
import '../services/storage_service.dart';
import '../services/media_service.dart';

class AppProvider extends ChangeNotifier {
  final _uuid = const Uuid();
  
  // Journals
  List<JournalEntry> _journals = [];
  List<JournalEntry> get journals => _journals;
  List<JournalEntry> get journals2025 => _journals.where((j) => j.date.year == 2025).toList();
  
  // Goals
  List<Goal> _goals = [];
  List<Goal> get goals => _goals;
  List<Goal> get activeGoals => _goals.where((g) => !g.isCompleted).toList();
  List<Goal> get completedGoals => _goals.where((g) => g.isCompleted).toList();
  
  // Habits
  List<Habit> _habits = [];
  List<Habit> get habits => _habits;
  
  // Achievements
  List<Achievement> _achievements = [];
  List<Achievement> get achievements => _achievements;
  List<Achievement> get achievements2025 => _achievements.where((a) => a.date.year == 2025).toList();
  
  // Screenshots
  List<ScreenshotItem> _screenshots = [];
  List<ScreenshotItem> get screenshots => _screenshots;
  
  // Weekly Reviews
  List<WeeklyReview> _weeklyReviews = [];
  List<WeeklyReview> get weeklyReviews => _weeklyReviews;
  
  // Badges & Progress
  List<UserBadge> _badges = [];
  List<UserBadge> get badges => _badges;
  List<UserBadge> get earnedBadges => _badges.where((b) => b.isEarned).toList();
  UserProgress _progress = UserProgress();
  UserProgress get progress => _progress;
  
  // Media from device (real user content)
  List<MediaItem> _photos = [];
  List<MediaItem> get photos => _photos;
  List<MediaItem> _videos = [];
  List<MediaItem> get videos => _videos;
  List<MediaItem> _deviceScreenshots = [];
  List<MediaItem> get deviceScreenshots => _deviceScreenshots;
  
  // Dark mode
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;
  
  Future<void> loadData() async {
    _journals = StorageService.getAllJournals();
    _goals = StorageService.getAllGoals();
    _habits = StorageService.getAllHabits();
    _achievements = StorageService.getAllAchievements();
    _screenshots = StorageService.getAllScreenshots();
    _weeklyReviews = StorageService.getAllWeeklyReviews();
    _badges = StorageService.getAllBadges();
    _progress = StorageService.getUserProgress();
    
    // Load real media from device storage
    _loadMediaFromDevice();
    
    notifyListeners();
  }
  
  void _loadMediaFromDevice() {
    try {
      _photos = MediaService.getAllPhotos();
      _videos = MediaService.getAllVideos();
      _deviceScreenshots = MediaService.getAllScreenshots();
    } catch (e) {
      // Initialize with empty lists if media loading fails
      _photos = [];
      _videos = [];
      _deviceScreenshots = [];
    }
  }
  
  /// Refresh media from device
  void refreshMedia() {
    _loadMediaFromDevice();
    notifyListeners();
  }
  
  /// Add photo to collection
  Future<void> addPhoto(MediaItem photo) async {
    _photos.insert(0, photo);
    notifyListeners();
  }
  
  /// Remove photo from collection
  Future<void> removePhoto(String id) async {
    await MediaService.deletePhoto(id);
    _photos.removeWhere((p) => p.id == id);
    notifyListeners();
  }
  
  /// Add video to collection
  Future<void> addVideo(MediaItem video) async {
    _videos.insert(0, video);
    notifyListeners();
  }
  
  /// Remove video from collection
  Future<void> removeVideo(String id) async {
    await MediaService.deleteVideo(id);
    _videos.removeWhere((v) => v.id == id);
    notifyListeners();
  }
  
  /// Add device screenshot to collection
  Future<void> addDeviceScreenshot(MediaItem screenshot) async {
    _deviceScreenshots.insert(0, screenshot);
    notifyListeners();
  }
  
  /// Remove device screenshot from collection
  Future<void> removeDeviceScreenshot(String id) async {
    await MediaService.deleteScreenshot(id);
    _deviceScreenshots.removeWhere((s) => s.id == id);
    notifyListeners();
  }
  
  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
  
  // Journal operations
  Future<void> addJournal({
    required String text,
    required String mood,
    required DateTime date,
  }) async {
    final entry = JournalEntry(
      id: _uuid.v4(),
      text: text,
      mood: mood,
      date: date,
      createdAt: DateTime.now(),
    );
    await StorageService.addJournal(entry);
    _journals = StorageService.getAllJournals();
    _badges = StorageService.getAllBadges();
    _progress = StorageService.getUserProgress();
    notifyListeners();
  }
  
  Future<void> updateJournal(JournalEntry entry) async {
    final updated = entry.copyWith(updatedAt: DateTime.now());
    await StorageService.updateJournal(updated);
    _journals = StorageService.getAllJournals();
    notifyListeners();
  }
  
  Future<void> deleteJournal(String id) async {
    await StorageService.deleteJournal(id);
    _journals = StorageService.getAllJournals();
    notifyListeners();
  }
  
  // Goal operations
  Future<void> addGoal({
    required String name,
    required String category,
    String description = '',
    double targetValue = 100,
    required DateTime deadline,
    String priority = 'Medium',
  }) async {
    final goal = Goal(
      id: _uuid.v4(),
      name: name,
      category: category,
      description: description,
      targetValue: targetValue,
      deadline: deadline,
      priority: priority,
      createdAt: DateTime.now(),
    );
    await StorageService.addGoal(goal);
    _goals = StorageService.getAllGoals();
    _badges = StorageService.getAllBadges();
    _progress = StorageService.getUserProgress();
    notifyListeners();
  }
  
  Future<void> updateGoal(Goal goal) async {
    await StorageService.updateGoal(goal);
    _goals = StorageService.getAllGoals();
    _badges = StorageService.getAllBadges();
    _progress = StorageService.getUserProgress();
    notifyListeners();
  }
  
  Future<void> updateGoalProgress(String goalId, double newValue) async {
    final goal = _goals.firstWhere((g) => g.id == goalId);
    final updated = goal.copyWith(
      currentValue: newValue,
      isCompleted: newValue >= goal.targetValue,
      completedAt: newValue >= goal.targetValue ? DateTime.now() : null,
    );
    await updateGoal(updated);
  }
  
  Future<void> toggleMilestone(String goalId, String milestoneId) async {
    final goal = _goals.firstWhere((g) => g.id == goalId);
    final milestones = goal.milestones.map((m) {
      if (m.id == milestoneId) {
        return m.copyWith(
          isCompleted: !m.isCompleted,
          completedAt: !m.isCompleted ? DateTime.now() : null,
        );
      }
      return m;
    }).toList();
    
    // Update progress based on milestones
    final completedCount = milestones.where((m) => m.isCompleted).length;
    final progress = milestones.isEmpty ? 0.0 : (completedCount / milestones.length * 100);
    
    final updated = goal.copyWith(
      milestones: milestones,
      currentValue: progress,
      isCompleted: progress >= 100,
      completedAt: progress >= 100 ? DateTime.now() : null,
    );
    await updateGoal(updated);
  }
  
  Future<void> addMilestone(String goalId, String title) async {
    final goal = _goals.firstWhere((g) => g.id == goalId);
    final milestone = Milestone(
      id: _uuid.v4(),
      title: title,
    );
    final updated = goal.copyWith(
      milestones: [...goal.milestones, milestone],
    );
    await updateGoal(updated);
  }
  
  Future<void> deleteGoal(String id) async {
    await StorageService.deleteGoal(id);
    _goals = StorageService.getAllGoals();
    notifyListeners();
  }
  
  // Habit operations
  Future<void> addHabit({
    required String name,
    String frequency = 'Daily',
    String? reminderTime,
  }) async {
    final habit = Habit(
      id: _uuid.v4(),
      name: name,
      frequency: frequency,
      reminderTime: reminderTime,
      createdAt: DateTime.now(),
    );
    await StorageService.addHabit(habit);
    _habits = StorageService.getAllHabits();
    _badges = StorageService.getAllBadges();
    _progress = StorageService.getUserProgress();
    notifyListeners();
  }
  
  Future<void> toggleHabitCompletion(String habitId) async {
    final habit = _habits.firstWhere((h) => h.id == habitId);
    if (habit.isCompletedToday()) {
      habit.markIncomplete();
    } else {
      habit.markComplete();
    }
    await StorageService.updateHabit(habit);
    _habits = StorageService.getAllHabits();
    _badges = StorageService.getAllBadges();
    _progress = StorageService.getUserProgress();
    notifyListeners();
  }
  
  Future<void> deleteHabit(String id) async {
    await StorageService.deleteHabit(id);
    _habits = StorageService.getAllHabits();
    notifyListeners();
  }
  
  // Achievement operations
  Future<void> addAchievement({
    required String title,
    required String category,
    required DateTime date,
    String description = '',
  }) async {
    final achievement = Achievement(
      id: _uuid.v4(),
      title: title,
      category: category,
      date: date,
      description: description,
      createdAt: DateTime.now(),
    );
    await StorageService.addAchievement(achievement);
    _achievements = StorageService.getAllAchievements();
    _badges = StorageService.getAllBadges();
    _progress = StorageService.getUserProgress();
    notifyListeners();
  }
  
  Future<void> updateAchievement(Achievement achievement) async {
    await StorageService.updateAchievement(achievement);
    _achievements = StorageService.getAllAchievements();
    notifyListeners();
  }
  
  Future<void> deleteAchievement(String id) async {
    await StorageService.deleteAchievement(id);
    _achievements = StorageService.getAllAchievements();
    notifyListeners();
  }
  
  // Screenshot operations (from legacy screenshot items)
  Future<void> addScreenshot({
    required String path,
    required DateTime date,
    String caption = '',
  }) async {
    final screenshot = ScreenshotItem(
      id: _uuid.v4(),
      path: path,
      date: date,
      caption: caption,
      createdAt: DateTime.now(),
    );
    await StorageService.addScreenshot(screenshot);
    _screenshots = StorageService.getAllScreenshots();
    notifyListeners();
  }
  
  Future<void> deleteScreenshot(String id) async {
    await StorageService.deleteScreenshot(id);
    _screenshots = StorageService.getAllScreenshots();
    notifyListeners();
  }
  
  // Weekly Review operations
  Future<void> addWeeklyReview({
    required DateTime weekEnding,
    String wentWell = '',
    String challenges = '',
    String nextWeekFocus = '',
    List<String>? completedGoalIds,
  }) async {
    final review = WeeklyReview(
      id: _uuid.v4(),
      weekEnding: weekEnding,
      wentWell: wentWell,
      challenges: challenges,
      nextWeekFocus: nextWeekFocus,
      completedGoalIds: completedGoalIds,
      createdAt: DateTime.now(),
    );
    await StorageService.addWeeklyReview(review);
    _weeklyReviews = StorageService.getAllWeeklyReviews();
    _badges = StorageService.getAllBadges();
    _progress = StorageService.getUserProgress();
    notifyListeners();
  }
  
  // Statistics
  Map<String, int> getMoodDistribution() {
    return StorageService.getMoodDistribution();
  }
  
  Map<int, int> getMonthlyActivity() {
    return StorageService.getMonthlyActivity();
  }
  
  int getMostActiveMonth() {
    return StorageService.getMostActiveMonth();
  }
  
  // Stats getters - Now count real device media
  int get totalPhotos => _photos.length;
  int get totalVideos => _videos.length;
  int get totalDeviceScreenshots => _deviceScreenshots.length;
  int get totalJournals => journals2025.length;
  int get totalAchievements => achievements2025.length;
  int get totalGoals => _goals.length;
  int get totalHabits => _habits.length;
  
  // Combined media count for wrapped/stats
  int get totalMedia => totalPhotos + totalVideos + totalDeviceScreenshots;
  
  double get goalCompletionRate {
    if (_goals.isEmpty) return 0;
    return completedGoals.length / _goals.length * 100;
  }
  
  int get bestHabitStreak {
    if (_habits.isEmpty) return 0;
    return _habits.map((h) => h.bestStreak).reduce((a, b) => a > b ? a : b);
  }
  
  /// Get all media items for video generation
  List<MediaItem> getAllMediaForVideo() {
    final allMedia = <MediaItem>[];
    allMedia.addAll(_photos);
    allMedia.addAll(_videos);
    allMedia.addAll(_deviceScreenshots);
    // Sort by date
    allMedia.sort((a, b) => a.date.compareTo(b.date));
    return allMedia;
  }
  
  /// Clear ALL data and reset app to fresh state
  /// Use this to remove all existing data before adding your own for testing
  Future<void> clearAllData() async {
    await StorageService.clearAllData();
    await MediaService.clearAllMedia();
    
    // Reset local lists
    _journals = [];
    _goals = [];
    _habits = [];
    _achievements = [];
    _screenshots = [];
    _weeklyReviews = [];
    _photos = [];
    _videos = [];
    _deviceScreenshots = [];
    
    // Reload badges (will have defaults)
    _badges = StorageService.getAllBadges();
    _progress = StorageService.getUserProgress();
    
    notifyListeners();
  }
  
  /// Get counts of all data for display
  Map<String, int> getDataCounts() {
    return {
      'journals': _journals.length,
      'goals': _goals.length,
      'habits': _habits.length,
      'achievements': _achievements.length,
      'screenshots': _screenshots.length,
      'weeklyReviews': _weeklyReviews.length,
      'photos': _photos.length,
      'videos': _videos.length,
      'deviceScreenshots': _deviceScreenshots.length,
      'badges': _badges.length,
      'earnedBadges': earnedBadges.length,
    };
  }
}
