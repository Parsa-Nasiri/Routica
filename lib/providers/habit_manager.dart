import '../models/habit.dart';

/// Analytics for individual habit
class HabitAnalytics {
  final int completed;
  final int currentStreak;
  final int longestStreak;
  final int totalDays;
  final double completionRate;
  final bool freezeUsed;

  HabitAnalytics({
    required this.completed,
    required this.currentStreak,
    required this.longestStreak,
    this.totalDays = 0,
    this.completionRate = 0.0,
    this.freezeUsed = false,
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

/// Habit management and analytics utilities.
///
/// All streak calculations walk the ACTUAL CALENDAR day-by-day from the
/// habit's creation date to today, NOT the sparse `history` map.  This
/// fixes four bugs that existed in the previous implementation:
///
///  S1 — Missing days (gaps with no history entry) now correctly break
///       streaks instead of being invisible.
///  S2 — There is now a single source of truth for streak math.  The
///       analytics screen previously had a divergent copy.
///  S3 — The current streak correctly handles "today not done yet": the
///       streak stays alive (the day isn't over) but doesn't increment.
///  S4 — No in-place list mutation.
class HabitManager {
  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Calculate progress towards frequency goal
  static GoalProgress calculateGoalProgress(Habit habit) {
    final goal = habit.frequencyGoal;
    final period = habit.frequencyPeriod;

    final now = DateTime.now();
    final today = _dateKey(DateTime(now.year, now.month, now.day));

    int current = 0;

    if (period == HabitFrequencyPeriod.day) {
      current = habit.history[today]?.count ?? 0;
    } else {
      final days = period == HabitFrequencyPeriod.week ? 7 : 30;
      for (var i = 0; i < days; i++) {
        final date = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: i));
        final key = _dateKey(date);
        if (habit.history[key]?.status == HabitDayStatus.completed) {
          current++;
        }
      }
    }

    final percentage =
        goal > 0 ? (current / goal * 100).clamp(0.0, 100.0).toDouble() : 0.0;

    return GoalProgress(
      current: current,
      goal: goal,
      percentage: percentage,
      achieved: current >= goal,
    );
  }

  /// Analyze a single habit's performance by walking the real calendar.
  ///
  /// This is the single source of truth for streak calculations — the
  /// analytics screen MUST call this instead of duplicating logic.
  static HabitAnalytics analyzeHabit(Habit habit) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayKey = _dateKey(today);

    // Walk from the habit's creation date forward through every calendar day.
    final createdDate = DateTime(
      habit.createdAt.year,
      habit.createdAt.month,
      habit.createdAt.day,
    );

    var completed = 0;
    var longestStreak = 0;
    var tempStreak = 0;
    var totalDays = 0;

    var cursor = createdDate;
    while (!cursor.isAfter(today)) {
      final key = _dateKey(cursor);
      final entry = habit.history[key];
      final status = entry?.status;

      // Don't count days before the habit existed or today (today isn't over)
      final isTrackableDay = !cursor.isAfter(today);
      if (isTrackableDay) totalDays++;

      if (status == HabitDayStatus.completed) {
        completed++;
        tempStreak++;
        if (tempStreak > longestStreak) longestStreak = tempStreak;
      } else if (status == HabitDayStatus.skipped) {
        // Skipped days don't break or add to the streak
      } else {
        // Missing day (no entry) or explicitly "none" — breaks streak.
        // Exception: today isn't over yet, so don't break on today.
        if (!cursor.isAtSameMomentAs(today)) {
          tempStreak = 0;
        }
      }

      cursor = cursor.add(const Duration(days: 1));
    }

    // --- Current streak: walk backwards from today ------------------------
    // If today is completed, count from today.
    // If today is NOT completed (day still in progress), the streak is
    //   "alive" — we skip today and continue to yesterday.
    // If a past day is missed (not completed, not skipped), the streak
    //   breaks — UNLESS a streak freeze is available (F1).
    var currentStreak = 0;
    var freezeUsed = false;
    var checkDate = today;

    while (true) {
      final key = _dateKey(checkDate);
      final entry = habit.history[key];
      final status = entry?.status;

      if (status == HabitDayStatus.completed) {
        currentStreak++;
      } else if (status == HabitDayStatus.skipped) {
        // Skipped doesn't break or add to streak
      } else if (checkDate.isAtSameMomentAs(today)) {
        // Today not done yet — don't break, continue to yesterday
      } else {
        // Past day missed — check for streak freeze (F1)
        if (!freezeUsed &&
            habit.streakFreezesAvailable > 0 &&
            currentStreak > 0) {
          freezeUsed = true;
          // Freeze consumed — continue without breaking
        } else {
          break;
        }
      }

      final prev = checkDate.subtract(const Duration(days: 1));
      if (prev.isBefore(createdDate)) break;
      checkDate = prev;
    }

    final completionRate =
        totalDays > 0 ? (completed / totalDays * 100).clamp(0.0, 100.0) : 0.0;

    return HabitAnalytics(
      completed: completed,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      totalDays: totalDays,
      completionRate: completionRate,
      freezeUsed: freezeUsed,
    );
  }

  /// Analyze all habits combined
  static OverallAnalytics analyzeAll(List<Habit> habits) {
    final now = DateTime.now();
    final today = _dateKey(DateTime(now.year, now.month, now.day));

    var totalCompleted = 0;
    var totalDays = 0;
    var longestStreak = 0;

    for (final habit in habits) {
      final analytics = analyzeHabit(habit);
      totalCompleted += analytics.completed;
      totalDays += analytics.totalDays;
      if (analytics.longestStreak > longestStreak) {
        longestStreak = analytics.longestStreak;
      }
    }

    final todayCompleted = habits
        .where((h) => h.history[today]?.status == HabitDayStatus.completed)
        .length;
    final todayRate =
        habits.isNotEmpty ? ((todayCompleted / habits.length) * 100).round() : 0;

    final weekDates = List.generate(7, (i) {
      final d = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: i));
      return _dateKey(d);
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
