import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alarm.dart';

class AlarmStorage {
  static const String _key = 'elevate_alarms_v1';

  static Future<void> saveAll(List<Alarm> alarms) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = alarms.map((a) => jsonEncode(a.toJson())).toList();
    await prefs.setStringList(_key, encoded);
  }

  static Future<List<Alarm>> loadAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = prefs.getStringList(_key) ?? [];
      return encoded
          .map((e) => Alarm.fromJson(jsonDecode(e) as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Corrupted data — return empty list
      return [];
    }
  }

  static Future<void> saveOne(Alarm alarm) async {
    final all = await loadAll();
    final index = all.indexWhere((a) => a.id == alarm.id);
    if (index == -1) {
      all.add(alarm);
    } else {
      all[index] = alarm;
    }
    await saveAll(all);
  }

  static Future<void> deleteOne(String id) async {
    final all = await loadAll();
    all.removeWhere((a) => a.id == id);
    await saveAll(all);
  }
}
