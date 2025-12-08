import 'package:hive/hive.dart';

part 'weekly_review.g.dart';

@HiveType(typeId: 6)
class WeeklyReview extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  DateTime weekEnding;
  
  @HiveField(2)
  String wentWell;
  
  @HiveField(3)
  String challenges;
  
  @HiveField(4)
  String nextWeekFocus;
  
  @HiveField(5)
  List<String> completedGoalIds;
  
  @HiveField(6)
  DateTime createdAt;

  WeeklyReview({
    required this.id,
    required this.weekEnding,
    this.wentWell = '',
    this.challenges = '',
    this.nextWeekFocus = '',
    List<String>? completedGoalIds,
    required this.createdAt,
  }) : completedGoalIds = completedGoalIds ?? [];
  
  WeeklyReview copyWith({
    String? id,
    DateTime? weekEnding,
    String? wentWell,
    String? challenges,
    String? nextWeekFocus,
    List<String>? completedGoalIds,
    DateTime? createdAt,
  }) {
    return WeeklyReview(
      id: id ?? this.id,
      weekEnding: weekEnding ?? this.weekEnding,
      wentWell: wentWell ?? this.wentWell,
      challenges: challenges ?? this.challenges,
      nextWeekFocus: nextWeekFocus ?? this.nextWeekFocus,
      completedGoalIds: completedGoalIds ?? List.from(this.completedGoalIds),
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
