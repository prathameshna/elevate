import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'colour_tiles_model.dart';

class ColourTilesConfigScreen extends StatefulWidget {
  final ColourTilesConfig? initialConfig;
  const ColourTilesConfigScreen({super.key, this.initialConfig});

  @override
  State<ColourTilesConfigScreen> createState() =>
      _ColourTilesConfigScreenState();
}

class _ColourTilesConfigScreenState
    extends State<ColourTilesConfigScreen>
    with SingleTickerProviderStateMixin {

  late CTDifficulty _difficulty;
  late int          _questionCount;

  // ── PERMANENT storage — assigned ONCE, never changed mid-preview ──
  List<int> _yellowIndices = []; // stores positions of yellow tiles
  int       _gridSize      = 4;  // stores grid size

  // ── Preview phase ──────────────────────────────────────
  // 'idle' = all grey, positions stored but not visible
  // 'showing' = yellow tiles visible
  // 'hidden' = all grey, positions STILL in _yellowIndices
  // 'answering' = user tapping (only in preview interactive mode)
  String _phase = 'idle';

  // Tiles correctly tapped in preview
  Set<int> _previewCorrect = {};
  int?     _previewWrong;

  late AnimationController _gridAnim;
  late Animation<double>   _gridFade;
  late Animation<double>   _gridScale;

  @override
  void initState() {
    super.initState();
    _difficulty    = widget.initialConfig?.difficulty    ?? CTDifficulty.normal;
    _questionCount = widget.initialConfig?.questionCount ?? 3;

    _gridAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380));
    _gridFade = CurvedAnimation(parent: _gridAnim, curve: Curves.easeOut);
    _gridScale = Tween<double>(begin: 0.93, end: 1.0).animate(
        CurvedAnimation(parent: _gridAnim, curve: Curves.easeOutBack));

    // Generate initial preview positions
    _generateNewPositions();
  }

  @override
  void dispose() {
    _gridAnim.dispose();
    super.dispose();
  }

  // ── Generate positions ONCE — store in plain List<int> ──
  void _generateNewPositions() {
    final rng     = Random();
    final total   = _difficulty.gridSize * _difficulty.gridSize;
    final count   = _difficulty.yellowCount;
    final indices = <int>{};
    while (indices.length < count) {
      indices.add(rng.nextInt(total));
    }

    // Store permanently in plain variables
    _yellowIndices  = indices.toList();
    _gridSize       = _difficulty.gridSize;
    _phase          = 'idle';
    _previewCorrect = {};
    _previewWrong   = null;

    _gridAnim.forward(from: 0);
    setState(() {});
  }

  // ── PREVIEW button — only changes phase, NEVER changes positions ──
  void _runPreview() {
    // Step 1: just change phase to showing — positions already stored
    setState(() {
      _phase          = 'showing';
      _previewCorrect = {};
      _previewWrong   = null;
    });

    // Step 2: after show duration → hide (positions stay in _yellowIndices)
    Future.delayed(
      Duration(milliseconds: _difficulty.showDurationMs),
      () {
        if (!mounted) return;
        setState(() => _phase = 'answering'); // user can now tap
      },
    );
  }

  // ── User taps a tile in preview ──
  void _onPreviewTileTap(int index) {
    if (_phase != 'answering') return;
    if (_previewCorrect.contains(index)) return;
    if (_previewWrong != null) return;

    // Check against _yellowIndices — the permanently stored list
    final isYellow = _yellowIndices.contains(index);

    if (isYellow) {
      HapticFeedback.lightImpact();
      final updated = Set<int>.from(_previewCorrect)..add(index);
      setState(() => _previewCorrect = updated);

      // All found — show success briefly then reset
      if (updated.length == _yellowIndices.length) {
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 800), () {
          if (!mounted) return;
          _generateNewPositions(); // generate fresh for next preview
        });
      }
    } else {
      HapticFeedback.mediumImpact();
      setState(() => _previewWrong = index);
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) setState(() => _previewWrong = null);
      });
    }
  }

  // ── Tile color — reads from _yellowIndices and _phase ──
  Color _tileColor(int i) {
    // Correct tap = green
    if (_previewCorrect.contains(i)) return const Color(0xFF22C55E);
    // Wrong tap = red flash
    if (i == _previewWrong)          return const Color(0xFFEF4444);
    // Show yellow only during 'showing' phase
    if (_phase == 'showing' && _yellowIndices.contains(i)) {
      return const Color(0xFFFFD600);
    }
    // Grey in all other phases
    return const Color(0xFF3A3A3A);
  }

  List<BoxShadow>? _tileShadow(int i) {
    if (_previewCorrect.contains(i)) {
      return [BoxShadow(
        color: const Color(0xFF22C55E).withValues(alpha: 0.4),
        blurRadius: 8)];
    }
    if (_phase == 'showing' && _yellowIndices.contains(i)) {
      return [BoxShadow(
        color: const Color(0xFFFFD600).withValues(alpha: 0.35),
        blurRadius: 8)];
    }
    return null;
  }

  // ── Difficulty change ──
  CTDifficulty _prevDiff() {
    final idx = CTDifficulty.values.indexOf(_difficulty);
    return CTDifficulty.values[(idx - 1 + 3) % 3];
  }

  CTDifficulty _nextDiff() {
    final idx = CTDifficulty.values.indexOf(_difficulty);
    return CTDifficulty.values[(idx + 1) % 3];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor:  const Color(0xFF0D0D0D),
        elevation:        0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFFF0F0F0), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Find Colour Tiles',
          style: TextStyle(color: Color(0xFFF0F0F0),
              fontSize: 18, fontWeight: FontWeight.w700)),
        actions: [
          TextButton(
            onPressed: (_phase == 'idle' || _phase == 'answering')
                ? _runPreview : null,
            child: Text(
              _phase == 'showing' ? 'WATCH...' : 'PREVIEW',
              style: TextStyle(
                color: _phase == 'showing'
                    ? const Color(0xFF555555)
                    : const Color(0xFFFFD600),
                fontSize: 13, fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(children: [

              // ── Preview card ──────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1C),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(children: [
                  // Status label
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      _phase == 'showing'   ? 'Memorise the yellow tiles...' :
                      _phase == 'answering' ? 'Now tap the yellow tiles' :
                                              'Example',
                      key: ValueKey(_phase),
                      style: TextStyle(
                        color:
                          _phase == 'showing'   ? const Color(0xFFFFD600) :
                          _phase == 'answering' ? const Color(0xFF14B8A6) :
                                                  const Color(0xFF888888),
                        fontSize: 13, fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Grid — uses _yellowIndices for all logic
                  FadeTransition(
                    opacity: _gridFade,
                    child: ScaleTransition(
                      scale: _gridScale,
                      child: _buildGrid(),
                    ),
                  ),

                  // Answering phase — show progress
                  if (_phase == 'answering') ...[
                    const SizedBox(height: 12),
                    Text(
                      '${_previewCorrect.length} / ${_yellowIndices.length} found',
                      style: const TextStyle(
                        color: Color(0xFF606060),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ]),
              ),

              const SizedBox(height: 32),

              // ── Number of Questions ───────────────────
              const Text('Number of Questions',
                style: TextStyle(color: Color(0xFF888888),
                    fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 18),

              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _CircleBtn(
                  icon:   Icons.remove,
                  active: _questionCount > 1,
                  onTap:  () => setState(() {
                    if (_questionCount > 1) _questionCount--;
                  }),
                ),
                const SizedBox(width: 40),
                Text('$_questionCount',
                  style: const TextStyle(color: Color(0xFFF0F0F0),
                      fontSize: 52, fontWeight: FontWeight.w800, height: 1.0)),
                const SizedBox(width: 40),
                _CircleBtn(
                  icon:   Icons.add,
                  active: _questionCount < 4, // MAX 4
                  onTap:  () => setState(() {
                    if (_questionCount < 4) _questionCount++;
                  }),
                ),
              ]),

              const SizedBox(height: 36),

              // ── Difficulty Level ──────────────────────
              const Text('Difficulty Level',
                style: TextStyle(color: Color(0xFF888888),
                    fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 14),

              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _difficulty = _prevDiff());
                    _generateNewPositions();
                  },
                  child: const Icon(Icons.chevron_left_rounded,
                      color: Color(0xFFF0F0F0), size: 36),
                ),
                const SizedBox(width: 20),
                SizedBox(
                  width: 160,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(_difficulty.label,
                      key: ValueKey(_difficulty),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFF0F0F0),
                        fontSize: 28, fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      )),
                  ),
                ),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _difficulty = _nextDiff());
                    _generateNewPositions();
                  },
                  child: const Icon(Icons.chevron_right_rounded,
                      color: Color(0xFFF0F0F0), size: 36),
                ),
              ]),

              const SizedBox(height: 32),
            ]),
          ),
        ),

        // ── Save ──────────────────────────────────────
        Container(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 12,
            bottom: MediaQuery.of(context).padding.bottom + 12,
          ),
          color: const Color(0xFF0D0D0D),
          child: SizedBox(
            width: double.infinity, height: 54,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(context, ColourTilesConfig(
                  difficulty:    _difficulty,
                  questionCount: _questionCount,
                ));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD600),
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Save',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildGrid() {
    final n   = _gridSize; // use stored gridSize, not difficulty.gridSize
    final gap = 6.0;

    return LayoutBuilder(builder: (_, c) {
      final w    = c.maxWidth;
      final size = (w - gap * (n - 1)) / n;
      final r    = (size * 0.18).clamp(4.0, 10.0);

      return SizedBox(
        width: w, height: size * n + gap * (n - 1),
        child: Stack(
          children: List.generate(n * n, (i) {
            final col = i % n;
            final row = i ~/ n;
            return Positioned(
              left: col * (size + gap),
              top:  row * (size + gap),
              child: GestureDetector(
                onTap: () => _onPreviewTileTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve:    Curves.easeOut,
                  width: size, height: size,
                  decoration: BoxDecoration(
                    color:        _tileColor(i),
                    borderRadius: BorderRadius.circular(r),
                    boxShadow:    _tileShadow(i),
                  ),
                ),
              ),
            );
          }),
        ),
      );
    });
  }
}

// ── Reusable widgets ──────────────────────────────────────

class _CircleBtn extends StatelessWidget {
  final IconData     icon;
  final bool         active;
  final VoidCallback onTap;

  const _CircleBtn({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (active) onTap();
      },
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF2A2A2A),
          border: Border.all(
            color: active
                ? const Color(0xFF444444)
                : const Color(0xFF222222),
          ),
        ),
        child: Icon(
          icon,
          size:  22,
          color: active
              ? const Color(0xFFF0F0F0)
              : const Color(0xFF3A3A3A),
        ),
      ),
    );
  }
}
