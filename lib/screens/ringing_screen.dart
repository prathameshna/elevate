import 'package:alarm/alarm.dart' as alarm_pkg;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/alarm.dart';
import '../alarm/alarm_manager.dart';
import '../missions/colour_tiles/colour_tiles_challenge_screen.dart';
import '../missions/colour_tiles/colour_tiles_model.dart';
import '../missions/memory/memory_challenge_screen.dart';
import '../missions/memory/memory_mission_model.dart';

class RingingScreen extends StatefulWidget {
  final Alarm alarm;
  final alarm_pkg.AlarmSettings alarmSettings;

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

  // ── Snooze ───────────────────────────────────────────────
  Future<void> _snooze() async {
    if (_dismissed) return;
    _dismissed = true;
    HapticFeedback.heavyImpact();
    await AlarmManager.snooze(widget.alarm);
    if (mounted) Navigator.of(context).pop();
  }

  // ── Dismiss ──────────────────────────────────────────────
  Future<void> _dismissAlarm() async {
    if (_dismissed) return;
    _dismissed = true;
    await AlarmManager.stopRinging(widget.alarm);
    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  // ── Start Mission ─────────────────────────────────────────
  void _startMission() {
    final missions = widget.alarm.missions;
    if (missions.isEmpty) {
      _dismissAlarm();
      return;
    }
    _runMission(missions[_missionIndex]);
  }

  void _runMission(Map<String, dynamic> data) {
    final type      = data['type'] as String? ?? '';
    final rawConfig = data['config'];

    if (rawConfig == null) {
      _dismissAlarm();
      return;
    }

    final configMap = Map<String, dynamic>.from(rawConfig as Map);

    if (type == 'colour_tiles') {
      final config = ColourTilesConfig(
        difficulty:    CTDifficultyX.fromKey(
            configMap['difficulty'] as String? ?? 'normal'),
        questionCount: configMap['questionCount'] as int? ?? 3,
      );
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => ColourTilesChallengeScreen(
          config:     config,
          onComplete: _missionDone,
        ),
      ));
    } else if (type == 'memory') {
      final config = MemoryMissionConfig.fromJson(configMap);
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => MemoryChallengeScreen(
          config:     config,
          onComplete: _missionDone,
        ),
      ));
    } else {
      _dismissAlarm();
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

  // ── Helpers ───────────────────────────────────────────────
  String get _timeString {
    final h = widget.alarm.time.hourOfPeriod == 0
        ? 12 : widget.alarm.time.hourOfPeriod;
    final m = widget.alarm.time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get _dateString {
    final n = DateTime.now();
    const days = ['Monday','Tuesday','Wednesday',
      'Thursday','Friday','Saturday','Sunday'];
    const months = ['January','February','March','April','May','June',
      'July','August','September','October','November','December'];
    return '${days[n.weekday - 1]}, ${n.day} ${months[n.month - 1]} ${n.year}';
  }

  String get _snoozeTimeString {
    final t = DateTime.now()
        .add(Duration(minutes: widget.alarm.snoozeMinutes));
    final h = t.hour > 12 ? t.hour - 12 : (t.hour == 0 ? 12 : t.hour);
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final hasMission    = widget.alarm.missions.isNotEmpty;
    final snoozeEnabled = widget.alarm.snoozeEnabled;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF0E0E0E),
        body: SafeArea(
          child: Column(
            children: [

              const Spacer(flex: 2),

              // ── Time ──────────────────────────────────────
              Text(
                _timeString,
                style: const TextStyle(
                  color:         Color(0xFFF0F0F0),
                  fontSize:      72,
                  fontWeight:    FontWeight.w300,
                  letterSpacing: -2,
                  height:        1.0,
                ),
              ),

              const SizedBox(height: 6),

              // ── Date / Label ───────────────────────────────
              Text(
                widget.alarm.label.isNotEmpty
                    ? widget.alarm.label
                    : _dateString,
                style: const TextStyle(
                  color:         Color(0xFF555555),
                  fontSize:      12,
                  letterSpacing: 3,
                  fontWeight:    FontWeight.w400,
                ),
              ),

              const Spacer(flex: 3),

              // ── Snooze slider ──────────────────────────────
              if (snoozeEnabled)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Column(
                    children: [
                      const Text(
                        'SLIDE TO SNOOZE',
                        style: TextStyle(
                          color:         Color(0xFF444444),
                          fontSize:      11,
                          letterSpacing: 2.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _SnoozeSlider(
                        snoozeMinutes: widget.alarm.snoozeMinutes,
                        snoozeTime:    _snoozeTimeString,
                        onSnooze:      _snooze,
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // ── Start Mission OR Dismiss button ────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: SizedBox(
                  width:  double.infinity,
                  height: 52,
                  child: hasMission
                  // Has mission → yellow Start Mission button
                      ? ElevatedButton(
                    onPressed: _startMission,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD600),
                      foregroundColor: Colors.black,
                      elevation:       0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: const Text(
                      'Start Mission',
                      style: TextStyle(
                        fontSize:   15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                  // No mission → outlined Dismiss button
                      : OutlinedButton(
                    onPressed: _dismissAlarm,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF888888),
                      side: const BorderSide(
                        color: Color(0xFF2A2A2A),
                        width: 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: const Text(
                      'Dismiss',
                      style: TextStyle(
                        fontSize:      15,
                        fontWeight:    FontWeight.w500,
                        letterSpacing: 1,
                        color:         Color(0xFF888888),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Bottom padding ─────────────────────────────
              SizedBox(
                height: MediaQuery.of(context).padding.bottom + 24,
              ),

            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Snooze Slider
// ─────────────────────────────────────────────────────────

class _SnoozeSlider extends StatefulWidget {
  final int          snoozeMinutes;
  final String       snoozeTime;
  final VoidCallback onSnooze;

  const _SnoozeSlider({
    required this.snoozeMinutes,
    required this.snoozeTime,
    required this.onSnooze,
  });

  @override
  State<_SnoozeSlider> createState() => _SnoozeSliderState();
}

class _SnoozeSliderState extends State<_SnoozeSlider>
    with SingleTickerProviderStateMixin {

  double _dragX    = 0;
  bool   _snoozed  = false;
  bool   _dragging = false;

  late AnimationController _rippleCtrl;
  late Animation<double>   _rippleScale;
  late Animation<double>   _rippleOpacity;

  static const double _height    = 64;
  static const double _thumbSize = 56;
  static const double _padding   = 4;

  @override
  void initState() {
    super.initState();
    _rippleCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _rippleScale = Tween<double>(begin: 1.0, end: 2.2).animate(
      CurvedAnimation(parent: _rippleCtrl, curve: Curves.easeOut),
    );
    _rippleOpacity = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _rippleCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _rippleCtrl.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails d, double maxX) {
    if (_snoozed) return;
    setState(() {
      _dragX    = (_dragX + d.delta.dx).clamp(0, maxX);
      _dragging = true;
    });
  }

  void _onDragEnd(DragEndDetails d, double maxX) {
    if (_snoozed) return;
    if (_dragX >= maxX * 0.95) {
      setState(() {
        _snoozed = true;
        _dragX   = maxX;
      });
      _rippleCtrl.stop();
      HapticFeedback.heavyImpact();
      Future.delayed(
        const Duration(milliseconds: 600),
        widget.onSnooze,
      );
    } else {
      setState(() {
        _dragX    = 0;
        _dragging = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      final trackWidth = constraints.maxWidth;
      final maxX       = trackWidth - _thumbSize - _padding * 2;
      final progress   = (_dragX / maxX).clamp(0.0, 1.0);

      return Container(
        height: _height,
        decoration: BoxDecoration(
          color:        const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(32),
          border:       Border.all(
            color: const Color(0xFF2A2A2A),
            width: 0.5,
          ),
        ),
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [

            // Fill bar
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedContainer(
                    duration: Duration.zero,
                    width:  trackWidth * progress,
                    height: _height,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF1D9E75).withOpacity(
                              _snoozed ? 0.22 : 0.18),
                          const Color(0xFF1D9E75).withOpacity(0.06),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Ripple ring
            if (!_snoozed && !_dragging)
              Positioned(
                left: _padding,
                child: AnimatedBuilder(
                  animation: _rippleCtrl,
                  builder: (_, __) => Transform.scale(
                    scale: _rippleScale.value,
                    child: Opacity(
                      opacity: _rippleOpacity.value,
                      child: Container(
                        width:  _thumbSize,
                        height: _thumbSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF1D9E75)
                                .withOpacity(0.4),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Center label
            if (!_snoozed && progress < 0.15)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Snooze',
                      style: TextStyle(
                        color:         Color(0xFF888888),
                        fontSize:      12,
                        fontWeight:    FontWeight.w500,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      '${widget.snoozeMinutes} min',
                      style: const TextStyle(
                        color:         Color(0xFF555555),
                        fontSize:      10,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),

            // Snoozed message
            if (_snoozed)
              Center(
                child: Text(
                  'Snoozed · ${widget.snoozeMinutes} min',
                  style: const TextStyle(
                    color:         Color(0xFF1D9E75),
                    fontSize:      11,
                    fontWeight:    FontWeight.w500,
                    letterSpacing: 1.5,
                  ),
                ),
              ),

            // Draggable thumb
            Positioned(
              left: _padding + _dragX,
              child: GestureDetector(
                onHorizontalDragUpdate: (d) => _onDragUpdate(d, maxX),
                onHorizontalDragEnd:    (d) => _onDragEnd(d, maxX),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 50),
                  width:  _thumbSize,
                  height: _thumbSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _snoozed
                        ? const Color(0xFF1D9E75)
                        : const Color(0xFF1E1E1E),
                    border: Border.all(
                      color: _snoozed
                          ? const Color(0xFF1D9E75)
                          : const Color(0xFF333333),
                      width: 0.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:      Colors.black.withOpacity(0.4),
                        blurRadius: 12,
                        offset:     const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _snoozed
                        ? const Icon(
                      Icons.check_rounded,
                      key:   ValueKey('check'),
                      color: Colors.white,
                      size:  20,
                    )
                        : const Icon(
                      Icons.bedtime_rounded,
                      key:   ValueKey('moon'),
                      color: Color(0xFF888888),
                      size:  20,
                    ),
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