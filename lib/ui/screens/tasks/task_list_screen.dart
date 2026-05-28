import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/date_utils.dart';
import '../../../data/database/app_database.dart';
import '../../../data/models/task_model.dart';
import '../../../providers/activity_provider.dart';
import '../../../data/models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/task_provider.dart';
import '../../../providers/team_provider.dart';
import '../../widgets/task_progress_ring.dart';
import 'create_task_screen.dart';
import 'task_detail_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  String _filter = 'all';
  String _search = '';

  List<TaskModel> _applyFilters(List<TaskModel> all) {
    List<TaskModel> list;
    switch (_filter) {
      case 'today':
        list = all
            .where((t) => AppDateUtils.isToday(t.deadline))
            .toList();
        break;
      case 'overdue':
        list = all
            .where((t) => t.status == TaskStatus.overdue)
            .toList();
        break;
      case 'done':
        list = all
            .where((t) => t.status == TaskStatus.completed)
            .toList();
        break;
      default:
        list = List.from(all);
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list
          .where((t) => t.title.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final teamProv = context.watch<TeamProvider>();
    final taskProv = context.watch<TaskProvider>();
    final currentUser = auth.user;

    // Team tasks live in TeamProvider (Firebase stream).
    // Personal tasks (no team) live in TaskProvider (SQLite).
    final tasks = currentUser?.hasTeam == true
        ? teamProv.tasks
        : taskProv.tasks;
    final isLoading = currentUser?.hasTeam == true
        ? teamProv.loading
        : taskProv.loading;
    final filtered = _applyFilters(tasks);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0C16),
      body: SafeArea(
        child: Column(
          children: [
            // TOP BAR
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.maybePop(context),
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
                  child: Text('My Tasks',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      )),
                ),
                if (auth.user?.canCreateTasks == true)
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              CreateTaskScreen(user: auth.user!)),
                    ).then((_) => context
                        .read<TaskProvider>()
                        .loadTasks(auth.user!.id)),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: Color(0xFF191D30),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add,
                          color: Colors.white, size: 20),
                    ),
                  )
                else
                  const SizedBox(width: 42),
              ]),
            ),

            const SizedBox(height: 16),

            // SEARCH BAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF191D30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  const SizedBox(width: 16),
                  const Icon(Icons.search,
                      color: Color(0xFF848A94), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      onChanged: (v) => setState(() => _search = v),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Search',
                        hintStyle: TextStyle(
                            color: Color(0xFF848A94), fontSize: 14),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ]),
              ),
            ),

            const SizedBox(height: 16),

            // FILTER CHIPS
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(children: [
                _chip('All', _filter == 'all'),
                _chip('Today', _filter == 'today'),
                _chip('Overdue', _filter == 'overdue'),
                _chip('Done', _filter == 'done'),
              ]),
            ),

            const SizedBox(height: 16),

            // TASKS LIST
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF3580FF)))
                  : filtered.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.task_outlined,
                                  color: Color(0xFF848A94), size: 48),
                              SizedBox(height: 12),
                              Text('No tasks yet',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'Poppins',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  )),
                              SizedBox(height: 4),
                              Text('Tasks will appear here',
                                  style: TextStyle(
                                    color: Color(0xFF848A94),
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                  )),
                            ],
                          ))
                      : ListView.builder(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: filtered.length,
                          itemBuilder: (ctx, i) {
                            final task = filtered[i];
                            return Dismissible(
                              key: Key(task.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                child: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: Colors.white,
                                    size: 26),
                              ),
                              confirmDismiss: (direction) async {
                                return await showDialog<bool>(
                                  context: ctx,
                                  builder: (dlg) => AlertDialog(
                                    backgroundColor:
                                        const Color(0xFF191D30),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16)),
                                    title: const Text('Delete Task',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        )),
                                    content: Text(
                                      'Delete "${task.title}"? This cannot be undone.',
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 14,
                                        color: Color(0xFF848A94),
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(dlg, false),
                                        child: const Text('Cancel',
                                            style: TextStyle(
                                                color:
                                                    Color(0xFF848A94)))),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(dlg, true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFFEF4444),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      8)),
                                        ),
                                        child: const Text('Delete',
                                            style: TextStyle(
                                                color: Colors.white))),
                                    ],
                                  ),
                                ) ??
                                    false;
                              },
                              onDismissed: (direction) async {
                                final taskToDelete = task;
                                final auth =
                                    ctx.read<AuthProvider>();
                                final isTeamTask =
                                    (auth.user?.hasTeam == true) &&
                                    taskToDelete.teamId.isNotEmpty;

                                try {
                                  if (isTeamTask) {
                                    ctx
                                        .read<TeamProvider>()
                                        .removeTaskLocally(
                                            taskToDelete.id);

                                    await FirebaseDatabase.instance
                                        .ref('team_tasks'
                                            '/${taskToDelete.teamId}'
                                            '/${taskToDelete.id}')
                                        .remove()
                                        .timeout(const Duration(
                                            seconds: 10));

                                    await ctx
                                        .read<TeamProvider>()
                                        .deleteTaskFromDb(
                                            taskToDelete.id);
                                  } else {
                                    await ctx
                                        .read<TaskProvider>()
                                        .deleteTask(
                                            taskToDelete.id);
                                  }

                                  await AppDatabase
                                      .deleteSubtasksForTask(
                                          taskToDelete.id);

                                  debugPrint(
                                      '[Delete] Swiped delete: '
                                      '${taskToDelete.id}');
                                } catch (e) {
                                  debugPrint(
                                      '[Delete] Swipe error: $e');
                                  if (mounted) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(const SnackBar(
                                      content: Text(
                                        'Could not delete task',
                                        style: TextStyle(
                                            fontFamily: 'Poppins')),
                                      backgroundColor:
                                          Color(0xFFEF4444)));
                                  }
                                }
                              },
                              child: _TaskCard(task: task),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, bool isActive) => GestureDetector(
        onTap: () => setState(() => _filter = label.toLowerCase()),
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF3580FF)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: isActive
                ? null
                : Border.all(color: const Color(0xFF191D30)),
          ),
          child: Text(label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color:
                    isActive ? Colors.white : const Color(0xFF848A94),
                fontWeight:
                    isActive ? FontWeight.w500 : FontWeight.normal,
              )),
        ),
      );
}

