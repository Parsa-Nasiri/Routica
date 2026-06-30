import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/habit.dart';
import '../providers/habit_manager.dart';
import '../theme/routica_theme.dart';
import '../utils/habit_icons.dart';
import '../widgets/pixel_heatmap.dart';
import '../widgets/routica_animations.dart';

/// Displays overall analytics, a weekly review summary, per-habit
/// breakdowns, and AI-generated suggestions.
///
/// Redesigned with animated visualisations: a circular progress hero,
/// a 7-day bar chart, count-up stat cards, and an expandable habit
/// breakdown with mini circular progress indicators.
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({
    super.key,
    required this.habits,
    this.onBack,
  });

  final List<Habit> habits;
  final VoidCallback? onBack;

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String? _expandedHabitId;

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (widget.habits.isEmpty) {
      return _buildEmptyState();
    }

    final overall = HabitManager.analyzeAll(widget.habits);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100, top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),
          const SizedBox(height: 20),

          // Hero: animated circular progress + today's rate
          StaggerFadeIn(
            index: 0,
            child: _buildHeroCard(overall),
          ),
          const SizedBox(height: 16),

          // 7-day bar chart
          StaggerFadeIn(
            index: 1,
            child: _buildWeeklyChart(),
          ),
          const SizedBox(height: 16),

          // Stat cards row
          StaggerFadeIn(
            index: 2,
            child: _buildStatRow(overall),
          ),
          const SizedBox(height: 16),

          // Insights
          StaggerFadeIn(
            index: 3,
            child: _buildInsights(overall),
          ),
          const SizedBox(height: 16),

          // Per-habit breakdown
          StaggerFadeIn(
            index: 4,
            child: _buildHabitBreakdownsHeader(),
          ),
          const SizedBox(height: 8),
          ...widget.habits.asMap().entries.map((entry) {
            return StaggerFadeIn(
              index: 5 + entry.key,
              child: _buildHabitCard(entry.value),
            );
          }),
        ],
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      children: [
        if (widget.onBack != null)
          IconButton(
            icon: const Icon(Icons.arrow_back, color: RouticaTheme.onSurface),
            onPressed: widget.onBack,
          ),
        const SizedBox(width: 4),
        const Text(
          'Analytics',
          style: TextStyle(
            color: RouticaTheme.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        // Date badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: RouticaTheme.iconBg(RouticaTheme.accent),
            borderRadius: BorderRadius.circular(RouticaTheme.radiusPill),
          ),
          child: Text(
            _formatToday(),
            style: const TextStyle(
              color: RouticaTheme.accent,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ── Hero card with animated progress ring ────────────────────

  Widget _buildHeroCard(OverallAnalytics overall) {
    final todayPercent = overall.todayRate / 100.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: RouticaTheme.surfaceGradient,
        borderRadius: BorderRadius.circular(RouticaTheme.radiusLarge),
        border: Border.all(color: RouticaTheme.border),
      ),
      child: Row(
        children: [
          // Animated progress ring
          AnimatedProgressRing(
            percent: todayPercent,
            gradient: RouticaTheme.brandGradient,
            size: 120,
            strokeWidth: 10,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CountUpText(
                  target: overall.todayRate,
                  suffix: '%',
                  style: const TextStyle(
                    color: RouticaTheme.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Text(
                  'today',
                  style: TextStyle(
                    color: RouticaTheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // Text summary
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getMotivationMessage(overall.todayRate),
                  style: const TextStyle(
                    color: RouticaTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                _buildTodayProgress(overall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayProgress(OverallAnalytics overall) {
    final todayCompleted = widget.habits
        .where((h) =>
            h.history[_todayKey()]?.status == HabitDayStatus.completed)
        .length;
    final remaining = widget.habits.length - todayCompleted;

    return Row(
      children: [
        Icon(
          remaining == 0 ? Icons.celebration : Icons.check_circle_outline,
          color: remaining == 0 ? RouticaTheme.success : RouticaTheme.accent,
          size: 16,
        ),
        const SizedBox(width: 6),
        Text(
          remaining == 0
              ? 'All done! 🎉'
              : '$todayCompleted/${widget.habits.length} done · $remaining left',
          style: TextStyle(
            color: remaining == 0
                ? RouticaTheme.success
                : RouticaTheme.onSurfaceVariant,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _getMotivationMessage(int rate) {
    if (rate >= 80) return 'On fire! 🔥';
    if (rate >= 50) return 'Good momentum! 💪';
    if (rate >= 25) return 'Keep going! 🎯';
    return 'Every day counts! 🌱';
  }

  // ── 7-day bar chart ──────────────────────────────────────────

  Widget _buildWeeklyChart() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Build last 7 days data
    final days = <_DayData>[];
    for (var i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final key = _dateKey(date);
      var completed = 0;
      var total = widget.habits.length;
      for (final habit in widget.habits) {
        // Only count if habit existed on this day
        final created = DateTime(
          habit.createdAt.year,
          habit.createdAt.month,
          habit.createdAt.day,
        );
        if (date.isBefore(created)) {
          total--;
          continue;
        }
        if (habit.history[key]?.status == HabitDayStatus.completed) {
          completed++;
        }
      }
      final rate = total > 0 ? completed / total : 0.0;
      days.add(_DayData(
        date: date,
        completed: completed,
        total: total,
        rate: rate,
      ));
    }

    final maxRate = days.fold<double>(0, (max, d) => math.max(max, d.rate));
    final weekAvg = days.fold<double>(0, (sum, d) => sum + d.rate) / 7;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: RouticaTheme.surface,
        borderRadius: BorderRadius.circular(RouticaTheme.radiusCard),
        border: Border.all(color: RouticaTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.bar_chart, color: RouticaTheme.secondary, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Last 7 Days',
                style: TextStyle(
                  color: RouticaTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: RouticaTheme.iconBg(RouticaTheme.secondary),
                  borderRadius: BorderRadius.circular(RouticaTheme.radiusPill),
                ),
                child: Text(
                  '${(weekAvg * 100).round()}% avg',
                  style: const TextStyle(
                    color: RouticaTheme.secondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Bars
          SizedBox(
            height: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: days.asMap().entries.map((entry) {
                final i = entry.key;
                final day = entry.value;
                final isToday = i == 6;
                final barHeight =
                    maxRate > 0 ? (day.rate / maxRate) * 80 : 0.0;
                return _buildBarColumn(
                  day: day,
                  height: barHeight,
                  isToday: isToday,
                  delay: i * 60,
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          // Day labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: days.map((day) {
              final isToday = day.date.day == today.day;
              return SizedBox(
                width: 30,
                child: Text(
                  _dayLabel(day.date),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isToday
                        ? RouticaTheme.accent
                        : RouticaTheme.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBarColumn({
    required _DayData day,
    required double height,
    required bool isToday,
    required int delay,
  }) {
    final color = isToday
        ? RouticaTheme.accent
        : day.rate >= 0.75
            ? RouticaTheme.success
            : day.rate >= 0.5
                ? RouticaTheme.secondary
                : day.rate > 0
                    ? RouticaTheme.warning
                    : RouticaTheme.borderStrong;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Completion count on top
        if (day.completed > 0)
          Text(
            '${day.completed}',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        const SizedBox(height: 4),
        if (height > 0)
          AnimatedBar(
            targetHeight: height,
            color: color,
            width: 26,
            delay: delay,
          )
        else
          Container(
            width: 26,
            height: 3,
            decoration: BoxDecoration(
              color: RouticaTheme.borderStrong,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
      ],
    );
  }

  // ── Stat row ─────────────────────────────────────────────────

  Widget _buildStatRow(OverallAnalytics overall) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            icon: Icons.check_circle_outline,
            label: 'Completion',
            value: overall.completionRate,
            suffix: '%',
            color: RouticaTheme.success,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            icon: Icons.local_fire_department_outlined,
            label: 'Best Streak',
            value: overall.longestStreak,
            suffix: 'd',
            color: RouticaTheme.warning,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            icon: Icons.done_all,
            label: 'Completed',
            value: overall.totalCompleted,
            color: RouticaTheme.secondary,
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required num value,
    String suffix = '',
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: RouticaTheme.surface,
        borderRadius: BorderRadius.circular(RouticaTheme.radiusCard),
        border: Border.all(color: RouticaTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: RouticaTheme.iconBg(color),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 10),
          CountUpText(
            target: value,
            suffix: suffix,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w800,
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

  // ── Insights ─────────────────────────────────────────────────

  Widget _buildInsights(OverallAnalytics overall) {
    final suggestions = _generateSuggestions(widget.habits, overall);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            RouticaTheme.iconBg(RouticaTheme.accent),
            RouticaTheme.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(RouticaTheme.radiusCard),
        border: Border.all(color: RouticaTheme.accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: RouticaTheme.iconBg(RouticaTheme.accent),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_awesome,
                    color: RouticaTheme.accent, size: 16),
              ),
              const SizedBox(width: 8),
              const Text(
                'Insights',
                style: TextStyle(
                  color: RouticaTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...suggestions.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildInsightItem(s),
              )),
        ],
      ),
    );
  }

  Widget _buildInsightItem(_Insight s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: RouticaTheme.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: RouticaTheme.iconBg(s.color),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(s.icon, color: s.color, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              s.text,
              style: const TextStyle(
                color: RouticaTheme.onSurface,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
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
        Icons.local_fire_department,
        RouticaTheme.warning,
        '"${bestStreakHabit.title}" is on a $bestStreak-day streak. '
            'Keep the momentum going!',
      ));
    }

    // Completion rate suggestion
    if (overall.completionRate >= 80) {
      suggestions.add(_Insight(
        Icons.star,
        RouticaTheme.accent,
        'You\'re completing ${overall.completionRate}% of your habits. '
            'Outstanding consistency!',
      ));
    } else if (overall.completionRate < 40 && habits.length > 2) {
      suggestions.add(_Insight(
        Icons.lightbulb_outline,
        RouticaTheme.info,
        'Your completion rate is ${overall.completionRate}%. '
            'Consider reducing habits or adjusting frequency goals.',
      ));
    }

    // Today's progress
    final todayDone = habits
        .where((h) =>
            h.history[_todayKey()]?.status == HabitDayStatus.completed)
        .length;
    if (todayDone == habits.length) {
      suggestions.add(_Insight(
        Icons.celebration,
        RouticaTheme.success,
        'All habits completed today! Perfect day!',
      ));
    } else if (todayDone > 0) {
      suggestions.add(_Insight(
        Icons.trending_up,
        RouticaTheme.secondary,
        '$todayDone of ${habits.length} habits completed today. '
            '${habits.length - todayDone} to go!',
      ));
    } else {
      suggestions.add(_Insight(
        Icons.rocket_launch,
        RouticaTheme.primary,
        'No habits completed yet today. Pick an easy one to start!',
      ));
    }

    // Weekly rate suggestion
    if (overall.weekRate < overall.completionRate) {
      suggestions.add(_Insight(
        Icons.show_chart,
        RouticaTheme.warning,
        'This week\'s rate (${overall.weekRate}%) is below your overall '
            'average (${overall.completionRate}%). You can do better!',
      ));
    }

    return suggestions;
  }

  // ── Per-habit breakdown ──────────────────────────────────────

  Widget _buildHabitBreakdownsHeader() {
    return const Text(
      'Habit Breakdown',
      style: TextStyle(
        color: RouticaTheme.onSurfaceVariant,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildHabitCard(Habit habit) {
    final analytics = HabitManager.analyzeHabit(habit);
    final goalProgress = HabitManager.calculateGoalProgress(habit);
    final isExpanded = _expandedHabitId == habit.id;
    final habitColor = Color(habit.color);
    final completionPercent = analytics.completionRate / 100.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: RouticaTheme.surface,
        borderRadius: BorderRadius.circular(RouticaTheme.radiusCard),
        border: Border.all(
          color: isExpanded
              ? habitColor.withValues(alpha: 0.4)
              : RouticaTheme.border,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(RouticaTheme.radiusCard),
          onTap: () {
            setState(() {
              _expandedHabitId = isExpanded ? null : habit.id;
            });
          },
          child: Column(
            children: [
              // Header row (always visible)
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    // Mini progress ring
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: Stack(
                        children: [
                          AnimatedProgressRing(
                            percent: completionPercent,
                            gradient: LinearGradient(
                              colors: [
                                habitColor.withValues(alpha: 0.7),
                                habitColor,
                              ],
                            ),
                            size: 44,
                            strokeWidth: 4,
                          ),
                          Center(
                            child: Icon(
                              HabitIcons.iconForId(habit.iconId),
                              color: habitColor,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Title + streak
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            habit.title,
                            style: const TextStyle(
                              color: RouticaTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              if (analytics.freezeUsed)
                                const Padding(
                                  padding: EdgeInsets.only(right: 4),
                                  child: Text('❄️', style: TextStyle(fontSize: 12)),
                                ),
                              Icon(
                                Icons.local_fire_department,
                                color: habitColor,
                                size: 12,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${analytics.currentStreak}d streak',
                                style: TextStyle(
                                  color: habitColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '· ${analytics.completed} done',
                                style: const TextStyle(
                                  color: RouticaTheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Expand chevron
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: RouticaTheme.animFast,
                      child: const Icon(
                        Icons.keyboard_arrow_down,
                        color: RouticaTheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
              // Expandable detail
              AnimatedSize(
                duration: RouticaTheme.animMedium,
                curve: Curves.easeInOutCubic,
                child: isExpanded
                    ? _buildHabitDetail(habit, analytics, goalProgress)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHabitDetail(
    Habit habit,
    HabitAnalytics analytics,
    GoalProgress goalProgress,
  ) {
    final habitColor = Color(habit.color);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: RouticaTheme.border, height: 1),
          const SizedBox(height: 12),

          // Stats grid
          Row(
            children: [
              _buildDetailStat(
                'Completed',
                '${analytics.completed}',
                habitColor,
              ),
              _buildDetailStat(
                'Best Streak',
                '${analytics.longestStreak}d',
                habitColor,
              ),
              _buildDetailStat(
                'Rate',
                '${analytics.completionRate.round()}%',
                habitColor,
              ),
              _buildDetailStat(
                'Goal',
                '${goalProgress.current}/${goalProgress.goal}',
                habitColor,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Progress bar for goal
          if (goalProgress.goal > 0) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: goalProgress.percentage / 100,
                minHeight: 6,
                backgroundColor: habitColor.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation(habitColor),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Heatmap
          PixelHeatmap(habit: habit),
        ],
      ),
    );
  }

  Widget _buildDetailStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
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
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Empty state ─────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insights_outlined,
            size: 64,
            color: RouticaTheme.onSurfaceVariant.withValues(alpha: 0.5),
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

  // ── Helpers ──────────────────────────────────────────────────

  String _todayKey() {
    final now = DateTime.now();
    return _dateKey(now);
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _formatToday() {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final now = DateTime.now();
    return '${months[now.month - 1]} ${now.day}';
  }

  String _dayLabel(DateTime date) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return days[date.weekday - 1];
  }
}

// ── Data classes ────────────────────────────────────────────────

class _DayData {
  final DateTime date;
  final int completed;
  final int total;
  final double rate;

  _DayData({
    required this.date,
    required this.completed,
    required this.total,
    required this.rate,
  });
}

class _Insight {
  final IconData icon;
  final Color color;
  final String text;
  _Insight(this.icon, this.color, this.text);
}
