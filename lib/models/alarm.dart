import 'package:flutter/material.dart';

enum AlarmRepeatPattern {
  oneTime,
  weekdays,
  weekends,
  everyDay,
  custom,
}

class Alarm {
  final String id;
  final TimeOfDay time;
  final String label;
  final List<int> repeatDays; // 1 = Monday ... 7 = Sunday
  final String sound;
  final int volume; // 0-100
  final bool vibration;
  final int snoozeMinutes;
  final bool isEnabled;
  final DateTime createdAt;

  const Alarm({
    required this.id,
    required this.time,
    required this.label,
    required this.repeatDays,
    required this.sound,
    required this.volume,
    required this.vibration,
    required this.snoozeMinutes,
    required this.isEnabled,
    required this.createdAt,
  });

  Alarm copyWith({
    String? id,
    TimeOfDay? time,
    String? label,
    List<int>? repeatDays,
    String? sound,
    int? volume,
    bool? vibration,
    int? snoozeMinutes,
    bool? isEnabled,
    DateTime? createdAt,
  }) {
    return Alarm(
      id: id ?? this.id,
      time: time ?? this.time,
      label: label ?? this.label,
      repeatDays: repeatDays ?? this.repeatDays,
      sound: sound ?? this.sound,
      volume: volume ?? this.volume,
      vibration: vibration ?? this.vibration,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hour': time.hour,
      'minute': time.minute,
      'label': label,
      'repeatDays': repeatDays,
      'sound': sound,
      'volume': volume,
      'vibration': vibration,
      'snoozeMinutes': snoozeMinutes,
      'isEnabled': isEnabled,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Alarm.fromJson(Map<String, dynamic> json) {
    return Alarm(
      id: json['id'] as String,
      time: TimeOfDay(
        hour: json['hour'] as int,
        minute: json['minute'] as int,
      ),
      label: json['label'] as String? ?? '',
      repeatDays: List<int>.from(json['repeatDays'] as List<dynamic>? ?? []),
      sound: json['sound'] as String? ?? 'Default',
      volume: json['volume'] as int? ?? 50,
      vibration: json['vibration'] as bool? ?? true,
      snoozeMinutes: json['snoozeMinutes'] as int? ?? 5,
      isEnabled: json['isEnabled'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  bool get isOneTime => repeatDays.isEmpty;

  String get frequencyLabel {
    if (repeatDays.isEmpty) return 'One-time alarm';
    if (repeatDays.length == 7) return 'Every day';
    if (_listEquals(repeatDays, const [1, 2, 3, 4, 5])) {
      return 'Weekdays alarm';
    }
    if (_listEquals(repeatDays, const [6, 7])) {
      return 'Weekends alarm';
    }
    return _customDaysLabel();
  }

  String _customDaysLabel() {
    const dayLabels = {
      1: 'Mon',
      2: 'Tue',
      3: 'Wed',
      4: 'Thu',
      5: 'Fri',
      6: 'Sat',
      7: 'Sun',
    };
    return repeatDays.map((d) => dayLabels[d] ?? '').join(' • ');
  }

  static bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

