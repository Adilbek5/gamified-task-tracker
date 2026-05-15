import 'package:flutter/material.dart';

enum UserRole { teamLead, teamMember }

enum SkillLevel { junior, middle, senior }

class UserModel {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String? teamId;
  final int xp;
  final int level;
  final int coins;
  final String equippedAvatarId;
  final String equippedBorderId;
  final String equippedBadgeId;
  final SkillLevel skillLevel;
  final int streakDays;
  final String lastActiveDate;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.role = UserRole.teamMember,
    this.teamId,
    this.xp = 0,
    this.level = 1,
    this.coins = 0,
    this.equippedAvatarId = 'avatar_default',
    this.equippedBorderId = 'border_none',
    this.equippedBadgeId = 'badge_none',
    this.skillLevel = SkillLevel.junior,
    this.streakDays = 0,
    this.lastActiveDate = '',
  });

  bool get isTeamLead => role == UserRole.teamLead;
  bool get canCreateTasks => isTeamLead;
  bool get hasTeam => teamId != null && teamId!.isNotEmpty;

  String get roleLabel =>
      isTeamLead ? 'Team Lead' : 'Team Member';
  String get roleEmoji => isTeamLead ? '🎯' : '👥';

  String get avatarEmoji {
    if (level >= 10) return '🧙';
    if (level >= 5) return '🧑‍💻';
    return '👶';
  }

  String get avatarTitle {
    if (level >= 10) return 'Code Wizard';
    if (level >= 5) return 'Code Knight';
    return 'Code Apprentice';
  }

  String get skillLabel {
    switch (skillLevel) {
      case SkillLevel.junior: return 'Junior';
      case SkillLevel.middle: return 'Middle';
      case SkillLevel.senior: return 'Senior';
    }
  }

  Color get skillColor {
    switch (skillLevel) {
      case SkillLevel.junior: return const Color(0xFF22C55E);
      case SkillLevel.middle: return const Color(0xFF3580FF);
      case SkillLevel.senior: return const Color(0xFFFFD700);
    }
  }

  String get skillEmoji {
    switch (skillLevel) {
      case SkillLevel.junior: return '🌱';
      case SkillLevel.middle: return '⚡';
      case SkillLevel.senior: return '🔥';
    }
  }

  double get xpMultiplier {
    switch (skillLevel) {
      case SkillLevel.junior: return 1.0;
      case SkillLevel.middle: return 1.25;
      case SkillLevel.senior: return 1.5;
    }
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    UserRole? role,
    String? teamId,
    int? xp,
    int? level,
    int? coins,
    String? equippedAvatarId,
    String? equippedBorderId,
    String? equippedBadgeId,
    SkillLevel? skillLevel,
    int? streakDays,
    String? lastActiveDate,
  }) =>
      UserModel(
        id: id ?? this.id,
        email: email ?? this.email,
        name: name ?? this.name,
        role: role ?? this.role,
        teamId: teamId ?? this.teamId,
        xp: xp ?? this.xp,
        level: level ?? this.level,
        coins: coins ?? this.coins,
        equippedAvatarId: equippedAvatarId ?? this.equippedAvatarId,
        equippedBorderId: equippedBorderId ?? this.equippedBorderId,
        equippedBadgeId: equippedBadgeId ?? this.equippedBadgeId,
        skillLevel: skillLevel ?? this.skillLevel,
        streakDays: streakDays ?? this.streakDays,
        lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      );

  Map<String, dynamic> toMap() => {
    'id': id,
    'email': email,
    'name': name,
    'role': role.name,
    'team_id': teamId ?? '',
    'xp': xp,
    'level': level,
    'coins': coins,
    'equipped_avatar_id': equippedAvatarId,
    'equipped_border_id': equippedBorderId,
    'equipped_badge_id': equippedBadgeId,
    'skill_level': skillLevel.name,
    'streak_days': streakDays,
    'last_active_date': lastActiveDate,
  };

  factory UserModel.fromMap(Map<String, dynamic> m) =>
      UserModel(
        id: m['id'],
        email: m['email'],
        name: m['name'],
        role: UserRole.values.firstWhere(
              (e) => e.name == m['role'],
          orElse: () => UserRole.teamMember,
        ),
        teamId: m['team_id'] ?? '',
        xp: m['xp'] ?? 0,
        level: m['level'] ?? 1,
        coins: m['coins'] ?? 0,
        equippedAvatarId: m['equipped_avatar_id'] as String? ?? 'avatar_default',
        equippedBorderId: m['equipped_border_id'] as String? ?? 'border_none',
        equippedBadgeId: m['equipped_badge_id'] as String? ?? 'badge_none',
        skillLevel: SkillLevel.values.firstWhere(
          (e) => e.name == (m['skill_level'] ?? 'junior'),
          orElse: () => SkillLevel.junior,
        ),
        streakDays: m['streak_days'] as int? ?? 0,
        lastActiveDate: m['last_active_date'] as String? ?? '',
      );
}
