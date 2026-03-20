import 'package:alarm/alarm.dart' as alarm_pkg;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/alarm.dart';
import '../alarm/alarm_manager.dart';
import '../missions/colour_tiles/colour_tiles_challenge_screen.dart';
import '../missions/colour_tiles/colour_tiles_model.dart';

class RingingScreen extends StatefulWidget {
  final Alarm                     alarm;
  final alarm_pkg.AlarmSettings   alarmSettings;

  const RingingScreen({
    super.key,
    required this.alarm,
    required this.alarmSettings,
  });

  @override
  State<RingingScreen> createState() => _RingingScreenState();
}

class _RingingScreenState extends State<RingingScreen>
    with SingleTickerProviderStateMixin {

  int  _missionIndex = 0;
  bool _dismissed    = false;

  // Snooze button press animation


  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  // ── Actions ───────────────────────────────────────────

  Future<void> _snooze() async {
    if (_dismissed) return;
    _dismissed = true;
    HapticFeedback.mediumImpact();
    await AlarmManager.snooze(widget.alarm);
    if (mounted) Navigator.of(context).pop();
  }

  void _startMission() {
    final missions = widget.alarm.missions;
    if (missions.isEmpty) { _dismissAlarm(); return; }
    _runMission(missions[_missionIndex]);
  }

  void _runMission(Map<String, dynamic> data) {
    final type = data['type'] as String? ?? '';
    if (type == 'colour_tiles') {
      final config = ColourTilesConfig.fromJson(
        Map<String, dynamic>.from(data['config'] as Map),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ColourTilesChallengeScreen(
            config:     config,
            onComplete: _missionDone,
          ),
        ),
      );
    }
  }

  void _missionDone() {
    if (Navigator.canPop(context)) Navigator.pop(context);
    _missionIndex++;
    final missions = widget.alarm.missions;
    if (_missionIndex < missions.length) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _runMission(missions[_missionIndex]);
      });
    } else {
      _dismissAlarm();
    }
  }

  Future<void> _dismissAlarm() async {
    if (_dismissed) return;
    _dismissed = true;
    await AlarmManager.stopRinging(widget.alarm);
    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  // ── Formatting ────────────────────────────────────────

  String get _timeString {
    final h = widget.alarm.time.hourOfPeriod == 0
        ? 12 : widget.alarm.time.hourOfPeriod;
    final m = widget.alarm.time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get _dateString {
    final n = DateTime.now();
    const days = [
      'Monday','Tuesday','Wednesday','Thursday',
      'Friday','Saturday','Sunday'
    ];
    const months = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December'
    ];
    return '${days[n.weekday - 1]}, ${n.day} ${months[n.month - 1]} ${n.year}';
  }

  // ── Build ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final missions      = widget.alarm.missions;
    final hasMission    = missions.isNotEmpty;
    final snoozeEnabled = widget.alarm.snoozeEnabled;
    final isAm          = widget.alarm.time.period == DayPeriod.am;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF080808),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [

                const SizedBox(height: 32),

                // ── Date ──────────────────────────────────
                Text(
                  _dateString,
                  style: const TextStyle(
                    color:         Color(0xFF888888),
                    fontSize:      15,
                    fontWeight:    FontWeight.w400,
                    letterSpacing: 0.2,
                  ),
                ),

                const SizedBox(height: 8),

                // ── Time ──────────────────────────────────
                Text(
                  _timeString,
                  style: const TextStyle(
                    color:         Color(0xFFF5F5F5),
                    fontSize:      78,
                    fontWeight:    FontWeight.w700,
                    letterSpacing: -2,
                    height:        1.0,
                  ),
                ),

                // ── AM / PM Badge ─────────────────────────
                Text(
                  isAm ? 'AM' : 'PM',
                  style: const TextStyle(
                    color:      Color(0xFF666666),
                    fontSize:   18,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const SizedBox(height: 20),

                // ── Label ─────────────────────────────────
                if (widget.alarm.label.isNotEmpty)
                  Text(
                    widget.alarm.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color:      Color(0xFFCCCCCC),
                      fontSize:   19,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                // ── Memo ──────────────────────────────────
                if (widget.alarm.memo?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      widget.alarm.memo!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color:    Color(0xFF666666),
                        fontSize: 14,
                        height:   1.5,
                      ),
                    ),
                  ),
                ],

                // ── Mission Indicator ─────────────────────
                if (hasMission) ...[
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width:  8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFD600),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${missions.length} mission${missions.length > 1 ? 's' : ''} • ${_getMissionName(missions[0])}',
                        style: const TextStyle(
                          color:      Color(0xFF888888),
                          fontSize:   12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],

                const Spacer(),

                // ── Start Mission / Dismiss button ────────
                SizedBox(
                  width:  double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _startMission,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD600),
                      foregroundColor: Colors.black,
                      elevation:       0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                    ),
                    child: Text(
                      hasMission ? 'Start Mission' : 'Dismiss',
                      style: const TextStyle(
                        fontSize:      17,
                        fontWeight:    FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ── Snooze Button (Professional) ──────────
                if (snoozeEnabled) _SnoozeButton(onSnooze: _snooze),

                const SizedBox(height: 36),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getMissionName(Map<String, dynamic> mission) {
    final type = mission['type'] as String? ?? '';
    switch (type) {
      case 'colour_tiles': return 'Colour Tiles';
      case 'math':         return 'Math';
      case 'shake':        return 'Shake';
      default:             return 'Challenge';
    }
  }
}

// ─────────────────────────────────────────────────────────
// Professional Snooze Button
// Two-part row: moon icon pill + "5 min" label + divider + "Snooze" text.
// Uses GestureDetector for a custom press-down scale animation.
// ─────────────────────────────────────────────────────────

class _SnoozeButton extends StatefulWidget {
  final VoidCallback onSnooze;
  const _SnoozeButton({required this.onSnooze});

  @override
  State<_SnoozeButton> createState() => _SnoozeButtonState();
}

class _SnoozeButtonState extends State<_SnoozeButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 160),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _ctrl.forward();
  void _onTapUp(_)   { _ctrl.reverse(); widget.onSnooze(); }
  void _onTapCancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   _onTapDown,
      onTapUp:     _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          height:     54,
          decoration: BoxDecoration(
            color:        const Color(0xFF131313),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: const Color(0xFF2A2A2A),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              // ── Moon icon in a small pill ──────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color:        const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.bedtime_rounded,
                      color: Color(0xFF666666),
                      size:  14,
                    ),
                    SizedBox(width: 5),
                    Text(
                      '5 min',
                      style: TextStyle(
                        color:      Color(0xFF666666),
                        fontSize:   12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // ── Vertical divider ───────────────────────
              Container(
                width:  1,
                height: 20,
                color:  const Color(0xFF252525),
              ),

              const SizedBox(width: 12),

              // ── "Snooze" label ─────────────────────────
              const Text(
                'Snooze',
                style: TextStyle(
                  color:         Color(0xFF888888),
                  fontSize:      15,
                  fontWeight:    FontWeight.w500,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}