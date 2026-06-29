import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/habit.dart';
import '../widgets/pixel_heatmap.dart';
import '../providers/habit_manager.dart';
import '../theme/routica_theme.dart';
import '../utils/habit_icons.dart';

/// A polished, performant habit card.
///
/// Design decisions:
///  • No [MouseRegion] / hover scale — mobile-only, saves an animation
///    controller per card and reduces repaint cost.
///  • Left accent border lights up when today is completed — instant
///    visual feedback without animation overhead.
///  • Icon tile tints toward the habit colour when completed.
///  • Stats are inline text with dot separators — lighter weight than
///    badge containers, reads better at small sizes.
///  • [RepaintBoundary] isolates each card so toggling one habit
///    doesn't repaint the entire grid.
class EnhancedHabitCard extends StatefulWidget {
  final Habit habit;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final Function(String dateKey, HabitDayStatus status) onUpdateDay;
  final VoidCallback? onToggleToday;
  final VoidCallback? onLongPress;

  const EnhancedHabitCard({
    super.key,
    required this.habit,
    required this.onDelete,
    required this.onEdit,
    required this.onUpdateDay,
    this.onToggleToday,
    this.onLongPress,
  });

  @override
  State<EnhancedHabitCard> createState() => _EnhancedHabitCardState();
}

class _EnhancedHabitCardState extends State<EnhancedHabitCard> {
  late HabitAnalytics _analytics;
  late GoalProgress _goalProgress;

  @override
  void initState() {
    super.initState();
    _analytics = HabitManager.analyzeHabit(widget.habit);
    _goalProgress = HabitManager.calculateGoalProgress(widget.habit);
  }

