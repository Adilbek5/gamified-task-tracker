import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/task_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/challenge_provider.dart';
import '../../../providers/gamification_provider.dart';
import '../../../providers/task_provider.dart';
import '../../../providers/team_provider.dart';
import '../../widgets/circular_progress_widget.dart';
import '../../widgets/overlapping_avatars.dart';

class TaskDetailScreen extends StatelessWidget {
  final TaskModel task;

  const TaskDetailScreen({super.key, required this.task});

  // ── helpers ──────────────────────────────────────────

  double get _progress {
    switch (task.status) {
      case TaskStatus.completed:
        return 1.0;
      case TaskStatus.inProgress:
        return 0.5;
      default:
        return 0.0;
    }
  }

  Color get _progressColor {
    switch (task.status) {
      case TaskStatus.completed:
        return AppColors.success;
      case TaskStatus.overdue:
        return AppColors.danger;
      default:
        return AppColors.primary;
    }
  }

  String get _centerText {
    if (task.status == TaskStatus.overdue) {
      final days = DateTime.now().difference(task.deadline).inDays;
      return '${days}d';
    }
    return '${(_progress * 100).toInt()}%';
  }

  String get _subText {
    if (task.status == TaskStatus.overdue) return 'overdue';
    if (task.status == TaskStatus.completed) return 'done';
    return 'complete';
  }

  Color get _statusColor {
    switch (task.status) {
      case TaskStatus.completed:
        return AppColors.success;
      case TaskStatus.overdue:
        return AppColors.danger;
      case TaskStatus.inProgress:
        return AppColors.primary;
      case TaskStatus.pending:
        return const Color(0xFF3B82F6);
    }
  }

  String get _statusLabel {
    switch (task.status) {
      case TaskStatus.completed:
        return 'Completed';
      case TaskStatus.overdue:
        return 'Overdue';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.pending:
        return 'Pending';
    }
  }

  Color get _diffColor {
    if (task.difficulty >= 8) return AppColors.danger;
    if (task.difficulty >= 5) return AppColors.warning;
    return AppColors.success;
  }

