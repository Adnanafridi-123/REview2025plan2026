import 'package:hive/hive.dart';

part 'health_record.g.dart';

@HiveType(typeId: 11)
class HealthRecord extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  int waterGlasses; // 0-12 glasses

  @HiveField(3)
  double sleepHours; // 0-12 hours

  @HiveField(4)
  int exerciseMinutes; // 0-180 minutes

  @HiveField(5)
  double? weight; // kg

  @HiveField(6)
  int steps; // daily steps

  @HiveField(7)
  String? notes;

  @HiveField(8)
  int moodScore; // 1-5 (sad to happy)

  HealthRecord({
    required this.id,
    required this.date,
    this.waterGlasses = 0,
    this.sleepHours = 0,
    this.exerciseMinutes = 0,
    this.weight,
    this.steps = 0,
    this.notes,
    this.moodScore = 3,
  });

  // Calculate daily health score (0-100)
  int get healthScore {
    int score = 0;
    
    // Water (max 25 points) - 8 glasses = 25 points
    score += (waterGlasses >= 8 ? 25 : (waterGlasses * 3.125)).toInt();
    
    // Sleep (max 25 points) - 7-8 hours = 25 points
    if (sleepHours >= 7 && sleepHours <= 9) {
      score += 25;
    } else if (sleepHours >= 6) {
      score += 20;
    } else if (sleepHours >= 5) {
      score += 15;
    } else {
      score += (sleepHours * 2.5).toInt();
    }
    
    // Exercise (max 25 points) - 30+ minutes = 25 points
    score += (exerciseMinutes >= 30 ? 25 : (exerciseMinutes * 0.83)).toInt();
    
    // Steps (max 25 points) - 10000 steps = 25 points
    score += (steps >= 10000 ? 25 : (steps / 400).toInt());
    
    return score.clamp(0, 100);
  }
}
