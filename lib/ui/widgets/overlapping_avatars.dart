import 'package:flutter/material.dart';

class OverlappingAvatars extends StatelessWidget {
  final List<String> labels;
  final double size;
  final double overlap;
  final int maxVisible;

  const OverlappingAvatars({
    super.key,
    required this.labels,
    this.size = 28,
    this.overlap = 8,
    this.maxVisible = 3,
  });

  static const _colors = [
    Color(0xFF7C3AED),
    Color(0xFF22C55E),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF60A5FA),
  ];

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) return const SizedBox.shrink();

    final visible = labels.take(maxVisible).toList();
    final extra = labels.length - visible.length;
    final itemCount = visible.length + (extra > 0 ? 1 : 0);
    final totalWidth = itemCount * (size - overlap) + overlap;

    return SizedBox(
      width: totalWidth,
      height: size,
      child: Stack(
        children: [
          ...visible.asMap().entries.map((e) => Positioned(
                left: e.key * (size - overlap),
                child: _AvatarCircle(
                  label: e.value,
                  color: _colors[e.key % _colors.length],
                  size: size,
                ),
              )),
          if (extra > 0)
            Positioned(
              left: visible.length * (size - overlap),
              child: _AvatarCircle(
                label: '+$extra',
                color: const Color(0xFF444455),
                size: size,
              ),
            ),
        ],
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  final String label;
  final Color color;
  final double size;

  const _AvatarCircle({
    required this.label,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF13131F), width: 1.5),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: label.length == 1 ? size * 0.42 : size * 0.32,
            color: Colors.white,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}
