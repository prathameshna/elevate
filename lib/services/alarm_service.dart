import '../models/alarm.dart';
import 'alarm_storage.dart';
import 'notification_service.dart';

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
      await NotificationService.instance.scheduleAlarm(alarm);
    }
  }

  Future<void> updateAlarm(Alarm updated) async {
    final index = _alarms.indexWhere((a) => a.id == updated.id);
    if (index == -1) return;
    _alarms[index] = updated;
    await AlarmStorage.saveAll(_alarms);
    // Always cancel then reschedule
    await NotificationService.instance.cancelAlarm(updated.id);
    if (updated.isEnabled) {
      await NotificationService.instance.scheduleAlarm(updated);
    }
  }

  Future<void> deleteAlarm(String id) async {
    await NotificationService.instance.cancelAlarm(id);
    _alarms.removeWhere((a) => a.id == id);
    await AlarmStorage.saveAll(_alarms);
  }

  Future<void> toggleAlarm(String id, bool isEnabled) async {
    final index = _alarms.indexWhere((a) => a.id == id);
    if (index == -1) return;
    final updated = _alarms[index].copyWith(isEnabled: isEnabled);
    _alarms[index] = updated;
    await AlarmStorage.saveAll(_alarms);
    if (isEnabled) {
      await NotificationService.instance.scheduleAlarm(updated);
    } else {
      await NotificationService.instance.cancelAlarm(id);
    }
  }
}
