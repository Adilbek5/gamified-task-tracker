import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/task_model.dart';
import '../../../data/models/user_model.dart';
import '../../../providers/activity_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/challenge_provider.dart';
import '../../../providers/gamification_provider.dart';
import '../../../providers/shop_provider.dart';
import '../../../providers/task_provider.dart';
import '../../../providers/team_provider.dart';
import '../../widgets/task_progress_ring.dart';
import '../auth/login_screen.dart';
import '../challenges/challenge_screen.dart';
import '../tasks/create_task_screen.dart';
import '../tasks/task_detail_screen.dart';
import '../tasks/task_list_screen.dart';
import '../profile/profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _idx = 0;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_loaded) return;
      _loaded = true;

      if (!mounted) return;
      final user = context.read<AuthProvider>().user;
      if (user == null) return;

      // Load gamification
      context.read<GamificationProvider>().load(user);

      // Always load team tasks for ALL users (lead AND member)
      if (user.hasTeam) {
        debugPrint('[Dashboard] Loading team: ${user.teamId}');
        final teamProv = context.read<TeamProvider>();
        await teamProv.loadTeam(user);
        debugPrint('[Dashboard] Tasks count: ${teamProv.tasks.length}');

        // Start challenge listener
        if (mounted) {
          context.read<ChallengeProvider>()
            .listenChallenges(user.teamId!);
        }

        // Start activity tracking
        if (mounted) {
          context.read<ActivityProvider>().setUserOnline(user);
          context.read<ActivityProvider>()
            .startListening(user.teamId!);
        }
      }

      // Load personal tasks
      if (mounted) {
        context.read<TaskProvider>().loadTasks(
          user.id,
          teamId: user.teamId,
        );
      }
    });
  }

  Widget _navItem(IconData icon, int index, int currentIndex,
      {VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap ?? () => setState(() => _idx = index),
        child: Container(
          color: Colors.transparent,
          child: Icon(
            icon,
            color: currentIndex == index
                ? const Color(0xFF3580FF)
                : const Color(0xFF848A94),
            size: 24,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    if (user == null) return const LoginScreen();

    final gam = context.watch<GamificationProvider>();
    // ignore: unused_local_variable
    final shop = context.watch<ShopProvider>();
    // ignore: unused_local_variable
    final challenges = context.watch<ChallengeProvider>();

    Widget body;
    switch (_idx) {
      case 1:
        body = const TaskListScreen();
        break;
      case 3:
        body = ProfileScreen(user: user, gam: gam);
        break;
      default:
        body = _HomeTab(user: user);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0C16),
      body: body,
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF3580FF),
        elevation: 6,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
        onPressed: () {
          if (user.canCreateTasks) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CreateTaskScreen(user: user)),
            );
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0A0C16),
          border: Border(
              top: BorderSide(color: Color(0xFF191D30), width: 0.5)),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(children: [
              _navItem(Icons.home_rounded, 0, _idx),
              _navItem(Icons.folder_outlined, 1, _idx),
              const Expanded(child: SizedBox()), // FAB space
              _navItem(Icons.emoji_events_outlined, 2, _idx, onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ChallengeScreen(user: user)),
                );
              }),
              _navItem(Icons.person_outline, 3, _idx),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  DASHBOARD SELECTOR DATA
// ─────────────────────────────────────────────
class _DashboardData {
  final List<TaskModel> personalTasks;
  final List<TaskModel> teamTasks;
  final String teamName;
  final int teamCompleted;
  final int teamTotal;
  final int membersCount;

  const _DashboardData({
    required this.personalTasks,
    required this.teamTasks,
    required this.teamName,
    required this.teamCompleted,
    required this.teamTotal,
    required this.membersCount,
  });
}

// ─────────────────────────────────────────────
//  STATIC STYLES
// ─────────────────────────────────────────────
class _HomeStyles {
  static const dateStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );
  static const greetingStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.35,
  );
  static const sectionTitle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
  static const taskTitle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );
  static const taskSub = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 11,
    color: Color(0xFF848A94),
  );
  static const cardDark = BoxDecoration(
    color: Color(0xFF0A0C16),
    border: Border.fromBorderSide(
        BorderSide(color: Color(0xFF191D30))),
    borderRadius: BorderRadius.all(Radius.circular(14)),
  );
}

// ─────────────────────────────────────────────
//  HOME TAB
// ─────────────────────────────────────────────
class _HomeTab extends StatefulWidget {
  final UserModel user;

