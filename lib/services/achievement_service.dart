import 'package:flutter/material.dart';
import '../theme/routica_theme.dart';

import '../models/achievement.dart';
import '../models/habit.dart';
import '../providers/habit_manager.dart';

/// Aggregated metrics derived from all habits, used to evaluate achievements.
class AchievementStats {
  const AchievementStats({
    required this.totalCompletions,
    required this.longestStreak,
    required this.bestCurrentStreak,
    required this.habitCount,
    required this.perfectDays,
    required this.activeDays,
  });

  /// Total number of completed days summed across every habit.
  final int totalCompletions;

  /// Best longest-streak found across all habits.
  final int longestStreak;

  /// Best current (ongoing) streak found across all habits.
  final int bestCurrentStreak;

  /// Number of habits the user is tracking.
  final int habitCount;

  /// Days on which every tracked habit was completed.
  final int perfectDays;

  /// Distinct days with at least one completion.
  final int activeDays;

  const AchievementStats.empty()
      : totalCompletions = 0,
        longestStreak = 0,
        bestCurrentStreak = 0,
        habitCount = 0,
        perfectDays = 0,
        activeDays = 0;
}

/// Computes habit statistics and evaluates the catalogue of achievements.
class AchievementService {
  static AchievementStats computeStats(List<Habit> habits) {
    if (habits.isEmpty) {
      return const AchievementStats.empty();
    }

    var totalCompletions = 0;
    var longestStreak = 0;
    var bestCurrentStreak = 0;

    // date -> number of habits completed that day.
    final completionsByDay = <String, int>{};

    for (final habit in habits) {
      final analytics = HabitManager.analyzeHabit(habit);
      totalCompletions += analytics.completed;
      if (analytics.longestStreak > longestStreak) {
        longestStreak = analytics.longestStreak;
      }
      if (analytics.currentStreak > bestCurrentStreak) {
        bestCurrentStreak = analytics.currentStreak;
      }

      habit.history.forEach((date, entry) {
        if (entry.status == HabitDayStatus.completed) {
          completionsByDay[date] = (completionsByDay[date] ?? 0) + 1;
        }
      });
    }

    final activeDays = completionsByDay.length;
    final perfectDays = completionsByDay.values
        .where((count) => count >= habits.length)
        .length;

    return AchievementStats(
      totalCompletions: totalCompletions,
      longestStreak: longestStreak,
      bestCurrentStreak: bestCurrentStreak,
      habitCount: habits.length,
      perfectDays: perfectDays,
      activeDays: activeDays,
    );
  }

