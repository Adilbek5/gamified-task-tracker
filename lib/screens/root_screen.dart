import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/team_provider.dart';
import '../ui/screens/auth/login_screen.dart';
import '../ui/screens/auth/team_setup_screen.dart';
import '../ui/screens/dashboard/dashboard_screen.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  Future<void> _initialize() async {
    try {
      final auth = context.read<AuthProvider>();
      await auth.loadUser();
      if (!mounted) return;
      final user = auth.user;
      if (user != null && user.hasTeam) {
        await context.read<TeamProvider>().loadTeam(user);
      }
    } catch (e) {
      debugPrint('[RootScreen] init error: $e');
    } finally {
      if (mounted) setState(() => _initialized = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    debugPrint('[RootScreen] provider hash: ${identityHashCode(auth)}');
    debugPrint('[RootScreen] build — '
        'initialized=$_initialized '
        'isAuth=${auth.isAuthenticated} '
        'hasTeam=${auth.user?.hasTeam}');

    if (!_initialized) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0C16),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF3580FF)),
        ),
      );
    }

    final user = auth.user;

    if (!auth.isAuthenticated || user == null) {
      return const LoginScreen(key: ValueKey('login'));
    }

    if (user.hasTeam) {
      return const DashboardScreen(key: ValueKey('dashboard'));
    }

    return const TeamSetupScreen(key: ValueKey('teamsetup'));
  }
}
