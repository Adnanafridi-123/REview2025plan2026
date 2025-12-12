import 'package:hive/hive.dart';

part 'health_goal.g.dart';

@HiveType(typeId: 21)
class HealthGoal extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String type; // 'weight', 'exercise', 'water', 'sleep', 'steps', 'nutrition', 'meditation'
  
  @HiveField(2)
  String title;
  
  @HiveField(3)
  double targetValue;
  
  @HiveField(4)
  double currentValue;
  
  @HiveField(5)
  String unit; // kg, lbs, liters, hours, steps, minutes
  
  @HiveField(6)
  String frequency; // 'daily', 'weekly', 'monthly', 'yearly'
  
  @HiveField(7)
  List<HealthLog> logs;
  
  @HiveField(8)
  DateTime createdAt;
  
  @HiveField(9)
  DateTime? targetDate;
  
  @HiveField(10)
  bool isCompleted;
  
  @HiveField(11)
  int colorValue;
  
  @HiveField(12)
  String icon;
  
  @HiveField(13)
  String notes;
  
  @HiveField(14)
  double startValue; // Starting point for tracking progress

  HealthGoal({
    required this.id,
    required this.type,
    required this.title,
    required this.targetValue,
    this.currentValue = 0,
    required this.unit,
    this.frequency = 'daily',
    List<HealthLog>? logs,
    required this.createdAt,
    this.targetDate,
    this.isCompleted = false,
    this.colorValue = 0xFF4CAF50,
    this.icon = '💪',
    this.notes = '',
    this.startValue = 0,
  }) : logs = logs ?? [];
  
  double get progress {
    // For weight loss goals, calculate differently
    if (type == 'weight' && startValue > targetValue) {
      // Losing weight
      final totalToLose = startValue - targetValue;
      final lost = startValue - currentValue;
      return totalToLose > 0 ? (lost / totalToLose * 100).clamp(0, 100) : 0;
    }
    // For gaining/increasing goals
    return targetValue > 0 ? (currentValue / targetValue * 100).clamp(0, 100) : 0;
  }
  
  double get todayValue {
    final today = DateTime.now();
    final todayLogs = logs.where((log) =>
      log.date.year == today.year &&
      log.date.month == today.month &&
      log.date.day == today.day
    );
    if (todayLogs.isEmpty) return 0;
    return todayLogs.map((l) => l.value).reduce((a, b) => a + b);
  }
  
  double get weeklyAverage {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final weekLogs = logs.where((log) => log.date.isAfter(weekAgo));
    if (weekLogs.isEmpty) return 0;
    return weekLogs.map((l) => l.value).reduce((a, b) => a + b) / weekLogs.length;
  }
  
  int get currentStreak {
    if (logs.isEmpty) return 0;
    
    final sortedLogs = List<HealthLog>.from(logs)
      ..sort((a, b) => b.date.compareTo(a.date));
    
    int streak = 0;
    DateTime checkDate = DateTime.now();
    
    for (var log in sortedLogs) {
      final logDate = DateTime(log.date.year, log.date.month, log.date.day);
      final check = DateTime(checkDate.year, checkDate.month, checkDate.day);
      
      if (logDate.isAtSameMomentAs(check) || 
          logDate.isAtSameMomentAs(check.subtract(const Duration(days: 1)))) {
        streak++;
        checkDate = logDate;
      } else {
        break;
      }
    }
    return streak;
  }
  
  HealthGoal copyWith({
    String? id,
    String? type,
    String? title,
    double? targetValue,
    double? currentValue,
    String? unit,
    String? frequency,
    List<HealthLog>? logs,
    DateTime? createdAt,
    DateTime? targetDate,
    bool? isCompleted,
    int? colorValue,
    String? icon,
    String? notes,
    double? startValue,
  }) {
    return HealthGoal(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      unit: unit ?? this.unit,
      frequency: frequency ?? this.frequency,
      logs: logs ?? List.from(this.logs),
      createdAt: createdAt ?? this.createdAt,
      targetDate: targetDate ?? this.targetDate,
      isCompleted: isCompleted ?? this.isCompleted,
      colorValue: colorValue ?? this.colorValue,
      icon: icon ?? this.icon,
      notes: notes ?? this.notes,
      startValue: startValue ?? this.startValue,
    );
  }
}

@HiveType(typeId: 22)
class HealthLog extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  double value;
  
  @HiveField(2)
  DateTime date;
  
  @HiveField(3)
  String? note;

  HealthLog({
    required this.id,
    required this.value,
    required this.date,
    this.note,
  });
}

class HealthGoalType {
  static const List<String> types = [
    'weight',
    'exercise',
    'water',
    'sleep',
    'steps',
    'nutrition',
    'meditation',
    'workout',
  ];
  
  static const Map<String, String> typeNames = {
    'weight': 'Weight Goal',
    'exercise': 'Exercise Minutes',
    'water': 'Water Intake',
    'sleep': 'Sleep Hours',
    'steps': 'Daily Steps',
    'nutrition': 'Calorie Goal',
    'meditation': 'Meditation',
    'workout': 'Workout Sessions',
  };
  
  static const Map<String, String> typeIcons = {
    'weight': '⚖️',
    'exercise': '🏃',
    'water': '💧',
    'sleep': '😴',
    'steps': '👟',
    'nutrition': '🥗',
    'meditation': '🧘',
    'workout': '💪',
  };
  
  static const Map<String, int> typeColors = {
    'weight': 0xFF9C27B0,
    'exercise': 0xFFFF5722,
    'water': 0xFF2196F3,
    'sleep': 0xFF673AB7,
    'steps': 0xFF4CAF50,
    'nutrition': 0xFFFF9800,
    'meditation': 0xFF00BCD4,
    'workout': 0xFFE91E63,
  };
  
  static const Map<String, String> typeUnits = {
    'weight': 'kg',
    'exercise': 'min',
    'water': 'L',
    'sleep': 'hrs',
    'steps': 'steps',
    'nutrition': 'cal',
    'meditation': 'min',
    'workout': 'sessions',
  };
  
  static const Map<String, double> defaultTargets = {
    'weight': 70.0,
    'exercise': 30.0,
    'water': 3.0,
    'sleep': 8.0,
    'steps': 10000.0,
    'nutrition': 2000.0,
    'meditation': 15.0,
    'workout': 4.0,
  };
}
