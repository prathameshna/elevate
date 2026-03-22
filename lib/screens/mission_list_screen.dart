import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── Mission definition ─────────────────────────────────────

class MissionDefinition {
  final String   id;
  final String   name;
  final IconData icon;
  final Color    iconBgColor;
  final String?  badge;      // 'AI' | 'HOT' | 'BEST' | 'PRO' | null
  final Color?   badgeColor;
  final bool     isLocked;   // true = coming soon / PRO
  final bool     isBuilt;    // true = has a real challenge screen

  const MissionDefinition({
    required this.id,
    required this.name,
    required this.icon,
    required this.iconBgColor,
    this.badge,
    this.badgeColor,
    this.isLocked = false,
    this.isBuilt  = false,
  });
}

const List<MissionDefinition> kAllMissions = [
  // ── Wake your brain ────────────────────────────────────
  MissionDefinition(
    id:           'colour_tiles',
    name:         'Find Colour Tiles',
    icon:         Icons.grid_view_rounded,
    iconBgColor:  Color(0xFF0D5C63),
    isLocked:     false,
    isBuilt:      true,
  ),
  MissionDefinition(
    id:           'typing',
    name:         'Typing',
    icon:         Icons.keyboard_rounded,
    iconBgColor:  Color(0xFF6366F1),
    isLocked:     false,
    isBuilt:      true,
  ),
];

// ── Mission List Screen ────────────────────────────────────

class MissionListScreen extends StatelessWidget {
  const MissionListScreen({super.key});

  // Returns MissionDefinition when user picks one
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
        title: const Text('Mission',
          style: TextStyle(
            color:      Color(0xFFF0F0F0),
            fontSize:   18,
            fontWeight: FontWeight.w700,
          )),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [

          // ── Wake your brain ───────────────────────
          const _SectionHeader('Wake your brain'),
          ..._missionsWhere((m) => m.id == 'colour_tiles' || m.id == 'typing', context),

          const SizedBox(height: 32),

          // Footer
          const Center(
            child: Text(
              'More missions are in the works',
              style: TextStyle(
                color:    Color(0xFF404040),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _missionsWhere(
    bool Function(MissionDefinition) test,
    BuildContext context,
  ) {
    return kAllMissions
        .where(test)
        .map((m) => _MissionTile(
              mission: m,
              onTap:   () => _onMissionTap(context, m),
            ))
        .toList();
  }

  void _onMissionTap(BuildContext context, MissionDefinition mission) {
    if (mission.isLocked) {
      // Show coming soon snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${mission.name} is coming soon!',
            style: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFFFFD600),
          behavior:        SnackBarBehavior.floating,
          duration:        const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    // Return selected mission to edit alarm screen
    HapticFeedback.mediumImpact();
    Navigator.pop(context, mission);
  }
}

// ── Sub-widgets ────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(text,
      style: const TextStyle(
        color:    Color(0xFF606060),
        fontSize: 13,
        fontWeight: FontWeight.w500,
      )),
  );
}

class _MissionTile extends StatelessWidget {
  final MissionDefinition mission;
  final VoidCallback       onTap;

  const _MissionTile({required this.mission, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        color: Colors.transparent,
        child: Row(children: [

          // Mission icon
          Stack(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color:        mission.iconBgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(mission.icon,
                    color: Colors.white, size: 26),
              ),
              // Lock badge for locked missions
              if (mission.isLocked)
                Positioned(
                  right: 0, bottom: 0,
                  child: Container(
                    width: 18, height: 18,
                    decoration: BoxDecoration(
                      color:        const Color(0xFF333333),
                      shape:        BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFF0D0D0D), width: 2),
                    ),
                    child: const Icon(Icons.lock_rounded,
                        color: Colors.white, size: 9),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),

          // Name + badge
          Expanded(
            child: Row(children: [
              Text(mission.name,
                style: TextStyle(
                  color: mission.isLocked
                      ? const Color(0xFF888888)
                      : const Color(0xFFF0F0F0),
                  fontSize:   16,
                  fontWeight: FontWeight.w600,
                )),
              if (mission.badge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: mission.badgeColor?.withValues(alpha: 0.25)
                        ?? const Color(0xFF333333),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: mission.badgeColor?.withValues(alpha: 0.5)
                          ?? const Color(0xFF444444),
                    ),
                  ),
                  child: Text(mission.badge!,
                    style: TextStyle(
                      color:       mission.badgeColor ?? Colors.white,
                      fontSize:    10,
                      fontWeight:  FontWeight.w800,
                      letterSpacing: 0.5,
                    )),
                ),
              ],
            ]),
          ),

          // Arrow
          Icon(
            Icons.chevron_right_rounded,
            color: mission.isLocked
                ? const Color(0xFF333333)
                : const Color(0xFF505050),
            size: 22,
          ),
        ]),
      ),
    );
  }
}
