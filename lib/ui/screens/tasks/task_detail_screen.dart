import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/database/app_database.dart';
import '../../../data/models/subtask_model.dart';
import '../../../data/models/task_model.dart';
import '../../../data/models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/challenge_provider.dart';
import '../../../providers/gamification_provider.dart';
import '../../../providers/task_provider.dart';
import '../../../providers/team_provider.dart';
import '../../widgets/overlapping_avatars.dart';

class TaskDetailScreen extends StatefulWidget {
  final TaskModel task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  List<SubtaskModel> _subtasks = [];
  bool _loadingSubtasks = true;
  final _subtaskController = TextEditingController();
  late TaskStatus _localStatus;

  // ── computed helpers ────────────────────────────────────

  double get _progressValue {
    if (_localStatus == TaskStatus.completed) return 1.0;
    if (_subtasks.isEmpty) {
      return (widget.task.progress / 100).clamp(0.0, 1.0);
    }
    final done = _subtasks.where((s) => s.isCompleted).length;
    return done / _subtasks.length;
  }

  int get _progressPercent => (_progressValue * 100).round();

  Color get _ringColor {
    if (_localStatus == TaskStatus.completed || _progressPercent >= 100) {
      return const Color(0xFF22C55E);
    }
    return const Color(0xFF3580FF);
  }

