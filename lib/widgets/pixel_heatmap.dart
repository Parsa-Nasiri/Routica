import 'package:flutter/material.dart';
import '../theme/routica_theme.dart';

import '../models/habit.dart';

class PixelHeatmap extends StatefulWidget {
  const PixelHeatmap({
    super.key,
    required this.habit,
    this.onDayTap,
  });

  final Habit habit;
  final void Function(String date, HabitDayStatus status)? onDayTap;

  static const int daysToShow = 56; // 8 weeks (4 rows × 14 columns)
  static const int pixelsPerRow = 14;

  @override
  State<PixelHeatmap> createState() => _PixelHeatmapState();
}

class _PixelHeatmapState extends State<PixelHeatmap> {
  @override
  Widget build(BuildContext context) {
    final days = _buildDays();
    final rows = (days.length / PixelHeatmap.pixelsPerRow).ceil();
    final spacing = 4.0;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final totalSpacing = spacing * (PixelHeatmap.pixelsPerRow - 1);
        final pixelSize = (availableWidth - totalSpacing) / PixelHeatmap.pixelsPerRow;
        final totalHeight = (rows * pixelSize) + ((rows - 1) * spacing);

        return SizedBox(
          height: totalHeight,
          child: GridView.builder(
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: PixelHeatmap.pixelsPerRow,
              mainAxisSpacing: spacing,
              crossAxisSpacing: spacing,
              childAspectRatio: 1.0,
            ),
            itemCount: days.length,
            itemBuilder: (context, index) {
              final day = days[index];
              return _buildPixel(context, day, index);
            },
          ),
        );
      },
    );
  }

  List<_DayInfo> _buildDays() {
    // Match web: show 56 days going backwards from today
    // Web: for (let i = daysToShow - 1; i >= 0; i--)
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    
    final result = <_DayInfo>[];
    // Start from 55 days ago and go up to today (56 days total)
    for (var i = PixelHeatmap.daysToShow - 1; i >= 0; i--) {
      final date = todayDate.subtract(Duration(days: i));
      final key = date.toIso8601String().split('T').first;
      final entry = widget.habit.history[key];
      result.add(_DayInfo(date: date, key: key, entry: entry));
    }
    return result;
  }

  Widget _buildPixel(BuildContext context, _DayInfo day, int index) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final dayDate = DateTime(day.date.year, day.date.month, day.date.day);
    final isToday = dayDate.isAtSameMomentAs(todayDate);
    final habitCreatedAt = DateTime(
      widget.habit.createdAt.year,
      widget.habit.createdAt.month,
      widget.habit.createdAt.day,
    );
    final isBeforeCreation = dayDate.isBefore(habitCreatedAt);
    final isPast = dayDate.isBefore(todayDate);

    Color backgroundColor;
    switch (day.entry?.status) {
      case HabitDayStatus.completed:
        backgroundColor = Color(widget.habit.color);
        break;
      case HabitDayStatus.skipped:
        backgroundColor = RouticaTheme.textDisabled.withValues(alpha: 0.5);
        break;
      case HabitDayStatus.none:
      case null:
        if (isToday) {
          backgroundColor = Colors.white.withValues(alpha: 0.15);
        } else if (isBeforeCreation || !isPast) {
          backgroundColor = RouticaTheme.border;
        } else {
          backgroundColor = Color(widget.habit.color).withValues(alpha: 0.2);
        }
        break;
    }

    return GestureDetector(
      onTap: widget.onDayTap == null
          ? null
          : () => _showDaySheet(day),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(3),
            border: isToday
                ? Border.all(
                    color: Color(widget.habit.color).withValues(alpha: 0.6),
                    width: 1.5,
                  )
                : null,
          ),
        ),
      ),
    );
  }

  void _showDaySheet(_DayInfo day) {
    final status = day.entry?.status ?? HabitDayStatus.none;
    final habitColor = Color(widget.habit.color);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).bottomSheetTheme.backgroundColor ??
                  RouticaTheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: RouticaTheme.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 16,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with grip and date
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _formatDate(day.key),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: RouticaTheme.border, height: 1),
                // Status options
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  child: Column(
                    children: [
                      // Completed option
                      _buildStatusOption(
                        icon: Icons.check_circle,
                        label: 'Completed',
                        subtitle: 'Mark as done',
                        color: habitColor,
                        isSelected: status == HabitDayStatus.completed,
                        onTap: () {
                          widget.onDayTap?.call(day.key, HabitDayStatus.completed);
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(height: 10),
                      // Skip option
                      _buildStatusOption(
                        icon: Icons.skip_next,
                        label: 'Skip',
                        subtitle: 'Intentionally skipped',
                        color: RouticaTheme.textDisabled,
                        isSelected: status == HabitDayStatus.skipped,
                        onTap: () {
                          widget.onDayTap?.call(day.key, HabitDayStatus.skipped);
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(height: 10),
                      // Clear option
                      _buildStatusOption(
                        icon: Icons.clear,
                        label: 'Clear',
                        subtitle: 'Remove status',
                        color: RouticaTheme.textDisabled,
                        isSelected: status == HabitDayStatus.none,
                        onTap: () {
                          widget.onDayTap?.call(day.key, HabitDayStatus.none);
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: isSelected ? 0.5 : 0.2),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: color,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check, color: color, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

}

class _DayInfo {
  _DayInfo({
    required this.date,
    required this.key,
    required this.entry,
  });

  final DateTime date;
  final String key;
  final HabitHistoryEntry? entry;
}

