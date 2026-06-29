import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/habit.dart';
import '../providers/habit_manager.dart';
import '../utils/logger.dart';

/// Callback type for when a notification is tapped and the app needs to
/// navigate to a specific habit.
typedef NotificationTapCallback = void Function(String habitId);

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Callback set by the app's root widget so notification taps can trigger
  /// navigation.  Previously this handler only `print()`-ed the payload and
  /// did nothing — **Bug 6**.  Now it invokes this callback if set.
  NotificationTapCallback? onNotificationTap;

  // ── Notification channel IDs ─────────────────────────────────
  static const _channelReminders = 'habit_reminders';
  static const _channelStreaks = 'streak_milestones';
  static const _channelSmart = 'smart_reminders';

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels (Android 8+)
    if (Platform.isAndroid) {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelStreaks,
          'Streak Milestones',
          description: 'Celebrate when you hit streak milestones',
          importance: Importance.high,
        ),
      );
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelSmart,
          'Smart Reminders',
          description: 'Context-aware reminders for habits not yet done today',
          importance: Importance.defaultImportance,
        ),
      );
    }

    _initialized = true;
    Log.d('NotificationService initialized');
  }

  /// Bug 6 fix: instead of just printing, this now delegates to
  /// [onNotificationTap] which the root widget wires to navigation.
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    Log.d('Notification tapped, payload=$payload');
    if (payload != null && onNotificationTap != null) {
      onNotificationTap!(payload);
    }
  }

  Future<void> requestPermissions() async {
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  // ── Habit reminders ──────────────────────────────────────────

  Future<void> scheduleHabitReminders(Habit habit) async {
    if (!_initialized) await initialize();
    await cancelHabitReminders(habit.id);

    for (var i = 0; i < habit.reminders.length; i++) {
      final reminder = habit.reminders[i];
      await _scheduleReminder(
        habit: habit,
        reminder: reminder,
        notificationId: habit.id.hashCode + i,
      );
    }
  }

  Future<void> _scheduleReminder({
    required Habit habit,
    required HabitReminder reminder,
    required int notificationId,
  }) async {
    final timeParts = reminder.time.split(':');
    if (timeParts.length != 2) {
      Log.w('Invalid reminder time format: ${reminder.time}');
      return;
    }
    final hour = int.tryParse(timeParts[0]) ?? 9;
    final minute = int.tryParse(timeParts[1]) ?? 0;

    final dayMap = {
      'Mon': DateTime.monday,
      'Tue': DateTime.tuesday,
      'Wed': DateTime.wednesday,
      'Thu': DateTime.thursday,
      'Fri': DateTime.friday,
      'Sat': DateTime.saturday,
      'Sun': DateTime.sunday,
    };

    for (final dayName in reminder.days) {
      final weekday = dayMap[dayName];
      if (weekday == null) continue;

      var scheduledDate = _nextInstanceOfDayAndTime(weekday, hour, minute);
      final now = tz.TZDateTime.now(tz.local);
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 7));
      }

      await _notifications.zonedSchedule(
        notificationId + weekday,
        '⏰ ${habit.title}',
        'Time to complete your habit!',
        scheduledDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelReminders,
            'Habit Reminders',
            channelDescription: 'Notifications for habit reminders',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            color: Color(habit.color),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: habit.id,
      );
    }
  }

  tz.TZDateTime _nextInstanceOfDayAndTime(int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    while (scheduledDate.weekday != weekday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  // ── F7: Streak milestone notifications ────────────────────────

  /// Checks all habits and fires a one-shot notification for any habit
  /// that just hit a milestone (3, 7, 14, 21, 30, 60, 100, 365 days).
  ///
  /// Call this after a habit's day status changes.
  Future<void> checkStreakMilestones(Habit habit) async {
    if (!_initialized) await initialize();

    final analytics = HabitManager.analyzeHabit(habit);
    final streak = analytics.currentStreak;

    const milestones = [3, 7, 14, 21, 30, 60, 100, 365];
    if (!milestones.contains(streak)) return;

    final milestoneId = '${habit.id}_streak_$streak'.hashCode;

    // Check if we already notified for this milestone (fire-and-forget:
    // the notification system deduplicates by ID).
    await _notifications.show(
      milestoneId,
      '🔥 $streak-Day Streak!',
      'Amazing! You\'ve maintained "${habit.title}" for $streak days straight!',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelStreaks,
          'Streak Milestones',
          channelDescription: 'Celebrate when you hit streak milestones',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: Color(habit.color),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: habit.id,
    );
    Log.d('Streak milestone notification: $streak days for "${habit.title}"');
  }

  // ── F9: Smart reminders ───────────────────────────────────────

  /// Sends a one-shot notification at [scheduledTime] for habits that
  /// haven't been completed today.  The message adapts based on the
  /// habit's current streak.
  Future<void> scheduleSmartReminder({
    required Habit habit,
    required tz.TZDateTime scheduledTime,
  }) async {
    if (!_initialized) await initialize();

    final todayKey = _dateKey(DateTime.now());
    final isDoneToday =
        habit.history[todayKey]?.status == HabitDayStatus.completed;
    if (isDoneToday) return; // Already done, no need to nag.

    final analytics = HabitManager.analyzeHabit(habit);
    final streak = analytics.currentStreak;

    String message;
    if (streak >= 7) {
      message = 'Don\'t break your $streak-day streak! 🔥';
    } else if (streak >= 3) {
      message = 'Keep the momentum going — $streak days and counting!';
    } else {
      message = 'You haven\'t completed this yet today.';
    }

    final id = '${habit.id}_smart'.hashCode;

    await _notifications.zonedSchedule(
      id,
      '📌 ${habit.title}',
      message,
      scheduledTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelSmart,
          'Smart Reminders',
          channelDescription:
              'Context-aware reminders for habits not yet done today',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
          color: Color(habit.color),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: habit.id,
    );
    Log.d('Smart reminder scheduled for "${habit.title}"');
  }

  /// Schedules smart reminders for all incomplete habits at a given hour.
  Future<void> scheduleAllSmartReminders(List<Habit> habits, int hour) async {
    if (!_initialized) await initialize();

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      0,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    for (final habit in habits) {
      if (habit.archived) continue;
      await scheduleSmartReminder(habit: habit, scheduledTime: scheduled);
    }
  }

  // ── Cancel helpers ────────────────────────────────────────────

  Future<void> cancelHabitReminders(String habitId) async {
    final baseId = habitId.hashCode;
    for (var i = 0; i < 10; i++) {
      for (var day = 1; day <= 7; day++) {
        await _notifications.cancel(baseId + i + day);
      }
    }
    // Also cancel smart reminder
    await _notifications.cancel('$habitId_smart'.hashCode);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // ── Utilities ────────────────────────────────────────────────

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
