import 'package:alarm/alarm.dart' as alarm_pkg;
import 'package:permission_handler/permission_handler.dart';
import '../models/alarm.dart' as app_alarm;

class AlarmManager {

  static Future<void> initialize() async {
    await alarm_pkg.Alarm.init(showDebugLogs: true);
  }

  static Future<bool> checkPermission() async {
    final status = await Permission.scheduleExactAlarm.status;
    return status.isGranted;
  }

  static Future<void> requestPermission() async {
    await Permission.scheduleExactAlarm.request();
    await Permission.notification.request();
  }

  static Future<void> schedule(app_alarm.Alarm alarm) async {
    final now           = DateTime.now();
    final scheduledTime = _nextOccurrence(alarm);
    if (scheduledTime == null) return;
    if (scheduledTime.isBefore(now)) return;

    final soundPath = alarm.soundEnabled == true &&
            alarm.soundFile != null &&
            alarm.soundFile!.isNotEmpty
        ? 'assets/sounds/${alarm.soundFile}'
        : 'assets/sounds/bright_bell.mp3';

    final settings = alarm_pkg.AlarmSettings(
      id:             _numericId(alarm.id),
      dateTime:       scheduledTime,
      assetAudioPath: soundPath,
      loopAudio:      true,
      vibrate:        alarm.vibrationEnabled,
      volume:         1.0,
      fadeDuration:   0,
      warningNotificationOnKill: true,
      androidFullScreenIntent:   true,
      notificationSettings: alarm_pkg.NotificationSettings(
        title: alarm.label.isNotEmpty
            ? alarm.label
            : 'Elevate Alarm',
        body: alarm.memo != null && alarm.memo!.isNotEmpty
            ? alarm.memo!
            : 'Time to wake up!',
        stopButton: 'Dismiss',
        icon: 'notification_icon',
      ),
    );

    await alarm_pkg.Alarm.set(alarmSettings: settings);
  }

  static Future<void> cancel(app_alarm.Alarm alarm) async {
    await alarm_pkg.Alarm.stop(_numericId(alarm.id));
  }

  static Future<void> stopRinging(app_alarm.Alarm alarm) async {
    await alarm_pkg.Alarm.stop(_numericId(alarm.id));
  }

  static Future<void> snooze(app_alarm.Alarm alarm) async {
    await stopRinging(alarm);

    final snoozeTime = DateTime.now()
        .add(Duration(minutes: alarm.snoozeMinutes));

    final soundPath = alarm.soundEnabled == true &&
            alarm.soundFile != null &&
            alarm.soundFile!.isNotEmpty
        ? 'assets/sounds/${alarm.soundFile}'
        : 'assets/sounds/bright_bell.mp3';

    final snoozeSettings = alarm_pkg.AlarmSettings(
      id:             _numericId(alarm.id),
      dateTime:       snoozeTime,
      assetAudioPath: soundPath,
      loopAudio:      true,
      vibrate:        alarm.vibrationEnabled,
      volume:         1.0,
      androidFullScreenIntent: true,
      notificationSettings: alarm_pkg.NotificationSettings(
        title: 'Snoozed — ${alarm.label.isNotEmpty ? alarm.label : "Alarm"}',
        body:  'Ringing again in ${alarm.snoozeMinutes} minutes',
        icon:  'notification_icon',
      ),
    );

    await alarm_pkg.Alarm.set(alarmSettings: snoozeSettings);
  }

  // Convert string UUID to valid int ID
  static int _numericId(String id) =>
      id.hashCode.abs() % 2147483647;

  // Find next occurrence DateTime for alarm
  static DateTime? _nextOccurrence(app_alarm.Alarm alarm) {
    final now = DateTime.now();
    var candidate = DateTime(
      now.year, now.month, now.day,
      alarm.time.hour, alarm.time.minute, 0,
    );

    if (alarm.days.isEmpty) {
      if (candidate.isBefore(now) || candidate.isAtSameMomentAs(now)) {
        candidate = candidate.add(const Duration(days: 1));
      }
      return candidate;
    }

    for (int i = 0; i < 8; i++) {
      final check   = candidate.add(Duration(days: i));
      final weekday = check.weekday % 7; // 0=Sun, 1=Mon ... 6=Sat
      if (alarm.days.contains(weekday) && check.isAfter(now)) {
        return check;
      }
    }
    return null;
  }
}
