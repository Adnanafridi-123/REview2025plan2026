import 'package:hive/hive.dart';

part 'screenshot_item.g.dart';

@HiveType(typeId: 5)
class ScreenshotItem extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String path; // Local file path or base64
  
  @HiveField(2)
  DateTime date;
  
  @HiveField(3)
  String caption;
  
  @HiveField(4)
  DateTime createdAt;
  
  @HiveField(5)
  String? thumbnailPath;

  ScreenshotItem({
    required this.id,
    required this.path,
    required this.date,
    this.caption = '',
    required this.createdAt,
    this.thumbnailPath,
  });
  
  ScreenshotItem copyWith({
    String? id,
    String? path,
    DateTime? date,
    String? caption,
    DateTime? createdAt,
    String? thumbnailPath,
  }) {
    return ScreenshotItem(
      id: id ?? this.id,
      path: path ?? this.path,
      date: date ?? this.date,
      caption: caption ?? this.caption,
      createdAt: createdAt ?? this.createdAt,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
    );
  }
}
