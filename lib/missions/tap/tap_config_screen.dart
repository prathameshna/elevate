import 'package:flutter/material.dart';
import 'tap_mission_model.dart';
import 'tap_challenge_screen.dart';

class TapConfigScreen extends StatefulWidget {
  final TapMissionConfig? initialConfig;

  const TapConfigScreen({super.key, this.initialConfig});

  @override
  State<TapConfigScreen> createState() => _TapConfigScreenState();
}

class _TapConfigScreenState extends State<TapConfigScreen> {
  late int _tapCount;
  late int _seconds;

  @override
  void initState() {
    super.initState();
    _tapCount = widget.initialConfig?.tapCount ?? 50;
    _seconds = widget.initialConfig?.seconds ?? 10;
  }

  void _openPreview() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TapChallengeScreen(
          config: TapMissionConfig(tapCount: _tapCount, seconds: _seconds),
          onComplete: () {
            // Preview completed
          },
          isPreview: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Tap Challenge', 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mission Concept',
              style: TextStyle(color: Color(0xFF606060), fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1.2),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tap the button 50 times within 10 seconds to wake up your body and mind.',
              style: TextStyle(color: Color(0xFFF0F0F0), fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 40),
            
            // Preview Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: _openPreview,
                icon: const Icon(Icons.play_circle_outline, color: Color(0xFFFFD600)),
                label: const Text('Preview Mission', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF333333)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            
            const Spacer(),
            
            // Add Mission Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, TapMissionConfig(tapCount: _tapCount, seconds: _seconds));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD600),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('Add Mission', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}
