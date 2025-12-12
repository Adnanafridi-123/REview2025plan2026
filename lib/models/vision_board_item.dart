import 'package:hive/hive.dart';

part 'vision_board_item.g.dart';

@HiveType(typeId: 10)
class VisionBoardItem extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String type; // 'image', 'text', 'quote', 'goal'
  
  @HiveField(2)
  String content; // Image path or text content
  
  @HiveField(3)
  String? title;
  
  @HiveField(4)
  String category; // Dreams, Career, Health, Travel, Relationships, Finance
  
  @HiveField(5)
  int colorValue; // Background color for text items
  
  @HiveField(6)
  double positionX;
  
  @HiveField(7)
  double positionY;
  
  @HiveField(8)
  double width;
  
  @HiveField(9)
  double height;
  
  @HiveField(10)
  DateTime createdAt;
  
  @HiveField(11)
  bool isCompleted;

  VisionBoardItem({
    required this.id,
    required this.type,
    required this.content,
    this.title,
    this.category = 'Dreams',
    this.colorValue = 0xFF667eea,
    this.positionX = 0,
    this.positionY = 0,
    this.width = 150,
    this.height = 150,
    required this.createdAt,
    this.isCompleted = false,
  });
  
  VisionBoardItem copyWith({
    String? id,
    String? type,
    String? content,
    String? title,
    String? category,
    int? colorValue,
    double? positionX,
    double? positionY,
    double? width,
    double? height,
    DateTime? createdAt,
    bool? isCompleted,
  }) {
    return VisionBoardItem(
      id: id ?? this.id,
      type: type ?? this.type,
      content: content ?? this.content,
      title: title ?? this.title,
      category: category ?? this.category,
      colorValue: colorValue ?? this.colorValue,
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
      width: width ?? this.width,
      height: height ?? this.height,
      createdAt: createdAt ?? this.createdAt,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class VisionBoardCategory {
  static const List<String> categories = [
    'Dreams',
    'Career',
    'Health',
    'Travel',
    'Relationships',
    'Finance',
    'Personal Growth',
    'Adventure',
  ];
  
  static const Map<String, int> categoryColors = {
    'Dreams': 0xFF9C27B0,
    'Career': 0xFF2196F3,
    'Health': 0xFF4CAF50,
    'Travel': 0xFFFF9800,
    'Relationships': 0xFFE91E63,
    'Finance': 0xFFFFEB3B,
    'Personal Growth': 0xFF00BCD4,
    'Adventure': 0xFFFF5722,
  };
  
  static const Map<String, String> categoryIcons = {
    'Dreams': '✨',
    'Career': '💼',
    'Health': '💪',
    'Travel': '✈️',
    'Relationships': '❤️',
    'Finance': '💰',
    'Personal Growth': '🌱',
    'Adventure': '🏔️',
  };
}
