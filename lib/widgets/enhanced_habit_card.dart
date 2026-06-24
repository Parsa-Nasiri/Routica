import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/habit.dart';
import '../widgets/pixel_heatmap.dart';
import '../providers/habit_manager.dart';

class EnhancedHabitCard extends StatefulWidget {
  final Habit habit;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final Function(String dateKey, HabitDayStatus status) onUpdateDay;
  final VoidCallback? onToggleToday;

  const EnhancedHabitCard({
    super.key,
    required this.habit,
    required this.onDelete,
    required this.onEdit,
    required this.onUpdateDay,
    this.onToggleToday,
  });

  @override
  State<EnhancedHabitCard> createState() => _EnhancedHabitCardState();
}

class _EnhancedHabitCardState extends State<EnhancedHabitCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late HabitAnalytics _analytics;
  late GoalProgress _goalProgress;

  @override
  void initState() {
    super.initState();
    _analytics = HabitManager.analyzeHabit(widget.habit);
    _goalProgress = HabitManager.calculateGoalProgress(widget.habit);
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );
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

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

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
                  const Color(0xFF1A2332),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0x14FFFFFF)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 16,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with grip indicator
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
                const Divider(color: Color(0x14FFFFFF), height: 1),
                // Menu items
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: Column(
                    children: [
                      // Edit option
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF3B82F6).withOpacity(0.2),
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              widget.onEdit();
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF3B82F6).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.edit,
                                      color: Color(0xFF3B82F6),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Edit Habit',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Modify habit details',
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
                      ),
                      const SizedBox(height: 10),
                      // Delete option
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFEF4444).withOpacity(0.2),
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              widget.onDelete();
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF4444).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.delete_outline,
                                      color: Color(0xFFEF4444),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Delete Habit',
                                          style: TextStyle(
                                            color: Color(0xFFEF4444),
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Remove this habit permanently',
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

  IconData _getIconForId(String id) {
    switch (id) {
      case 'brain':
        return Icons.lightbulb_outline;
      case 'dumbbell':
        return Icons.fitness_center;
      case 'book':
        return Icons.book;
      case 'droplet':
        return Icons.water;
      case 'code':
        return Icons.code;
      case 'heart':
        return Icons.favorite;
      case 'coffee':
        return Icons.local_cafe;
      case 'music':
        return Icons.music_note;
      case 'bike':
        return Icons.directions_bike;
      case 'camera':
        return Icons.camera;
      case 'palette':
        return Icons.palette;
      case 'flame':
        return Icons.local_fire_department;
      case 'moon':
        return Icons.dark_mode;
      case 'sun':
        return Icons.light_mode;
      case 'zap':
        return Icons.bolt;
      case 'target':
        return Icons.location_on;
      case 'pencil':
        return Icons.edit;
      case 'smile':
        return Icons.sentiment_satisfied;
      case 'star':
        return Icons.star;
      case 'trending':
        return Icons.trending_up;
      case 'award':
        return Icons.emoji_events;
      case 'clock':
        return Icons.schedule;
      case 'check':
        return Icons.check;
      case 'activity':
        return Icons.directions_run;
      case 'briefcase':
        return Icons.work;
      case 'gift':
        return Icons.card_giftcard;
      case 'home':
        return Icons.home;
      case 'leaf':
        return Icons.eco;
      case 'mountain':
        return Icons.terrain;
      case 'sparkles':
        return Icons.star;
      case 'users':
        return Icons.people;
      case 'wind':
        return Icons.cloud;
      case 'apple':
        return Icons.apple;
      case 'cookie':
        return Icons.fastfood;
      case 'pizza':
        return Icons.local_pizza;
      case 'sandwich':
        return Icons.lunch_dining;
      case 'salad':
        return Icons.restaurant;
      case 'soup':
        return Icons.restaurant;
      case 'water':
        return Icons.water_drop;
      case 'graduation':
        return Icons.school;
      case 'game':
        return Icons.sports_esports;
      case 'plant':
        return Icons.nature;
      case 'utensils':
        return Icons.dinner_dining;
      case 'schedule':
        return Icons.event_note;
      case 'calendar':
        return Icons.calendar_today;
      case 'hourglass':
        return Icons.hourglass_empty;
      case 'handshake':
        return Icons.handshake;
      case 'family':
        return Icons.family_restroom;
      case 'social':
        return Icons.group;
      case 'globe':
        return Icons.public;
      case 'light':
        return Icons.lightbulb;
      default:
        return Icons.lightbulb_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().toIso8601String().split('T').first;
    final todayEntry = widget.habit.history[today];
    final isCompletedToday = todayEntry?.status == HabitDayStatus.completed;
    final todayCount = todayEntry?.count ?? 0;
    final isMultiCount = widget.habit.frequencyPeriod == HabitFrequencyPeriod.day && 
                         widget.habit.frequencyGoal > 1;

    return RepaintBoundary(
      child: MouseRegion(
        onEnter: (_) => _scaleController.forward(),
        onExit: (_) => _scaleController.reverse(),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A2332),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0x14FFFFFF),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(widget.habit.color).withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(isCompletedToday, todayCount, isMultiCount),
                    if (widget.habit.description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _buildDescription(),
                    ],
                    const SizedBox(height: 8),
                    _buildGoalProgress(),
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

  Widget _buildHeader(bool isCompletedToday, int todayCount, bool isMultiCount) {
    final currentStreak = _analytics.currentStreak;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Color(widget.habit.color).withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getIconForId(widget.habit.iconId),
                  color: Color.lerp(Color(widget.habit.color), Colors.white, 0.3),
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.habit.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Color(widget.habit.color).withOpacity(0.09),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (currentStreak > 0)
                                const Text(
                                  '🔥',
                                  style: TextStyle(fontSize: 11),
                                ),
                              if (currentStreak > 0)
                                const SizedBox(width: 4),
                              Text(
                                currentStreak > 0
                                    ? '$currentStreak day${currentStreak != 1 ? 's' : ''}'
                                    : 'No streak',
                                style: TextStyle(
                                  color: Color(widget.habit.color),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.habit.frequencyGoal}/${widget.habit.frequencyPeriod.toString().split('.').last}',
                          style: const TextStyle(
                            color: Color(0xFF9AA3B2),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.more_vert, color: Color(0xFF9AA3B2)),
              onPressed: _showMenu,
              splashRadius: 24,
            ),
            const SizedBox(width: 4),
            Transform.scale(
              scale: isCompletedToday ? 1.05 : 1.0,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    if (widget.onToggleToday != null) widget.onToggleToday!();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isCompletedToday
                          ? Color(widget.habit.color)
                          : isMultiCount && todayCount > 0
                              ? Color(widget.habit.color).withOpacity(0.3)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCompletedToday
                            ? Colors.transparent
                            : isMultiCount && todayCount > 0
                                ? Color(widget.habit.color).withOpacity(0.5)
                                : const Color(0x33FFFFFF),
                        width: 2,
                      ),
                      boxShadow: null,
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.8, end: 1.0).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: isMultiCount
                          ? (isCompletedToday
                              ? const Icon(
                                  Icons.check,
                                  key: ValueKey('check'),
                                  color: Colors.white,
                                  size: 24,
                                )
                              : Text(
                                  '$todayCount/${widget.habit.frequencyGoal}',
                                  key: ValueKey('count_$todayCount'),
                                  style: TextStyle(
                                    color: todayCount > 0
                                        ? Colors.white
                                        : const Color(0xFF9AA3B2),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ))
                          : (isCompletedToday
                              ? const Icon(
                                  Icons.check,
                                  key: ValueKey('check_single'),
                                  color: Colors.white,
                                  size: 24,
                                )
                              : const SizedBox.shrink(key: ValueKey('empty'))),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Text(
      widget.habit.description,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Color(0xFF9AA3B2),
        fontSize: 14,
      ),
    );
  }

  Widget _buildGoalProgress() {
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
                color: progress.achieved ? Color(widget.habit.color) : const Color(0xFF9AA3B2),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${progress.percentage.toInt()}%',
              style: TextStyle(
                color: progress.achieved ? Color(widget.habit.color) : const Color(0xFF9AA3B2),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.percentage / 100,
              minHeight: 8,
              backgroundColor: const Color(0x28FFFFFF),
              valueColor: AlwaysStoppedAnimation<Color>(
                progress.achieved 
                  ? Color(widget.habit.color)
                  : Color(widget.habit.color).withOpacity(0.8),
              ),
            ),
          ),
        ),
      ],
    );
  }

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
