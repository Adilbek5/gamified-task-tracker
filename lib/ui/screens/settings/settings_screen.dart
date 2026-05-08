import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/team_provider.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  bool _sounds = false;
  bool _haptics = true;

  static const _sectionStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: Color(0xFF848A94),
    letterSpacing: 1.2,
  );

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _notifications = prefs.getBool('notif') ?? true;
        _sounds = prefs.getBool('sounds') ?? false;
        _haptics = prefs.getBool('haptics') ?? true;
      });
    }
  }

  Future<void> _savePref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _signOut() async {
    final confirm = await _showConfirmDialog(
      title: 'Sign Out',
      message: 'Are you sure you want to sign out?',
      confirmText: 'Sign Out',
      confirmColor: const Color(0xFFEF4444),
    );
    if (confirm != true || !mounted) return;
    context.read<TeamProvider>().clearTeamData();
    await context.read<AuthProvider>().signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF191D30),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text(title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              color: Colors.white,
            )),
        content: Text(message,
            style: const TextStyle(
              fontFamily: 'Poppins',
              color: Color(0xFF848A94),
            )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF848A94))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(confirmText,
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthProvider, UserModel?>(
        (auth) => auth.user);
    final teamProv = context.watch<TeamProvider>();
    final team = teamProv.team;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0C16),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),

            // ── Top bar ──────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: Color(0xFF191D30),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'Settings',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 42),
              ]),
            ),

            const SizedBox(height: 20),

            // ── Scrollable body ───────────────────────────────
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  // USER CARD
                  if (user != null)
                    RepaintBoundary(child: _UserCard(user: user)),

                  const SizedBox(height: 24),

                  // ── TEAM SECTION ──
                  if (team != null) ...[
                    const Text('MY TEAM', style: _sectionStyle),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF191D30),
                        borderRadius: BorderRadius.circular(14)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Text('🏢',
                              style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 10),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(team.name,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white)),
                                Text(
                                  user?.isTeamLead == true
                                    ? 'You are the Team Lead 👑'
                                    : 'You are a Team Member',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    color: Color(0xFF848A94))),
                              ])),
                          ]),
                          const SizedBox(height: 12),
                          const Divider(color: Color(0xFF0A0C16), height: 1),
                          const SizedBox(height: 12),
                          Row(children: [
                            const Icon(Icons.people_outline,
                              color: Color(0xFF848A94), size: 16),
                            const SizedBox(width: 8),
                            Text(
                              '${team.memberIds.length} team member${team.memberIds.length == 1 ? '' : 's'}',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                color: Color(0xFF848A94))),
                          ]),
                          const SizedBox(height: 8),
                          Row(children: [
                            const Icon(Icons.key_rounded,
                              color: Color(0xFF3580FF), size: 16),
                            const SizedBox(width: 8),
                            const Text('Code: ',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                color: Color(0xFF848A94))),
                            Text(team.inviteCode,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF3580FF),
                                letterSpacing: 3)),
                            const Spacer(),
                            GestureDetector(
                              onTap: () {
                                Clipboard.setData(
                                  ClipboardData(text: team.inviteCode));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Code copied!'),
                                    backgroundColor: Color(0xFF22C55E),
                                    behavior: SnackBarBehavior.floating,
                                    duration: Duration(seconds: 2)));
                              },
                              child: const Icon(Icons.copy_rounded,
                                color: Color(0xFF848A94), size: 16)),
                          ]),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  const Text('PREFERENCES', style: _sectionStyle),
                  const SizedBox(height: 12),

                  RepaintBoundary(
                    child: _ToggleItem(
                      icon: Icons.notifications_outlined,
                      label: 'Push Notifications',
                      subtitle: 'Task deadlines and assignments',
                      value: _notifications,
                      onChanged: (v) {
                        setState(() => _notifications = v);
                        _savePref('notif', v);
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  RepaintBoundary(
                    child: _ToggleItem(
                      icon: Icons.volume_up_outlined,
                      label: 'Sound Effects',
                      subtitle: 'Play on task completion',
                      value: _sounds,
                      onChanged: (v) {
                        setState(() => _sounds = v);
                        _savePref('sounds', v);
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  RepaintBoundary(
                    child: _ToggleItem(
                      icon: Icons.vibration_outlined,
                      label: 'Haptic Feedback',
                      subtitle: 'Vibration on interactions',
                      value: _haptics,
                      onChanged: (v) {
                        setState(() => _haptics = v);
                        _savePref('haptics', v);
                      },
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Text('ACCOUNT', style: _sectionStyle),
                  const SizedBox(height: 12),

                  _MenuItem(
                    icon: Icons.security_outlined,
                    label: 'Security',
                    onTap: () {},
                  ),
                  const SizedBox(height: 10),
                  _MenuItem(
                    icon: Icons.language_outlined,
                    label: 'Language',
                    trailing: const Text(
                      'English',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: Color(0xFF848A94),
                      ),
                    ),
                    onTap: () {},
                  ),
                  const SizedBox(height: 10),
                  _MenuItem(
                    icon: Icons.info_outline_rounded,
                    label: 'About App',
                    onTap: () => showAboutDialog(
                      context: context,
                      applicationName: 'Task Tracker',
                      applicationVersion: '1.0.0',
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Text('DANGER ZONE', style: _sectionStyle),
                  const SizedBox(height: 12),

                  // SIGN OUT
                  GestureDetector(
                    onTap: _signOut,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444)
                            .withOpacity(0.08),
                        borderRadius: const BorderRadius.all(
                            Radius.circular(14)),
                        border: Border.all(
                          color: const Color(0xFFEF4444)
                              .withOpacity(0.2),
                        ),
                      ),
                      child: const Row(children: [
                        Icon(Icons.logout_rounded,
                            color: Color(0xFFEF4444), size: 20),
                        SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Sign Out',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios,
                            color: Color(0xFFEF4444), size: 14),
                      ]),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  USER CARD
// ─────────────────────────────────────────────
class _UserCard extends StatelessWidget {
  final UserModel user;
  const _UserCard({required this.user});

  static const _nameStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
  static const _emailStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 12,
    color: Color(0xFF848A94),
  );
  static const _cardDeco = BoxDecoration(
    color: Color(0xFF191D30),
    borderRadius: BorderRadius.all(Radius.circular(14)),
  );
  static const _avatarDeco = BoxDecoration(
    color: Color(0xFF3580FF),
    shape: BoxShape.circle,
  );
  static const _roleLabelStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 11,
    color: Color(0xFF3580FF),
    fontWeight: FontWeight.w500,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco,
      child: Row(children: [
        Container(
          width: 52,
          height: 52,
          decoration: _avatarDeco,
          child: Center(
            child: Text(user.avatarEmoji,
                style: const TextStyle(fontSize: 24)),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(user.name, style: _nameStyle),
              Text(user.email, style: _emailStyle),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color:
                      const Color(0xFF3580FF).withOpacity(0.15),
                  borderRadius:
                      const BorderRadius.all(Radius.circular(6)),
                ),
                child: Text(user.roleLabel,
                    style: _roleLabelStyle),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────
//  TOGGLE ITEM
// ─────────────────────────────────────────────
class _ToggleItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  static const _deco = BoxDecoration(
    color: Color(0xFF191D30),
    borderRadius: BorderRadius.all(Radius.circular(14)),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _deco,
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 4),
        secondary:
            Icon(icon, color: const Color(0xFF3580FF), size: 22),
        title: Text(label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              color: Colors.white,
            )),
        subtitle: Text(subtitle,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: Color(0xFF848A94),
            )),
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF3580FF),
        activeTrackColor:
            const Color(0xFF3580FF).withOpacity(0.3),
        inactiveTrackColor: const Color(0xFF0A0C16),
        inactiveThumbColor: const Color(0xFF848A94),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  MENU ITEM
// ─────────────────────────────────────────────
class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  static const _deco = BoxDecoration(
    color: Color(0xFF191D30),
    borderRadius: BorderRadius.all(Radius.circular(14)),
  );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 16),
        decoration: _deco,
        child: Row(children: [
          Icon(icon, color: const Color(0xFF3580FF), size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  color: Colors.white,
                )),
          ),
          trailing ??
              const Icon(Icons.arrow_forward_ios,
                  color: Color(0xFF848A94), size: 14),
        ]),
      ),
    );
  }
}
