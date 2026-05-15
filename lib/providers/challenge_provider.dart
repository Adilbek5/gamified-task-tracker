import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../data/models/challenge_model.dart';
import '../services/challenge_service.dart';

class ChallengeProvider extends ChangeNotifier {
  final ChallengeService _svc;

  List<ChallengeModel> _challenges = [];
  final Map<String, List<LeaderboardEntry>> _leaderboards = {};
  final Map<String, List<ChallengeActivity>> _activities = {};
  String? _userId;

  List<ChallengeModel> get challenges => _challenges;

  ChallengeProvider(this._svc);

  void setUser(String userId) => _userId = userId;

  List<LeaderboardEntry> leaderboardFor(String challengeId) =>
      _leaderboards[challengeId] ?? [];

  List<ChallengeActivity> activitiesFor(String challengeId) =>
      _activities[challengeId] ?? [];

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
      for (final c in _challenges.where((c) => c.isActive)) {
        listenLeaderboard(teamId, c.id);
      }
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
    int prizeCoins = 0,
  }) async {
    await _svc.createChallenge(
        title: title,
        teamId: teamId,
        startDate: startDate,
        endDate: endDate,
        prizeCoins: prizeCoins);
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

  Future<void> logActivity(
      String teamId, String challengeId,
      String userName, String taskTitle, int xpEarned) async {
    final ref = FirebaseDatabase.instance
        .ref('challenge_activity/$teamId/$challengeId')
        .push();
    await ref.set({
      'user_name': userName,
      'task_title': taskTitle,
      'xp_earned': xpEarned,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  void listenActivity(String teamId, String challengeId) {
    FirebaseDatabase.instance
        .ref('challenge_activity/$teamId/$challengeId')
        .orderByChild('timestamp')
        .limitToLast(20)
        .onValue
        .listen((event) {
          if (event.snapshot.value == null) {
            _activities[challengeId] = [];
          } else {
            final data = event.snapshot.value as Map<dynamic, dynamic>;
            final list = data.entries.map((e) {
              final m = e.value as Map<dynamic, dynamic>;
              return ChallengeActivity(
                userName: m['user_name'] ?? '',
                taskTitle: m['task_title'] ?? '',
                xpEarned: (m['xp_earned'] ?? 0) as int,
                timestamp: DateTime.fromMillisecondsSinceEpoch(
                    (m['timestamp'] ?? 0) as int),
              );
            }).toList()
              ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
            _activities[challengeId] = list;
          }
          notifyListeners();
        });
  }
}

class ChallengeActivity {
  final String userName;
  final String taskTitle;
  final int xpEarned;
  final DateTime timestamp;

  ChallengeActivity({
    required this.userName,
    required this.taskTitle,
    required this.xpEarned,
    required this.timestamp,
  });
}
