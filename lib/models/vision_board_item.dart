import 'package:hive/hive.dart';

part 'vision_board_item.g.dart';

@HiveType(typeId: 10)
class VisionBoardItem extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? description;

  @HiveField(3)
  String? imagePath; // Local image path

  @HiveField(4)
  String category; // Career, Health, Family, Travel, Finance, Personal

  @HiveField(5)
  String? quote; // Motivational quote

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  bool isCompleted;

  @HiveField(8)
  int priority; // 1-5

  VisionBoardItem({
    required this.id,
    required this.title,
    this.description,
    this.imagePath,
    required this.category,
    this.quote,
    required this.createdAt,
    this.isCompleted = false,
    this.priority = 3,
  });
}
