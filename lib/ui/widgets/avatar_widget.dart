import 'package:flutter/material.dart';

import '../../core/constants/avatar_constants.dart';

class AvatarWidget extends StatelessWidget {
  final String avatarId;
  final String borderId;
  final String? badgeId;
  final double size;

  const AvatarWidget({
    super.key,
    required this.avatarId,
    required this.borderId,
    this.badgeId,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = AvatarConstants.getById(avatarId);
    final border = BorderConstants.getById(borderId);
    final hasBadge = badgeId != null && badgeId != 'badge_none';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Border ring
        if (border.id != 'border_none')
          Container(
            width: size + border.width * 2,
            height: size + border.width * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: border.gradient != null
                  ? SweepGradient(colors: border.gradient!)
                  : null,
              color: border.gradient == null ? border.color : null,
            ),
          ),
        // Avatar circle
        Container(
          width: size,
          height: size,
          margin: border.id != 'border_none'
              ? EdgeInsets.all(border.width)
              : EdgeInsets.zero,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: avatar.gradient,
            ),
          ),
          child: Center(
            child: Icon(
              avatar.icon,
              color: avatar.iconColor,
              size: size * 0.48,
            ),
          ),
        ),
        // Badge
        if (hasBadge)
          Positioned(
            right: 0,
            bottom: 0,
            child: _BadgeDot(
              badgeId: badgeId!,
              size: size * 0.32,
            ),
          ),
      ],
    );
  }
}

class _BadgeDot extends StatelessWidget {
  final String badgeId;
  final double size;

  const _BadgeDot({
    required this.badgeId,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final badge = BadgeConstants.getById(badgeId);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0C16),
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF191D30),
          width: 2,
        ),
      ),
      child: Center(
        child: Icon(
          badge.icon,
          color: badge.color,
          size: size * 0.6,
        ),
      ),
    );
  }
}

/// Small version for task cards and lists
class AvatarMini extends StatelessWidget {
  final String avatarId;
  final String borderId;
  final double size;

  const AvatarMini({
    super.key,
    required this.avatarId,
    required this.borderId,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = AvatarConstants.getById(avatarId);
    final border = BorderConstants.getById(borderId);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: avatar.gradient,
        ),
        border: border.id != 'border_none'
            ? Border.all(color: border.color, width: 2)
            : null,
      ),
      child: Center(
        child: Icon(
          avatar.icon,
          color: avatar.iconColor,
          size: size * 0.48,
        ),
      ),
    );
  }
}
