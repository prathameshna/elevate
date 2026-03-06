import 'package:flutter/material.dart';

class SoundSelectionScreen extends StatelessWidget {
  const SoundSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const sounds = [
      'default_alarm',
      'gentle_wake',
      'skyblue',
      'bells',
      'pulse',
      'radar',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Sound'),
        backgroundColor: const Color(0xFF2A2A2A),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFF1A1A1A),
      body: ListView.builder(
        itemCount: sounds.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(
              sounds[index],
              style: const TextStyle(color: Color(0xFFF5F5F5)),
            ),
            trailing: const Icon(Icons.chevron_right, color: Color(0xFFA0A0A0)),
            onTap: () => Navigator.pop(context, sounds[index]),
          );
        },
      ),
    );
  }
}
