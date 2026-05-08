import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/task_model.dart';

class TaskRepository {
  Future<Database> get _db async => AppDatabase.instance;

  // Insert or update — works for both personal and team tasks
  Future<void> upsert(TaskModel task) async {
    final db = await _db;
    await db.insert(
      'tasks',
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get tasks by teamId from SQLite
  Future<List<TaskModel>> getByTeamId(String teamId) async {
    final db = await _db;
    final maps = await db.query(
      'tasks',
      where: 'team_id = ?',
      whereArgs: [teamId],
      orderBy: 'deadline ASC',
    );
    return maps.map(TaskModel.fromMap).toList();
  }

  // Get personal tasks by userId
  Future<List<TaskModel>> getAllForUser(
      String userId, {String? teamId}) async {
    final db = await _db;
    String where = 'created_by = ?';
    List<dynamic> args = [userId];
    if (teamId != null && teamId.isNotEmpty) {
      where += ' AND team_id = ?';
      args.add(teamId);
    }
    final maps = await db.query(
      'tasks',
      where: where,
      whereArgs: args,
      orderBy: 'deadline ASC',
    );
    return maps.map(TaskModel.fromMap).toList();
  }

  Future<void> update(TaskModel task) async {
    final db = await _db;
    await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<void> deleteById(String id) async {
    final db = await _db;
    await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete ALL tasks for a team (used when switching accounts)
  Future<void> deleteByTeamId(String teamId) async {
    final db = await _db;
    await db.delete(
      'tasks',
      where: 'team_id = ?',
      whereArgs: [teamId],
    );
  }

  // Clear ALL tasks (used on logout)
  Future<void> clearAll() async {
    final db = await _db;
    await db.delete('tasks');
  }

  Future<int> countCompleted(String teamId) async {
    final db = await _db;
    final r = await db.rawQuery(
      "SELECT COUNT(*) as c FROM tasks WHERE team_id=? AND status='completed'",
      [teamId],
    );
    return (r.first['c'] as int?) ?? 0;
  }
}