  /// The full catalogue of achievements with their current progress applied.
  static List<Achievement> evaluate(AchievementStats stats) {
    return [
      // ---- Milestones: total completions -----------------------------------
      _milestone('ms_first', 'First Step',
          'Complete a habit for the very first time', Icons.flag_rounded, 1,
          stats.totalCompletions),
      _milestone('ms_10', 'Getting Started', 'Log 10 completions',
          Icons.directions_walk_rounded, 10, stats.totalCompletions),
      _milestone('ms_50', 'Habitual', 'Log 50 completions',
          Icons.auto_graph_rounded, 50, stats.totalCompletions),
      _milestone('ms_100', 'Centurion', 'Reach 100 completions',
          Icons.workspace_premium_rounded, 100, stats.totalCompletions),
      _milestone('ms_250', 'Unstoppable', 'Reach 250 completions',
          Icons.rocket_launch_rounded, 250, stats.totalCompletions),
      _milestone('ms_500', 'Legend', 'Reach 500 completions',
          Icons.military_tech_rounded, 500, stats.totalCompletions),
      _milestone('ms_1000', 'Grandmaster', 'Reach 1000 completions',
          Icons.diamond_rounded, 1000, stats.totalCompletions),

      // ---- Streaks: best longest streak ------------------------------------
      _streak('st_3', 'Spark', 'Maintain a 3-day streak',
          Icons.bolt_rounded, 3, stats.longestStreak),
      _streak('st_7', 'On Fire', 'Maintain a 7-day streak',
          Icons.local_fire_department_rounded, 7, stats.longestStreak),
      _streak('st_14', 'Fortnight Focus', 'Maintain a 14-day streak',
          Icons.whatshot_rounded, 14, stats.longestStreak),
      _streak('st_21', 'Habit Formed', 'Hit the 21-day habit threshold',
          Icons.psychology_rounded, 21, stats.longestStreak),
      _streak('st_30', 'Monthly Master', 'Maintain a 30-day streak',
          Icons.calendar_month_rounded, 30, stats.longestStreak),
      _streak('st_60', 'Iron Will', 'Maintain a 60-day streak',
          Icons.shield_rounded, 60, stats.longestStreak),
      _streak('st_100', 'Century Streak', 'Maintain a 100-day streak',
          Icons.electric_bolt_rounded, 100, stats.longestStreak),

      // ---- Consistency -----------------------------------------------------
      _consistency('cs_perfect_1', 'Flawless Day',
          'Complete every habit in a single day', Icons.verified_rounded, 1,
          stats.perfectDays),
      _consistency('cs_perfect_5', 'Perfectionist',
          'Have 5 flawless days', Icons.star_rounded, 5, stats.perfectDays),
      _consistency('cs_perfect_25', 'Impeccable',
          'Have 25 flawless days', Icons.auto_awesome_rounded, 25,
          stats.perfectDays),
      _consistency('cs_active_7', 'Showing Up',
          'Be active on 7 different days', Icons.event_available_rounded, 7,
          stats.activeDays),
      _consistency('cs_active_30', 'Dedicated Month',
          'Be active on 30 different days', Icons.calendar_today_rounded, 30,
          stats.activeDays),

      // ---- Collection: number of habits ------------------------------------
      _collection('cl_1', 'New Beginnings', 'Create your first habit',
          Icons.add_circle_rounded, 1, stats.habitCount),
      _collection('cl_3', 'Routine Builder', 'Track 3 habits at once',
          Icons.dashboard_customize_rounded, 3, stats.habitCount),
      _collection('cl_5', 'Life Architect', 'Track 5 habits at once',
          Icons.architecture_rounded, 5, stats.habitCount),
      _collection('cl_10', 'Grand Visionary', 'Track 10 habits at once',
          Icons.hub_rounded, 10, stats.habitCount),

      // ---- Dedication: best current streak ---------------------------------
      _dedication('dd_7', 'Locked In', 'Hold a 7-day active streak right now',
          Icons.lock_clock_rounded, 7, stats.bestCurrentStreak),
      _dedication('dd_30', 'Devoted', 'Hold a 30-day active streak right now',
          Icons.favorite_rounded, 30, stats.bestCurrentStreak),
    ];
  }

  static Achievement _milestone(String id, String title, String description,
      IconData icon, int target, int value) {
    return Achievement(
      id: id,
      title: title,
      description: description,
      icon: icon,
      color: const RouticaTheme.accent,
      category: AchievementCategory.milestones,
      target: target,
      value: value,
    );
  }

  static Achievement _streak(String id, String title, String description,
      IconData icon, int target, int value) {
    return Achievement(
      id: id,
      title: title,
      description: description,
      icon: icon,
      color: const RouticaTheme.warning,
      category: AchievementCategory.streaks,
      target: target,
      value: value,
    );
  }

  static Achievement _consistency(String id, String title, String description,
      IconData icon, int target, int value) {
    return Achievement(
      id: id,
      title: title,
      description: description,
      icon: icon,
      color: const RouticaTheme.infoLight,
      category: AchievementCategory.consistency,
      target: target,
      value: value,
    );
  }

  static Achievement _collection(String id, String title, String description,
      IconData icon, int target, int value) {
    return Achievement(
      id: id,
      title: title,
      description: description,
      icon: icon,
      color: const RouticaTheme.secondary,
      category: AchievementCategory.collection,
      target: target,
      value: value,
    );
  }

  static Achievement _dedication(String id, String title, String description,
      IconData icon, int target, int value) {
    return Achievement(
      id: id,
      title: title,
      description: description,
      icon: icon,
      color: const Color(0xFFF472B6),
      category: AchievementCategory.dedication,
      target: target,
      value: value,
    );
  }
}
