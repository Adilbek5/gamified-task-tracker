import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/challenge_model.dart';
import '../../../data/models/user_model.dart';
import '../../../providers/challenge_provider.dart';
import 'challenge_detail_screen.dart';

class ChallengeScreen extends StatefulWidget {
  final UserModel user;
  const ChallengeScreen({super.key, required this.user});

  @override
  State<ChallengeScreen> createState() =>
      _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ChallengeProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Challenges',
          style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w500),
        ),
        actions: [
          if (widget.user.isTeamLead)
            IconButton(
              icon: const Icon(Icons.add,
                  color: AppColors.primaryLight),
              onPressed: () =>
                  _showCreateDialog(context),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding:
            const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            if (cp.challenges.isEmpty)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius:
                        BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.border,
                        width: 0.5)),
                child: const Text(
                    'No challenges yet. Team lead can create one.',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13)),
              )
            else
              ...cp.challenges.map((c) {
                return _ChallengeCard(
                  challenge: c,
                  user: widget.user,
                  isExpanded: false,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChallengeDetailScreen(
                        challenge: c,
                        user: widget.user,
                      ),
                    ),
                  ),
                  leaderboard: const [],
                );
              }),
          ],
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    int selectedDays = 7;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Text('New Challenge',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleCtrl,
                style: const TextStyle(
                    color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Challenge title',
                  hintStyle: const TextStyle(
                      color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.surfaceAlt,
                  border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(8),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Duration',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [3, 7, 14, 30]
                    .map((days) => ChoiceChip(
                          label: Text('$days days'),
                          selected:
                              selectedDays == days,
                          onSelected: (_) =>
                              setDialogState(() =>
                                  selectedDays = days),
                          selectedColor:
                              AppColors.primary,
                          backgroundColor:
                              AppColors.surfaceAlt,
                          labelStyle: TextStyle(
                            color: selectedDays ==
                                    days
                                ? Colors.white
                                : AppColors
                                    .textSecondary,
                            fontSize: 12,
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius:
                      BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('MMM d')
                          .format(DateTime.now()),
                      style: const TextStyle(
                          color:
                              AppColors.textSecondary,
                          fontSize: 12),
                    ),
                    const Text(' → ',
                        style: TextStyle(
                            color:
                                AppColors.textMuted)),
                    Text(
                      DateFormat('MMM d').format(
                          DateTime.now().add(Duration(
                              days: selectedDays))),
                      style: const TextStyle(
                          color:
                              AppColors.primaryLight,
                          fontSize: 12,
                          fontWeight:
                              FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () =>
                    Navigator.pop(ctx),
                child: const Text('Cancel',
                    style: TextStyle(
                        color: AppColors
                            .textSecondary))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(8))),
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty)
                  return;
                Navigator.pop(ctx);
                await context
                    .read<ChallengeProvider>()
                    .createChallenge(
                      title:
                          titleCtrl.text.trim(),
                      teamId:
                          widget.user.teamId!,
                      startDate: DateTime.now(),
                      endDate: DateTime.now().add(
                          Duration(
                              days: selectedDays)),
                    );
              },
              child: const Text('CREATE',
                  style: TextStyle(
                      color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final ChallengeModel challenge;
  final UserModel user;
  final bool isExpanded;
  final VoidCallback onTap;
  final List<LeaderboardEntry> leaderboard;

  const _ChallengeCard({
    required this.challenge,
    required this.user,
    required this.isExpanded,
    required this.onTap,
    required this.leaderboard,
  });

  static const _gold = Color(0xFFF59E0B);
  static const _silver = Color(0xFF888888);
  static const _bronze = Color(0xFFCD7F32);
  static const _liveGreen = Color(0xFF22C55E);
  static const _joinedBg = Color(0xFF0A2010);
  static const _meBg = Color(0xFF1E1035);

  @override
  Widget build(BuildContext context) {
    final isJoined =
        challenge.participantIds.contains(user.id);
    final now = DateTime.now();
    final daysLeft =
        challenge.endDate.difference(now).inDays;
    final totalDays = challenge.endDate
        .difference(challenge.startDate)
        .inDays;
    final elapsed = now
        .difference(challenge.startDate)
        .inDays
        .clamp(0, totalDays);
    final timeProgress = totalDays > 0
        ? 1.0 - (elapsed / totalDays)
        : 0.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: challenge.isActive
                ? AppColors.primary.withOpacity(0.4)
                : const Color(0xFF252535),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // Status row
            Row(children: [
              if (challenge.isActive) ...[
                Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                        color: _liveGreen,
                        shape: BoxShape.circle)),
                const SizedBox(width: 5),
                const Text('Live',
                    style: TextStyle(
                        color: _liveGreen,
                        fontSize: 10,
                        fontWeight:
                            FontWeight.w500)),
              ] else if (daysLeft < 0)
                const Text('Ended',
                    style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10))
              else
                const Text('Upcoming',
                    style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10)),
              const Spacer(),
              Text(
                daysLeft > 0
                    ? '$daysLeft days left'
                    : daysLeft == 0
                        ? 'Last day!'
                        : 'Ended',
                style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.arrow_forward_ios,
                  size: 12, color: AppColors.textMuted),
            ]),
            const SizedBox(height: 10),

            // Title
            Text(challenge.title,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),

            // Subtitle
            Text(
              '${challenge.participantIds.length} participants · Ends ${DateFormat('MMM d').format(challenge.endDate)}',
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11),
            ),

            // Progress bar (time remaining)
            if (challenge.isActive) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius:
                    BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: timeProgress
                      .clamp(0.0, 1.0),
                  backgroundColor:
                      AppColors.surfaceAlt,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(
                          AppColors.primary),
                  minHeight: 4,
                ),
              ),
            ],

            const SizedBox(height: 14),

            // Join/Joined
            if (!isJoined && challenge.isActive)
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                                10)),
                  ),
                  onPressed: () => context
                      .read<ChallengeProvider>()
                      .join(user.teamId!,
                          challenge.id, user.id),
                  child: const Text('JOIN',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight:
                              FontWeight.w600,
                          fontSize: 14)),
                ),
              )
            else if (isJoined)
              Container(
                padding:
                    const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6),
                decoration: BoxDecoration(
                  color: _joinedBg,
                  borderRadius:
                      BorderRadius.circular(8),
                  border: Border.all(
                      color: _liveGreen
                          .withOpacity(0.3),
                      width: 0.5),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle,
                        color: _liveGreen,
                        size: 14),
                    SizedBox(width: 6),
                    Text('Joined',
                        style: TextStyle(
                            color: _liveGreen,
                            fontSize: 12,
                            fontWeight:
                                FontWeight.w500)),
                  ],
                ),
              ),

            // Leaderboard (expanded)
            if (isExpanded) ...[
              const SizedBox(height: 14),
              const Divider(
                  color: AppColors.border,
                  height: 1),
              const SizedBox(height: 12),
              Row(children: [
                Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                        color: _liveGreen,
                        shape: BoxShape.circle)),
                const SizedBox(width: 6),
                const Text('LEADERBOARD',
                    style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 9,
                        letterSpacing: 0.8,
                        fontWeight:
                            FontWeight.w500)),
              ]),
              const SizedBox(height: 10),
              if (leaderboard.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(
                      vertical: 8),
                  child: Text(
                      'Be the first to complete tasks!',
                      style: TextStyle(
                          color: AppColors
                              .textSecondary,
                          fontSize: 12)),
                )
              else ...[
                ...leaderboard
                    .take(5)
                    .toList()
                    .asMap()
                    .entries
                    .map((e) {
                  final rank = e.key + 1;
                  final entry = e.value;
                  final isMe =
                      entry.userId == user.id;
                  final rankColor = rank == 1
                      ? _gold
                      : rank == 2
                          ? _silver
                          : rank == 3
                              ? _bronze
                              : AppColors.textMuted;
                  final emoji = rank == 1
                      ? '🥇'
                      : rank == 2
                          ? '🥈'
                          : rank == 3
                              ? '🥉'
                              : '👤';

                  return Container(
                    margin: const EdgeInsets.only(
                        bottom: 4),
                    padding:
                        const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7),
                    decoration: BoxDecoration(
                      color: isMe
                          ? _meBg
                          : Colors.transparent,
                      borderRadius:
                          BorderRadius.circular(8),
                      border: isMe
                          ? const Border(
                              left: BorderSide(
                                  color: AppColors
                                      .primary,
                                  width: 2))
                          : null,
                    ),
                    child: Row(children: [
                      SizedBox(
                        width: 22,
                        child: Text('$rank',
                            style: TextStyle(
                                color: rankColor,
                                fontSize: 12,
                                fontWeight:
                                    FontWeight
                                        .w600)),
                      ),
                      Text(emoji,
                          style: const TextStyle(
                              fontSize: 14)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.userName +
                              (isMe ? ' (you)' : ''),
                          style: TextStyle(
                            color: isMe
                                ? AppColors
                                    .primaryLight
                                : AppColors
                                    .textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Text('${entry.xp} XP',
                          style: const TextStyle(
                              color:
                                  AppColors.textMuted,
                              fontSize: 11,
                              fontWeight:
                                  FontWeight.w500)),
                    ]),
                  );
                }),
                // Show current user rank if not in top 5
                if (!leaderboard
                        .take(5)
                        .any((e) =>
                            e.userId == user.id) &&
                    leaderboard.any(
                        (e) => e.userId == user.id)) ...[
                  const Divider(
                      color: AppColors.border,
                      height: 12),
                  Builder(builder: (context) {
                    final myIdx = leaderboard
                        .indexWhere(
                            (e) => e.userId == user.id);
                    final myEntry =
                        leaderboard[myIdx];
                    return Container(
                      padding:
                          const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7),
                      decoration: BoxDecoration(
                        color: _meBg,
                        borderRadius:
                            BorderRadius.circular(8),
                        border: const Border(
                            left: BorderSide(
                                color: AppColors
                                    .primary,
                                width: 2)),
                      ),
                      child: Row(children: [
                        SizedBox(
                          width: 22,
                          child: Text(
                              '${myIdx + 1}',
                              style: const TextStyle(
                                  color: AppColors
                                      .textMuted,
                                  fontSize: 12,
                                  fontWeight:
                                      FontWeight
                                          .w600)),
                        ),
                        const Text('👤',
                            style: TextStyle(
                                fontSize: 14)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${myEntry.userName} (you)',
                            style: const TextStyle(
                                color: AppColors
                                    .primaryLight,
                                fontSize: 12),
                          ),
                        ),
                        Text('${myEntry.xp} XP',
                            style: const TextStyle(
                                color: AppColors
                                    .textMuted,
                                fontSize: 11,
                                fontWeight:
                                    FontWeight
                                        .w500)),
                      ]),
                    );
                  }),
                ],
              ],
            ],
          ],
        ),
      ),
    );
  }
}
