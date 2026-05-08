import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/gamification_provider.dart';
import '../../../providers/team_provider.dart';
import '../team/team_invite_screen.dart';

class TeamSetupScreen extends StatefulWidget {
  const TeamSetupScreen({super.key});

  @override
  State<TeamSetupScreen> createState() =>
      _TeamSetupScreenState();
}

class _TeamSetupScreenState extends State<TeamSetupScreen> {
  final _ctrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  int _step = 0;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _ctrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Please enter a team name');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      final auth = context.read<AuthProvider>();
      final teamProvider = context.read<TeamProvider>();

      final code = await teamProvider.createTeam(
          name, auth.user!);

      if (!mounted) return;

      if (code != null) {
        final updatedUser = auth.user!.copyWith(
          teamId: teamProvider.team!.id,
          role: UserRole.teamLead,
        );
        auth.refresh(updatedUser);
        await context
            .read<GamificationProvider>()
            .load(updatedUser);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => TeamInviteScreen(
                teamName: _ctrl.text.trim(),
                inviteCode: code,
              ),
            ),
          );
        }
      } else {
        setState(() {
          _error = teamProvider.error ?? 'Failed to create team';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _joinTeam() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.length != 6) {
      setState(() => _error = 'Enter a valid 6-character invite code');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      final auth = context.read<AuthProvider>();
      final teamProv = context.read<TeamProvider>();

      final team = await teamProv.joinTeam(code, auth.user!);
      if (!mounted) return;

      if (team != null) {
        final updated = auth.user!.copyWith(
          teamId: team.id,
          role: UserRole.teamMember,
        );
        await UserRepository().upsert(updated);
        auth.refresh(updated);
        // AppEntry navigates to Dashboard automatically
      } else {
        setState(() => _error = teamProv.error ?? 'Team not found');
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _step == 2
              ? _buildJoinView()
              : _buildCreateView(),
        ),
      ),
    );
  }

  Widget _buildCreateView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Spacer(),
        const Text(
          'Join or create a team',
          style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        const Text(
          'Create a new team and become Team Lead, or join an existing team with an invite code.',
          style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _ctrl,
          style: const TextStyle(
              color: AppColors.textPrimary),
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'Team name',
            hintStyle: const TextStyle(
                color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                    color: AppColors.border, width: 0.5)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                    color: AppColors.border, width: 0.5)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                    color: AppColors.primary, width: 1)),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            style: const TextStyle(
                color: AppColors.danger, fontSize: 12),
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _loading ? null : _create,
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor:
                    AppColors.primary.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text('Create Team',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: () {
              setState(() { _step = 2; _error = null; });
            },
            style: OutlinedButton.styleFrom(
                side: const BorderSide(
                    color: AppColors.primary, width: 0.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.login,
                    color: AppColors.primaryLight, size: 18),
                SizedBox(width: 8),
                Text('Join with Code',
                    style: TextStyle(
                        color: AppColors.primaryLight,
                        fontSize: 15,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
        const Spacer(),
        Center(
          child: TextButton(
            onPressed: () async {
              context.read<TeamProvider>().clearTeamData();
              await context.read<AuthProvider>().signOut();
              // No Navigator here — AppEntry handles navigation
            },
            child: const Text(
              'Sign out',
              style: TextStyle(
                  color: AppColors.textMuted, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildJoinView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Spacer(),
        Row(
          children: [
            GestureDetector(
              onTap: () => setState(() { _step = 0; _error = null; }),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: AppColors.textPrimary, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Join a Team',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Enter the 6-character invite code shared by your Team Lead.',
          style: TextStyle(
              fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _codeCtrl,
          style: const TextStyle(
              color: AppColors.textPrimary, letterSpacing: 4),
          textCapitalization: TextCapitalization.characters,
          maxLength: 6,
          decoration: InputDecoration(
            hintText: 'e.g. ABC123',
            hintStyle: const TextStyle(
                color: AppColors.textMuted, letterSpacing: 1),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                    color: AppColors.border, width: 0.5)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                    color: AppColors.border, width: 0.5)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                    color: AppColors.primary, width: 1)),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 4),
          Text(
            _error!,
            style: const TextStyle(
                color: AppColors.danger, fontSize: 12),
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _loading ? null : _joinTeam,
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor:
                    AppColors.primary.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.group_add,
                          color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text('Join Team',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
          ),
        ),
        const Spacer(),
      ],
    );
  }
}
