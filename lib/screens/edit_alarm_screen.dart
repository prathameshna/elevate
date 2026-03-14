import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/alarm.dart';
import '../models/my_music_track.dart';
import '../models/sound_item.dart';
import '../models/vibration_item.dart';
import '../alarm/alarm_scheduler.dart';
import '../services/alarm_service.dart';
import '../widgets/day_selector/day_selector_widget.dart';
import '../missions/colour_tiles/colour_tiles_config_screen.dart';
import '../missions/colour_tiles/colour_tiles_model.dart';
import 'mission_list_screen.dart';
import '../widgets/time_picker/time_picker_wheel.dart';
import '../widgets/snooze_config_modal.dart';
import 'sound_selection_screen.dart';
import 'vibration_screen.dart';

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
  String? _selectedSoundId;
  String _selectedVibrationId = 'basic';
  late int _snoozeMinutes;
  late bool _alwaysSnooze;
  List<Map<String, dynamic>?> _missionSlots = [null, null, null, null];
  bool _wakeUpCheckEnabled = false;

  int get _activeMissionCount =>
      _missionSlots.where((s) => s != null).length;
  late bool _showMemoAfter;
  late String _memoText;
  String? _selectedSoundFile;
  bool _snoozeEnabled = false;


  late bool _isLoading;
  late bool _isEditMode;

  late TextEditingController _memoController;

  List<MyMusicTrack> _myMusicTracks = [];

  @override
  void initState() {
    super.initState();
    _initializeState();
    _loadMyMusicTracks();
  }

  Future<void> _loadMyMusicTracks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = prefs.getStringList('my_music_tracks') ?? [];
      if (mounted) {
        setState(() {
          _myMusicTracks = encoded
              .map((e) => MyMusicTrack.fromJson(jsonDecode(e)))
              .toList();
        });
      }
    } catch (_) {}
  }

  void _initializeState() {
    _isEditMode = widget.alarmId != null;

    if (_isEditMode) {
      try {
        final alarm = AlarmService.instance.alarms.firstWhere((a) => a.id == widget.alarmId);
        _selectedTime = alarm.time;
        _isEnabled = alarm.isEnabled;
        _selectedDays = Set<int>.from(alarm.selectedDays);
        _missionSlots = List.generate(4, (i) {
          if (i < alarm.missions.length) {
            return alarm.missions[i];
          }
          return null;
        });
        _selectedSoundId = alarm.soundId;
        _selectedVibrationId = alarm.vibrationId;
        _snoozeMinutes = alarm.snoozeMinutes;
        _alwaysSnooze = alarm.alwaysSnooze;
        _wakeUpCheckEnabled = alarm.enableWakeUpCheck;
        _showMemoAfter = alarm.showMemoAfter;
        _memoText = alarm.memo ?? '';
        _selectedSoundFile = alarm.soundFile;
        _snoozeEnabled = alarm.snoozeEnabled;
      } catch (e) {
        // Fallback if alarm not found
        _selectedTime = TimeOfDay.now();
        _isEnabled = true;
        _selectedDays = {};
        _missionSlots = [null, null, null, null];
        _selectedSoundId = null;
        _selectedVibrationId = 'basic';
        _snoozeMinutes = 5;
        _alwaysSnooze = true;
        _wakeUpCheckEnabled = false;
        _showMemoAfter = false;
        _memoText = '';
        _selectedSoundFile = null;
        _snoozeEnabled = false;
      }
    } else {
      _selectedTime = TimeOfDay.now();
      _isEnabled = true;
      _selectedDays = {};
      _missionSlots = [null, null, null, null];
      _selectedSoundId = null;
      _selectedVibrationId = 'basic';
      _snoozeMinutes = 5;
      _alwaysSnooze = true;
      _wakeUpCheckEnabled = false;
      _showMemoAfter = false;
      _memoText = '';
      _selectedSoundFile = null;
      _snoozeEnabled = false;
    }

    _isLoading = false;
    _memoController = TextEditingController(text: _memoText);
  }



  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }




  String _getSoundName() {
    if (_selectedSoundId == null || _selectedSoundId == 'default_alarm') return 'Default';
    for (final sounds in soundLibrary.values) {
      for (final s in sounds) {
        if (s.id == _selectedSoundId) return s.name;
      }
    }
    for (final track in _myMusicTracks) {
      if (track.id == _selectedSoundId) return track.name;
    }
    if (_selectedSoundId!.startsWith('my_')) return 'Custom Sound';
    return _selectedSoundId!;
  }

  String _getVibrationName() {
    return kVibrations
        .firstWhere(
          (v) => v.id == _selectedVibrationId,
          orElse: () => kVibrations.first,
        )
        .name;
  }

  void _openSoundSelection() async {
    final result = await Navigator.of(context).push<Map<String, String>>(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 380),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, animation, _) => SoundSelectionScreen(initialSoundId: _selectedSoundId),
        transitionsBuilder: (_, animation, _, child) {
          final slide = Tween<Offset>(
            begin: const Offset(0, 0.08),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
          final fade = Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: const Interval(0.0, 0.65, curve: Curves.easeOut)),
          );
          return FadeTransition(opacity: fade, child: SlideTransition(position: slide, child: child));
        },
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _selectedSoundId = result['id'];
        _selectedSoundFile = result['file'];
      });
      _loadMyMusicTracks();
      HapticFeedback.selectionClick();
    }
  }

  void _openVibrationSelection() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => VibrationScreen(initialId: _selectedVibrationId),
      ),
    );
    if (result != null && mounted) {
      setState(() => _selectedVibrationId = result);
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
        soundId: _selectedSoundId,
        soundFile: _selectedSoundFile ?? 'alarm_ringtone.mp3',
        soundEnabled: true,
        isEnabled: _isEnabled,
        selectedDays: _selectedDays,
        vibrationId: _selectedVibrationId,
        vibrationEnabled: true,
        snoozeEnabled: _snoozeEnabled,
        snoozeMinutes: _snoozeMinutes,
        alwaysSnooze: _alwaysSnooze,
        enableWakeUpCheck: _wakeUpCheckEnabled,
        showMemoAfter: _showMemoAfter,
        memoText: _showMemoAfter ? _memoController.text : _memoController.text,
        missions: _missionSlots
            .where((s) => s != null)
            .map((s) => s!)
            .toList(),
        volume: 50,
        snoozeCount: 0,
      );

      if (_isEditMode) {
        await AlarmService.instance.updateAlarm(alarm);
      } else {
        await AlarmService.instance.createAlarm(alarm);
      }
      
      await AlarmScheduler.instance.schedule(alarm);

      debugPrint('--- ALARM SAVED ---');
      debugPrint('Label: ${alarm.label}');
      debugPrint('Time: ${alarm.time.hour}:${alarm.time.minute}');
      debugPrint('Sound: ${alarm.soundFile}');
      debugPrint('VibId: ${alarm.vibrationId}');
      debugPrint('Memo: ${alarm.memo}');
      debugPrint('-------------------');

      if (!mounted) return;

      HapticFeedback.heavyImpact();

      // Show confirmation snackbar:
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Alarm set ✓',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
          ),
          backgroundColor: const Color(0xFFFFD600),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: TimePickerWheel(
                      initialTime: _selectedTime,
                      onTimeChanged: (time) {
                        setState(() {
                          _selectedTime = time;
                        });
                      },
                    ),
                  ),
                  
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

                  _buildMissionCard(),
                  const SizedBox(height: 24),

                  // --- SETTINGS SECTION ---
                  _buildSectionLabel('Settings'),
                  const SizedBox(height: 12),
                  // Mission tile removed as it's now in MissionCard
                  _buildProfessionalSettingTile(
                    label: 'Sound',
                    value: _getSoundName(),
                    onTap: _openSoundSelection,
                  ),
                  const SizedBox(height: 12),
                  _buildProfessionalSettingTile(
                    label: 'Vibration',
                    value: _getVibrationName(),
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
            color: Colors.black.withValues(alpha: 0.3),
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
              color: Colors.black.withValues(alpha: 0.15),
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
              color: Colors.black.withValues(alpha: 0.15),
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
              activeThumbColor: const Color(0xFF14B8A6),
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
            color: Colors.black.withValues(alpha: 0.15),
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
                color: const Color(0xFFFFD600).withValues(alpha: 0.3),
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
              disabledBackgroundColor: const Color(0xFFFFD600).withValues(alpha: 0.5),
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

  // === NEW MISSION SELECTION UI ===
  Widget _buildMissionCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF252525)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ───────────────────────────────
          Row(
            children: [
              const Text(
                'Wake-up mission',
                style: TextStyle(
                  color: Color(0xFFF0F0F0),
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              // Yellow count / grey max
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$_activeMissionCount',
                      style: const TextStyle(
                        color: Color(0xFFFFD600),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const TextSpan(
                      text: '/5',
                      style: TextStyle(
                        color: Color(0xFF606060),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Mission slots row (4 slots) ──────────────
          Row(
            children: List.generate(4, (i) {
              final slot = _missionSlots[i];
              return Expanded(
                child: GestureDetector(
                  onTap: () => _onSlotTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(right: i < 3 ? 10 : 0),
                    height: 72,
                    decoration: BoxDecoration(
                      color: slot != null
                          ? const Color(0xFF252525)
                          : const Color(0xFF222222),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: slot != null
                            ? const Color(0xFFFFD600).withValues(alpha: 0.3)
                            : const Color(0xFF2E2E2E),
                      ),
                    ),
                    child: slot == null
                        ? const Icon(
                            Icons.add_rounded,
                            color: Color(0xFF505050),
                            size: 26,
                          )
                        : _buildFilledSlot(slot, i),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 4),
          const Divider(color: Color(0xFF252525), height: 28),

          // ── Wake up check row ─────────────────────────
          GestureDetector(
            onTap: () => setState(() => _wakeUpCheckEnabled = !_wakeUpCheckEnabled),
            child: Container(
              color: Colors.transparent, // expand tap area
              child: Row(
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    color: _wakeUpCheckEnabled
                        ? const Color(0xFFFFD600)
                        : const Color(0xFF606060),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Wake up check',
                    style: TextStyle(
                      color: Color(0xFFF0F0F0),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // HOT badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCC2222),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'HOT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _wakeUpCheckEnabled ? 'On' : 'Off',
                    style: const TextStyle(
                      color: Color(0xFF606060),
                      fontSize: 14,
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: Color(0xFF505050), size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilledSlot(Map<String, dynamic> slot, int index) {
    final type = slot['type'] as String;
    final def = kAllMissions.firstWhere(
      (m) => m.id == type,
      orElse: () => const MissionDefinition(
        id:          'unknown',
        name:        'Mission',
        icon:        Icons.star_rounded,
        iconBgColor: Color(0xFF333333),
      ),
    );

    return Stack(
      children: [
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color:        def.iconBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(def.icon, color: Colors.white, size: 18),
              ),
              const SizedBox(height: 4),
              Text(
                def.name.length > 10
                    ? '${def.name.substring(0, 8)}..' : def.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color:      Color(0xFFF0F0F0),
                  fontSize:   8.5,
                  fontWeight: FontWeight.w600,
                  height:     1.2,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 4, right: 4,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _missionSlots[index] = null);
            },
            child: Container(
              width: 16, height: 16,
              decoration: const BoxDecoration(
                color: Color(0xFF444444), shape: BoxShape.circle),
              child: const Icon(Icons.close_rounded,
                  color: Colors.white, size: 10),
            ),
          ),
        ),
      ],
    );
  }

  void _onSlotTap(int index) async {
    if (_missionSlots[index] != null) {
      _openMissionConfig(index);
      return;
    }

    final MissionDefinition? mission = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MissionListScreen()),
    );

    if (mission == null || !mounted) return;

    switch (mission.id) {
      case 'colour_tiles':
        final config = await Navigator.push<ColourTilesConfig>(
          context,
          MaterialPageRoute(
              builder: (_) => const ColourTilesConfigScreen()),
        );
        if (config != null && mounted) {
          setState(() => _missionSlots[index] = {
            'type':   'colour_tiles',
            'config': config.toJson(),
          });
        }
        break;
      default:
        break;
    }
  }

  void _openMissionConfig(int index) async {
    final slot = _missionSlots[index]!;
    final type = slot['type'] as String;

    if (type == 'colour_tiles') {
      final existing = ColourTilesConfig.fromJson(
          Map<String, dynamic>.from(slot['config'] as Map));
      final config = await Navigator.push<ColourTilesConfig>(
        context,
        MaterialPageRoute(
          builder: (_) => ColourTilesConfigScreen(initialConfig: existing),
        ),
      );
      if (config != null && mounted) {
        setState(() {
          _missionSlots[index] = {
            'type':   'colour_tiles',
            'config': config.toJson(),
          };
        });
      }
    }
  }
}
