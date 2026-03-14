import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter/material.dart';
import 'alarm_task_handler.dart';

class AlarmService {
  static final AlarmService instance = AlarmService._();
  AlarmService._();

  // Call once in main() before runApp
  static void initialize() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId:          'elevate_alarm_channel',
        channelName:        'Alarm',
        channelImportance:  NotificationChannelImportance.MAX,
        priority:           NotificationPriority.MAX,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification:   false,
        playSound:          false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction:        ForegroundTaskEventAction.repeat(1000),
        autoRunOnBoot:      false,
        allowWakeLock:      true,
      ),
    );
  }
  
  // Instance wrapper for backward compatibility
  Future<void> init() async {
    initialize();
  }

  // Start ringing — called when alarm fires
  static Future<void> startRinging({
    required String soundFile,
    required String vibrationId,
    required String alarmId,
    required String label,
  }) async {
    debugPrint('▶️ startRinging: $soundFile / $vibrationId');

    // Store sound file so task handler can read it BEFORE starting
    await FlutterForegroundTask.saveData(key: 'soundFile',    value: soundFile);
    await FlutterForegroundTask.saveData(key: 'vibrationId',  value: vibrationId);
    await FlutterForegroundTask.saveData(key: 'alarmId',      value: alarmId);

    // Small delay to ensure data is saved before service reads it
    await Future.delayed(const Duration(milliseconds: 100));

    final isRunning = await FlutterForegroundTask.isRunningService;
    if (isRunning) {
      await FlutterForegroundTask.restartService();
    } else {
      await FlutterForegroundTask.startService(
        notificationTitle:   'Elevate Alarm',
        notificationText:    label.isNotEmpty ? label : 'Alarm ringing',
        callback:            startAlarmCallback,
      );
    }
  }

  // Stop ringing — called on dismiss or snooze
  static Future<void> stopRinging() async {
    debugPrint('🛑 stopRinging');
    FlutterForegroundTask.sendDataToTask('stop');
    await Future.delayed(const Duration(milliseconds: 300));
    await FlutterForegroundTask.stopService();
  }
  
  // Instance wrappers for backward compatibility
  Future<void> stopRingingInstance() async {
    await stopRinging();
  }

  Future<void> snooze(int minutes) async {
    await stopRinging();
  }
}

