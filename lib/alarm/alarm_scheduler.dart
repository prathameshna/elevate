import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/alarm.dart';
import '../screens/ringing_screen.dart';

class AlarmScheduler {
  static final AlarmScheduler instance = AlarmScheduler._();
  AlarmScheduler._();
  
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool  _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings     = DarwinInitializationSettings();

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS:     iosSettings,
      ),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Handle notification that launched app from terminated state
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp == true) {
      final payload = launchDetails?.notificationResponse?.payload;
      if (payload != null) _handleAlarmPayload(payload);
    }

    _initialized = true;
  }
  
  Future<void> init() async {
    await initialize();
  }

  static void _onNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      _handleAlarmPayload(response.payload!);
    }
  }

  static void _handleAlarmPayload(String payload) {
    // This triggers RingingScreen — handled via navigatorKey
    try {
      final alarmJson = jsonDecode(payload) as Map<String, dynamic>;
      final alarm     = Alarm.fromJson(alarmJson);
      AlarmNavigator.showRingingScreen(alarm);
    } catch (e) {
      debugPrint('Error handling payload: $e');
    }
  }

  // Schedule alarm for next occurrence
  Future<void> schedule(Alarm alarm) async {
    await initialize();
    if (!alarm.isEnabled) {
      await cancel(alarm);
      return;
    }
    
    final scheduledTime = _nextOccurrence(alarm);
    if (scheduledTime == null) return;

    await _plugin.zonedSchedule(
      alarm.id.hashCode,
      'Elevate',
      alarm.label.isNotEmpty == true ? alarm.label : 'Alarm',
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'elevate_alarm_v1',
          'Alarms',
          channelDescription:  'Elevate alarm notifications',
          importance:          Importance.max,
          priority:            Priority.max,
          fullScreenIntent:    true,
          category:            AndroidNotificationCategory.alarm,
          visibility:          NotificationVisibility.public,
          sound:               null, // sound handled by foreground service
          playSound:           false,
          enableVibration:     false, // vibration handled by foreground service
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: jsonEncode(alarm.toJson()),
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // Cancel a scheduled alarm
  Future<void> cancel(Alarm alarm) async {
    await _plugin.cancel(alarm.id.hashCode);
  }

  // Schedule snooze — 5 minutes from now
  static Future<void> scheduleSnooze(Alarm alarm) async {
    final now     = DateTime.now();
    final snooze  = now.add(const Duration(minutes: 5));
    final tzSnooze = tz.TZDateTime.from(snooze, tz.local);

    await _plugin.zonedSchedule(
      alarm.id.hashCode + 99999, // different ID for snooze
      'Elevate — Snoozed',
      alarm.label.isNotEmpty == true ? alarm.label : 'Alarm',
      tzSnooze,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'elevate_alarm_v1',
          'Alarms',
          importance:       Importance.max,
          priority:         Priority.max,
          fullScreenIntent: true,
          category:         AndroidNotificationCategory.alarm,
          playSound:        false,
          enableVibration:  false,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: jsonEncode(alarm.toJson()),
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelSnooze(Alarm alarm) async {
    await _plugin.cancel(alarm.id.hashCode + 99999);
  }

  // Calculate next alarm DateTime
  static tz.TZDateTime? _nextOccurrence(Alarm alarm) {
    final now  = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year, now.month, now.day,
      alarm.time.hour, alarm.time.minute, 0,
    );

    if (alarm.days.isEmpty) {
      // One-time alarm — if time passed today, schedule tomorrow
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
      return scheduled;
    }

    // Repeating alarm — find next matching day
    for (int i = 0; i < 8; i++) {
      final candidate = scheduled.add(Duration(days: i));
      final weekday   = candidate.weekday % 7; // 0=Sun, 1=Mon...6=Sat
      if (alarm.days.contains(weekday)) {
        if (candidate.isAfter(now)) return candidate;
      }
    }
    return null;
  }
}

// Global navigator key for showing RingingScreen from anywhere
class AlarmNavigator {
  static GlobalKey<NavigatorState>? navigatorKey;

  static void showRingingScreen(Alarm alarm) {
    final context = navigatorKey?.currentContext;
    if (context == null) return;
    
    // Don't show if RingingScreen is already on top
    final route = ModalRoute.of(context);
    if (route?.settings.name == '/ringing') return;

    Navigator.of(context).push(MaterialPageRoute(
      settings: const RouteSettings(name: '/ringing'),
      builder: (_) => RingingScreen(alarm: alarm),
    ));
  }
}
