import 'dart:math';

import 'package:flutter/material.dart';

import '../models/alarm.dart';
import '../services/alarm_scheduler.dart';
import '../services/alarm_storage.dart';

class AlarmProvider extends ChangeNotifier {
  AlarmProvider({
    AlarmStorage? storage,
    AlarmScheduler? scheduler,
  })  : _storage = storage ?? AlarmStorage(),
        _scheduler = scheduler ?? AlarmScheduler.instance;

  final AlarmStorage _storage;
  final AlarmScheduler _scheduler;

  final List<Alarm> _alarms = [];
  bool _initialized = false;
  bool _isLoading = false;

  List<Alarm> get alarms =>
      List.unmodifiable(_alarms..sort((a, b) => _compareTime(a, b)));

  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    if (_initialized) return;
    _isLoading = true;
    notifyListeners();
    final loaded = await _storage.loadAlarms();
    _alarms
      ..clear()
      ..addAll(loaded);
    _initialized = true;
    _isLoading = false;
    notifyListeners();
    await _scheduler.rescheduleAll(_alarms);
  }

  Future<void> addAlarm(Alarm alarm) async {
    _alarms.add(alarm);
    await _persist();
    await _scheduler.scheduleAlarm(alarm);
    notifyListeners();
  }

  Future<void> updateAlarm(Alarm alarm) async {
    final index = _alarms.indexWhere((a) => a.id == alarm.id);
    if (index == -1) return;
    final old = _alarms[index];
    _alarms[index] = alarm;
    await _persist();
    if (!old.isEnabled && alarm.isEnabled) {
      await _scheduler.scheduleAlarm(alarm);
    } else if (old.isEnabled && !alarm.isEnabled) {
      await _scheduler.cancelAlarm(alarm);
    } else if (alarm.isEnabled) {
      await _scheduler.scheduleAlarm(alarm);
    }
    notifyListeners();
  }

  Future<void> deleteAlarm(String id) async {
    final index = _alarms.indexWhere((a) => a.id == id);
    if (index == -1) return;
    final alarm = _alarms.removeAt(index);
    await _persist();
    await _scheduler.cancelAlarm(alarm);
    notifyListeners();
  }

  Future<void> toggleAlarm(String id, bool enabled) async {
    final index = _alarms.indexWhere((a) => a.id == id);
    if (index == -1) return;
    final updated = _alarms[index].copyWith(isEnabled: enabled);
    _alarms[index] = updated;
    await _persist();
    if (enabled) {
      await _scheduler.scheduleAlarm(updated);
    } else {
      await _scheduler.cancelAlarm(updated);
    }
    notifyListeners();
  }

  Alarm createNewForTime(TimeOfDay time) {
    return Alarm(
      id: _generateId(),
      time: time,
      label: '',
      repeatDays: const [],
      sound: 'Default',
      volume: 50,
      vibration: true,
      snoozeMinutes: 5,
      isEnabled: true,
      createdAt: DateTime.now(),
    );
  }

  Future<void> _persist() async {
    await _storage.saveAlarms(_alarms);
  }

  String _generateId() {
    final rand = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomPart = rand.nextInt(1 << 32);
    return '$timestamp-$randomPart';
  }

  static int _compareTime(Alarm a, Alarm b) {
    if (a.time.hour != b.time.hour) {
      return a.time.hour.compareTo(b.time.hour);
    }
    return a.time.minute.compareTo(b.time.minute);
  }
}

