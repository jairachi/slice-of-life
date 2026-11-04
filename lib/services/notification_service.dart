import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../models/task.dart';

/// Local reminders (Android/iOS only; silently does nothing on web/desktop).
///
/// Two kinds, both at the user's chosen reminder time:
///  * a daily check-in reminder
///  * one reminder on the target date of every unfinished one-time task
///
/// [sync] rebuilds every pending notification from scratch, so call it whenever tasks or the
/// reminder settings change.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static const _dailyId = 1;
  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'sol_reminders',
      'Reminders',
      channelDescription: 'Daily check-in and task target-date reminders',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  static bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Call once at startup (before runApp).
  static Future<void> init() async {
    if (!_supported) return;
    try {
      tzdata.initializeTimeZones();
      try {
        // use the phone's own time zone so reminders fire at local clock time
        final info = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(info.identifier));
      } catch (_) {
        // falls back to UTC; one-off reminders are still correct (absolute instants)
      }
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
              requestAlertPermission: false,
              requestBadgePermission: false,
              requestSoundPermission: false),
        ),
      );
      _ready = true;
    } catch (e) {
      debugPrint('Notifications unavailable: $e');
    }
  }

  /// Asks the OS for notification permission (Android 13+ / iOS). Returns true if granted.
  static Future<bool> requestPermission() async {
    if (!_ready) return false;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null)
        return (await android.requestNotificationsPermission()) ?? false;
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null)
        return (await ios.requestPermissions(
                alert: true, badge: true, sound: true)) ??
            false;
    } catch (_) {}
    return false;
  }

  static int _taskNotificationId(Task t) =>
      (int.tryParse(t.id) ?? t.id.hashCode).abs() % 1000000000 + 1000;

  /// Cancels everything and schedules the current reminders (nothing if [enabled] is false).
  static Future<void> sync(
      {required bool enabled,
      required TimeOfDay time,
      required List<Task> tasks}) async {
    if (!_ready) return;
    try {
      await _plugin.cancelAll();
      if (!enabled) return;

      // daily check-in: repeats every day at [time]
      final now = tz.TZDateTime.now(tz.local);
      var first = tz.TZDateTime(
          tz.local, now.year, now.month, now.day, time.hour, time.minute);
      if (first.isBefore(now)) first = first.add(const Duration(days: 1));
      await _plugin.zonedSchedule(
        id: _dailyId,
        title: 'Slice of Life',
        body: 'Ready to level up? Check your quests for today.',
        scheduledDate: first,
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode
            .inexactAllowWhileIdle, // no exact-alarm permission needed
        matchDateTimeComponents: DateTimeComponents.time,
      );

      // one reminder on the target date of each unfinished one-time task
      for (final t in tasks) {
        if (t.recurring || t.done || t.dueDate == null) continue;
        final d = DateTime.parse(t.dueDate!);
        final at = DateTime(d.year, d.month, d.day, time.hour, time.minute);
        if (!at.isAfter(DateTime.now())) continue; // already passed
        await _plugin.zonedSchedule(
          id: _taskNotificationId(t),
          title: t.name,
          body: 'Target date today! Finish this quest for +${t.xp} XP.',
          scheduledDate: tz.TZDateTime.from(at, tz.local),
          notificationDetails: _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    } catch (e) {
      debugPrint('Could not schedule reminders: $e');
    }
  }
}
