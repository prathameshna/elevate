import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AlarmToggle extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final double width;
  final double height;

  const AlarmToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.width = 56.0,
    this.height = 30.0,
  });

  @override
  State<AlarmToggle> createState() => _AlarmToggleState();
}

class _AlarmToggleState extends State<AlarmToggle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _thumbAnimation;
  late Animation<Color?> _trackColorAnimation;
  late Animation<double> _scaleAnimation;

  static const Color _activeTrack   = Color(0xFF14B8A6);
  static const Color _inactiveTrack = Color(0xFF2E3A47);
  static const Color _activeGlow    = Color(0x4014B8A6);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: widget.value ? 1.0 : 0.0,
    );
    _thumbAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _trackColorAnimation = ColorTween(
      begin: _inactiveTrack,
      end: _activeTrack,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _scaleAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.85), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.08), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(AlarmToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      widget.value ? _controller.forward() : _controller.reverse();
    }
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    final newValue = !widget.value;
    newValue ? _controller.forward() : _controller.reverse();
    widget.onChanged(newValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final thumbSize   = widget.height - 6.0;
    final thumbTravel = widget.width - thumbSize - 6.0;

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: _trackColorAnimation.value,
              borderRadius: BorderRadius.circular(widget.height / 2),
              boxShadow: [
                BoxShadow(
                  color: _activeGlow.withValues(
                    alpha: (_controller.value * 0.5).clamp(0.0, 0.5),
                  ),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Transform.translate(
                  offset: Offset(
                    3.0 + (_thumbAnimation.value * thumbTravel),
                    0,
                  ),
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      width: thumbSize,
                      height: thumbSize,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
