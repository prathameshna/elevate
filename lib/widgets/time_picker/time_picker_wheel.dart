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
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;
  late FixedExtentScrollController _amPmController;

  late int _selectedHour;   // 1–12
  late int _selectedMinute; // 0–59
  late bool _isAM;

  @override
  void initState() {
    super.initState();
    final h = widget.initialTime.hour;
    _isAM = h < 12;
    _selectedHour = h % 12 == 0 ? 12 : h % 12;
    _selectedMinute = widget.initialTime.minute;

    _hourController = FixedExtentScrollController(
      initialItem: _selectedHour - 1,
    );
    _minuteController = FixedExtentScrollController(
      initialItem: _selectedMinute,
    );
    _amPmController = FixedExtentScrollController(
      initialItem: _isAM ? 0 : 1,
    );
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    _amPmController.dispose();
    super.dispose();
  }

  void _notifyParent() {
    final hour24 = _isAM
        ? (_selectedHour == 12 ? 0 : _selectedHour)
        : (_selectedHour == 12 ? 12 : _selectedHour + 12);
    widget.onTimeChanged(
      TimeOfDay(hour: hour24, minute: _selectedMinute),
    );
  }

  // ── Selection highlight overlay ──────────────────────────

  Widget _selectionHighlight(double width) {
    return IgnorePointer(
      child: Center(
        child: Container(
          width: width,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFF1A2E2C),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF14B8A6).withOpacity(0.45),
              width: 1,
            ),
          ),
        ),
      ),
    );
  }

  // ── Top/bottom fade overlay ───────────────────────────────

  Widget _fadeOverlay() {
    return IgnorePointer(
      child: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1A1A1A),
            Colors.transparent,
            Colors.transparent,
            Color(0xFF1A1A1A),
          ],
          stops: [0.0, 0.28, 0.72, 1.0],
        ).createShader(bounds),
        blendMode: BlendMode.dstIn,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1A1A1A), Colors.transparent,
                       Colors.transparent, Color(0xFF1A1A1A)],
              stops: [0.0, 0.28, 0.72, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  // ── Single wheel column ───────────────────────────────────

  Widget _buildWheel({
    required FixedExtentScrollController controller,
    required int itemCount,
    required String Function(int) labelBuilder,
    required int selectedIndex,
    required ValueChanged<int> onChanged,
    double width = 76,
    double fontSize = 34,
    bool isAmPm = false,
  }) {
    return SizedBox(
      width: width,
      height: 200,
      child: Stack(
        children: [
          // The wheel
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
                final isSelected = index == selectedIndex;
                return Center(
                  child: Text(
                    labelBuilder(index),
                    style: TextStyle(
                      fontSize: isSelected
                          ? (isAmPm ? 18 : fontSize)
                          : (isAmPm ? 14 : fontSize - 6),
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w300,
                      color: isSelected
                          ? const Color(0xFFF5F5F5)
                          : const Color(0xFFF5F5F5).withOpacity(0.28),
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
          // Fade overlay on top
          _fadeOverlay(),
        ],
      ),
    );
  }

  // ── Fixed colon separator ─────────────────────────────────

  Widget _colon() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        ':',
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w300,
          color: const Color(0xFFF5F5F5).withOpacity(0.45),
          height: 1,
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive wheel widths
        final availableWidth = constraints.maxWidth;
        final hourWidth   = (availableWidth * 0.26).clamp(64.0, 88.0);
        final minuteWidth = (availableWidth * 0.26).clamp(64.0, 88.0);
        final amPmWidth   = (availableWidth * 0.18).clamp(44.0, 60.0);
        final totalWheelWidth = hourWidth + minuteWidth + amPmWidth + 40;

        return SizedBox(
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Selection highlight behind all wheels
              _selectionHighlight(totalWheelWidth),

              // Wheels row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Hour wheel: 01–12
                  _buildWheel(
                    controller: _hourController,
                    itemCount: 12,
                    labelBuilder: (i) => (i + 1).toString().padLeft(2, '0'),
                    selectedIndex: _selectedHour - 1,
                    onChanged: (i) {
                      setState(() => _selectedHour = i + 1);
                      _notifyParent();
                    },
                    width: hourWidth,
                  ),

                  // Fixed colon
                  _colon(),

                  // Minute wheel: 00–59
                  _buildWheel(
                    controller: _minuteController,
                    itemCount: 60,
                    labelBuilder: (i) => i.toString().padLeft(2, '0'),
                    selectedIndex: _selectedMinute,
                    onChanged: (i) {
                      setState(() => _selectedMinute = i);
                      _notifyParent();
                    },
                    width: minuteWidth,
                  ),

                  const SizedBox(width: 8),

                  // AM/PM wheel
                  _buildWheel(
                    controller: _amPmController,
                    itemCount: 2,
                    labelBuilder: (i) => i == 0 ? 'a.m.' : 'p.m.',
                    selectedIndex: _isAM ? 0 : 1,
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
