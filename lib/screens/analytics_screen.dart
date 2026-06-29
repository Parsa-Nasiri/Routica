import 'package:flutter/material.dart';

import '../models/habit.dart';
import '../providers/habit_manager.dart';
import '../theme/routica_theme.dart';
import '../utils/habit_icons.dart';
import '../widgets/pixel_heatmap.dart';

/// Displays overall analytics, a weekly review summary, per-habit
/// breakdowns, and AI-generated suggestions.
///
/// **Bug S2/S4 fix:** The previous version had `_calculateStats()` and
/// `_getHabitStats()` which duplicated streak logic from `HabitManager`
/// — with the same bugs (iterating the sparse history map instead of
/// walking the calendar, and mutating the same list twice).  Both have
/// been removed.  All analytics now flow through the single source of
/// truth: `HabitManager.analyzeAll()` and `HabitManager.analyzeHabit()`.
class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({
    super.key,
    required this.habits,
    this.onBack,
  });

  final List<Habit> habits;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    // F19: Empty state when no habits exist.
    if (habits.isEmpty) {
      return _buildEmptyState();
    }

    final overall = HabitManager.analyzeAll(habits);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        _buildHeader(),
        const SizedBox(height: 16),

        // Overall stat cards
        _buildOverallStats(overall),
        const SizedBox(height: 16),

        // F8: Weekly review summary
        _buildWeeklyReview(overall),
        const SizedBox(height: 16),

        // AI-style insights
        _buildInsights(overall),
        const SizedBox(height: 16),

        // Per-habit breakdown
        _buildHabitBreakdowns(),
        const SizedBox(height: 100),
      ],
    );
  }

  // ── Header ───────────────────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      children: [
        if (onBack != null)
          IconButton(
            icon: const Icon(Icons.arrow_back, color: RouticaTheme.onSurface),
            onPressed: onBack,
          ),
        const SizedBox(width: 4),
        const Text(
          'Analytics',
          style: TextStyle(
            color: RouticaTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ── F19: Empty state ─────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insights_outlined,
            size: 64,
            color: RouticaTheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No analytics yet',
            style: TextStyle(
              color: RouticaTheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start tracking habits to see insights,\n'
            'streaks, and weekly reviews here!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: RouticaTheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ── Overall stats ───────────────────────────────────────────

  Widget _buildOverallStats(OverallAnalytics overall) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            icon: Icons.check_circle_outline,
            label: 'Completion',
            value: '${overall.completionRate}%',
            color: RouticaTheme.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            icon: Icons.local_fire_department_outlined,
            label: 'Best Streak',
            value: '${overall.longestStreak}',
            color: RouticaTheme.warning,
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RouticaTheme.surface,
        borderRadius: BorderRadius.circular(RouticaTheme.radiusCard),
        border: Border.all(color: RouticaTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: RouticaTheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ── F8: Weekly review summary ────────────────────────────────

  Widget _buildWeeklyReview(OverallAnalytics overall) {
    final weekRate = overall.weekRate;
    final todayRate = overall.todayRate;

    // Motivational message based on weekly completion rate
    String emoji;
    String message;
    Color messageColor;
    if (weekRate >= 80) {
      emoji = '🔥';
      message = 'Amazing week! You\'re on fire!';
      messageColor = RouticaTheme.success;
    } else if (weekRate >= 50) {
      emoji = '💪';
      message = 'Good progress! Keep it up!';
      messageColor = RouticaTheme.accent;
    } else if (weekRate >= 25) {
      emoji = '🎯';
      message = 'Getting there — stay consistent!';
      messageColor = RouticaTheme.warning;
    } else {
      emoji = '🌱';
      message = 'Every day is a new chance to grow!';
      messageColor = RouticaTheme.info;
    }

    final todayCompleted = habits
        .where((h) =>
            h.history[_todayKey()]?.status == HabitDayStatus.completed)
        .length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            messageColor.withOpacity(0.15),
            RouticaTheme.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(RouticaTheme.radiusLarge),
        border: Border.all(color: messageColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              const Text(
                'Weekly Review',
                style: TextStyle(
                  color: RouticaTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Big completion rate
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$weekRate%',
                style: TextStyle(
                  color: messageColor,
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: const Text(
                  'this week',
                  style: TextStyle(
                    color: RouticaTheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: messageColor,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),

          // Mini stats row
          Row(
            children: [
              Expanded(
                child: _miniStat(
                  label: 'Today',
                  value: '$todayCompleted/${habits.length}',
                  icon: Icons.today_outlined,
                  color: RouticaTheme.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _miniStat(
                  label: 'Today Rate',
                  value: '$todayRate%',
                  icon: Icons.check_circle_outline,
                  color: RouticaTheme.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _miniStat(
                  label: 'Best Streak',
                  value: '${overall.longestStreak}d',
                  icon: Icons.local_fire_department_outlined,
                  color: RouticaTheme.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(RouticaTheme.radiusCard),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: RouticaTheme.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ── AI-style insights ────────────────────────────────────────

  Widget _buildInsights(OverallAnalytics overall) {
    final suggestions = _generateSuggestions(habits, overall);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RouticaTheme.surface,
        borderRadius: BorderRadius.circular(RouticaTheme.radiusCard),
        border: Border.all(color: RouticaTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: RouticaTheme.accent, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Insights',
                style: TextStyle(
                  color: RouticaTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...suggestions.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.emoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        s.text,
                        style: const TextStyle(
                          color: RouticaTheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  List<_Insight> _generateSuggestions(
      List<Habit> habits, OverallAnalytics overall) {
    final suggestions = <_Insight>[];

    // Streak-based suggestion
    Habit? bestStreakHabit;
    var bestStreak = 0;
    for (final habit in habits) {
      final analytics = HabitManager.analyzeHabit(habit);
      if (analytics.currentStreak > bestStreak) {
        bestStreak = analytics.currentStreak;
        bestStreakHabit = habit;
      }
    }
    if (bestStreak >= 7 && bestStreakHabit != null) {
      suggestions.add(_Insight(
        '🔥',
        '"${bestStreakHabit.title}" is on a $bestStreak-day streak. '
        'Keep the momentum going!',
      ));
    }

    // Completion rate suggestion
    if (overall.completionRate >= 80) {
      suggestions.add(_Insight(
        '⭐',
        'You\'re completing ${overall.completionRate}% of your habits. '
        'Outstanding consistency!',
      ));
    } else if (overall.completionRate < 40 && habits.length > 2) {
      suggestions.add(_Insight(
        '💡',
        'Your completion rate is ${overall.completionRate}%. '
        'Consider reducing the number of habits or adjusting frequency goals.',
      ));
    }

    // Today's progress
    final todayDone = habits
        .where((h) =>
            h.history[_todayKey()]?.status == HabitDayStatus.completed)
        .length;
    if (todayDone == habits.length) {
      suggestions.add(_Insight('🎉', 'All habits completed today! Perfect day!'));
    } else if (todayDone > 0) {
      suggestions.add(_Insight(
        '📌',
        '$todayDone of ${habits.length} habits completed today. '
        '${habits.length - todayDone} to go!',
      ));
    } else {
      suggestions.add(_Insight(
        '🚀',
        'No habits completed yet today. Pick an easy one to start!',
      ));
    }

    // Weekly rate suggestion
    if (overall.weekRate < overall.completionRate) {
      suggestions.add(_Insight(
        '📈',
        'This week\'s rate (${overall.weekRate}%) is below your overall '
        'average (${overall.completionRate}%). You can do better!',
      ));
    }

    return suggestions;
  }

  // ── Per-habit breakdown ──────────────────────────────────────

  Widget _buildHabitBreakdowns() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Habit Breakdown',
          style: TextStyle(
            color: RouticaTheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        ...habits.map((habit) => _buildHabitRow(habit)),
      ],
    );
  }

  Widget _buildHabitRow(Habit habit) {
    final analytics = HabitManager.analyzeHabit(habit);
    final goalProgress = HabitManager.calculateGoalProgress(habit);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RouticaTheme.surface,
        borderRadius: BorderRadius.circular(RouticaTheme.radiusCard),
        border: Border.all(color: RouticaTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Color(habit.color).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _iconForId(habit.iconId),
                  color: Color(habit.color),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  habit.title,
                  style: const TextStyle(
                    color: RouticaTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (analytics.freezeUsed)
                const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Text('❄️', style: TextStyle(fontSize: 14)),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(habit.color).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(RouticaTheme.radiusPill),
                ),
                child: Text(
                  '🔥 ${analytics.currentStreak}',
                  style: TextStyle(
                    color: Color(habit.color),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Stats row
          Row(
            children: [
              _buildMiniStat('Completed', '${analytics.completed}'),
              const SizedBox(width: 16),
              _buildMiniStat('Longest', '${analytics.longestStreak}d'),
              const SizedBox(width: 16),
              _buildMiniStat('Rate', '${analytics.completionRate.round()}%'),
              const SizedBox(width: 16),
              _buildMiniStat(
                'Goal',
                '${goalProgress.current}/${goalProgress.goal}',
              ),
            ],
          ),

          // Heatmap
          const SizedBox(height: 12),
          PixelHeatmap(
            history: habit.history,
            color: Color(habit.color),
            cellSize: 14,
            cellSpacing: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: RouticaTheme.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: RouticaTheme.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  // ── Helpers ──────────────────────────────────────────────────

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  IconData _iconForId(String id) {
    // Use the shared utility — avoids the old duplicated 50-case switch.
    return HabitIcons.iconForId(id);
  }
}

class _Insight {
  final String emoji;
  final String text;
  _Insight(this.emoji, this.text);
}
