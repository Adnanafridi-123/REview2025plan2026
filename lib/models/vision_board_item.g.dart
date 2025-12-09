// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vision_board_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VisionBoardItemAdapter extends TypeAdapter<VisionBoardItem> {
  @override
  final int typeId = 10;

  @override
  VisionBoardItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VisionBoardItem(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String?,
      imagePath: fields[3] as String?,
      category: fields[4] as String,
      quote: fields[5] as String?,
      createdAt: fields[6] as DateTime,
      isCompleted: fields[7] as bool,
      priority: fields[8] as int,
    );
  }

  @override
  void write(BinaryWriter writer, VisionBoardItem obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.imagePath)
      ..writeByte(4)
      ..write(obj.category)
      ..writeByte(5)
      ..write(obj.quote)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.isCompleted)
      ..writeByte(8)
      ..write(obj.priority);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VisionBoardItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
