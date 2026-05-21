import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/team_provider.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _name = TextEditingController();
  final bool _isLogin = true;
  bool _googleLoading = false;
  bool _loading = false;

  late final AnimationController _anim;

  late final Animation<Offset> _headerSlide;
  late final Animation<double>  _headerFade;

  late final Animation<Offset> _emailSlide;
  late final Animation<double>  _emailFade;

  late final Animation<Offset> _passSlide;
  late final Animation<double>  _passFade;

  late final Animation<Offset> _btnSlide;
  late final Animation<double>  _btnFade;

  late final Animation<Offset> _googleSlide;
  late final Animation<double>  _googleFade;

  // Compiled once — never recreated during build
  static final _emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

  @override
  void initState() {
    super.initState();

    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );

    Animation<Offset> slide(double s, double e) =>
      Tween<Offset>(
        begin: const Offset(0, 0.45),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _anim,
        curve: Interval(s, e, curve: Curves.easeOut),
      ));

    Animation<double> fade(double s, double e) =>
      Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(
          parent: _anim,
          curve: Interval(s, e, curve: Curves.easeOut),
        ));

    _headerSlide = slide(0.00, 0.40);
    _headerFade  = fade(0.00, 0.40);

    _emailSlide  = slide(0.15, 0.55);
    _emailFade   = fade(0.15, 0.55);

    _passSlide   = slide(0.30, 0.70);
    _passFade    = fade(0.30, 0.70);

    _btnSlide    = slide(0.45, 0.85);
    _btnFade     = fade(0.45, 0.85);

    _googleSlide = slide(0.55, 0.95);
    _googleFade  = fade(0.55, 0.95);

    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Widget _animated(
    Animation<Offset> slide,
    Animation<double> fade,
    Widget child,
  ) {
    return SlideTransition(
      position: slide,
      child: FadeTransition(
        opacity: fade,
        child: child,
      ),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)),
      backgroundColor: const Color(0xFFEF4444),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 3),
    ));
  }

  Future<void> _submit() async {
    context.read<TeamProvider>().clearTeamData();

    final email = _email.text.trim();
    final pass = _pass.text.trim();

    if (email.isEmpty) {
      _showError('Email is required');
      return;
    }
    if (!_emailRegex.hasMatch(email)) {
      _showError('Enter a valid email address');
      return;
    }
    if (pass.isEmpty) {
      _showError('Password is required');
      return;
    }
    if (pass.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }

    try {
      final auth = context.read<AuthProvider>();
      final ok = _isLogin
          ? await auth.signIn(email, pass)
          : await auth.signUp(
              email,
              pass,
              _name.text.trim().isEmpty
                  ? email.split('@').first
                  : _name.text.trim(),
            );
      if (!mounted) return;
      if (!ok) {
        _showError(auth.error ?? 'Something went wrong');
      }
      // AppEntry handles navigation automatically via context.watch
    } catch (e) {
      if (mounted) _showError('Sign in failed. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      } else {
        _loading = false;
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _googleLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      final ok = await auth.signInWithGoogle();
      if (mounted) {
        setState(() {
          _googleLoading = false;
          _loading = false;
        });
      }
      if (!mounted) return;
      if (!ok && auth.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.error!,
              style: const TextStyle(fontFamily: 'Poppins')),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating));
      }
      // NO Navigator.push here
      // AppEntry watches AuthProvider and navigates automatically
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign in failed: $e'),
            backgroundColor: const Color(0xFFEF4444)));
      }
    } finally {
      if (mounted) {
        setState(() => _googleLoading = false);
      } else {
        _googleLoading = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.isAuthenticated) {
      // Auth succeeded but parent AppEntry hasn't rebuilt yet.
      // Force a microtask to let parent rebuild.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
    final bool loading = auth.loading || _loading;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0C16),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // --- TOP BAR ---
              Stack(
                children: [
                  // Decorative dots at top-right
                  Positioned(
                    right: 0,
                    top: 0,
                    child: SizedBox(
                      width: 60,
                      height: 42,
                      child: Stack(
                        children: [
                          Positioned(
                            right: 0,
                            top: 8,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFD700),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 18,
                            top: 2,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF3580FF),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 6,
                            top: 26,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF6B9D),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Row: back button + title
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFF191D30),
                            borderRadius: BorderRadius.circular(21),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Sign In',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 42),
                    ],
                  ),
                ],
              ),

              // --- TITLE SECTION (header animation) ---
              const SizedBox(height: 82),
              _animated(
                _headerSlide,
                _headerFade,
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome Back',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    SizedBox(
                      width: 249,
                      child: Text(
                        'Please enter your email address and password for Login',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF868D95),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // --- EMAIL FIELD (email animation) ---
              const SizedBox(height: 56),
              _animated(
                _emailSlide,
                _emailFade,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Email',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF848A94),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0C16),
                        border: Border.all(
                            color: const Color(0xFF3580FF), width: 1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          color: Colors.white,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Enter your email',
                          hintStyle: TextStyle(
                            color: Color(0xFF848A94),
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // --- PASSWORD FIELD (pass animation) ---
              const SizedBox(height: 16),
              _animated(
                _passSlide,
                _passFade,
                Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0C16),
                    border: Border.all(
                        color: const Color(0xFF191D30), width: 1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextField(
                    controller: _pass,
                    obscureText: true,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      color: Colors.white,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Enter your password',
                      hintStyle: TextStyle(
                        color: Color(0xFF848A94),
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 20, vertical: 20),
                    ),
                  ),
                ),
              ),

              // --- FORGOT PASSWORD ---
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Forgot Password?',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),

              // --- SIGN IN BUTTON (btn animation) ---
              const SizedBox(height: 24),
              _animated(
                _btnSlide,
                _btnFade,
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3580FF),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: loading
                        ? const CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2)
                        : const Text(
                            'Sign In',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),

              // --- SOCIAL LOGIN SECTION ---
              const SizedBox(height: 32),
              Row(children: [
                Expanded(child: Container(
                  height: 1, color: const Color(0xFF191D30))),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Text('OR',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Color(0xFF848A94),
                      letterSpacing: 1))),
                Expanded(child: Container(
                  height: 1, color: const Color(0xFF191D30))),
              ]),
              const SizedBox(height: 16),

              // --- GOOGLE BUTTON (google animation) ---
              _animated(
                _googleSlide,
                _googleFade,
                GestureDetector(
                  onTap: _googleLoading ? null : _signInWithGoogle,
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0C16),
                      border: Border.all(
                        color: const Color(0xFF191D30), width: 1.5),
                      borderRadius: BorderRadius.circular(14)),
                    child: _googleLoading
                      ? const Center(child: SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF3580FF))))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 24, height: 24,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white),
                              child: const Center(
                                child: Text('G',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF4285F4))))),
                            const SizedBox(width: 10),
                            const Text('Continue with Google',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white)),
                          ]),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Apple Sign-In coming soon on iOS',
                        style: TextStyle(fontFamily: 'Poppins')),
                      backgroundColor: Color(0xFF191D30),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.all(Radius.circular(10)))));
                },
                child: Opacity(
                  opacity: 0.4,
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0C16),
                      border: Border.all(
                        color: const Color(0xFF191D30), width: 1.5),
                      borderRadius: BorderRadius.circular(14)),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.apple,
                          color: Colors.white, size: 22),
                        SizedBox(width: 10),
                        Text('Continue with Apple',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white)),
                        SizedBox(width: 8),
                        Text('(iOS only)',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: Color(0xFF848A94))),
                      ])),
                ),
              ),

              // --- BOTTOM LINK ---
              const SizedBox(height: 40),
              Center(
                child: RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Not Registered Yet? ',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      TextSpan(
                        text: 'Sign Up',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3580FF),
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const RegisterScreen()),
                            );
                          },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
