import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/achievement.dart';
import '../models/habit.dart';
import '../providers/achievement_provider.dart';
import '../providers/habit_manager.dart';
import '../services/notification_service.dart';
import '../theme/routica_theme.dart';
import '../widgets/achievement_island.dart';
import '../widgets/enhanced_habit_card.dart';
import '../providers/habit_repository.dart';
import 'achievements_screen.dart';
import 'analytics_screen.dart';
import 'habit_form_screen.dart';
import 'settings_screen.dart';

class RouticaHomeScreen extends ConsumerStatefulWidget {
  const RouticaHomeScreen({super.key});

  @override
  ConsumerState<RouticaHomeScreen> createState() => _RouticaHomeScreenState();
}

/// Sort mode enum for F11.
enum _SortMode { alphabetical, streak, creation, completion }

class _RouticaHomeScreenState extends ConsumerState<RouticaHomeScreen> {
  String _currentView = 'habits';

  // ── Bug 3 fix: baseline is now computed in a ref.listen callback,
  // not during build(). Calling ref.read() inside build() was a
  // side-effect that could throw "setState during build" or fire
  // celebratory animations for already-unlocked achievements.
  Set<String>? _baseline;

  final Queue<Achievement> _celebrationQueue = Queue<Achievement>();
  OverlayEntry? _islandEntry;

