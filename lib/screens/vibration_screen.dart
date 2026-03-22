import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import '../models/vibration_item.dart';
import '../widgets/alarm_toggle.dart';

class VibrationScreen extends StatefulWidget {
  final String? initialId;

  const VibrationScreen({super.key, this.initialId});

  @override
  State<VibrationScreen> createState() => _VibrationScreenState();
}

class _VibrationScreenState extends State<VibrationScreen> {

  bool   _enabled = true;
  String _selectedId = 'basic';

  // ── Lifecycle ─────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _selectedId = widget.initialId ?? 'basic';
    _loadPrefs();
  }

  @override
  void dispose() {
    Vibration.cancel();
    super.dispose();
  }

  // ── Prefs ─────────────────────────────────────────────────

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _enabled = prefs.getBool('vib_enabled') ?? true;

      // widget.initialId always wins — this is the alarm's own saved vibration
      if (widget.initialId != null && widget.initialId!.isNotEmpty) {
        _selectedId = widget.initialId!;
      } else {
        _selectedId = prefs.getString('vib_id') ?? 'basic';
      }
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    // Only save enabled toggle globally
    // Do NOT save vib_id here — each alarm saves its own via Navigator.pop
    await prefs.setBool('vib_enabled', _enabled);
  }

  // ── Actions ───────────────────────────────────────────────

  Future<void> _toggleEnabled(bool val) async {
    setState(() => _enabled = val);
    if (!val) await Vibration.cancel();
    await _savePrefs();
  }

  Future<void> _selectVibration(VibrationItem item) async {
    if (!_enabled) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedId = item.id);
    await _savePrefs();
    await _buzz(item.pattern);
  }

  Future<void> _buzz(List<int> pattern) async {
    final has = await Vibration.hasVibrator();
    if (has != true) return;
    await Vibration.cancel();
    await Future.delayed(const Duration(milliseconds: 20));
    Vibration.vibrate(pattern: pattern);
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          Navigator.pop(context, _selectedId);
        },
        child: Scaffold(
          backgroundColor: const Color(0xFF1A1A1A),

          // AppBar
          appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFFF5F5F5),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context, _selectedId),
        ),
        title: const Text(
          'Vibration',
          style: TextStyle(
            color: Color(0xFFF5F5F5),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
      ),

      // Body — scrollable card
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 20,
        ),
        child: _buildCard(),
      ),
        ),
    );
  }

  // ── Card ──────────────────────────────────────────────────

  Widget _buildCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF242424),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF303030),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          // ── Enable Vibration row ──────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
            child: Row(
              children: [
                const Text(
                  'Enable vibration',
                  style: TextStyle(
                    color: Color(0xFFF5F5F5),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                AlarmToggle(
                  value: _enabled,
                  onChanged: _toggleEnabled,
                ),
              ],
            ),
          ),

          // Divider
          Container(
            height: 1,
            color: const Color(0xFF303030),
          ),

          // ── Pattern list ──────────────────────────────────
          AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: _enabled ? 1.0 : 0.3,
            child: IgnorePointer(
              ignoring: !_enabled,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: List.generate(
                  kVibrations.length,
                  (index) => _buildRow(
                    kVibrations[index],
                    isLast: index == kVibrations.length - 1,
                  ),
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }

  // ── Single Row ────────────────────────────────────────────

  Widget _buildRow(VibrationItem item, {required bool isLast}) {
    final isSelected = _selectedId == item.id;

    return GestureDetector(
      onTap: () => _selectVibration(item),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFFD600).withValues(alpha: 0.05)
              : Colors.transparent,
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(
                    color: Color(0xFF303030),
                    width: 1,
                  ),
                ),
          borderRadius: isLast
              ? const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                )
              : null,
        ),
        child: Row(
          children: [
            // Pattern name
            Text(
              item.name,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFFFFD600)
                    : const Color(0xFFF5F5F5),
                fontSize: 16,
                fontWeight: isSelected
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
            ),

            const Spacer(),

            // Checkmark
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) => ScaleTransition(
                scale: CurvedAnimation(
                  parent: anim,
                  curve: Curves.easeOutBack,
                ),
                child: child,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      key: ValueKey('check'),
                      color: Color(0xFFFFD600),
                      size: 20,
                    )
                  : const SizedBox(
                      key: ValueKey('empty'),
                      width: 20,
                      height: 20,
                    ),
            ),
          ],
        ),
      ),
    );
  }

}
