import 'package:flutter/foundation.dart';
import '../data/models/task_model.dart';
import '../data/models/user_model.dart';
import '../services/activity_service.dart';

class ActivityProvider extends ChangeNotifier {
  final ActivityService _svc;

  List<MemberActivity> _members = [];
  bool _listening = false;

  List<MemberActivity> get members => _members;
  List<MemberActivity> get onlineMembers =>
    _members.where((m) => m.isOnline).toList();
  List<MemberActivity> get activeMembers =>
    _members.where((m) => m.isOnline && m.hasActiveTask).toList();

  ActivityProvider(this._svc);

  void startListening(String teamId) {
    if (_listening) return;
    _listening = true;
    _svc.teamActivityStream(teamId).listen((list) {
      _members = list;
      notifyListeners();
    });
  }

  Future<void> setUserOnline(UserModel user) async {
    if (!user.hasTeam) return;
    _svc.setupPresence(user.teamId!, user.id);
    await _svc.updateMemberActivity(
      teamId: user.teamId!,
      userId: user.id,
      name: user.name,
      skillLevel: user.skillLevel.name,
      isOnline: true,
    );
  }

  Future<void> setUserOffline(UserModel user) async {
    if (!user.hasTeam) return;
    await _svc.setOffline(user.teamId!, user.id);
  }

  Future<void> onTaskStarted(UserModel user, TaskModel task) async {
    if (!user.hasTeam) return;
    await _svc.updateMemberActivity(
      teamId: user.teamId!,
      userId: user.id,
      name: user.name,
      skillLevel: user.skillLevel.name,
      isOnline: true,
      currentTaskId: task.id,
      currentTaskTitle: task.title,
    );
    await _svc.markTaskStarted(
      teamId: user.teamId!,
      taskId: task.id,
      taskTitle: task.title,
      difficulty: task.difficulty,
      userId: user.id,
      userName: user.name,
      skillLevel: user.skillLevel.name,
    );
  }

  Future<void> onTaskCompleted(UserModel user, TaskModel task) async {
    if (!user.hasTeam) return;
    await _svc.updateMemberActivity(
      teamId: user.teamId!,
      userId: user.id,
      name: user.name,
      skillLevel: user.skillLevel.name,
      isOnline: true,
      currentTaskId: null,
      currentTaskTitle: null,
    );
    await _svc.markTaskCompleted(
      teamId: user.teamId!,
      taskId: task.id,
      userId: user.id,
    );
  }
}
