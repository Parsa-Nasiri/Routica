import 'package:flutter/material.dart';

import '../models/habit.dart';
import '../theme/routica_theme.dart';

/// A bottom sheet (F2) that lets the user view and edit a note for a
/// specific day of a specific habit.
///
/// Usage:
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   builder: (_) => HabitNoteSheet(
///     habit: habit,
///     dateKey: '2024-01-15',
///     onSave: (note) => ...,
///   ),
/// );
/// ```
class HabitNoteSheet extends StatefulWidget {
  const HabitNoteSheet({
    super.key,
    required this.habit,
    required this.dateKey,
    required this.onSave,
  });

  final Habit habit;
  final String dateKey; // yyyy-MM-dd
  final void Function(String? note) onSave;

  @override
  State<HabitNoteSheet> createState() => _HabitNoteSheetState();
}

class _HabitNoteSheetState extends State<HabitNoteSheet> {
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    final existingNote = widget.habit.history[widget.dateKey]?.note;
    _noteController = TextEditingController(text: existingNote ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _save() {
    final note = _noteController.text.trim();
    widget.onSave(note.isEmpty ? null : note);
    Navigator.pop(context);
  }

  void _delete() {
    widget.onSave(null);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.habit.history[widget.dateKey];
    final hasExistingNote = entry?.note != null && entry!.note!.isNotEmpty;

    // Parse the date for display
    final dateLabel = _formatDate(widget.dateKey);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: RouticaTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Icon(Icons.note_add_outlined,
                    color: Color(widget.habit.color), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.habit.title,
                        style: const TextStyle(
                          color: RouticaTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        dateLabel,
                        style: const TextStyle(
                          color: RouticaTheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Text field
            TextField(
              controller: _noteController,
              autofocus: true,
              maxLines: 4,
              style: const TextStyle(color: RouticaTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Add a note for this day...',
                hintStyle:
                    const TextStyle(color: RouticaTheme.onSurfaceVariant),
                filled: true,
                fillColor: RouticaTheme.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Action buttons
            Row(
              children: [
                if (hasExistingNote)
                  TextButton(
                    onPressed: _delete,
                    style: TextButton.styleFrom(
                      foregroundColor: RouticaTheme.danger,
                    ),
                    child: const Text('Delete Note'),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(widget.habit.color),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateKey) {
    try {
      final parts = dateKey.split('-');
      if (parts.length != 3) return dateKey;
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);
      final date = DateTime(year, month, day);

      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (_) {
      return dateKey;
    }
  }
}
