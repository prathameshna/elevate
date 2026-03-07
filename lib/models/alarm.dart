import 'package:flutter/material.dart';

class Alarm {
  final String id;
  final TimeOfDay time;
  final String label;
  final String? soundId;
  bool isEnabled;
  final Set<int> selectedDays; // 0=Sun, 1=Mon, ..., 6=Sat

  final List<String> missionIds;
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
    this.soundId,
    this.isEnabled = true,
    this.selectedDays = const {},
    this.missionIds = const [],
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
      'soundId': soundId,
      'isEnabled': isEnabled,
      'selectedDays': selectedDays.toList(),
      'missionIds': missionIds,
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
      soundId: json['soundId'] as String? ?? json['sound'] as String?,
      isEnabled: json['isEnabled'] as bool? ?? json['enabled'] as bool? ?? true,
      selectedDays: Set<int>.from(json['selectedDays'] ?? json['repeatDays'] ?? []),
      missionIds: List<String>.from(json['missionIds'] ?? (json['missionId'] != null ? [json['missionId']] : [])),
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
    String? soundId,
    bool? isEnabled,
    Set<int>? selectedDays,
    List<String>? missionIds,
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
      soundId: soundId ?? this.soundId,
      isEnabled: isEnabled ?? this.isEnabled,
      selectedDays: selectedDays ?? this.selectedDays,
      missionIds: missionIds ?? this.missionIds,
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
    if (selectedDays.length == 7) return 'Every day';
    if (selectedDays.length == 5 &&
        selectedDays.containsAll({1, 2, 3, 4, 5})) return 'Weekdays';
    if (selectedDays.length == 2 &&
        selectedDays.containsAll({0, 6})) return 'Weekends';

    const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final sortedDays = List<int>.from(selectedDays)..sort();
    return sortedDays.map((d) => dayNames[d]).join(', ');
  }
}
