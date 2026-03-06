import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MissionCard extends StatefulWidget {
  final List<String> assignedMissions;
  final bool wakeUpCheckEnabled;
  final ValueChanged<List<String>> onMissionsChanged;
  final ValueChanged<bool> onWakeUpCheckChanged;

  const MissionCard({
    super.key,
    required this.assignedMissions,
    required this.wakeUpCheckEnabled,
    required this.onMissionsChanged,
    required this.onWakeUpCheckChanged,
  });

  @override
  State<MissionCard> createState() => _MissionCardState();
}

class _MissionCardState extends State<MissionCard> {
  late List<String> _localMissions;
  late bool _localWakeUpCheck;

  @override
  void initState() {
    super.initState();
    _localMissions = List<String>.from(widget.assignedMissions);
    // Ensure we have at least 4 slots for UI rendering
    while (_localMissions.length < 4) {
      _localMissions.add('');
    }
    _localWakeUpCheck = widget.wakeUpCheckEnabled;
  }

  void _onMissionSlotTapped(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      if (index < _localMissions.length && _localMissions[index].isNotEmpty) {
        _localMissions[index] = '';
      } else {
        // Placeholder for now
        _localMissions[index] = 'mission_${index + 1}';
      }
    });
    widget.onMissionsChanged(_localMissions.where((m) => m.isNotEmpty).toList());
  }

  void _toggleWakeUpCheck() {
    HapticFeedback.mediumImpact();
    setState(() {
      _localWakeUpCheck = !_localWakeUpCheck;
    });
    widget.onWakeUpCheckChanged(_localWakeUpCheck);
  }

  int get _completedCount => _localMissions.where((m) => m.isNotEmpty).length;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - value)),
          child: child,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF2E2E2E), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              offset: const Offset(0, 4),
              blurRadius: 20,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Row 1: Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Wake-up mission',
                  style: TextStyle(
                    color: Color(0xFFF5F5F5),
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                      child: Text(
                        '$_completedCount',
                        key: ValueKey(_completedCount),
                        style: const TextStyle(
                          color: Color(0xFFFFD600),
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Text(
                      '/5',
                      style: TextStyle(
                        color: Color(0xFF505050),
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Row 2: Slots
            LayoutBuilder(
              builder: (context, constraints) {
                const gaps = 3 * 10.0;
                final btnSize = (constraints.maxWidth - gaps) / 4;
                final size = btnSize.clamp(64.0, 88.0);

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(4, (i) {
                    final isAssigned = i < _localMissions.length && _localMissions[i].isNotEmpty;
                    return _MissionSlotButton(
                      index: i,
                      isAssigned: isAssigned,
                      onTap: () => _onMissionSlotTapped(i),
                      size: size,
                    );
                  }),
                );
              },
            ),
            const SizedBox(height: 12),
            const Divider(color: Color(0xFF2A2A2A), thickness: 1),
            const SizedBox(height: 12),

            // Row 3: Wake up check
            _buildWakeUpCheckRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildWakeUpCheckRow() {
    return Row(
      children: [
        const Icon(Icons.lock_rounded, size: 16, color: Color(0xFF606060)),
        const SizedBox(width: 8),
        const Text(
          'Wake up check',
          style: TextStyle(
            color: Color(0xFFE0E0E0),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFF3D1515),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.4), width: 1),
          ),
          child: const Text(
            'HOT',
            style: TextStyle(
              color: Color(0xFFEF4444),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: _toggleWakeUpCheck,
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _localWakeUpCheck ? 'On' : 'Off',
                style: TextStyle(
                  color: _localWakeUpCheck ? const Color(0xFF14B8A6) : const Color(0xFF606060),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF505050)),
            ],
          ),
        ),
      ],
    );
  }
}

class _MissionSlotButton extends StatefulWidget {
  final int index;
  final bool isAssigned;
  final VoidCallback onTap;
  final double size;

  const _MissionSlotButton({
    required this.index,
    required this.isAssigned,
    required this.onTap,
    required this.size,
  });

  @override
  State<_MissionSlotButton> createState() => _MissionSlotButtonState();
}

class _MissionSlotButtonState extends State<_MissionSlotButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.90).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() async {
    await _controller.forward();
    _controller.reverse();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    // Special styling for first slot if empty
    final isFirstEmpty = widget.index == 0 && !widget.isAssigned;

    return GestureDetector(
      onTap: _handleTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.isAssigned
                ? const Color(0xFF1A3A35)
                : (isFirstEmpty ? const Color(0xFF2A2A2A) : const Color(0xFF252525)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.isAssigned
                  ? const Color(0xFF14B8A6)
                  : (isFirstEmpty ? const Color(0xFF3A3A3A) : const Color(0xFF333333)),
              width: 1.5,
            ),
          ),
          child: Center(
            child: widget.isAssigned
                ? const Icon(Icons.check_circle_rounded, color: Color(0xFF14B8A6), size: 28)
                : Icon(
                    Icons.add_rounded,
                    size: 24,
                    color: isFirstEmpty ? const Color(0xFF808080) : const Color(0xFF505050),
                  ),
          ),
        ),
      ),
    );
  }
}
