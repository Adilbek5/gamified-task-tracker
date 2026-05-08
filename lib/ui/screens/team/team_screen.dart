import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../providers/activity_provider.dart';
import '../../../services/activity_service.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/team_provider.dart';
import '../../../services/team_service.dart';

class TeamScreen extends StatefulWidget {
  final UserModel user;
  const TeamScreen({super.key, required this.user});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  void _showTransferDialog(BuildContext context,
      TeamProvider teamProv, UserModel currentUser) {
    final members = teamProv.team!.memberIds
      .where((id) => id != currentUser.id).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF191D30),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4,
            decoration: BoxDecoration(color: const Color(0xFF848A94),
              borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('Transfer Leadership',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 17,
              fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 4),
          const Text('You will become Team Member',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 13,
              color: Color(0xFF848A94))),
          const SizedBox(height: 16),
          ...members.map((memberId) => FutureBuilder<UserModel?>(
            future: UserRepository().getById(memberId),
            builder: (_, snap) {
              final m = snap.data;
              if (m == null) return const SizedBox.shrink();
              return GestureDetector(
                onTap: () async {
                  Navigator.pop(ctx);
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (d) => AlertDialog(
                      backgroundColor: const Color(0xFF191D30),
                      title: const Text('Confirm',
                        style: TextStyle(color: Colors.white,
                          fontFamily: 'Poppins')),
                      content: Text('Transfer to ${m.name}?',
                        style: const TextStyle(color: Color(0xFF848A94),
                          fontFamily: 'Poppins')),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(d, false),
                          child: const Text('Cancel',
                            style: TextStyle(color: Color(0xFF848A94)))),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(d, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFD700)),
                          child: const Text('Transfer',
                            style: TextStyle(color: Colors.black,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600))),
                      ],
                    ),
                  );
                  if (ok == true && context.mounted) {
                    await TeamService().transferLeadership(
                      currentUser.teamId!, memberId, currentUser.id);
                    final updated = currentUser.copyWith(
                      role: UserRole.teamMember);
                    await UserRepository().upsert(updated);
                    if (!context.mounted) return;
                    context.read<AuthProvider>().refresh(updated);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Leadership transferred!'),
                        backgroundColor: Color(0xFF22C55E),
                        behavior: SnackBarBehavior.floating));
                  }
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 4),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: const Color(0xFF0A0C16),
                    borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    Container(width: 40, height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFF191D30), shape: BoxShape.circle),
                      child: Center(child: Text(m.avatarEmoji,
                        style: const TextStyle(fontSize: 20)))),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.name, style: const TextStyle(
                          fontFamily: 'Poppins', fontSize: 14,
                          fontWeight: FontWeight.w500, color: Colors.white)),
                        Text(m.roleLabel, style: const TextStyle(
                          fontFamily: 'Poppins', fontSize: 12,
                          color: Color(0xFF848A94))),
                      ])),
                    const Icon(Icons.arrow_forward_ios,
                      color: Color(0xFF848A94), size: 14),
                  ]),
                ),
              );
            },
          )),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final team = context.watch<TeamProvider>();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Team',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            if (team.loading)
              const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primary))
            else if (team.team == null)
              const Center(
                  child: Text('No team data',
                      style: TextStyle(
                          color: AppColors.textMuted)))
            else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius:
                      BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.primary
                              .withValues(alpha: 0.3),
                          width: 0.5)),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                              color: AppColors.primary
                                  .withValues(alpha: 0.15),
                              borderRadius:
                              BorderRadius.circular(
                                  10)),
                          child: const Icon(Icons.group,
                              color:
                              AppColors.primaryLight,
                              size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(team.team!.name,
                                  style: const TextStyle(
                                      color: AppColors
                                          .textPrimary,
                                      fontSize: 15,
                                      fontWeight:
                                      FontWeight.w500)),
                              Text(
                                  '${team.team!.memberIds.length} members',
                                  style: const TextStyle(
                                      color: AppColors
                                          .textSecondary,
                                      fontSize: 11)),
                            ],
                          ),
                        ),
                      ]),
                      if (widget.user.isTeamLead)
                        Container(
                          margin: const EdgeInsets.only(top: 16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3580FF)
                                .withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF3580FF)
                                  .withValues(alpha: 0.25),
                              width: 1.5,
                            ),
                          ),
                          child: Column(children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('YOUR INVITE CODE',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF848A94),
                                      letterSpacing: 1.2,
                                    )),
                                GestureDetector(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(
                                        text:
                                            team.team!.inviteCode));
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                      content: const Text(
                                        '✅ Invite code copied!',
                                        style: TextStyle(
                                            fontFamily: 'Poppins'),
                                      ),
                                      backgroundColor:
                                          const Color(0xFF22C55E),
                                      behavior:
                                          SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(
                                                  10)),
                                      duration: const Duration(
                                          seconds: 2),
                                    ));
                                  },
                                  child: Container(
                                    padding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF3580FF)
                                          .withValues(alpha: 0.12),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.copy_rounded,
                                            color: Color(0xFF3580FF),
                                            size: 14),
                                        SizedBox(width: 4),
                                        Text('Copy',
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 12,
                                              color:
                                                  Color(0xFF3580FF),
                                            )),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: team.team!.inviteCode
                                  .split('')
                                  .map((char) => Container(
                                        margin:
                                            const EdgeInsets.symmetric(
                                                horizontal: 4),
                                        width: 38,
                                        height: 46,
                                        decoration: BoxDecoration(
                                          color:
                                              const Color(0xFF0A0C16),
                                          borderRadius:
                                              BorderRadius.circular(
                                                  10),
                                          border: Border.all(
                                              color: const Color(
                                                      0xFF3580FF)
                                                  .withValues(
                                                      alpha: 0.3)),
                                        ),
                                        child: Center(
                                          child: Text(char,
                                              style: const TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 20,
                                                fontWeight:
                                                    FontWeight.w700,
                                                color: Color(
                                                    0xFF3580FF),
                                              )),
                                        ),
                                      ))
                                  .toList(),
                            ),
                            const SizedBox(height: 14),
                            const Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Icon(Icons.share_outlined,
                                    color: Color(0xFF848A94),
                                    size: 14),
                                SizedBox(width: 6),
                                Text(
                                  'Share this code with your team members',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    color: Color(0xFF848A94),
                                  ),
                                ),
                              ],
                            ),
                          ]),
                        ),
                      if (widget.user.isTeamLead &&
                          team.team!.memberIds.length > 1)
                        GestureDetector(
                          onTap: () => _showTransferDialog(
                              context, team, widget.user),
                          child: Container(
                            margin: const EdgeInsets.only(top: 12),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD700)
                                  .withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: const Color(0xFFFFD700)
                                      .withValues(alpha: 0.2))),
                            child: const Row(children: [
                              Icon(Icons.swap_horiz_rounded,
                                  color: Color(0xFFFFD700), size: 16),
                              SizedBox(width: 8),
                              Text('Transfer Leadership',
                                style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    color: Color(0xFFFFD700))),
                              Spacer(),
                              Icon(Icons.arrow_forward_ios,
                                  color: Color(0xFFFFD700), size: 12),
                            ])),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Consumer<ActivityProvider>(
                  builder: (ctx, activity, _) {
                    if (activity.members.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(width: 8, height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF22C55E),
                              shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Text('${activity.onlineMembers.length} online',
                            style: const TextStyle(
                              fontFamily: 'Poppins', fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF22C55E))),
                          const Spacer(),
                          Text('${activity.members.length} total',
                            style: const TextStyle(
                              fontFamily: 'Poppins', fontSize: 12,
                              color: Color(0xFF848A94))),
                        ]),
                        const SizedBox(height: 10),
                        ...activity.members.map((m) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF191D30),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: m.isOnline
                                ? const Color(0xFF22C55E).withValues(alpha: 0.15)
                                : const Color(0xFF191D30))),
                          child: Row(children: [
                            Stack(children: [
                              Container(
                                width: 42, height: 42,
                                decoration: BoxDecoration(
                                  color: m.skillColor.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: m.skillColor.withValues(alpha: 0.4),
                                    width: 1.5)),
                                child: Center(child: Text(m.skillEmoji,
                                  style: const TextStyle(fontSize: 18)))),
                              Positioned(right: 0, bottom: 0,
                                child: Container(
                                  width: 12, height: 12,
                                  decoration: BoxDecoration(
                                    color: m.isOnline
                                      ? const Color(0xFF22C55E)
                                      : const Color(0xFF848A94),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFF191D30),
                                      width: 2)))),
                            ]),
                            const SizedBox(width: 12),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Text(m.name,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins', fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white)),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: m.skillColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6)),
                                    child: Text(m.skillLabel,
                                      style: TextStyle(
                                        fontFamily: 'Poppins', fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                        color: m.skillColor))),
                                ]),
                                const SizedBox(height: 3),
                                if (!m.isOnline)
                                  const Text('Offline',
                                    style: TextStyle(fontFamily: 'Poppins',
                                      fontSize: 12, color: Color(0xFF545A64)))
                                else if (m.hasActiveTask)
                                  Text('Working on: ${m.currentTaskTitle}',
                                    style: const TextStyle(
                                      fontFamily: 'Poppins', fontSize: 12,
                                      color: Color(0xFF3580FF)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis)
                                else
                                  const Text('Online · No active task',
                                    style: TextStyle(fontFamily: 'Poppins',
                                      fontSize: 12, color: Color(0xFF22C55E))),
                              ])),
                          ])),
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('TEAM TASKS',
                        style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.8)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: AppColors.surfaceAlt,
                          borderRadius:
                          BorderRadius.circular(10)),
                      child: Text(
                          '${team.tasks.length} tasks',
                          style: const TextStyle(
                              color:
                              AppColors.textSecondary,
                              fontSize: 10)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (team.tasks.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius:
                        BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.border,
                            width: 0.5)),
                    child: const Center(
                        child: Text('No tasks yet',
                            style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12))),
                  )
                else
                  ...team.tasks.map((t) => Container(
                    margin: const EdgeInsets.only(
                        bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius:
                        BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.border,
                            width: 0.5)),
                    child: Row(children: [
                      Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                              color: t.difficulty >= 8
                                  ? AppColors.danger
                                  : t.difficulty >= 5
                                  ? AppColors.warning
                                  : AppColors.success,
                              shape: BoxShape.circle)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(t.title,
                                style: const TextStyle(
                                    color: AppColors
                                        .textPrimary,
                                    fontSize: 13)),
                            Text(
                                'Diff ${t.difficulty}/10 · ${t.status.name}',
                                style: const TextStyle(
                                    color: AppColors
                                        .textMuted,
                                    fontSize: 10)),
                          ],
                        ),
                      ),
                      Container(
                          padding:
                          const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2),
                          decoration: BoxDecoration(
                              color: t.status.name ==
                                  'completed'
                                  ? AppColors.success
                                  .withValues(alpha: 0.15)
                                  : AppColors.primary
                                  .withValues(alpha: 0.12),
                              borderRadius:
                              BorderRadius.circular(
                                  20)),
                          child: Text(
                              '${t.difficulty * 10} XP',
                              style: TextStyle(
                                  color: t.status.name ==
                                      'completed'
                                      ? AppColors.success
                                      : AppColors
                                      .primaryLight,
                                  fontSize: 9,
                                  fontWeight:
                                  FontWeight.w500))),
                    ]),
                  )),
              ],
          ],
        ),
      ),
    );
  }
}
