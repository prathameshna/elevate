import 'package:flutter/material.dart';
import '../alarm/alarm_manager.dart';
import '../models/alarm.dart';
import '../services/alarm_storage.dart';

class AlarmProvider with ChangeNotifier {
  List<Alarm> _alarms = [];
  bool _isLoading = false;

  List<Alarm> get alarms => _alarms;
  bool get isLoading => _isLoading;

  AlarmProvider() {
    loadAlarms();
  }

  Future<void> loadAlarms() async {
    _isLoading = true;
    notifyListeners();

    _alarms = await AlarmStorage.loadList();
    _sortAlarms();
    
    _isLoading = false;
    notifyListeners();
  }

  void _sortAlarms() {
    _alarms.sort((a, b) {
      final aMin = a.time.hour * 60 + a.time.minute;
      final bMin = b.time.hour * 60 + b.time.minute;
      return aMin.compareTo(bMin);
    });
  }

  Future<void> addAlarm(Alarm alarm) async {
    await AlarmStorage.save(alarm);
    if (alarm.isEnabled) {
      await AlarmManager.schedule(alarm);
    }
    await loadAlarms();
  }

  Future<void> updateAlarm(Alarm alarm) async {
    await AlarmStorage.save(alarm);
    if (alarm.isEnabled) {
      await AlarmManager.schedule(alarm);
    } else {
      await AlarmManager.cancel(alarm);
    }
    await loadAlarms();
  }

  Future<void> deleteAlarm(String id) async {
    try {
      final alarm = _alarms.firstWhere((a) => a.id == id);
      await AlarmManager.cancel(alarm);
    } catch (_) {}

    await AlarmStorage.delete(id);
    await loadAlarms();
  }

  Future<void> toggleAlarm(String id) async {
    final index = _alarms.indexWhere((a) => a.id == id);
    if (index != -1) {
      final alarm = _alarms[index];
      final updated = alarm.copyWith(isEnabled: !alarm.isEnabled);
      
      await AlarmStorage.save(updated);
      
      if (updated.isEnabled) {
        await AlarmManager.schedule(updated);
      } else {
        await AlarmManager.cancel(updated);
      }
      
      await loadAlarms();
    }
  }

  Alarm createNewForTime(TimeOfDay time) {
    return Alarm(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      time: time,
      label: '',
      soundId: 'default_alarm',
      isEnabled: true,
      selectedDays: {}, 
    );
  }
}
