import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/alarm.dart';
import 'alarm_toggle.dart';

class AlarmCard extends StatefulWidget {
  final Alarm alarm;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;
  final VoidCallback? onDelete;

  const AlarmCard({
    super.key,
    required this.alarm,
    required this.onTap,
    required this.onToggle,
    this.onDelete,
  });

  @override
  State<AlarmCard> createState() => _AlarmCardState();
}

class _AlarmCardState extends State<AlarmCard> {
  bool _isPressed = false;

  // ── Helpers ──────────────────────────────────────────────

  String _formatTime() {
    final h = widget.alarm.time.hour;
    final m = widget.alarm.time.minute;
    final hour = h % 12 == 0 ? 12 : h % 12;
    final minute = m.toString().padLeft(2, '0');
    final period = h < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String _timeUntilText() {
    final now = DateTime.now();
    var next = DateTime(
      now.year, now.month, now.day,
      widget.alarm.time.hour,
      widget.alarm.time.minute,
    );
    if (!next.isAfter(now)) {
      next = next.add(const Duration(days: 1));
    }
    final diff = next.difference(now);
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    if (hours > 0) {
      return 'Alarm in $hours hour${hours != 1 ? 's' : ''} '
          '${minutes.toString().padLeft(2, '0')} minutes';
    }
    return 'Alarm in $minutes minute${minutes != 1 ? 's' : ''}';
  }

  String _repeatLabel() {
    final days = widget.alarm.selectedDays;
    if (days.isEmpty) return 'One-time';
    if (days.length == 7) return 'Every day';
    if (days.length == 5 &&
        days.containsAll({1, 2, 3, 4, 5})) return 'Weekdays';
    if (days.length == 2 &&
        days.containsAll({0, 6})) return 'Weekends';
    const labels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final sorted = days.toList()..sort();
    return sorted.map((d) => labels[d]).join(', ');
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onLongPress: widget.onDelete,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        transform: Matrix4.identity()
          ..scale(_isPressed ? 0.97 : 1.0),
        transformAlignment: Alignment.center,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        decoration: BoxDecoration(
          color: _isPressed
              ? const Color(0xFF323232)
              : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isPressed
                ? const Color(0xFF14B8A6).withOpacity(0.35)
                : const Color(0xFF3A3A3A),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Left: time info ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // "Alarm in X hours Y minutes"
                  Text(
                    _timeUntilText(),
                    style: TextStyle(
                      color: widget.alarm.isEnabled
                          ? const Color(0xFFA0A0A0)
                          : const Color(0xFF606060),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // "9:19 PM"
                  Text(
                    _formatTime(),
                    style: TextStyle(
                      color: widget.alarm.isEnabled
                          ? const Color(0xFFF5F5F5)
                          : const Color(0xFF565656),
                      fontSize: 38,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1.0,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // "One-time" / "Weekdays" / days
                  Text(
                    _repeatLabel(),
                    style: TextStyle(
                      color: widget.alarm.isEnabled
                          ? const Color(0xFFA0A0A0)
                          : const Color(0xFF505050),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            // ── Right: toggle (isolated — does NOT trigger card tap) ──
            GestureDetector(
              onTap: () {}, // absorbs tap so card onTap doesn't fire
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: AlarmToggle(
                  value: widget.alarm.isEnabled,
                  onChanged: widget.onToggle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
