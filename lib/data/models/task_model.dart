enum TaskStatus { pending, inProgress, completed, overdue }

class TaskModel {
  final String id;
  final String title;
  final String? description;
  final int difficulty;
  final DateTime deadline;
  final TaskStatus status;
  final String createdBy;
  final String teamId;
  final String? assignedUserId;
  final String? assignedUserName;
  final DateTime? completedAt;
  final int xpEarned;

  const TaskModel({
    required this.id,
    required this.title,
    this.description,
    required this.difficulty,
    required this.deadline,
    this.status = TaskStatus.pending,
    required this.createdBy,
    required this.teamId,
    this.assignedUserId,
    this.assignedUserName,
    this.completedAt,
    this.xpEarned = 0,
  });

  /// Returns true if [userId] is allowed to complete this task.
  /// An unassigned task (null or empty assignedUserId) can be completed by anyone.
  bool canBeCompletedBy(String userId) {
    if (assignedUserId == null || assignedUserId!.isEmpty) return true;
    return assignedUserId == userId;
  }

  TaskModel copyWith({
    String? id, String? title, String? description,
    int? difficulty, DateTime? deadline, TaskStatus? status,
    String? createdBy, String? teamId,
    String? assignedUserId, String? assignedUserName,
    DateTime? completedAt, int? xpEarned,
  }) =>
      TaskModel(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        difficulty: difficulty ?? this.difficulty,
        deadline: deadline ?? this.deadline,
        status: status ?? this.status,
        createdBy: createdBy ?? this.createdBy,
        teamId: teamId ?? this.teamId,
        assignedUserId: assignedUserId ?? this.assignedUserId,
        assignedUserName: assignedUserName ?? this.assignedUserName,
        completedAt: completedAt ?? this.completedAt,
        xpEarned: xpEarned ?? this.xpEarned,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description ?? '',
        'difficulty': difficulty,
        'deadline': deadline.toIso8601String(),
        'status': status.name,
        'created_by': createdBy,
        'team_id': teamId,
        'assigned_user_id': assignedUserId ?? '',
        'assigned_user_name': assignedUserName ?? '',
        'completed_at': completedAt?.toIso8601String() ?? '',
        'xp_earned': xpEarned,
      };

  factory TaskModel.fromMap(Map<String, dynamic> m) {
    return TaskModel(
      id: _parseStr(m['id']),
      title: _parseStr(m['title'], 'Untitled'),
      description: m['description']?.toString(),
      difficulty: _parseInt(m['difficulty'], 1),
      deadline: _parseDate(m['deadline']),
      status: TaskStatus.values.firstWhere(
        (e) => e.name == _parseStr(m['status'], 'pending'),
        orElse: () => TaskStatus.pending,
      ),
      createdBy: _parseStr(m['created_by']),
      teamId: _parseStr(m['team_id']),
      assignedUserId: m['assigned_user_id']?.toString(),
      assignedUserName: m['assigned_user_name']?.toString(),
      completedAt: _parseDateOrNull(m['completed_at']),
      xpEarned: _parseInt(m['xp_earned'], 0),
    );
  }

  static String _parseStr(dynamic v, [String def = '']) =>
      (v ?? def).toString();

  // Handles int, double (Firebase numeric), String, and null safely.
  static int _parseInt(dynamic v, [int def = 0]) {
    if (v == null) return def;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? def;
  }

  static DateTime _parseDate(dynamic v) {
    if (v == null) return DateTime.now().add(const Duration(days: 1));
    try {
      return DateTime.parse(v.toString());
    } catch (_) {
      return DateTime.now().add(const Duration(days: 1));
    }
  }

  static DateTime? _parseDateOrNull(dynamic v) {
    if (v == null || v.toString().isEmpty) return null;
    try {
      return DateTime.parse(v.toString());
    } catch (_) {
      return null;
    }
  }

  factory TaskModel.fromFirebase(String id, Map<dynamic, dynamic> m) {
    final map = Map<String, dynamic>.from(m);
    map['id'] = id;
    return TaskModel.fromMap(map);
  }

  Map<String, dynamic> toFirebase() => toMap();
}