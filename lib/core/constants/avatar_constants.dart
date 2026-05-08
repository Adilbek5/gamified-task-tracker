import 'package:flutter/material.dart';

class AvatarData {
  final String id;
  final String name;
  final List<Color> gradient;
  final Color iconColor;
  final IconData icon;
  final int requiredLevel;
  final int price;
  final String description;

  const AvatarData({
    required this.id,
    required this.name,
    required this.gradient,
    required this.iconColor,
    required this.icon,
    required this.requiredLevel,
    required this.price,
    required this.description,
  });
}

class AvatarConstants {
  static const List<AvatarData> avatars = [
    AvatarData(
      id: 'avatar_default',
      name: 'Rookie',
      gradient: [Color(0xFF374151), Color(0xFF1F2937)],
      iconColor: Color(0xFF9CA3AF),
      icon: Icons.person_rounded,
      requiredLevel: 1,
      price: 0,
      description: 'Just getting started',
    ),
    AvatarData(
      id: 'avatar_coder',
      name: 'Code Dev',
      gradient: [Color(0xFF1D4ED8), Color(0xFF1E3A8A)],
      iconColor: Color(0xFF93C5FD),
      icon: Icons.code_rounded,
      requiredLevel: 2,
      price: 150,
      description: 'A real developer',
    ),
    AvatarData(
      id: 'avatar_knight',
      name: 'Code Knight',
      gradient: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
      iconColor: Color(0xFFC4B5FD),
      icon: Icons.shield_rounded,
      requiredLevel: 4,
      price: 350,
      description: 'Defender of clean code',
    ),
    AvatarData(
      id: 'avatar_hacker',
      name: 'Dark Hacker',
      gradient: [Color(0xFF064E3B), Color(0xFF022C22)],
      iconColor: Color(0xFF6EE7B7),
      icon: Icons.terminal_rounded,
      requiredLevel: 6,
      price: 600,
      description: 'In the shadows',
    ),
    AvatarData(
      id: 'avatar_wizard',
      name: 'Code Wizard',
      gradient: [Color(0xFF831843), Color(0xFF500724)],
      iconColor: Color(0xFFFBCFE8),
      icon: Icons.auto_awesome_rounded,
      requiredLevel: 8,
      price: 1000,
      description: 'Magic in every commit',
    ),
    AvatarData(
      id: 'avatar_robot',
      name: 'Cyber Bot',
      gradient: [Color(0xFF0C4A6E), Color(0xFF082F49)],
      iconColor: Color(0xFF7DD3FC),
      icon: Icons.smart_toy_rounded,
      requiredLevel: 10,
      price: 1500,
      description: 'Half human, half machine',
    ),
    AvatarData(
      id: 'avatar_ninja',
      name: 'Code Ninja',
      gradient: [Color(0xFF292524), Color(0xFF1C1917)],
      iconColor: Color(0xFFFF0000),
      icon: Icons.electric_bolt_rounded,
      requiredLevel: 12,
      price: 2000,
      description: 'Silent but deadly fast',
    ),
    AvatarData(
      id: 'avatar_galaxy',
      name: 'Galaxy Brain',
      gradient: [Color(0xFF1E1B4B), Color(0xFF312E81)],
      iconColor: Color(0xFFA5B4FC),
      icon: Icons.star_rounded,
      requiredLevel: 15,
      price: 3000,
      description: 'Thinking on a cosmic level',
    ),
  ];

  static AvatarData getById(String id) =>
      avatars.firstWhere((a) => a.id == id, orElse: () => avatars.first);
}

class BorderData {
  final String id;
  final String name;
  final Color color;
  final List<Color>? gradient;
  final double width;
  final int requiredLevel;
  final int price;

  const BorderData({
    required this.id,
    required this.name,
    required this.color,
    this.gradient,
    this.width = 3.0,
    required this.requiredLevel,
    required this.price,
  });
}

