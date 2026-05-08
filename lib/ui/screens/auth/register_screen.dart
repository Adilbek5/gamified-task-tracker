import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import 'email_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();

  // Compiled once — not recreated on rebuild
  static final _emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(fontFamily: 'Poppins')),
      backgroundColor: const Color(0xFFEF4444),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 3),
    ));
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    final email = _email.text.trim();
    final pass = _pass.text.trim();

    if (name.isEmpty || email.isEmpty || pass.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }
    if (!_emailRegex.hasMatch(email)) {
      _showError('Please enter a valid email address');
      return;
    }
    if (pass.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }

    final auth = context.read<AuthProvider>();
    final ok = await auth.signUp(email, pass, name);
    if (ok && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => EmailVerificationScreen(email: email)),
      );
      return;
    }
    if (!ok && mounted) {
      _showError(auth.error ?? 'Error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final bool loading = auth.loading;

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
                            'Sign Up',
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

              // --- TITLE SECTION ---
              const SizedBox(height: 82),
              const Text(
                'Create Account',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please enter your information and create your account',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF868D95),
                ),
              ),

              // --- NAME FIELD ---
              const SizedBox(height: 56),
              Container(
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0C16),
                  border: Border.all(color: const Color(0xFF3580FF), width: 1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: _name,
                  keyboardType: TextInputType.name,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    color: Colors.white,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Enter your name',
                    hintStyle: TextStyle(
                      color: Color(0xFF848A94),
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  ),
                ),
              ),

              // --- EMAIL FIELD ---
              const SizedBox(height: 16),
              Container(
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0C16),
                  border: Border.all(color: const Color(0xFF191D30), width: 1),
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
                    hintText: 'Enter your mail',
                    hintStyle: TextStyle(
                      color: Color(0xFF848A94),
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  ),
                ),
              ),

              // --- PASSWORD FIELD ---
              const SizedBox(height: 16),
              Container(
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0C16),
                  border: Border.all(color: const Color(0xFF191D30), width: 1),
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
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  ),
                ),
              ),

              // --- SIGN UP BUTTON ---
              const SizedBox(height: 24),
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
                          'Sign Up',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              // --- SOCIAL SECTION ---
              const SizedBox(height: 32),
              const Center(
                child: Text(
                  'Signup With',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: Color(0xFF868D95),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Apple button
                  Container(
                    width: 60,
                    height: 58,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0C16),
                      border: Border.all(color: const Color(0xFF191D30)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.apple,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Google button
                  Container(
                    width: 60,
                    height: 58,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0C16),
                      border: Border.all(color: const Color(0xFF191D30)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text(
                        'G',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3580FF),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // --- BOTTOM LINK ---
              const SizedBox(height: 40),
              Center(
                child: RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Have an Account? ',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      TextSpan(
                        text: 'Sign In',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3580FF),
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => Navigator.pop(context),
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
