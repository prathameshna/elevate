import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

class VibrationPattern {
  final String id;
  final String name;
  final List<int> pattern;       // [wait, vibrate, wait, vibrate...]
  final List<int>? intensities;  // optional amplitude per step (0-255)

  const VibrationPattern({
    required this.id,
    required this.name,
    required this.pattern,
    this.intensities,
  });

  /// Preview this pattern with given intensity scale (0.0 - 1.0)
  Future<void> preview({double intensityScale = 1.0}) async {
    if (pattern.isEmpty) return;

    final bool supported = await Vibration.hasVibrator() ?? false;
    if (!supported) {
      HapticFeedback.mediumImpact();
      return;
    }

    await Vibration.cancel();
    await Future.delayed(const Duration(milliseconds: 30));

    if (intensities != null) {
      final scaled = intensities!
          .map((v) => (v * intensityScale).round().clamp(0, 255))
          .toList();
      Vibration.vibrate(pattern: pattern, intensities: scaled);
    } else {
      Vibration.vibrate(pattern: pattern);
    }
  }
}

// ── All vibration patterns ─────────────────────────────────

final List<VibrationPattern> allVibrationPatterns = [

  const VibrationPattern(
    id: 'short',
    name: 'Short',
    pattern: [0, 100],
  ),

  const VibrationPattern(
    id: 'medium',
    name: 'Medium',
    pattern: [0, 400],
  ),

  const VibrationPattern(
    id: 'basic',
    name: 'Basic',
    pattern: [0, 200, 100, 200],
  ),

  const VibrationPattern(
    id: 'heartbeat',
    name: 'Heartbeat',
    pattern: [0, 150, 80, 150, 400, 150, 80, 150],
    intensities: [0, 180, 0, 255, 0, 180, 0, 255],
  ),

  const VibrationPattern(
    id: 'tiktok',
    name: 'Tik Tok',
    pattern: [0, 80, 80, 80, 80, 80, 80, 80, 80, 80],
  ),

  const VibrationPattern(
    id: 'waltz',
    name: 'Waltz',
    pattern: [0, 300, 150, 150, 150, 150],
    intensities: [0, 255, 0, 180, 0, 180],
  ),

  const VibrationPattern(
    id: 'zigzigzig',
    name: 'Zig-Zig-Zig',
    pattern: [0, 80, 40, 80, 40, 80],
  ),

  const VibrationPattern(
    id: 'offbeat',
    name: 'Offbeat',
    pattern: [0, 200, 300, 100, 100, 300],
    intensities: [0, 255, 0, 128, 0, 200],
  ),

  const VibrationPattern(
    id: 'spinning',
    name: 'Spinning',
    pattern: [0, 50, 30, 50, 30, 50, 30, 50, 30, 50, 30, 50],
  ),

  const VibrationPattern(
    id: 'siren',
    name: 'Siren',
    pattern: [0, 100, 50, 200, 50, 100, 50, 200],
    intensities: [0, 128, 0, 255, 0, 128, 0, 255],
  ),

  const VibrationPattern(
    id: 'telephone',
    name: 'Telephone',
    pattern: [0, 400, 200, 400, 600, 400, 200, 400],
  ),

  const VibrationPattern(
    id: 'spring',
    name: 'Spring',
    pattern: [0, 50, 50, 100, 50, 150, 50, 200],
    intensities: [0, 100, 0, 150, 0, 200, 0, 255],
  ),
];
