import '../models/habit.dart';

/// Analytics for individual habit
class HabitAnalytics {
  final int completed;
  final int currentStreak;
  final int longestStreak;

  HabitAnalytics({
    required this.completed,
    required this.currentStreak,
    required this.longestStreak,
  });
}

/// Goal progress tracking
class GoalProgress {
  final int current;
  final int goal;
  final double percentage;
  final bool achieved;

  GoalProgress({
    required this.current,
    required this.goal,
    required this.percentage,
    required this.achieved,
  });
}

/// Overall analytics for all habits
class OverallAnalytics {
  final int completionRate;
  final int longestStreak;
  final int todayRate;
  final int weekRate;
  final int totalCompleted;

  OverallAnalytics({
    required this.completionRate,
    required this.longestStreak,
    required this.todayRate,
    required this.weekRate,
    required this.totalCompleted,
  });
}

/// Habit management and analytics utilities
class HabitManager {
  /// Calculate progress towards frequency goal
  static GoalProgress calculateGoalProgress(Habit habit) {
    final goal = habit.frequencyGoal;
    final period = habit.frequencyPeriod;
    
    // Get date range based on period
    final now = DateTime.now();
    final today = now.toIso8601String().split('T').first;
    
    int current = 0;
    
    if (period == HabitFrequencyPeriod.day) {
      // For daily goals, use the count for today
      current = habit.history[today]?.count ?? 0;
    } else {
      // For weekly/monthly, count completed days
      final dates = <String>[];
      final days = period == HabitFrequencyPeriod.week ? 7 : 30;
      
      for (var i = 0; i < days; i++) {
        final date = now.subtract(Duration(days: i));
        dates.add(date.toIso8601String().split('T').first);
      }
      
      for (final date in dates) {
        if (habit.history[date]?.status == HabitDayStatus.completed) {
          current++;
        }
      }
    }
    
    final percentage = goal > 0 ? (current / goal * 100).clamp(0.0, 100.0).toDouble() : 0.0;
    
    return GoalProgress(
      current: current,
      goal: goal,
      percentage: percentage,
      achieved: current >= goal,
    );
  }

  /// Analyze a single habit's performance
  static HabitAnalytics analyzeHabit(Habit habit) {
    final dates = habit.history.keys.toList()..sort();
    var completed = 0;
    var currentStreak = 0;
    var longestStreak = 0;
    var tempStreak = 0;

    final today = DateTime.now().toIso8601String().split('T').first;

    for (final date in dates) {
      final status = habit.history[date]?.status;
      if (status == HabitDayStatus.completed) {
        completed++;
        tempStreak++;
        if (tempStreak > longestStreak) {
          longestStreak = tempStreak;
        }
      } else if (status != HabitDayStatus.skipped) {
        if (DateTime.parse(date).isBefore(DateTime.parse(today))) {
          tempStreak = 0;
        }
      }
    }

    // Calculate current streak (from today backwards)
    final sortedDates = dates.reversed.toList();
    for (final date in sortedDates) {
      final status = habit.history[date]?.status;
      if (status == HabitDayStatus.completed) {
        currentStreak++;
      } else if (status == HabitDayStatus.skipped) {
        // Skipped does not break streak; continue
      } else if (DateTime.parse(date).isBefore(DateTime.parse(today))) {
        break;
      }
    }

    return HabitAnalytics(
      completed: completed,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
    );
  }

  /// Analyze all habits combined
  static OverallAnalytics analyzeAll(List<Habit> habits) {
    final today = DateTime.now().toIso8601String().split('T').first;

    var totalCompleted = 0;
    var totalDays = 0;
    var longestStreak = 0;

    for (final habit in habits) {
      final dates = habit.history.keys.toList()..sort();
      var habitStreak = 0;

      for (final date in dates) {
        totalDays++;
        final status = habit.history[date]?.status;
        if (status == HabitDayStatus.completed) {
          totalCompleted++;
          habitStreak++;
        } else if (status != HabitDayStatus.skipped) {
          if (DateTime.parse(date).isBefore(DateTime.parse(today))) {
            if (habitStreak > longestStreak) {
              longestStreak = habitStreak;
            }
            habitStreak = 0;
          }
        }
      }

      if (habitStreak > longestStreak) {
        longestStreak = habitStreak;
      }
    }

    final todayCompleted = habits
        .where((h) => h.history[today]?.status == HabitDayStatus.completed)
        .length;
    final todayRate =
        habits.isNotEmpty ? ((todayCompleted / habits.length) * 100).round() : 0;

    final weekDates = List.generate(7, (i) {
      final d = DateTime.now().subtract(Duration(days: i));
      return d.toIso8601String().split('T').first;
    });

    var weekCompleted = 0;
    var weekTotal = 0;
    for (final habit in habits) {
      for (final date in weekDates) {
        weekTotal++;
        if (habit.history[date]?.status == HabitDayStatus.completed) {
          weekCompleted++;
        }
      }
    }

    final weekRate =
        weekTotal > 0 ? ((weekCompleted / weekTotal) * 100).round() : 0;
    final completionRate =
        totalDays > 0 ? ((totalCompleted / totalDays) * 100).round() : 0;

    return OverallAnalytics(
      completionRate: completionRate,
      longestStreak: longestStreak,
      todayRate: todayRate,
      weekRate: weekRate,
      totalCompleted: totalCompleted,
    );
  }
}
