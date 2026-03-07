import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/mission_type.dart';
import 'mission_picker_sheet.dart';

class MissionCard extends StatefulWidget {
  final List<MissionType> assignedMissions;
  final bool wakeUpCheckEnabled;
  final ValueChanged<List<MissionType>> onMissionsChanged;
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
  late List<MissionType?> _assignedMissions;
  late bool _localWakeUpCheck;

  @override
  void initState() {
    super.initState();
    _assignedMissions = List<MissionType?>.from(widget.assignedMissions);
    // Ensure we have at least 4 slots for UI rendering
    while (_assignedMissions.length < 4) {
      _assignedMissions.add(null);
    }
    _localWakeUpCheck = widget.wakeUpCheckEnabled;
  }

  void _onMissionSlotTapped(int slotIndex) async {
    HapticFeedback.lightImpact();

    // Open mission picker bottom sheet
    final MissionType? selected = await showModalBottomSheet<MissionType>(
      context: context,
      isScrollControlled: true, // full height
      backgroundColor: Colors.transparent,
      builder: (_) => MissionPickerSheet(
        alreadySelected: _assignedMissions
            .where((m) => m != null)
            .cast<MissionType>()
            .toList(),
      ),
    );

    if (selected == null) return; // user dismissed

    setState(() {
      // Expand list if needed (though we keep it at 4 normally)
      while (_assignedMissions.length <= slotIndex) {
        _assignedMissions.add(null);
      }
      _assignedMissions[slotIndex] = selected;
    });

    widget.onMissionsChanged(
      _assignedMissions.whereType<MissionType>().toList(),
    );
  }

  void _removeMission(int index) {
    HapticFeedback.mediumImpact();
    setState(() => _assignedMissions[index] = null);
    widget.onMissionsChanged(
      _assignedMissions.whereType<MissionType>().toList(),
    );
  }

  void _toggleWakeUpCheck() {
    HapticFeedback.mediumImpact();
    setState(() {
      _localWakeUpCheck = !_localWakeUpCheck;
    });
    widget.onWakeUpCheckChanged(_localWakeUpCheck);
  }

  int get _completedCount => _assignedMissions.where((m) => m != null).length;

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
                  children: List.generate(4, (i) => _buildSlotButton(i, size)),
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

  Widget _buildSlotButton(int index, double size) {
    final mission = index < _assignedMissions.length ? _assignedMissions[index] : null;

    return GestureDetector(
      onTap: () => _onMissionSlotTapped(index),
      onLongPress: mission != null ? () => _removeMission(index) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: mission != null ? mission.iconBgColor.withOpacity(0.3) : const Color(0xFF252525),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: mission != null ? mission.iconBgColor.withOpacity(0.6) : const Color(0xFF333333),
            width: 1.5,
          ),
        ),
        child: mission != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(mission.icon, color: Colors.white, size: size * 0.38),
                  const SizedBox(height: 4),
                  Text(
                    mission.name.split(' ').first, // first word only
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              )
            : Icon(Icons.add_rounded, color: const Color(0xFF606060), size: size * 0.38),
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
