import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/mission_type.dart';

class MissionPickerSheet extends StatefulWidget {
  final List<MissionType> alreadySelected;

  const MissionPickerSheet({
    super.key,
    this.alreadySelected = const [],
  });

  @override
  State<MissionPickerSheet> createState() => _MissionPickerSheetState();
}

class _MissionPickerSheetState extends State<MissionPickerSheet>
    with SingleTickerProviderStateMixin {

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // Group missions by category
  Map<String, List<MissionType>> get _grouped {
    final map = <String, List<MissionType>>{};
    for (final m in allMissions) {
      map.putIfAbsent(m.category, () => []).add(m);
    }
    return map;
  }

  String _categoryLabel(String key) {
    switch (key) {
      case 'popular': return 'Popular mission';
      case 'brain':   return 'Wake your brain';
      case 'body':    return 'Wake your body';
      default:        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['popular', 'brain', 'body'];

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Color(0xFF161616),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF3A3A3A),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
                child: Row(
                  children: [
                    const Text(
                      'Mission',
                      style: TextStyle(
                        color: Color(0xFFF5F5F5),
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Color(0xFFA0A0A0),
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Mission list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  itemCount: categories.length,
                  itemBuilder: (context, catIndex) {
                    final cat = categories[catIndex];
                    final missions = _grouped[cat] ?? [];
                    if (missions.isEmpty) return const SizedBox();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category label
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 20, bottom: 12),
                          child: Text(
                            _categoryLabel(cat),
                            style: const TextStyle(
                              color: Color(0xFF808080),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),

                        // Mission items
                        ...missions.map((mission) =>
                          _MissionListItem(
                            mission: mission,
                            isSelected: widget.alreadySelected
                                .any((s) => s.id == mission.id),
                            onTap: () {
                              if (mission.isPro) {
                                _showProDialog();
                                return;
                              }
                              HapticFeedback.lightImpact();
                              Navigator.pop(context, mission);
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Footer
              const Padding(
                padding: EdgeInsets.only(bottom: 32, top: 8),
                child: Text(
                  'More missions are in the works',
                  style: TextStyle(
                    color: Color(0xFF505050),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProDialog() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('PRO Feature',
          style: TextStyle(color: Color(0xFFF5F5F5))),
        content: const Text(
          'Upgrade to PRO to unlock this mission.',
          style: TextStyle(color: Color(0xFFA0A0A0)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later',
              style: TextStyle(color: Color(0xFFA0A0A0))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Upgrade',
              style: TextStyle(color: Color(0xFF14B8A6))),
          ),
        ],
      ),
    );
  }
}

// ── Individual mission row ─────────────────────────────────

class _MissionListItem extends StatelessWidget {
  final MissionType mission;
  final bool isSelected;
  final VoidCallback onTap;

  const _MissionListItem({
    required this.mission,
    required this.isSelected,
    required this.onTap,
  });

  Widget _badge() {
    switch (mission.badge) {
      case MissionBadge.ai:
        return _pill('AI', const Color(0xFFB8860B),
            const Color(0xFF3D2E00));
      case MissionBadge.best:
        return _pill('BEST', const Color(0xFFFFD600),
            const Color(0xFF3D3400));
      case MissionBadge.hot:
        return _pill('HOT', const Color(0xFFEF4444),
            const Color(0xFF3D0F0F));
      case MissionBadge.none:
        return const SizedBox.shrink();
    }
  }

  Widget _pill(String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: textColor.withOpacity(0.4), width: 1),
      ),
      child: Text(text,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF1A2E2C)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(
                    color: const Color(0xFF14B8A6).withOpacity(0.4),
                    width: 1)
                : null,
          ),
          child: Row(
            children: [
              // Icon container
              Stack(
                children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: mission.iconBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(mission.icon,
                      color: Colors.white, size: 26),
                  ),
                  // PRO lock badge
                  if (mission.isPro)
                    Positioned(
                      bottom: -2, right: -2,
                      child: Container(
                        width: 20, height: 20,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF3A3A3A), width: 1),
                        ),
                        child: const Icon(Icons.lock_rounded,
                          color: Color(0xFFA0A0A0), size: 11),
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 14),

              // Name + badge
              Expanded(
                child: Row(
                  children: [
                    Text(mission.name,
                      style: TextStyle(
                        color: mission.isPro
                            ? const Color(0xFF808080)
                            : const Color(0xFFF5F5F5),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (mission.badge != MissionBadge.none) ...[
                      const SizedBox(width: 8),
                      _badge(),
                    ],
                  ],
                ),
              ),

              // Chevron or selected check
              if (isSelected)
                const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF14B8A6), size: 20)
              else
                Icon(
                  mission.isPro
                      ? Icons.lock_outline_rounded
                      : Icons.chevron_right_rounded,
                  color: const Color(0xFF505050),
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
