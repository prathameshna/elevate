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

  bool get _hasMission => widget.alarm.missions.isNotEmpty;

  // ── Build ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
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
  
                // ── Spacer: small gap from top ─────────────
                const SizedBox(height: 48),
  
                // ── Date ───────────────────────────────────
                // Small, grey, centered — matches Image 2
                Text(
                  _dateString,
                  style: const TextStyle(
                    color:      Color(0xFF888888),
                    fontSize:   15,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.2,
                  ),
                ),
  
                const SizedBox(height: 8),
  
                // ── Time ───────────────────────────────────
                // Smaller than current — weight 700, NOT w900
                // Image 2 shows "7:24" style — not full screen giant
                Text(
                  _timeString,
                  style: const TextStyle(
                    color:       Color(0xFFF5F5F5),
                    fontSize:    80,     // NOT 100+ like current
                    fontWeight:  FontWeight.w900,
                    letterSpacing: -2,
                    height:      1.0,
                  ),
                ),
  
                const SizedBox(height: 32),
  
                // ── Alarm label ─────────────────────────────
                // "Weekends alarm" — visible in Image 2
                if (widget.alarm.label.isNotEmpty)
                  Text(
                    widget.alarm.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color:      Color(0xFFCCCCCC),
                      fontSize:   20, // Slightly larger
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.2,
                    ),
                  ),
  
                // ── Memo (if set) ───────────────────────────
                if (widget.alarm.memo?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
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
  
                // ── Push buttons to bottom ──────────────────
                const Spacer(),
  
                // ── Mission progress (if multiple) ──────────
                if (widget.alarm.missions.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      'Mission ${_missionIndex + 1} '
                      'of ${widget.alarm.missions.length}',
                      style: const TextStyle(
                        color:    Color(0xFF555555),
                        fontSize: 12,
                      ),
                    ),
                  ),
  
                // ── Start Mission yellow pill ────────────────
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
                      _hasMission ? 'Start Mission' : 'Dismiss',
                      style: const TextStyle(
                        fontSize:   17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
  
                const SizedBox(height: 14),
  
                // ── Swipe to Snooze dark pill ────────────────
                // Only show if snooze is enabled
                if (widget.alarm.snoozeEnabled == true)
                  _SwipeToSnooze(onSnooze: _snooze),
  
                // ── Bottom safe area padding ─────────────────
                SizedBox(
                  height: MediaQuery.of(context).padding.bottom + 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Swipe to Snooze ───────────────────────────────────────

class _SwipeToSnooze extends StatefulWidget {
  final VoidCallback onSnooze;
  const _SwipeToSnooze({required this.onSnooze});

  @override
  State<_SwipeToSnooze> createState() => _SwipeToSnoozeState();
}

class _SwipeToSnoozeState extends State<_SwipeToSnooze> {
  double _dx        = 0;
  bool   _triggered = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, c) {
      final maxDx = c.maxWidth - 52;

      return Container(
        height: 56,
        decoration: BoxDecoration(
          color:        const Color(0xFF1C1C1C),
          borderRadius: BorderRadius.circular(32),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [

            // "SWIPE TO SNOOZE" label — fades as thumb moves
            Opacity(
              opacity: (1.0 - (_dx / maxDx) * 2.5).clamp(0.0, 1.0),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bedtime_rounded,
                      color: Color(0xFF888888), size: 15),
                  SizedBox(width: 8),
                  Text(
                    'SWIPE TO SNOOZE',
                    style: TextStyle(
                      color:       Color(0xFF888888),
                      fontSize:    13,
                      fontWeight:  FontWeight.w600,
                      letterSpacing: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // Moon icon thumb — draggable
            Positioned(
              left: 5 + _dx,
              child: GestureDetector(
                onHorizontalDragUpdate: (d) {
                  if (_triggered) return;
                  setState(() {
                    _dx = (_dx + d.delta.dx).clamp(0.0, maxDx);
                  });
                  if (_dx / maxDx >= 0.65) {
                    _triggered = true;
                    HapticFeedback.heavyImpact();
                    widget.onSnooze();
                  }
                },
                onHorizontalDragEnd: (_) {
                  if (!_triggered) setState(() => _dx = 0);
                },
                child: Container(
                  width:  46,
                  height: 46,
                  decoration: BoxDecoration(
                    color:  const Color(0xFF2A2A2A),
                    shape:  BoxShape.circle,
                    border: Border.all(color: const Color(0xFF383838)),
                  ),
                  child: const Icon(
                    Icons.bedtime_rounded,
                    color: Color(0xFFAAAAAA),
                    size:  20,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
