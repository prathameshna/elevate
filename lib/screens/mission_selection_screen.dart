import 'package:flutter/material.dart';

class MissionSelectionScreen extends StatelessWidget {
  const MissionSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const missions = [
      {'id': '', 'name': 'None'},
      {'id': 'work', 'name': 'Work'},
      {'id': 'health', 'name': 'Health'},
      {'id': 'exercise', 'name': 'Exercise'},
      {'id': 'personal', 'name': 'Personal'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Mission'),
        backgroundColor: const Color(0xFF2A2A2A),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFF1A1A1A),
      body: ListView.builder(
        itemCount: missions.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(
              missions[index]['name'] as String,
              style: const TextStyle(color: Color(0xFFF5F5F5)),
            ),
            trailing: const Icon(Icons.chevron_right, color: Color(0xFFA0A0A0)),
            onTap: () => Navigator.pop(context, missions[index]['id']),
          );
        },
      ),
    );
  }
}
