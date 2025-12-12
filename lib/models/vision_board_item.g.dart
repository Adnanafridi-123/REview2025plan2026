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
      type: fields[1] as String,
      content: fields[2] as String,
      title: fields[3] as String?,
      category: fields[4] as String,
      colorValue: fields[5] as int,
      positionX: fields[6] as double,
      positionY: fields[7] as double,
      width: fields[8] as double,
      height: fields[9] as double,
      createdAt: fields[10] as DateTime,
      isCompleted: fields[11] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, VisionBoardItem obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.content)
      ..writeByte(3)
      ..write(obj.title)
      ..writeByte(4)
      ..write(obj.category)
      ..writeByte(5)
      ..write(obj.colorValue)
      ..writeByte(6)
      ..write(obj.positionX)
      ..writeByte(7)
      ..write(obj.positionY)
      ..writeByte(8)
      ..write(obj.width)
      ..writeByte(9)
      ..write(obj.height)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.isCompleted);
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
