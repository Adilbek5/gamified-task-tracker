import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/user_model.dart';
import '../../../providers/auth_provider.dart';
import 'team_setup_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() =>
      _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  UserRole? _selected;

  static const _titleStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );
  static const _subStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14,
    color: Color(0xFF848A94),
    height: 1.6,
  );

  void _confirm() {
    if (_selected == null) return;
    final auth = context.read<AuthProvider>();
    auth.refresh(auth.user!.copyWith(role: _selected));
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const TeamSetupScreen()),
    );
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
              const SizedBox(height: 48),
              const Text('Who are you?', style: _titleStyle),
              const SizedBox(height: 10),
              const Text(
                'Choose your role. This determines\nwhat you can do in the app.',
                style: _subStyle,
              ),
              const SizedBox(height: 48),

              _RoleCard(
                emoji: '🎯',
                title: 'Team Lead',
                description:
                    'Create teams, assign tasks,\nmanage challenges and the team',
                role: UserRole.teamLead,
                isSelected: _selected == UserRole.teamLead,
                onTap: () =>
                    setState(() => _selected = UserRole.teamLead),
              ),

              const SizedBox(height: 14),

              _RoleCard(
                emoji: '👥',
                title: 'Team Member',
                description:
                    'Join a team, complete tasks,\nparticipate in challenges',
                role: UserRole.teamMember,
                isSelected: _selected == UserRole.teamMember,
                onTap: () =>
                    setState(() => _selected = UserRole.teamMember),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _selected != null ? 1.0 : 0.5,
                  child: ElevatedButton(
                    onPressed: _selected != null ? _confirm : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3580FF),
                      disabledBackgroundColor:
                          const Color(0xFF191D30),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Text(
                      _selected == null
                          ? 'Select a role to continue'
                          : _selected == UserRole.teamLead
                              ? 'Continue as Team Lead'
                              : 'Continue as Team Member',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: _selected != null
                            ? Colors.white
                            : const Color(0xFF848A94),
                      ),
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
//  ROLE CARD
// ─────────────────────────────────────────────
class _RoleCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String description;
  final UserRole role;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.emoji,
    required this.title,
    required this.description,
    required this.role,
    required this.isSelected,
    required this.onTap,
  });

  static const _selectedDeco = BoxDecoration(
    color: Color(0x203580FF),
    borderRadius: BorderRadius.all(Radius.circular(18)),
    border: Border.fromBorderSide(
        BorderSide(color: Color(0xFF3580FF), width: 2)),
  );
  static const _normalDeco = BoxDecoration(
    color: Color(0xFF191D30),
    borderRadius: BorderRadius.all(Radius.circular(18)),
    border: Border.fromBorderSide(
        BorderSide(color: Color(0xFF191D30), width: 1)),
  );
  static const _titleStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
  static const _selectedTitleStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: Color(0xFF3580FF),
  );
  static const _descStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 13,
    color: Color(0xFF848A94),
    height: 1.4,
  );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: isSelected ? _selectedDeco : _normalDeco,
        child: Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF3580FF).withOpacity(0.2)
                  : const Color(0xFF0A0C16),
              borderRadius:
                  const BorderRadius.all(Radius.circular(14)),
            ),
            child: Center(
              child: Text(emoji,
                  style: const TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    style: isSelected
                        ? _selectedTitleStyle
                        : _titleStyle),
                const SizedBox(height: 4),
                Text(description, style: _descStyle),
              ],
            ),
          ),
          if (isSelected)
            const Icon(Icons.check_circle_rounded,
                color: Color(0xFF3580FF), size: 24),
        ]),
      ),
    );
  }
}
