import 'package:uuid/uuid.dart';
import '../core/constants/xp_constants.dart';
import '../data/models/achievement_model.dart';
import '../data/models/task_model.dart';
import '../data/models/user_model.dart';
import '../data/repositories/shop_repository.dart';
import '../data/repositories/task_repository.dart';
import '../data/repositories/user_repository.dart';

class GamificationService {
  final UserRepository _userRepo;
  final TaskRepository _taskRepo;
  final ShopRepository _shopRepo;
  final _uuid = const Uuid();

  GamificationService(this._userRepo, this._taskRepo, this._shopRepo);

  Future<({
    UserModel updatedUser,
    List<AchievementModel> achievements,
    int xpEarned,
    int coinsEarned,
  })> processCompletion(TaskModel task, UserModel user) async {
    final onTime = DateTime.now().isBefore(task.deadline);
    final baseXp = onTime ? task.difficulty * 10 : 0;
    final baseCoins = onTime ? task.difficulty * 5 : 0;
    final xp = (baseXp * user.xpMultiplier).round();
    final coins = baseCoins;

    final newXp = user.xp + xp;
    final newCoins = user.coins + coins;
    final newLevel = XpConstants.levelFromXp(newXp);

    await _userRepo.updateXp(user.id, newXp, newLevel);
    if (coins > 0) {
      await _shopRepo.updateCoins(user.id, newCoins);
    }

    final updatedUser = user.copyWith(
      xp: newXp,
      level: newLevel,
      coins: newCoins,
    );

    final existing = await _userRepo.getAchievements(user.id);
    final titles = existing.map((a) => a.title).toSet();
    final completed = await _taskRepo.countCompleted(user.teamId ?? '');
    final newAchievements = <AchievementModel>[];

    Future<void> try_(String t, String d, bool cond) async {
      if (cond && !titles.contains(t)) {
        final a = AchievementModel(
            id: _uuid.v4(),
            userId: user.id,
            title: t,
            description: d,
            earnedAt: DateTime.now());
        await _userRepo.insertAchievement(a);
        newAchievements.add(a);
      }
    }

    await try_('First Step', 'Completed your first task!', completed >= 1);
    await try_('Task Master', 'Completed 10 tasks!', completed >= 10);
    await try_('XP Hunter', 'Earned 100 XP!', newXp >= 100);
    await try_('Code Knight', 'Reached level 5!', newLevel >= 5);

    return (
      updatedUser: updatedUser,
      achievements: newAchievements,
      xpEarned: xp,
      coinsEarned: coins,
    );
  }
}
