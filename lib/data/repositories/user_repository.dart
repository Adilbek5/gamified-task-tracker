import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/user_model.dart';
import '../models/achievement_model.dart';

class UserRepository {
  Future<Database> get _db async => AppDatabase.instance;

  Future<void> upsert(UserModel u) async {
    final db = await _db;
    await db.insert('users', u.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<UserModel?> getById(String id) async {
    final db = await _db;
    final r = await db.query('users', where: 'id=?', whereArgs: [id]);
    return r.isEmpty ? null : UserModel.fromMap(r.first);
  }

  Future<void> updateXp(String id, int xp, int level) async {
    final db = await _db;
    await db.update('users', {'xp': xp, 'level': level},
        where: 'id=?', whereArgs: [id]);
  }

  Future<void> updateCoins(String id, int coins) async {
    final db = await _db;
    await db.update('users', {'coins': coins},
        where: 'id=?', whereArgs: [id]);
  }

  Future<void> insertAchievement(AchievementModel a) async {
    final db = await _db;
    await db.insert('achievements', a.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<List<AchievementModel>> getAchievements(String uid) async {
    final db = await _db;
    final r = await db.query('achievements',
        where: 'user_id=?', whereArgs: [uid],
        orderBy: 'earned_at DESC');
    return r.map(AchievementModel.fromMap).toList();
  }
}