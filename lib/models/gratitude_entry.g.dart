// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gratitude_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GratitudeEntryAdapter extends TypeAdapter<GratitudeEntry> {
  @override
  final int typeId = 15;

  @override
  GratitudeEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GratitudeEntry(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      item1: fields[2] as String,
      item2: fields[3] as String,
      item3: fields[4] as String,
      note: fields[5] as String?,
      mood: fields[6] as String,
      imagePath: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, GratitudeEntry obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.item1)
      ..writeByte(3)
      ..write(obj.item2)
      ..writeByte(4)
      ..write(obj.item3)
      ..writeByte(5)
      ..write(obj.note)
      ..writeByte(6)
      ..write(obj.mood)
      ..writeByte(7)
      ..write(obj.imagePath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GratitudeEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
