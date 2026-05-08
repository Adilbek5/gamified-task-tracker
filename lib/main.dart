import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_colors.dart';
import 'data/database/app_database.dart';
import 'data/repositories/shop_repository.dart';
import 'data/repositories/task_repository.dart';
import 'data/repositories/user_repository.dart';
import 'firebase_options.dart';
import 'providers/activity_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/challenge_provider.dart';
import 'providers/gamification_provider.dart';
import 'providers/shop_provider.dart';
import 'providers/task_provider.dart';
import 'providers/team_provider.dart';
import 'services/activity_service.dart';
import 'services/auth_service.dart';
import 'services/challenge_service.dart';
import 'services/gamification_service.dart';
import 'services/sync_service.dart';
import 'services/team_service.dart';
import 'ui/screens/auth/login_screen.dart';
import 'ui/screens/auth/team_setup_screen.dart';
import 'ui/screens/dashboard/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform);
  await AppDatabase.instance;
  SyncService.instance.startSync();
  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final UserRepository _userRepo;
  late final TaskRepository _taskRepo;
  late final ShopRepository _shopRepo;
  late final AuthService _authSvc;
  late final TeamService _teamSvc;
  late final ChallengeService _challengeSvc;
  late final GamificationService _gamSvc;

  @override
  void initState() {
    super.initState();
    _userRepo = UserRepository();
    _taskRepo = TaskRepository();
    _shopRepo = ShopRepository();
    _authSvc = AuthService();
    _teamSvc = TeamService();
    _challengeSvc = ChallengeService();
    _gamSvc = GamificationService(_userRepo, _taskRepo, _shopRepo);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(_authSvc, _userRepo)),
        ChangeNotifierProvider(
          create: (_) => TaskProvider(_taskRepo)),
        ChangeNotifierProvider(
          create: (_) => TeamProvider(_teamSvc, _userRepo)),
        ChangeNotifierProvider(
          create: (_) => GamificationProvider(_gamSvc, _userRepo)),
        ChangeNotifierProvider(
          create: (_) => ChallengeProvider(_challengeSvc)),
        ChangeNotifierProvider(
          create: (_) => ShopProvider(_shopRepo, _userRepo)),
        ChangeNotifierProvider(
          create: (_) => ActivityProvider(ActivityService())),
        Provider<SyncService>(
          create: (_) => SyncService.instance),
      ],
      child: MaterialApp(
        title: 'Gamified Task Tracker',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: AppColors.background,
          fontFamily: 'Poppins',
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            surface: AppColors.surface),
        ),
        home: const AppEntry(),
      ),
    );
  }
}

class AppEntry extends StatefulWidget {
  const AppEntry({super.key});
  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
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
      debugPrint('[AppEntry] init error: $e');
    } finally {
      if (mounted) setState(() => _initialized = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0C16),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF3580FF))));
    }

    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    if (!auth.isAuthenticated || user == null) {
      return const LoginScreen();
    }

    if (user.hasTeam) {
      return const DashboardScreen();
    }

    return const TeamSetupScreen();
  }
}
