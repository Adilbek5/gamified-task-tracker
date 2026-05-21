import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../data/database/app_database.dart';
import '../data/models/user_model.dart';
import '../data/repositories/user_repository.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _auth;
  final UserRepository _repo;

  UserModel? _user;
  bool _loading = false;
  String? _error;
  StreamSubscription<User?>? _authSub;

  UserModel? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get hasTeam => _user?.hasTeam ?? false;
  AuthService get authSvc => _auth;

  AuthProvider(this._auth, this._repo) {
    _authSub = FirebaseAuth.instance.authStateChanges().listen(
      (firebaseUser) async {
        debugPrint('[AuthProvider] authStateChanges: '
            '${firebaseUser?.uid}');

        if (firebaseUser == null) {
          if (_user != null) {
            _user = null;
            _error = null;
            _loading = false;
            notifyListeners();
          }
          return;
        }

        if (_user == null || _user!.id != firebaseUser.uid) {
          debugPrint('[AuthProvider] authStateChanges '
              'triggering loadUser for: ${firebaseUser.uid}');
          await loadUser();
        }
      },
    );
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> loadUser() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        _user = null;
        _loading = false;
        notifyListeners();
        return;
      }

      final local = await _repo.getById(firebaseUser.uid);

      if (local != null && local.id == firebaseUser.uid) {
        _user = local;

        debugPrint('[Auth] User loaded: ${_user?.id}');
        debugPrint('[Auth] Team: ${_user?.teamId}');
        debugPrint('[Auth] Role: ${_user?.role.name}');

        // If teamId missing from SQLite, search Firebase
        if (!_user!.hasTeam) {
          await _tryRestoreTeam(firebaseUser.uid);
        }
      } else {
        // No local record — create minimal user from Firebase
        _user = UserModel(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          name: firebaseUser.displayName ??
              firebaseUser.email?.split('@').first ?? 'User',
        );
        await _repo.upsert(_user!);

        debugPrint('[Auth] User loaded: ${_user?.id}');
        debugPrint('[Auth] Team: ${_user?.teamId}');
        debugPrint('[Auth] Role: ${_user?.role.name}');

        // Try to find their team in Firebase
        await _tryRestoreTeam(firebaseUser.uid);
      }
    } catch (e) {
      debugPrint('loadUser error: $e');
      _user = null;
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> _tryRestoreTeam(String userId) async {
    try {
      final db = FirebaseDatabase.instance;

      // STEP 1: Try direct O(1) lookup first
      final directSnap = await db
          .ref('users/$userId/teamId')
          .get()
          .timeout(const Duration(seconds: 5));

      if (directSnap.exists &&
          directSnap.value != null &&
          directSnap.value.toString().isNotEmpty) {
        final teamId = directSnap.value.toString();

        // Verify team still exists
        final teamSnap = await db
            .ref('teams/$teamId/lead_id')
            .get()
            .timeout(const Duration(seconds: 5));

        if (teamSnap.exists) {
          final leadId = teamSnap.value?.toString() ?? '';
          final role = leadId == userId
              ? UserRole.teamLead
              : UserRole.teamMember;

          _user = _user!.copyWith(teamId: teamId, role: role);
          await _repo.upsert(_user!);
          notifyListeners();

          debugPrint('[Auth] Restored team via direct '
              'lookup: $teamId as ${role.name}');
          return;
        }
      }

      // STEP 2: Fallback — scan all teams (old method)
      // This runs only if direct lookup fails
      debugPrint('[Auth] Direct lookup failed, '
          'scanning all teams...');

      final teamsSnap = await db
          .ref('teams')
          .get()
          .timeout(const Duration(seconds: 6));

      if (!teamsSnap.exists || teamsSnap.value == null) {
        debugPrint('[AuthProvider] _tryRestoreTeam: '
            'no teams found');
        return;
      }

      final teams = Map<String, dynamic>.from(
          teamsSnap.value as Map);

      for (final entry in teams.entries) {
        final teamId = entry.key;
        final data = Map<String, dynamic>.from(
            entry.value as Map);

        final leadId = data['lead_id']?.toString() ?? '';
        final memberIds = data['member_ids'];

        bool belongs = leadId == userId;
        if (!belongs && memberIds is List) {
          belongs = memberIds.any(
              (id) => id.toString() == userId);
        }

        if (belongs) {
          final role = leadId == userId
              ? UserRole.teamLead
              : UserRole.teamMember;

          _user = _user!.copyWith(teamId: teamId, role: role);
          await _repo.upsert(_user!);

          // Save for future direct lookups
          await FirebaseDatabase.instance
              .ref('users/$userId/teamId')
              .set(teamId);

          notifyListeners();
          debugPrint('[Auth] Restored team via scan: '
              '$teamId as ${role.name}');
          return;
        }
      }

      debugPrint('[AuthProvider] _tryRestoreTeam: '
          'no team found for $userId');
    } catch (e) {
      debugPrint('[Auth] _tryRestoreTeam error: $e');
    }
  }

  Future<bool> signIn(String email, String password) async {
    _loading = true; _error = null; notifyListeners();
    try {
      final fb = await _auth.signIn(email, password);
      if (fb == null) { _error = 'Sign in failed'; return false; }
      _user = await _repo.getById(fb.uid);
      if (_user == null) {
        _user = UserModel(id: fb.uid, email: email,
            name: email.split('@').first);
        await _repo.upsert(_user!);
      }
      if (!_user!.hasTeam) {
        await _tryRestoreTeam(_user!.id);
      }
      debugPrint('[AuthProvider] signIn teamId: ${_user?.teamId}');
      debugPrint('[AuthProvider] signIn hasTeam: ${_user?.hasTeam}');
      return true;
    } catch (e) { _error = e.toString(); return false; }
    finally { _loading = false; notifyListeners(); }
  }

  Future<bool> signUp(String email, String pass, String name) async {
    _loading = true; _error = null; notifyListeners();
    try {
      final fb = await _auth.signUp(email, pass);
      if (fb == null) { _error = 'Sign up failed'; return false; }
      // Send verification email immediately after account creation
      await _auth.sendVerificationEmail();
      // Save user to local DB
      _user = UserModel(id: fb.uid, email: email, name: name);
      await _repo.upsert(_user!);
      return true;
    } catch (e) { _error = e.toString(); return false; }
    finally { _loading = false; notifyListeners(); }
  }

  Future<bool> signInWithGoogle() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('[AuthProvider] Starting Google Sign-In');

      final credential = await _auth.signInWithGoogle();

      if (credential == null) {
        debugPrint('[AuthProvider] Cancelled by user');
        _loading = false;
        notifyListeners();
        return false;
      }

      final fb = credential.user;
      if (fb == null) {
        _error = 'Sign in failed: no user returned';
        _loading = false;
        notifyListeners();
        return false;
      }

      debugPrint('[AuthProvider] Firebase user: ${fb.uid}');

      // Load or create user record in SQLite
      UserModel? existing = await _repo.getById(fb.uid);

      if (existing == null) {
        existing = UserModel(
          id: fb.uid,
          email: fb.email ?? '',
          name: fb.displayName ??
              fb.email?.split('@').first ?? 'User',
        );
        await _repo.upsert(existing);
        debugPrint('[AuthProvider] New user created in SQLite');
      } else {
        debugPrint('[AuthProvider] Existing user loaded from SQLite');
      }

      _user = existing;
      debugPrint('[Auth] _user set: ${_user?.id}');
      debugPrint('[Auth] _user null? ${_user == null}');

      // Restore team from Firebase if SQLite has no teamId
      if (!_user!.hasTeam) {
        await _tryRestoreTeam(_user!.id);
      }
      debugPrint('[Auth] after restore: ${_user?.teamId}');
      debugPrint('[Auth] _user still set: ${_user?.id}');

      debugPrint('[AuthProvider] teamId after restore: ${_user?.teamId}');
      debugPrint('[AuthProvider] hasTeam: ${_user?.hasTeam}');

      return true;

    } catch (e) {
      debugPrint('[AuthProvider] signInWithGoogle error: $e');
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      debugPrint('[Auth] finally: _user=${_user?.id} loading=$_loading');
      _loading = false;
      notifyListeners();
      debugPrint('[Auth] notifyListeners firing now');
    }
  }

  Future<void> signOut() async {
    try {
      await AppDatabase.clearAllData();
    } catch (_) {}
    try {
      await _auth.signOut();
    } catch (_) {}
    _user = null;
    _error = null;
    _loading = false;
    notifyListeners();
  }

  Future<bool> leaveTeam() async {
    if (_user == null) return false;

    final teamId = _user!.teamId;
    final userId = _user!.id;

    try {
      final db = FirebaseDatabase.instance;

      await db
          .ref('users/$userId/teamId')
          .remove();

      if (teamId != null && teamId.isNotEmpty) {
        final memberRef = db.ref('teams/$teamId/member_ids');
        final snap = await memberRef
            .get()
            .timeout(const Duration(seconds: 5));

        if (snap.exists && snap.value != null) {
          final raw = snap.value;
          final ids = raw is List
              ? List<dynamic>.from(raw)
              : List<dynamic>.from((raw as Map).values);
          ids.removeWhere(
              (id) => id.toString() == userId);
          await memberRef.set(ids);
          debugPrint('[Auth] Removed user '
              'from team member_ids');
        }
      }

      final updated = _user!.copyWith(
        teamId: '',
        role: UserRole.teamMember,
      );
      await _repo.upsert(updated);
      _user = updated;
      _error = null;
      debugPrint('[AuthProvider] Left team successfully');
      debugPrint('[AuthProvider] hasTeam: ${_user?.hasTeam}');
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[AuthProvider] leaveTeam error: $e');
      return false;
    }
  }

  void refresh(UserModel u) { _user = u; notifyListeners(); }
}