import 'package:hive/hive.dart';

part 'journal_entry.g.dart';

@HiveType(typeId: 0)
class JournalEntry extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String text;
  
  @HiveField(2)
  String mood; // 😊, 😐, 😢, 😡, 😍
  
  @HiveField(3)
  DateTime date;
  
  @HiveField(4)
  DateTime createdAt;
  
  @HiveField(5)
  DateTime? updatedAt;

  JournalEntry({
    required this.id,
    required this.text,
    required this.mood,
    required this.date,
    required this.createdAt,
    this.updatedAt,
  });
  
  JournalEntry copyWith({
    String? id,
    String? text,
    String? mood,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      text: text ?? this.text,
      mood: mood ?? this.mood,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'mood': mood,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
  
  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id'],
      text: json['text'],
      mood: json['mood'],
      date: DateTime.parse(json['date']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }
}

// Mood helper
class MoodHelper {
  static const List<String> moods = ['😊', '😐', '😢', '😡', '😍'];
  
  static const Map<String, String> moodNames = {
    '😊': 'Happy',
    '😐': 'Neutral',
    '😢': 'Sad',
    '😡': 'Angry',
    '😍': 'Love',
  };
  
  static String getMoodName(String emoji) {
    return moodNames[emoji] ?? 'Unknown';
  }
}
