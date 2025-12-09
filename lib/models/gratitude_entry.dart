import 'package:hive/hive.dart';

part 'gratitude_entry.g.dart';

@HiveType(typeId: 15)
class GratitudeEntry extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  String item1; // First thing grateful for

  @HiveField(3)
  String item2; // Second thing grateful for

  @HiveField(4)
  String item3; // Third thing grateful for

  @HiveField(5)
  String? note; // Additional thoughts

  @HiveField(6)
  String mood; // emoji mood

  @HiveField(7)
  String? imagePath; // Optional photo

  GratitudeEntry({
    required this.id,
    required this.date,
    required this.item1,
    required this.item2,
    required this.item3,
    this.note,
    this.mood = '😊',
    this.imagePath,
  });
}
