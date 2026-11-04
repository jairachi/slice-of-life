import 'package:flutter/material.dart';
import '../core/palette.dart';
import '../core/shapes.dart';

/// Slanted button with an offset shadow slab.
class SlantButton extends StatelessWidget {
  final String label;
  final Color color, textColor, shadow;
  final VoidCallback onTap;
  const SlantButton(
      {required this.label,
      required this.color,
      required this.textColor,
      required this.shadow,
      required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(right: 5, bottom: 5),
          child: Stack(children: [
            Positioned.fill(
              child: Transform.translate(
                  offset: const Offset(5, 5),
                  child: ClipPath(
                      clipper: const Para(10),
                      child: ColoredBox(color: shadow))),
            ),
            ClipPath(
              clipper: const Para(10),
              child: Container(
                color: color,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 15),
                child: Text(label.toUpperCase(),
                    style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 1)),
              ),
            ),
          ]),
        ),
      );
}

/// Slanted category chip (filter bar + weekday picker): offset shadow slab like the panels.
class SlantChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color off;
  final Widget? trailing;
  final double pad, gap;
  const SlantChip(
      {required this.label,
      required this.selected,
      required this.onTap,
      this.off = cream,
      this.trailing,
      this.pad = 18,
      this.gap = 9});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.only(right: gap, bottom: 5),
          child: Stack(children: [
            Positioned.fill(
              child: Transform.translate(
                  offset: const Offset(4, 4),
                  child: ClipPath(
                      clipper: const Para(8),
                      child: ColoredBox(color: selected ? cocoa : peach))),
            ),
            ClipPath(
              clipper: const Para(8),
              child: Container(
                color: selected ? coral : off,
                padding: EdgeInsets.fromLTRB(pad, 10, pad, 10),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(label.toUpperCase(),
                      style: pixel(12, selected ? cream : coral,
                          height: 1.2, weight: FontWeight.w700)),
                  if (trailing != null) ...[
                    const SizedBox(width: 4),
                    trailing!
                  ],
                ]),
              ),
            ),
          ]),
        ),
      );
}

/// Round arrow button with an offset shadow (same look as the menu buttons).
class ArrowBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const ArrowBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 50,
          height: 50,
          child: Stack(children: [
            Positioned(
                left: 4,
                top: 4,
                child: Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                        color: cocoa, shape: BoxShape.circle))),
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: coral,
                  shape: BoxShape.circle,
                  border: Border.all(color: cocoa, width: 2)),
              child: Icon(icon, color: cream, size: 30),
            ),
          ]),
        ),
      );
}
