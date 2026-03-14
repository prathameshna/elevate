import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'memory_mission_model.dart';
import 'memory_grid_widget.dart';

class MemoryConfigScreen extends StatefulWidget {
  final MemoryMissionConfig? initialConfig;
  const MemoryConfigScreen({super.key, this.initialConfig});

  @override
  State<MemoryConfigScreen> createState() => _MemoryConfigScreenState();
}

class _MemoryConfigScreenState extends State<MemoryConfigScreen>
    with TickerProviderStateMixin {

  late int    _questionCount;
  late String _difficulty;

  bool         _isPreviewing = false;
  bool         _showTiles    = false;
  List<int>    _previewHighlighted = [];
  Timer?       _timer;

  List<TileState> _previewStates = List.filled(25, TileState.normal);

  static const _diffs  = ['easy', 'normal', 'hard', 'expert'];
  static const _labels = ['Easy', 'Normal', 'Hard', 'Expert'];

  late AnimationController _flamePulse;

  MemoryMissionConfig get _config => MemoryMissionConfig(
    questionCount: _questionCount,
    difficulty:    _difficulty,
  );

  @override
  void initState() {
    super.initState();
    _questionCount = widget.initialConfig?.questionCount ?? 3;
    _difficulty    = widget.initialConfig?.difficulty    ?? 'normal';
    _flamePulse    = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _refreshPreview();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _flamePulse.dispose();
    super.dispose();
  }

  void _refreshPreview() {
    final q = MemoryQuestion.generate(_config.tilesToMemorize);
    setState(() {
      _previewHighlighted = q.highlightedIndices;
      _previewStates      = List.generate(25, (i) =>
          _previewHighlighted.contains(i)
              ? TileState.highlighted
              : TileState.normal);
    });
  }

  void _startPreview() {
    setState(() => _isPreviewing = true);
    _previewCycle();
  }

  void _previewCycle() {
    _refreshPreview();
    setState(() => _showTiles = true);
    _timer = Timer(Duration(milliseconds: _config.memorizeDurationMs), () {
      if (!mounted || !_isPreviewing) return;
      setState(() {
        _showTiles     = false;
        _previewStates = List.filled(25, TileState.normal);
      });
      _timer = Timer(const Duration(milliseconds: 1200), () {
        if (!mounted || !_isPreviewing) return;
        _previewCycle();
      });
    });
  }

  void _stopPreview() {
    _timer?.cancel();
    setState(() {
      _isPreviewing  = false;
      _showTiles     = false;
      _previewStates = List.filled(25, TileState.normal);
    });
    _refreshPreview();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        backgroundColor:  const Color(0xFF111111),
        elevation:        0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFFF5F5F5), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Memory',
            style: TextStyle(color: Color(0xFFF5F5F5),
                fontSize: 20, fontWeight: FontWeight.w700)),
        actions: [
          TextButton(
            onPressed: _isPreviewing ? _stopPreview : _startPreview,
            child: Text(
              _isPreviewing ? 'STOP' : 'PREVIEW',
              style: TextStyle(
                color: _isPreviewing
                    ? const Color(0xFFEF4444)
                    : const Color(0xFFFFD600),
                fontSize: 13, fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Column(children: [

                // Flames
                _buildFlames(),
                const SizedBox(height: 20),

                // Preview card
                _buildPreviewCard(),
                const SizedBox(height: 28),

                // Questions
                _buildSectionLabel('Number of Questions'),
                const SizedBox(height: 14),
                _buildCounter(),
                const SizedBox(height: 28),

                // Difficulty
                _buildSectionLabel('Difficulty Level'),
                const SizedBox(height: 14),
                _buildDifficultyRow(),
                const SizedBox(height: 20),

                // Info
                _buildInfoCard(),
                const SizedBox(height: 20),
              ]),
            ),
          ),

          // Save
          _buildSaveBar(),
        ],
      ),
    );
  }

  Widget _buildFlames() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (i) {
          final on = i < _config.flameCount;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: on
                ? AnimatedBuilder(
                    animation: _flamePulse,
                    builder: (_, _) => Text('🔥',
                        style: TextStyle(
                            fontSize: 18 + _flamePulse.value * 3)))
                : const Opacity(opacity: 0.2,
                    child: Text('🔥', style: TextStyle(fontSize: 18))),
          );
        }),
      ),
    );
  }

  Widget _buildPreviewCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isPreviewing
              ? const Color(0xFFFFD600).withValues(alpha: 0.35)
              : const Color(0xFF2A2A2A),
          width: 1.5,
        ),
      ),
      child: Column(children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Text(
            _isPreviewing
                ? (_showTiles ? 'Memorise the tiles...' : 'Ready?')
                : 'Example',
            key: ValueKey('$_isPreviewing$_showTiles'),
            style: TextStyle(
              color: _showTiles
                  ? const Color(0xFFFFD600)
                  : const Color(0xFF606060),
              fontSize: 13, fontWeight: FontWeight.w500,
              letterSpacing: 0.4,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: MemoryGridWidget(
            tileStates: _previewStates, interactive: false),
        ),
        if (!_isPreviewing) ...[
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _startPreview,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD600).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: const Color(0xFFFFD600).withValues(alpha: 0.25)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_arrow_rounded,
                      color: Color(0xFFFFD600), size: 16),
                  SizedBox(width: 5),
                  Text('Preview', style: TextStyle(
                      color: Color(0xFFFFD600),
                      fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _buildSectionLabel(String text) => Align(
    alignment: Alignment.centerLeft,
    child: Text(text, style: const TextStyle(
        color: Color(0xFF606060), fontSize: 12,
        fontWeight: FontWeight.w600, letterSpacing: 0.8)),
  );

  Widget _buildCounter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _CircleBtn(
          icon: Icons.remove_rounded,
          active: _questionCount > 1,
          onTap: () { if (_questionCount > 1) {
            setState(() => _questionCount--);
          } },
        ),
        const SizedBox(width: 28),
        Text('$_questionCount', style: const TextStyle(
            color: Color(0xFFF5F5F5), fontSize: 44,
            fontWeight: FontWeight.w800, height: 1)),
        const SizedBox(width: 28),
        _CircleBtn(
          icon: Icons.add_rounded,
          active: _questionCount < 10,
          onTap: () { if (_questionCount < 10) {
            setState(() => _questionCount++);
          } },
        ),
      ],
    );
  }

  Widget _buildDifficultyRow() {
    return Row(
      children: List.generate(_diffs.length, (i) {
        final sel = _diffs[i] == _difficulty;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() { _difficulty = _diffs[i]; });
              if (!_isPreviewing) _refreshPreview();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(
                  right: i < _diffs.length - 1 ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: sel
                    ? const Color(0xFFFFD600)
                    : const Color(0xFF1C1C1C),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: sel
                      ? const Color(0xFFFFD600)
                      : const Color(0xFF2A2A2A),
                ),
              ),
              child: Center(child: Text(_labels[i], style: TextStyle(
                  color: sel ? Colors.black : const Color(0xFF707070),
                  fontSize: 11.5, fontWeight: sel
                      ? FontWeight.w700 : FontWeight.w500))),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(children: [
        const Icon(Icons.info_outline_rounded,
            color: Color(0xFF14B8A6), size: 17),
        const SizedBox(width: 10),
        Expanded(child: Text(
          '${_config.tilesToMemorize} tiles flash for '
          '${(_config.memorizeDurationMs / 1000).toStringAsFixed(1)}s. '
          'Remember and tap them all to dismiss the alarm.',
          style: const TextStyle(color: Color(0xFF606060),
              fontSize: 12, height: 1.5),
        )),
      ]),
    );
  }

  Widget _buildSaveBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      color: const Color(0xFF111111),
      child: SizedBox(
        width: double.infinity, height: 52,
        child: ElevatedButton(
          onPressed: () {
            HapticFeedback.mediumImpact();
            Navigator.pop(context, _config);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFD600),
            foregroundColor: Colors.black,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('Save', style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData  icon;
  final bool      active;
  final VoidCallback onTap;
  const _CircleBtn({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
      child: Container(
        width: 46, height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active
              ? const Color(0xFF262626) : const Color(0xFF1A1A1A),
          border: Border.all(
            color: active
                ? const Color(0xFF3A3A3A) : const Color(0xFF242424),
          ),
        ),
        child: Icon(icon,
            color: active
                ? const Color(0xFFF5F5F5) : const Color(0xFF383838),
            size: 20),
      ),
    );
  }
}
