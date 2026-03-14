import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/alarm.dart';
import '../alarm/alarm_service.dart';
import '../alarm/alarm_scheduler.dart';
import '../missions/colour_tiles/colour_tiles_challenge_screen.dart';
import '../missions/colour_tiles/colour_tiles_model.dart';
// Add if memory is used

class RingingScreen extends StatefulWidget {
  final Alarm alarm;
  const RingingScreen({super.key, required this.alarm});

  @override
  State<RingingScreen> createState() => _RingingScreenState();
}

class _RingingScreenState extends State<RingingScreen>
    with TickerProviderStateMixin {

  late AnimationController _pulseCtrl;
  late Animation<double>   _pulseAnim;

  bool _snoozed = false;
  int _missionIndex = 0;

  @override
  void initState() {
    super.initState();

    // Keep screen on
    WakelockPlus.enable();

    // Pulse animation for time display
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.03)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Snooze ─────────────────────────────────────────────
  Future<void> _snooze() async {
    if (_snoozed) return;
    
    // Max snooze safety
    const maxSnoozes = 3;
    if (widget.alarm.snoozeCount >= maxSnoozes) {
      // Force mission — no more snoozing
      _startMission();
      return;
    }
    
    setState(() => _snoozed = true);
    HapticFeedback.mediumImpact();

    await AlarmService.stopRinging();
    await AlarmScheduler.scheduleSnooze(
      widget.alarm.copyWith(snoozeCount: widget.alarm.snoozeCount + 1),
    );

    if (mounted) Navigator.of(context).pop();
  }

  // ── Start mission ───────────────────────────────────────
  void _startMission() {
    HapticFeedback.heavyImpact();
    final missions = widget.alarm.missions;

    if (missions.isEmpty) {
      _dismissAlarm(); // no mission — dismiss directly
      return;
    }

    _runMission(missions[_missionIndex]);
  }

  void _runMission(Map<String, dynamic> missionData) {
    final type = missionData['type'] as String;

    if (type == 'colour_tiles') {
      final config = ColourTilesConfig.fromJson(
        Map<String, dynamic>.from(missionData['config'] as Map),
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
    } else {
      // Fallback dismiss if mission not handled
      _dismissAlarm();
    }
  }

  void _missionDone() {
    // Close current mission screen
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }

    _missionIndex++;
    final missions = widget.alarm.missions;

    if (_missionIndex < missions.length) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _runMission(missions[_missionIndex]);
      });
    } else {
      // All missions done
      _dismissAlarm();
    }
  }

  // ── Dismiss ─────────────────────────────────────────────
  Future<void> _dismissAlarm() async {
    await AlarmService.stopRinging();
    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  // ── Time formatting ─────────────────────────────────────
  String get _timeString {
    final h = widget.alarm.time.hourOfPeriod == 0
        ? 12
        : widget.alarm.time.hourOfPeriod;
    final m = widget.alarm.time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get _periodString =>
      widget.alarm.time.period == DayPeriod.am ? 'AM' : 'PM';

  String get _dateString {
    final now  = DateTime.now();
    const days = ['Monday', 'Tuesday', 'Wednesday',
                  'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['January', 'February', 'March', 'April', 'May',
                    'June', 'July', 'August', 'September', 'October',
                    'November', 'December'];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // cannot go back — must solve mission
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // ── Date ──────────────────────────────────
                Text(
                  _dateString,
                  style: const TextStyle(
                    color:      Color(0xFF888888),
                    fontSize:   15,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 12),

                // ── Time ──────────────────────────────────
                ScaleTransition(
                  scale: _pulseAnim,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        _timeString,
                        style: const TextStyle(
                          color:       Color(0xFFF5F5F5),
                          fontSize:    88,
                          fontWeight:  FontWeight.w300,
                          letterSpacing: -4,
                          height:      1.0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _periodString,
                        style: const TextStyle(
                          color:      Color(0xFF888888),
                          fontSize:   22,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Label ─────────────────────────────────
                if (widget.alarm.label.isNotEmpty == true)
                  Text(
                    widget.alarm.label,
                    style: const TextStyle(
                      color:      Color(0xFFBBBBBB),
                      fontSize:   18,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                // ── Memo ──────────────────────────────────
                if (widget.alarm.memo?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.alarm.memo!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color:    Color(0xFF606060),
                      fontSize: 14,
                      height:   1.4,
                    ),
                  ),
                ],

                // ── Mission badge ─────────────────────────
                if (widget.alarm.missions.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  if (widget.alarm.missions.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Mission ${_missionIndex + 1} of ${widget.alarm.missions.length}',
                        style: const TextStyle(
                          color:    Color(0xFF606060),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD600).withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFFFFD600).withValues(alpha: 0.25)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('🧩', style: TextStyle(fontSize: 13)),
                        SizedBox(width: 6),
                        Text(
                          'Mission required to dismiss',
                          style: TextStyle(
                            color:      Color(0xFFFFD600),
                            fontSize:   12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const Spacer(flex: 3),

                // ── Start Mission button ───────────────────
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: _startMission,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD600),
                      foregroundColor: Colors.black,
                      elevation:       0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    child: Text(
                      widget.alarm.missions.isNotEmpty
                          ? 'Start Mission'
                          : 'Dismiss',
                      style: const TextStyle(
                        fontSize:   17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Swipe to Snooze ───────────────────────
                if (widget.alarm.snoozeEnabled && widget.alarm.snoozeCount < 3)
                  _SwipeToSnooze(onSnooze: _snooze),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Swipe to Snooze widget ────────────────────────────────

class _SwipeToSnooze extends StatefulWidget {
  final VoidCallback onSnooze;
  const _SwipeToSnooze({required this.onSnooze});

  @override
  State<_SwipeToSnooze> createState() => _SwipeToSnoozeState();
}

class _SwipeToSnoozeState extends State<_SwipeToSnooze> {
  double _dragX    = 0;
  bool   _triggered = false;

  static const double _height      = 56.0;
  static const double _thumbSize   = 46.0;
  static const double _triggerFrac = 0.65; // trigger at 65% of width

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final maxDrag = constraints.maxWidth - _thumbSize - 16;
      final progress = (_dragX / maxDrag).clamp(0.0, 1.0);

      return Container(
        height: _height,
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1C),
          borderRadius: BorderRadius.circular(_height / 2),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            // Label text
            Center(
              child: AnimatedOpacity(
                opacity: 1.0 - progress * 2,
                duration: Duration.zero,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bedtime_rounded,
                        color: Color(0xFF606060), size: 16),
                    SizedBox(width: 8),
                    Text(
                      'SWIPE TO SNOOZE',
                      style: TextStyle(
                        color:       Color(0xFF606060),
                        fontSize:    12,
                        fontWeight:  FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Draggable thumb
            Positioned(
              left: 5 + _dragX,
              child: GestureDetector(
                onHorizontalDragUpdate: (details) {
                  if (_triggered) return;
                  setState(() {
                    _dragX = (_dragX + details.delta.dx)
                        .clamp(0.0, maxDrag);
                  });

                  if (_dragX / maxDrag >= _triggerFrac) {
                    _triggered = true;
                    HapticFeedback.heavyImpact();
                    widget.onSnooze();
                  }
                },
                onHorizontalDragEnd: (_) {
                  if (!_triggered) {
                    setState(() => _dragX = 0);
                  }
                },
                child: Container(
                  width:  _thumbSize,
                  height: _thumbSize,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E2E2E),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF3A3A3A)),
                  ),
                  child: const Icon(
                    Icons.bedtime_rounded,
                    color: Color(0xFF888888),
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