  Future<void> _complete(BuildContext ctx) async {
    final auth = ctx.read<AuthProvider>();
    if (auth.user == null) return;
    final user = auth.user!;

    final taskProvider = ctx.read<TaskProvider>();
    final gam = ctx.read<GamificationProvider>();
    final cp = ctx.read<ChallengeProvider>();

    final completed = await taskProvider.completeTask(task.id);
    final result = await gam.handleCompletion(completed, user);

    if (completed.xpEarned > 0 &&
        user.teamId != null &&
        user.teamId!.isNotEmpty) {
      for (final challenge in cp.challenges) {
        if (challenge.isActive &&
            challenge.participantIds.contains(user.id)) {
          await cp.addXp(
            user.teamId!,
            challenge.id,
            user.id,
            user.name,
            completed.xpEarned,
          );
        }
      }
    }

    if (ctx.mounted) {
      final xp = result.xpEarned;
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        backgroundColor: AppColors.success,
        content: Text(
          xp > 0 ? 'Task complete! +$xp XP earned' : 'Task marked complete',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        duration: const Duration(seconds: 3),
      ));

      if (result.achievements.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (ctx.mounted) {
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              backgroundColor: AppColors.warning,
              content: Text(
                'Achievement: ${result.achievements.first.title}',
                style: const TextStyle(color: Colors.white),
              ),
              duration: const Duration(seconds: 3),
            ));
          }
        });
      }

      Navigator.pop(ctx);
    }
  }

  // ── build ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final team = context.watch<TeamProvider>();
    final auth = context.watch<AuthProvider>();
    final currentUser = auth.user;

    final canComplete = task.status != TaskStatus.completed &&
        task.status != TaskStatus.overdue;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D14),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: AppColors.textPrimary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          task.title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (currentUser?.canCreateTasks == true ||
              task.createdBy == currentUser?.id)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: Color(0xFFEF4444)),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: const Color(0xFF191D30),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    title: const Text('Delete Task',
                        style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Poppins')),
                    content: const Text('This cannot be undone.',
                        style: TextStyle(
                            color: Color(0xFF848A94),
                            fontFamily: 'Poppins')),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel',
                            style: TextStyle(
                                color: Color(0xFF848A94)))),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444)),
                        child: const Text('Delete',
                            style: TextStyle(color: Colors.white))),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  await context
                      .read<TaskProvider>()
                      .deleteTask(task.id);
                  if (context.mounted) Navigator.pop(context);
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── top section ────────────────────────────
            Text(
              team.team?.name ?? 'Personal',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              task.title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            _StatusChip(label: _statusLabel, color: _statusColor),

            const SizedBox(height: 28),

            // ── circular progress ─────────────────────
            Center(
              child: CircularProgressWidget(
                progress: _progress,
                centerText: _centerText,
                subText: _subText,
                progressColor: _progressColor,
                size: 120,
                strokeWidth: 8,
              ),
            ),

            const SizedBox(height: 28),

            // ── info cards row ────────────────────────
            Row(children: [
              Expanded(
                child: _InfoCard(
                  label: 'Difficulty',
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _diffColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${task.difficulty}/10',
                        style: TextStyle(
                          color: _diffColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoCard(
                  label: 'XP Reward',
                  child: Text(
                    task.status == TaskStatus.completed
                        ? '+${task.xpEarned} XP'
                        : '+${task.difficulty * 10} XP',
                    style: const TextStyle(
                      color: AppColors.primaryLight,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoCard(
                  label: 'Deadline',
                  child: Text(
                    DateFormat('MMM d').format(task.deadline),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ]),

            const SizedBox(height: 24),

            // ── description ───────────────────────────
            _SectionTitle('Description'),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Text(
                task.description?.isNotEmpty == true
                    ? task.description!
                    : 'No description provided.',
                style: TextStyle(
                  color: task.description?.isNotEmpty == true
                      ? AppColors.textSecondary
                      : AppColors.textMuted,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── team members ──────────────────────────
            _SectionTitle('Team Members'),
            const SizedBox(height: 10),
            _buildMembersSection(context, team, currentUser),

            const SizedBox(height: 24),

            // ── activity timeline ─────────────────────
            _SectionTitle('Activity'),
            const SizedBox(height: 10),
            _buildTimeline(),
          ],
        ),
      ),
      // ── bottom button ─────────────────────────────
      bottomNavigationBar: canComplete
          ? Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              color: const Color(0xFF0D0D14),
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: () => _complete(context),
                  child: const Text(
                    'Mark as Complete',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildMembersSection(
      BuildContext context, TeamProvider team, dynamic currentUser) {
    final assignedId = task.assignedUserId;
    final leadId = team.team?.leadId;

    if (assignedId == null || assignedId.isEmpty) {
      // Show overlapping avatars for team if no one assigned
      if (team.team != null && team.team!.memberIds.isNotEmpty) {
        final initials = team.team!.memberIds
            .map((id) => id.length >= 2 ? id.substring(0, 2).toUpperCase() : id.toUpperCase())
            .toList();
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Column(
            children: [
              Row(children: [
                OverlappingAvatars(labels: initials, maxVisible: 5),
                const SizedBox(width: 12),
                const Text(
                  'No one assigned yet',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ]),
            ],
          ),
        );
      }
      return _memberEmptyState();
    }

    // Build member row for assigned user
    final isCurrentUser = currentUser?.id == assignedId;
    final isLead = assignedId == leadId;
    final initials = assignedId.length >= 2
        ? assignedId.substring(0, 2).toUpperCase()
        : assignedId.toUpperCase();
    final displayName = isCurrentUser
        ? (currentUser?.name ?? 'You')
        : 'Team Member';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: _MemberRow(
        initials: initials,
        name: displayName,
        role: isLead ? 'Team Lead' : 'Team Member',
        isAssigned: true,
        isCurrentUser: isCurrentUser,
      ),
    );
  }

  Widget _memberEmptyState() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: const Text(
          'No one assigned yet',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
      );

  Widget _buildTimeline() {
    final events = <_TimelineEvent>[];

    events.add(_TimelineEvent(
      label: 'Task created',
      date: task.deadline.subtract(const Duration(days: 1)),
      color: AppColors.primary,
    ));

    if (task.status == TaskStatus.inProgress) {
      events.add(_TimelineEvent(
        label: 'Work started',
        date: DateTime.now().subtract(const Duration(hours: 2)),
        color: AppColors.warning,
      ));
    }

    if (task.status == TaskStatus.completed && task.completedAt != null) {
      events.add(_TimelineEvent(
        label: 'Task completed · +${task.xpEarned} XP',
        date: task.completedAt!,
        color: AppColors.success,
      ));
    }

    if (task.status == TaskStatus.overdue) {
      events.add(_TimelineEvent(
        label: 'Deadline missed',
        date: task.deadline,
        color: AppColors.danger,
      ));
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: events.asMap().entries.map((e) {
          final isLast = e.key == events.length - 1;
          return _TimelineTile(event: e.value, isLast: isLast);
        }).toList(),
      ),
    );
  }
}

// ── sub-widgets ──────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String label;
  final Widget child;

  const _InfoCard({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          child,
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  final String initials;
  final String name;
  final String role;
  final bool isAssigned;
  final bool isCurrentUser;

  const _MemberRow({
    required this.initials,
    required this.name,
    required this.role,
    required this.isAssigned,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isCurrentUser ? '$name (you)' : name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                role,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        if (isAssigned)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.success.withOpacity(0.3), width: 0.5),
            ),
            child: const Text(
              'Assigned',
              style: TextStyle(
                color: AppColors.success,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}

class _TimelineEvent {
  final String label;
  final DateTime date;
  final Color color;

  _TimelineEvent({required this.label, required this.date, required this.color});
}

class _TimelineTile extends StatelessWidget {
  final _TimelineEvent event;
  final bool isLast;

  const _TimelineTile({required this.event, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: event.color,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 1.5,
                height: 32,
                color: AppColors.border,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('MMM d, HH:mm').format(event.date),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
