import '../models/alarm.dart';
import 'alarm_storage.dart';
import '../alarm/alarm_scheduler.dart';

class AlarmService {
  AlarmService._();
  static final AlarmService instance = AlarmService._();

  List<Alarm> _alarms = [];
  List<Alarm> get alarms => List.unmodifiable(_alarms);

  bool _loaded = false;

  Future<void> init() async {
    if (_loaded) return;
    _alarms = await AlarmStorage.loadAll();
    _loaded = true;
  }

  // Force reload from disk
  Future<void> reload() async {
    _alarms = await AlarmStorage.loadAll();
  }

  Future<void> createAlarm(Alarm alarm) async {
    _alarms.add(alarm);
    await AlarmStorage.saveAll(_alarms);
    if (alarm.isEnabled) {
      await AlarmScheduler.instance.schedule(alarm);
    }
  }

  Future<void> updateAlarm(Alarm updated) async {
    final index = _alarms.indexWhere((a) => a.id == updated.id);
    if (index == -1) return;
    _alarms[index] = updated;
    await AlarmStorage.saveAll(_alarms);
    // Always cancel then reschedule
    await AlarmScheduler.instance.cancel(updated);
    if (updated.isEnabled) {
      await AlarmScheduler.instance.schedule(updated);
    }
  }

  Future<void> deleteAlarm(String id) async {
    final index = _alarms.indexWhere((a) => a.id == id);
    if (index == -1) return;
    final alarm = _alarms[index];
    await AlarmScheduler.instance.cancel(alarm);
    _alarms.removeAt(index);
    await AlarmStorage.saveAll(_alarms);
  }

  Future<void> toggleAlarm(String id, bool isEnabled) async {
    final index = _alarms.indexWhere((a) => a.id == id);
    if (index == -1) return;
    final updated = _alarms[index].copyWith(isEnabled: isEnabled);
    _alarms[index] = updated;
    await AlarmStorage.saveAll(_alarms);
    if (isEnabled) {
      await AlarmScheduler.instance.schedule(updated);
    } else {
      await AlarmScheduler.instance.cancel(updated);
    }
  }
}
