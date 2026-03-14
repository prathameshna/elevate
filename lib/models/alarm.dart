import 'package:flutter/material.dart';

class Alarm {
  final String id;
  final TimeOfDay time;
  final String label;
  final String? soundId;
  final String? soundFile;
  final bool soundEnabled;
  bool isEnabled;
  final Set<int> selectedDays; // 0=Sun, 1=Mon, ..., 6=Sat

  final List<String> missionIds;
  final String vibrationId;
  final bool vibrationEnabled;
  final int snoozeMinutes;
  final bool alwaysSnooze; 
  final bool enableWakeUpCheck;
  final bool showMemoAfter;
  final String? memoText;
  final List<Map<String, dynamic>> missions;

  final int volume;
  final bool      snoozeEnabled;
  final int snoozeCount;

  List<int> get days => selectedDays.toList();
  String? get memo => memoText;

  Alarm({
    required this.id,
    required this.time,
    this.label = '',
    this.soundId,
    this.soundFile,
    this.soundEnabled = true,
    this.isEnabled = true,
    this.selectedDays = const {},
    this.missionIds = const [],
    this.vibrationId = 'basic',
    this.vibrationEnabled = true,
    this.snoozeMinutes = 5,
    this.alwaysSnooze = true,
    this.enableWakeUpCheck = false,
    this.showMemoAfter = false,
    this.memoText,
    this.missions = const [],
    this.volume = 50,
    this.snoozeEnabled = false,
    this.snoozeCount = 0,
  });

  bool get isOneTime => selectedDays.isEmpty;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timeHour': time.hour,
      'timeMinute': time.minute,
      'label': label,
      'soundId': soundId,
      'soundFile': soundFile,
      'soundEnabled': soundEnabled,
      'isEnabled': isEnabled,
      'selectedDays': selectedDays.toList(),
      'missionIds': missionIds,
      'vibrationId': vibrationId,
      'vibrationEnabled': vibrationEnabled,
      'snoozeMinutes': snoozeMinutes,
      'alwaysSnooze': alwaysSnooze,
      'enableWakeUpCheck': enableWakeUpCheck,
      'showMemoAfter': showMemoAfter,
      'memoText': memoText,
      'missions': missions.map((m) => m).toList(),
      'volume': volume,
      'snoozeEnabled': snoozeEnabled,
      'snoozeCount': snoozeCount,
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
      soundFile: json['soundFile'] as String?,
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      isEnabled: json['isEnabled'] as bool? ?? json['enabled'] as bool? ?? true,
      selectedDays: Set<int>.from(json['selectedDays'] ?? json['repeatDays'] ?? []),
      missionIds: List<String>.from(json['missionIds'] ?? (json['missionId'] != null ? [json['missionId']] : [])),
      vibrationId: json['vibrationId'] as String? ?? json['vibrationPattern'] as String? ?? 'basic',
      vibrationEnabled: json['vibrationEnabled'] as bool? ?? json['vibration'] as bool? ?? true,
      snoozeMinutes: json['snoozeMinutes'] as int? ?? 5,
      alwaysSnooze: json['alwaysSnooze'] as bool? ?? true,
      enableWakeUpCheck: json['enableWakeUpCheck'] as bool? ?? false,
      showMemoAfter: json['showMemoAfter'] as bool? ?? false,
      memoText: json['memoText'] as String?,
      missions: json['missions'] != null
          ? (json['missions'] as List<dynamic>)
              .map((m) => Map<String, dynamic>.from(m as Map))
              .toList()
          : (json['missionData'] != null
              ? [Map<String, dynamic>.from(json['missionData'] as Map)]
              : []),
      volume: json['volume'] as int? ?? 50,
      snoozeEnabled: json['snoozeEnabled'] as bool? ?? false,
      snoozeCount: json['snoozeCount'] as int? ?? 0,
    );
  }

  Alarm copyWith({
    String? id,
    TimeOfDay? time,
    String? label,
    String? soundId,
    String? soundFile,
    bool? soundEnabled,
    bool? isEnabled,
    Set<int>? selectedDays,
    List<String>? missionIds,
    String? vibrationId,
    bool? vibrationEnabled,
    int? snoozeMinutes,
    bool? alwaysSnooze,
    bool? enableWakeUpCheck,
    bool? showMemoAfter,
    String? memoText,
    List<Map<String, dynamic>>? missions,
    int? volume,
    bool? snoozeEnabled,
    int? snoozeCount,
  }) {
    return Alarm(
      id: id ?? this.id,
      time: time ?? this.time,
      label: label ?? this.label,
      soundId: soundId ?? this.soundId,
      soundFile: soundFile ?? this.soundFile,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      isEnabled: isEnabled ?? this.isEnabled,
      selectedDays: selectedDays ?? this.selectedDays,
      missionIds: missionIds ?? this.missionIds,
      vibrationId: vibrationId ?? this.vibrationId,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      alwaysSnooze: alwaysSnooze ?? this.alwaysSnooze,
      enableWakeUpCheck: enableWakeUpCheck ?? this.enableWakeUpCheck,
      showMemoAfter: showMemoAfter ?? this.showMemoAfter,
      memoText: memoText ?? this.memoText,
      missions: missions ?? this.missions,
      volume: volume ?? this.volume,
      snoozeEnabled: snoozeEnabled ?? this.snoozeEnabled,
      snoozeCount: snoozeCount ?? this.snoozeCount,
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
        selectedDays.containsAll({1, 2, 3, 4, 5})) {
      return 'Weekdays';
    }
    if (selectedDays.length == 2 &&
        selectedDays.containsAll({0, 6})) {
      return 'Weekends';
    }

    const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final sortedDays = List<int>.from(selectedDays)..sort();
    return sortedDays.map((d) => dayNames[d]).join(', ');
  }
}
