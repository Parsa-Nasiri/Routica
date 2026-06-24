// Habit model and mock data for Routica habit tracker app.
import 'package:hive/hive.dart';

part 'habit.g.dart';

@HiveType(typeId: 0)
enum HabitFrequencyPeriod {
  @HiveField(0)
  day,
  @HiveField(1)
  week,
  @HiveField(2)
  month,
}

@HiveType(typeId: 1)
enum HabitDayStatus {
  @HiveField(0)
  completed,
  @HiveField(1)
  none,
  @HiveField(2)
  skipped,
}

@HiveType(typeId: 2)
class HabitHistoryEntry {
  HabitHistoryEntry({
    required this.status,
    this.note,
    this.count = 1,
  });

  @HiveField(0)
  HabitDayStatus status;
  
  @HiveField(1)
  String? note;

  @HiveField(2)
  int count; // For multi-count habits like "5 times/day"
}

@HiveType(typeId: 3)
class HabitReminder {
  HabitReminder({
    required this.time, // HH:mm format
    required this.days, // e.g. ["Mon", "Tue", ...]
  });

  @HiveField(0)
  final String time;
  
  @HiveField(1)
  final List<String> days;
}

@HiveType(typeId: 4)
class Habit {
  Habit({
    required this.id,
    required this.title,
    required this.description,
    required this.iconId,
    required this.color,
    required this.frequencyGoal,
    required this.frequencyPeriod,
    required this.history,
    required this.createdAt,
    required this.reminders,
  });

  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String title;
  
  @HiveField(2)
  final String description;
  
  @HiveField(3)
  final String iconId;
  
  @HiveField(4)
  final int color;
  
  @HiveField(5)
  final int frequencyGoal;
  
  @HiveField(6)
  final HabitFrequencyPeriod frequencyPeriod;
  
  @HiveField(7)
  final Map<String, HabitHistoryEntry> history; // yyyy-MM-dd -> entry
  
  @HiveField(8)
  final DateTime createdAt;
  
  @HiveField(9)
  final List<HabitReminder> reminders;
}

Map<String, HabitHistoryEntry> generateMockHistory({int daysBack = 60}) {
  // Start with an empty history; pixels will only be colored
  // when the user explicitly marks a day.
  return <String, HabitHistoryEntry>{};
}

List<Habit> buildInitialHabits() {
  final now = DateTime.now();

  return [
    Habit(
      id: '1',
      title: 'Morning Meditation',
      description: 'Start the day with 10 minutes of mindfulness',
      iconId: 'brain',
      color: 0xFF8B5CF6,
      frequencyGoal: 7,
      frequencyPeriod: HabitFrequencyPeriod.week,
      history: generateMockHistory(),
      createdAt: now,
      reminders: [
        HabitReminder(
          time: '07:00',
          days: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
        ),
      ],
    ),
    Habit(
      id: '2',
      title: 'Exercise',
      description: 'At least 30 minutes of physical activity',
      iconId: 'dumbbell',
      color: 0xFFF59E0B,
      frequencyGoal: 5,
      frequencyPeriod: HabitFrequencyPeriod.week,
      history: generateMockHistory(),
      createdAt: now,
      reminders: [
        HabitReminder(
          time: '18:00',
          days: const ['Mon', 'Wed', 'Fri'],
        ),
      ],
    ),
    Habit(
      id: '3',
      title: 'Read',
      description: 'Read for 20 minutes before bed',
      iconId: 'book',
      color: 0xFF10B981,
      frequencyGoal: 1,
      frequencyPeriod: HabitFrequencyPeriod.day,
      history: generateMockHistory(),
      createdAt: now,
      reminders: [
        HabitReminder(
          time: '21:00',
          days: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
        ),
      ],
    ),
    Habit(
      id: '4',
      title: 'Hydration',
      description: 'Drink 8 glasses of water',
      iconId: 'droplet',
      color: 0xFF3B82F6,
      frequencyGoal: 1,
      frequencyPeriod: HabitFrequencyPeriod.day,
      history: generateMockHistory(),
      createdAt: now,
      reminders: const [],
    ),
    Habit(
      id: '5',
      title: 'Code Practice',
      description: 'Work on personal coding projects',
      iconId: 'code',
      color: 0xFFEC4899,
      frequencyGoal: 4,
      frequencyPeriod: HabitFrequencyPeriod.week,
      history: generateMockHistory(),
      createdAt: now,
      reminders: [
        HabitReminder(
          time: '19:00',
          days: const ['Mon', 'Tue', 'Thu', 'Sat'],
        ),
      ],
    ),
  ];
}
