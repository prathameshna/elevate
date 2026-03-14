import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'memory_mission_model.dart';
import 'memory_grid_widget.dart';

class MemoryChallengeScreen extends StatefulWidget {
  final MemoryMissionConfig config;
  final VoidCallback        onComplete; // call when all questions solved

  const MemoryChallengeScreen({
    super.key,
    required this.config,
    required this.onComplete,
  });

  @override
  State<MemoryChallengeScreen> createState() =>
      _MemoryChallengeScreenState();
}

class _MemoryChallengeScreenState
    extends State<MemoryChallengeScreen> with TickerProviderStateMixin {

  int              _qIndex    = 0;
  late MemoryQuestion _q;
  List<int>        _tapped    = [];
  List<TileState>  _states    = List.filled(25, TileState.normal);
  String           _phase     = 'memorise'; // memorise | recall | feedback
  int              _countdown = 0;

  Timer? _timer;

  late AnimationController _shakeCtrl;
  late Animation<Offset>   _shakeAnim;
  late AnimationController _successCtrl;
  late Animation<double>   _successScale;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _shakeAnim = TweenSequence([
      TweenSequenceItem(
          tween: Tween(begin: Offset.zero, end: const Offset(-0.03, 0)),
          weight: 1),
      TweenSequenceItem(
          tween: Tween(
              begin: const Offset(-0.03, 0), end: const Offset(0.03, 0)),
          weight: 2),
      TweenSequenceItem(
          tween: Tween(begin: const Offset(0.03, 0), end: Offset.zero),
          weight: 1),
    ]).animate(CurvedAnimation(
        parent: _shakeCtrl, curve: Curves.easeInOut));

    _successCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _successScale = Tween<double>(begin: 0.92, end: 1.0).animate(
        CurvedAnimation(parent: _successCtrl, curve: Curves.elasticOut));

    _loadQuestion();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _shakeCtrl.dispose();
    _successCtrl.dispose();
    super.dispose();
  }

  void _loadQuestion() {
    _q         = MemoryQuestion.generate(widget.config.tilesToMemorize);
    _tapped    = [];
    _phase     = 'memorise';
    _countdown = (widget.config.memorizeDurationMs / 1000).ceil();

    setState(() {
      _states = List.generate(25, (i) =>
          _q.highlightedIndices.contains(i)
              ? TileState.highlighted : TileState.normal);
    });

    // Countdown ticker
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _countdown = (_countdown - 1).clamp(0, 99));
      if (_countdown <= 0) t.cancel();
    });

    // Hide tiles after duration
    _timer = Timer(
      Duration(milliseconds: widget.config.memorizeDurationMs),
      _goToRecall,
    );
  }

  void _goToRecall() {
    if (!mounted) return;
    setState(() {
      _phase   = 'recall';
      _states  = List.filled(25, TileState.normal);
      _countdown = 0;
    });
  }

  void _tapTile(int i) {
    if (_phase != 'recall') return;
    HapticFeedback.lightImpact();
    setState(() {
      if (_tapped.contains(i)) {
        _tapped.remove(i);
        _states[i] = TileState.normal;
      } else {
        _tapped.add(i);
        _states[i] = TileState.selected;
      }
    });
  }

  void _submit() {
    if (_phase != 'recall') return;
    final needed = _q.highlightedIndices.length;
    if (_tapped.length != needed) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Select $needed tiles',
            style: const TextStyle(color: Colors.black,
                fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFFFFD600),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1200),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      ));
      return;
    }
    _phase = 'feedback';
    _q.isCorrect(_tapped) ? _correct() : _wrong();
  }

  void _correct() {
    HapticFeedback.heavyImpact();
    _successCtrl.forward(from: 0);
    setState(() {
      _states = List.generate(25, (i) =>
          _q.highlightedIndices.contains(i)
              ? TileState.correct : TileState.normal);
    });
    _timer = Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      if (_qIndex + 1 >= widget.config.questionCount) {
        widget.onComplete();
      } else {
        setState(() => _qIndex++);
        _loadQuestion();
      }
    });
  }

  void _wrong() {
    HapticFeedback.vibrate();
    _shakeCtrl.forward(from: 0);
    setState(() {
      _states = List.generate(25, (i) {
        final isAnswer = _q.highlightedIndices.contains(i);
        final wasTapped = _tapped.contains(i);
        if (isAnswer && wasTapped)  return TileState.correct;
        if (!isAnswer && wasTapped) return TileState.wrong;
        if (isAnswer)               return TileState.highlighted;
        return TileState.normal;
      });
    });

    // Re-show tiles briefly for retry
    _timer = Timer(const Duration(milliseconds: 1100), () {
      if (!mounted) return;
      setState(() {
        _tapped    = [];
        _countdown = 2;
        _phase     = 'memorise';
        _states    = List.generate(25, (i) =>
            _q.highlightedIndices.contains(i)
                ? TileState.highlighted : TileState.normal);
      });
      _timer = Timer(const Duration(milliseconds: 2000), _goToRecall);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // must complete mission to go back
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0D0D),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              _buildProgressBar(),
              const SizedBox(height: 22),
              _buildPhaseText(),
              const SizedBox(height: 18),
              Expanded(
                child: Center(
                  child: SlideTransition(
                    position: _shakeAnim,
                    child: ScaleTransition(
                      scale: _successScale,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: MemoryGridWidget(
                          tileStates:  _states,
                          interactive: _phase == 'recall',
                          onTileTap:   _tapTile,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildBottomBar(),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Row(
      children: [
        ...List.generate(widget.config.questionCount, (i) {
          final done    = i < _qIndex;
          final current = i == _qIndex;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(right: 5),
            width:  current ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: done
                  ? const Color(0xFF22C55E)
                  : current
                      ? const Color(0xFFFFD600)
                      : const Color(0xFF2A2A2A),
            ),
          );
        }),
        const Spacer(),
        Text(
          '${_qIndex + 1} / ${widget.config.questionCount}',
          style: const TextStyle(color: Color(0xFF505050),
              fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildPhaseText() {
    String text;
    Color  color;
    if (_phase == 'memorise') {
      text  = 'Memorise the tiles';
      color = const Color(0xFFF5F5F5);
    } else if (_phase == 'recall') {
      text  = 'Tap the tiles you remember';
      color = const Color(0xFFF5F5F5);
    } else if (_q.isCorrect(_tapped)) {
      text  = '✓ Correct!';
      color = const Color(0xFF22C55E);
    } else {
      text  = '✗ Try again';
      color = const Color(0xFFEF4444);
    }

    return Column(children: [
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: Text(text,
          key: ValueKey(text),
          textAlign: TextAlign.center,
          style: TextStyle(color: color, fontSize: 21,
              fontWeight: FontWeight.w700),
        ),
      ),
      if (_phase == 'memorise' && _countdown > 0) ...[
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text('$_countdown',
            key: ValueKey(_countdown),
            style: const TextStyle(color: Color(0xFFFFD600),
                fontSize: 38, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ]);
  }

  Widget _buildBottomBar() {
    if (_phase != 'recall') {
      return const SizedBox(height: 56);
    }
    final needed  = _q.highlightedIndices.length;
    final ready   = _tapped.length == needed;

    return Column(children: [
      Text(
        '${_tapped.length} / $needed selected',
        style: TextStyle(
          color: ready
              ? const Color(0xFF22C55E)
              : const Color(0xFF505050),
          fontSize: 13, fontWeight: FontWeight.w500,
        ),
      ),
      const SizedBox(height: 10),
      SizedBox(
        width: double.infinity, height: 52,
        child: ElevatedButton(
          onPressed: ready ? _submit : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: ready
                ? const Color(0xFFFFD600)
                : const Color(0xFF1C1C1C),
            foregroundColor: Colors.black,
            disabledBackgroundColor: const Color(0xFF1C1C1C),
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          child: Text('Submit',
            style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700,
              color: ready ? Colors.black : const Color(0xFF383838),
            )),
        ),
      ),
    ]);
  }
}
