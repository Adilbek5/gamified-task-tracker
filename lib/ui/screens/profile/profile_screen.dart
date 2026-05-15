import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../data/models/achievement_model.dart';
import '../../../data/models/task_model.dart';
import '../../../data/models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/gamification_provider.dart';
import '../../../providers/task_provider.dart';
import '../../../providers/team_provider.dart';
import '../../widgets/avatar_widget.dart';
import '../auth/login_screen.dart';
import '../auth/team_setup_screen.dart';
import '../settings/settings_screen.dart';
import '../shop/shop_screen.dart';
import '../tasks/task_list_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  final UserModel user;
  final GamificationProvider gam;

  const ProfileScreen(
      {super.key, required this.user, required this.gam});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final tasks = context.watch<TaskProvider>();
    final teamProv = context.watch<TeamProvider>();
    final team = teamProv.team;
    final user = auth.user ?? this.user;
    final gam = context.watch<GamificationProvider>();
    final xpFraction = gam.xpForNext > 0
        ? (gam.xpProgress / gam.xpForNext).clamp(0.0, 1.0)
        : 0.0;
    final inProgressCount = user.hasTeam
        ? teamProv.tasks
            .where((t) =>
                t.status == TaskStatus.pending ||
                t.status == TaskStatus.inProgress)
            .length
        : tasks.tasks
            .where((t) =>
                t.status == TaskStatus.pending ||
                t.status == TaskStatus.inProgress)
            .length;
    final completedCount = user.hasTeam
        ? teamProv.tasks
            .where((t) => t.status == TaskStatus.completed)
            .length
        : tasks.completedTasks.length;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0C16),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── TOP BAR ──
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                      },
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFF191D30),
                          borderRadius: BorderRadius.circular(21),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Profile',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 42, height: 42),
                  ],
                ),
              ),

              // ── PROFILE SECTION ──
              const SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    AvatarWidget(
                      avatarId: user.equippedAvatarId,
                      borderId: user.equippedBorderId,
                      badgeId: user.equippedBadgeId,
                      size: 90,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@${user.name.toLowerCase().replaceAll(' ', '.')}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Color(0xFF848A94),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                EditProfileScreen(user: user))),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: const Color(0xFF3580FF),
                              width: 1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Edit',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── LEVEL & XP CARD ──
              Container(
                margin: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: const Color(0xFF191D30),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(0xFF3580FF)
                            .withValues(alpha: 0.3),
                        width: 1)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(user.avatarEmoji,
                                style: const TextStyle(
                                    fontSize: 24)),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Level ${user.level}',
                                  style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight:
                                          FontWeight.w700)),
                                Text(
                                  user.avatarTitle,
                                  style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      color: Color(0xFF3580FF),
                                      fontSize: 13,
                                      fontWeight:
                                          FontWeight.w500)),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${user.xp} XP',
                              style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                            Text(
                              '${gam.xpForNext} to next level',
                              style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  color: Color(0xFF848A94),
                                  fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'XP Progress',
                              style: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: Color(0xFF848A94),
                                  fontSize: 11)),
                            Text(
                              '${(xpFraction * 100).toInt()}%',
                              style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  color: Color(0xFF3580FF),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: xpFraction,
                            minHeight: 8,
                            backgroundColor:
                                const Color(0xFF0A0C16),
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(
                                    Color(0xFF3580FF)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (user.role == UserRole.teamLead)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                                color: const Color(0xFFFFB800)
                                    .withValues(alpha: 0.15),
                                borderRadius:
                                    BorderRadius.circular(20),
                                border: Border.all(
                                    color: const Color(0xFFFFB800)
                                        .withValues(alpha: 0.5))),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('👑',
                                    style: TextStyle(fontSize: 12)),
                                SizedBox(width: 4),
                                Text(
                                  'Team Lead',
                                  style: TextStyle(
                                      fontFamily: 'Poppins',
                                      color: Color(0xFFFFB800),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600)),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                                color: _skillColor(user.skillLevel)
                                    .withValues(alpha: 0.15),
                                borderRadius:
                                    BorderRadius.circular(20),
                                border: Border.all(
                                    color: _skillColor(user.skillLevel)
                                        .withValues(alpha: 0.5))),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_skillEmoji(user.skillLevel),
                                    style: const TextStyle(
                                        fontSize: 12)),
                                const SizedBox(width: 4),
                                Text(
                                  _skillLabel(user.skillLevel),
                                  style: TextStyle(
                                      fontFamily: 'Poppins',
                                      color: _skillColor(
                                          user.skillLevel),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600)),
                                const SizedBox(width: 4),
                                if (user.role != UserRole.teamLead)
                                  Text(
                                    '${user.xpMultiplier}× XP',
                                    style: TextStyle(
                                        fontFamily: 'Poppins',
                                        color: _skillColor(
                                                user.skillLevel)
                                            .withValues(alpha: 0.8),
                                        fontSize: 10)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── STATS ROW ──
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF191D30),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            const Icon(Icons.access_time,
                                color: Color(0xFF3580FF), size: 24),
                            const SizedBox(height: 8),
                            Text(
                              '$inProgressCount',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              'On Going',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF848A94)),
                            ),
                          ],
                        ),
                      ),
                      Container(
                          width: 1,
                          height: 50,
                          color: const Color(0xFF0A0C16)),
                      Expanded(
                        child: Column(
                          children: [
                            const Icon(Icons.check_box,
                                color: Color(0xFF22C55E), size: 24),
                            const SizedBox(height: 8),
                            Text(
                              '$completedCount',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              'Total Complete',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF848A94)),
                            ),
                          ],
                        ),
                      ),
                      Container(
                          width: 1,
                          height: 50,
                          color: const Color(0xFF0A0C16)),
                      Expanded(
                        child: Column(
                          children: [
                            const Icon(Icons.monetization_on_rounded,
                                color: Color(0xFFFFD700), size: 24),
                            const SizedBox(height: 8),
                            Text(
                              '${user.coins}',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              'Coins',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF848A94)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── ACHIEVEMENTS SECTION ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    const Text(
                      '🏆',
                      style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    const Text(
                      'Achievements',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    if (gam.achievements.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFB800)
                            .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10)),
                        child: Text(
                          '${gam.achievements.length}',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            color: Color(0xFFFFB800),
                            fontSize: 12,
                            fontWeight: FontWeight.w600))),
                  ],
                ),
              ),
              if (gam.achievements.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: gam.achievements
                      .map((achievement) =>
                        _AchievementCard(achievement: achievement))
                      .toList(),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF191D30),
                      borderRadius: BorderRadius.circular(16)),
                    child: const Column(
                      children: [
                        Text(
                          '🏆',
                          style: TextStyle(fontSize: 32)),
                        SizedBox(height: 8),
                        Text(
                          'No achievements yet',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                        SizedBox(height: 4),
                        Text(
                          'Complete tasks to earn achievements!',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Color(0xFF848A94),
                            fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 8),

              // ── TEAM CARD ──
              if (team != null) ...[
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF191D30),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF3580FF).withValues(alpha: 0.2))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(
                            width: 38, height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFF3580FF).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.group_rounded,
                              color: Color(0xFF3580FF), size: 20)),
                          const SizedBox(width: 12),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(team.name,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                              Text(
                                '${team.memberIds.length} member${team.memberIds.length == 1 ? '' : 's'}',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  color: Color(0xFF848A94))),
                            ])),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: user.isTeamLead
                                ? const Color(0xFFFFD700).withValues(alpha: 0.12)
                                : const Color(0xFF3580FF).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8)),
                            child: Text(
                              user.isTeamLead ? '👑 Lead' : '👤 Member',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: user.isTeamLead
                                  ? const Color(0xFFFFD700)
                                  : const Color(0xFF3580FF)))),
                        ]),
                        const SizedBox(height: 14),
                        const Divider(color: Color(0xFF0A0C16), height: 1),
                        const SizedBox(height: 14),
                        const Text('INVITE CODE',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF848A94),
                            letterSpacing: 1.2)),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(
                              ClipboardData(text: team.inviteCode));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Code copied!',
                                  style: TextStyle(fontFamily: 'Poppins')),
                                backgroundColor: Color(0xFF22C55E),
                                behavior: SnackBarBehavior.floating,
                                duration: Duration(seconds: 2)));
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0A0C16),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFF3580FF)
                                  .withValues(alpha: 0.25))),
                            child: Row(children: [
                              const Icon(Icons.key_rounded,
                                color: Color(0xFF3580FF), size: 16),
                              const SizedBox(width: 10),
                              Text(team.inviteCode,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF3580FF),
                                  letterSpacing: 6)),
                              const Spacer(),
                              const Icon(Icons.copy_rounded,
                                color: Color(0xFF848A94), size: 16),
                            ])),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Tap to copy and share with teammates',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: Color(0xFF545A64))),
                      ],
                    ),
                  ),
                ),
              ],

              // ── MENU ITEMS ──
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _menuItem(
                      context,
                      'My Projects',
                      Icons.folder_outlined,
                      const Color(0xFF3580FF),
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const TaskListScreen()),
                      ),
                    ),
                    _menuItem(
                      context,
                      'Join a Team',
                      Icons.group_outlined,
                      const Color(0xFF3580FF),
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const TeamSetupScreen()),
                      ),
                    ),
                    _menuItem(
                      context,
                      'Shop',
                      Icons.store_outlined,
                      const Color(0xFFFFD700),
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ShopScreen(user: user)),
                      ),
                    ),
                    _menuItem(
                      context,
                      'Settings',
                      Icons.settings_outlined,
                      const Color(0xFF3580FF),
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const SettingsScreen()),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF191D30),
                          borderRadius: BorderRadius.circular(10)),
                        child: const Icon(
                          Icons.group_remove_outlined,
                          color: Color(0xFFFFB800),
                          size: 20)),
                      title: const Text(
                        'Leave Team',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Color(0xFFFFB800),
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                      subtitle: const Text(
                        'Stay logged in but leave your current team',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Color(0xFF848A94),
                          fontSize: 11)),
                      onTap: () async {
                        final user = context.read<AuthProvider>().user;
                        if (user == null || !user.hasTeam) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('You are not in a team',
                                style: TextStyle(fontFamily: 'Poppins')),
                              backgroundColor: Color(0xFF848A94)));
                          return;
                        }
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: const Color(0xFF191D30),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                            title: const Text(
                              'Leave Team?',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600)),
                            content: const Text(
                              'You will stay logged in but lose access '
                              'to your current team and its tasks. '
                              'You can join or create a new team afterwards.',
                              style: TextStyle(
                                color: Color(0xFF848A94),
                                fontFamily: 'Poppins',
                                fontSize: 13)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel',
                                  style: TextStyle(
                                    color: Color(0xFF848A94),
                                    fontFamily: 'Poppins'))),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFB800),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8))),
                                child: const Text('Leave',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600))),
                            ],
                          ),
                        );
                        if (confirm == true && context.mounted) {
                          context.read<TeamProvider>().clearTeamData();
                          final ok = await context.read<AuthProvider>().leaveTeam();
                          if (ok && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Left team successfully',
                                  style: TextStyle(fontFamily: 'Poppins')),
                                backgroundColor: Color(0xFF22C55E),
                                behavior: SnackBarBehavior.floating));
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    _menuItem(
                      context,
                      'Sign Out',
                      Icons.logout,
                      const Color(0xFFEF4444),
                      () async {
                        // Clear team data first
                        context.read<TeamProvider>().clearTeamData();
                        // Clear auth + SQLite
                        await context.read<AuthProvider>().signOut();
                        // Navigate to login
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen()),
                            (route) => false,
                          );
                        }
                      },
                      textColor: const Color(0xFFEF4444),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Color _skillColor(SkillLevel level) {
    switch (level) {
      case SkillLevel.junior: return const Color(0xFF22C55E);
      case SkillLevel.middle: return const Color(0xFF3580FF);
      case SkillLevel.senior: return const Color(0xFFFFB800);
    }
  }

  String _skillEmoji(SkillLevel level) {
    switch (level) {
      case SkillLevel.junior: return '🌱';
      case SkillLevel.middle: return '⚡';
      case SkillLevel.senior: return '🔥';
    }
  }

  String _skillLabel(SkillLevel level) {
    switch (level) {
      case SkillLevel.junior: return 'Junior';
      case SkillLevel.middle: return 'Middle';
      case SkillLevel.senior: return 'Senior';
    }
  }

  Widget _menuItem(
    BuildContext context,
    String label,
    IconData icon,
    Color iconColor,
    VoidCallback onTap, {
    Color textColor = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF191D30),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    color: textColor,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  color: iconColor == const Color(0xFFEF4444)
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF848A94),
                  size: 14),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  ACHIEVEMENT CARD
// ─────────────────────────────────────────────
class _AchievementCard extends StatelessWidget {
  final AchievementModel achievement;

  const _AchievementCard({required this.achievement});

  @override
  Widget build(BuildContext context) {
    // 2 cards per row: account for horizontal padding (32) + gap (10)
    final cardWidth = (MediaQuery.of(context).size.width - 42) / 2;

    return Container(
      width: cardWidth,
      padding: const EdgeInsets.all(12),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: const Color(0xFF191D30),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFFB800).withValues(alpha: 0.35),
          width: 1)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB800).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8)),
                child: const Center(
                  child: Text(
                    '🏆',
                    style: TextStyle(fontSize: 16)))),
              const Spacer(),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFB800),
                  shape: BoxShape.circle)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            achievement.title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.2),
            maxLines: 2,
            overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(
            achievement.description,
            style: const TextStyle(
              fontFamily: 'Poppins',
              color: Color(0xFF848A94),
              fontSize: 10,
              height: 1.3),
            maxLines: 3,
            overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
