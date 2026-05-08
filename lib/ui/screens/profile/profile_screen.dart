import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

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
    final inProgressCount = tasks.tasks
        .where((t) =>
            t.status == TaskStatus.inProgress ||
            t.status == TaskStatus.pending)
        .length;
    final completedCount = tasks.completedTasks.length;

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
                    _menuItem(
                      context,
                      'My Task',
                      Icons.task_outlined,
                      const Color(0xFF3580FF),
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const TaskListScreen()),
                      ),
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
