import 'package:flutter/material.dart';
import '../theme/routica_theme.dart';

import '../models/habit.dart';
import '../utils/habit_icons.dart';
import '../utils/logger.dart';

class HabitFormResult {
  HabitFormResult({
    required this.habit,
  });

  final Habit habit;
}

class HabitFormScreen extends StatefulWidget {
  const HabitFormScreen({
    super.key,
    this.existing,
  });

  final Habit? existing;

  @override
  State<HabitFormScreen> createState() => _HabitFormScreenState();
}

class _HabitFormScreenState extends State<HabitFormScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _frequencyGoalController;
  late TextEditingController _hexController;
  late int _frequencyGoal;
  late HabitFrequencyPeriod _frequencyPeriod;
  late String _iconId;
  late int _color;
  late String _category;
  late bool _archived;
  TimeOfDay? _reminderTime;
  late List<String> _reminderDays;
  late bool _remindersEnabled;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existing?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.existing?.description ?? '');
    _frequencyGoal = widget.existing?.frequencyGoal ?? 1;
    _frequencyGoalController = TextEditingController(text: _frequencyGoal.toString());
    _frequencyPeriod = widget.existing?.frequencyPeriod ?? HabitFrequencyPeriod.day;

    _iconId = widget.existing?.iconId ?? 'brain';
    _color = widget.existing?.color ?? 0xFF8B5CF6;
    _category = widget.existing?.category ?? HabitCategory.general;
    _archived = widget.existing?.archived ?? false;

    // Bug 1 fix: _hexController is created ONCE here in initState() and
    // disposed in dispose(). Previously it was recreated in
    // didChangeDependencies() (which runs on every dependency change),
    // leaking the previous controller each time. We now only ever update
    // its .text inside a setState() when the color changes — never
    // recreate the controller.
    _hexController = TextEditingController(
      text: '#${_color.toRadixString(16).substring(2).toUpperCase()}',
    );

    if (widget.existing != null && widget.existing!.reminders.isNotEmpty) {
      final first = widget.existing!.reminders.first;
      final parts = first.time.split(':');
      if (parts.length == 2) {
        final hour = int.tryParse(parts[0]) ?? 9;
        final minute = int.tryParse(parts[1]) ?? 0;
        _reminderTime = TimeOfDay(hour: hour, minute: minute);
      }
      _reminderDays = List<String>.from(first.days);
      _remindersEnabled = true;
    } else {
      _reminderDays = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      _remindersEnabled = false;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _frequencyGoalController.dispose();
    _hexController.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      Log.w('Save aborted: habit title is empty.');
      return;
    }

    final existing = widget.existing;
    final now = DateTime.now();

    final reminders = <HabitReminder>[];
    if (_remindersEnabled && _reminderTime != null) {
      final hour = _reminderTime!.hour.toString().padLeft(2, '0');
      final minute = _reminderTime!.minute.toString().padLeft(2, '0');
      reminders.add(
        HabitReminder(
          time: '$hour:$minute',
          days: List<String>.from(_reminderDays),
        ),
      );
    }

    final Habit habit;
    if (existing != null) {
      // Editing: use copyWith() so we never silently drop fields such as
      // history, createdAt, id, or streakFreezesAvailable that the old
      // manual reconstruction was prone to forgetting.
      habit = existing.copyWith(
        title: title,
        description: _descriptionController.text.trim(),
        iconId: _iconId,
        color: _color,
        frequencyGoal: _frequencyGoal,
        frequencyPeriod: _frequencyPeriod,
        reminders: reminders,
        category: _category,
        archived: _archived,
      );
      Log.d('Edited habit ${existing.id}: "$title" '
          '(category=$_category, archived=$_archived)');
    } else {
      // Creating new: pass the new category + archived fields through to
      // the Habit constructor.
      habit = Habit(
        id: now.millisecondsSinceEpoch.toString(),
        title: title,
        description: _descriptionController.text.trim(),
        iconId: _iconId,
        color: _color,
        frequencyGoal: _frequencyGoal,
        frequencyPeriod: _frequencyPeriod,
        history: <String, HabitHistoryEntry>{},
        createdAt: now,
        reminders: reminders,
        category: _category,
        archived: _archived,
      );
      Log.d('Created new habit "$title" (category=$_category)');
    }

    Navigator.of(context).pop(HabitFormResult(habit: habit));
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;

    return Scaffold(
      backgroundColor: RouticaTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: RouticaTheme.appBar,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(isEditing ? 'Edit Habit' : 'New Habit'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _titleController.text.trim().isEmpty ? null : _save,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNameAndDescription(),
            const SizedBox(height: 16),
            _buildIconPicker(),
            const SizedBox(height: 16),
            // F5: Category picker, between icon and color pickers.
            _buildCategoryPicker(),
            const SizedBox(height: 16),
            _buildColorPicker(),
            const SizedBox(height: 16),
            _buildFrequency(),
            const SizedBox(height: 16),
            _buildReminder(),
            // F6: Archive toggle, only when editing an existing habit.
            if (isEditing) ...[
              const SizedBox(height: 16),
              _buildArchiveToggle(),
            ],
            const SizedBox(height: 20),
            _buildPreviewCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildNameAndDescription() {
    final titleEmpty = _titleController.text.trim().isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Habit Name',
              style: TextStyle(color: RouticaTheme.onSurfaceVariant, fontSize: 13),
            ),
            if (!titleEmpty)
              const Icon(Icons.check_circle, color: RouticaTheme.success, size: 16),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _titleController,
          decoration: InputDecoration(
            hintText: 'e.g. Morning Meditation',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: titleEmpty ? RouticaTheme.borderStrong : RouticaTheme.success,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: titleEmpty ? RouticaTheme.borderStrong : RouticaTheme.success,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: RouticaTheme.primary,
                width: 2,
              ),
            ),
          ),
          autofocus: true,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        const Text(
          'Description (optional)',
          style: TextStyle(color: RouticaTheme.onSurfaceVariant, fontSize: 13),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _descriptionController,
          decoration: InputDecoration(
            hintText: 'Add more details about your habit...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: RouticaTheme.borderStrong),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: RouticaTheme.borderStrong),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: RouticaTheme.primary,
                width: 2,
              ),
            ),
          ),
          minLines: 3,
          maxLines: 4,
        ),
      ],
    );
  }

  // NOTE: The duplicated local _iconGroups / _allIconIds / _iconForId()
  // switch were removed in favour of the single source of truth in
  // `HabitIcons` (../utils/habit_icons.dart). Callers now use
  // HabitIcons.iconForId(id) and HabitIcons.iconGroups directly.

  Widget _buildIconPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Icon',
          style: TextStyle(color: RouticaTheme.onSurfaceVariant, fontSize: 14),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: RouticaTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: RouticaTheme.border),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Display current selected icon
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Color(_color).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      HabitIcons.iconForId(_iconId),
                      color: Color(_color),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Selected Icon',
                          style: TextStyle(color: RouticaTheme.onSurfaceVariant, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _iconId,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Open icon picker button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showIconPickerDialog(),
                  icon: const Icon(Icons.apps),
                  label: const Text('Choose Icon'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(_color),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showIconPickerDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: RouticaTheme.scaffoldBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Icon',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: RouticaTheme.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Icon groups
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: HabitIcons.iconGroups.entries.map((entry) {
                      final groupName = entry.key;
                      final icons = entry.value;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Group title
                          Text(
                            groupName,
                            style: const TextStyle(
                              color: RouticaTheme.onSurfaceVariant,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Icons grid
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 6,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 1,
                            ),
                            itemCount: icons.length,
                            itemBuilder: (context, index) {
                              final id = icons[index];
                              final selected = _iconId == id;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _iconId = id;
                                  });
                                  Navigator.pop(context);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? Color(_color).withValues(alpha: 0.2)
                                        : Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: selected
                                        ? Border.all(
                                            color: Color(_color),
                                            width: 2,
                                          )
                                        : Border.all(
                                            color: RouticaTheme.border,
                                            width: 1,
                                          ),
                                  ),
                                  child: Icon(
                                    HabitIcons.iconForId(id),
                                    color: selected
                                        ? Color(_color)
                                        : RouticaTheme.onSurfaceVariant,
                                    size: 24,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // F5 — Category Picker: 8 selectable chips with emoji icons. The
  // selected chip is highlighted with the habit's accent color.
  Widget _buildCategoryPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category',
          style: TextStyle(color: RouticaTheme.onSurfaceVariant, fontSize: 14),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: RouticaTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: RouticaTheme.border),
          ),
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: HabitCategory.all.map((category) {
              final selected = _category == category;
              final emoji = HabitCategory.iconFor(category);
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _category = category;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? Color(_color).withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: selected
                        ? Border.all(color: Color(_color), width: 2)
                        : Border.all(color: RouticaTheme.border, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(
                        category,
                        style: TextStyle(
                          color: selected
                              ? Color(_color)
                              : RouticaTheme.onSurfaceVariant,
                          fontSize: 13,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                      if (selected) ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.check_circle_rounded,
                          color: Color(_color),
                          size: 16,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // 24 preset colors - organized by hue spectrum with better color selection
  static const _presetColors = [
    // Red & Pink Spectrum
    {'name': 'Red', 'value': 0xFFEF4444},
    {'name': 'Rose', 'value': 0xFFF43F5E},
    {'name': 'Pink', 'value': 0xFFEC4899},
    {'name': 'Fuchsia', 'value': 0xFFD946EF},

    // Orange & Amber Spectrum
    {'name': 'Orange', 'value': 0xFFF97316},
    {'name': 'Amber', 'value': 0xFFFB923C},
    {'name': 'Yellow', 'value': 0xFFEAB308},
    {'name': 'Lime', 'value': 0xFF84CC16},

    // Green Spectrum
    {'name': 'Green', 'value': 0xFF22C55E},
    {'name': 'Emerald', 'value': 0xFF059669},
    {'name': 'Teal', 'value': 0xFF14B8A6},
    {'name': 'Mint', 'value': 0xFF10B981},

    // Cyan & Blue Spectrum
    {'name': 'Cyan', 'value': 0xFF06B6D4},
    {'name': 'Sky', 'value': 0xFF0EA5E9},
    {'name': 'Blue', 'value': 0xFF3B82F6},
    {'name': 'Indigo', 'value': 0xFF2B2EEE},

    // Purple & Violet Spectrum
    {'name': 'Violet', 'value': 0xFFA855F7},
    {'name': 'Purple', 'value': 0xFF8B5CF6},
    {'name': 'Magenta', 'value': 0xFFD900F0},
    {'name': 'Grape', 'value': 0xFF9D4EDD},

    // Neutral Spectrum
    {'name': 'Gray', 'value': 0xFF6B7280},
    {'name': 'Slate', 'value': 0xFF64748B},
    {'name': 'Brown', 'value': 0xFFA16207},
    {'name': 'Charcoal', 'value': 0xFF374151},
  ];

  Widget _buildColorPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Accent Color',
          style: TextStyle(color: RouticaTheme.onSurfaceVariant, fontSize: 14),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: RouticaTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: RouticaTheme.border),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current selected color preview
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Color(_color),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Color',
                          style: TextStyle(color: RouticaTheme.onSurfaceVariant, fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '#${_color.toRadixString(16).substring(2).toUpperCase()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // Color grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1,
                ),
                itemCount: _presetColors.length,
                itemBuilder: (context, index) {
                  final colorData = _presetColors[index];
                  final colorValue = colorData['value'] as int;
                  final selected = _color == colorValue;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _color = colorValue;
                        // Bug 1 fix: only update .text of the existing
                        // controller — never recreate it.
                        _hexController.text =
                            '#${colorValue.toRadixString(16).substring(2).toUpperCase()}';
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: Color(colorValue),
                        borderRadius: BorderRadius.circular(12),
                        border: selected
                            ? Border.all(color: Colors.white, width: 3)
                            : Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 1,
                              ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: Color(colorValue).withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  spreadRadius: 0,
                                ),
                              ]
                            : null,
                      ),
                      child: selected
                          ? const Center(
                              child: Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 24,
                              ),
                            )
                          : null,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFrequency() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Frequency Goal',
          style: TextStyle(color: RouticaTheme.onSurfaceVariant, fontSize: 14),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: RouticaTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: RouticaTheme.border),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Goal count and period selector
              Row(
                children: [
                  // Number input
                  Expanded(
                    flex: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: TextField(
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                          hintText: '1',
                          hintStyle: TextStyle(color: RouticaTheme.onSurfaceVariant),
                        ),
                        controller: _frequencyGoalController,
                        onChanged: (value) {
                          if (value.isEmpty) {
                            setState(() {
                              _frequencyGoal = 1;
                            });
                          } else {
                            final parsed = int.tryParse(value);
                            if (parsed != null && parsed >= 1 && parsed <= 100) {
                              setState(() {
                                _frequencyGoal = parsed;
                              });
                            } else if (parsed != null) {
                              setState(() {
                                _frequencyGoal = parsed.clamp(1, 100);
                              });
                              _frequencyGoalController.text = _frequencyGoal.toString();
                            }
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // "per" label
                  const Text(
                    'per',
                    style: TextStyle(color: RouticaTheme.onSurfaceVariant, fontSize: 14),
                  ),
                  const SizedBox(width: 12),
                  // Period dropdown
                  Expanded(
                    flex: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: DropdownButton<HabitFrequencyPeriod>(
                        value: _frequencyPeriod,
                        isExpanded: true,
                        underline: const SizedBox(),
                        dropdownColor: RouticaTheme.surface,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        items: const [
                          DropdownMenuItem(
                            value: HabitFrequencyPeriod.day,
                            child: Text(
                              'Day',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          DropdownMenuItem(
                            value: HabitFrequencyPeriod.week,
                            child: Text(
                              'Week',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          DropdownMenuItem(
                            value: HabitFrequencyPeriod.month,
                            child: Text(
                              'Month',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _frequencyPeriod = value;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Summary text
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Color(_color).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Color(_color).withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Color(_color),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Complete $_frequencyGoal ${_frequencyGoal == 1 ? 'time' : 'times'} per ${_frequencyPeriod.name}',
                        style: TextStyle(
                          color: Color(_color),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // F3 helper: tip text shown only for daily habits.
              if (_frequencyPeriod == HabitFrequencyPeriod.day)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    '💡 Tip: Set goal > 1 for habits you do multiple times (e.g. 8 glasses of water/day)',
                    style: TextStyle(
                      color: RouticaTheme.onSurfaceVariant.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReminder() {
    const weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Reminders',
              style: TextStyle(color: RouticaTheme.onSurfaceVariant, fontSize: 13),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _remindersEnabled = !_remindersEnabled;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 50,
                height: 28,
                decoration: BoxDecoration(
                  color: _remindersEnabled
                      ? Color(_color).withValues(alpha: 0.6)
                      : RouticaTheme.borderStrong,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _remindersEnabled
                        ? Color(_color)
                        : RouticaTheme.borderStrong,
                    width: 1.5,
                  ),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 250),
                  alignment:
                      _remindersEnabled ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.all(3),
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AnimatedOpacity(
          opacity: _remindersEnabled ? 1.0 : 0.5,
          duration: const Duration(milliseconds: 250),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              color: RouticaTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _remindersEnabled
                    ? Color(_color).withValues(alpha: 0.3)
                    : RouticaTheme.borderStrong,
              ),
            ),
            child: IgnorePointer(
              ignoring: !_remindersEnabled,
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Color(_color).withValues(alpha: 0.08),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          final initial =
                              _reminderTime ?? const TimeOfDay(hour: 9, minute: 0);
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: initial,
                          );
                          if (picked != null) {
                            setState(() {
                              _reminderTime = picked;
                            });
                          }
                        },
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Reminder Time',
                                    style: TextStyle(
                                      color: RouticaTheme.onSurfaceVariant,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _reminderTime == null
                                        ? 'Not set'
                                        : _reminderTime!.format(context),
                                    style: TextStyle(
                                      color: _reminderTime == null
                                          ? RouticaTheme.onSurfaceVariant
                                          : Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              Icon(
                                Icons.access_time,
                                color: Color(_color),
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 1, color: RouticaTheme.borderStrong),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Color(_color).withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Repeat on',
                              style: TextStyle(
                                color: RouticaTheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: weekDays.map((day) {
                            final selected = _reminderDays.contains(day);
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (selected) {
                                    _reminderDays.remove(day);
                                  } else {
                                    _reminderDays.add(day);
                                  }
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: selected
                                      ? Color(_color)
                                      : RouticaTheme.scaffoldBackground,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: selected
                                        ? Colors.transparent
                                        : RouticaTheme.borderStrong,
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    day.substring(0, 1),
                                    style: TextStyle(
                                      color: selected
                                          ? Colors.white
                                          : RouticaTheme.onSurfaceVariant,
                                      fontSize: 12,
                                      fontWeight: selected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // F6 — Archive Toggle: shown only when editing an existing habit. Uses
  // the same animated switch style as the reminders toggle above.
  Widget _buildArchiveToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Archive',
                    style: TextStyle(color: RouticaTheme.onSurfaceVariant, fontSize: 13),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Hide from your main list while keeping the history.',
                    style: TextStyle(color: RouticaTheme.textDisabled, fontSize: 11),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _archived = !_archived;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 50,
                height: 28,
                decoration: BoxDecoration(
                  color: _archived
                      ? Color(_color).withValues(alpha: 0.6)
                      : RouticaTheme.borderStrong,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _archived
                        ? Color(_color)
                        : RouticaTheme.borderStrong,
                    width: 1.5,
                  ),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 250),
                  alignment:
                      _archived ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.all(3),
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
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

  Widget _buildPreviewCard() {
    final title = _titleController.text.trim().isEmpty
        ? 'Habit Name'
        : _titleController.text.trim();
    final description = _descriptionController.text.trim().isEmpty
        ? 'Description will appear here'
        : _descriptionController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Preview',
          style: TextStyle(color: RouticaTheme.onSurfaceVariant, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: RouticaTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: RouticaTheme.border),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Color(_color).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  HabitIcons.iconForId(_iconId),
                  color: Color(_color),
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: RouticaTheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Color(_color).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$_frequencyGoal/${_frequencyPeriod.name}',
                        style: TextStyle(
                          color: Color(_color),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