  @override
  void didUpdateWidget(covariant EnhancedHabitCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.habit.id != widget.habit.id ||
        oldWidget.habit.history != widget.habit.history) {
      _analytics = HabitManager.analyzeHabit(widget.habit);
      _goalProgress = HabitManager.calculateGoalProgress(widget.habit);
    }
  }

  // ── Menu (bottom sheet) ──────────────────────────────────────

  void _showMenu() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).bottomSheetTheme.backgroundColor ??
                  RouticaTheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: RouticaTheme.border),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Grip handle
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Habit Options',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: RouticaTheme.border, height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: Column(
                    children: [
                      _buildMenuOption(
                        icon: Icons.edit_outlined,
                        label: 'Edit Habit',
                        subtitle: 'Modify habit details',
                        color: RouticaTheme.info,
                        onTap: () {
                          Navigator.pop(context);
                          widget.onEdit();
                        },
                      ),
                      const SizedBox(height: 10),
                      _buildMenuOption(
                        icon: Icons.delete_outline,
                        label: 'Delete Habit',
                        subtitle: 'Remove this habit permanently',
                        color: RouticaTheme.danger,
                        onTap: () {
                          Navigator.pop(context);
                          widget.onDelete();
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

  Widget _buildMenuOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
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
                    color: color.withOpacity(0.2),
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
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withOpacity(0.3),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().toIso8601String().split('T').first;
    final todayEntry = widget.habit.history[today];
    final isCompletedToday = todayEntry?.status == HabitDayStatus.completed;
    final todayCount = todayEntry?.count ?? 0;
    final hasNoteToday =
        todayEntry?.note != null && todayEntry!.note!.isNotEmpty;
    final isMultiCount =
        widget.habit.frequencyPeriod == HabitFrequencyPeriod.day &&
            widget.habit.frequencyGoal > 1;

    final habitColor = Color(widget.habit.color);

    return RepaintBoundary(
      child: GestureDetector(
        onTap: widget.onToggleToday == null
            ? null
            : () {
                HapticFeedback.lightImpact();
                widget.onToggleToday!();
              },
        onLongPress: widget.onLongPress == null
            ? null
            : () {
                HapticFeedback.heavyImpact();
                widget.onLongPress!();
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: RouticaTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isCompletedToday
                  ? habitColor.withOpacity(0.4)
                  : RouticaTheme.border,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: habitColor.withOpacity(isCompletedToday ? 0.15 : 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    width: 4,
                    color: isCompletedToday
                        ? habitColor
                        : habitColor.withOpacity(0.15),
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 14, 14, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildHeader(
                            habitColor,
                            isCompletedToday,
                            todayCount,
                            isMultiCount,
                          ),
                          if (widget.habit.description.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            _buildDescription(),
                          ],
                          const SizedBox(height: 10),
                          _buildStatsRow(
                            habitColor,
                            hasNoteToday,
                          ),
                          const SizedBox(height: 8),
                          _buildGoalProgress(habitColor),
                          const SizedBox(height: 10),
                          _buildHeatmap(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  // ── Header ───────────────────────────────────────────────────

  Widget _buildHeader(
    Color habitColor,
    bool isCompletedToday,
    int todayCount,
    bool isMultiCount,
  ) {
    return Row(
      children: [
        // Icon tile
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isCompletedToday
                ? habitColor.withOpacity(0.35)
                : habitColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            HabitIcons.iconForId(widget.habit.iconId),
            color: isCompletedToday
                ? Color.lerp(habitColor, Colors.white, 0.2)
                : habitColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        // Title + category
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.habit.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: isCompletedToday
                      ? FontWeight.w600
                      : FontWeight.w500,
                  decoration: isCompletedToday
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                  decorationColor: Colors.white38,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.habit.category,
                style: const TextStyle(
                  color: RouticaTheme.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        // More menu
        IconButton(
          icon: const Icon(Icons.more_vert,
              color: RouticaTheme.onSurfaceVariant, size: 20),
          onPressed: _showMenu,
          splashRadius: 20,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
        const SizedBox(width: 2),
        // Completion circle
        _buildCompletionCircle(
          habitColor,
          isCompletedToday,
          todayCount,
          isMultiCount,
        ),
      ],
    );
  }

  Widget _buildCompletionCircle(
    Color habitColor,
    bool isCompletedToday,
    int todayCount,
    bool isMultiCount,
  ) {
    return GestureDetector(
      onTap: widget.onToggleToday == null
          ? null
          : () {
              if (!isCompletedToday) {
                HapticFeedback.mediumImpact();
              } else {
                HapticFeedback.lightImpact();
              }
              widget.onToggleToday?.call();
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isCompletedToday
              ? habitColor
              : isMultiCount && todayCount > 0
                  ? habitColor.withOpacity(0.25)
                  : Colors.transparent,
          border: Border.all(
            color: isCompletedToday
                ? Colors.transparent
                : isMultiCount && todayCount > 0
                    ? habitColor.withOpacity(0.5)
                    : RouticaTheme.borderStrong,
            width: 2,
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isMultiCount
              ? (isCompletedToday
                  ? const Icon(Icons.check,
                      key: ValueKey('check_multi'),
                      color: Colors.white,
                      size: 22)
                  : Text(
                      '$todayCount/${widget.habit.frequencyGoal}',
                      key: ValueKey('count_$todayCount'),
                      style: TextStyle(
                        color: todayCount > 0
                            ? Colors.white
                            : RouticaTheme.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ))
              : (isCompletedToday
                  ? const Icon(Icons.check,
                      key: ValueKey('check_single'),
                      color: Colors.white,
                      size: 22)
                  : const SizedBox.shrink(key: ValueKey('empty'))),
        ),
      ),
    );
  }

  // ── Description ──────────────────────────────────────────────

  Widget _buildDescription() {
    return Text(
      widget.habit.description,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: RouticaTheme.onSurfaceVariant,
        fontSize: 13,
      ),
    );
  }

  // ── Stats row ────────────────────────────────────────────────

  Widget _buildStatsRow(
    Color habitColor,
    bool hasNoteToday,
  ) {
    final currentStreak = _analytics.currentStreak;
    final periodName = widget.habit.frequencyPeriod.toString().split('.').last;

    // Build stat items with dot separators
    final items = <Widget>[];

    // Streak
    if (currentStreak > 0) {
      items.add(_buildStatItem(
        '🔥 $currentStreak',
        currentStreak == 1 ? 'day' : 'days',
        habitColor,
      ));
    }

    // Frequency
    items.add(_buildStatItem(
      '${widget.habit.frequencyGoal}',
      periodName,
      RouticaTheme.onSurfaceVariant,
    ));

    // Streak freeze
    if (_analytics.freezeUsed) {
      items.add(_buildStatItem('❄️', 'frozen', RouticaTheme.onSurfaceVariant));
    }

    // Note
    if (hasNoteToday) {
      items.add(_buildStatItem('📝', 'note', RouticaTheme.onSurfaceVariant));
    }

    // Best streak
    if (_analytics.longestStreak > 0 && _analytics.longestStreak != currentStreak) {
      items.add(_buildStatItem(
        '🏆 ${_analytics.longestStreak}',
        'best',
        RouticaTheme.onSurfaceVariant,
      ));
    }

    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                '•',
                style: TextStyle(
                  color: RouticaTheme.borderStrong,
                  fontSize: 12,
                ),
              ),
            ),
          items[i],
        ],
      ],
    );
  }

  Widget _buildStatItem(String value, String label, Color color) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$value ',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(
            text: label,
            style: const TextStyle(
              color: RouticaTheme.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ── Goal progress ────────────────────────────────────────────

  Widget _buildGoalProgress(Color habitColor) {
    final progress = _goalProgress;
    final periodName = widget.habit.frequencyPeriod.toString().split('.').last;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${progress.current}/${progress.goal} this $periodName',
              style: TextStyle(
                color: progress.achieved
                    ? habitColor
                    : RouticaTheme.onSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${progress.percentage.toInt()}%',
              style: TextStyle(
                color: progress.achieved
                    ? habitColor
                    : RouticaTheme.onSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: progress.percentage / 100,
            minHeight: 6,
            backgroundColor: habitColor.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
              progress.achieved
                  ? habitColor
                  : habitColor.withOpacity(0.7),
            ),
          ),
        ),
      ],
    );
  }

  // ── Heatmap ──────────────────────────────────────────────────

  Widget _buildHeatmap() {
    return SizedBox(
      width: double.infinity,
      child: PixelHeatmap(
        habit: widget.habit,
        onDayTap: (date, status) {
          HapticFeedback.selectionClick();
          widget.onUpdateDay(date, status);
        },
      ),
    );
  }
}
