// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HabitHistoryEntryAdapter extends TypeAdapter<HabitHistoryEntry> {
  @override
  final int typeId = 2;

  @override
  HabitHistoryEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HabitHistoryEntry(
      status: fields[0] as HabitDayStatus,
      note: fields[1] as String?,
      count: fields[2] as int? ?? 1,
    );
  }

  @override
  void write(BinaryWriter writer, HabitHistoryEntry obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.status)
      ..writeByte(1)
      ..write(obj.note)
      ..writeByte(2)
      ..write(obj.count);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitHistoryEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HabitReminderAdapter extends TypeAdapter<HabitReminder> {
  @override
  final int typeId = 3;

  @override
  HabitReminder read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HabitReminder(
      time: fields[0] as String,
      days: (fields[1] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, HabitReminder obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.time)
      ..writeByte(1)
      ..write(obj.days);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitReminderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HabitAdapter extends TypeAdapter<Habit> {
  @override
  final int typeId = 4;

  @override
  Habit read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Habit(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      iconId: fields[3] as String,
      color: fields[4] as int,
      frequencyGoal: fields[5] as int,
      frequencyPeriod: fields[6] as HabitFrequencyPeriod,
      history: (fields[7] as Map).cast<String, HabitHistoryEntry>(),
      createdAt: fields[8] as DateTime,
      reminders: (fields[9] as List).cast<HabitReminder>(),
      // New fields with defaults for backward compatibility with
      // existing Hive data written before these fields existed.
      category: fields[10] as String? ?? 'General',
      archived: fields[11] as bool? ?? false,
      streakFreezesAvailable: fields[12] as int? ?? 1,
    );
  }

  @override
  void write(BinaryWriter writer, Habit obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.iconId)
      ..writeByte(4)
      ..write(obj.color)
      ..writeByte(5)
      ..write(obj.frequencyGoal)
      ..writeByte(6)
      ..write(obj.frequencyPeriod)
      ..writeByte(7)
      ..write(obj.history)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.reminders)
      ..writeByte(10)
      ..write(obj.category)
      ..writeByte(11)
      ..write(obj.archived)
      ..writeByte(12)
      ..write(obj.streakFreezesAvailable);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HabitFrequencyPeriodAdapter extends TypeAdapter<HabitFrequencyPeriod> {
  @override
  final int typeId = 0;

  @override
  HabitFrequencyPeriod read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return HabitFrequencyPeriod.day;
      case 1:
        return HabitFrequencyPeriod.week;
      case 2:
        return HabitFrequencyPeriod.month;
      default:
        return HabitFrequencyPeriod.day;
    }
  }

  @override
  void write(BinaryWriter writer, HabitFrequencyPeriod obj) {
    switch (obj) {
      case HabitFrequencyPeriod.day:
        writer.writeByte(0);
        break;
      case HabitFrequencyPeriod.week:
        writer.writeByte(1);
        break;
      case HabitFrequencyPeriod.month:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitFrequencyPeriodAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HabitDayStatusAdapter extends TypeAdapter<HabitDayStatus> {
  @override
  final int typeId = 1;

  @override
  HabitDayStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return HabitDayStatus.completed;
      case 1:
        return HabitDayStatus.none;
      case 2:
        return HabitDayStatus.skipped;
      default:
        return HabitDayStatus.none;
    }
  }

  @override
  void write(BinaryWriter writer, HabitDayStatus obj) {
    switch (obj) {
      case HabitDayStatus.completed:
        writer.writeByte(0);
        break;
      case HabitDayStatus.none:
        writer.writeByte(1);
        break;
      case HabitDayStatus.skipped:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitDayStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
