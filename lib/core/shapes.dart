import 'package:flutter/material.dart';

/// Parallelogram clip used for the slanted Persona-style panels.
class Para extends CustomClipper<Path> {
  final double s;
  const Para([this.s = 14]);
  @override
  Path getClip(Size z) => Path()
    ..moveTo(s, 0)
    ..lineTo(z.width, 0)
    ..lineTo(z.width - s, z.height)
    ..lineTo(0, z.height)
    ..close();
  @override
  bool shouldReclip(covariant CustomClipper<Path> o) => false;
}

/// Clips to the area right of a slanted line at [frac] of the width.
class SplitClip extends CustomClipper<Path> {
  final double frac, slant;
  const SplitClip(this.frac, this.slant);
  @override
  Path getClip(Size z) {
    final x = z.width * frac;
    return Path()
      ..moveTo(x + slant, 0)
      ..lineTo(z.width, 0)
      ..lineTo(z.width, z.height)
      ..lineTo(x - slant, z.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> o) => false;
}

/// Header tab: flat left, diagonal cut on the right.
class HeaderClip extends CustomClipper<Path> {
  const HeaderClip();
  @override
  Path getClip(Size z) => Path()
    ..lineTo(z.width, 0)
    ..lineTo(z.width - 22, z.height)
    ..lineTo(0, z.height)
    ..close();
  @override
  bool shouldReclip(covariant CustomClipper<Path> o) => false;
}

/// Corner tag: slanted left edge, flush to the panel's bottom-right.
class TagClip extends CustomClipper<Path> {
  const TagClip();
  @override
  Path getClip(Size z) => Path()
    ..moveTo(z.height, 0)
    ..lineTo(z.width, 0)
    ..lineTo(z.width, z.height)
    ..lineTo(0, z.height)
    ..close();
  @override
  bool shouldReclip(covariant CustomClipper<Path> o) => false;
}
