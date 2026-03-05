import 'package:flutter/material.dart';

import '../models/alarm.dart';
import '../theme/app_theme.dart';
import '../widgets/day_of_week_selector.dart';

class EditAlarmScreen extends StatefulWidget {
  const EditAlarmScreen({
    super.key,
    required this.alarm,
    required this.isNew,
  });

  final Alarm alarm;
  final bool isNew;

  @override
  State<EditAlarmScreen> createState() => _EditAlarmScreenState();
}

class _EditAlarmScreenState extends State<EditAlarmScreen> {
  late TimeOfDay _time;
  late TextEditingController _labelController;
  late List<int> _repeatDays;
  late int _snoozeMinutes;
  String _sound = 'Default';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _time = widget.alarm.time;
    _labelController = TextEditingController(text: widget.alarm.label);
    _repeatDays = List<int>.from(widget.alarm.repeatDays);
    _snoozeMinutes = widget.alarm.snoozeMinutes;
    _sound = widget.alarm.sound;
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: const TimePickerThemeData(
              backgroundColor: Color(0xFF1F1F1F),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked != null) {
      setState(() => _time = picked);
    }
  }

  void _changeSnooze(int delta) {
    setState(() {
      _snoozeMinutes = (_snoozeMinutes + delta).clamp(1, 30);
    });
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final updated = widget.alarm.copyWith(
      time: _time,
      label: _labelController.text.trim(),
      repeatDays: _repeatDays,
      sound: _sound,
      snoozeMinutes: _snoozeMinutes,
    );

    Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.isNew ? 'New Alarm' : 'Edit Alarm'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _pickTime,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F1F1F),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: ElevateTheme.cardBorder),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Time',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        MaterialLocalizations.of(context)
                            .formatTimeOfDay(_time),
                        style: theme.textTheme.displayLarge,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Repeat',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              DayOfWeekSelector(
                selectedDays: _repeatDays,
                onChanged: (days) => setState(() => _repeatDays = days),
              ),
              const SizedBox(height: 24),
              Text(
                'Label',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _labelController,
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Add label...',
                  hintStyle: theme.textTheme.bodyMedium,
                  filled: true,
                  fillColor: const Color(0xFF1F1F1F),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: ElevateTheme.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: ElevateTheme.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: ElevateTheme.accent),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sound',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1F1F1F),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: ElevateTheme.cardBorder,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _sound,
                                style: theme.textTheme.bodyLarge,
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: ElevateTheme.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Snooze',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1F1F1F),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: ElevateTheme.cardBorder,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                color: ElevateTheme.textSecondary,
                                onPressed: () => _changeSnooze(-5),
                              ),
                              Text(
                                '$_snoozeMinutes min',
                                style: theme.textTheme.bodyLarge,
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                color: ElevateTheme.textSecondary,
                                onPressed: () => _changeSnooze(5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: 16 + media.padding.bottom,
          ),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ElevateTheme.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(widget.isNew ? 'Save alarm' : 'Update alarm'),
            ),
          ),
        ),
      ),
    );
  }
}

