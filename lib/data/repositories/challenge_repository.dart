import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/challenge_model.dart';

class ChallengeRepository {
  Future<Database> get _db async => AppDatabase.instance;

  Future<void> upsert(ChallengeModel c) async {
    final db = await _db;
    await db.insert(
      'challenges',
      c.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ChallengeModel>> getAll() async {
    final db = await _db;
    final maps = await db.query('challenges');
    return maps
        .map((m) => ChallengeModel.fromMap(m))
        .toList();
  }

  Future<void> addParticipant(
      String challengeId, String userId) async {
    final db = await _db;
    final maps = await db.query('challenges',
        where: 'id=?', whereArgs: [challengeId]);
    if (maps.isEmpty) return;
    final c = ChallengeModel.fromMap(maps.first);
    if (!c.participantIds.contains(userId)) {
      final updated = [...c.participantIds, userId];
      await db.update(
        'challenges',
        {'participant_ids': updated.join(',')},
        where: 'id=?',
        whereArgs: [challengeId],
      );
    }
  }
}