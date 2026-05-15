import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/challenge_model.dart';
import '../../../data/models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/challenge_provider.dart';
import '../../widgets/circular_progress_widget.dart';

class ChallengeDetailScreen extends StatefulWidget {
  final ChallengeModel challenge;
  final UserModel user;

  const ChallengeDetailScreen({
    super.key,
    required this.challenge,
    required this.user,
  });

  @override
  State<ChallengeDetailScreen> createState() => _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends State<ChallengeDetailScreen> {
  static const _gold = Color(0xFFF59E0B);
  static const _silver = Color(0xFF888888);
  static const _bronze = Color(0xFFCD7F32);
  static const _liveGreen = Color(0xFF22C55E);

  static final Set<String> _shownWinnerDialogs = {};

  ChallengeModel get _challenge => widget.challenge;
  UserModel get _user => widget.user;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_user.teamId != null) {
        final cp = context.read<ChallengeProvider>();
        cp.listenLeaderboard(_user.teamId!, _challenge.id);
        cp.listenActivity(_user.teamId!, _challenge.id);
      }
      _maybeShowWinnerDialog();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeShowWinnerDialog();
  }

  // ── helpers ──────────────────────────────────────────

  int get _daysLeft => _challenge.endDate.difference(DateTime.now()).inDays;
  int get _totalDays =>
      _challenge.endDate.difference(_challenge.startDate).inDays;

  double get _timeProgress {
    if (_totalDays <= 0) return 1.0;
    final elapsed =
        DateTime.now().difference(_challenge.startDate).inDays.clamp(0, _totalDays);
    return elapsed / _totalDays;
  }

  Color get _statusColor {
    if (_challenge.isActive) return _liveGreen;
    if (_daysLeft < 0) return AppColors.textMuted;
    return AppColors.warning;
  }

  String get _statusLabel {
    if (_challenge.isActive) return 'Live';
    if (_daysLeft < 0) return 'Ended';
    return 'Upcoming';
  }

  Color get _progressColor {
    if (_daysLeft < 0) return AppColors.textMuted;
    if (!_challenge.isActive) return AppColors.warning;
    return _liveGreen;
  }

  // ── actions ───────────────────────────────────────────

  Future<void> _join(BuildContext ctx) async {
    await ctx.read<ChallengeProvider>().join(
          _user.teamId!,
          _challenge.id,
          _user.id,
        );
    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
        backgroundColor: AppColors.success,
        content: Text('Joined challenge!',
            style: TextStyle(color: Colors.white)),
        duration: Duration(seconds: 2),
      ));
    }
  }

  // ── winner dialog ─────────────────────────────────────

  void _maybeShowWinnerDialog() {
    if (_challenge.isActive) return;
    if (_shownWinnerDialogs.contains(_challenge.id)) return;
    final cp = context.read<ChallengeProvider>();
    final lb = cp.leaderboardFor(_challenge.id);
    if (lb.isEmpty) return;

    _shownWinnerDialogs.add(_challenge.id);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _showWinnerDialog(lb);
      }
    });
  }

  void _showWinnerDialog(List<LeaderboardEntry> leaderboard) {
    final top3 = leaderboard.take(3).toList();
    final medals = ['🥇', '🥈', '🥉'];
    final medalColors = [
      const Color(0xFFFFB800),
      const Color(0xFFB0B0B0),
      const Color(0xFFCD7F32),
    ];
    final winner = top3.first;
    final myEntry = leaderboard
        .where((e) => e.userId == context.read<AuthProvider>().user?.id)
        .firstOrNull;
    final myRank = myEntry != null ? leaderboard.indexOf(myEntry) + 1 : -1;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF191D30),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: const Color(0xFFFFB800).withValues(alpha: 0.7),
                width: 2),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFFFFB800).withValues(alpha: 0.15),
                  blurRadius: 40,
                  spreadRadius: 5),
            ]),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🏆', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 8),
              const Text(
                'Challenge Ended!',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Color(0xFFFFB800),
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1)),
              const SizedBox(height: 4),
              Text(
                _challenge.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: Color(0xFF848A94),
                    fontSize: 12)),
              const SizedBox(height: 20),
              // Winner highlight
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    const Color(0xFFFFB800).withValues(alpha: 0.2),
                    const Color(0xFFFF6B35).withValues(alpha: 0.1),
                  ]),
                  borderRadius: BorderRadius.circular(16)),
                child: Column(children: [
                  const Text('🥇 Winner',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Color(0xFFFFB800),
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(winner.userName,
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800)),
                  Text('${winner.xp} XP earned',
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: Color(0xFF3580FF),
                          fontSize: 13)),
                  if (_challenge.prizeCoins > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '🪙 ${_challenge.prizeCoins} coins awarded!',
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            color: Color(0xFFFFB800),
                            fontSize: 14,
                            fontWeight: FontWeight.w700))),
                ]),
              ),
              // Ranks 2 and 3
              if (top3.length > 1) ...[
                const SizedBox(height: 16),
                ...top3.skip(1).toList().asMap().entries.map((e) {
                  final rank = e.key + 2;
                  final entry = e.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(children: [
                      Text(medals[rank - 1],
                          style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(entry.userName,
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                color: medalColors[rank - 1],
                                fontSize: 13,
                                fontWeight: FontWeight.w600))),
                      Text('${entry.xp} XP',
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              color: Color(0xFF848A94),
                              fontSize: 12)),
                    ]),
                  );
                }),
              ],
              // Current user's result if outside top 3
              if (myRank > 3 && myEntry != null) ...[
                const Divider(color: Color(0xFF2A2D3E)),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(children: [
                    Text('#$myRank',
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            color: Color(0xFF848A94),
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('${myEntry.userName} (you)',
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              color: Color(0xFF3580FF),
                              fontSize: 13,
                              fontWeight: FontWeight.w600))),
                    Text('${myEntry.xp} XP',
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            color: Color(0xFF848A94),
                            fontSize: 12)),
                  ]),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFB800),
                      foregroundColor: Colors.black,
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))),
                  child: const Text('See Full Results',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 14))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── build ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ChallengeProvider>();
    final leaderboard = cp.leaderboardFor(_challenge.id);
    final isJoined = _challenge.participantIds.contains(_user.id);

    final myEntry = leaderboard.where((e) => e.userId == _user.id).firstOrNull;
    final myRank = myEntry != null ? leaderboard.indexOf(myEntry) + 1 : null;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D14),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: AppColors.textPrimary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _challenge.title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: _statusColor.withOpacity(0.3), width: 0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_challenge.isActive) ...[
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                        color: _liveGreen, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  _statusLabel,
                  style: TextStyle(
                    color: _statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── hero section ──────────────────────────
            Text(
              _challenge.title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete as many tasks as possible to earn XP and climb the leaderboard.',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.calendar_today,
                  color: AppColors.textMuted, size: 13),
              const SizedBox(width: 6),
              Text(
                '${DateFormat('MMM d').format(_challenge.startDate)} → ${DateFormat('MMM d').format(_challenge.endDate)}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ]),

            const SizedBox(height: 28),

            // ── circular progress ──────────────────────
            Center(
              child: CircularProgressWidget(
                progress: _timeProgress,
                centerText: _daysLeft > 0 ? '$_daysLeft' : '0',
                subText: _daysLeft > 0 ? 'days left' : 'ended',
                progressColor: _progressColor,
                size: 120,
                strokeWidth: 8,
              ),
            ),

            const SizedBox(height: 28),

            // ── prize banner ──────────────────────────
            if (_challenge.prizeCoins > 0)
              Container(
                margin: const EdgeInsets.fromLTRB(
                  20, 0, 20, 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFFB800)
                        .withValues(alpha: 0.15),
                      const Color(0xFFFF6B35)
                        .withValues(alpha: 0.1),
                    ]),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFFFB800)
                      .withValues(alpha: 0.5))),
                child: Row(
                  children: [
                    const Text('🏆',
                      style: TextStyle(fontSize: 32)),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment:
                        CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Winner Prize',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Color(0xFF848A94),
                            fontSize: 11)),
                        Text(
                          '🪙 ${_challenge.prizeCoins} Coins',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            color: Color(0xFFFFB800),
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                        const Text(
                          'Awarded to #1 on leaderboard',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Color(0xFF848A94),
                            fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ),

            // ── stats row ─────────────────────────────
            Row(children: [
              Expanded(
                child: _StatCard(
                  label: 'Participants',
                  value: '${_challenge.participantIds.length}',
                  color: AppColors.primaryLight,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: 'Your XP',
                  value: myEntry != null ? '${myEntry.xp}' : '—',
                  color: _liveGreen,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: 'Your Rank',
                  value: myRank != null ? '#$myRank' : '—',
                  color: AppColors.warning,
                ),
              ),
            ]),

            const SizedBox(height: 20),

            // ── join / joined ─────────────────────────
            if (!isJoined && _challenge.isActive)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: () => _join(context),
                  child: const Text(
                    'Join Challenge',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
            else if (isJoined)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: _liveGreen.withOpacity(0.3), width: 0.5),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: _liveGreen, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Joined ✓',
                      style: TextStyle(
                        color: _liveGreen,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 28),

            // ── leaderboard ───────────────────────────
            Row(children: [
              const Text(
                'Leaderboard',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_challenge.isActive) ...[
                const SizedBox(width: 8),
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                      color: _liveGreen, shape: BoxShape.circle),
                ),
              ],
            ]),
            const SizedBox(height: 10),

            if (leaderboard.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: const Text(
                  'No participants yet. Be the first!',
                  style: TextStyle(
                      color: AppColors.textMuted, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Column(
                  children: leaderboard.asMap().entries.map((e) {
                    final rank = e.key + 1;
                    final entry = e.value;
                    final isMe = entry.userId == _user.id;
                    final isLast = e.key == leaderboard.length - 1;

                    final rankColor = rank == 1
                        ? _gold
                        : rank == 2
                            ? _silver
                            : rank == 3
                                ? _bronze
                                : AppColors.textMuted;

                    final medalEmoji = rank == 1
                        ? '🥇'
                        : rank == 2
                            ? '🥈'
                            : rank == 3
                                ? '🥉'
                                : null;

                    final rowBg = rank == 1
                        ? _gold.withOpacity(0.06)
                        : rank == 2
                            ? _silver.withOpacity(0.05)
                            : rank == 3
                                ? _bronze.withOpacity(0.05)
                                : isMe
                                    ? const Color(0xFF1E1035)
                                    : Colors.transparent;

                    return Container(
                      decoration: BoxDecoration(
                        color: rowBg,
                        border: isMe
                            ? const Border(
                                left: BorderSide(
                                    color: AppColors.primary, width: 2))
                            : null,
                        borderRadius: isLast
                            ? const BorderRadius.only(
                                bottomLeft: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              )
                            : rank == 1
                                ? const BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    topRight: Radius.circular(12),
                                  )
                                : null,
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            child: Row(children: [
                              SizedBox(
                                width: 24,
                                child: medalEmoji != null
                                    ? Text(medalEmoji,
                                        style: const TextStyle(fontSize: 16))
                                    : Text(
                                        '$rank',
                                        style: TextStyle(
                                          color: rankColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 8),
                              _LeaderboardAvatar(
                                  name: entry.userName, index: e.key),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  entry.userName + (isMe ? ' (you)' : ''),
                                  style: TextStyle(
                                    color: isMe
                                        ? AppColors.primaryLight
                                        : AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Text(
                                '${entry.xp} XP',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ]),
                          ),
                          if (!isLast)
                            const Divider(
                                color: AppColors.border, height: 1,
                                indent: 14, endIndent: 14),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: 28),

            // ── participants ──────────────────────────
            const Text(
              'Participants',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildParticipants(leaderboard),

            const SizedBox(height: 28),

            // ── activity feed ─────────────────────────
            Row(children: [
              const Text(
                'Live Activity',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                    color: _liveGreen, shape: BoxShape.circle),
              ),
            ]),
            const SizedBox(height: 10),
            Consumer<ChallengeProvider>(
              builder: (_, cp, __) {
                final activities = cp.activitiesFor(_challenge.id);
                if (activities.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.border, width: 0.5),
                    ),
                    child: const Text(
                      'No activity yet. Complete tasks to appear here!',
                      style: TextStyle(
                          color: AppColors.textMuted, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.border, width: 0.5),
                  ),
                  child: Column(
                    children: activities.asMap().entries.map((e) {
                      final act = e.value;
                      final isLast = e.key == activities.length - 1;
                      final minutesAgo = DateTime.now()
                          .difference(act.timestamp)
                          .inMinutes;
                      final timeLabel = minutesAgo < 1
                          ? 'just now'
                          : minutesAgo < 60
                              ? '${minutesAgo}m ago'
                              : '${minutesAgo ~/ 60}h ago';

                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            child: Row(children: [
                              const Text('⚡',
                                  style: TextStyle(fontSize: 14)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 13),
                                    children: [
                                      TextSpan(
                                        text: act.userName,
                                        style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontWeight:
                                                FontWeight.w600),
                                      ),
                                      const TextSpan(
                                        text: ' completed ',
                                        style: TextStyle(
                                            color:
                                                AppColors.textSecondary),
                                      ),
                                      TextSpan(
                                        text: '"${act.taskTitle}"',
                                        style: const TextStyle(
                                            color:
                                                AppColors.textPrimary),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '+${act.xpEarned} XP',
                                    style: const TextStyle(
                                      color: _liveGreen,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    timeLabel,
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ]),
                          ),
                          if (!isLast)
                            const Divider(
                                color: AppColors.border,
                                height: 1,
                                indent: 14,
                                endIndent: 14),
                        ],
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipants(List<LeaderboardEntry> leaderboard) {
    if (leaderboard.isEmpty) {
      return const Text(
        'No participants yet.',
        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
      );
    }

    final visible = leaderboard.take(10).toList();
    final extra = leaderboard.length - visible.length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...visible.asMap().entries.map((e) {
            final entry = e.value;
            final initial =
                entry.userName.isNotEmpty ? entry.userName[0].toUpperCase() : '?';
            const avatarColors = [
              Color(0xFF7C3AED),
              Color(0xFF22C55E),
              Color(0xFFF59E0B),
              Color(0xFFEF4444),
              Color(0xFF60A5FA),
            ];
            final color = avatarColors[e.key % avatarColors.length];

            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: entry.userId == _user.id
                            ? AppColors.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 40,
                    child: Text(
                      entry.userName.split(' ').first,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 9,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }),
          if (extra > 0)
            Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFF444455),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '+$extra',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const SizedBox(
                  width: 40,
                  child: Text(
                    'more',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 9),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ── sub-widgets ───────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _LeaderboardAvatar extends StatelessWidget {
  final String name;
  final int index;

  const _LeaderboardAvatar({required this.name, required this.index});

  static const _colors = [
    Color(0xFF7C3AED),
    Color(0xFF22C55E),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF60A5FA),
  ];

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final color = _colors[index % _colors.length];

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
