import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/alarm.dart';
import '../models/mission.dart';
import '../providers/alarm_provider.dart';
import '../services/alarm_service.dart';
import '../widgets/day_selector/day_selector_widget.dart';
import '../widgets/mission_card.dart';
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
  late Set<int> _selectedDays;
  late bool _isEnabled;
  late String _selectedSound;
  late String _selectedVibration;
  late int _snoozeMinutes;
  late bool _alwaysSnooze;
  late List<String> _assignedMissions;
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

    if (_isEditMode) {
      try {
        final alarm = AlarmService.instance.alarms.firstWhere((a) => a.id == widget.alarmId);
        _selectedTime = alarm.time;
        _isEnabled = alarm.isEnabled;
        _selectedDays = Set<int>.from(alarm.selectedDays);
        _assignedMissions = List<String>.from(alarm.missionIds);
        _selectedSound = alarm.sound;
        _selectedVibration = alarm.vibrationPattern;
        _snoozeMinutes = alarm.snoozeMinutes;
        _alwaysSnooze = alarm.alwaysSnooze;
        _enableWakeUpCheck = alarm.enableWakeUpCheck;
        _showMemoAfter = alarm.showMemoAfter;
        _memoText = alarm.memoText ?? '';
      } catch (e) {
        // Fallback if alarm not found
        _selectedTime = TimeOfDay.now();
        _isEnabled = true;
        _selectedDays = {};
        _assignedMissions = [];
        _selectedSound = 'default_alarm';
        _selectedVibration = 'basic';
        _snoozeMinutes = 5;
        _alwaysSnooze = true;
        _enableWakeUpCheck = false;
        _showMemoAfter = false;
        _memoText = '';
      }
    } else {
      _selectedTime = TimeOfDay.now();
      _isEnabled = true;
      _selectedDays = {};
      _assignedMissions = [];
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

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
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
    if (_isLoading) return;
    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      final alarm = Alarm(
        id: _isEditMode ? widget.alarmId! : DateTime.now().millisecondsSinceEpoch.toString(),
        time: _selectedTime,
        label: '',
        sound: _selectedSound,
        isEnabled: _isEnabled,
        selectedDays: _selectedDays,
        missionIds: _assignedMissions,
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
        await AlarmService.instance.updateAlarm(alarm);
      } else {
        await AlarmService.instance.createAlarm(alarm);
      }

      if (!mounted) return;

      HapticFeedback.heavyImpact();

      // Show teal success snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.alarm_on_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Text(
                'Alarm set for ${_formatAlarmTime()}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF14B8A6),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );

      Navigator.pop(context, alarm);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save alarm: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Helper to format time for snackbar
  String _formatAlarmTime() {
    final hour = _selectedTime.hourOfPeriod == 0 ? 12 : _selectedTime.hourOfPeriod;
    final minute = _selectedTime.minute.toString().padLeft(2, '0');
    final period = _selectedTime.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Column(
        children: [
          // === HEADER SECTION (Non-scrollable, Professional) ===
          _buildProfessionalHeader(context),

          // === SCROLLABLE CONTENT ===
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInset + safeAreaBottom + 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- TIME PICKER SECTION ---
                  _buildProfessionalTimePicker(),
                  
                  // --- SCHEDULE SECTION (New Redesigned Day Selector) ---
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8, top: 20),
                    child: const Text(
                      'SCHEDULE',
                      style: TextStyle(
                        color: Color(0xFFA0A0A0),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ),
                  DaySelectorWidget(
                    selectedDays: _selectedDays,
                    onDaysChanged: (days) {
                      if (!mounted) return;
                      setState(() => _selectedDays = days);
                    },
                  ),
                  const SizedBox(height: 20),

                  // --- MISSION section label ---
                  Padding(
                    padding: const EdgeInsets.only(top: 20, bottom: 8, left: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 3,
                          height: 12,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF14B8A6),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const Text(
                          'MISSION',
                          style: TextStyle(
                            color: Color(0xFFA0A0A0),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- Mission card ---
                  MissionCard(
                    assignedMissions: _assignedMissions,
                    wakeUpCheckEnabled: _enableWakeUpCheck,
                    onMissionsChanged: (missions) {
                      setState(() => _assignedMissions = missions);
                    },
                    onWakeUpCheckChanged: (value) {
                      setState(() => _enableWakeUpCheck = value);
                    },
                  ),
                  const SizedBox(height: 24),

                  // --- SETTINGS SECTION ---
                  _buildSectionLabel('Settings'),
                  const SizedBox(height: 12),
                  // Mission tile removed as it's now in MissionCard
                  _buildProfessionalSettingTile(
                    label: 'Sound',
                    value: _selectedSound,
                    onTap: _openSoundSelection,
                  ),
                  const SizedBox(height: 12),
                  _buildProfessionalSettingTile(
                    label: 'Vibration',
                    value: _selectedVibration,
                    onTap: _openVibrationSelection,
                  ),
                  const SizedBox(height: 12),
                  _buildProfessionalSettingTile(
                    label: 'Snooze',
                    value: '$_snoozeMinutes min${_alwaysSnooze ? ', forever' : ''}',
                    onTap: _openSnoozeConfig,
                  ),
                  const SizedBox(height: 24),

                  // --- TOGGLES SECTION ---
                  // Wake Up Check tile removed as it's now in MissionCard
                  _buildProfessionalToggleTile(
                    icon: Icons.note_outlined,
                    label: 'Show memo after alarm',
                    value: _showMemoAfter,
                    onToggle: (v) => setState(() => _showMemoAfter = v),
                  ),

                  // --- CONDITIONAL MEMO ---
                  AnimatedCrossFade(
                    firstChild: const SizedBox(width: double.infinity),
                    secondChild: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _buildProfessionalMemoInput(),
                    ),
                    crossFadeState: _showMemoAfter ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 200),
                  ),
                ],
              ),
            ),
          ),

          // === SAVE BUTTON (Outside scroll, respects safe area) ===
          _buildProfessionalSaveButton(safeAreaBottom),
        ],
      ),
    );
  }

  Widget _buildProfessionalHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 12,
        left: 8,
        right: 16,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1A1A), Color(0xFF0F0F0F)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFFF5F5F5),
              size: 20,
            ),
            onPressed: () => Navigator.of(context).pop(),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Edit alarm',
                  style: TextStyle(
                    color: Color(0xFFF5F5F5),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalTimePicker() {
    return GestureDetector(
      onTap: _pickTime,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              offset: const Offset(0, 4),
              blurRadius: 12,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedTime.format(context),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  _selectedTime.period == DayPeriod.am ? 'AM' : 'PM',
                  style: const TextStyle(color: Color(0xFFA0A0A0), fontSize: 12),
                ),
              ],
            ),
            const Icon(Icons.access_time_filled, color: Color(0xFFF59E0B), size: 40),
          ],
        ),
      ),
    );
  }


  Widget _buildProfessionalSettingTile({required String label, required String value, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              offset: const Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: Color(0xFFF5F5F5), fontSize: 14, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(color: Color(0xFFA0A0A0), fontSize: 12, fontWeight: FontWeight.w400),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Color(0xFFA0A0A0), size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalToggleTile({required IconData icon, required String label, required bool value, required Function(bool) onToggle}) {
    return GestureDetector(
      onTap: () => onToggle(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              offset: const Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(icon, color: const Color(0xFFA0A0A0), size: 20),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: const TextStyle(color: Color(0xFFF5F5F5), fontSize: 14, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: value,
              onChanged: onToggle,
              activeColor: const Color(0xFF14B8A6),
              inactiveTrackColor: const Color(0xFF3A3A3A),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalMemoInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3A3A3A)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: TextField(
        controller: _memoController,
        maxLines: null,
        minLines: 3,
        cursorColor: const Color(0xFF14B8A6),
        style: const TextStyle(color: Color(0xFFF5F5F5), fontSize: 14, fontWeight: FontWeight.w400),
        decoration: const InputDecoration(
          hintText: 'Enter an alarm memo',
          hintStyle: TextStyle(color: Color(0xFFA0A0A0)),
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildProfessionalSaveButton(double safeAreaBottom) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, safeAreaBottom > 0 ? 0 : 16),
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD600).withOpacity(0.3),
                offset: const Offset(0, 8),
                blurRadius: 24,
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveAlarm,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD600),
              foregroundColor: const Color(0xFF1A1A1A),
              disabledBackgroundColor: const Color(0xFFFFD600).withOpacity(0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
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
}
