import 'package:flutter/material.dart';

class AnimatedGridCard extends StatefulWidget {
  final Widget child;
  final int index;

  const AnimatedGridCard({
    super.key,
    required this.child,
    required this.index,
  });

  @override
  State<AnimatedGridCard> createState() => _AnimatedGridCardState();
}

class _AnimatedGridCardState extends State<AnimatedGridCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> fadeAnim;
  late final Animation<Offset> slideAnim;
  late final Animation<double> scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    final delay = Duration(milliseconds: 80 * (widget.index % 6));
    if (delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnim,
      child: SlideTransition(
        position: slideAnim,
        child: ScaleTransition(
          scale: scaleAnim,
          child: widget.child,
        ),
      ),
    );
  }
}