  Color get _statusColor {
    switch (_localStatus) {
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
    switch (_localStatus) {
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
    if (widget.task.difficulty >= 8) return AppColors.danger;
    if (widget.task.difficulty >= 5) return AppColors.warning;
    return AppColors.success;
  }

  // ── lifecycle ───────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _localStatus = widget.task.status;
    _loadSubtasks();
  }

  @override
  void dispose() {
    _subtaskController.dispose();
    super.dispose();
  }

  // ── subtask CRUD ────────────────────────────────────────

  Future<void> _loadSubtasks() async {
    final list = await AppDatabase.getSubtasks(widget.task.id);
    if (mounted) {
      setState(() {
        _subtasks = list;
        _loadingSubtasks = false;
      });
    }
  }

  Future<void> _addSubtask() async {
    final title = _subtaskController.text.trim();
    if (title.isEmpty) return;
    final sub = SubtaskModel(
      id: const Uuid().v4(),
      taskId: widget.task.id,
      title: title,
      sortOrder: _subtasks.length,
    );
    await AppDatabase.insertSubtask(sub);
    _subtaskController.clear();
    if (mounted) setState(() => _subtasks = [..._subtasks, sub]);
  }

  Future<void> _toggleSubtask(SubtaskModel sub) async {
    final updated = sub.copyWith(isCompleted: !sub.isCompleted);
    await AppDatabase.toggleSubtask(updated.id, updated.isCompleted);
    if (mounted) {
      setState(() {
        final idx = _subtasks.indexWhere((s) => s.id == sub.id);
        if (idx != -1) {
          final list = List<SubtaskModel>.from(_subtasks);
          list[idx] = updated;
          _subtasks = list;
        }
      });
      _onSubtaskToggled();
    }
  }

  void _onSubtaskToggled() {
    final total = _subtasks.length;
    if (total == 0) return;
    final done = _subtasks.where((s) => s.isCompleted).length;
    final newProgress = ((done / total) * 100).round();

    if (widget.task.teamId.isNotEmpty) {
      final liveTask = context
          .read<TeamProvider>()
          .tasks
          .firstWhere(
            (t) => t.id == widget.task.id,
            orElse: () => widget.task,
          );
      context.read<TeamProvider>().updateTaskProgress(
          widget.task.id, newProgress, liveTask.status.name);
    }

    setState(() {}); // rebuild ring + complete button
  }

  Future<void> _deleteSubtask(SubtaskModel sub) async {
    await AppDatabase.deleteSubtask(sub.id);
    if (mounted) {
      setState(() =>
          _subtasks = _subtasks.where((s) => s.id != sub.id).toList());
    }
  }

  // ── complete task ───────────────────────────────────────

  Future<void> _completeTask() async {
    // Guard: all subtasks must be ticked first
    if (_subtasks.isNotEmpty && !_subtasks.every((s) => s.isCompleted)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete all subtasks first!'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Capture providers before any await
    final auth = context.read<AuthProvider>();
    if (auth.user == null) return;
    final user = auth.user!;

    final taskProvider = context.read<TaskProvider>();
    final teamProv = context.read<TeamProvider>();
    final gam = context.read<GamificationProvider>();
    final cp = context.read<ChallengeProvider>();

    try {
      final isTeamTask = user.hasTeam && widget.task.teamId.isNotEmpty;

      final TaskModel completed;
      if (isTeamTask) {
        // completeTask writes to Firebase (status + progress:100 + completedAt)
        completed = await teamProv.completeTask(widget.task.id, user);
        // updateTaskProgress syncs local state, SQLite, and Firebase progress field
        await teamProv.updateTaskProgress(widget.task.id, 100, 'completed');
      } else {
        completed = await taskProvider.completeTask(widget.task.id);
      }

      final result = await gam.handleCompletion(completed, user);

      // Refresh dashboard XP/coins immediately
      if (gam.user != null && mounted) {
        auth.refresh(gam.user!);
      }

      // Challenge XP uses the gamification-adjusted value (respects xpMultiplier)
      if (result.xpEarned > 0 &&
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
              result.xpEarned,
            );
          }
        }
      }

      if (mounted) {
        // Flip the ring to green immediately — no round-trip needed
        setState(() => _localStatus = TaskStatus.completed);

        final xp = result.xpEarned;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: AppColors.success,
          content: Text(
            xp > 0
                ? '✅ Task complete! +$xp XP earned'
                : '✅ Task marked complete',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w500),
          ),
          duration: const Duration(seconds: 3),
        ));

        if (result.achievements.isNotEmpty) {
          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
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

        await Future.delayed(const Duration(milliseconds: 1200));
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('[TaskDetail] complete error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e',
              style: const TextStyle(fontFamily: 'Poppins')),
          backgroundColor: AppColors.danger,
        ));
      }
    }
  }

  // ── build ───────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final team = context.watch<TeamProvider>();
    final auth = context.watch<AuthProvider>();
    final currentUser = auth.user;

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
          widget.task.title,
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
              widget.task.createdBy == currentUser?.id)
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
                    title: const Text(
                      'Delete Task?',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                    content: const Text(
                      'This will permanently delete '
                      'the task and all its subtasks.',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Color(0xFF848A94),
                        fontSize: 13)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: Color(0xFF848A94)))),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8))),
                        child: const Text('Delete',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.white,
                              fontWeight: FontWeight.w600))),
                    ],
                  ),
                );

                if (confirm != true) return;
                if (!mounted) return;

                try {
                  final auth = context.read<AuthProvider>();
                  final user = auth.user;
                  final isTeamTask =
                      (user?.hasTeam == true) &&
                      widget.task.teamId.isNotEmpty;

                  if (isTeamTask) {
                    context
                        .read<TeamProvider>()
                        .removeTaskLocally(widget.task.id);

                    await FirebaseDatabase.instance
                        .ref('team_tasks'
                            '/${widget.task.teamId}'
                            '/${widget.task.id}')
                        .remove()
                        .timeout(const Duration(seconds: 10));

                    await context
                        .read<TeamProvider>()
                        .deleteTaskFromDb(widget.task.id);
                  } else {
                    await context
                        .read<TaskProvider>()
                        .deleteTask(widget.task.id);
                  }

                  await AppDatabase
                      .deleteSubtasksForTask(widget.task.id);

                  debugPrint('[Delete] Task deleted: '
                      '${widget.task.id}');

                  if (mounted) {
                    Navigator.pop(context);
                  }
                } catch (e) {
                  debugPrint('[Delete] Error: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Failed to delete: $e',
                          style: const TextStyle(
                            fontFamily: 'Poppins')),
                        backgroundColor:
                          const Color(0xFFEF4444)));
                  }
                }
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
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
              widget.task.title,
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
            LayoutBuilder(
              builder: (context, constraints) {
                final ringSize =
                    MediaQuery.of(context).size.width * 0.38;
                return Center(
                  child: SizedBox(
                    width: ringSize,
                    height: ringSize,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: _progressValue,
                          strokeWidth: 10,
                          backgroundColor: const Color(0xFF1E2235),
                          valueColor:
                              AlwaysStoppedAnimation<Color>(_ringColor),
                        ),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FittedBox(
                                child: Text(
                                  _localStatus == TaskStatus.completed
                                      ? '100%'
                                      : '$_progressPercent%',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                    color: _ringColor,
                                  ),
                                ),
                              ),
                              Text(
                                _localStatus == TaskStatus.completed
                                    ? 'done'
                                    : 'complete',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF848A94),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
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
                        '${widget.task.difficulty}/10',
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
                    widget.task.status == TaskStatus.completed
                        ? '+${widget.task.xpEarned} XP'
                        : '+${widget.task.difficulty * 10} XP',
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
                    DateFormat('MMM d').format(widget.task.deadline),
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
                widget.task.description?.isNotEmpty == true
                    ? widget.task.description!
                    : 'No description provided.',
                style: TextStyle(
                  color: widget.task.description?.isNotEmpty == true
                      ? AppColors.textSecondary
                      : AppColors.textMuted,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── subtasks ──────────────────────────────
            _SectionTitle('Subtasks'),
            const SizedBox(height: 10),
            _SubtasksSection(
              subtasks: _subtasks,
              loading: _loadingSubtasks,
              controller: _subtaskController,
              isTeamLead: currentUser?.role == UserRole.teamLead,
              onAdd: _addSubtask,
              onToggle: _toggleSubtask,
              onDelete: _deleteSubtask,
              taskCompleted:
                  _localStatus == TaskStatus.completed,
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
            ),
            if (currentUser != null) _buildBottomBar(currentUser),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(UserModel user) {
    // Case 1: Already completed
    if (_localStatus == TaskStatus.completed) {
      return _bottomContainer(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 20),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Task Completed',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: TextStyle(
                  color: Color(0xFF22C55E),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        color: const Color(0xFF22C55E).withValues(alpha: 0.1),
        borderColor: const Color(0xFF22C55E).withValues(alpha: 0.3),
      );
    }

    // Case 2: Team Lead — always show this
    if (user.role == UserRole.teamLead) {
      return _bottomContainer(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.info_outline,
              color: const Color(0xFF848A94).withValues(alpha: 0.7),
              size: 16,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Only assigned members can complete this task',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: TextStyle(
                  color: const Color(0xFF848A94).withValues(alpha: 0.7),
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        color: const Color(0xFF1E2235),
        borderColor: const Color(0xFF2A2D3E),
      );
    }

    // Case 3: Assigned to someone else
    final assigned = widget.task.assignedUserId;
    final isOtherPerson =
        assigned != null && assigned.isNotEmpty && assigned != user.id;

    if (isOtherPerson) {
      return _bottomContainer(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_outline,
                color: Color(0xFF848A94), size: 16),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Assigned to '
                '${widget.task.assignedUserName ?? "another member"}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: const TextStyle(
                    color: Color(0xFF848A94), fontSize: 13),
              ),
            ),
          ],
        ),
        color: const Color(0xFF1E2235),
        borderColor: const Color(0xFF2A2D3E),
      );
    }

    // Case 4: Subtasks not all done yet
    final allDone =
        _subtasks.isEmpty || _subtasks.every((s) => s.isCompleted);

    if (!allDone) {
      final done = _subtasks.where((s) => s.isCompleted).length;
      final total = _subtasks.length;
      return _bottomContainer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Complete all subtasks first',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$done of $total done',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: const TextStyle(
                color: Color(0xFF3580FF),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        color: const Color(0xFF1E2235),
        borderColor: const Color(0xFF2A2D3E),
      );
    }

    // Case 5: CAN complete — active button
    return GestureDetector(
      onTap: _completeTask,
      child: _bottomContainer(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Mark as Complete',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
        color: const Color(0xFF22C55E),
        borderColor: const Color(0xFF22C55E),
        isActive: true,
      ),
    );
  }

  Widget _bottomContainer({
    required Widget child,
    required Color color,
    required Color borderColor,
    bool isActive = false,
  }) {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: isActive ? 0 : 1),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: child,
      ),
    );
  }

  Widget _buildMembersSection(
      BuildContext context, TeamProvider team, dynamic currentUser) {
    final assignedId = widget.task.assignedUserId;
    final leadId = team.team?.leadId;

    if (assignedId == null || assignedId.isEmpty) {
      if (team.team != null && team.team!.memberIds.isNotEmpty) {
        final initials = team.team!.memberIds
            .map((id) => id.length >= 2
                ? id.substring(0, 2).toUpperCase()
                : id.toUpperCase())
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

    final isCurrentUser = currentUser?.id == assignedId;
    final isLead = assignedId == leadId;
    final initials = assignedId.length >= 2
        ? assignedId.substring(0, 2).toUpperCase()
        : assignedId.toUpperCase();
    final displayName =
        isCurrentUser ? (currentUser?.name ?? 'You') : 'Team Member';

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

    if (widget.task.status == TaskStatus.inProgress) {
      events.add(_TimelineEvent(
        label: 'Work started',
        date: DateTime.now().subtract(const Duration(hours: 2)),
        color: AppColors.warning,
      ));
    }

    if (widget.task.status == TaskStatus.completed &&
        widget.task.completedAt != null) {
      events.add(_TimelineEvent(
        label: 'Task completed · +${widget.task.xpEarned} XP',
        date: widget.task.completedAt!,
        color: AppColors.success,
      ));
    }

    if (widget.task.status == TaskStatus.overdue) {
      events.add(_TimelineEvent(
        label: 'Deadline missed',
        date: widget.task.deadline,
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

class _SubtasksSection extends StatelessWidget {
  final List<SubtaskModel> subtasks;
  final bool loading;
  final TextEditingController controller;
  final Future<void> Function() onAdd;
  final Future<void> Function(SubtaskModel) onToggle;
  final Future<void> Function(SubtaskModel) onDelete;
  final bool taskCompleted;
  final bool isTeamLead;

  const _SubtasksSection({
    required this.subtasks,
    required this.loading,
    required this.controller,
    required this.onAdd,
    required this.onToggle,
    required this.onDelete,
    required this.taskCompleted,
    required this.isTeamLead,
  });

  @override
  Widget build(BuildContext context) {
    final total = subtasks.length;
    final done = subtasks.where((s) => s.isCompleted).length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (total > 0) ...[
            Row(children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: done / total,
                    backgroundColor: const Color(0xFF2A2F45),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      done == total ? AppColors.success : AppColors.primary,
                    ),
                    minHeight: 4,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$done / $total',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ]),
            const SizedBox(height: 12),
          ],
          if (loading)
            const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else ...[
            if (subtasks.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
                child: Row(
                  children: [
                    Icon(
                      isTeamLead
                          ? Icons.add_circle_outline
                          : Icons.checklist_rounded,
                      size: 14,
                      color: const Color(0xFF848A94),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isTeamLead
                          ? 'Break this task into steps'
                          : 'No subtasks added yet',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: Color(0xFF848A94),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ...subtasks.map((sub) => _SubtaskTile(
                  subtask: sub,
                  isTeamLead: isTeamLead,
                  onToggle: taskCompleted ? null : () => onToggle(sub),
                  onDelete: taskCompleted ? null : () => onDelete(sub),
                )),
            if (!taskCompleted && isTeamLead) ...[
              if (subtasks.isNotEmpty) const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontFamily: 'Poppins',
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Add a subtask...',
                      hintStyle: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                        fontFamily: 'Poppins',
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: (_) => onAdd(),
                  ),
                ),
                GestureDetector(
                  onTap: onAdd,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.add,
                      color: AppColors.primary,
                      size: 16,
                    ),
                  ),
                ),
              ]),
            ],
          ],
        ],
      ),
    );
  }
}

class _SubtaskTile extends StatelessWidget {
  final SubtaskModel subtask;
  final bool isTeamLead;
  final VoidCallback? onToggle;
  final VoidCallback? onDelete;

  const _SubtaskTile({
    required this.subtask,
    required this.isTeamLead,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: isTeamLead
                ? () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Assign this task to a team member'
                          ' to track subtask progress',
                        ),
                        backgroundColor: Color(0xFF2A2D3E),
                        duration: Duration(seconds: 2),
                      ),
                    )
                : onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: subtask.isCompleted
                    ? const Color(0xFF22C55E)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isTeamLead
                      ? const Color(0xFF848A94).withValues(alpha: 0.3)
                      : subtask.isCompleted
                          ? const Color(0xFF22C55E)
                          : const Color(0xFF3580FF).withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: subtask.isCompleted
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              subtask.title,
              style: TextStyle(
                color: subtask.isCompleted
                    ? AppColors.textMuted
                    : AppColors.textSecondary,
                fontSize: 13,
                decoration: subtask.isCompleted
                    ? TextDecoration.lineThrough
                    : null,
                decorationColor: AppColors.textMuted,
              ),
            ),
          ),
          if (isTeamLead && onDelete != null)
            GestureDetector(
              onTap: onDelete,
              child: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.close, size: 14, color: AppColors.textMuted),
              ),
            ),
        ],
      ),
    );
  }
}

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
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(child: child),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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

  _TimelineEvent(
      {required this.label, required this.date, required this.color});
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
