import '../models/alarm.dart';
import '../providers/alarm_provider.dart';
import 'alarm_scheduler.dart';

class AlarmService {
  AlarmService._();
  static final AlarmService instance = AlarmService._();

  late AlarmProvider _provider;

  void init(AlarmProvider provider) {
    _provider = provider;
  }

  // UPDATE alarm (called when toggle changes)
  Future<void> updateAlarm(Alarm updated) async {
    await _provider.updateAlarm(updated);
  }

  // SCHEDULE native alarm notification
  Future<void> scheduleAlarm(Alarm alarm) async {
    if (!alarm.isEnabled) return;
    await AlarmScheduler.instance.scheduleAlarm(alarm);
  }

  // CANCEL native alarm notification
  Future<void> cancelAlarm(String alarmId) async {
    await AlarmScheduler.instance.cancelAlarm(alarmId);
  }
}
