import 'package:flutter/material.dart';
import 'root_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  late final AnimationController _enterCtrl;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _subtitleFade;
  late final Animation<Offset> _subtitleSlide;

  late final AnimationController _glowCtrl;
  late final Animation<double> _glowAnim;

  late final AnimationController _lineCtrl;
  late final Animation<double> _lineWidth;

  static const _bgColor = Color(0xFF060C1A);
  static const _primaryBlue = Color(0xFF4A7FE5);
  static const _glowBlue = Color(0xFF6B9FFF);

  @override
  void initState() {
    super.initState();

    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _enterCtrl,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
      ),
    );

    _logoScale = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(
        parent: _enterCtrl,
        curve: const Interval(0.0, 0.60, curve: Curves.elasticOut),
      ),
    );

    _subtitleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _enterCtrl,
        curve: const Interval(0.45, 0.85, curve: Curves.easeOut),
      ),
    );

    _subtitleSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _enterCtrl,
        curve: const Interval(0.45, 0.85, curve: Curves.easeOut),
      ),
    );

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _glowAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _glowCtrl,
        curve: Curves.easeInOut,
      ),
    );

    _lineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _lineWidth = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _lineCtrl,
        curve: Curves.easeOut,
      ),
    );

    _enterCtrl.forward().then((_) {
      _glowCtrl.repeat(reverse: true);
      _lineCtrl.forward();
    });

    Future.delayed(const Duration(milliseconds: 2800), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (_, anim, __) => FadeTransition(
            opacity: anim,
            child: const RootScreen(),
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    _glowCtrl.dispose();
    _lineCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([_enterCtrl, _glowCtrl, _lineCtrl]),
          builder: (_, __) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeTransition(
                  opacity: _logoFade,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: RepaintBoundary(
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: _glowBlue.withValues(
                                  alpha: 0.25 * _glowAnim.value),
                              blurRadius: 60 * _glowAnim.value,
                              spreadRadius: 10 * _glowAnim.value,
                            ),
                          ],
                        ),
                        child: ShaderMask(
                          shaderCallback: (bounds) =>
                              const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFFB8CEFF),
                                  Color(0xFF6B9FFF),
                                  Color(0xFF3A6FE5),
                                ],
                              ).createShader(bounds),
                          child: const Text(
                            'AOX',
                            style: TextStyle(
                              fontSize: 88,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 12,
                              color: Colors.white,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                FadeTransition(
                  opacity: _subtitleFade,
                  child: SlideTransition(
                    position: _subtitleSlide,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRect(
                          child: Align(
                            alignment: Alignment.centerRight,
                            widthFactor: _lineWidth.value,
                            child: Container(
                              width: 48,
                              height: 1.5,
                              color: _primaryBlue.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'TASKS.  LEVEL UP.  REPEAT.',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 3.5,
                            color: _primaryBlue.withValues(alpha: 0.85),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ClipRect(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            widthFactor: _lineWidth.value,
                            child: Container(
                              width: 48,
                              height: 1.5,
                              color: _primaryBlue.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
