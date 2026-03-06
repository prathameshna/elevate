import 'package:flutter/material.dart';

class Alarm {
  final String id;
  final TimeOfDay time;
  final String label;
  final String sound;
  bool isEnabled;
  final Set<int> selectedDays; // 0=Sun, 1=Mon, ..., 6=Sat

  final String? missionId;
  final String vibrationPattern;
  final int snoozeMinutes;
  final bool alwaysSnooze; 
  final bool enableWakeUpCheck;
  final bool showMemoAfter;
  final String? memoText;

  final int volume;
  final bool vibration;

  Alarm({
    required this.id,
    required this.time,
    this.label = '',
    this.sound = 'default_alarm',
    this.isEnabled = true,
    this.selectedDays = const {},
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

  bool get isOneTime => selectedDays.isEmpty;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timeHour': time.hour,
      'timeMinute': time.minute,
      'label': label,
      'sound': sound,
      'isEnabled': isEnabled,
      'selectedDays': selectedDays.toList(),
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
      time: TimeOfDay(
        hour: json['timeHour'] as int,
        minute: json['timeMinute'] as int,
      ),
      label: json['label'] as String? ?? '',
      sound: json['sound'] as String? ?? 'default_alarm',
      isEnabled: json['isEnabled'] as bool? ?? json['enabled'] as bool? ?? true,
      selectedDays: Set<int>.from(json['selectedDays'] ?? json['repeatDays'] ?? []),
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
    TimeOfDay? time,
    String? label,
    String? sound,
    bool? isEnabled,
    Set<int>? selectedDays,
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
      isEnabled: isEnabled ?? this.isEnabled,
      selectedDays: selectedDays ?? this.selectedDays,
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
    if (selectedDays.isEmpty) return 'One-time';
    if (selectedDays.length == 7) return 'Daily';
    if (selectedDays.length == 5 &&
        !selectedDays.contains(0) &&
        !selectedDays.contains(6)) return 'Weekdays';
    if (selectedDays.length == 2 &&
        selectedDays.contains(0) &&
        selectedDays.contains(6)) return 'Weekends';

    const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final sortedDays = List<int>.from(selectedDays)..sort();
    return 'Every ${sortedDays.map((d) => dayNames[d]).join(', ')}';
  }
}
