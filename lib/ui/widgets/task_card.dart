import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/task_model.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback? onComplete;

  const TaskCard({super.key, required this.task, this.onComplete});

  Color get _diffColor {
    if (task.difficulty >= 8) return AppColors.danger;
    if (task.difficulty >= 5) return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = task.status == TaskStatus.completed;
    final isOverdue = task.status == TaskStatus.overdue;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isOverdue
              ? AppColors.danger.withOpacity(0.4)
              : AppColors.border,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: (!isCompleted && !isOverdue) ? onComplete : null,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                isCompleted ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: isCompleted
                      ? AppColors.primary
                      : AppColors.textMuted,
                  width: 1.5,
                ),
              ),
              child: isCompleted
                  ? const Icon(Icons.check,
                  size: 12, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
                color: _diffColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    color: isCompleted
                        ? AppColors.textMuted
                        : AppColors.textPrimary,
                    fontSize: 13,
                    decoration: isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Due ${DateFormat('MMM d, HH:mm').format(task.deadline)} · Diff ${task.difficulty}/10',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 10),
                ),
              ],
            ),
          ),
          if (isCompleted)
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '+${task.xpEarned} XP',
                style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 9,
                    fontWeight: FontWeight.w500),
              ),
            ),
          if (isOverdue)
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Late',
                  style: TextStyle(
                      color: AppColors.danger,
                      fontSize: 9,
                      fontWeight: FontWeight.w500)),
            ),
        ],
      ),
    );
  }
}