import 'package:flutter/foundation.dart';
import '../core/constants/xp_constants.dart';
import '../data/models/achievement_model.dart';
import '../data/models/task_model.dart';
import '../data/models/user_model.dart';
import '../data/repositories/user_repository.dart';
import '../services/gamification_service.dart';

class GamificationProvider extends ChangeNotifier {
  final GamificationService _svc;
  final UserRepository _repo;

  UserModel? _user;
  List<AchievementModel> _achievements = [];
  bool _justLeveledUp = false;
  int _newLevel = 1;
  bool _lastStreakReset = false;
  bool _lastIsEarlyBird = false;
  String _lastCompletionStatus = '';
  int _lastDaysLate = 0;

  UserModel? get user => _user;
  List<AchievementModel> get achievements => _achievements;
  int get coins => _user?.coins ?? 0;
  int get xpProgress =>
      _user != null ? XpConstants.xpProgressInCurrentLevel(_user!.xp) : 0;
  int get xpForNext =>
      _user != null ? XpConstants.xpForNextLevel(_user!.level) : 100;
  bool get justLeveledUp => _justLeveledUp;
  int get newLevel => _newLevel;
  bool get lastStreakReset => _lastStreakReset;
  bool get lastIsEarlyBird => _lastIsEarlyBird;
  String get lastCompletionStatus => _lastCompletionStatus;
  int get lastDaysLate => _lastDaysLate;

  GamificationProvider(this._svc, this._repo);

  void clear() {
    _user = null;
    _achievements = [];
    notifyListeners();
  }

  Future<void> load(UserModel u) async {
    _user = u;
    _achievements = await _repo.getAchievements(u.id);
    notifyListeners();
  }

  void updateUser(UserModel u) {
    _user = u;
    notifyListeners();
  }

  Future<({
    List<AchievementModel> achievements,
    int xpEarned,
    int coinsEarned,
  })> handleCompletion(TaskModel task, UserModel user) async {
    final oldLevel = user.level;
    final result = await _svc.processCompletion(task, user);
    _user = result.updatedUser;
    _achievements = await _repo.getAchievements(user.id);
    final currentLevel = _user?.level ?? 1;
    if (currentLevel > oldLevel) {
      _justLeveledUp = true;
      _newLevel = currentLevel;
    } else {
      _justLeveledUp = false;
    }
    _lastStreakReset = result.streakReset;
    _lastIsEarlyBird = result.isEarlyBird;
    _lastCompletionStatus = result.completionStatus;
    _lastDaysLate = result.daysLate;
    notifyListeners();
    return (
      achievements: result.achievements,
      xpEarned: result.xpEarned,
      coinsEarned: result.coinsEarned,
    );
  }
}