class _TaskCard extends StatefulWidget {
  final TaskModel task;
  const _TaskCard({required this.task});

  @override
  State<_TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<_TaskCard> {
  TaskModel get task => widget.task;

  Future<(int, int)>? _subtaskFuture;

  @override
  void initState() {
    super.initState();
    _initSubtaskFuture();
  }

  @override
  void didUpdateWidget(covariant _TaskCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task.id != widget.task.id ||
        oldWidget.task.progress != widget.task.progress) {
      setState(_initSubtaskFuture);
    }
  }

  void _initSubtaskFuture() {
    _subtaskFuture = AppDatabase.getSubtaskProgress(widget.task.id);
  }

  // ── Static styles ──────────────────────────────────────────────
  static const _titleStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );
  static const _diffStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 12,
    color: Color(0xFF848A94),
  );
  static const _assigneeStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 11,
    color: Color(0xFF3580FF),
  );
  static const _openStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 11,
    color: Color(0xFF848A94),
  );
  static const _cardDeco = BoxDecoration(
    color: Color(0xFF0A0C16),
    border: Border.fromBorderSide(
        BorderSide(color: Color(0xFF191D30))),
    borderRadius: BorderRadius.all(Radius.circular(14)),
  );
  static double _taskProgress(TaskModel task) {
    if (task.status == TaskStatus.completed) return 1.0;
    return (task.progress / 100.0).clamp(0.0, 1.0);
  }

  static Color _taskProgressColor(TaskModel task) {
    switch (task.status) {
      case TaskStatus.completed:
        return const Color(0xFF22C55E);
      case TaskStatus.overdue:
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF3580FF);
    }
  }

  // ── Status button ──────────────────────────────────────────────

  Widget _buildStatusButton(BuildContext context) {
    final currentUser = context.read<AuthProvider>().user;
    if (currentUser == null) return const SizedBox.shrink();

    final canAct = task.assignedUserId == null ||
        task.assignedUserId!.isEmpty ||
        task.assignedUserId == currentUser.id;

    switch (task.status) {
      case TaskStatus.pending:
        if (currentUser.role == UserRole.teamLead) return const SizedBox.shrink();
        if (!canAct) return _lockedBadge();
        return _actionButton(
          label: 'Start',
          icon: Icons.play_arrow_rounded,
          color: const Color(0xFF3580FF),
          onTap: () async {
            final user = context.read<AuthProvider>().user;
            if (user == null) return;
            // Capture before any await to avoid BuildContext-across-gap lint
            final teamProv = context.read<TeamProvider>();
            final activityProv = context.read<ActivityProvider>();
            final messenger = ScaffoldMessenger.of(context);
            try {
              await teamProv.startTask(task.id, user);
              await activityProv.onTaskStarted(user, task);
            } catch (e) {
              messenger.showSnackBar(SnackBar(
                content: Text(e.toString()),
                backgroundColor: const Color(0xFFEF4444),
              ));
            }
          },
        );

      case TaskStatus.inProgress:
        return const SizedBox.shrink();

      case TaskStatus.overdue:
        return const SizedBox.shrink();

      case TaskStatus.completed:
        return _completedBadge();
    }
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: color,
                )),
          ]),
        ),
      );

  Widget _lockedBadge() => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: const BoxDecoration(
          color: Color(0xFF191D30),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.lock_outline, color: Color(0xFF444444), size: 12),
          SizedBox(width: 3),
          Text('Not assigned',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                color: Color(0xFF444444),
              )),
        ]),
      );

  Widget _completedBadge() => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF22C55E).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: const Color(0xFF22C55E).withValues(alpha: 0.4)),
        ),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.check_circle,
              color: Color(0xFF22C55E), size: 14),
          SizedBox(width: 4),
          Text('Done',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF22C55E),
              )),
        ]),
      );

  @override
  Widget build(BuildContext context) {

    final diffLabel = task.difficulty >= 8
        ? 'Hard Task'
        : task.difficulty >= 5
            ? 'Medium Task'
            : 'Easy Task';

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(
              builder: (_) => TaskDetailScreen(task: task))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: _cardDeco,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header row ─────────────────────────────────────
              Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(task.title,
                          style: _titleStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(diffLabel, style: _diffStyle),
                    ],
                  ),
                ),
                TaskProgressRing(
                  progress: _taskProgress(task),
                  color: _taskProgressColor(task),
                  size: 44,
                  strokeWidth: 3.5,
                ),
              ]),

              FutureBuilder<(int, int)>(
                future: _subtaskFuture,
                builder: (context, snap) {
                  if (!snap.hasData || snap.data!.$2 == 0) {
                    return const SizedBox(height: 10);
                  }
                  final done = snap.data!.$1;
                  final total = snap.data!.$2;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 2),
                    child: Row(children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: total > 0 ? done / total : 0,
                            backgroundColor: const Color(0xFF2A2F45),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              done == total
                                  ? const Color(0xFF22C55E)
                                  : const Color(0xFF3580FF),
                            ),
                            minHeight: 3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$done/$total subtasks',
                        style: const TextStyle(
                          color: Color(0xFF848A94),
                          fontSize: 10,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ]),
                  );
                },
              ),

              const SizedBox(height: 8),

              if (task.deadline.isBefore(DateTime.now()) &&
                  task.status != TaskStatus.completed) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 11,
                      color: Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${DateTime.now().difference(task.deadline).inDays}d overdue',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: Color(0xFFEF4444),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],

              // ── Assignee badge + complete button ───────────────
              Row(children: [
                if (task.assignedUserName != null &&
                    task.assignedUserName!.isNotEmpty)
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.person_outline,
                        size: 11, color: Color(0xFF3580FF)),
                    const SizedBox(width: 3),
                    Text(task.assignedUserName!,
                        style: _assigneeStyle),
                  ])
                else
                  const Text('Open to all', style: _openStyle),
                const Spacer(),
                _buildStatusButton(context),
              ]),

            ],
          ),
        ),
      ),
    );
  }
}
