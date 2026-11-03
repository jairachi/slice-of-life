import 'package:flutter/material.dart';
import '../core/palette.dart';
import '../core/shapes.dart';
import '../widgets/slant_widgets.dart';

/// Level-up popup styled like the rest of the app (slanted panel, coral header tab,
/// offset slab, pixel font).
class LevelUpDialog extends StatelessWidget {
  final int level;
  final String name;
  const LevelUpDialog({super.key, required this.level, required this.name});

  @override
  Widget build(BuildContext context) {
    const slant = 12.0;
    return Dialog(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.only(right: 8, bottom: 8),
        child: Stack(children: [
          // offset peach slab behind the panel
          Positioned.fill(
            child: Transform.translate(
              offset: const Offset(8, 8),
              child: ClipPath(clipper: const Para(slant), child: const ColoredBox(color: peach)),
            ),
          ),
          ClipPath(
            clipper: const Para(slant),
            child: Container(
              color: cocoa,
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                // coral header tab with diagonal edge
                Row(children: [
                  Expanded(
                    child: ClipPath(
                      clipper: const HeaderClip(),
                      child: Container(
                        color: coral,
                        padding: const EdgeInsets.fromLTRB(slant + 18, 14, 34, 14),
                        child: Text('LEVEL UP!', style: pixel(26, cream, weight: FontWeight.w700)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                ]),
                Padding(
                  padding: const EdgeInsets.fromLTRB(slant + 22, 20, slant + 22, 4),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(name.toUpperCase(), style: const TextStyle(color: peach, fontSize: 16, fontWeight: FontWeight.w800, fontStyle: FontStyle.italic, letterSpacing: 1)),
                    const SizedBox(height: 6),
                    Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('LV', style: pixel(28, cream, height: 1.5, weight: FontWeight.w700)),
                      const SizedBox(width: 10),
                      Text('$level', style: pixel(76, sun, height: 1)),
                    ]),
                    const SizedBox(height: 10),
                    const Text('Your character just leveled up. Keep it going!', style: TextStyle(color: cream, fontSize: 14, height: 1.4)),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(slant + 22, 20, slant + 22, 22),
                  child: SlantButton(label: 'Continue', color: coral, textColor: cream, shadow: peach, onTap: () => Navigator.pop(context)),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
