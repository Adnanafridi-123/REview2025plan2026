import 'package:hive/hive.dart';

part 'bucket_list_item.g.dart';

@HiveType(typeId: 14)
class BucketListItem extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? description;

  @HiveField(3)
  String category; // Travel, Experience, Learning, Adventure, Personal, Career

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  DateTime? completedAt;

  @HiveField(6)
  bool isCompleted;

  @HiveField(7)
  String? imagePath; // Photo when completed

  @HiveField(8)
  int priority; // 1-5 (1 = must do, 5 = nice to have)

  @HiveField(9)
  String icon; // emoji

  @HiveField(10)
  String? location; // For travel items

  @HiveField(11)
  double? estimatedCost;

  BucketListItem({
    required this.id,
    required this.title,
    this.description,
    required this.category,
    required this.createdAt,
    this.completedAt,
    this.isCompleted = false,
    this.imagePath,
    this.priority = 3,
    this.icon = '⭐',
    this.location,
    this.estimatedCost,
  });
}
