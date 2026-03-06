import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/alarm.dart';
import '../providers/alarm_provider.dart';
import '../widgets/day_of_week_selector.dart';
import '../widgets/snooze_config_modal.dart';
import 'mission_selection_screen.dart';
import 'sound_selection_screen.dart';
import 'vibration_selection_screen.dart';

class EditAlarmScreen extends StatefulWidget {
  final String? alarmId;

  const EditAlarmScreen({
    super.key,
    this.alarmId,
  });

  @override
  State<EditAlarmScreen> createState() => _EditAlarmScreenState();
}

class _EditAlarmScreenState extends State<EditAlarmScreen> {
  // === STATE VARIABLES ===
  late TimeOfDay _selectedTime;
  late List<int> _selectedDays;
  late String _selectedMission;
  late String _selectedSound;
  late String _selectedVibration;
  late int _snoozeMinutes;
  late bool _alwaysSnooze;
  late bool _enableWakeUpCheck;
  late bool _showMemoAfter;
  late String _memoText;

  late bool _isLoading;
  late bool _isEditMode;

  late TextEditingController _memoController;

  @override
  void initState() {
    super.initState();
    _initializeState();
  }

  void _initializeState() {
    _isEditMode = widget.alarmId != null;
    final provider = context.read<AlarmProvider>();

    if (_isEditMode) {
      final alarm = provider.alarms.firstWhere((a) => a.id == widget.alarmId);
      _selectedTime = TimeOfDay(hour: alarm.time.hour, minute: alarm.time.minute);
      _selectedDays = List<int>.from(alarm.repeatDays);
      _selectedMission = alarm.missionId ?? '';
      _selectedSound = alarm.sound;
      _selectedVibration = alarm.vibrationPattern;
      _snoozeMinutes = alarm.snoozeMinutes;
      _alwaysSnooze = alarm.alwaysSnooze;
      _enableWakeUpCheck = alarm.enableWakeUpCheck;
      _showMemoAfter = alarm.showMemoAfter;
      _memoText = alarm.memoText ?? '';
    } else {
      _selectedTime = TimeOfDay.now();
      _selectedDays = [];
      _selectedMission = '';
      _selectedSound = 'default_alarm';
      _selectedVibration = 'basic';
      _snoozeMinutes = 5;
      _alwaysSnooze = true;
      _enableWakeUpCheck = false;
      _showMemoAfter = false;
      _memoText = '';
    }

    _isLoading = false;
    _memoController = TextEditingController(text: _memoText);
  }

