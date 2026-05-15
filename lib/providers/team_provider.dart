import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../data/models/team_model.dart';
import '../data/models/task_model.dart';
import '../data/models/user_model.dart';
import '../data/repositories/task_repository.dart';
import '../data/repositories/user_repository.dart';
import '../services/team_service.dart';

class TeamProvider extends ChangeNotifier {
  final TeamService _svc;
  final UserRepository _repo;

  TeamModel? _team;
  List<TaskModel> _tasks = [];
  bool _loading = false;
  String? _error;
  StreamSubscription<List<TaskModel>>? _tasksSub;
  bool _streamStarted = false;
  String? _activeTeamId;
  String? _currentTeamId;
  final _taskRepo = TaskRepository();
  final Set<String> _deletedTaskIds = {};

  TeamModel? get team => _team;
  List<TaskModel> get tasks => _tasks;
  bool get loading => _loading;
  String? get error => _error;
  bool get hasTeam => _team != null;

  List<TaskModel> get pendingTasks => _tasks
      .where((t) => t.status == TaskStatus.pending ||
      t.status == TaskStatus.inProgress)
      .toList();
  List<TaskModel> get completedTasks =>
      _tasks.where((t) => t.status == TaskStatus.completed).toList();
  List<TaskModel> get overdueTasks =>
      _tasks.where((t) => t.status == TaskStatus.overdue).toList();

  TeamProvider(this._svc, this._repo);

