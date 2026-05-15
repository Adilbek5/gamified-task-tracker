import 'package:flutter/foundation.dart';
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
    bool streakReset,
    String completionStatus,
    bool isEarlyBird,
    int daysLate,
  })> processCompletion(TaskModel task, UserModel user) async {
    // --- Deadline analysis ---
    final now = DateTime.now();
    final onTime = now.isBefore(task.deadline);
    final hoursLate = onTime ? 0 : now.difference(task.deadline).inHours;
    final daysLate = hoursLate ~/ 24;

    final isEarly = task.deadline.difference(now).inHours > 1;
    final isVeryLate = daysLate >= 2;

    // --- XP calculation ---
    final baseXp = onTime ? task.difficulty * 10 : 0;
    final xp = (baseXp * user.xpMultiplier).round();
    final newXp = user.xp + xp;

    // --- Coins calculation ---
    final baseCoins = onTime ? task.difficulty * 5 : 0;
    int coins = (baseCoins * user.xpMultiplier).round();

    if (isEarly && onTime && coins > 0) {
      final bonus = (coins * 0.1).round();
      coins += bonus;
      debugPrint('[Gamification] Early Bird bonus: +$bonus coins');
    }

    final newCoins = user.coins + coins;

    // --- Streak calculation ---
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final yesterday = DateTime.now()
        .subtract(const Duration(days: 1))
        .toIso8601String()
        .substring(0, 10);

    int newStreak = user.streakDays;
    String newLastActive = user.lastActiveDate;

    if (!onTime && isVeryLate) {
      newStreak = 0;
      newLastActive = '';
      debugPrint('[Gamification] Streak RESET — task $daysLate days overdue');
    } else if (!onTime) {
      newStreak = 0;
      newLastActive = '';
      debugPrint('[Gamification] Streak RESET — task overdue');
    } else {
      if (newLastActive == today) {
        // Already completed today — keep streak
      } else if (newLastActive == yesterday) {
        newStreak = user.streakDays + 1;
        newLastActive = today;
      } else if (newLastActive.isEmpty) {
        newStreak = 1;
        newLastActive = today;
      } else {
        newStreak = 1;
        newLastActive = today;
      }
    }

    // --- Level calculation ---
    final newLevel = XpConstants.levelFromXp(newXp);

    // --- Update user ---
    final updatedUser = user.copyWith(
      xp: newXp,
      level: newLevel,
      coins: newCoins,
      streakDays: newStreak,
      lastActiveDate: newLastActive,
    );

    // --- Save to DB ---
    await _userRepo.updateXp(user.id, newXp, newLevel);
    if (coins > 0) {
      await _shopRepo.updateCoins(user.id, newCoins);
    }
    await _userRepo.upsert(updatedUser);

    // --- Achievements ---
    final completedCount = await _taskRepo.countCompleted(user.teamId ?? '');
    final existing = await _userRepo.getAchievements(user.id);
    final existingTitles = existing.map((a) => a.title).toSet();
    final newAchievements = <AchievementModel>[];

    Future<void> try_(String t, String d, bool cond) async {
      if (cond && !existingTitles.contains(t)) {
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

    await try_('First Step', 'Completed your first task!', completedCount >= 1);
    await try_('Task Master', 'Completed 10 tasks!', completedCount >= 10);
    await try_('XP Hunter', 'Earned 100 XP!', newXp >= 100);
    await try_('Code Knight', 'Reached level 5!', newLevel >= 5);
    await try_('Early Bird', 'Completed a task ahead of schedule!', isEarly && onTime);
    await try_('Week Warrior', 'Maintained a 7-day streak!', newStreak >= 7);
    await try_('Unstoppable', 'Maintained a 30-day streak!', newStreak >= 30);

    // --- Build result ---
    String completionStatus;
    if (isEarly && onTime) {
      completionStatus = 'early_bird';
    } else if (onTime) {
      completionStatus = 'on_time';
    } else if (isVeryLate) {
      completionStatus = 'very_late';
    } else {
      completionStatus = 'late';
    }

    return (
      updatedUser: updatedUser,
      achievements: newAchievements,
      xpEarned: xp,
      coinsEarned: coins,
      streakReset: !onTime,
      completionStatus: completionStatus,
      isEarlyBird: isEarly && onTime,
      daysLate: daysLate,
    );
  }
}
