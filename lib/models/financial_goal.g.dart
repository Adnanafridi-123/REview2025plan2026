// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'financial_goal.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FinancialGoalAdapter extends TypeAdapter<FinancialGoal> {
  @override
  final int typeId = 11;

  @override
  FinancialGoal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FinancialGoal(
      id: fields[0] as String,
      name: fields[1] as String,
      type: fields[2] as String,
      targetAmount: fields[3] as double,
      currentAmount: fields[4] as double,
      currency: fields[5] as String,
      deadline: fields[6] as DateTime,
      priority: fields[7] as String,
      notes: fields[8] as String,
      transactions: (fields[9] as List?)?.cast<FinancialTransaction>(),
      createdAt: fields[10] as DateTime,
      isCompleted: fields[11] as bool,
      completedAt: fields[12] as DateTime?,
      colorValue: fields[13] as int,
      icon: fields[14] as String,
    );
  }

  @override
  void write(BinaryWriter writer, FinancialGoal obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.targetAmount)
      ..writeByte(4)
      ..write(obj.currentAmount)
      ..writeByte(5)
      ..write(obj.currency)
      ..writeByte(6)
      ..write(obj.deadline)
      ..writeByte(7)
      ..write(obj.priority)
      ..writeByte(8)
      ..write(obj.notes)
      ..writeByte(9)
      ..write(obj.transactions)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.isCompleted)
      ..writeByte(12)
      ..write(obj.completedAt)
      ..writeByte(13)
      ..write(obj.colorValue)
      ..writeByte(14)
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

class FinancialTransactionAdapter extends TypeAdapter<FinancialTransaction> {
  @override
  final int typeId = 12;

  @override
  FinancialTransaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FinancialTransaction(
      id: fields[0] as String,
      amount: fields[1] as double,
      type: fields[2] as String,
      note: fields[3] as String,
      date: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, FinancialTransaction obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.note)
      ..writeByte(4)
      ..write(obj.date);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FinancialTransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
