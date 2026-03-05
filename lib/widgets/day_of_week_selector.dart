import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class DayOfWeekSelector extends StatelessWidget {
  const DayOfWeekSelector({
    super.key,
    required this.selectedDays,
    required this.onChanged,
  });

  final List<int> selectedDays; // 1 = Monday ... 7 = Sunday
  final ValueChanged<List<int>> onChanged;

  static const _labels = <int, String>{
    7: 'S',
    1: 'M',
    2: 'T',
    3: 'W',
    4: 'T',
    5: 'F',
    6: 'S',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ordered = [7, 1, 2, 3, 4, 5, 6];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final day in ordered)
          _DayChip(
            label: _labels[day] ?? '',
            isSelected: selectedDays.contains(day),
            onTap: () {
              final current = List<int>.from(selectedDays);
              if (current.contains(day)) {
                current.remove(day);
              } else {
                current.add(day);
              }
              current.sort();
              onChanged(current);
            },
          ),
      ],
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color:
              isSelected ? ElevateTheme.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected
                ? ElevateTheme.accent
                : Colors.grey.shade600,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isSelected ? Colors.white : ElevateTheme.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

