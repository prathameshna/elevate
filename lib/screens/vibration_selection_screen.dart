import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import '../widgets/alarm_toggle.dart';

// ─────────────────────────────────────────────────────────────
// Internal data class — no external model file needed
// ─────────────────────────────────────────────────────────────
class _VP {
  final String id;
  final String name;
  final List<int> p; // vibration pattern
  const _VP(this.id, this.name, this.p);
}

// ─────────────────────────────────────────────────────────────
// All 10 patterns — matches reference list exactly
// ─────────────────────────────────────────────────────────────
const List<_VP> _kPatterns = [
  _VP('basic',     'Basic',       [0, 200, 100, 200]),
  _VP('heartbeat', 'Heartbeat',   [0, 150, 80, 150, 400, 150, 80, 150]),
  _VP('ticktock',  'Ticktock',    [0, 80, 80, 80, 80, 80, 80, 80]),
  _VP('waltz',     'Waltz',       [0, 300, 150, 150, 150, 150]),
  _VP('zigzigzig', 'Zig-Zig-Zig', [0, 80, 40, 80, 40, 80]),
  _VP('offbeat',   'Offbeat',     [0, 200, 300, 100, 100, 300]),
  _VP('spinning',  'Spinning',    [0, 50, 30, 50, 30, 50, 30, 50, 30, 50]),
  _VP('siren',     'Siren',       [0, 100, 50, 200, 50, 100, 50, 200]),
  _VP('telephone', 'Telephone',   [0, 400, 200, 400, 600, 400, 200, 400]),
  _VP('spring',    'Spring',      [0, 50, 50, 100, 50, 150, 50, 200]),
];

// ─────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────
class VibrationSelectionScreen extends StatefulWidget {
  final String? initialPatternId;
  const VibrationSelectionScreen({super.key, this.initialPatternId});

  @override
  State<VibrationSelectionScreen> createState() =>
      _VibrationSelectionScreenState();
}

class _VibrationSelectionScreenState
    extends State<VibrationSelectionScreen> {
  bool   _enabled   = true;
  String _selected  = 'spinning';

  @override
  void initState() {
    super.initState();
    _selected = widget.initialPatternId ?? 'spinning';
    _load();
  }

  @override
  void dispose() {
    Vibration.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _enabled   = p.getBool('vib_on')  ?? true;
      _selected  = p.getString('vib_id')
          ?? widget.initialPatternId
          ?? 'spinning';
    });
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('vib_on',   _enabled);
    await p.setString('vib_id', _selected);
  }

  Future<void> _buzz(List<int> pattern) async {
    final ok = await Vibration.hasVibrator();
    if (ok != true) return;
    await Vibration.cancel();
    await Future.delayed(const Duration(milliseconds: 20));
    Vibration.vibrate(pattern: pattern);
  }

  Future<void> _onToggle(bool val) async {
    setState(() => _enabled = val);
    if (!val) await Vibration.cancel();
    await _save();
  }

  Future<void> _onTap(_VP vp) async {
    if (!_enabled) return;
    HapticFeedback.selectionClick();
    setState(() => _selected = vp.id);
    await _save();
    await _buzz(vp.p);
  }

  // ── UI ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context, _selected),
        ),
        title: const Text(
          'Vibration',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      // ── Scrollable body with card ──
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _card(),
      ),
    );
  }

  // ── Card — toggle + pattern list ─────────────────────────

  Widget _card() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF242424),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF303030)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Toggle row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(
              children: [
                const Text(
                  'Enable vibration',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                AlarmToggle(
                  value: _enabled,
                  onChanged: _onToggle,
                ),
              ],
            ),
          ),
          // Divider
          Container(height: 1, color: const Color(0xFF303030)),
          // Pattern rows
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _enabled ? 1.0 : 0.3,
            child: IgnorePointer(
              ignoring: !_enabled,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(_kPatterns.length, (i) {
                  return _row(_kPatterns[i], i == _kPatterns.length - 1);
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Single pattern row ────────────────────────────────────

  Widget _row(_VP vp, bool isLast) {
    final sel = _selected == vp.id;
    return GestureDetector(
      onTap: () => _onTap(vp),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: sel
              ? const Color(0xFFFFD600).withValues(alpha: 0.05)
              : Colors.transparent,
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(color: Color(0xFF303030), width: 1),
                ),
          borderRadius: isLast
              ? const BorderRadius.vertical(bottom: Radius.circular(16))
              : null,
        ),
        child: Row(
          children: [
            Text(
              vp.name,
              style: TextStyle(
                color: sel ? const Color(0xFFFFD600) : Colors.white,
                fontSize: 16,
                fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            const Spacer(),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: sel
                  ? const Icon(
                      Icons.check_rounded,
                      key: ValueKey('y'),
                      color: Color(0xFFFFD600),
                      size: 20,
                    )
                  : const SizedBox(key: ValueKey('n'), width: 20, height: 20),
            ),
          ],
        ),
      ),
    );
  }

}
