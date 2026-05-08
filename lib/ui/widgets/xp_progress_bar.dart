import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class XpProgressBar extends StatelessWidget {
  final int current, total, level;
  const XpProgressBar({
    super.key,
    required this.current,
    required this.total,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    final p = total > 0 ? (current / total).clamp(0.0, 1.0) : 0.0;
    return Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Level $level',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                Text('$current / $total XP',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ]),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: p, minHeight: 7,
              backgroundColor: AppColors.surfaceAlt,
              valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary),
            ),
          ),
        ]);
  }
}