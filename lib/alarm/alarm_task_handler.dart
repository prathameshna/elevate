import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:just_audio/just_audio.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter/material.dart';

// Top-level entry point — required
@pragma('vm:entry-point')
void startAlarmCallback() {
  FlutterForegroundTask.setTaskHandler(AlarmTaskHandler());
}

class AlarmTaskHandler extends TaskHandler {
  AudioPlayer? _player;
  bool _isStopped = false;

  // Called when foreground service starts
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    debugPrint('🔔 AlarmTaskHandler.onStart');
    
    // Get stored values
    final soundFile   = await FlutterForegroundTask.getData<String>(key: 'soundFile')   ?? 'bright_bell.mp3';
    final vibrationId = await FlutterForegroundTask.getData<String>(key: 'vibrationId') ?? 'heartbeat';

    debugPrint('Sound: $soundFile | Vib: $vibrationId');

    // Audio — must use setAudioSource with full path
    _player = AudioPlayer();
    try {
      await _player!.setAudioSource(
        AudioSource.asset('assets/sounds/$soundFile'),
      );
      await _player!.setLoopMode(LoopMode.one);
      await _player!.play();
      debugPrint('✅ Sound playing: $soundFile');
    } catch (_) {
      debugPrint('❌ Sound error on main file, trying fallback');
      // Fallback to first available sound
      try {
        await _player!.setAudioSource(
          AudioSource.asset('assets/sounds/bright_bell.mp3'),
        );
        await _player!.setLoopMode(LoopMode.one);
        await _player!.play();
      } catch (e) {
        debugPrint('❌ Fallback sound error: $e');
      }
    }

    // Vibration
    final pattern = _vibrationPattern(vibrationId);
    if (pattern != null) {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) Vibration.vibrate(pattern: pattern, repeat: 0);
      debugPrint('✅ Vibrating: $vibrationId');
    }
  }

  List<int>? _vibrationPattern(String id) {
    switch (id) {
      case 'heartbeat': return [0, 200, 100, 200, 800];
      case 'pulse':     return [0, 500, 500];
      case 'rapid':     return [0, 100, 100];
      case 'gentle':    return [0, 300, 700];
      case 'sos':       return [0,100,100,100,100,100,300,100,300,100,300,100,100];
      case 'long':      return [0, 1000, 500];
      case 'none':      return null;
      default:          return [0, 500, 500];
    }
  }

  // Called periodically — use to keep vibration alive
  @override
  void onRepeatEvent(DateTime timestamp) {
    if (_isStopped) FlutterForegroundTask.stopService();
  }

  // Called when service stops (Dismiss tapped)
  @override
  Future<void> onDestroy(DateTime timestamp) async {
    debugPrint('🛑 AlarmTaskHandler.onDestroy — stopping');
    _isStopped = true;
    try { await _player?.stop(); } catch (_) {}
    try { await _player?.dispose(); } catch (_) {}
    _player = null;
    try { Vibration.cancel(); } catch (_) {}
  }

  // Called when user sends message from UI (Dismiss / Snooze)
  @override
  void onReceiveData(Object data) {
    debugPrint('📨 Task received: $data');
    if (data == 'stop' || data == 'snooze' || data == 'dismiss') {
      FlutterForegroundTask.stopService();
    }
  }

  // Called when notification button is pressed
  @override
  void onNotificationButtonPressed(String id) {
    debugPrint('📨 Notification button pressed: $id');
    if (id == 'dismiss' || id == 'snooze') {
      FlutterForegroundTask.stopService();
    }
  }
}

