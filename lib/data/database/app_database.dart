import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/subtask_model.dart';

class AppDatabase {
  static Database? _db;

  static Future<Database> get instance async {
    if (_db != null && _db!.isOpen) return _db!;
    _db = await _init();
    return _db!;
  }

  static Future<Database> _init() async {
    final path = join(await getDatabasesPath(), 'gtt.db');
    return openDatabase(
      path,
      version: 13,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int v) async {
    await db.execute('''
  CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    email TEXT NOT NULL DEFAULT '',
    name TEXT NOT NULL DEFAULT '',
    role TEXT NOT NULL DEFAULT 'teamMember',
    team_id TEXT DEFAULT '',
    xp INTEGER NOT NULL DEFAULT 0,
    level INTEGER NOT NULL DEFAULT 1,
    coins INTEGER NOT NULL DEFAULT 0,
    equipped_avatar_id TEXT NOT NULL DEFAULT 'avatar_default',
    equipped_border_id TEXT NOT NULL DEFAULT 'border_none',
    equipped_badge_id TEXT NOT NULL DEFAULT 'badge_none',
    skill_level TEXT NOT NULL DEFAULT 'junior',
    streak_days INTEGER NOT NULL DEFAULT 0,
    last_active_date TEXT NOT NULL DEFAULT ''
  )
''');
    await db.execute('''CREATE TABLE tasks(
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      description TEXT DEFAULT '',
      difficulty INTEGER NOT NULL DEFAULT 1,
      deadline TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'pending',
      created_by TEXT DEFAULT '',
      team_id TEXT DEFAULT '',
      assigned_user_id TEXT DEFAULT '',
      assigned_user_name TEXT DEFAULT '',
      completed_at TEXT DEFAULT '',
      xp_earned INTEGER DEFAULT 0,
      progress INTEGER NOT NULL DEFAULT 0
    )''');
    await db.execute('''CREATE TABLE achievements(
      id TEXT PRIMARY KEY, user_id TEXT, title TEXT,
      description TEXT, earned_at TEXT
    )''');
    await db.execute('''CREATE TABLE user_inventory(
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      item_id TEXT NOT NULL,
      purchased_at TEXT NOT NULL
    )''');
    await db.execute('''CREATE TABLE sync_queue(
      id TEXT PRIMARY KEY,
      task_id TEXT NOT NULL,
      team_id TEXT NOT NULL,
      action TEXT NOT NULL,
      data TEXT,
      created_at TEXT NOT NULL
    )''');
    await db.execute('''CREATE TABLE subtasks(
      id TEXT PRIMARY KEY,
      task_id TEXT NOT NULL,
      title TEXT NOT NULL,
      is_completed INTEGER NOT NULL DEFAULT 0,
      sort_order INTEGER NOT NULL DEFAULT 0
    )''');
  }

  static Future<void> clearAllData() async {
    final db = await instance;
    final batch = db.batch();
    batch.delete('tasks');
    batch.delete('sync_queue');
    // DO NOT delete users — teamId and role must survive logout
    await batch.commit(noResult: true);
  }

  static Future<void> _onUpgrade(Database db, int oldV, int newV) async {
    if (oldV < 2) {
      try {
        await db.execute(
            'ALTER TABLE users ADD COLUMN coins INTEGER DEFAULT 0');
      } catch (_) {}
    }
    if (oldV < 4) {
      try {
        await db.execute(
            "ALTER TABLE tasks ADD COLUMN assigned_user_id TEXT DEFAULT ''");
      } catch (_) {}
      try {
        await db.execute(
            "ALTER TABLE tasks ADD COLUMN assigned_user_name TEXT DEFAULT ''");
      } catch (_) {}
    }
    if (oldV < 6) {
      try {
        await db.execute(
            "ALTER TABLE users ADD COLUMN equipped_avatar_id TEXT DEFAULT 'avatar_default'");
      } catch (_) {}
      try {
        await db.execute(
            "ALTER TABLE users ADD COLUMN equipped_border_id TEXT DEFAULT 'border_none'");
      } catch (_) {}
      try {
        await db.execute(
            "ALTER TABLE users ADD COLUMN equipped_badge_id TEXT DEFAULT 'badge_none'");
      } catch (_) {}
      // Replace old single-row-per-user inventory with one-row-per-item schema
      await db.execute('DROP TABLE IF EXISTS user_inventory');
      await db.execute('''CREATE TABLE user_inventory(
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        item_id TEXT NOT NULL,
        purchased_at TEXT NOT NULL
      )''');
    }
    if (oldV < 7) {
      try {
        await db.execute(
            "ALTER TABLE users ADD COLUMN skill_level TEXT DEFAULT 'junior'");
      } catch (_) {}
    }
    if (oldV < 8) {
      try {
        await db.execute('''CREATE TABLE IF NOT EXISTS sync_queue(
          id TEXT PRIMARY KEY,
          task_id TEXT NOT NULL,
          team_id TEXT NOT NULL,
          action TEXT NOT NULL,
          data TEXT,
          created_at TEXT NOT NULL
        )''');
      } catch (_) {}
    }
    if (oldV < 9) {
      // Ensure all task columns exist on older installs (try-catch each —
      // ALTER TABLE fails silently if the column already exists).
      for (final sql in [
        "ALTER TABLE tasks ADD COLUMN description TEXT DEFAULT ''",
        "ALTER TABLE tasks ADD COLUMN created_by TEXT DEFAULT ''",
        "ALTER TABLE tasks ADD COLUMN team_id TEXT DEFAULT ''",
        "ALTER TABLE tasks ADD COLUMN assigned_user_id TEXT DEFAULT ''",
        "ALTER TABLE tasks ADD COLUMN assigned_user_name TEXT DEFAULT ''",
        "ALTER TABLE tasks ADD COLUMN completed_at TEXT DEFAULT ''",
        'ALTER TABLE tasks ADD COLUMN xp_earned INTEGER DEFAULT 0',
      ]) {
        try {
          await db.execute(sql);
        } catch (_) {}
      }
    }
    if (oldV < 10) {
      try {
        await db.execute(
          "ALTER TABLE users ADD COLUMN skill_level "
          "TEXT NOT NULL DEFAULT 'junior'");
      } catch (_) {}
    }
    if (oldV < 11) {
      try {
        await db.execute('''CREATE TABLE IF NOT EXISTS subtasks(
          id TEXT PRIMARY KEY,
          task_id TEXT NOT NULL,
          title TEXT NOT NULL,
          is_completed INTEGER NOT NULL DEFAULT 0,
          sort_order INTEGER NOT NULL DEFAULT 0
        )''');
      } catch (_) {}
    }
    if (oldV < 12) {
      try {
        await db.execute(
            'ALTER TABLE users ADD COLUMN streak_days INTEGER DEFAULT 0');
      } catch (_) {}
      try {
        await db.execute(
            "ALTER TABLE users ADD COLUMN last_active_date TEXT DEFAULT ''");
      } catch (_) {}
    }
    if (oldV < 13) {
      try {
        await db.execute(
            'ALTER TABLE tasks ADD COLUMN progress INTEGER NOT NULL DEFAULT 0');
      } catch (_) {}
    }
  }

  static Future<List<SubtaskModel>> getSubtasks(String taskId) async {
    final db = await instance;
    final rows = await db.query(
      'subtasks',
      where: 'task_id = ?',
      whereArgs: [taskId],
      orderBy: 'sort_order ASC',
    );
    return rows.map(SubtaskModel.fromMap).toList();
  }

  static Future<void> insertSubtask(SubtaskModel sub) async {
    final db = await instance;
    await db.insert('subtasks', sub.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> toggleSubtask(String id, bool isCompleted) async {
    final db = await instance;
    await db.update(
      'subtasks',
      {'is_completed': isCompleted ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> deleteSubtask(String id) async {
    final db = await instance;
    await db.delete('subtasks', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> deleteSubtasksForTask(String taskId) async {
    final db = await instance;
    await db.delete('subtasks', where: 'task_id = ?', whereArgs: [taskId]);
  }

  static Future<(int, int)> getSubtaskProgress(String taskId) async {
    final db = await instance;
    final rows = await db.query(
      'subtasks',
      columns: ['is_completed'],
      where: 'task_id = ?',
      whereArgs: [taskId],
    );
    final total = rows.length;
    final done = rows.where((r) => (r['is_completed'] as int? ?? 0) == 1).length;
    return (done, total);
  }
}
