// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HealthRecordAdapter extends TypeAdapter<HealthRecord> {
  @override
  final int typeId = 11;

  @override
  HealthRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HealthRecord(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      waterGlasses: fields[2] as int,
      sleepHours: fields[3] as double,
      exerciseMinutes: fields[4] as int,
      weight: fields[5] as double?,
      steps: fields[6] as int,
      notes: fields[7] as String?,
      moodScore: fields[8] as int,
    );
  }

  @override
  void write(BinaryWriter writer, HealthRecord obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.waterGlasses)
      ..writeByte(3)
      ..write(obj.sleepHours)
      ..writeByte(4)
      ..write(obj.exerciseMinutes)
      ..writeByte(5)
      ..write(obj.weight)
      ..writeByte(6)
      ..write(obj.steps)
      ..writeByte(7)
      ..write(obj.notes)
      ..writeByte(8)
      ..write(obj.moodScore);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HealthRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
