import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/achievement_model.dart';

class AchievementBadge extends StatelessWidget {
  final AchievementModel achievement;
  const AchievementBadge({super.key, required this.achievement});

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: AppColors.warning.withOpacity(0.3),
              width: 0.5)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.emoji_events,
            size: 14, color: AppColors.warning),
        const SizedBox(width: 5),
        Text(achievement.title,
            style: const TextStyle(
                color: AppColors.warning,
                fontSize: 11,
                fontWeight: FontWeight.w500)),
      ]));
}