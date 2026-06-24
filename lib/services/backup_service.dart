import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/habit.dart';

class BackupService {
  /// Export habits as JSON string
  static Future<String?> exportHabitsToJson(List<Habit> habits) async {
    try {
      // Convert habits to JSON
      final habitsList = habits.map((habit) => {
        'id': habit.id,
        'title': habit.title,
        'description': habit.description,
        'iconId': habit.iconId,
        'color': habit.color,
        'frequencyGoal': habit.frequencyGoal,
        'frequencyPeriod': habit.frequencyPeriod.toString().split('.').last,
        'createdAt': habit.createdAt.toIso8601String(),
        'reminders': habit.reminders.map((r) => {
          'time': r.time,
          'days': r.days,
        }).toList(),
        'history': habit.history.map((key, entry) => MapEntry(key, {
          'status': entry.status.toString().split('.').last,
          'note': entry.note,
          'count': entry.count,
        })),
      }).toList();

      // Create backup JSON
      final backup = {
        'version': '1.0',
        'exportedAt': DateTime.now().toIso8601String(),
        'totalHabits': habits.length,
        'habits': habitsList,
      };

      return jsonEncode(backup);
    } catch (e) {
      print('Export error: $e');
      return null;
    }
  }

  /// Save exported JSON to file
  static Future<File?> saveExportToFile(String jsonString) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${appDir.path}/routica_backup_$timestamp.json');
      await file.writeAsString(jsonString);
      return file;
    } catch (e) {
      print('Save error: $e');
      return null;
    }
  }

  /// Import habits from JSON string
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
            .toList() ?? [];

        return Habit(
          id: habitJson['id'] as String,
          title: habitJson['title'] as String,
          description: habitJson['description'] as String? ?? '',
          iconId: habitJson['iconId'] as String,
          color: habitJson['color'] as int,
          frequencyGoal: habitJson['frequencyGoal'] as int? ?? 1,
          frequencyPeriod: frequencyPeriod,
          reminders: reminders,
          history: history,
          createdAt: DateTime.parse(habitJson['createdAt'] as String? ?? DateTime.now().toIso8601String()),
        );
      }).toList();

      return habitsList;
    } catch (e) {
      print('Import error: $e');
      return null;
    }
  }

  /// Get backup info summary
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
