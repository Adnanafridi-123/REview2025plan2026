// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quote_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class QuoteItemAdapter extends TypeAdapter<QuoteItem> {
  @override
  final int typeId = 16;

  @override
  QuoteItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QuoteItem(
      id: fields[0] as String,
      text: fields[1] as String,
      category: fields[2] as String,
      author: fields[3] as String?,
      isCustom: fields[4] as bool,
      isFavorite: fields[5] as bool,
      createdAt: fields[6] as DateTime,
      backgroundGradient: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, QuoteItem obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.text)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.author)
      ..writeByte(4)
      ..write(obj.isCustom)
      ..writeByte(5)
      ..write(obj.isFavorite)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.backgroundGradient);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuoteItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
