// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'screenshot_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScreenshotItemAdapter extends TypeAdapter<ScreenshotItem> {
  @override
  final int typeId = 5;

  @override
  ScreenshotItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScreenshotItem(
      id: fields[0] as String,
      path: fields[1] as String,
      date: fields[2] as DateTime,
      caption: fields[3] as String,
      createdAt: fields[4] as DateTime,
      thumbnailPath: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ScreenshotItem obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.path)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.caption)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.thumbnailPath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScreenshotItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
