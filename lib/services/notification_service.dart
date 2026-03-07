import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/alarm.dart';
import '../models/sound_item.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    // Set local timezone
    final String timeZoneName = DateTime.now().timeZoneName;
    try {
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    // Request notification permission (Android 13+)
    await Permission.notification.request();

    // Request exact alarm permission (Android 12+)
    final exactAlarmStatus = await Permission.scheduleExactAlarm.status;
    if (exactAlarmStatus.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }

    _initialized = true;
  }

  Future<void> scheduleAlarm(Alarm alarm) async {
    if (!alarm.isEnabled) return;

    final nextTime = _nextOccurrence(alarm);
    if (nextTime == null) return;

    final vibrationPattern = Int64List.fromList([0, 500, 200, 500, 200, 500]);

    String androidSoundName = 'alarm_ringtone';
    if (alarm.soundId != null && alarm.soundId!.isNotEmpty && alarm.soundId != 'default_alarm') {
      for (final sounds in soundLibrary.values) {
        for (final s in sounds) {
          if (s.id == alarm.soundId) {
            androidSoundName = s.file.replaceAll('.mp3', '');
            break;
          }
        }
      }
    }

    final androidDetails = AndroidNotificationDetails(
      'elevate_alarm_channel',
      'Elevate Alarms',
      channelDescription: 'Alarm notifications for Elevate app',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(androidSoundName),
      enableVibration: true,
      vibrationPattern: vibrationPattern,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      ticker: 'Elevate Alarm',
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: '$androidSoundName.mp3',
      interruptionLevel: InterruptionLevel.critical,
    );

    final tzScheduled = tz.TZDateTime.from(nextTime, tz.local);

    // Repeating alarm (has selected days)
    if (alarm.selectedDays.isNotEmpty) {
      await _plugin.zonedSchedule(
        alarm.id.hashCode,
        'Elevate ⏰',
        alarm.label.isEmpty ? 'Time to wake up!' : alarm.label,
        tzScheduled,
        NotificationDetails(android: androidDetails, iOS: iosDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    } else {
      // One-time alarm
      await _plugin.zonedSchedule(
        alarm.id.hashCode,
        'Elevate ⏰',
        alarm.label.isEmpty ? 'Time to wake up!' : alarm.label,
        tzScheduled,
        NotificationDetails(android: androidDetails, iOS: iosDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  Future<void> cancelAlarm(String alarmId) async {
    await _plugin.cancel(alarmId.hashCode);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  // Find the next DateTime this alarm should fire
  DateTime? _nextOccurrence(Alarm alarm) {
    final now = DateTime.now();
    final todayAlarm = DateTime(
      now.year, now.month, now.day,
      alarm.time.hour, alarm.time.minute,
    );

    // No repeat — fire once
    if (alarm.selectedDays.isEmpty) {
      if (todayAlarm.isAfter(now)) return todayAlarm;
      return todayAlarm.add(const Duration(days: 1));
    }

    // Has repeat days — find next matching day
    // DateTime.weekday: Mon=1 ... Sun=7
    // Our selectedDays: Sun=0, Mon=1 ... Sat=6
    for (int offset = 0; offset < 8; offset++) {
      final candidate = todayAlarm.add(Duration(days: offset));
      // Convert to our format: Sun=0 ... Sat=6
      final ourDay = candidate.weekday % 7;
      if (alarm.selectedDays.contains(ourDay)) {
        if (candidate.isAfter(now)) return candidate;
      }
    }
    return null;
  }
}
