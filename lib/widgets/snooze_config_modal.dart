import 'package:flutter/material.dart';

class SnoozeConfigModal extends StatefulWidget {
  final int initialMinutes;
  final bool initialAlwaysSnooze;

  const SnoozeConfigModal({
    Key? key,
    required this.initialMinutes,
    required this.initialAlwaysSnooze,
  }) : super(key: key);

  @override
  State<SnoozeConfigModal> createState() => _SnoozeConfigModalState();
}

class _SnoozeConfigModalState extends State<SnoozeConfigModal> {
  late int _selectedMinutes;
  late bool _alwaysSnooze;

  @override
  void initState() {
    super.initState();
    _selectedMinutes = widget.initialMinutes;
    _alwaysSnooze = widget.initialAlwaysSnooze;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Snooze Configuration',
            style: TextStyle(
              color: Color(0xFFF5F5F5),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Duration (minutes)',
                style: TextStyle(color: Color(0xFFF5F5F5), fontSize: 16),
              ),
              DropdownButton<int>(
                value: _selectedMinutes,
                dropdownColor: const Color(0xFF3A3A3A),
                underline: const SizedBox(),
                icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFFA0A0A0)),
                items: [5, 10, 15, 30].map((value) {
                  return DropdownMenuItem(
                    value: value,
                    child: Text(
                      '$value min',
                      style: const TextStyle(color: Color(0xFFF5F5F5)),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedMinutes = value ?? 5;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Always Snooze',
                style: TextStyle(color: Color(0xFFF5F5F5), fontSize: 16),
              ),
              Switch(
                value: _alwaysSnooze,
                onChanged: (value) {
                  setState(() {
                    _alwaysSnooze = value;
                  });
                },
                activeColor: const Color(0xFF14B8A6),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
                  'minutes': _selectedMinutes,
                  'always': _alwaysSnooze,
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD600),
                foregroundColor: const Color(0xFF1A1A1A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Done',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
