import 'package:hive/hive.dart';

part 'badge.g.dart';

@HiveType(typeId: 7)
class UserBadge extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String name;
  
  @HiveField(2)
  String description;
  
  @HiveField(3)
  String icon;
  
  @HiveField(4)
  bool isEarned;
  
  @HiveField(5)
  DateTime? earnedAt;
  
  @HiveField(6)
  int pointsRequired;

  UserBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.isEarned = false,
    this.earnedAt,
    this.pointsRequired = 0,
  });
  
  UserBadge copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    bool? isEarned,
    DateTime? earnedAt,
    int? pointsRequired,
  }) {
    return UserBadge(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      isEarned: isEarned ?? this.isEarned,
      earnedAt: earnedAt ?? this.earnedAt,
      pointsRequired: pointsRequired ?? this.pointsRequired,
    );
  }
}

@HiveType(typeId: 8)
class UserProgress extends HiveObject {
  @HiveField(0)
  int totalPoints;
  
  @HiveField(1)
  int level;
  
  @HiveField(2)
  List<String> earnedBadgeIds;

  UserProgress({
    this.totalPoints = 0,
    this.level = 1,
    List<String>? earnedBadgeIds,
  }) : earnedBadgeIds = earnedBadgeIds ?? [];
  
  String get levelName {
    if (level <= 2) return 'Beginner';
    if (level <= 5) return 'Explorer';
    if (level <= 10) return 'Achiever';
    if (level <= 15) return 'Champion';
    return 'Legend';
  }
  
  int get pointsToNextLevel => level * 100;
  
  double get progressToNextLevel => (totalPoints % 100) / 100;
}

// Predefined badges
class BadgeDefinitions {
  static List<UserBadge> getDefaultBadges() {
    return [
      UserBadge(
        id: 'first_goal',
        name: 'Goal Setter',
        description: 'Create your first goal',
        icon: '🎯',
        pointsRequired: 10,
      ),
      UserBadge(
        id: 'five_goals',
        name: 'Ambitious',
        description: 'Create 5 goals',
        icon: '🚀',
        pointsRequired: 50,
      ),
      UserBadge(
        id: 'first_habit',
        name: 'Habit Builder',
        description: 'Create your first habit',
        icon: '🔄',
        pointsRequired: 10,
      ),
      UserBadge(
        id: 'week_streak',
        name: 'Week Warrior',
        description: '7-day habit streak',
        icon: '🔥',
        pointsRequired: 70,
      ),
      UserBadge(
        id: 'month_streak',
        name: 'Monthly Master',
        description: '30-day habit streak',
        icon: '⭐',
        pointsRequired: 300,
      ),
      UserBadge(
        id: 'first_journal',
        name: 'Reflector',
        description: 'Write your first journal entry',
        icon: '📝',
        pointsRequired: 10,
      ),
      UserBadge(
        id: 'ten_journals',
        name: 'Storyteller',
        description: 'Write 10 journal entries',
        icon: '📖',
        pointsRequired: 100,
      ),
      UserBadge(
        id: 'first_achievement',
        name: 'Winner',
        description: 'Log your first achievement',
        icon: '🏆',
        pointsRequired: 20,
      ),
      UserBadge(
        id: 'goal_complete',
        name: 'Finisher',
        description: 'Complete your first goal',
        icon: '✅',
        pointsRequired: 50,
      ),
      UserBadge(
        id: 'weekly_reviewer',
        name: 'Weekly Reviewer',
        description: 'Complete a weekly review',
        icon: '📊',
        pointsRequired: 25,
      ),
      UserBadge(
        id: 'all_moods',
        name: 'Emotional Explorer',
        description: 'Use all mood types',
        icon: '🎭',
        pointsRequired: 50,
      ),
      UserBadge(
        id: 'wrapped_creator',
        name: 'Wrapped Creator',
        description: 'Generate your 2025 Wrapped',
        icon: '🎁',
        pointsRequired: 100,
      ),
    ];
  }
}
