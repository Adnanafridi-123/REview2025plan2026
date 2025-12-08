import 'package:hive/hive.dart';

part 'achievement.g.dart';

@HiveType(typeId: 4)
class Achievement extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String title;
  
  @HiveField(2)
  String category; // Career, Health, Personal, Education, Other
  
  @HiveField(3)
  DateTime date;
  
  @HiveField(4)
  String description;
  
  @HiveField(5)
  DateTime createdAt;

  Achievement({
    required this.id,
    required this.title,
    required this.category,
    required this.date,
    this.description = '',
    required this.createdAt,
  });
  
  Achievement copyWith({
    String? id,
    String? title,
    String? category,
    DateTime? date,
    String? description,
    DateTime? createdAt,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      date: date ?? this.date,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class AchievementCategory {
  static const List<String> categories = [
    'Career',
    'Health',
    'Personal',
    'Education',
    'Other',
  ];
  
  static String getIcon(String category) {
    switch (category) {
      case 'Career':
        return '💼';
      case 'Health':
        return '🏃';
      case 'Personal':
        return '🌟';
      case 'Education':
        return '📚';
      default:
        return '🏆';
    }
  }
}