  // ── F11: Search & filter state
  final _searchController = TextEditingController();
  String _searchQuery = '';
  _SortMode _sortMode = _SortMode.creation;
  String? _filterCategory;
  bool _showArchived = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _islandEntry?.remove();
    _islandEntry = null;
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
    });
  }

  // ── Achievement celebration logic ─────────────────────────────

  void _establishBaseline() {
    // Called only from ref.listen callback (not during build()).
    // Bug 3 fix: no longer called in build().
    if (_baseline != null) return;
    _baseline = ref
        .read(achievementsProvider)
        .where((a) => a.unlocked)
        .map((a) => a.id)
        .toSet();
  }

  void _reconcileAchievements(List<Achievement> achievements) {
    final baseline = _baseline;
    if (baseline == null) return;

    final unlocked = achievements.where((a) => a.unlocked).toList();
    final newIds = unlocked.map((a) => a.id).toSet().difference(baseline);
    if (newIds.isEmpty) return;

    baseline.addAll(newIds);
    for (final achievement
        in unlocked.where((a) => newIds.contains(a.id))) {
      _celebrationQueue.add(achievement);
    }
    _showNextCelebration();
  }

  void _showNextCelebration() {
    if (_islandEntry != null || _celebrationQueue.isEmpty || !mounted) return;

    final achievement = _celebrationQueue.removeFirst();
    HapticFeedback.heavyImpact();

    final entry = OverlayEntry(
      builder: (context) => AchievementIsland(
        achievement: achievement,
        onDismiss: () {
          _islandEntry?.remove();
          _islandEntry = null;
          _showNextCelebration();
        },
      ),
    );
    _islandEntry = entry;
    Overlay.of(context, rootOverlay: true).insert(entry);
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final habitsLoaded = ref.watch(habitsLoadedProvider);

    // Bug 3 fix: establish baseline via listener, not in build body.
    ref.listen<bool>(habitsLoadedProvider, (previous, loaded) {
      if (loaded && _baseline == null) {
        _establishBaseline();
      }
    });
    ref.listen<List<Achievement>>(achievementsProvider, (previous, next) {
      _reconcileAchievements(next);
    });

    return Scaffold(
      backgroundColor: RouticaTheme.scaffoldBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: habitsLoaded
              ? _buildCurrentView()
              : _buildLoadingState(),
        ),
      ),
      bottomNavigationBar: _buildNavigationBar(),
      floatingActionButton: _buildAddFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  // ── F18: Loading state ────────────────────────────────────────

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: RouticaTheme.accent),
          SizedBox(height: 16),
          Text(
            'Loading your habits...',
            style: TextStyle(color: RouticaTheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 8, bottom: 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: RouticaTheme.brandGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.track_changes_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Routica',
            style: TextStyle(
              color: RouticaTheme.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  // ── Navigation bar ───────────────────────────────────────────

  Widget _buildNavigationBar() {
    return BottomAppBar(
      elevation: 0,
      padding: EdgeInsets.zero,
      color: RouticaTheme.surface.withOpacity(0.98),
      shape: const CircularNotchedRectangle(),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              _buildNavDestination('habits', Icons.home_outlined,
                  Icons.home_rounded, 'Home'),
              _buildNavDestination('analytics', Icons.query_stats_outlined,
                  Icons.query_stats_rounded, 'Analytics'),
              const Expanded(child: SizedBox.shrink()),
              _buildNavDestination('achievements',
                  Icons.emoji_events_outlined, Icons.emoji_events_rounded, 'Awards'),
              _buildNavDestination('settings', Icons.settings_outlined,
                  Icons.settings_rounded, 'Settings'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavDestination(
    String view,
    IconData icon,
    IconData selectedIcon,
    String label,
  ) {
    final isSelected = _currentView == view;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _currentView = view);
        },
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                  color: isSelected
                      ? RouticaTheme.accent
                      : RouticaTheme.onSurfaceVariant,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
      foregroundColor: RouticaTheme.scaffoldBackground,
      elevation: 4,
      child: const Icon(Icons.add_rounded, size: 28),
    );
  }

  // ── Current view router ──────────────────────────────────────

  Widget _buildCurrentView() {
    final allHabits = ref.watch(habitRepositoryProvider);

    switch (_currentView) {
      case 'analytics':
        return AnalyticsScreen(
          habits: allHabits,
          onBack: () => setState(() => _currentView = 'habits'),
        );
      case 'achievements':
        return AchievementsScreen(
          onBack: () => setState(() => _currentView = 'habits'),
        );
      case 'settings':
        return SettingsScreen(
          onBack: () => setState(() => _currentView = 'habits'),
        );
      case 'habits':
      default:
        // F13: Onboarding hint when no habits at all
        if (allHabits.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              Expanded(child: _buildEmptyState()),
            ],
          );
        }

        // F11: Filter + sort
        final filtered = _applyFiltersAndSort(allHabits);

        // F13: Empty search results
        if (filtered.isEmpty && _searchQuery.isNotEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildSearchAndFilterBar(),
              Expanded(child: _buildNoResultsState()),
            ],
          );
        }

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            // F11: Search + filter bar
            SliverToBoxAdapter(child: _buildSearchAndFilterBar()),
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 100),
              sliver: SliverLayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount =
                      constraints.crossAxisExtent >= 1024 ? 2 : 1;
                  return SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final habit = filtered[index];
                        return EnhancedHabitCard(
                          key: ValueKey(habit.id),
                          habit: habit,
                          onDelete: () => _deleteHabitWithUndo(habit),
                          onEdit: () => _openHabitForm(existing: habit),
                          onUpdateDay: (date, status) =>
                              _updateDayStatus(habit, date, status),
                          onToggleToday: () => _toggleTodayStatus(habit),
                          onLongPress: () => _skipToday(habit),
                        );
                      },
                      childCount: filtered.length,
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

  // ── F11: Search & filter bar ─────────────────────────────────

  Widget _buildSearchAndFilterBar() {
    return Column(
      children: [
        // Compact search field — always visible
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: RouticaTheme.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search habits...',
              hintStyle: const TextStyle(
                color: RouticaTheme.onSurfaceVariant,
                fontSize: 14,
              ),
              prefixIcon: const Icon(Icons.search,
                  color: RouticaTheme.onSurfaceVariant, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear,
                          color: RouticaTheme.onSurfaceVariant, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: RouticaTheme.surface,
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(RouticaTheme.radiusPill),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(RouticaTheme.radiusPill),
                borderSide: const BorderSide(color: RouticaTheme.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(RouticaTheme.radiusPill),
                borderSide: const BorderSide(color: RouticaTheme.accent, width: 1.5),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ),

        // Category bar — horizontal pill selector
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            children: [
              // "All" pill
              _buildCategoryPill(
                label: 'All',
                emoji: null,
                icon: Icons.apps_rounded,
                selected: _filterCategory == null && !_showArchived,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _filterCategory = null;
                    _showArchived = false;
                  });
                },
              ),
              const SizedBox(width: 6),
              // Category pills
              ...HabitCategory.all.map((category) {
                final selected = _filterCategory == category;
                return _buildCategoryPill(
                  label: category,
                  emoji: HabitCategory.iconFor(category),
                  icon: null,
                  selected: selected,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _filterCategory = selected ? null : category;
                      _showArchived = false;
                    });
                  },
                );
              }),
              const SizedBox(width: 6),
              // Archived pill
              _buildCategoryPill(
                label: 'Archived',
                emoji: null,
                icon: Icons.archive_outlined,
                selected: _showArchived,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _showArchived = !_showArchived;
                    _filterCategory = null;
                  });
                },
              ),
              const SizedBox(width: 6),
              // Sort pill
              _buildSortPill(),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  /// A single category pill with animated selected state.
  Widget _buildCategoryPill({
    required String label,
    String? emoji,
    IconData? icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [RouticaTheme.secondary, RouticaTheme.primary],
                )
              : null,
          color: selected ? null : RouticaTheme.surface,
          borderRadius: BorderRadius.circular(RouticaTheme.radiusPill),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : RouticaTheme.borderStrong,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null) ...[
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
            ] else if (icon != null) ...[
              Icon(icon,
                  size: 16,
                  color: selected
                      ? Colors.white
                      : RouticaTheme.onSurfaceVariant),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? Colors.white
                    : RouticaTheme.onSurfaceVariant,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Sort mode pill with icon rotation animation.
  Widget _buildSortPill() {
    final icons = {
      _SortMode.creation: Icons.schedule_rounded,
      _SortMode.alphabetical: Icons.sort_by_alpha_rounded,
      _SortMode.streak: Icons.local_fire_department_rounded,
      _SortMode.completion: Icons.check_circle_outline_rounded,
    };
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _sortMode = _SortMode.values[
              (_sortMode.index + 1) % _SortMode.values.length];
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: RouticaTheme.accent.withOpacity(0.12),
          borderRadius: BorderRadius.circular(RouticaTheme.radiusPill),
          border: Border.all(color: RouticaTheme.accent.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icons[_sortMode] ?? Icons.sort,
                color: RouticaTheme.accent, size: 16),
            const SizedBox(width: 6),
            Text(
              _sortMode.name,
              style: const TextStyle(
                color: RouticaTheme.accent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// F11: Applies search query, category filter, archive filter, and sort.
  List<Habit> _applyFiltersAndSort(List<Habit> habits) {
    var result = habits.where((h) {
      // Archive filter: show archived habits only when toggled
      if (!_showArchived && h.archived) return false;
      if (_showArchived && !h.archived) return false;

      // Category filter
      if (_filterCategory != null && h.category != _filterCategory) {
        return false;
      }

      // Search query
      if (_searchQuery.isNotEmpty) {
        final title = h.title.toLowerCase();
        final desc = h.description.toLowerCase();
        if (!title.contains(_searchQuery) && !desc.contains(_searchQuery)) {
          return false;
        }
      }

      return true;
    }).toList();

    // Sort
    switch (_sortMode) {
      case _SortMode.alphabetical:
        result.sort((a, b) => a.title.compareTo(b.title));
        break;
      case _SortMode.streak:
        result.sort((a, b) {
          final sa = HabitManager.analyzeHabit(a).currentStreak;
          final sb = HabitManager.analyzeHabit(b).currentStreak;
          return sb.compareTo(sa); // highest first
        });
        break;
      case _SortMode.creation:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case _SortMode.completion:
        result.sort((a, b) {
          final ra = HabitManager.calculateGoalProgress(a).percentage;
          final rb = HabitManager.calculateGoalProgress(b).percentage;
          return rb.compareTo(ra); // highest first
        });
        break;
    }

    return result;
  }

  // ── Empty states ─────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.track_changes_outlined,
            size: 64,
            color: RouticaTheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No habits yet',
            style: TextStyle(
              color: RouticaTheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start building your routine!\n'
            'Tap the + button to create your first habit.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: RouticaTheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Create your first habit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: RouticaTheme.accent,
              foregroundColor: RouticaTheme.scaffoldBackground,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(RouticaTheme.radiusCard),
              ),
            ),
            onPressed: () {
              HapticFeedback.mediumImpact();
              _openHabitForm();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 48, color: RouticaTheme.onSurfaceVariant),
          const SizedBox(height: 12),
          const Text(
            'No habits found',
            style: TextStyle(color: RouticaTheme.onSurfaceVariant, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search term or filter',
            style: TextStyle(
              color: RouticaTheme.onSurfaceVariant.withOpacity(0.7),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ── Habit actions ───────────────────────────────────────────

  void _updateDayStatus(Habit habit, String dateKey, HabitDayStatus status) {
    final updatedHistory = Map<String, HabitHistoryEntry>.from(habit.history);
    updatedHistory[dateKey] =
        (habit.history[dateKey] ?? HabitHistoryEntry(status: status))
            .copyWith(status: status);

    final updatedHabit = habit.copyWith(history: updatedHistory);
    ref.read(habitRepositoryProvider.notifier).updateHabit(updatedHabit);

    // F7: Check for streak milestones
    NotificationService().checkStreakMilestones(updatedHabit);
  }

  void _toggleTodayStatus(Habit habit) {
    final today = _todayKey();
    final updatedHistory = Map<String, HabitHistoryEntry>.from(habit.history);

    final currentEntry = habit.history[today];
    final currentCount = currentEntry?.count ?? 0;
    final currentStatus = currentEntry?.status ?? HabitDayStatus.none;

    if (habit.frequencyPeriod == HabitFrequencyPeriod.day &&
        habit.frequencyGoal > 1) {
      // Multi-count: increment, wrap at goal
      if (currentCount >= habit.frequencyGoal) {
        updatedHistory[today] = HabitHistoryEntry(status: HabitDayStatus.none, count: 0);
      } else {
        final newCount = currentCount + 1;
        final newStatus = newCount >= habit.frequencyGoal
            ? HabitDayStatus.completed
            : HabitDayStatus.none;
        updatedHistory[today] = HabitHistoryEntry(status: newStatus, count: newCount);
      }
    } else {
      // Simple toggle
      final newStatus = currentStatus == HabitDayStatus.completed
          ? HabitDayStatus.none
          : HabitDayStatus.completed;
      updatedHistory[today] = HabitHistoryEntry(
        status: newStatus,
        count: newStatus == HabitDayStatus.completed ? 1 : 0,
        note: currentEntry?.note,
      );
    }

    final updatedHabit = habit.copyWith(history: updatedHistory);
    ref.read(habitRepositoryProvider.notifier).updateHabit(updatedHabit);

    // F7: Check for streak milestones
    NotificationService().checkStreakMilestones(updatedHabit);
  }

  // ── F21: Long-press to skip today ────────────────────────────

  void _skipToday(Habit habit) {
    final today = _todayKey();
    final updatedHistory = Map<String, HabitHistoryEntry>.from(habit.history);
    final currentEntry = habit.history[today];
    final isSkipped = currentEntry?.status == HabitDayStatus.skipped;

    updatedHistory[today] = HabitHistoryEntry(
      status: isSkipped ? HabitDayStatus.none : HabitDayStatus.skipped,
      count: currentEntry?.count ?? 0,
      note: currentEntry?.note,
    );

    final updatedHabit = habit.copyWith(history: updatedHistory);
    ref.read(habitRepositoryProvider.notifier).updateHabit(updatedHabit);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isSkipped
            ? 'Un-skipped "${habit.title}" for today'
            : 'Skipped "${habit.title}" for today'),
        duration: const Duration(seconds: 2),
      ),
    );
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

  // ── Helpers ──────────────────────────────────────────────────

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