  String _getTimeUntilAlarm() {
    final now = DateTime.now();
    var alarmDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    if (alarmDateTime.isBefore(now)) {
      alarmDateTime = alarmDateTime.add(const Duration(days: 1));
    }

    final diff = alarmDateTime.difference(now);
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;

    if (hours == 0) {
      return 'Alarm in $minutes minute${minutes != 1 ? 's' : ''}';
    } else if (minutes == 0) {
      return 'Alarm in $hours hour${hours != 1 ? 's' : ''}';
    } else {
      return 'Alarm in $hours hour${hours != 1 ? 's' : ''} $minutes minute${minutes != 1 ? 's' : ''}';
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF14B8A6),
              onPrimary: Colors.white,
              surface: Color(0xFF2A2A2A),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
      HapticFeedback.selectionClick();
    }
  }

  void _openMissionSelection() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const MissionSelectionScreen()),
    );
    if (result != null) {
      setState(() => _selectedMission = result);
      HapticFeedback.selectionClick();
    }
  }

  void _openSoundSelection() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const SoundSelectionScreen()),
    );
    if (result != null) {
      setState(() => _selectedSound = result);
      HapticFeedback.selectionClick();
    }
  }

  void _openVibrationSelection() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const VibrationSelectionScreen()),
    );
    if (result != null) {
      setState(() => _selectedVibration = result);
      HapticFeedback.selectionClick();
    }
  }

  void _openSnoozeConfig() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SnoozeConfigModal(
        initialMinutes: _snoozeMinutes,
        initialAlwaysSnooze: _alwaysSnooze,
      ),
    );
    if (result != null) {
      setState(() {
        _snoozeMinutes = result['minutes'] as int;
        _alwaysSnooze = result['always'] as bool;
      });
      HapticFeedback.selectionClick();
    }
  }

  Future<void> _saveAlarm() async {
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one day'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      final provider = context.read<AlarmProvider>();
      final now = DateTime.now();
      final alarmTime = DateTime(
        now.year,
        now.month,
        now.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final alarm = Alarm(
        id: _isEditMode ? widget.alarmId! : DateTime.now().millisecondsSinceEpoch.toString(),
        time: alarmTime,
        label: '',
        sound: _selectedSound,
        enabled: true,
        repeatDays: _selectedDays,
        missionId: _selectedMission.isNotEmpty ? _selectedMission : null,
        vibrationPattern: _selectedVibration,
        snoozeMinutes: _snoozeMinutes,
        alwaysSnooze: _alwaysSnooze,
        enableWakeUpCheck: _enableWakeUpCheck,
        showMemoAfter: _showMemoAfter,
        memoText: _showMemoAfter ? _memoController.text : null,
        volume: 50,
        vibration: true,
      );

      if (_isEditMode) {
        await provider.updateAlarm(alarm);
      } else {
        await provider.addAlarm(alarm);
      }

      HapticFeedback.heavyImpact();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _isEditMode ? 'Edit alarm' : 'Create alarm',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    _getTimeUntilAlarm(),
                    style: const TextStyle(
                      color: Color(0xFFA0A0A0),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // === TIME PICKER BUTTON ===
                GestureDetector(
                  onTap: _pickTime,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.access_time_filled, color: Color(0xFFA0A0A0), size: 28),
                        const SizedBox(width: 16),
                        Text(
                          _selectedTime.format(context),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // === DAYS SELECTOR ===
                DayOfWeekSelector(
                  selectedDays: _selectedDays,
                  onDaysChanged: (days) => setState(() => _selectedDays = days),
                ),
                const SizedBox(height: 24),

                // === SETTINGS TILES ===
                _buildSectionLabel('Settings'),
                const SizedBox(height: 12),
                _buildSettingTile(
                  label: 'Mission',
                  value: _selectedMission.isEmpty ? 'None' : _selectedMission,
                  onTap: _openMissionSelection,
                ),
                const SizedBox(height: 12),
                _buildSettingTile(
                  label: 'Sound',
                  value: _selectedSound,
                  onTap: _openSoundSelection,
                ),
                const SizedBox(height: 12),
                _buildSettingTile(
                  label: 'Vibration',
                  value: _selectedVibration,
                  onTap: _openVibrationSelection,
                ),
                const SizedBox(height: 12),
                _buildSettingTile(
                  label: 'Snooze',
                  value: '$_snoozeMinutes min${_alwaysSnooze ? ', forever' : ''}',
                  onTap: _openSnoozeConfig,
                ),
                const SizedBox(height: 24),

                // === TOGGLES ===
                _buildToggleTile(
                  icon: Icons.check_circle_outline,
                  label: 'Wake Up Check',
                  value: _enableWakeUpCheck,
                  onToggle: (v) => setState(() => _enableWakeUpCheck = v),
                ),
                const SizedBox(height: 12),
                _buildToggleTile(
                  icon: Icons.note_outlined,
                  label: 'Show memo after alarm',
                  value: _showMemoAfter,
                  onToggle: (v) => setState(() => _showMemoAfter = v),
                ),

                if (_showMemoAfter) ...[
                  const SizedBox(height: 12),
                  _buildMemoInput(),
                ],

                const SizedBox(height: 120), // Space for sticky button
              ],
            ),
          ),

          // === STICKY SAVE BUTTON ===
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              height: 100,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF1A1A1A).withOpacity(0),
                    const Color(0xFF1A1A1A),
                  ],
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveAlarm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD600),
                    foregroundColor: const Color(0xFF1A1A1A),
                    disabledBackgroundColor: const Color(0xFFFFD600).withOpacity(0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A1A1A)),
                        )
                      : const Text(
                          'Save',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFFA0A0A0),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildSettingTile({required String label, required String value, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(color: Color(0xFFA0A0A0), fontSize: 12),
                ),
              ],
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFA0A0A0)),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleTile({required IconData icon, required String label, required bool value, required Function(bool) onToggle}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFA0A0A0), size: 20),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          Switch.adaptive(
            value: value,
            onChanged: onToggle,
            activeColor: const Color(0xFF14B8A6),
            inactiveTrackColor: const Color(0xFF3A3A3A),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3A3A3A)),
      ),
      child: TextField(
        controller: _memoController,
        maxLines: null,
        minLines: 3,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: const InputDecoration(
          hintText: 'Enter an alarm memo',
          hintStyle: TextStyle(color: Color(0xFFA0A0A0)),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
