import 'package:hive/hive.dart';

part 'reminder.g.dart';

@HiveType(typeId: 10)
class Reminder extends HiveObject {
  @HiveField(0)
  int id;
  
  @HiveField(1)
  String title;
  
  @HiveField(2)
  String description;
  
  @HiveField(3)
  int hour; // 0-23
  
  @HiveField(4)
  int minute; // 0-59
  
  @HiveField(5)
  bool isEnabled;
  
  @HiveField(6)
  String frequency; // 'once', 'daily' or 'weekly'
  
  @HiveField(7)
  int? weekday; // 1-7 (Monday-Sunday), only for weekly reminders
  
  @HiveField(8)
  String emoji;
  
  @HiveField(9)
  DateTime createdAt;
  
  @HiveField(10)
  bool isPreset; // true for default reminders, false for custom
  
  @HiveField(11)
  DateTime? scheduledDate; // For one-time reminders - specific date

  Reminder({
    required this.id,
    required this.title,
    this.description = '',
    required this.hour,
    required this.minute,
    this.isEnabled = false,
    this.frequency = 'daily',
    this.weekday,
    this.emoji = '🔔',
    required this.createdAt,
    this.isPreset = false,
    this.scheduledDate,
  });
  
  String get timeString {
    final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final m = minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }
  
  String get scheduleDescription {
    if (frequency == 'once' && scheduledDate != null) {
      final months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${scheduledDate!.day} ${months[scheduledDate!.month]} ${scheduledDate!.year} at $timeString';
    }
    if (frequency == 'weekly' && weekday != null) {
      final days = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return '${days[weekday!]} $timeString';
    }
    return 'Daily at $timeString';
  }
  
  /// Check if this is a one-time reminder that has passed
  bool get isExpired {
    if (frequency != 'once' || scheduledDate == null) return false;
    final reminderDateTime = DateTime(
      scheduledDate!.year,
      scheduledDate!.month,
      scheduledDate!.day,
      hour,
      minute,
    );
    return reminderDateTime.isBefore(DateTime.now());
  }
  
  Reminder copyWith({
    int? id,
    String? title,
    String? description,
    int? hour,
    int? minute,
    bool? isEnabled,
    String? frequency,
    int? weekday,
    String? emoji,
    DateTime? createdAt,
    bool? isPreset,
    DateTime? scheduledDate,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      isEnabled: isEnabled ?? this.isEnabled,
      frequency: frequency ?? this.frequency,
      weekday: weekday ?? this.weekday,
      emoji: emoji ?? this.emoji,
      createdAt: createdAt ?? this.createdAt,
      isPreset: isPreset ?? this.isPreset,
      scheduledDate: scheduledDate ?? this.scheduledDate,
    );
  }
}

/// Default preset reminders
class PresetReminders {
  static List<Reminder> getDefaults() {
    final now = DateTime.now();
    return [
      Reminder(
        id: 1001,
        title: 'Morning Goals Review',
        description: 'Subah 7 AM - Apne goals check karein',
        hour: 7,
        minute: 0,
        emoji: '🌅',
        frequency: 'daily',
        isPreset: true,
        createdAt: now,
      ),
      Reminder(
        id: 1002,
        title: 'Exercise Time',
        description: 'Subah 8 AM - Workout karein',
        hour: 8,
        minute: 0,
        emoji: '🏃',
        frequency: 'daily',
        isPreset: true,
        createdAt: now,
      ),
      Reminder(
        id: 1003,
        title: 'Study/Learning Time',
        description: 'Sham 6 PM - Kuch naya seekhein',
        hour: 18,
        minute: 0,
        emoji: '📚',
        frequency: 'daily',
        isPreset: true,
        createdAt: now,
      ),
      Reminder(
        id: 1004,
        title: 'Night Review',
        description: 'Raat 9 PM - Din ka review karein',
        hour: 21,
        minute: 0,
        emoji: '🌙',
        frequency: 'daily',
        isPreset: true,
        createdAt: now,
      ),
      Reminder(
        id: 1005,
        title: 'Weekly Check-in',
        description: 'Sunday 10 AM - Hafta review karein',
        hour: 10,
        minute: 0,
        emoji: '📅',
        frequency: 'weekly',
        weekday: 7, // Sunday
        isPreset: true,
        createdAt: now,
      ),
    ];
  }
}
