import 'package:flutter/material.dart';

import '../models/alarm.dart';
import '../theme/app_theme.dart';

class AlarmCard extends StatelessWidget {
  const AlarmCard({
    super.key,
    required this.alarm,
    required this.onToggleChanged,
    required this.onTap,
    required this.onDelete,
  });

  final Alarm alarm;
  final ValueChanged<bool> onToggleChanged;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  String _formattedTime(BuildContext context) {
    final now = TimeOfDay.now();
    final localizations = MaterialLocalizations.of(context);
    final reference = DateTime(0, 1, 1, alarm.time.hour, alarm.time.minute);
    final formatted =
        localizations.formatTimeOfDay(alarm.time, alwaysUse24HourFormat: false);
    return formatted;
  }

  String _timeUntilLabel() {
    final now = DateTime.now();
    var scheduled = DateTime(
      now.year,
      now.month,
      now.day,
      alarm.time.hour,
      alarm.time.minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    final diff = scheduled.difference(now);
    final hours = diff.inHours;
    final minutes = diff.inMinutes.remainder(60);
    if (hours <= 0 && minutes <= 0) {
      return 'Alarm soon';
    }
    if (hours == 0) {
      return 'Alarm in $minutes minutes';
    }
    return 'Alarm in $hours hours ${minutes.toString().padLeft(2, '0')} minutes';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardTheme = theme.cardTheme;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: alarm.isEnabled ? 1 : 0.6,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 120),
          scale: 1.0,
          child: Card(
            margin: EdgeInsets.zero,
            shape: cardTheme.shape,
            color: cardTheme.color,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onLongPress: onDelete,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _timeUntilLabel(),
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formattedTime(context),
                                style: theme.textTheme.displayMedium?.copyWith(
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                alarm.label.isNotEmpty
                                    ? alarm.label
                                    : alarm.frequencyLabel,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: alarm.isEnabled,
                          onChanged: onToggleChanged,
                          activeColor: ElevateTheme.accent,
                        ),
                      ],
                    ),
                    if (alarm.repeatDays.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        alarm.frequencyLabel,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

