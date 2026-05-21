import 'package:flutter/material.dart';

/// Wraps any widget with staggered
/// fade + slide + scale entrance animation.
/// index controls the delay offset.
class AnimatedCard extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delay;

  const AnimatedCard({
    super.key,
    required this.child,
    required this.index,
    this.delay = const Duration(milliseconds: 70),
  });

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {

  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );

    _fade = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(
          parent: _ctrl,
          curve: Curves.easeOut,
        ));

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.22),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOut,
    ));

    _scale = Tween<double>(begin: 0.90, end: 1.0)
        .animate(CurvedAnimation(
          parent: _ctrl,
          curve: Curves.easeOut,
        ));

    // Stagger: cap at 6 so long lists don't wait forever
    final stagger = widget.index.clamp(0, 6);
    Future.delayed(widget.delay * stagger, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _ctrl,
        child: widget.child,
        builder: (_, child) => FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: ScaleTransition(
              scale: _scale,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
