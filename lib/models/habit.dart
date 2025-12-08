import 'package:hive/hive.dart';

part 'habit.g.dart';

@HiveType(typeId: 3)
class Habit extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String name;
  
  @HiveField(2)
  String frequency; // Daily, Weekly
  
  @HiveField(3)
  List<DateTime> completionDates;
  
  @HiveField(4)
  int currentStreak;
  
  @HiveField(5)
  int bestStreak;
  
  @HiveField(6)
  String? reminderTime; // HH:mm format
  
  @HiveField(7)
  DateTime createdAt;
  
  @HiveField(8)
  bool isActive;

  Habit({
    required this.id,
    required this.name,
    this.frequency = 'Daily',
    List<DateTime>? completionDates,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.reminderTime,
    required this.createdAt,
    this.isActive = true,
  }) : completionDates = completionDates ?? [];
  
  bool isCompletedToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return completionDates.any((date) {
      final d = DateTime(date.year, date.month, date.day);
      return d.isAtSameMomentAs(today);
    });
  }
  
  bool isCompletedOnDate(DateTime date) {
    final targetDate = DateTime(date.year, date.month, date.day);
    return completionDates.any((d) {
      final completedDate = DateTime(d.year, d.month, d.day);
      return completedDate.isAtSameMomentAs(targetDate);
    });
  }
  
  void markComplete() {
    final now = DateTime.now();
    if (!isCompletedToday()) {
      completionDates.add(now);
      _updateStreak();
    }
  }
  
  void markIncomplete() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    completionDates.removeWhere((date) {
      final d = DateTime(date.year, date.month, date.day);
      return d.isAtSameMomentAs(today);
    });
    _updateStreak();
  }
  
  void _updateStreak() {
    if (completionDates.isEmpty) {
      currentStreak = 0;
      return;
    }
    
    completionDates.sort((a, b) => b.compareTo(a));
    
    int streak = 0;
    DateTime checkDate = DateTime.now();
    
    for (var date in completionDates) {
      final completedDate = DateTime(date.year, date.month, date.day);
      final check = DateTime(checkDate.year, checkDate.month, checkDate.day);
      
      if (completedDate.isAtSameMomentAs(check) || 
          completedDate.isAtSameMomentAs(check.subtract(const Duration(days: 1)))) {
        streak++;
        checkDate = completedDate;
      } else {
        break;
      }
    }
    
    currentStreak = streak;
    if (currentStreak > bestStreak) {
      bestStreak = currentStreak;
    }
  }
  
  double getCompletionRate() {
    if (completionDates.isEmpty) return 0;
    
    final now = DateTime.now();
    final startOfYear = DateTime(2026, 1, 1);
    final daysSinceStart = now.difference(startOfYear).inDays + 1;
    
    if (daysSinceStart <= 0) return 0;
    
    final completionsThisYear = completionDates.where((date) => date.year == 2026).length;
    return (completionsThisYear / daysSinceStart * 100).clamp(0, 100);
  }
  
  Habit copyWith({
    String? id,
    String? name,
    String? frequency,
    List<DateTime>? completionDates,
    int? currentStreak,
    int? bestStreak,
    String? reminderTime,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      frequency: frequency ?? this.frequency,
      completionDates: completionDates ?? List.from(this.completionDates),
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      reminderTime: reminderTime ?? this.reminderTime,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}

class HabitFrequency {
  static const List<String> frequencies = ['Daily', 'Weekly'];
}
