import 'package:flutter/material.dart';

import '../models/habit.dart';
import '../theme/routica_theme.dart';

/// A full-screen monthly calendar (F4) that shows a habit's completion
/// status for each day.  Tapping a day cycles through:
/// none → completed → skipped → none.
///
/// Usage:
/// ```dart
/// Navigator.push(context, MaterialPageRoute(
///   builder: (_) => CalendarViewScreen(habit: habit, onUpdateDay: ...),
/// ));
/// ```
class CalendarViewScreen extends StatefulWidget {
  const CalendarViewScreen({
    super.key,
    required this.habit,
    required this.onUpdateDay,
  });

  final Habit habit;
  final void Function(String dateKey, HabitDayStatus status) onUpdateDay;

  @override
  State<CalendarViewScreen> createState() => _CalendarViewScreenState();
}

class _CalendarViewScreenState extends State<CalendarViewScreen> {
  late DateTime _focusedMonth;

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
    });
  }

  void _cycleDayStatus(DateTime day) {
    final key = _dateKey(day);
    final entry = widget.habit.history[key];
    final currentStatus = entry?.status ?? HabitDayStatus.none;

    // Cycle: none → completed → skipped → none
    HabitDayStatus newStatus;
    switch (currentStatus) {
      case HabitDayStatus.completed:
        newStatus = HabitDayStatus.skipped;
        break;
      case HabitDayStatus.skipped:
        newStatus = HabitDayStatus.none;
        break;
      case HabitDayStatus.none:
        newStatus = HabitDayStatus.completed;
        break;
    }

    widget.onUpdateDay(key, newStatus);
    setState(() {}); // Refresh to show new status
  }

  @override
  Widget build(BuildContext context) {
    final monthName = _monthName(_focusedMonth.month);
    final today = DateTime.now();
    final todayKey = _dateKey(DateTime(today.year, today.month, today.day));

    return Scaffold(
      backgroundColor: RouticaTheme.scaffoldBackground,
      appBar: AppBar(
        title: Text(widget.habit.title),
        backgroundColor: RouticaTheme.appBar,
        foregroundColor: RouticaTheme.textPrimary,
      ),
      body: Column(
        children: [
          // Month navigation
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left,
                      color: RouticaTheme.onSurfaceVariant),
                  onPressed: _previousMonth,
                ),
                Text(
                  '$monthName ${_focusedMonth.year}',
                  style: const TextStyle(
                    color: RouticaTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right,
                      color: RouticaTheme.onSurfaceVariant),
                  onPressed: _nextMonth,
                ),
              ],
            ),
          ),

          // Weekday headers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                  .map((d) => Expanded(
                        child: Center(
                          child: Text(
                            d,
                            style: const TextStyle(
                              color: RouticaTheme.onSurfaceVariant,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),

          // Calendar grid
          Expanded(
            child: _buildCalendarGrid(todayKey),
          ),

          // Legend
          _buildLegend(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(String todayKey) {
    final firstOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;

    // Monday = 1, Sunday = 7 → offset
    final firstWeekday = firstOfMonth.weekday;
    final leadingBlanks = firstWeekday - 1;

    final cells = <Widget>[];

    // Leading blank cells
    for (var i = 0; i < leadingBlanks; i++) {
      cells.add(const SizedBox.shrink());
    }

    // Day cells
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
      final key = _dateKey(date);
      final entry = widget.habit.history[key];
      final status = entry?.status;
      final isToday = key == todayKey;

      cells.add(_buildDayCell(
        day: day,
        date: date,
        status: status,
        isToday: isToday,
      ));
    }

    return GridView.count(
      crossAxisCount: 7,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      children: cells,
    );
  }

  Widget _buildDayCell({
    required int day,
    required DateTime date,
    required HabitDayStatus? status,
    required bool isToday,
  }) {
    Color bgColor;
    Color textColor;
    IconData? icon;

    if (status == HabitDayStatus.completed) {
      bgColor = Color(widget.habit.color);
      textColor = Colors.white;
      icon = Icons.check_rounded;
    } else if (status == HabitDayStatus.skipped) {
      bgColor = RouticaTheme.iconBg(RouticaTheme.warning);
      textColor = RouticaTheme.warning;
      icon = Icons.remove_rounded;
    } else {
      bgColor = RouticaTheme.surface;
      textColor = RouticaTheme.onSurfaceVariant;
    }

    return GestureDetector(
      onTap: () => _cycleDayStatus(date),
      child: Container(
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: isToday
              ? Border.all(color: RouticaTheme.accent, width: 2)
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '$day',
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (icon != null)
              Positioned(
                bottom: 2,
                child: Icon(icon, size: 12, color: textColor.withValues(alpha: 0.8)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _legendItem('Completed', Color(widget.habit.color), Icons.check),
          const SizedBox(width: 20),
          _legendItem('Skipped', RouticaTheme.iconBg(RouticaTheme.warning), Icons.remove),
          const SizedBox(width: 20),
          _legendItem('None', RouticaTheme.surface, null),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color, IconData? icon) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
          child: icon != null
              ? Icon(icon, size: 10, color: Colors.white.withValues(alpha: 0.8))
              : null,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: RouticaTheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _monthName(int month) {
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return names[month - 1];
  }
}
