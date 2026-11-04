import 'package:flutter/material.dart';
import '../core/palette.dart';
import '../core/shapes.dart';

/// Small slanted "+50 XP" badge that floats up when a task is ticked ("-50 XP" when undone).
class XpGainPill extends StatelessWidget {
  final int amount;
  const XpGainPill(this.amount, {super.key});

  @override
  Widget build(BuildContext context) {
    final gain = amount >= 0;
    return Padding(
      padding: const EdgeInsets.only(right: 5, bottom: 5),
      child: Stack(children: [
        Positioned.fill(
          child: Transform.translate(
              offset: const Offset(5, 5),
              child: ClipPath(
                  clipper: const Para(10),
                  child: ColoredBox(color: gain ? cocoa : coral))),
        ),
        ClipPath(
          clipper: const Para(10),
          child: Container(
            color: gain ? coral : cocoa,
            padding: const EdgeInsets.fromLTRB(22, 9, 20, 9),
            child: Text('${gain ? '+' : '-'}${amount.abs()} XP',
                style: pixel(16, cream, height: 1.2, weight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }
}
