class VibrationItem {
  final String id;
  final String name;
  final List<int> pattern; // [wait_ms, vibrate_ms, wait_ms, vibrate_ms ...]

  const VibrationItem({
    required this.id,
    required this.name,
    required this.pattern,
  });
}

// All 10 vibration patterns
const List<VibrationItem> kVibrations = [
  VibrationItem(
    id: 'basic',
    name: 'Basic',
    pattern: [0, 200, 100, 200],
  ),
  VibrationItem(
    id: 'heartbeat',
    name: 'Heartbeat',
    pattern: [0, 150, 80, 150, 400, 150, 80, 150],
  ),
  VibrationItem(
    id: 'ticktock',
    name: 'Ticktock',
    pattern: [0, 80, 80, 80, 80, 80, 80, 80],
  ),
  VibrationItem(
    id: 'waltz',
    name: 'Waltz',
    pattern: [0, 300, 150, 150, 150, 150],
  ),
  VibrationItem(
    id: 'zigzigzig',
    name: 'Zig-Zig-Zig',
    pattern: [0, 80, 40, 80, 40, 80],
  ),
  VibrationItem(
    id: 'offbeat',
    name: 'Offbeat',
    pattern: [0, 200, 300, 100, 100, 300],
  ),
  VibrationItem(
    id: 'spinning',
    name: 'Spinning',
    pattern: [0, 50, 30, 50, 30, 50, 30, 50, 30, 50],
  ),
  VibrationItem(
    id: 'siren',
    name: 'Siren',
    pattern: [0, 100, 50, 200, 50, 100, 50, 200],
  ),
  VibrationItem(
    id: 'telephone',
    name: 'Telephone',
    pattern: [0, 400, 200, 400, 600, 400, 200, 400],
  ),
  VibrationItem(
    id: 'spring',
    name: 'Spring',
    pattern: [0, 50, 50, 100, 50, 150, 50, 200],
  ),
];