  const _HomeTab({required this.user});

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  @override
  Widget build(BuildContext context) {
    // Selector2 watches both providers; rebuilds on any task data change.
    // List.from() snapshots the list at selection time so shouldRebuild can
    // detect in-place mutations (e.g. removeTaskLocally) via length/id checks.
    return Selector2<TaskProvider, TeamProvider, _DashboardData>(
      selector: (_, taskProv, teamProv) => _DashboardData(
        personalTasks: List<TaskModel>.from(taskProv.tasks),
        teamTasks: List<TaskModel>.from(teamProv.tasks),
        teamName: teamProv.team?.name ?? 'Team Tasks',
        teamCompleted: teamProv.completedTasks.length,
        teamTotal: teamProv.tasks.length,
        membersCount: teamProv.team?.memberIds.length ?? 0,
      ),
      shouldRebuild: (prev, next) {
        if (prev.teamTasks.length !=
            next.teamTasks.length) { return true; }
        if (prev.personalTasks.length !=
            next.personalTasks.length) { return true; }
        if (prev.membersCount !=
            next.membersCount) { return true; }
        if (prev.teamCompleted !=
            next.teamCompleted) { return true; }

        final prevTeamStatuses = prev.teamTasks
            .map((t) => '${t.id}:${t.progress}:${t.status.name}')
            .join('|');
        final nextTeamStatuses = next.teamTasks
            .map((t) => '${t.id}:${t.progress}:${t.status.name}')
            .join('|');
        if (prevTeamStatuses != nextTeamStatuses) return true;

        final prevPersonalStatuses = prev.personalTasks
            .map((t) => '${t.id}:${t.progress}:${t.status.name}')
            .join('|');
        final nextPersonalStatuses = next.personalTasks
            .map((t) => '${t.id}:${t.progress}:${t.status.name}')
            .join('|');
        if (prevPersonalStatuses != nextPersonalStatuses) return true;

        return false;
      },
      builder: (context, data, child) {
        // Merge personal + team tasks, deduplicate by id.
        final merged = <String, TaskModel>{};
        for (final t in data.personalTasks) { merged[t.id] = t; }
        for (final t in data.teamTasks) { merged[t.id] = t; }

        final allTasks = merged.values.toList()
          ..sort((a, b) => a.deadline.compareTo(b.deadline));

        // "In Progress" shows pending/inProgress tasks only (max 3).
        final inProgress = allTasks
            .where((t) =>
                t.status == TaskStatus.pending ||
                t.status == TaskStatus.inProgress)
            .take(3)
            .toList();

        final completedCount =
            allTasks.where((t) => t.status == TaskStatus.completed).length;
        final totalCount = allTasks.length;
        final progress =
            totalCount > 0 ? completedCount / totalCount : 0.0;

        return _buildHomeContent(
          context: context,
          inProgressTasks: inProgress,
          teamName: data.teamName,
          membersCount: data.membersCount,
          completed: completedCount,
          total: totalCount,
          progress: progress,
        );
      },
    );
  }

  Widget _buildHomeContent({
    required BuildContext context,
    required List<TaskModel> inProgressTasks,
    required String teamName,
    required int membersCount,
    required int completed,
    required int total,
    required double progress,
  }) {
    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _TopBar(user: widget.user),
                  const SizedBox(height: 20),
                  const _GreetingSection(),
                  const SizedBox(height: 24),
                  RepaintBoundary(
                    child: _TeamCard(
                      teamName: teamName,
                      membersCount: membersCount,
                      completed: completed,
                      total: total,
                      progress: progress,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const _SectionHeader(),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),

          if (inProgressTasks.isEmpty)
            const SliverToBoxAdapter(child: _EmptyTasksCard())
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => RepaintBoundary(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TaskDetailScreen(
                              task: inProgressTasks[i],
                            ),
                          ),
                        ).then((_) {
                          if (mounted) setState(() {});
                        });
                      },
                      child: _DashTaskCard(
                        task: inProgressTasks[i],
                        currentUserId: widget.user.id,
                      ),
                    ),
                  ),
                  childCount: inProgressTasks.length,
                ),
              ),
            ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Consumer<ActivityProvider>(
                builder: (ctx, activity, _) {
                  final active = activity.activeMembers;
                  if (active.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      Row(children: [
                        Container(width: 7, height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFF22C55E),
                            shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        const Text('Live Activity',
                          style: TextStyle(fontFamily: 'Poppins',
                            fontSize: 16, fontWeight: FontWeight.w600,
                            color: Colors.white)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8)),
                          child: Text('${active.length} working',
                            style: const TextStyle(fontFamily: 'Poppins',
                              fontSize: 10, color: Color(0xFF22C55E),
                              fontWeight: FontWeight.w500))),
                      ]),
                      const SizedBox(height: 12),
                      ...active.take(3).map((m) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF191D30),
                          borderRadius: BorderRadius.circular(12)),
                        child: Row(children: [
                          if (!m.isTeamLead) ...[
                            Text(m.skillEmoji,
                              style: const TextStyle(fontSize: 16)),
                          ] else ...[
                            const Text('👑',
                              style: TextStyle(fontSize: 12)),
                          ],
                          const SizedBox(width: 10),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Text(m.name,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins', fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white)),
                                const SizedBox(width: 6),
                                if (!m.isTeamLead)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: m.skillColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(5)),
                                    child: Text(m.skillLabel,
                                      style: TextStyle(fontFamily: 'Poppins',
                                        fontSize: 8, fontWeight: FontWeight.w600,
                                        color: m.skillColor))),
                              ]),
                              Text(m.currentTaskTitle ?? '',
                                style: const TextStyle(fontFamily: 'Poppins',
                                  fontSize: 11, color: Color(0xFF3580FF)),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            ])),
                          Container(width: 8, height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF22C55E),
                              shape: BoxShape.circle)),
                        ])),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  TOP BAR
