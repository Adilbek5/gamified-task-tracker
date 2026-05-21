import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/challenge_model.dart';
import '../../../data/models/user_model.dart';
import '../../../providers/challenge_provider.dart';
import 'challenge_detail_screen.dart';
import '../../../widgets/animated_list_tile.dart';

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
              ...cp.challenges.asMap().entries.map<Widget>((entry) {
                final c = entry.value;
                return AnimatedListTile(
                  index: entry.key,
                  child: _ChallengeCard(
                    challenge: c,
                    user: widget.user,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChallengeDetailScreen(
                          challenge: c,
                          user: widget.user,
                        ),
                      ),
                    ),
                    leaderboard: cp.leaderboardFor(c.id),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(
            horizontal: 20, vertical: 24),
        child: _CreateChallengeDialog(
          teamId: widget.user.teamId!,
          onCreated: () => Navigator.pop(ctx),
        ),
      ),
    );
  }
}

// ── Responsive create-challenge dialog ─────────────────────────

class _CreateChallengeDialog extends StatefulWidget {
  final String teamId;
  final VoidCallback onCreated;

  const _CreateChallengeDialog({
    required this.teamId,
    required this.onCreated,
  });

  @override
  State<_CreateChallengeDialog> createState() =>
      _CreateChallengeDialogState();
}

class _CreateChallengeDialogState
    extends State<_CreateChallengeDialog> {
  final _titleController = TextEditingController();
  int _selectedDays = 7;
  int _selectedPrize = 0;
  bool _isCreating = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  Future<void> _createChallenge() async {
    if (_titleController.text.trim().isEmpty) return;
    setState(() => _isCreating = true);
    try {
      await context.read<ChallengeProvider>().createChallenge(
        title: _titleController.text.trim(),
        teamId: widget.teamId,
        startDate: DateTime.now(),
        endDate:
            DateTime.now().add(Duration(days: _selectedDays)),
        prizeCoins: _selectedPrize,
      );
      widget.onCreated();
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF191D30),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Scrollable form ────────────────────────────────
          Flexible(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'New Challenge',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Challenge title input
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Challenge title',
                      hintStyle: const TextStyle(
                        fontFamily: 'Poppins',
                        color: Color(0xFF848A94),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF0A0C16),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Duration label
                  const Text(
                    'Duration',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Color(0xFF848A94),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Duration selector — 2×2 grid, never overflows
                  GridView.count(
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 3.0,
                    children: [3, 7, 14, 30]
                        .map((days) => GestureDetector(
                              onTap: () => setState(
                                  () => _selectedDays = days),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _selectedDays == days
                                      ? const Color(0xFF3580FF)
                                      : const Color(0xFF0A0C16),
                                  borderRadius:
                                      BorderRadius.circular(10),
                                  border: Border.all(
                                    color: _selectedDays == days
                                        ? const Color(0xFF3580FF)
                                        : const Color(0xFF2A2D3E),
                                  ),
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisSize:
                                        MainAxisSize.min,
                                    children: [
                                      if (_selectedDays == days)
                                        const Padding(
                                          padding: EdgeInsets
                                              .only(right: 4),
                                          child: Icon(
                                            Icons.check,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                        ),
                                      Text(
                                        '$days days',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          color:
                                              _selectedDays ==
                                                      days
                                                  ? Colors.white
                                                  : const Color(
                                                      0xFF848A94),
                                          fontSize: 13,
                                          fontWeight:
                                              FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 12),

                  // Date range display
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0C16),
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Text(
                          _formatDate(DateTime.now()),
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            color: Color(0xFF848A94),
                            fontSize: 12,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8),
                          child: Icon(
                            Icons.arrow_forward,
                            size: 14,
                            color: Color(0xFF848A94),
                          ),
                        ),
                        Text(
                          _formatDate(DateTime.now().add(
                              Duration(days: _selectedDays))),
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Prize Coins label
                  const Text(
                    '🪙 Prize Coins',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Color(0xFF848A94),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Prize selector — Wrap, never overflows
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [0, 100, 250, 500, 1000]
                        .map((coins) => GestureDetector(
                              onTap: () => setState(
                                  () => _selectedPrize = coins),
                              child: Container(
                                padding: const EdgeInsets
                                    .symmetric(
                                    horizontal: 14,
                                    vertical: 8),
                                decoration: BoxDecoration(
                                  color: _selectedPrize == coins
                                      ? const Color(0xFFFFB800)
                                          .withValues(alpha: 0.2)
                                      : const Color(0xFF0A0C16),
                                  borderRadius:
                                      BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _selectedPrize == coins
                                        ? const Color(0xFFFFB800)
                                        : const Color(0xFF2A2D3E),
                                  ),
                                ),
                                child: Text(
                                  coins == 0
                                      ? 'No prize'
                                      : '🪙 $coins',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color: _selectedPrize == coins
                                        ? const Color(0xFFFFB800)
                                        : const Color(0xFF848A94),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // ── Buttons — fixed below scroll, always visible ───
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                        side: const BorderSide(
                            color: Color(0xFF2A2D3E)),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Color(0xFF848A94),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed:
                        _isCreating ? null : _createChallenge,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF3580FF),
                      disabledBackgroundColor:
                          const Color(0xFF3580FF)
                              .withValues(alpha: 0.5),
                      padding: const EdgeInsets.symmetric(
                          vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                    ),
                    child: _isCreating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'CREATE',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final ChallengeModel challenge;
  final UserModel user;
  final VoidCallback onTap;
  final List<LeaderboardEntry> leaderboard;

  const _ChallengeCard({
    required this.challenge,
    required this.user,
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
            if (challenge.prizeCoins > 0)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB800)
                    .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFFFB800)
                      .withValues(alpha: 0.4))),
                child: Text(
                  '🏆 Prize: 🪙${challenge.prizeCoins} coins',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: Color(0xFFFFB800),
                    fontSize: 10,
                    fontWeight: FontWeight.w600))),
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

            Consumer<ChallengeProvider>(
              builder: (ctx, cp, _) {
                final lb = cp.leaderboardFor(challenge.id);
                if (lb.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'No participants yet — be first!',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Color(0xFF848A94),
                        fontSize: 10)));
                }
                final top = lb.take(2).toList();
                final medals = ['🥇', '🥈', '🥉'];
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Top players',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: Color(0xFF848A94),
                              fontSize: 10,
                              fontWeight: FontWeight.w500)),
                          const Spacer(),
                          Text(
                            '${lb.length} players',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              color: Color(0xFF848A94),
                              fontSize: 10)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ...top.asMap().entries.map((entry) {
                        final i = entry.key;
                        final player = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Text(medals[i],
                                  style: const TextStyle(fontSize: 14)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  player.userName,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis)),
                              Text(
                                '${player.xp} XP',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  color: Color(0xFF3580FF),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                            ],
                          ));
                      }),
                    ],
                  ));
              },
            ),

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

            // Leaderboard
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
        ),
      ),
    );
  }
}
