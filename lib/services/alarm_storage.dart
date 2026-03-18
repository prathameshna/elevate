import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alarm.dart';

class AlarmStorage {
  static const String _key = 'alarms';

  static Future<Map<String, Alarm>> _loadAllInternal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, Alarm.fromJson(v as Map<String, dynamic>)));
    } catch (_) {
      return {};
    }
  }

  static Future<List<Alarm>> loadList() async {
    final map = await _loadAllInternal();
    final list = map.values.toList();
    list.sort((a, b) {
      final aMin = a.time.hour * 60 + a.time.minute;
      final bMin = b.time.hour * 60 + b.time.minute;
      return aMin.compareTo(bMin);
    });
    return list;
  }

  static Future<void> save(Alarm alarm) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await _loadAllInternal();
    all[alarm.id] = alarm;
    await prefs.setString(
      _key,
      jsonEncode(all.map((k, v) => MapEntry(k, v.toJson()))),
    );
  }

  static Future<void> delete(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await _loadAllInternal();
    all.remove(id);
    await prefs.setString(
      _key,
      jsonEncode(all.map((k, v) => MapEntry(k, v.toJson()))),
    );
  }

  static Future<Alarm?> loadOne(String id) async {
    final all = await _loadAllInternal();
    return all[id];
  }

  // Find alarm by numeric ID — called when alarm rings
  static Future<Alarm?> getByNumericId(int numericId) async {
    final all = await _loadAllInternal();
    try {
      return all.values.firstWhere(
        (a) => a.id.hashCode.abs() % 2147483647 == numericId,
      );
    } catch (_) {
      return null;
    }
  }

  // Backward compatibility aliases if needed
  static Future<List<Alarm>> loadAll() => loadList();
  static Future<void> saveOne(Alarm alarm) => save(alarm);
  static Future<void> deleteOne(String id) => delete(id);
  static Future<void> saveAll(List<Alarm> alarms) async {
    final prefs = await SharedPreferences.getInstance();
    final map = {for (var a in alarms) a.id: a};
    await prefs.setString(
      _key,
      jsonEncode(map.map((k, v) => MapEntry(k, v.toJson()))),
    );
  }
}
