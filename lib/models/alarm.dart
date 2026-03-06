import 'package:flutter/material.dart';

class Alarm {
  final String id;
  final DateTime time;
  final String label;
  final String sound;
  final bool enabled;
  final List<int> repeatDays; // 0=Sun, 1=Mon, ..., 6=Sat

  final String? missionId;
  final String vibrationPattern;
  final int snoozeMinutes;
  final bool alwaysSnooze; // Not explicitly in practical but useful
  final bool enableWakeUpCheck;
  final bool showMemoAfter;
  final String? memoText;

  final int volume;
  final bool vibration;

  Alarm({
    required this.id,
    required this.time,
    required this.label,
    required this.sound,
    required this.enabled,
    required this.repeatDays,
    this.missionId,
    this.vibrationPattern = 'basic',
    this.snoozeMinutes = 5,
    this.alwaysSnooze = true,
    this.enableWakeUpCheck = false,
    this.showMemoAfter = false,
    this.memoText,
    this.volume = 50,
    this.vibration = true,
  });

  bool get isOneTime => repeatDays.isEmpty;
  bool get isEnabled => enabled;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'time': time.toIso8601String(),
      'label': label,
      'sound': sound,
      'enabled': enabled,
      'repeatDays': repeatDays,
      'missionId': missionId,
      'vibrationPattern': vibrationPattern,
      'snoozeMinutes': snoozeMinutes,
      'alwaysSnooze': alwaysSnooze,
      'enableWakeUpCheck': enableWakeUpCheck,
      'showMemoAfter': showMemoAfter,
      'memoText': memoText,
      'volume': volume,
      'vibration': vibration,
    };
  }

  factory Alarm.fromJson(Map<String, dynamic> json) {
    return Alarm(
      id: json['id'] as String,
      time: DateTime.parse(json['time'] as String),
      label: json['label'] as String? ?? '',
      sound: json['sound'] as String? ?? 'default_alarm',
      enabled: json['enabled'] as bool? ?? true,
      repeatDays: List<int>.from(json['repeatDays'] ?? []),
      missionId: json['missionId'] as String?,
      vibrationPattern: json['vibrationPattern'] as String? ?? 'basic',
      snoozeMinutes: json['snoozeMinutes'] as int? ?? 5,
      alwaysSnooze: json['alwaysSnooze'] as bool? ?? true,
      enableWakeUpCheck: json['enableWakeUpCheck'] as bool? ?? false,
      showMemoAfter: json['showMemoAfter'] as bool? ?? false,
      memoText: json['memoText'] as String?,
      volume: json['volume'] as int? ?? 50,
      vibration: json['vibration'] as bool? ?? true,
    );
  }

  Alarm copyWith({
    String? id,
    DateTime? time,
    String? label,
    String? sound,
    bool? enabled,
    List<int>? repeatDays,
    String? missionId,
    String? vibrationPattern,
    int? snoozeMinutes,
    bool? alwaysSnooze,
    bool? enableWakeUpCheck,
    bool? showMemoAfter,
    String? memoText,
    int? volume,
    bool? vibration,
  }) {
    return Alarm(
      id: id ?? this.id,
      time: time ?? this.time,
      label: label ?? this.label,
      sound: sound ?? this.sound,
      enabled: enabled ?? this.enabled,
      repeatDays: repeatDays ?? this.repeatDays,
      missionId: missionId ?? this.missionId,
      vibrationPattern: vibrationPattern ?? this.vibrationPattern,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      alwaysSnooze: alwaysSnooze ?? this.alwaysSnooze,
      enableWakeUpCheck: enableWakeUpCheck ?? this.enableWakeUpCheck,
      showMemoAfter: showMemoAfter ?? this.showMemoAfter,
      memoText: memoText ?? this.memoText,
      volume: volume ?? this.volume,
      vibration: vibration ?? this.vibration,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Alarm &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  String get frequencyLabel {
    if (repeatDays.isEmpty) return 'One-time';
    if (repeatDays.length == 7) return 'Daily';
    if (repeatDays.length == 5 &&
        !repeatDays.contains(0) &&
        !repeatDays.contains(6)) return 'Weekdays';
    if (repeatDays.length == 2 &&
        repeatDays.contains(0) &&
        repeatDays.contains(6)) return 'Weekends';

    const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final sortedDays = List<int>.from(repeatDays)..sort();
    return 'Every ${sortedDays.map((d) => dayNames[d]).join(', ')}';
  }
}
