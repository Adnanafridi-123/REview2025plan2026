import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/goal.dart';
import '../models/habit.dart';
import '../models/badge.dart';
import '../models/media_item.dart';
import '../services/storage_service.dart';
import '../services/media_service.dart';
import '../services/home_widget_service.dart';

class AppProvider extends ChangeNotifier {
  final _uuid = const Uuid();
  
  // Goals
  List<Goal> _goals = [];
  List<Goal> get goals => _goals;
  List<Goal> get activeGoals => _goals.where((g) => !g.isCompleted).toList();
  List<Goal> get completedGoals => _goals.where((g) => g.isCompleted).toList();
  
  // Habits
  List<Habit> _habits = [];
  List<Habit> get habits => _habits;
  
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
    _goals = StorageService.getAllGoals();
    _habits = StorageService.getAllHabits();
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
  
  // Goal operations
  Future<void> addGoal({
    required String name,
    required String category,
    String description = '',
    double targetValue = 100,
    required DateTime deadline,
    String priority = 'Medium',
    String? reminderTime,
    bool reminderEnabled = false,
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
      reminderTime: reminderTime,
      reminderEnabled: reminderEnabled,
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
    _updateHomeWidget();
  }
  
  void _updateHomeWidget() {
    HomeWidgetService.updateGoalWidget(goals: _goals, habits: _habits);
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
  
  Future<void> addMilestoneWithDetails(String goalId, String title, {String? description, DateTime? dueDate}) async {
    final goal = _goals.firstWhere((g) => g.id == goalId);
    final milestone = Milestone(
      id: _uuid.v4(),
      title: title,
      description: description,
      dueDate: dueDate,
    );
    final updated = goal.copyWith(
      milestones: [...goal.milestones, milestone],
    );
    await updateGoal(updated);
  }
  
  Future<void> updateMilestone(String goalId, Milestone updatedMilestone) async {
    final goal = _goals.firstWhere((g) => g.id == goalId);
    final milestones = goal.milestones.map((m) {
      if (m.id == updatedMilestone.id) {
        return updatedMilestone;
      }
      return m;
    }).toList();
    
    final updated = goal.copyWith(milestones: milestones);
    await updateGoal(updated);
  }
  
  Future<void> deleteMilestone(String goalId, String milestoneId) async {
    final goal = _goals.firstWhere((g) => g.id == goalId);
    final milestones = goal.milestones.where((m) => m.id != milestoneId).toList();
    
    // Recalculate progress
    final completedCount = milestones.where((m) => m.isCompleted).length;
    final progress = milestones.isEmpty ? 0.0 : (completedCount / milestones.length * 100);
    
    final updated = goal.copyWith(
      milestones: milestones,
      currentValue: progress,
      isCompleted: progress >= 100 && milestones.isNotEmpty,
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
    String category = 'Personal',
  }) async {
    final habit = Habit(
      id: _uuid.v4(),
      name: name,
      frequency: frequency,
      reminderTime: reminderTime,
      createdAt: DateTime.now(),
      category: category,
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
    _updateHomeWidget();
  }
  
  Future<void> updateHabit(Habit habit) async {
    await StorageService.updateHabit(habit);
    _habits = StorageService.getAllHabits();
    notifyListeners();
    _updateHomeWidget();
  }
  
  Future<void> deleteHabit(String id) async {
    await StorageService.deleteHabit(id);
    _habits = StorageService.getAllHabits();
    notifyListeners();
    _updateHomeWidget();
  }
  
  // Stats getters - Now count real device media
  int get totalPhotos => _photos.length;
  int get totalVideos => _videos.length;
  int get totalDeviceScreenshots => _deviceScreenshots.length;
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
  Future<void> clearAllData() async {
    await StorageService.clearAllData();
    await MediaService.clearAllMedia();
    
    // Reset local lists
    _goals = [];
    _habits = [];
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
      'goals': _goals.length,
      'habits': _habits.length,
      'photos': _photos.length,
      'videos': _videos.length,
      'deviceScreenshots': _deviceScreenshots.length,
      'badges': _badges.length,
      'earnedBadges': earnedBadges.length,
    };
  }
}
