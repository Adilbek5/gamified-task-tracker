import 'package:flutter/material.dart';

/// Wraps a ListTile with slide-from-left
/// + fade entrance animation.
class AnimatedListTile extends StatefulWidget {
  final Widget child;
  final int index;

  const AnimatedListTile({
    super.key,
    required this.child,
    required this.index,
  });

  @override
  State<AnimatedListTile> createState() => _AnimatedListTileState();
}

class _AnimatedListTileState extends State<AnimatedListTile>
    with SingleTickerProviderStateMixin {

  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    // Cap stagger at index 7
    final i = widget.index.clamp(0, 7);
    Future.delayed(Duration(milliseconds: 55 * i), () {
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
          opacity: CurvedAnimation(
            parent: _ctrl,
            curve: Curves.easeOut,
          ),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.10, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _ctrl,
              curve: Curves.easeOut,
            )),
            child: child,
          ),
        ),
      ),
    );
  }
}
