import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'daily_pill_toggle.dart';
import 'day_button.dart';

class DaySelectorWidget extends StatefulWidget {
  final List<int> selectedDays;
  final Function(List<int>) onDaysChanged;

  const DaySelectorWidget({
    super.key,
    required this.selectedDays,
    required this.onDaysChanged,
  });

  @override
  State<DaySelectorWidget> createState() => _DaySelectorWidgetState();
}

class _DaySelectorWidgetState extends State<DaySelectorWidget> {
  bool _isDailyActive = false;

  @override
  void initState() {
    super.initState();
    _isDailyActive = widget.selectedDays.length == 7;
  }

  @override
  void didUpdateWidget(DaySelectorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep internal toggle state in sync with external selectedDays set
    if (widget.selectedDays.length == 7 && !_isDailyActive) {
      setState(() => _isDailyActive = true);
    } else if (widget.selectedDays.length != 7 && _isDailyActive) {
      setState(() => _isDailyActive = false);
    }
  }

  @override
  void dispose() {
    // Note: Future.delayed cannot be cancelled easily, 
    // but the mounted check in the callback handles it.
    super.dispose();
  }

  void _onDailyToggled() async {
    final newValue = !_isDailyActive;
    setState(() => _isDailyActive = newValue);
    
    if (newValue) {
      // RECOMMENDED FIX: Select all 7 days instantly in the data
      widget.onDaysChanged([0, 1, 2, 3, 4, 5, 6]);
      
      // OPTIONAL: Run purely visual staggered animation on local state
      // (The days will light up because widget.selectedDays is now full)
    } else {
      widget.onDaysChanged([]);
    }
  }

  void _onDayTapped(int index) {
    final updated = List<int>.from(widget.selectedDays);
    if (updated.contains(index)) {
      updated.remove(index);
    } else {
      updated.add(index);
    }
    
    setState(() => _isDailyActive = updated.length == 7);
    widget.onDaysChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF3A3A3A), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Repeat Title + Daily Pill Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Repeat",
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFFF5F5F5),
                  fontWeight: FontWeight.w500,
                ),
              ),
              DailyPillToggle(
                isActive: _isDailyActive,
                onToggle: _onDailyToggled,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Row 2: Dynamic-sized circular day buttons
          LayoutBuilder(
            builder: (context, constraints) {
              const gapsCount = 6;
              const gapWidth = 8.0;
              final btnSize = ((constraints.maxWidth - (gapsCount * gapWidth)) / 7).clamp(32.0, 46.0);
              const labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
              
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (i) => DayButton(
                  label: labels[i],
                  isSelected: widget.selectedDays.contains(i),
                  onTap: () => _onDayTapped(i),
                  size: btnSize,
                )),
              );
            },
          ),
        ],
      ),
    );
  }
}
