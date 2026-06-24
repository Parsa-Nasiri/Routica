import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/habit.dart';
import '../theme/routica_theme.dart';
import '../widgets/enhanced_habit_card.dart';
import '../providers/habit_repository.dart';
import 'analytics_screen.dart';
import 'habit_form_screen.dart';  
import 'settings_screen.dart';

class RouticaHomeScreen extends ConsumerStatefulWidget {
  const RouticaHomeScreen({super.key});

  @override
  ConsumerState<RouticaHomeScreen> createState() => _RouticaHomeScreenState();
}

class _RouticaHomeScreenState extends ConsumerState<RouticaHomeScreen> {
  String _currentView = 'habits'; // 'habits' | 'analytics' | 'settings'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C1421),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildCurrentView(),
        ),
      ),
      bottomNavigationBar: _buildNavigationBar(),
      floatingActionButton: _buildAddFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 8, bottom: 16),
      child: const Text(
        'Routica',
        style: TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: RouticaTheme.surface.withOpacity(0.98),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavDestination(0, Icons.home_outlined, Icons.home_rounded, 'Home'),
              _buildNavDestination(1, Icons.query_stats_outlined, Icons.query_stats_rounded, 'Analytics'),
              const SizedBox(width: 56),
              _buildNavDestination(2, Icons.settings_outlined, Icons.settings_rounded, 'Settings'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavDestination(
    int index,
    IconData icon,
    IconData selectedIcon,
    String label,
  ) {
    final view = index == 0 ? 'habits' : index == 1 ? 'analytics' : 'settings';
    final isSelected = _currentView == view;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _currentView = view);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? RouticaTheme.accent.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              size: 24,
              color: isSelected ? RouticaTheme.accent : RouticaTheme.onSurfaceVariant,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? RouticaTheme.accent
                    : RouticaTheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddFAB() {
    return FloatingActionButton(
      onPressed: () {
        HapticFeedback.mediumImpact();
        _openHabitForm();
      },
      backgroundColor: RouticaTheme.accent,
      foregroundColor: const Color(0xFF0C1421),
      elevation: 4,
      child: const Icon(Icons.add_rounded, size: 28),
    );
  }

  Widget _buildCurrentView() {
    final habits = ref.watch(habitRepositoryProvider);
    
    switch (_currentView) {
      case 'analytics':
        return AnalyticsScreen(
          habits: habits,
          onBack: () {
            setState(() {
              _currentView = 'habits';
            });
          },
        );
      case 'settings':
        return SettingsScreen(
          onBack: () {
            setState(() {
              _currentView = 'habits';
            });
          },
        );
      case 'habits':
      default:
        if (habits.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              Expanded(child: _buildEmptyState()),
            ],
          );
        }
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 100),
              sliver: SliverLayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.crossAxisExtent >= 1024 ? 2 : 1;
                  return SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final habit = habits[index];
                        return EnhancedHabitCard(
                          key: ValueKey(habit.id),
                          habit: habit,
                          onDelete: () => _deleteHabitWithUndo(habit),
                          onEdit: () => _openHabitForm(existing: habit),
                          onUpdateDay: (date, status) => _updateDayStatus(habit, date, status),
                          onToggleToday: () => _toggleTodayStatus(habit),
                        );
                      },
                      childCount: habits.length,
                      addAutomaticKeepAlives: false,
                    ),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisExtent: 280,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                  );
                },
              ),
            ),
          ],
        );
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.calendar_today, size: 48, color: Color(0xFF9AA3B2)),
          const SizedBox(height: 12),
          const Text(
            'No habits yet. Start building your routine!',
            style: TextStyle(color: Color(0xFF9AA3B2)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Create your first habit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: RouticaTheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () {
              _openHabitForm();
            },
          ),
        ],
      ),
    );
  }


  void _updateDayStatus(Habit habit, String dateKey, HabitDayStatus status) {
    final updatedHistory = Map<String, HabitHistoryEntry>.from(habit.history);
    updatedHistory[dateKey] = HabitHistoryEntry(status: status);

    final updatedHabit = Habit(
      id: habit.id,
      title: habit.title,
      description: habit.description,
      iconId: habit.iconId,
      color: habit.color,
      frequencyGoal: habit.frequencyGoal,
      frequencyPeriod: habit.frequencyPeriod,
      history: updatedHistory,
      createdAt: habit.createdAt,
      reminders: habit.reminders,
    );
    
    ref.read(habitRepositoryProvider.notifier).updateHabit(updatedHabit);
  }

  Future<void> _openHabitForm({Habit? existing}) async {
    final result = await Navigator.of(context).push<HabitFormResult>(
      MaterialPageRoute(
        builder: (_) => HabitFormScreen(existing: existing),
      ),
    );

    if (result == null) return;
    
    if (existing != null) {
      await ref.read(habitRepositoryProvider.notifier).updateHabit(result.habit);
    } else {
      await ref.read(habitRepositoryProvider.notifier).addHabit(result.habit);
    }
  }


  void _deleteHabitWithUndo(Habit habit) {
    ref.read(habitRepositoryProvider.notifier).deleteHabit(habit.id);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Habit "${habit.title}" deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            ref.read(habitRepositoryProvider.notifier).addHabit(habit);
          },
        ),
      ),
    );
  }

  void _toggleTodayStatus(Habit habit) {
    final today = DateTime.now().toIso8601String().split('T').first;
    final updatedHistory = Map<String, HabitHistoryEntry>.from(habit.history);
    
    final currentEntry = habit.history[today];
    final currentCount = currentEntry?.count ?? 0;
    final currentStatus = currentEntry?.status ?? HabitDayStatus.none;
    
    // For daily frequency: support multi-count (e.g., 5/day)
    if (habit.frequencyPeriod == HabitFrequencyPeriod.day && habit.frequencyGoal > 1) {
      // Increment count, reset to 0 if already at goal
      if (currentCount >= habit.frequencyGoal) {
        // Reset to 0
        updatedHistory[today] = HabitHistoryEntry(status: HabitDayStatus.none, count: 0);
      } else {
        // Increment
        final newCount = currentCount + 1;
        final newStatus = newCount >= habit.frequencyGoal 
            ? HabitDayStatus.completed 
            : HabitDayStatus.none;
        updatedHistory[today] = HabitHistoryEntry(status: newStatus, count: newCount);
      }
    } else {
      // Simple toggle for non-daily or 1/day habits
      final newStatus = currentStatus == HabitDayStatus.completed
          ? HabitDayStatus.none
          : HabitDayStatus.completed;
      updatedHistory[today] = HabitHistoryEntry(status: newStatus, count: newStatus == HabitDayStatus.completed ? 1 : 0);
    }

    final updatedHabit = Habit(
      id: habit.id,
      title: habit.title,
      description: habit.description,
      iconId: habit.iconId,
      color: habit.color,
      frequencyGoal: habit.frequencyGoal,
      frequencyPeriod: habit.frequencyPeriod,
      history: updatedHistory,
      createdAt: habit.createdAt,
      reminders: habit.reminders,
    );
    
    ref.read(habitRepositoryProvider.notifier).updateHabit(updatedHabit);
  }
}
