import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../core/utils/date_utils.dart';
import '../data/models/task_model.dart';
import '../data/repositories/task_repository.dart';

class TaskProvider extends ChangeNotifier {
  final TaskRepository _repo;
  final _uuid = const Uuid();

  List<TaskModel> _tasks = [];
  bool _loading = false;

  List<TaskModel> get tasks => _tasks;
  bool get loading => _loading;

  List<TaskModel> get todayTasks => _tasks
      .where((t) =>
  AppDateUtils.isToday(t.deadline) &&
      t.status != TaskStatus.completed &&
      t.status != TaskStatus.overdue)
      .toList();

  List<TaskModel> get upcomingTasks => _tasks
      .where((t) =>
  AppDateUtils.isUpcoming(t.deadline) &&
      t.status != TaskStatus.completed)
      .toList();

  List<TaskModel> get completedTasks =>
      _tasks.where((t) => t.status == TaskStatus.completed).toList();

  List<TaskModel> get overdueTasks =>
      _tasks.where((t) => t.status == TaskStatus.overdue).toList();

  TaskProvider(this._repo);

  Future<void> loadTasks(String userId, {String? teamId}) async {
    _loading = true;
    _tasks = [];
    notifyListeners();

    try {
      final all = teamId != null && teamId.isNotEmpty
        ? await _repo.getAllForUser(userId, teamId: teamId)
        : await _repo.getAllForUser(userId);

      final now = DateTime.now();
      _tasks = all.map((t) {
        if (t.status == TaskStatus.pending &&
            now.isAfter(t.deadline)) {
          return t.copyWith(status: TaskStatus.overdue);
        }
        return t;
      }).toList();
    } catch (_) {}

    _loading = false;
    notifyListeners();
  }

  Future<void> createTask({
    required String userId,
    required String title,
    String? id,
    String? description,
    required int difficulty,
    required DateTime deadline,
    String? teamId,
    String? assignedUserId,
    String? assignedUserName,
  }) async {
    final task = TaskModel(
      id: id ?? _uuid.v4(),
      title: title,
      description: description,
      difficulty: difficulty,
      deadline: deadline,
      createdBy: userId,
      teamId: teamId ?? '',
      assignedUserId: assignedUserId,
      assignedUserName: assignedUserName,
    );
    await _repo.upsert(task);
    _tasks.add(task);
    notifyListeners();
  }

  Future<void> deleteTask(String taskId) async {
    await _repo.deleteById(taskId);
    _tasks.removeWhere((t) => t.id == taskId);
    notifyListeners();
  }

  Future<TaskModel> completeTask(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) throw Exception('Task not found');
    final task = _tasks[index];
    final now = DateTime.now();
    final onTime = now.isBefore(task.deadline);
    final updated = task.copyWith(
      status: TaskStatus.completed,
      completedAt: now,
      xpEarned: onTime ? task.difficulty * 10 : 0,
    );
    await _repo.update(updated);
    _tasks[index] = updated;
    notifyListeners();
    return updated;
  }
}