import 'package:flutter/material.dart';

class VibrationSelectionScreen extends StatelessWidget {
  const VibrationSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const vibrations = ['basic', 'custom', 'off'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Vibration'),
        backgroundColor: const Color(0xFF2A2A2A),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFF1A1A1A),
      body: ListView.builder(
        itemCount: vibrations.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(
              vibrations[index],
              style: const TextStyle(color: Color(0xFFF5F5F5)),
            ),
            trailing: const Icon(Icons.chevron_right, color: Color(0xFFA0A0A0)),
            onTap: () => Navigator.pop(context, vibrations[index]),
          );
        },
      ),
    );
  }
}