// ─────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final UserModel user;
  const _TopBar({required this.user});

  String _getDateString() {
    final now = DateTime.now();
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[now.weekday - 1]}, ${now.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      GestureDetector(
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Menu coming soon'),
              backgroundColor: Color(0xFF191D30),
              duration: Duration(seconds: 1),
            )),
        child: const _CircleButton(
          child: Icon(Icons.grid_view_rounded,
              color: Colors.white, size: 20),
        ),
      ),
      Expanded(
        child: Text(
          _getDateString(),
          textAlign: TextAlign.center,
          style: _HomeStyles.dateStyle,
        ),
      ),
      GestureDetector(
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No new notifications'),
              backgroundColor: Color(0xFF191D30),
              duration: Duration(seconds: 1),
            )),
        child: const _CircleButton(
          child: Icon(Icons.notifications_outlined,
              color: Colors.white, size: 20),
        ),
      ),
    ]);
  }
}

class _CircleButton extends StatelessWidget {
  final Widget child;
  const _CircleButton({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: const BoxDecoration(
        color: Color(0xFF191D30),
        shape: BoxShape.circle,
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────
//  GREETING SECTION
// ─────────────────────────────────────────────
class _GreetingSection extends StatelessWidget {
  const _GreetingSection();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Text(
          "Let's make a tasks\ntogether 🙌",
          style: _HomeStyles.greetingStyle,
        ),
        Positioned(
          right: 24,
          top: -4,
          child: Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Color(0xFFFFD700),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          right: 0,
          top: 18,
          child: Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Color(0xFF3580FF),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  TEAM CARD
// ─────────────────────────────────────────────
class _TeamCard extends StatelessWidget {
  final String teamName;
  final int membersCount;
  final int completed;
  final int total;
  final double progress;

  const _TeamCard({
    required this.teamName,
    required this.membersCount,
    required this.completed,
    required this.total,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 130,
      decoration: const BoxDecoration(
        color: Color(0xFF3580FF),
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            right: -30,
            bottom: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      teamName,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      membersCount > 0
                        ? '$membersCount member${membersCount == 1 ? '' : 's'} · Current Sprint'
                        : 'Current Sprint',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Color(0xFFC5DAFD),
                      ),
                    ),
                  ],
                ),
                Row(children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                      color: Color(0xFF22C55E),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFD700),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Progress  $completed/$total',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: Color(0xFFC5DAFD),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 110,
                        child: ClipRRect(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(3)),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 5,
                            backgroundColor: const Color(0xFF004CCD),
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(
                                    Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SECTION HEADER
// ─────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  const _SectionHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(children: [
      Text('In Progress', style: _HomeStyles.sectionTitle),
      Spacer(),
      Icon(Icons.arrow_forward_ios, color: Colors.white, size: 15),
    ]);
  }
}

// ─────────────────────────────────────────────
//  EMPTY TASKS CARD
// ─────────────────────────────────────────────
class _EmptyTasksCard extends StatelessWidget {
  const _EmptyTasksCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF191D30),
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
        child: const Center(
          child: Text(
            'No tasks yet',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: Color(0xFF848A94),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  TASK CARD
// ─────────────────────────────────────────────
class _DashTaskCard extends StatelessWidget {
  final TaskModel task;
  final String currentUserId;

  const _DashTaskCard({
    required this.task,
    required this.currentUserId,
  });

  double get _progress {
    if (task.status == TaskStatus.completed) return 1.0;
    return (task.progress / 100.0).clamp(0.0, 1.0);
  }

  Color get _progressColor {
    switch (task.status) {
      case TaskStatus.completed:
        return const Color(0xFF22C55E);
      case TaskStatus.overdue:
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF3580FF);
    }
  }

  String get _timeAgo {
    final diff = DateTime.now().difference(task.deadline);
    if (diff.inMinutes.abs() < 60) {
      return diff.isNegative
          ? '${diff.inMinutes.abs()} min left'
          : '${diff.inMinutes} min ago';
    }
    if (diff.inHours.abs() < 24) {
      return diff.isNegative
          ? '${diff.inHours.abs()} hours left'
          : '${diff.inHours} hours ago';
    }
    return diff.isNegative
        ? '${diff.inDays.abs()} days left'
        : '${diff.inDays} days ago';
  }

  String get _diffLabel =>
      task.difficulty >= 8 ? 'Hard' : task.difficulty >= 5 ? 'Medium' : 'Easy';

  @override
  Widget build(BuildContext context) {
    final progress = _progress;
    final color = _progressColor;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: _HomeStyles.cardDark,
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_diffLabel, style: _HomeStyles.taskSub),
              const SizedBox(height: 3),
              Text(
                task.title,
                style: _HomeStyles.taskTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(_timeAgo, style: _HomeStyles.taskSub),
            ],
          ),
        ),
        const SizedBox(width: 12),
        TaskProgressRing(
          progress: progress,
          color: color,
          size: 44,
          strokeWidth: 3.5,
        ),
      ]),
    );
  }
}

