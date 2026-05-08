import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/user_model.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/team_provider.dart';
import '../dashboard/dashboard_screen.dart';

// ─────────────────────────────────────────────
// Data class
// ─────────────────────────────────────────────

class _LevelData {
  final SkillLevel level;
  final String emoji;
  final String title;
  final String subtitle;
  final List<String> traits;
  final Color color;
  final String xpBonus;

  const _LevelData({
    required this.level,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.traits,
    required this.color,
    required this.xpBonus,
  });
}

const _levels = [
  _LevelData(
    level: SkillLevel.junior,
    emoji: '🌱',
    title: 'Junior Developer',
    subtitle: 'Less than 2 years of experience',
    traits: ['Learning the basics', 'Needs guidance', 'Grows fast'],
    color: Color(0xFF22C55E),
    xpBonus: 'x1.0 XP',
  ),
  _LevelData(
    level: SkillLevel.middle,
    emoji: '⚡',
    title: 'Middle Developer',
    subtitle: '2–5 years of experience',
    traits: ['Works independently', 'Solves complex tasks', 'Mentors juniors'],
    color: Color(0xFF3580FF),
    xpBonus: 'x1.25 XP',
  ),
  _LevelData(
    level: SkillLevel.senior,
    emoji: '🔥',
    title: 'Senior Developer',
    subtitle: '5+ years of experience',
    traits: ['Leads technically', 'Architects solutions', 'Sets standards'],
    color: Color(0xFFFFD700),
    xpBonus: 'x1.5 XP',
  ),
];

// ─────────────────────────────────────────────
// Level card widget
// ─────────────────────────────────────────────

class _LevelCard extends StatelessWidget {
  final _LevelData data;
  final bool isSelected;
  final VoidCallback onTap;

  const _LevelCard({
    required this.data,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? data.color.withValues(alpha: 0.08)
              : const Color(0xFF191D30),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? data.color : const Color(0xFF191D30),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Emoji circle
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isSelected
                    ? data.color.withValues(alpha: 0.15)
                    : const Color(0xFF0A0C16),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(data.emoji,
                    style: const TextStyle(fontSize: 26)),
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          data.title,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? data.color : Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: data.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          data.xpBonus,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: data.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    data.subtitle,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Color(0xFF848A94),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: data.traits
                        .map((t) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? data.color.withValues(alpha: 0.1)
                                    : const Color(0xFF0A0C16),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                t,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 10,
                                  color: isSelected
                                      ? data.color
                                      : const Color(0xFF848A94),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isSelected ? 1.0 : 0.0,
              child: Icon(Icons.check_circle_rounded,
                  color: data.color, size: 24),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SkillLevelScreen
// ─────────────────────────────────────────────

class SkillLevelScreen extends StatefulWidget {
  const SkillLevelScreen({super.key});

  @override
  State<SkillLevelScreen> createState() => _SkillLevelScreenState();
}

class _SkillLevelScreenState extends State<SkillLevelScreen> {
  SkillLevel? _selected;

  @override
  Widget build(BuildContext context) {
    final selectedData =
        _selected != null ? _levels.firstWhere((l) => l.level == _selected) : null;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0C16),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              const Text(
                'Your skill level',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This helps your team lead assign the right tasks.\n'
                'Higher level = more XP per task.',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: Color(0xFF848A94),
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 32),

              ..._levels.map((data) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _LevelCard(
                      data: data,
                      isSelected: _selected == data.level,
                      onTap: () => setState(() => _selected = data.level),
                    ),
                  )),

              const SizedBox(height: 16),

              if (selectedData != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: selectedData.color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: selectedData.color.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: selectedData.color, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'As ${selectedData.title}, you earn '
                          '${selectedData.xpBonus} multiplier on all '
                          'completed tasks.',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: Colors.white,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _selected == null
                      ? null
                      : () {
                          final auth = context.read<AuthProvider>();
                          final updated =
                              auth.user!.copyWith(skillLevel: _selected);
                          auth.refresh(updated);

                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const _JoinTeamScreen()),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedData != null
                        ? selectedData.color
                        : const Color(0xFF191D30),
                    disabledBackgroundColor: const Color(0xFF191D30),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text(
                    selectedData != null
                        ? 'Join as ${selectedData.title}'
                        : 'Select your level',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: selectedData != null
                          ? Colors.black
                          : const Color(0xFF848A94),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// _JoinTeamScreen
// ─────────────────────────────────────────────

class _JoinTeamScreen extends StatefulWidget {
  const _JoinTeamScreen();

  @override
  State<_JoinTeamScreen> createState() => _JoinTeamScreenState();
}

class _JoinTeamScreenState extends State<_JoinTeamScreen> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final code = _ctrl.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _error = 'Please enter an invite code');
      return;
    }
    if (code.length != 6) {
      setState(() => _error = 'Code must be 6 characters');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final auth = context.read<AuthProvider>();
      final teamProv = context.read<TeamProvider>();

      final team = await teamProv.joinTeam(code, auth.user!);
      if (!mounted) return;

      if (team != null) {
        // Restore as Lead if this user owns the team
        final isLead = team.leadId == auth.user!.id;
        final role = isLead ? UserRole.teamLead : UserRole.teamMember;

        final updated = auth.user!.copyWith(
          teamId: team.id,
          role: role,
        );
        final repo = UserRepository();
        await repo.upsert(updated);
        auth.refresh(updated);

        await FirebaseDatabase.instance
            .ref('team_members/${team.id}/${updated.id}')
            .set({
          'user_id': updated.id,
          'name': updated.name,
          'skill_level': updated.skillLevel.name,
          'role': 'teamMember',
          'joined_at': ServerValue.timestamp,
          'is_online': true,
        });

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
            (route) => false,
          );
        }
      } else {
        setState(() =>
            _error = teamProv.error ?? 'Team not found. Check the code.');
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0C16),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: Color(0xFF191D30),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white, size: 16),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Join Team',
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
                ],
              ),

              const Spacer(),

              const Text(
                'Enter invite code',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ask your Team Lead for the 6-character code',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: Color(0xFF848A94),
                ),
              ),

              const SizedBox(height: 32),

              Container(
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0C16),
                  border: Border.all(
                      color: const Color(0xFF3580FF), width: 1.5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextField(
                  controller: _ctrl,
                  textCapitalization: TextCapitalization.characters,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF3580FF),
                    letterSpacing: 8,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'XXXXXX',
                    hintStyle: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 28,
                      color: Color(0xFF191D30),
                      letterSpacing: 8,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 20, vertical: 18),
                  ),
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ],

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _loading ? null : _join,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3580FF),
                    disabledBackgroundColor: const Color(0xFF191D30),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Join Team',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
