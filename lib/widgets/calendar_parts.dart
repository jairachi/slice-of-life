import 'package:flutter/material.dart';
import '../core/palette.dart';

/// Big solid orange circle with a ring around it, drawn behind calendars (like the circle in the
/// Persona calendar screen). Sizes follow the space it is given.
class CalendarBackdrop extends StatelessWidget {
  const CalendarBackdrop({super.key});
  @override
  Widget build(BuildContext context) =>
      const CustomPaint(painter: _BackdropPainter(), size: Size.infinite);
}

class _BackdropPainter extends CustomPainter {
  const _BackdropPainter();
  @override
  void paint(Canvas canvas, Size size) {
    // sized against the whole panel; the circle reaches up behind the header tab
    final center = Offset(size.width * 0.5, size.height * 0.34);
    final radius = size.width * 0.6;
    canvas.drawCircle(
        center, radius, Paint()..color = lightOrange.withOpacity(0.6));
    canvas.drawCircle(
      center,
      radius + 22,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..color = lightOrange.withOpacity(0.9),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Small coral triangle that marks today in a calendar cell.
class TodayTriangle extends StatelessWidget {
  const TodayTriangle({super.key});
  @override
  Widget build(BuildContext context) =>
      const CustomPaint(size: Size(15, 15), painter: _TrianglePainter());
}

class _TrianglePainter extends CustomPainter {
  const _TrianglePainter();
  @override
  void paint(Canvas canvas, Size s) => canvas.drawPath(
      Path()
        ..moveTo(0, s.height)
        ..lineTo(s.width, s.height)
        ..lineTo(0, 0)
        ..close(),
      Paint()..color = coral);
  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}
