import 'package:hive/hive.dart';

part 'goal.g.dart';

@HiveType(typeId: 1)
class Goal extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String name;
  
  @HiveField(2)
  String category; // Career, Health, Finance, Personal, Education, Custom
  
  @HiveField(3)
  String description;
  
  @HiveField(4)
  double targetValue;
  
  @HiveField(5)
  double currentValue;
  
  @HiveField(6)
  DateTime deadline;
  
  @HiveField(7)
  String priority; // High, Medium, Low
  
  @HiveField(8)
  List<Milestone> milestones;
  
  @HiveField(9)
  String notes;
  
  @HiveField(10)
  bool isCompleted;
  
  @HiveField(11)
  DateTime createdAt;
  
  @HiveField(12)
  DateTime? completedAt;
  
  @HiveField(13)
  List<String> photos; // List of photo paths
  
  @HiveField(14)
  String? reminderTime; // HH:mm format for daily reminder
  
  @HiveField(15)
  bool reminderEnabled;

  Goal({
    required this.id,
    required this.name,
    required this.category,
    this.description = '',
    this.targetValue = 100,
    this.currentValue = 0,
    required this.deadline,
    this.priority = 'Medium',
    List<Milestone>? milestones,
    this.notes = '',
    this.isCompleted = false,
    required this.createdAt,
    this.completedAt,
    List<String>? photos,
    this.reminderTime,
    this.reminderEnabled = false,
  }) : milestones = milestones ?? [],
       photos = photos ?? [];
  
  double get progress => targetValue > 0 ? (currentValue / targetValue * 100).clamp(0, 100) : 0;
  
  Goal copyWith({
    String? id,
    String? name,
    String? category,
    String? description,
    double? targetValue,
    double? currentValue,
    DateTime? deadline,
    String? priority,
    List<Milestone>? milestones,
    String? notes,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? completedAt,
    List<String>? photos,
    String? reminderTime,
    bool? reminderEnabled,
  }) {
    return Goal(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      deadline: deadline ?? this.deadline,
      priority: priority ?? this.priority,
      milestones: milestones ?? List.from(this.milestones),
      notes: notes ?? this.notes,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      photos: photos ?? List.from(this.photos),
      reminderTime: reminderTime ?? this.reminderTime,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
    );
  }
}

@HiveType(typeId: 2)
class Milestone extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String title;
  
  @HiveField(2)
  bool isCompleted;
  
  @HiveField(3)
  DateTime? completedAt;
  
  @HiveField(4)
  DateTime? dueDate;
  
  @HiveField(5)
  String? description;

  Milestone({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.completedAt,
    this.dueDate,
    this.description,
  });
  
  Milestone copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    DateTime? completedAt,
    DateTime? dueDate,
    String? description,
  }) {
    return Milestone(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      dueDate: dueDate ?? this.dueDate,
      description: description ?? this.description,
    );
  }
}

class GoalCategory {
  static const List<String> categories = [
    'Career',
    'Health',
    'Finance',
    'Personal',
    'Education',
    'Custom',
  ];
  
  static const List<String> priorities = ['High', 'Medium', 'Low'];
}
