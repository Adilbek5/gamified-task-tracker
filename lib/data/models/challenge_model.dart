class ChallengeModel {
  final String id;
  final String title;
  final String teamId;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> participantIds;

  ChallengeModel({
    required this.id,
    required this.title,
    required this.teamId,
    required this.startDate,
    required this.endDate,
    this.participantIds = const [],
  });

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'team_id': teamId,
    'start_date': startDate.toIso8601String(),
    'end_date': endDate.toIso8601String(),
    'participant_ids': participantIds.join(','),
  };

  factory ChallengeModel.fromMap(Map<String, dynamic> m) =>
      ChallengeModel(
        id: m['id'],
        title: m['title'],
        teamId: m['team_id'] ?? '',
        startDate: DateTime.parse(m['start_date']),
        endDate: DateTime.parse(m['end_date']),
        participantIds: m['participant_ids'] != null &&
            (m['participant_ids'] as String).isNotEmpty
            ? (m['participant_ids'] as String).split(',')
            : [],
      );

  Map<String, dynamic> toFirebase() => {
    'title': title,
    'team_id': teamId,
    'start_date': startDate.toIso8601String(),
    'end_date': endDate.toIso8601String(),
    'participant_ids': participantIds,
  };

  factory ChallengeModel.fromFirebase(
      String id, Map<dynamic, dynamic> m) =>
      ChallengeModel(
        id: id,
        title: m['title'] ?? '',
        teamId: m['team_id'] ?? '',
        startDate: DateTime.parse(m['start_date']),
        endDate: DateTime.parse(m['end_date']),
        participantIds: m['participant_ids'] != null
            ? List<String>.from(m['participant_ids'])
            : [],
      );
}

class LeaderboardEntry {
  final String userId;
  final String userName;
  final int xp;

  LeaderboardEntry({
    required this.userId,
    required this.userName,
    required this.xp,
  });

  factory LeaderboardEntry.fromFirebase(
      Map<dynamic, dynamic> m) =>
      LeaderboardEntry(
        userId: m['user_id'] ?? '',
        userName: m['user_name'] ?? '',
        xp: (m['xp'] ?? 0) as int,
      );

  Map<String, dynamic> toMap() => {
    'user_id': userId,
    'user_name': userName,
    'xp': xp,
  };
}