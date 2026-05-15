import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class MemberActivity {
  final String userId;
  final String name;
  final String skillLevel;
  final bool isOnline;
  final bool isTeamLead;
  final String? currentTaskId;
  final String? currentTaskTitle;

  const MemberActivity({
    required this.userId,
    required this.name,
    required this.skillLevel,
    required this.isOnline,
    this.isTeamLead = false,
    this.currentTaskId,
    this.currentTaskTitle,
  });

  factory MemberActivity.fromFirebase(
      String uid, Map<dynamic, dynamic> m) =>
    MemberActivity(
      userId: uid,
      name: m['name'] as String? ?? 'Unknown',
      skillLevel: m['skill_level'] as String? ?? 'junior',
      isOnline: m['is_online'] as bool? ?? false,
      isTeamLead: m['is_team_lead'] as bool? ?? false,
      currentTaskId: m['current_task_id'] as String?,
      currentTaskTitle: m['current_task_title'] as String?,
    );

  String get skillEmoji {
    switch (skillLevel) {
      case 'senior': return '🔥';
      case 'middle': return '⚡';
      default: return '🌱';
    }
  }

  Color get skillColor {
    switch (skillLevel) {
      case 'senior': return const Color(0xFFFFD700);
      case 'middle': return const Color(0xFF3580FF);
      default: return const Color(0xFF22C55E);
    }
  }

  String get skillLabel {
    switch (skillLevel) {
      case 'senior': return 'Senior';
      case 'middle': return 'Middle';
      default: return 'Junior';
    }
  }

  bool get hasActiveTask =>
    currentTaskId != null && currentTaskId!.isNotEmpty;
}

class ActivityService {
  final _db = FirebaseDatabase.instance;

  Future<void> updateMemberActivity({
    required String teamId,
    required String userId,
    required String name,
    required String skillLevel,
    bool isOnline = true,
    bool isTeamLead = false,
    String? currentTaskId,
    String? currentTaskTitle,
  }) async {
    try {
      await _db.ref('team_members/$teamId/$userId').update({
        'user_id': userId,
        'name': name,
        'skill_level': skillLevel,
        'is_online': isOnline,
        'is_team_lead': isTeamLead,
        'current_task_id': currentTaskId ?? '',
        'current_task_title': currentTaskTitle ?? '',
        'last_active': ServerValue.timestamp,
      });
    } catch (_) {}
  }

  Future<void> setOffline(String teamId, String userId) async {
    try {
      await _db.ref('team_members/$teamId/$userId').update({
        'is_online': false,
        'current_task_id': '',
        'current_task_title': '',
        'last_active': ServerValue.timestamp,
      });
    } catch (_) {}
  }

  void setupPresence(String teamId, String userId) {
    _db.ref('team_members/$teamId/$userId/is_online')
      .onDisconnect().set(false);
  }

  Stream<List<MemberActivity>> teamActivityStream(String teamId) {
    return _db.ref('team_members/$teamId').onValue.map((event) {
      if (event.snapshot.value == null) return [];
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      return data.entries
        .map((e) => MemberActivity.fromFirebase(
          e.key.toString(),
          e.value as Map<dynamic, dynamic>))
        .toList()
        ..sort((a, b) {
          if (a.isOnline != b.isOnline) return a.isOnline ? -1 : 1;
          const order = ['senior', 'middle', 'junior'];
          return order.indexOf(a.skillLevel)
            .compareTo(order.indexOf(b.skillLevel));
        });
    });
  }

  Future<void> markTaskStarted({
    required String teamId,
    required String taskId,
    required String taskTitle,
    required int difficulty,
    required String userId,
    required String userName,
    required String skillLevel,
  }) async {
    try {
      await _db
        .ref('task_activity/$teamId/$taskId/workers/$userId')
        .set({
          'name': userName,
          'skill_level': skillLevel,
          'started_at': ServerValue.timestamp,
        });
    } catch (_) {}
  }

  Future<void> markTaskCompleted({
    required String teamId,
    required String taskId,
    required String userId,
  }) async {
    try {
      await _db
        .ref('task_activity/$teamId/$taskId/workers/$userId')
        .remove();
    } catch (_) {}
  }
}
