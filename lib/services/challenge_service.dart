import 'package:firebase_database/firebase_database.dart';
import 'package:uuid/uuid.dart';
import '../data/models/challenge_model.dart';

class ChallengeService {
  final _db = FirebaseDatabase.instance;
  final _uuid = const Uuid();

  Future<ChallengeModel> createChallenge({
    required String title,
    required String teamId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final id = _uuid.v4();
    final c = ChallengeModel(
        id: id, title: title, teamId: teamId,
        startDate: startDate, endDate: endDate);
    await _db.ref('challenges/$teamId/$id').set(c.toFirebase());
    return c;
  }

  Stream<List<ChallengeModel>> challengesStream(String teamId) =>
      _db.ref('challenges/$teamId').onValue.map((e) {
        if (e.snapshot.value == null) return [];
        final data = e.snapshot.value as Map<dynamic, dynamic>;
        return data.entries
            .map((x) => ChallengeModel.fromFirebase(
            x.key.toString(),
            x.value as Map<dynamic, dynamic>))
            .toList();
      });

  Future<void> joinChallenge(
      String teamId, String challengeId, String userId) async {
    final ref = _db.ref('challenges/$teamId/$challengeId/participant_ids');
    final snap = await ref.get();
    final List<String> ids =
    snap.exists ? List<String>.from(snap.value as List) : [];
    if (!ids.contains(userId)) {
      ids.add(userId);
      await ref.set(ids);
    }
  }

  Future<void> addXpToLeaderboard(
      String teamId, String challengeId,
      String userId, String userName, int xp) async {
    final ref = _db.ref(
        'leaderboard/$teamId/$challengeId/$userId');
    final snap = await ref.get();
    final current = snap.exists ? (snap.value as Map)['xp'] ?? 0 : 0;
    await ref.set({'user_id': userId, 'user_name': userName,
      'xp': (current as int) + xp});
  }

  Stream<List<LeaderboardEntry>> leaderboardStream(
      String teamId, String challengeId) =>
      _db.ref('leaderboard/$teamId/$challengeId').onValue.map((e) {
        if (e.snapshot.value == null) return [];
        final data = e.snapshot.value as Map<dynamic, dynamic>;
        return (data.values
            .map((v) {
          final m = v as Map<dynamic, dynamic>;
          return LeaderboardEntry(
              userId: m['user_id'] ?? '',
              userName: m['user_name'] ?? '',
              xp: m['xp'] ?? 0);
        })
            .toList()
          ..sort((a, b) => b.xp.compareTo(a.xp)));
      });
}