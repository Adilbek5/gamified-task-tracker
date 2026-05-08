import 'package:flutter/foundation.dart';
import '../data/models/challenge_model.dart';
import '../services/challenge_service.dart';

class ChallengeProvider extends ChangeNotifier {
  final ChallengeService _svc;

  List<ChallengeModel> _challenges = [];
  final Map<String, List<LeaderboardEntry>> _leaderboards = {};
  String? _userId;

  List<ChallengeModel> get challenges => _challenges;

  ChallengeProvider(this._svc);

  void setUser(String userId) => _userId = userId;

  List<LeaderboardEntry> leaderboardFor(String challengeId) =>
      _leaderboards[challengeId] ?? [];

  bool isJoined(String challengeId) {
    if (_userId == null) return false;
    try {
      final c = _challenges.firstWhere((c) => c.id == challengeId);
      return c.participantIds.contains(_userId);
    } catch (_) {
      return false;
    }
  }

  int myRank(String challengeId) {
    if (_userId == null) return -1;
    final lb = _leaderboards[challengeId] ?? [];
    final idx = lb.indexWhere((e) => e.userId == _userId!);
    return idx == -1 ? -1 : idx + 1;
  }

  int myXpInChallenge(String challengeId) {
    if (_userId == null) return 0;
    final lb = _leaderboards[challengeId] ?? [];
    try {
      return lb.firstWhere((e) => e.userId == _userId!).xp;
    } catch (_) {
      return 0;
    }
  }

  void listenChallenges(String teamId) {
    _svc.challengesStream(teamId).listen((list) {
      _challenges = list;
      notifyListeners();
    });
  }

  void listenLeaderboard(String teamId, String challengeId) {
    _svc.leaderboardStream(teamId, challengeId).listen((list) {
      _leaderboards[challengeId] = list;
      notifyListeners();
    });
  }

  Future<void> createChallenge({
    required String title,
    required String teamId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    await _svc.createChallenge(
        title: title,
        teamId: teamId,
        startDate: startDate,
        endDate: endDate);
  }

  Future<void> join(
      String teamId, String challengeId, String userId) async {
    await _svc.joinChallenge(teamId, challengeId, userId);
  }

  Future<void> addXp(String teamId, String challengeId,
      String userId, String userName, int xp) async {
    await _svc.addXpToLeaderboard(
        teamId, challengeId, userId, userName, xp);
  }
}
