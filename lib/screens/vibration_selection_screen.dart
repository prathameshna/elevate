import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import '../models/vibration_pattern.dart';
import '../widgets/alarm_toggle.dart';

class VibrationSelectionScreen extends StatefulWidget {
  final String? initialPatternId;

  const VibrationSelectionScreen({super.key, this.initialPatternId});

  @override
  State<VibrationSelectionScreen> createState() =>
      _VibrationSelectionScreenState();
}

class _VibrationSelectionScreenState extends State<VibrationSelectionScreen> {

  bool    _vibrationEnabled  = true;
  String? _selectedPatternId = 'basic';
  double  _intensity         = 1.0;

  @override
  void initState() {
    super.initState();
    _selectedPatternId = widget.initialPatternId ?? 'basic';
    _loadPreferences();
  }

  @override
  void dispose() {
    Vibration.cancel();
    super.dispose();
  }

  // ── Persistence ───────────────────────────────────────────

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _vibrationEnabled  = prefs.getBool('vibration_enabled') ?? true;
      _intensity         = prefs.getDouble('vibration_intensity') ?? 1.0;
      _selectedPatternId = prefs.getString('vibration_pattern_id')
          ?? widget.initialPatternId
          ?? 'basic';
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vibration_enabled', _vibrationEnabled);
    await prefs.setDouble('vibration_intensity', _intensity);
    await prefs.setString('vibration_pattern_id', _selectedPatternId ?? 'basic');
  }

  // ── Actions ───────────────────────────────────────────────

  Future<void> _setVibrationEnabled(bool value) async {
    setState(() => _vibrationEnabled = value);
    if (!value) await Vibration.cancel();
    await _savePreferences();
  }

  Future<void> _selectPattern(VibrationPattern pattern) async {
    if (!_vibrationEnabled) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedPatternId = pattern.id);
    await _savePreferences();
    await pattern.preview(intensityScale: _intensity);
  }

  Future<void> _onIntensityChangeEnd(double value) async {
    setState(() => _intensity = value);
    await _savePreferences();
    if (_vibrationEnabled && _selectedPatternId != null) {
      final pattern = allVibrationPatterns.firstWhere(
        (p) => p.id == _selectedPatternId,
        orElse: () => allVibrationPatterns[2],
      );
      await pattern.preview(intensityScale: value);
    }
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFFF5F5F5), size: 20),
          onPressed: () => Navigator.pop(context, _selectedPatternId),
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
      bottomNavigationBar: _buildBottomBar(),
      // SingleChildScrollView fixes the blank screen — avoids unbounded height conflict
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: _buildPatternCard(),
      ),
    );
  }

  // ── Pattern Card ──────────────────────────────────────────

  Widget _buildPatternCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF242424),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2E2E2E)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,  // CRITICAL: lets card size to its children
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          // ── Enable Vibration Toggle ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                  value: _vibrationEnabled,
                  onChanged: _setVibrationEnabled,
                ),
              ],
            ),
          ),

          // Divider
          Container(height: 1, color: const Color(0xFF2E2E2E)),

          // ── Pattern list — Column + List.generate avoids nested scroll conflict ──
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _vibrationEnabled ? 1.0 : 0.35,
            child: IgnorePointer(
              ignoring: !_vibrationEnabled,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  allVibrationPatterns.length,
                  (index) {
                    final pattern = allVibrationPatterns[index];
                    final isSelected = _selectedPatternId == pattern.id;
                    final isLast = index == allVibrationPatterns.length - 1;
                    return _buildPatternRow(pattern, isSelected, isLast);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Pattern Row ───────────────────────────────────────────

  Widget _buildPatternRow(VibrationPattern pattern, bool isSelected, bool isLast) {
    return GestureDetector(
      onTap: () => _selectPattern(pattern),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFFD600).withOpacity(0.05)
              : Colors.transparent,
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(color: Color(0xFF2E2E2E), width: 1)),
          borderRadius: isLast
              ? const BorderRadius.vertical(bottom: Radius.circular(16))
              : null,
        ),
        child: Row(
          children: [
            Text(
              pattern.name,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFFFFD600)
                    : const Color(0xFFF5F5F5),
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            const Spacer(),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
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

  // ── Bottom Intensity Bar ──────────────────────────────────

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        border: Border(top: BorderSide(color: Color(0xFF2A2A2A), width: 1)),
      ),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _vibrationEnabled ? 1.0 : 0.35,
        child: IgnorePointer(
          ignoring: !_vibrationEnabled,
          child: Row(
            children: [
              const Icon(Icons.vibration_rounded,
                  color: Color(0xFFFFD600), size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFFF5F5F5),
                    inactiveTrackColor: const Color(0xFF3A3A3A),
                    thumbColor: Colors.white,
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 10),
                    overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 18),
                    overlayColor: Colors.white.withOpacity(0.12),
                  ),
                  child: Slider(
                    value: _intensity,
                    min: 0.1,
                    max: 1.0,
                    onChanged: (v) => setState(() => _intensity = v),
                    onChangeEnd: _onIntensityChangeEnd,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
