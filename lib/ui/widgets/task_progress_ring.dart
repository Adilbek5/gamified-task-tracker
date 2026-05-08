import 'package:flutter/material.dart';

/// A self-contained circular progress ring with a centred percentage label.
///
/// Uses [Stack(alignment: Alignment.center)] so the text is always centred
/// regardless of screen size. [FittedBox] prevents the label from overflowing
/// when the ring is small. Each layer is bounded by an explicit [SizedBox].
class TaskProgressRing extends StatelessWidget {
  final double progress;   // 0.0 to 1.0
  final Color color;
  final double size;
  final double strokeWidth;

  const TaskProgressRing({
    super.key,
    required this.progress,
    required this.color,
    this.size = 44,
    this.strokeWidth = 3.5,
  });

  double get _safeProgress => progress.clamp(0.0, 1.0);

  String get _label => '${(_safeProgress * 100).round()}%';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background track
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: strokeWidth,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF191D30),
              ),
            ),
          ),
          // Progress arc
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: _safeProgress,
              strokeWidth: strokeWidth,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              strokeCap: StrokeCap.round,
            ),
          ),
          // Label — bounded and scaled; never overflows
          SizedBox(
            width: size - strokeWidth * 2 - 4,
            height: size - strokeWidth * 2 - 4,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: size * 0.22,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.0,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
