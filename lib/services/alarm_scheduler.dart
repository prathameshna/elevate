import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/alarm.dart';

class AlarmScheduler {
  AlarmScheduler._internal();

  static final AlarmScheduler instance = AlarmScheduler._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initSettings);
    _initialized = true;
  }

  Future<void> scheduleAlarm(Alarm alarm) async {
    if (!alarm.isEnabled) return;
    await initialize();

    final id = alarm.id.hashCode & 0x7fffffff;
    final now = DateTime.now();

    DateTime nextTime = DateTime(
      now.year,
      now.month,
      now.day,
      alarm.time.hour,
      alarm.time.minute,
    );

    if (!alarm.isOneTime && alarm.selectedDays.isNotEmpty) {
      nextTime = _nextForRepeatDays(alarm, now);
    } else if (!nextTime.isAfter(now)) {
      nextTime = nextTime.add(const Duration(days: 1));
    }

    final tzTime = tz.TZDateTime.from(nextTime, tz.local);

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'elevate_alarms',
        'Alarms',
        channelDescription: 'Scheduled alarms for Elevate',
        importance: Importance.max,
        priority: Priority.high,
        sound: null,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    if (alarm.isOneTime) {
      await _plugin.zonedSchedule(
        id,
        'Alarm',
        'It\'s time',
        tzTime,
        details,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidAllowWhileIdle: true,
      );
    } else {
      await _plugin.zonedSchedule(
        id,
        'Alarm',
        'It\'s time',
        tzTime,
        details,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidAllowWhileIdle: true,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  Future<void> cancelAlarm(String alarmId) async {
    await initialize();
    final id = alarmId.hashCode & 0x7fffffff;
    await _plugin.cancel(id);
  }

  Future<void> rescheduleAll(List<Alarm> alarms) async {
    await initialize();
    await _plugin.cancelAll();
    for (final alarm in alarms.where((a) => a.isEnabled)) {
      await scheduleAlarm(alarm);
    }
  }

  DateTime _nextForRepeatDays(Alarm alarm, DateTime from) {
    final days = alarm.selectedDays;
    if (days.isEmpty) {
      return from.add(const Duration(days: 1));
    }

    
    int currentDayIndex = from.weekday;
    if (currentDayIndex == 7) currentDayIndex = 0; // Sun=0

    final todayMatches = days.contains(currentDayIndex);

    DateTime candidate = DateTime(
      from.year,
      from.month,
      from.day,
      alarm.time.hour,
      alarm.time.minute,
    );

    if (todayMatches && candidate.isAfter(from)) {
      return candidate;
    }

    for (var i = 1; i <= 7; i++) {
      final next = from.add(Duration(days: i));
      int nextDayIndex = next.weekday;
      if (nextDayIndex == 7) nextDayIndex = 0;
      
      if (days.contains(nextDayIndex)) {
        return DateTime(
          next.year,
          next.month,
          next.day,
          alarm.time.hour,
          alarm.time.minute,
        );
      }
    }

    return candidate.add(const Duration(days: 1));
  }
}
