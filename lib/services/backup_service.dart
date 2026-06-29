import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/habit.dart';
import '../providers/habit_manager.dart';
import '../utils/logger.dart';

/// Handles backup (JSON + CSV export) and restore (JSON import).
class BackupService {
  /// Export habits as JSON string (full backup, includes history).
  static Future<String?> exportHabitsToJson(List<Habit> habits) async {
    try {
      final habitsList = habits.map((habit) {
        return {
          'id': habit.id,
          'title': habit.title,
          'description': habit.description,
          'iconId': habit.iconId,
          'color': habit.color,
          'frequencyGoal': habit.frequencyGoal,
          'frequencyPeriod': habit.frequencyPeriod.toString().split('.').last,
          'createdAt': habit.createdAt.toIso8601String(),
          'category': habit.category,
          'archived': habit.archived,
          'streakFreezesAvailable': habit.streakFreezesAvailable,
          'reminders': habit.reminders
              .map((r) => {'time': r.time, 'days': r.days})
              .toList(),
          'history': habit.history.map((key, entry) {
            return MapEntry(key, {
              'status': entry.status.toString().split('.').last,
              'note': entry.note,
              'count': entry.count,
            });
          }),
        };
      }).toList();

      final backup = {
        'version': '2.0',
        'exportedAt': DateTime.now().toIso8601String(),
        'totalHabits': habits.length,
        'habits': habitsList,
      };

      return jsonEncode(backup);
    } catch (e) {
      Log.e('Export error: $e');
      return null;
    }
  }

  /// Save exported JSON to file in the app's Documents directory.
  static Future<File?> saveExportToFile(String jsonString) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${appDir.path}/routica_backup_$timestamp.json');
      await file.writeAsString(jsonString);
      Log.d('Backup saved to ${file.path}');
      return file;
    } catch (e) {
      Log.e('Save error: $e');
      return null;
    }
  }

  // ── F16: CSV Export ──────────────────────────────────────────

  /// Export habits as CSV string (human-readable summary, no history detail).
  ///
  /// Columns: Title, Description, Category, Icon, Color, Frequency Goal,
  /// Frequency Period, Created At, Total Completed, Current Streak,
  /// Longest Streak, Archived.
  static Future<String?> exportHabitsToCsv(List<Habit> habits) async {
    try {
      final buffer = StringBuffer();

      // Header row
      buffer.writeln(
        'Title,Description,Category,Icon,Color,Frequency Goal,'
        'Frequency Period,Created At,Total Completed,Current Streak,'
        'Longest Streak,Archived',
      );

      for (final habit in habits) {
        final analytics = HabitManager.analyzeHabit(habit);
        buffer.writeln([
          _csvEscape(habit.title),
          _csvEscape(habit.description),
          _csvEscape(habit.category),
          habit.iconId,
          '#${habit.color.toRadixString(16).padLeft(8, '0').toUpperCase()}',
          habit.frequencyGoal,
          habit.frequencyPeriod.name,
          habit.createdAt.toIso8601String(),
          analytics.completed,
          analytics.currentStreak,
          analytics.longestStreak,
          habit.archived ? 'Yes' : 'No',
        ].join(','));
      }

      return buffer.toString();
    } catch (e) {
      Log.e('CSV export error: $e');
      return null;
    }
  }

  /// Save CSV string to a file in Documents directory.
  static Future<File?> saveCsvToFile(String csvString) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${appDir.path}/routica_export_$timestamp.csv');
      await file.writeAsString(csvString);
      Log.d('CSV saved to ${file.path}');
      return file;
    } catch (e) {
      Log.e('CSV save error: $e');
      return null;
    }
  }

  /// Escapes a field for CSV: wraps in quotes if it contains comma,
  /// quote, or newline; doubles internal quotes.
  static String _csvEscape(String value) {
    if (value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  // ── Import ────────────────────────────────────────────────────

  /// Import habits from a JSON string (previously exported backup).
  static Future<List<Habit>?> importHabits(String jsonString) async {
    try {
      final json = jsonDecode(jsonString);

      if (json is! Map || json['habits'] is! List) {
        throw Exception('Invalid backup format');
      }

      final habitsList = (json['habits'] as List).map((habitJson) {
        final frequencyStr = habitJson['frequencyPeriod'] as String;
        final frequencyPeriod = HabitFrequencyPeriod.values.firstWhere(
          (e) => e.toString().split('.').last == frequencyStr,
          orElse: () => HabitFrequencyPeriod.day,
        );

        final history = <String, HabitHistoryEntry>{};
        (habitJson['history'] as Map).forEach((key, value) {
          final statusStr = value['status'] as String;
          final status = HabitDayStatus.values.firstWhere(
            (e) => e.toString().split('.').last == statusStr,
            orElse: () => HabitDayStatus.none,
          );
          history[key] = HabitHistoryEntry(
            status: status,
            note: value['note'],
            count: value['count'] ?? 1,
          );
        });

        final reminders = (habitJson['reminders'] as List?)
                ?.map((r) => HabitReminder(
                      time: r['time'] as String,
                      days: List<String>.from(r['days'] as List),
                    ))
                .toList() ??
            [];

        return Habit(
          id: habitJson['id'] as String,
          title: habitJson['title'] as String,
          description: habitJson['description'] as String? ?? '',
          iconId: habitJson['iconId'] as String? ?? 'brain',
          color: habitJson['color'] as int? ?? 0xFF8B5CF6,
          frequencyGoal: habitJson['frequencyGoal'] as int? ?? 1,
          frequencyPeriod: frequencyPeriod,
          reminders: reminders,
          history: history,
          createdAt: DateTime.parse(habitJson['createdAt'] as String? ??
              DateTime.now().toIso8601String()),
          category: habitJson['category'] as String? ?? HabitCategory.general,
          archived: habitJson['archived'] as bool? ?? false,
          streakFreezesAvailable:
              habitJson['streakFreezesAvailable'] as int? ?? 1,
        );
      }).toList();

      Log.d('Imported ${habitsList.length} habits from backup');
      return habitsList;
    } catch (e) {
      Log.e('Import error: $e');
      return null;
    }
  }

  /// Read a backup file from the given path and return its contents.
  static Future<String?> readFile(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return null;
      return await file.readAsString();
    } catch (e) {
      Log.e('Read file error: $e');
      return null;
    }
  }

  /// Get backup info summary from a JSON string (for preview before import).
  static Map<String, dynamic> getBackupInfo(String jsonString) {
    try {
      final json = jsonDecode(jsonString);
      return {
        'version': json['version'],
        'exportedAt': json['exportedAt'],
        'totalHabits': json['totalHabits'],
        'valid': true,
      };
    } catch (e) {
      return {'valid': false, 'error': e.toString()};
    }
  }
}
