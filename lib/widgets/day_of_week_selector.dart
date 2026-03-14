import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DayOfWeekSelector extends StatefulWidget {
  final List<int> selectedDays; // 0=Sun, 1=Mon, ..., 6=Sat
  final Function(List<int>) onDaysChanged;

  const DayOfWeekSelector({
    super.key,
    required this.selectedDays,
    required this.onDaysChanged,
  });

  @override
  State<DayOfWeekSelector> createState() => _DayOfWeekSelectorState();
}

class _DayOfWeekSelectorState extends State<DayOfWeekSelector> {
  late List<int> _localSelectedDays;
  static const List<String> _dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  @override
  void initState() {
    super.initState();
    _localSelectedDays = List<int>.from(widget.selectedDays);
  }

  void _toggleDay(int dayIndex) {
    HapticFeedback.selectionClick();

    setState(() {
      if (_localSelectedDays.contains(dayIndex)) {
        _localSelectedDays.remove(dayIndex);
      } else {
        _localSelectedDays.add(dayIndex);
      }
      _localSelectedDays.sort();
    });

    widget.onDaysChanged(_localSelectedDays);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Repeat',
          style: TextStyle(
            color: Color(0xFFA0A0A0),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(
            7,
            (index) {
              final isSelected = _localSelectedDays.contains(index);

              return GestureDetector(
                onTap: () => _toggleDay(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? const Color(0xFF14B8A6)
                        : const Color(0xFF3A3A3A),
                    border: isSelected
                        ? Border.all(color: const Color(0xFFFFD600), width: 2)
                        : Border.all(color: const Color(0xFF4A4A4A), width: 1),
                  ),
                  child: Center(
                    child: Text(
                      _dayLabels[index],
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFFA0A0A0),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
