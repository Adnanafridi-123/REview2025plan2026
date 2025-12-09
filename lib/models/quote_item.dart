import 'package:hive/hive.dart';

part 'quote_item.g.dart';

@HiveType(typeId: 16)
class QuoteItem extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String text;

  @HiveField(2)
  String category; // Maafi, Shukr, Khushi, Dua, Umeed, Custom

  @HiveField(3)
  String? author;

  @HiveField(4)
  bool isCustom; // User added

  @HiveField(5)
  bool isFavorite;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  String backgroundGradient; // gradient style

  QuoteItem({
    required this.id,
    required this.text,
    required this.category,
    this.author,
    this.isCustom = false,
    this.isFavorite = false,
    required this.createdAt,
    this.backgroundGradient = 'purple',
  });
}
