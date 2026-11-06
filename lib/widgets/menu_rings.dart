import 'package:flutter/material.dart';
import '../core/palette.dart';

/// Rings that expand out of the menu button when the dock opens and shrink back into it when it
/// closes. [progress] is the dock animation (0 = closed, 1 = open); the same controller drives
/// the menu items, so everything opens and closes together.
class MenuRingsPainter extends CustomPainter {
  final Animation<double> progress;
  MenuRingsPainter(this.progress) : super(repaint: progress);

  // final radius, colour and thickness of each ring (the button's radius is 28)
  static const _rings = [
    (radius: 76.0, color: coral, width: 12.0),
    (radius: 118.0, color: lightOrange, width: 10.5),
    (radius: 164.0, color: cream, width: 9.0),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final v = progress.value;
    if (v <= 0) return;
    const buttonRadius = 28.0;
    const center =
        Offset(buttonRadius, buttonRadius); // centre of the round button
    for (var i = 0; i < _rings.length; i++) {
      final ring = _rings[i];
      // each ring starts a little after the previous one, so they ripple outwards
      final delay = i * 0.12;
      final t = Curves.easeOutCubic
          .transform(((v - delay) / (1 - delay)).clamp(0.0, 1.0));
      if (t <= 0) continue;
      canvas.drawCircle(
        center,
        buttonRadius + (ring.radius - buttonRadius) * t,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = ring.width
          ..color = ring.color.withOpacity(0.75 * t),
      );
    }
  }

  @override
  bool shouldRepaint(covariant MenuRingsPainter old) =>
      old.progress != progress;
}
