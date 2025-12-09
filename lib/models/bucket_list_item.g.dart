// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bucket_list_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BucketListItemAdapter extends TypeAdapter<BucketListItem> {
  @override
  final int typeId = 14;

  @override
  BucketListItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BucketListItem(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String?,
      category: fields[3] as String,
      createdAt: fields[4] as DateTime,
      completedAt: fields[5] as DateTime?,
      isCompleted: fields[6] as bool,
      imagePath: fields[7] as String?,
      priority: fields[8] as int,
      icon: fields[9] as String,
      location: fields[10] as String?,
      estimatedCost: fields[11] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, BucketListItem obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.completedAt)
      ..writeByte(6)
      ..write(obj.isCompleted)
      ..writeByte(7)
      ..write(obj.imagePath)
      ..writeByte(8)
      ..write(obj.priority)
      ..writeByte(9)
      ..write(obj.icon)
      ..writeByte(10)
      ..write(obj.location)
      ..writeByte(11)
      ..write(obj.estimatedCost);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BucketListItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
