import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/team_provider.dart';
import 'login_screen.dart';
import 'team_setup_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  const EmailVerificationScreen({super.key, required this.email});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends State<EmailVerificationScreen> {
  // Timers stored as fields — always cancelled in dispose()
  Timer? _pollTimer;
  Timer? _cdTimer;
  int _cd = 60;
  bool _canResend = false;
  bool _verified = false;

  static const _titleStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
  static const _subStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14,
    color: Color(0xFF848A94),
    height: 1.6,
  );

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _cdTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _cdTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_cd <= 1) {
        t.cancel();
        if (mounted) setState(() => _canResend = true);
      } else {
        setState(() => _cd--);
      }
    });
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(
      const Duration(seconds: 4), (_) async {
        if (!mounted) return;
        final auth = context.read<AuthProvider>();
        final verified = await auth.authSvc.checkEmailVerified();
        if (verified && mounted) {
          _pollTimer?.cancel();
          setState(() => _verified = true);
          await Future.delayed(const Duration(milliseconds: 800));
          if (mounted) {
            Navigator.pushReplacement(context,
              MaterialPageRoute(
                builder: (_) => const TeamSetupScreen()));
          }
        }
      });
  }

  Future<void> _resend() async {
    if (!_canResend) return;
    final auth = context.read<AuthProvider>();
    await auth.authSvc.sendVerificationEmail();
    if (!mounted) return;
    setState(() {
      _canResend = false;
      _cd = 60;
    });
    _cdTimer?.cancel();
    _startCountdown();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Verification email sent!',
            style: TextStyle(fontFamily: 'Poppins')),
        backgroundColor: Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _cancel() async {
    _pollTimer?.cancel();
    _cdTimer?.cancel();
    final auth = context.read<AuthProvider>();
    final team = context.read<TeamProvider>();
    await auth.authSvc.deleteCurrentUser();
    // Clear team data first
    team.clearTeamData();
    // Clear auth + SQLite
    await auth.signOut();
    // Navigate to login
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0C16),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(children: [
            const SizedBox(height: 20),

            // ── Top bar ──────────────────────────────────────────
            Row(children: [
              GestureDetector(
                onTap: _cancel,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: Color(0xFF191D30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
              const Expanded(
                child: Text(
                  'Verify Email',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 42),
            ]),

            const Spacer(),

            // ── Icon — animates on verification ──────────────────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Container(
                key: ValueKey(_verified),
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: (_verified
                          ? const Color(0xFF22C55E)
                          : const Color(0xFF3580FF))
                      .withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _verified
                      ? Icons.check_circle_outline_rounded
                      : Icons.mark_email_unread_outlined,
                  color: _verified
                      ? const Color(0xFF22C55E)
                      : const Color(0xFF3580FF),
                  size: 44,
                ),
              ),
            ),

            const SizedBox(height: 24),

            Text(
              _verified ? 'Email Verified! ✅' : 'Check your inbox',
              style: _titleStyle,
            ),

            const SizedBox(height: 10),

            Text(
              _verified
                  ? 'Redirecting you...'
                  : 'We sent a link to:\n${widget.email}',
              textAlign: TextAlign.center,
              style: _subStyle,
            ),

            const SizedBox(height: 28),

            // ── Auto-check status card ────────────────────────────
            if (!_verified)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF191D30),
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                ),
                child: const Row(children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Color(0xFF3580FF),
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Checking automatically every 4 seconds...',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: Color(0xFF848A94),
                      ),
                    ),
                  ),
                ]),
              ),

            const Spacer(),

            // ── Resend button + back link ─────────────────────────
            if (!_verified) ...[
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _canResend ? _resend : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3580FF),
                    disabledBackgroundColor: const Color(0xFF191D30),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text(
                    _canResend
                        ? 'Resend verification email'
                        : 'Resend in ${_cd}s',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: _canResend
                          ? Colors.white
                          : const Color(0xFF848A94),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              TextButton(
                onPressed: _cancel,
                child: const Text(
                  'Wrong email? Go back',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: Color(0xFF848A94),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }
}
