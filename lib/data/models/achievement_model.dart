class AchievementModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final DateTime earnedAt;

  AchievementModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.earnedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'user_id': userId,
    'title': title, 'description': description,
    'earned_at': earnedAt.toIso8601String(),
  };

  factory AchievementModel.fromMap(Map<String, dynamic> m) =>
      AchievementModel(
        id: m['id'], userId: m['user_id'],
        title: m['title'], description: m['description'],
        earnedAt: DateTime.parse(m['earned_at']),
      );
}