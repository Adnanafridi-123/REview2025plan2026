// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_goal.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HealthGoalAdapter extends TypeAdapter<HealthGoal> {
  @override
  final int typeId = 21;

  @override
  HealthGoal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HealthGoal(
      id: fields[0] as String,
      type: fields[1] as String,
      title: fields[2] as String,
      targetValue: fields[3] as double,
      currentValue: fields[4] as double,
      unit: fields[5] as String,
      frequency: fields[6] as String,
      logs: (fields[7] as List?)?.cast<HealthLog>(),
      createdAt: fields[8] as DateTime,
      targetDate: fields[9] as DateTime?,
      isCompleted: fields[10] as bool,
      colorValue: fields[11] as int,
      icon: fields[12] as String,
      notes: fields[13] as String,
      startValue: fields[14] as double,
    );
  }

  @override
  void write(BinaryWriter writer, HealthGoal obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.targetValue)
      ..writeByte(4)
      ..write(obj.currentValue)
      ..writeByte(5)
      ..write(obj.unit)
      ..writeByte(6)
      ..write(obj.frequency)
      ..writeByte(7)
      ..write(obj.logs)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.targetDate)
      ..writeByte(10)
      ..write(obj.isCompleted)
      ..writeByte(11)
      ..write(obj.colorValue)
      ..writeByte(12)
      ..write(obj.icon)
      ..writeByte(13)
      ..write(obj.notes)
      ..writeByte(14)
      ..write(obj.startValue);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HealthGoalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HealthLogAdapter extends TypeAdapter<HealthLog> {
  @override
  final int typeId = 22;

  @override
  HealthLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HealthLog(
      id: fields[0] as String,
      value: fields[1] as double,
      date: fields[2] as DateTime,
      note: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, HealthLog obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.value)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.note);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HealthLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