  Future<void> loadTeam(UserModel user) async {
    if (!user.hasTeam) return;
    final teamId = user.teamId!;
    if (_currentTeamId == teamId && _streamStarted) return;
    _currentTeamId = teamId;
    _loading = true;
    notifyListeners();
    try {
      final cached = await _taskRepo.getByTeamId(teamId);
      if (cached.isNotEmpty) {
        _tasks = cached.map((t) =>
            t.status == TaskStatus.completed && t.progress < 100
                ? t.copyWith(progress: 100)
                : t).toList();
        notifyListeners();
      }
      _team = await _svc.getTeam(teamId);
      if (_team != null && !_streamStarted) {
        try {
          final fresh = await _svc.fetchTasksOnce(teamId);
          if (fresh.isNotEmpty) {
            _tasks = fresh.map((t) =>
                t.status == TaskStatus.completed && t.progress < 100
                    ? t.copyWith(progress: 100)
                    : t).toList();
            notifyListeners();
          }
        } catch (e) {
          debugPrint('[TeamProvider] fetchTasksOnce failed, '
              'will rely on stream: $e');
          // Continue — stream will provide data
        }
        _tasksSub = _svc.tasksStream(teamId).listen(
          (list) {
            if (list.isNotEmpty) {
              final now = DateTime.now();
              final mapped = list.map((t) {
                TaskModel result = t.status == TaskStatus.pending &&
                        now.isAfter(t.deadline)
                    ? t.copyWith(status: TaskStatus.overdue)
                    : t;
                if (result.status == TaskStatus.completed &&
                    result.progress < 100) {
                  result = result.copyWith(progress: 100);
                }
                return result;
              }).toList();
              _tasks = mapped
                .where((t) => !_deletedTaskIds.contains(t.id))
                .toList();
              notifyListeners();
            }
          },
          onError: (e) {
            debugPrint('[TeamProvider] Stream error: $e');
            _streamStarted = false;
          },
        );
        _streamStarted = true;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Call ONLY on logout
  void clearTeamData() {
    _tasksSub?.cancel();
    _tasksSub = null;
    _streamStarted = false;
    _currentTeamId = null;
    _team = null;
    _tasks = [];
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _tasksSub?.cancel();
    super.dispose();
  }

  Future<String?> createTeam(String name, UserModel lead) async {
    _loading = true; _error = null; notifyListeners();
    try {
      final t = await _svc.createTeam(name, lead.id);
      _team = t;
      _activeTeamId = t.id;
      final updated = lead.copyWith(
          teamId: t.id, role: UserRole.teamLead);
      await _repo.upsert(updated);
      _streamStarted = true;
      _tasksSub?.cancel();
      _tasksSub = _svc.tasksStream(t.id).listen(
        (list) {
          if (list.isNotEmpty) {
            final now = DateTime.now();
            final mapped = list.map((task) {
              TaskModel result = task.status == TaskStatus.pending &&
                      now.isAfter(task.deadline)
                  ? task.copyWith(status: TaskStatus.overdue)
                  : task;
              if (result.status == TaskStatus.completed &&
                  result.progress < 100) {
                result = result.copyWith(progress: 100);
              }
              return result;
            }).toList();
            _tasks = mapped
              .where((t) => !_deletedTaskIds.contains(t.id))
              .toList();
            notifyListeners();
          }
        },
        onError: (_) {},
      );
      notifyListeners();
      return t.inviteCode;
    } catch (e) { _error = e.toString(); return null; }
    finally { _loading = false; notifyListeners(); }
  }

  Future<TeamModel?> joinTeam(String code, UserModel user) async {
    _loading = true; _error = null; notifyListeners();
    try {
      final t = await _svc.findByCode(code);
      if (t == null) { _error = 'Team not found'; return null; }
      await _svc.addMember(t.id, user.id);
      _team = t;
      _activeTeamId = t.id;
      final updated = user.copyWith(
          teamId: t.id, role: UserRole.teamMember);
      await _repo.upsert(updated);
      _streamStarted = true;
      _tasksSub?.cancel();
      _tasksSub = _svc.tasksStream(t.id).listen(
        (list) {
          if (list.isNotEmpty) {
            final now = DateTime.now();
            final mapped = list.map((task) {
              TaskModel result = task.status == TaskStatus.pending &&
                      now.isAfter(task.deadline)
                  ? task.copyWith(status: TaskStatus.overdue)
                  : task;
              if (result.status == TaskStatus.completed &&
                  result.progress < 100) {
                result = result.copyWith(progress: 100);
              }
              return result;
            }).toList();
            _tasks = mapped
              .where((t) => !_deletedTaskIds.contains(t.id))
              .toList();
            notifyListeners();
          }
        },
        onError: (_) {},
      );
      notifyListeners();
      return t;
    } catch (e) { _error = e.toString(); return null; }
    finally { _loading = false; notifyListeners(); }
  }

  Future<void> createTask(TaskModel task) async {
    await _svc.createTask(task);
    // Stream will update _tasks automatically
  }

  Future<void> startTask(String taskId, UserModel user) async {
    final task = _tasks.firstWhere(
      (t) => t.id == taskId,
      orElse: () => throw Exception('Task not found'),
    );

    final canAct = task.assignedUserId == null ||
        task.assignedUserId!.isEmpty ||
        task.assignedUserId == user.id;

    if (!canAct) throw Exception('This task is not assigned to you');

    final updated = task.copyWith(
      status: TaskStatus.inProgress,
      // Preserve existing assignee if set, otherwise claim for self
      assignedUserId: task.assignedUserId?.isNotEmpty == true
          ? task.assignedUserId
          : user.id,
      assignedUserName: task.assignedUserName?.isNotEmpty == true
          ? task.assignedUserName
          : user.name,
    );
    await _svc.updateTask(updated);
    // Firebase stream will update _tasks automatically
  }

  Future<TaskModel> completeTask(
      String taskId, UserModel completer) async {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    final now = DateTime.now();
    final onTime = now.isBefore(task.deadline);
    final updated = task.copyWith(
      status: TaskStatus.completed,
      completedAt: now,
      xpEarned: onTime ? task.difficulty * 10 : 0,
      assignedUserId: completer.id,
      assignedUserName: completer.name,
    );
    await _svc.updateTask(updated);
    return updated;
  }

  Future<void> deleteTask(String taskId, String teamId) async {
    // STEP 1: Remove from local list IMMEDIATELY — UI updates at once
    _tasks.removeWhere((t) => t.id == taskId);
    _deletedTaskIds.add(taskId);
    notifyListeners();

    // Auto-clear the guard after 30 s to avoid memory leak
    Future.delayed(const Duration(seconds: 30), () {
      _deletedTaskIds.remove(taskId);
    });

    try {
      // STEP 2: Delete from SQLite
      await _taskRepo.deleteById(taskId);

      // STEP 3: Delete from Firebase
      await FirebaseDatabase.instance
          .ref('team_tasks/$teamId/$taskId')
          .remove()
          .timeout(const Duration(seconds: 10));

      debugPrint('[TeamProvider] Task deleted from Firebase: $taskId');
    } catch (e) {
      debugPrint('[TeamProvider] Delete error: $e');
      // Task already removed from UI; if Firebase still has it,
      // the stream filter will block it from reappearing for 30 s.
    }
  }

  void removeTaskLocally(String taskId) {
    _tasks.removeWhere((t) => t.id == taskId);
    _deletedTaskIds.add(taskId);
    notifyListeners();
    debugPrint('[TeamProvider] Task removed locally: $taskId');
    Future.delayed(const Duration(seconds: 60), () {
      _deletedTaskIds.remove(taskId);
    });
  }

  Future<void> deleteTaskFromDb(String taskId) async {
    try {
      await _taskRepo.deleteById(taskId);
      debugPrint('[TeamProvider] Task deleted from SQLite: $taskId');
    } catch (e) {
      debugPrint('[TeamProvider] SQLite delete error: $e');
    }
  }

  Future<void> updateTaskProgress(
      String taskId, int progress, String status) async {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx == -1) return;
    _tasks[idx] = _tasks[idx].copyWith(
      progress: progress,
      status: _statusFromString(status),
    );
    notifyListeners();
    await _taskRepo.updateProgress(taskId, progress, status);
  }

  TaskStatus _statusFromString(String s) =>
      TaskStatus.values.firstWhere(
        (e) => e.name == s,
        orElse: () => TaskStatus.pending,
      );
}
