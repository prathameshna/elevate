import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alarm.dart';
import '../services/alarm_scheduler.dart';

class AlarmProvider extends ChangeNotifier {
  final List<Alarm> _alarms = [];
  bool _isLoading = true;

  List<Alarm> get alarms => List.unmodifiable(_alarms);
  bool get isLoading => _isLoading;

  AlarmProvider() {
    _loadAlarms();
  }

  Future<void> _loadAlarms() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final alarmData = prefs.getStringList('alarms') ?? [];
      
      _alarms.clear();
      for (final item in alarmData) {
        try {
          _alarms.add(Alarm.fromJson(jsonDecode(item)));
        } catch (e) {
          debugPrint('Error decoding alarm: $e');
        }
      }
      _sortAlarms();
    } catch (e) {
      debugPrint('Error loading alarms: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveAlarms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alarmData = _alarms.map((a) => jsonEncode(a.toJson())).toList();
      await prefs.setStringList('alarms', alarmData);
    } catch (e) {
      debugPrint('Error saving alarms: $e');
    }
  }

  void _sortAlarms() {
    _alarms.sort((a, b) {
      final aMinutes = a.time.hour * 60 + a.time.minute;
      final bMinutes = b.time.hour * 60 + b.time.minute;
      return aMinutes.compareTo(bMinutes);
    });
  }

  Future<void> addAlarm(Alarm alarm) async {
    _alarms.add(alarm);
    _sortAlarms();
    await _saveAlarms();
    await AlarmScheduler.instance.scheduleAlarm(alarm);
    notifyListeners();
  }

  Future<void> updateAlarm(Alarm alarm) async {
    final index = _alarms.indexWhere((a) => a.id == alarm.id);
    if (index != -1) {
      _alarms[index] = alarm;
      _sortAlarms();
      await _saveAlarms();
      await AlarmScheduler.instance.scheduleAlarm(alarm);
      notifyListeners();
    }
  }

  Future<void> deleteAlarm(String id) async {
    final index = _alarms.indexWhere((a) => a.id == id);
    if (index != -1) {
      final alarm = _alarms[index];
      _alarms.removeAt(index);
      await _saveAlarms();
      await AlarmScheduler.instance.cancelAlarm(alarm.id);
      notifyListeners();
    }
  }

  Future<void> toggleAlarm(String id) async {
    final index = _alarms.indexWhere((a) => a.id == id);
    if (index != -1) {
      final alarm = _alarms[index];
      final updated = alarm.copyWith(enabled: !alarm.enabled);
      _alarms[index] = updated;
      await _saveAlarms();
      
      if (updated.enabled) {
        await AlarmScheduler.instance.scheduleAlarm(updated);
      } else {
        await AlarmScheduler.instance.cancelAlarm(updated.id);
      }
      
      notifyListeners();
    }
  }

  Alarm createNewForTime(TimeOfDay time) {
    final now = DateTime.now();
    final alarmTime = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    return Alarm(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      time: alarmTime,
      label: '',
      sound: 'default_alarm',
      enabled: true,
      repeatDays: [], // Practical spec uses List<int>
    );
  }
}
