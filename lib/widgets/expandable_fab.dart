import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

typedef FabActionCallback = Future<void> Function();

class ExpandableFab extends StatefulWidget {
  const ExpandableFab({
    super.key,
    required this.onAlarm,
    required this.onQuickAlarm,
  });

  final FabActionCallback onAlarm;
  final FabActionCallback onQuickAlarm;

  @override
  State<ExpandableFab> createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<ExpandableFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _rotation;
  late final Animation<double> _overlayOpacity;
  late final Animation<double> _alarmScale;
  late final Animation<double> _quickScale;

  bool _open = false;
  bool _isAnimating = false;
  bool _isTransitioning = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _rotation = Tween<double>(begin: 0, end: 0.125).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _overlayOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _alarmScale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
    );
    _quickScale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutBack),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        setState(() {
          _isAnimating = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_isAnimating || _isTransitioning) return;
    setState(() {
      _isAnimating = true;
      _open = !_open;
    });
    HapticFeedback.mediumImpact(); // More pronounced impact for primary action
    if (_open) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  Future<void> _handleAction(FabActionCallback action) async {
    if (_isAnimating || _isTransitioning) return;
    setState(() {
      _isTransitioning = true;
    });
    
    // Immediate haptic feedback (success pattern-like)
    await HapticFeedback.vibrate();
    
    await action();
    
    // Close menu and reset states
    _open = false;
    await _controller.reverse();
    
    setState(() {
      _isTransitioning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return Stack(
      children: [
        if (_open)
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggle,
              behavior: HitTestBehavior.opaque,
              child: FadeTransition(
                opacity: _overlayOpacity,
                child: Container(
                  color: Colors.black.withOpacity(0.4),
                ),
              ),
            ),
          ),
        Positioned(
          right: 24 + media.padding.right,
          bottom: 24 + media.padding.bottom + 56, // above bottom nav
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _ActionButton(
                label: 'Alarm',
                color: ElevateTheme.warning,
                scale: _alarmScale,
                visible: _open,
                icon: Icons.alarm_rounded,
                onTap: () => _handleAction(widget.onAlarm),
              ),
              const SizedBox(height: 16),
              _ActionButton(
                label: 'Quick alarm',
                color: ElevateTheme.quick,
                scale: _quickScale,
                visible: _open,
                icon: Icons.bolt_rounded,
                onTap: () => _handleAction(widget.onQuickAlarm),
              ),
              const SizedBox(height: 20),
              _PrimaryFab(
                rotation: _rotation,
                open: _open,
                onPressed: _toggle,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PrimaryFab extends StatelessWidget {
  const _PrimaryFab({
    required this.rotation,
    required this.open,
    required this.onPressed,
  });

  final Animation<double> rotation;
  final bool open;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: rotation,
      builder: (context, child) {
        return Transform.rotate(
          angle: rotation.value * 3.1415926535 * 2,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: (_) => HapticFeedback.lightImpact(),
        child: AnimatedScale(
          scale: open ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: FloatingActionButton(
            onPressed: onPressed,
            backgroundColor: ElevateTheme.primaryAccent,
            elevation: 8,
            child: const Icon(
              Icons.add,
              size: 28,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.color,
    required this.scale,
    required this.visible,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final Color color;
  final Animation<double> scale;
  final bool visible;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FadeTransition(
      opacity: scale,
      child: ScaleTransition(
        scale: scale,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (visible)
              Flexible(
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  constraints: const BoxConstraints(maxWidth: 160),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: ElevateTheme.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            GestureDetector(
              onTap: onTap,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

