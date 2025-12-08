// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weekly_review.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WeeklyReviewAdapter extends TypeAdapter<WeeklyReview> {
  @override
  final int typeId = 6;

  @override
  WeeklyReview read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WeeklyReview(
      id: fields[0] as String,
      weekEnding: fields[1] as DateTime,
      wentWell: fields[2] as String,
      challenges: fields[3] as String,
      nextWeekFocus: fields[4] as String,
      completedGoalIds: (fields[5] as List).cast<String>(),
      createdAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, WeeklyReview obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.weekEnding)
      ..writeByte(2)
      ..write(obj.wentWell)
      ..writeByte(3)
      ..write(obj.challenges)
      ..writeByte(4)
      ..write(obj.nextWeekFocus)
      ..writeByte(5)
      ..write(obj.completedGoalIds)
      ..writeByte(6)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeeklyReviewAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
