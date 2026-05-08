import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

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
      version: 10,
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
    skill_level TEXT NOT NULL DEFAULT 'junior'
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
      xp_earned INTEGER DEFAULT 0
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
  }

  static Future<void> clearAllData() async {
    final db = await instance;
    final batch = db.batch();
    batch.delete('tasks');
    batch.delete('user_inventory');
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
  }
}
