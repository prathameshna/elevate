import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DailyPillToggle extends StatelessWidget {
  final bool isActive;
  final VoidCallback onToggle;

  const DailyPillToggle({
    super.key,
    required this.isActive,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onToggle();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 72,
        height: 32,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF14B8A6) : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(16),
          border: isActive 
              ? null 
              : Border.all(color: const Color(0xFF3A3A3A), width: 1),
        ),
        child: Center(
          child: Text(
            'Daily',
            style: TextStyle(
              color: isActive ? Colors.white : const Color(0xFFA0A0A0),
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
