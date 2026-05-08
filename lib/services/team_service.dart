import 'package:firebase_database/firebase_database.dart';
import 'package:uuid/uuid.dart';
import '../data/models/team_model.dart';
import '../data/models/task_model.dart';
import '../data/repositories/task_repository.dart';

class TeamService {
  final _db = FirebaseDatabase.instance;
  final _uuid = const Uuid();
  final _taskRepo = TaskRepository();

  String _code() {
    const c = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final n = DateTime.now().millisecondsSinceEpoch;
    return List.generate(6, (i) => c[(n ~/ (i + 1)) % c.length]).join();
  }

  Future<TeamModel> createTeam(String name, String leadId) async {
    final id = _uuid.v4();
    final code = _code();
    final team = TeamModel(
        id: id, name: name, leadId: leadId,
        inviteCode: code, memberIds: [leadId]);
    await _db.ref('teams/$id').set(team.toFirebase());
    return team;
  }

  Future<TeamModel?> findByCode(String code) async {
    try {
      final snap = await _db
          .ref('teams')
          .get()
          .timeout(const Duration(seconds: 10));
      if (!snap.exists) return null;
      final data = snap.value as Map<dynamic, dynamic>;
      for (final entry in data.entries) {
        final teamData = entry.value as Map<dynamic, dynamic>;
        if (teamData['invite_code'] == code) {
          return TeamModel.fromFirebase(
              entry.key.toString(), teamData);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> addMember(String teamId, String userId) async {
    final snap = await _db.ref('teams/$teamId/member_ids').get();
    final List<String> ids = snap.exists
        ? List<String>.from(snap.value as List)
        : [];
    if (!ids.contains(userId)) {
      ids.add(userId);
      await _db.ref('teams/$teamId/member_ids').set(ids);
    }
  }

  Future<TeamModel?> getTeam(String teamId) async {
    try {
      final snap = await _db
        .ref('teams/$teamId')
        .get()
        .timeout(const Duration(seconds: 10));
      if (!snap.exists) return null;
      return TeamModel.fromFirebase(
        teamId,
        snap.value as Map<dynamic, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> transferLeadership(
      String teamId, String newLeadId, String oldLeadId) async {
    await _db.ref('teams/$teamId/lead_id').set(newLeadId);
    await _db.ref('users_roles/$teamId/$newLeadId').set('teamLead');
    await _db.ref('users_roles/$teamId/$oldLeadId').set('teamMember');
  }

  // ─── CREATE TASK ────────────────────────────────────────
  Future<void> createTask(TaskModel task) async {
    if (task.teamId.isEmpty) throw Exception('teamId required');
    await _taskRepo.upsert(task); // SQLite first
    await _db
      .ref('team_tasks/${task.teamId}/${task.id}')
      .set({
        'id': task.id,
        'title': task.title,
        'description': task.description ?? '',
        'difficulty': task.difficulty,
        'deadline': task.deadline.toIso8601String(),
        'status': task.status.name,
        'created_by': task.createdBy,
        'team_id': task.teamId,
        'assigned_user_id': task.assignedUserId ?? '',
        'assigned_user_name': task.assignedUserName ?? '',
        'completed_at': '',
        'xp_earned': 0,
      })
      .timeout(const Duration(seconds: 15));
  }

  // ─── UPDATE TASK ────────────────────────────────────────
  Future<void> updateTask(TaskModel task) async {
    await _taskRepo.upsert(task);
    try {
      await _db
        .ref('team_tasks/${task.teamId}/${task.id}')
        .update({
          'status': task.status.name,
          'completed_at':
            task.completedAt?.toIso8601String() ?? '',
          'xp_earned': task.xpEarned,
          'assigned_user_id': task.assignedUserId ?? '',
          'assigned_user_name': task.assignedUserName ?? '',
        })
        .timeout(const Duration(seconds: 15));
    } catch (_) {}
  }

  // ─── DELETE TASK ────────────────────────────────────────
  Future<void> deleteTask(String teamId, String taskId) async {
    await _taskRepo.deleteById(taskId);
    try {
      await _db
        .ref('team_tasks/$teamId/$taskId')
        .remove()
        .timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  // ─── FETCH ONCE (for initial load) ──────────────────────
  Future<List<TaskModel>> fetchTasksOnce(String teamId) async {
    try {
      final snap = await _db
        .ref('team_tasks/$teamId')
        .get()
        .timeout(const Duration(seconds: 10));
      if (snap.exists && snap.value is Map) {
        final raw = Map<String, dynamic>.from(snap.value as Map);
        final tasks = <TaskModel>[];
        for (final entry in raw.entries) {
          try {
            final m = Map<String, dynamic>.from(entry.value as Map);
            m['id'] = entry.key;
            m['team_id'] = teamId;
            final task = TaskModel.fromMap(m);
            tasks.add(task);
            await _taskRepo.upsert(task);
          } catch (_) {}
        }
        return tasks;
      }
    } catch (_) {}
    return _taskRepo.getByTeamId(teamId);
  }

  // ─── REAL-TIME STREAM ───────────────────────────────────
  Stream<List<TaskModel>> tasksStream(String teamId) {
    return _db
      .ref('team_tasks/$teamId')
      .onValue
      .asyncMap((event) async {
        if (event.snapshot.value == null ||
            event.snapshot.value is! Map) {
          return _taskRepo.getByTeamId(teamId);
        }
        final raw = Map<String, dynamic>.from(
          event.snapshot.value as Map);
        final tasks = <TaskModel>[];
        for (final entry in raw.entries) {
          try {
            final m = Map<String, dynamic>.from(entry.value as Map);
            m['id'] = entry.key;
            m['team_id'] = teamId;
            final task = TaskModel.fromMap(m);
            tasks.add(task);
            await _taskRepo.upsert(task);
          } catch (_) {}
        }
        tasks.sort((a, b) => a.deadline.compareTo(b.deadline));
        if (tasks.isEmpty) return _taskRepo.getByTeamId(teamId);
        return tasks;
      });
  }
}
