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
  int _missionIndex = 0;
  bool _dismissed = false;
  late AnimationController _swipeCtrl;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _swipeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    print('🔔 RingingScreen initialized');
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _swipeCtrl.dispose();
    super.dispose();
  }

  // ── Actions ───────────────────────────────────────────

  Future<void> _snooze() async {
    if (_dismissed) return;
    _dismissed = true;
    print('💤 Snoozing alarm: ${widget.alarm.id}');
    HapticFeedback.mediumImpact();
    await AlarmManager.snooze(widget.alarm);
    if (mounted) {
      print('🔄 Snooze scheduled, popping ringing screen');
      Navigator.of(context).pop();
    }
  }

  void _startMission() {
    final missions = widget.alarm.missions;
    if (missions.isEmpty) {
      _dismissAlarm();
      return;
    }
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
            config: config,
            onComplete: _missionDone,
          ),
        ),
      );
    } else if (type == 'memory') {
      final config = MemoryMissionConfig.fromJson(
        Map<String, dynamic>.from(data['config'] as Map),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MemoryChallengeScreen(
            config: config,
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
    print('❌ Dismissing alarm: ${widget.alarm.id}');
    await AlarmManager.stopRinging(widget.alarm);
    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  // ── Formatting ────────────────────────────────────────

  String get _timeString {
    final h = widget.alarm.time.hourOfPeriod == 0
        ? 12
        : widget.alarm.time.hourOfPeriod;
    final m = widget.alarm.time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get _dateString {
    final n = DateTime.now();
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${days[n.weekday - 1]}, ${n.day} ${months[n.month - 1]} ${n.year}';
  }

  // ── Build ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final snoozeEnabled = widget.alarm.snoozeEnabled;
    final snoozeMinutes = widget.alarm.snoozeMinutes;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Date ──────────────────────────────────
                Text(
                  _dateString,
                  style: const TextStyle(
                    color: Color(0xFF888888),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.3,
                  ),
                ),

                const SizedBox(height: 24),

                // ── Time (Large & Bold) ───────────────────
                Text(
                  _timeString,
                  style: const TextStyle(
                    color: Color(0xFFFFFAF0),
                    fontSize: 88,
                    fontWeight: FontWeight.w700,
                    height: 1.0,
                    letterSpacing: -2,
                  ),
                ),

                const SizedBox(height: 32),

                // ── Alarm Label ───────────────────────────
                if (widget.alarm.label.isNotEmpty)
                  Text(
                    widget.alarm.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFCCCCCC),
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.2,
                    ),
                  ),

                const Spacer(),

                // ── Start Mission Button ───────────────────
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _startMission,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD600),
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: const Text(
                      'Start Mission',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Swipe to Snooze (ONLY if snoozeEnabled is TRUE) ───
                if (snoozeEnabled)
                  _SwipeToSnoozeWidget(
                    onSnooze: _snooze,
                    snoozeMinutes: snoozeMinutes,
                  ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Swipe to Snooze Widget - FIXED: Requires full swipe
// ─────────────────────────────────────────────────────────

class _SwipeToSnoozeWidget extends StatefulWidget {
  final VoidCallback onSnooze;
  final int snoozeMinutes;

  const _SwipeToSnoozeWidget({
    required this.onSnooze,
    required this.snoozeMinutes,
  });

  @override
  State<_SwipeToSnoozeWidget> createState() => _SwipeToSnoozeWidgetState();
}

class _SwipeToSnoozeWidgetState extends State<_SwipeToSnoozeWidget>
    with SingleTickerProviderStateMixin {
  double _dragOffset = 0;
  bool _snoozed = false;
  late AnimationController _animCtrl;
  late Animation<double> _slideAnimation;

  // ✅ NEW: Constants for threshold
  static const double maxDragDistance = 250; // Total drag distance needed
  static const double dragThreshold = 0.95; // 95% = must reach 95% to trigger

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _resetSwipe() {
    _slideAnimation = Tween<double>(begin: _dragOffset, end: 0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic),
    );
    _animCtrl.forward(from: 0).then((_) {
      if (mounted) {
        setState(() {
          _dragOffset = 0;
        });
      }
    });
  }

  void _completeSwipe() {
    _slideAnimation = Tween<double>(begin: _dragOffset, end: maxDragDistance)
        .animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic),
    );
    _animCtrl.forward(from: 0).then((_) {
      if (mounted) {
        _snoozed = true;
        HapticFeedback.heavyImpact();
        widget.onSnooze();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Calculate progress percentage
    final progress = (_dragOffset / maxDragDistance).clamp(0.0, 1.0);
    final isDragComplete = progress >= dragThreshold;

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        if (_snoozed) return;

        setState(() {
          _dragOffset = (_dragOffset + details.delta.dx).clamp(0, maxDragDistance);
        });
      },
      onHorizontalDragEnd: (details) {
        if (_snoozed) return;

        final progress = (_dragOffset / maxDragDistance).clamp(0.0, 1.0);

        // ✅ FIXED: Require 95% completion
        if (progress >= dragThreshold) {
          print('✅ Swipe completed: $progress (${(progress * 100).toStringAsFixed(1)}%)');
          _completeSwipe();
        } else {
          print('❌ Swipe incomplete: $progress (${(progress * 100).toStringAsFixed(1)}%) - needs ${(dragThreshold * 100).toStringAsFixed(0)}%');
          _resetSwipe();
        }
      },
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(27),
          border: Border.all(
            color: const Color(0xFF2A2A2A),
            width: 1,
          ),
        ),
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            // ── Background Progress Bar ───────────────────
            AnimatedBuilder(
              animation: _slideAnimation,
              builder: (context, child) {
                final currentProgress = _animCtrl.isAnimating
                    ? _slideAnimation.value / maxDragDistance
                    : progress;

                return Container(
                  width: (54 * currentProgress).clamp(0, 54),
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFF14B8A6).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(27),
                  ),
                );
              },
            ),

            // ── Draggable Icon (Left side) ────────────────
            AnimatedBuilder(
              animation: _slideAnimation,
              builder: (context, child) {
                final currentOffset = _animCtrl.isAnimating
                    ? _slideAnimation.value
                    : _dragOffset;

                return Positioned(
                  left: 12 + (currentOffset * 0.8).clamp(0, 190),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.bedtime_rounded,
                      color: isDragComplete
                          ? const Color(0xFF14B8A6)
                          : const Color(0xFF888888),
                      size: 20,
                    ),
                  ),
                );
              },
            ),

            // ── Swipe Text with Duration and Progress ─────
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'SWIPE TO SNOOZE (${widget.snoozeMinutes} min)',
                    style: TextStyle(
                      color: isDragComplete
                          ? const Color(0xFF14B8A6)
                          : const Color(0xFF606060),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: isDragComplete
                          ? const Color(0xFF14B8A6)
                          : const Color(0xFF505050),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}