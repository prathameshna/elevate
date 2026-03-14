import 'package:flutter/material.dart';

enum MissionBadge { none, ai, best, hot }

class MissionType {
  final String id;
  final String name;
  final String category;      // 'popular' | 'brain' | 'body'
  final IconData icon;
  final Color iconBgColor;
  final MissionBadge badge;
  final bool isPro;           // true = requires premium

  const MissionType({
    required this.id,
    required this.name,
    required this.category,
    required this.icon,
    required this.iconBgColor,
    this.badge = MissionBadge.none,
    this.isPro = false,
  });
}

// All missions list
final List<MissionType> allMissions = [
  // ── Popular ──
  MissionType(
    id: 'household_hunt',
    name: 'Household Item Hunt',
    category: 'popular',
    icon: Icons.search_rounded,
    iconBgColor: const Color(0xFF8B1A1A),  // dark red
    badge: MissionBadge.ai,
  ),
  MissionType(
    id: 'tap_challenge',
    name: 'Tap Challenge',
    category: 'popular',
    icon: Icons.touch_app_rounded,
    iconBgColor: const Color(0xFF8B1A1A),  // dark red
  ),

  // ── Wake Your Brain ──
  MissionType(
    id: 'color_tiles',
    name: 'Find Color Tiles',
    category: 'brain',
    icon: Icons.grid_view_rounded,
    iconBgColor: const Color(0xFF0D5C63),  // dark teal
  ),
  MissionType(
    id: 'typing',
    name: 'Typing',
    category: 'brain',
    icon: Icons.keyboard_rounded,
    iconBgColor: const Color(0xFF0D5C63),  // dark teal
  ),
  MissionType(
    id: 'math',
    name: 'Math',
    category: 'brain',
    icon: Icons.calculate_rounded,
    iconBgColor: const Color(0xFF0D5C63),  // dark teal
    badge: MissionBadge.best,
  ),
  MissionType(
    id: 'memory',
    name: 'Memory',
    category: 'brain',
    icon: Icons.grid_on_rounded,
    iconBgColor: const Color(0xFF4A3080),  // purple
  ),

  // ── Wake Your Body ──
  MissionType(
    id: 'step',
    name: 'Step',
    category: 'body',
    icon: Icons.directions_walk_rounded,
    iconBgColor: const Color(0xFF6B1A8A),  // purple
    badge: MissionBadge.hot,
    isPro: true,
  ),
  MissionType(
    id: 'qr_barcode',
    name: 'QR/Barcode Scan',
    category: 'body',
    icon: Icons.qr_code_scanner_rounded,
    iconBgColor: const Color(0xFF5B2D8E),  // purple
    isPro: true,
  ),
  MissionType(
    id: 'shake',
    name: 'Shake',
    category: 'body',
    icon: Icons.vibration_rounded,
    iconBgColor: const Color(0xFFE07B20),  // orange
    isPro: true,
  ),
  MissionType(
    id: 'object_scan',
    name: 'Object Scan',
    category: 'body',
    icon: Icons.camera_alt_rounded,
    iconBgColor: const Color(0xFF0D7A6B),  // teal-green
    badge: MissionBadge.ai,
    isPro: true,
  ),
];
