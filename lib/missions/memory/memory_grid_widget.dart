import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum TileState { normal, highlighted, selected, correct, wrong }

class MemoryGridWidget extends StatelessWidget {
  final List<TileState>        tileStates;  // must have exactly 25 items
  final void Function(int)?    onTileTap;
  final bool                   interactive;

  const MemoryGridWidget({
    super.key,
    required this.tileStates,
    this.onTileTap,
    this.interactive = true,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size    = constraints.maxWidth;
      final gap     = size * 0.025;
      final tileSize = (size - gap * 4) / 5;
      return SizedBox(
        width: size, height: size,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount:    5,
            crossAxisSpacing:  gap,
            mainAxisSpacing:   gap,
          ),
          itemCount: 25,
          itemBuilder: (_, i) => _Tile(
            state: tileStates[i],
            size:  tileSize,
            onTap: interactive ? () => onTileTap?.call(i) : null,
          ),
        ),
      );
    });
  }
}

class _Tile extends StatefulWidget {
  final TileState     state;
  final double        size;
  final VoidCallback? onTap;
  const _Tile({required this.state, required this.size, this.onTap});

  @override
  State<_Tile> createState() => _TileState();
}

class _TileState extends State<_Tile> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 110));
    _scale = Tween<double>(begin: 1.0, end: 0.86)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _tap() {
    if (widget.onTap == null) return;
    HapticFeedback.lightImpact();
    _ctrl.forward().then((_) => _ctrl.reverse());
    widget.onTap!();
  }

  Color get _color {
    switch (widget.state) {
      case TileState.highlighted: return const Color(0xFFFFD600);
      case TileState.selected:    return const Color(0xFF14B8A6);
      case TileState.correct:     return const Color(0xFF22C55E);
      case TileState.wrong:       return const Color(0xFFEF4444);
      case TileState.normal:      return const Color(0xFF3A3A3A);
    }
  }

  List<BoxShadow>? get _shadow {
    if (widget.state == TileState.normal) return null;
    final Map<TileState, Color> glows = {
      TileState.highlighted: const Color(0xFFFFD600),
      TileState.selected:    const Color(0xFF14B8A6),
      TileState.correct:     const Color(0xFF22C55E),
      TileState.wrong:       const Color(0xFFEF4444),
    };
    return [BoxShadow(
      color: (glows[widget.state] ?? Colors.transparent).withValues(alpha: 0.45),
      blurRadius: 10, spreadRadius: 1,
    )];
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _tap,
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color:        _color,
            borderRadius: BorderRadius.circular(10),
            boxShadow:    _shadow,
          ),
        ),
      ),
    );
  }
}
