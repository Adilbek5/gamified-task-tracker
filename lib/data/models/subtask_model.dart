class SubtaskModel {
  final String id;
  final String taskId;
  final String title;
  final bool isCompleted;
  final int sortOrder;

  const SubtaskModel({
    required this.id,
    required this.taskId,
    required this.title,
    this.isCompleted = false,
    this.sortOrder = 0,
  });

  SubtaskModel copyWith({
    String? id,
    String? taskId,
    String? title,
    bool? isCompleted,
    int? sortOrder,
  }) =>
      SubtaskModel(
        id: id ?? this.id,
        taskId: taskId ?? this.taskId,
        title: title ?? this.title,
        isCompleted: isCompleted ?? this.isCompleted,
        sortOrder: sortOrder ?? this.sortOrder,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'task_id': taskId,
        'title': title,
        'is_completed': isCompleted ? 1 : 0,
        'sort_order': sortOrder,
      };

  factory SubtaskModel.fromMap(Map<String, dynamic> m) => SubtaskModel(
        id: m['id'] as String,
        taskId: m['task_id'] as String,
        title: m['title'] as String,
        isCompleted: (m['is_completed'] as int? ?? 0) == 1,
        sortOrder: m['sort_order'] as int? ?? 0,
      );
}