class BorderConstants {
  static const List<BorderData> borders = [
    BorderData(
      id: 'border_none',
      name: 'No Border',
      color: Colors.transparent,
      requiredLevel: 1,
      price: 0,
    ),
    BorderData(
      id: 'border_blue',
      name: 'Blue Ring',
      color: Color(0xFF3580FF),
      requiredLevel: 2,
      price: 100,
    ),
    BorderData(
      id: 'border_silver',
      name: 'Silver',
      color: Color(0xFF9CA3AF),
      requiredLevel: 3,
      price: 200,
    ),
    BorderData(
      id: 'border_gold',
      name: 'Gold',
      color: Color(0xFFFFD700),
      requiredLevel: 5,
      price: 450,
    ),
    BorderData(
      id: 'border_purple',
      name: 'Purple Glow',
      color: Color(0xFF8B5CF6),
      requiredLevel: 7,
      price: 700,
    ),
    BorderData(
      id: 'border_red',
      name: 'Fire Red',
      color: Color(0xFFEF4444),
      requiredLevel: 9,
      price: 900,
    ),
    BorderData(
      id: 'border_cyan',
      name: 'Neon Cyan',
      color: Color(0xFF06B6D4),
      requiredLevel: 11,
      price: 1200,
    ),
    BorderData(
      id: 'border_rainbow',
      name: 'Rainbow',
      color: Color(0xFFFF0080),
      gradient: [
        Color(0xFFFF0080),
        Color(0xFFFF6B00),
        Color(0xFFFFD700),
        Color(0xFF00FF80),
        Color(0xFF0080FF),
        Color(0xFF8000FF),
      ],
      requiredLevel: 15,
      price: 2500,
    ),
  ];

  static BorderData getById(String id) =>
      borders.firstWhere((b) => b.id == id, orElse: () => borders.first);
}

class BadgeData {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final int requiredLevel;
  final int price;
  final String description;

  const BadgeData({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.requiredLevel,
    required this.price,
    required this.description,
  });
}

class BadgeConstants {
  static const List<BadgeData> badges = [
    BadgeData(
      id: 'badge_none',
      name: 'No Badge',
      icon: Icons.remove,
      color: Colors.transparent,
      requiredLevel: 1,
      price: 0,
      description: 'Keep it clean',
    ),
    BadgeData(
      id: 'badge_fire',
      name: 'On Fire',
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFEF4444),
      requiredLevel: 1,
      price: 80,
      description: '5 tasks in one day',
    ),
    BadgeData(
      id: 'badge_lightning',
      name: 'Lightning',
      icon: Icons.electric_bolt_rounded,
      color: Color(0xFFFFD700),
      requiredLevel: 3,
      price: 200,
      description: 'Fastest completer',
    ),
    BadgeData(
      id: 'badge_crown',
      name: 'Crown',
      icon: Icons.workspace_premium_rounded,
      color: Color(0xFFFFD700),
      requiredLevel: 5,
      price: 500,
      description: 'Top of leaderboard',
    ),
    BadgeData(
      id: 'badge_diamond',
      name: 'Diamond',
      icon: Icons.diamond_rounded,
      color: Color(0xFF67E8F9),
      requiredLevel: 8,
      price: 800,
      description: 'Rare achiever',
    ),
    BadgeData(
      id: 'badge_skull',
      name: 'Terminator',
      icon: Icons.sports_score_rounded,
      color: Color(0xFFEF4444),
      requiredLevel: 12,
      price: 1500,
      description: 'Never stops',
    ),
    BadgeData(
      id: 'badge_infinity',
      name: 'Infinity',
      icon: Icons.all_inclusive_rounded,
      color: Color(0xFF8B5CF6),
      requiredLevel: 15,
      price: 2000,
      description: 'Beyond limits',
    ),
  ];

  static BadgeData getById(String id) =>
      badges.firstWhere((b) => b.id == id, orElse: () => badges.first);
}
