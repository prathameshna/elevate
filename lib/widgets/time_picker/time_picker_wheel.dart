import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TimePickerWheel extends StatefulWidget {
  final TimeOfDay initialTime;
  final ValueChanged<TimeOfDay> onTimeChanged;

  const TimePickerWheel({
    super.key,
    required this.initialTime,
    required this.onTimeChanged,
  });

  @override
  State<TimePickerWheel> createState() => _TimePickerWheelState();
}

class _TimePickerWheelState extends State<TimePickerWheel> {

  // ── Looping constants ──────────────────────────────────────
  static const int _hourLoopCount   = 12 * 500;  // 6,000
  static const int _minuteLoopCount = 60 * 500;  // 30,000
  static const int _hourMiddle      = 12 * 250;  // 3,000
  static const int _minuteMiddle    = 60 * 250;  // 15,000

  // ── Controllers ───────────────────────────────────────────
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;
  late FixedExtentScrollController _amPmController;

  // ── State ─────────────────────────────────────────────────
  late int  _selectedHour;   // 1–12
  late int  _selectedMinute; // 0–59
  late bool _isAM;

  // ── Modulo helpers ────────────────────────────────────────

  /// Converts a large looping index → real hour value (1–12)
  int _hourFromIndex(int index) {
    final mod = index % 12;
    return mod == 0 ? 12 : mod; // 0 mod edge case → show 12
  }

  /// Converts a large looping index → real minute value (0–59)
  int _minuteFromIndex(int index) => index % 60;

  String _formatHour(int index)   =>
      _hourFromIndex(index).toString().padLeft(2, '0');

  String _formatMinute(int index) =>
      _minuteFromIndex(index).toString().padLeft(2, '0');

  // ── Init ──────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    final h = widget.initialTime.hour;
    _isAM         = h < 12;
    _selectedHour   = h % 12 == 0 ? 12 : h % 12;
    _selectedMinute = widget.initialTime.minute;

