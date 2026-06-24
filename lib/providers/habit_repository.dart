import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/habit.dart';
import '../services/notification_service.dart';

class HabitRepository extends Notifier<List<Habit>> {
  late Box<Habit> _box;
  final _notificationService = NotificationService();

  @override
  List<Habit> build() {
    _initBox();
    return [];
  }

  Future<void> _initBox() async {
    _box = await Hive.openBox<Habit>('habits');
    state = _box.values.toList();
    
    // If empty, add initial habits
    if (state.isEmpty) {
      final initialHabits = buildInitialHabits();
      for (final habit in initialHabits) {
        await _box.put(habit.id, habit);
      }
      state = _box.values.toList();
    }

    // Signal that the initial load from storage is complete so listeners can
    // distinguish "freshly loaded data" from genuine in-session changes.
    ref.read(habitsLoadedProvider.notifier).markLoaded();

    // Schedule notifications for existing habits
    for (final habit in state) {
      if (habit.reminders.isNotEmpty) {
        await _notificationService.scheduleHabitReminders(habit);
      }
    }
  }

  Future<void> addHabit(Habit habit) async {
    await _box.put(habit.id, habit);
    state = _box.values.toList();
    
    // Schedule notifications if habit has reminders
    if (habit.reminders.isNotEmpty) {
      await _notificationService.scheduleHabitReminders(habit);
    }
  }

  Future<void> updateHabit(Habit habit) async {
    await _box.put(habit.id, habit);
    state = _box.values.toList();
    
    // Reschedule notifications
    if (habit.reminders.isNotEmpty) {
      await _notificationService.scheduleHabitReminders(habit);
    } else {
      await _notificationService.cancelHabitReminders(habit.id);
    }
  }

  Future<void> deleteHabit(String habitId) async {
    await _box.delete(habitId);
    state = _box.values.toList();
    
    // Cancel notifications for deleted habit
    await _notificationService.cancelHabitReminders(habitId);
  }

  Future<void> reorderHabits(List<Habit> reordered) async {
    // Update all habits in the box with new order
    await _box.clear();
    for (final habit in reordered) {
      await _box.put(habit.id, habit);
    }
    state = reordered;
  }

  Future<void> clearAll() async {
    await _box.clear();
    state = [];
    
    // Cancel all notifications
    await _notificationService.cancelAllNotifications();
  }
}

final habitRepositoryProvider = NotifierProvider<HabitRepository, List<Habit>>(() {
  return HabitRepository();
});

/// Becomes `true` once the habit repository has finished its initial load from
/// storage. Used to establish the achievement "baseline" so already-unlocked
/// achievements are not re-celebrated on app launch.
class HabitsLoadedNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void markLoaded() => state = true;
}

final habitsLoadedProvider =
    NotifierProvider<HabitsLoadedNotifier, bool>(HabitsLoadedNotifier.new);
