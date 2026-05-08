import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:sqflite/sqflite.dart';
import '../data/database/app_database.dart';
import '../data/repositories/task_repository.dart';
import '../data/models/task_model.dart';

class SyncService {
  static final SyncService instance = SyncService._();
  SyncService._();

  final _db = FirebaseDatabase.instance;
  final _taskRepo = TaskRepository();
  StreamSubscription? _connectivitySub;
  bool _isSyncing = false;

  // Start listening for connectivity changes
  void startSync() {
    _connectivitySub = Connectivity()
      .onConnectivityChanged
      .listen((List<ConnectivityResult> results) {
        final online = results.any(
          (r) => r != ConnectivityResult.none);
        if (online && !_isSyncing) {
          _syncPendingTasks();
        }
      });
  }

  void stopSync() {
    _connectivitySub?.cancel();
  }

  // Queue a task for sync (called when offline)
  Future<void> queueTask(TaskModel task, String action) async {
    try {
      final db = await AppDatabase.instance;
      await db.insert(
        'sync_queue',
        {
          'id': '${task.id}_${DateTime.now().millisecondsSinceEpoch}',
          'task_id': task.id,
          'team_id': task.teamId,
          'action': action, // 'create', 'update', 'delete'
          'data': task.toMap().toString(),
          'created_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {}
  }

  // Push all pending changes to Firebase
  Future<void> _syncPendingTasks() async {
    _isSyncing = true;
    try {
      final db = await AppDatabase.instance;
      final pending = await db.query('sync_queue',
        orderBy: 'created_at ASC');

      for (final row in pending) {
        try {
          final taskId = row['task_id'] as String;
          final teamId = row['team_id'] as String;
          final action = row['action'] as String;

          if (action == 'delete') {
            await _db
              .ref('team_tasks/$teamId/$taskId')
              .remove();
          } else {
            // Get current task from SQLite
            final tasks = await _taskRepo.getByTeamId(teamId);
            final task = tasks.firstWhere(
              (t) => t.id == taskId,
              orElse: () => throw Exception('not found'));

            final map = {
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
              'completed_at':
                task.completedAt?.toIso8601String() ?? '',
              'xp_earned': task.xpEarned,
            };

            await _db
              .ref('team_tasks/$teamId/$taskId')
              .set(map)
              .timeout(const Duration(seconds: 15));
          }

          // Remove from queue after successful sync
          await db.delete('sync_queue',
            where: 'task_id = ?',
            whereArgs: [taskId]);

        } catch (_) {
          // Keep in queue for next retry
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  // Manual sync trigger
  Future<void> syncNow() async {
    final results = await Connectivity().checkConnectivity();
    final online = results.any(
      (r) => r != ConnectivityResult.none);
    if (online) {
      await _syncPendingTasks();
    }
  }
}