    // Start in the MIDDLE of each large list + offset to real value
    _hourController = FixedExtentScrollController(
      initialItem: _hourMiddle + (_selectedHour % 12),
    );
    _minuteController = FixedExtentScrollController(
      initialItem: _minuteMiddle + _selectedMinute,
    );
    _amPmController = FixedExtentScrollController(
      initialItem: _isAM ? 0 : 1,
    );
  }

  @override
  void didUpdateWidget(covariant TimePickerWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTime != widget.initialTime) {
      final h = widget.initialTime.hour;
      setState(() {
        _isAM           = h < 12;
        _selectedHour   = h % 12 == 0 ? 12 : h % 12;
        _selectedMinute = widget.initialTime.minute;
      });

      // Jump or animate to new time (Animate is smoother for UX)
      _hourController.animateToItem(
        _hourMiddle + (_selectedHour % 12),
        duration: const Duration(milliseconds: 400),
        curve:    Curves.easeOutCubic,
      );
      _minuteController.animateToItem(
        _minuteMiddle + _selectedMinute,
        duration: const Duration(milliseconds: 400),
        curve:    Curves.easeOutCubic,
      );
      _amPmController.animateToItem(
        _isAM ? 0 : 1,
        duration: const Duration(milliseconds: 400),
        curve:    Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    _amPmController.dispose();
    super.dispose();
  }

  // ── Notify parent with correct 24hr time ──────────────────

  void _notifyParent() {
    final hour24 = _isAM
        ? (_selectedHour == 12 ? 0  : _selectedHour)
        : (_selectedHour == 12 ? 12 : _selectedHour + 12);
    widget.onTimeChanged(
      TimeOfDay(hour: hour24, minute: _selectedMinute),
    );
  }

  // ── UI Helpers ────────────────────────────────────────────

  Widget _selectionHighlight(double totalWidth) {
    return IgnorePointer(
      child: Center(
        child: Container(
          width: totalWidth,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFF1A2E2C),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF14B8A6).withValues(alpha: 0.45),
              width: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _fadeOverlay() {
    return IgnorePointer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1A1A),
              Colors.transparent,
              Colors.transparent,
              Color(0xFF1A1A1A),
            ],
            stops: [0.0, 0.28, 0.72, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _colon() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        ':',
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w300,
          color: const Color(0xFFF5F5F5).withValues(alpha: 0.45),
          height: 1,
        ),
      ),
    );
  }

  // ── Core wheel builder ────────────────────────────────────

  Widget _buildWheel({
    required FixedExtentScrollController controller,
    required int itemCount,
    required String Function(int) labelBuilder,
    required bool Function(int) isSelectedCheck, // value-based, not index-based
    required ValueChanged<int> onChanged,
    double width = 76,
    bool isAmPm = false,
  }) {
    return SizedBox(
      width: width,
      height: 200,
      child: Stack(
        children: [
          ListWheelScrollView.useDelegate(
            controller: controller,
            itemExtent: 46,
            diameterRatio: 2.2,
            perspective: 0.002,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: (index) {
              HapticFeedback.selectionClick();
              onChanged(index);
            },
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: itemCount,
              builder: (context, index) {
                final isSelected = isSelectedCheck(index);
                return Center(
                  child: Text(
                    labelBuilder(index),
                    style: TextStyle(
                      fontSize: isSelected
                          ? (isAmPm ? 18 : 34)
                          : (isAmPm ? 14 : 28),
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w300,
                      color: isSelected
                          ? const Color(0xFFF5F5F5)
                          : const Color(0xFFF5F5F5).withValues(alpha: 0.28),
                      fontFeatures: isAmPm
                          ? null
                          : const [FontFeature.tabularFigures()],
                      letterSpacing: -0.5,
                    ),
                  ),
                );
              },
            ),
          ),
          // Fade overlay — must be LAST in Stack so it renders on top
          _fadeOverlay(),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final hourWidth   = (constraints.maxWidth * 0.26).clamp(64.0, 88.0);
        final minuteWidth = (constraints.maxWidth * 0.26).clamp(64.0, 88.0);
        final amPmWidth   = (constraints.maxWidth * 0.18).clamp(44.0, 60.0);
        final highlightWidth = hourWidth + minuteWidth + amPmWidth + 48;

        return SizedBox(
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Teal selection card behind wheels
              _selectionHighlight(highlightWidth),

              // Wheels row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [

                  // ── Hour wheel (looping 1–12) ──
                  _buildWheel(
                    controller: _hourController,
                    itemCount: _hourLoopCount,
                    labelBuilder: _formatHour,
                    isSelectedCheck: (i) =>
                        _hourFromIndex(i) == _selectedHour,
                    onChanged: (i) {
                      setState(() => _selectedHour = _hourFromIndex(i));
                      _notifyParent();
                    },
                    width: hourWidth,
                  ),

                  _colon(),

                  // ── Minute wheel (looping 0–59) ──
                  _buildWheel(
                    controller: _minuteController,
                    itemCount: _minuteLoopCount,
                    labelBuilder: _formatMinute,
                    isSelectedCheck: (i) =>
                        _minuteFromIndex(i) == _selectedMinute,
                    onChanged: (i) {
                      setState(() => _selectedMinute = _minuteFromIndex(i));
                      _notifyParent();
                    },
                    width: minuteWidth,
                  ),

                  const SizedBox(width: 8),

                  // ── AM/PM wheel (no loop — only 2 items) ──
                  _buildWheel(
                    controller: _amPmController,
                    itemCount: 2,
                    labelBuilder: (i) => i == 0 ? 'a.m.' : 'p.m.',
                    isSelectedCheck: (i) => (_isAM ? 0 : 1) == i,
                    onChanged: (i) {
                      setState(() => _isAM = i == 0);
                      _notifyParent();
                    },
                    width: amPmWidth,
                    isAmPm: true,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
