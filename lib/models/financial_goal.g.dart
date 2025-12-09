// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'financial_goal.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FinancialGoalAdapter extends TypeAdapter<FinancialGoal> {
  @override
  final int typeId = 12;

  @override
  FinancialGoal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FinancialGoal(
      id: fields[0] as String,
      title: fields[1] as String,
      targetAmount: fields[2] as double,
      currentAmount: fields[3] as double,
      currency: fields[4] as String,
      startDate: fields[5] as DateTime,
      targetDate: fields[6] as DateTime,
      category: fields[7] as String,
      description: fields[8] as String?,
      entries: (fields[9] as List?)?.cast<SavingsEntry>(),
      isCompleted: fields[10] as bool,
      icon: fields[11] as String,
    );
  }

  @override
  void write(BinaryWriter writer, FinancialGoal obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.targetAmount)
      ..writeByte(3)
      ..write(obj.currentAmount)
      ..writeByte(4)
      ..write(obj.currency)
      ..writeByte(5)
      ..write(obj.startDate)
      ..writeByte(6)
      ..write(obj.targetDate)
      ..writeByte(7)
      ..write(obj.category)
      ..writeByte(8)
      ..write(obj.description)
      ..writeByte(9)
      ..write(obj.entries)
      ..writeByte(10)
      ..write(obj.isCompleted)
      ..writeByte(11)
      ..write(obj.icon);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FinancialGoalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SavingsEntryAdapter extends TypeAdapter<SavingsEntry> {
  @override
  final int typeId = 13;

  @override
  SavingsEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SavingsEntry(
      id: fields[0] as String,
      amount: fields[1] as double,
      date: fields[2] as DateTime,
      note: fields[3] as String?,
      isDeposit: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, SavingsEntry obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.note)
      ..writeByte(4)
      ..write(obj.isDeposit);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavingsEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
