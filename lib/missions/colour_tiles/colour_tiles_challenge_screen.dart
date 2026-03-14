import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'colour_tiles_model.dart';

class ColourTilesChallengeScreen extends StatefulWidget {
  final ColourTilesConfig config;
  final VoidCallback onComplete;

  const ColourTilesChallengeScreen({
    super.key,
    required this.config,
    required this.onComplete,
  });

  @override
  State<ColourTilesChallengeScreen> createState() =>
      _ColourTilesChallengeScreenState();
}

class _ColourTilesChallengeScreenState
    extends State<ColourTilesChallengeScreen>
    with SingleTickerProviderStateMixin {

  // ── FIXED storage — plain List<int>, assigned once per round ──
  List<int> _yellowPositions = []; // NEVER reassigned mid-round
  int       _gridSize        = 4;

  int      _roundIndex    = 0;
  Set<int> _tappedCorrect = {};
  int?     _tappedWrong;

  late AnimationController _enterCtrl;
  late Animation<double>   _enterScale;
  late Animation<double>   _enterFade;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _enterScale = Tween<double>(begin: 0.88, end: 1.0).animate(
        CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutBack));
    _enterFade = CurvedAnimation(
        parent: _enterCtrl, curve: Curves.easeOut);
    _loadRound();
  }

  @override
  void dispose() { _enterCtrl.dispose(); super.dispose(); }

  // ── Generate positions ONCE per round ─────────────────
  void _loadRound() {
    final rng    = Random();
    final diff   = widget.config.difficulty;
    final total  = diff.gridSize * diff.gridSize;
    final count  = diff.yellowCount;
    final set    = <int>{};
    while (set.length < count) {
      set.add(rng.nextInt(total));
    }

    // Store in plain List<int> — THIS IS THE SOURCE OF TRUTH
    _yellowPositions = set.toList();
    _gridSize        = diff.gridSize;
    _tappedCorrect   = {};
    _tappedWrong     = null;

    setState(() {});
    _enterCtrl.forward(from: 0);
  }

  // ── Tap handler ───────────────────────────────────────
  void _onTileTap(int index) {
    if (_tappedWrong != null) return;
    if (_tappedCorrect.contains(index)) return;

    // Check against _yellowPositions — the fixed list
    final isYellow = _yellowPositions.contains(index);

    if (isYellow) {
      HapticFeedback.lightImpact();
      final updated = Set<int>.from(_tappedCorrect)..add(index);
      setState(() => _tappedCorrect = updated);

      // All yellow tiles found
      if (updated.length == _yellowPositions.length) {
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 600), () {
          if (!mounted) return;
          if (_roundIndex + 1 >= widget.config.questionCount) {
            widget.onComplete();
          } else {
            _roundIndex++;
            _loadRound(); // new round — generates NEW positions
          }
        });
      }
    } else {
      // Wrong — red flash only, _yellowPositions unchanged
      HapticFeedback.mediumImpact();
      setState(() => _tappedWrong = index);
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) setState(() => _tappedWrong = null);
      });
    }
  }

  // ── Tile color ─────────────────────────────────────────
  Color _tileColor(int i) {
    if (_tappedCorrect.contains(i))    return const Color(0xFF22C55E);
    if (i == _tappedWrong)             return const Color(0xFFEF4444);
    if (_yellowPositions.contains(i))  return const Color(0xFFFFD600);
    return const Color(0xFF252525);
  }

  List<BoxShadow>? _tileShadow(int i) {
    if (_tappedCorrect.contains(i)) {
      return [BoxShadow(color: const Color(0xFF22C55E).withValues(alpha: 0.4),
          blurRadius: 10, spreadRadius: 1)];
    }
    if (_yellowPositions.contains(i) && !_tappedCorrect.contains(i)) {
      return [BoxShadow(color: const Color(0xFFFFD600).withValues(alpha: 0.25),
          blurRadius: 8, spreadRadius: 1)];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final total     = widget.config.questionCount;
    final remaining = _yellowPositions.length - _tappedCorrect.length;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [

              _ProgressRow(total: total, current: _roundIndex),
              const SizedBox(height: 28),

              const Text('Tap all yellow tiles',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFFF0F0F0),
                    fontSize: 22, fontWeight: FontWeight.w700,
                    letterSpacing: -0.3)),
              const SizedBox(height: 6),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  remaining > 0
                      ? '$remaining tile${remaining > 1 ? "s" : ""} remaining'
                      : '✓ All found!',
                  key: ValueKey(remaining),
                  style: TextStyle(
                    color: remaining > 0
                        ? const Color(0xFF505050)
                        : const Color(0xFF22C55E),
                    fontSize: 14, fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              Expanded(
                child: Center(
                  child: FadeTransition(
                    opacity: _enterFade,
                    child: ScaleTransition(
                      scale: _enterScale,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: _buildGrid(),
                      ),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + 8),
                child: const Text(
                  'Tap all yellow tiles to stop the alarm',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF2E2E2E), fontSize: 12),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildGrid() {
    final n   = _gridSize; // use stored value
    final gap = n <= 4 ? 9.0 : n <= 5 ? 7.0 : 6.0;

    return LayoutBuilder(builder: (_, c) {
      final w    = c.maxWidth;
      final size = (w - gap * (n - 1)) / n;
      final r    = (size * 0.18).clamp(4.0, 12.0);

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
                onTap: () => _onTileTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
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

class _ProgressRow extends StatelessWidget {
  final int total, current;
  const _ProgressRow({required this.total, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ...List.generate(total, (i) {
          final done   = i < current;
          final active = i == current;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: active ? 22 : 8, height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: done
                  ? const Color(0xFF22C55E)
                  : active
                      ? const Color(0xFFFFD600)
                      : const Color(0xFF1E1E1E),
            ),
          );
        }),
        if (total > 1) ...[
          const SizedBox(width: 12),
          Text('${current + 1} / $total',
            style: const TextStyle(color: Color(0xFF404040),
                fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ],
    );
  }
}
