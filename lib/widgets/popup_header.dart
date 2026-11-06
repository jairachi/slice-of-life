import 'package:flutter/material.dart';
import '../core/palette.dart';
import '../core/shapes.dart';

/// How far the header tab sticks out above the top edge of the panel.
const double kHeaderLift = 16;

/// Height of the header tab.
const double kHeaderHeight = 52;

/// Room the panel's content must leave at its top for the part of the tab that overlaps it.
const double kHeaderSpace = kHeaderHeight - kHeaderLift + 12;

/// A popup panel whose header tab looks pulled away from it: the tab is its own slanted piece
/// with its own offset shadow, shifted up and to the right so it sticks out above the panel's top
/// edge, while most of it still rests on the panel. The close button sits inside the panel.
///
/// Put `SizedBox(height: kHeaderSpace)` at the top of the panel's content so nothing hides
/// behind the tab.
class HeaderPanel extends StatelessWidget {
  final String title;
  final double titleSize;
  final Color headerColor, shadowColor, closeColor;
  final VoidCallback? onClose;
  final StackFit fit;
  final Widget panel;

  const HeaderPanel({
    super.key,
    required this.title,
    required this.panel,
    this.titleSize = 24,
    this.headerColor = coral,
    this.shadowColor = cocoa,
    this.closeColor = cocoa,
    this.onClose,
    this.fit = StackFit.loose,
  });

  @override
  Widget build(BuildContext context) =>
      Stack(fit: fit, clipBehavior: Clip.none, children: [
        Padding(padding: const EdgeInsets.only(top: kHeaderLift), child: panel),
        // the tab: up and to the right of where a flush header would sit
        Positioned(
          left: -14,
          right: 64,
          top: 0,
          child: Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: _HeaderTab(
                  title: title,
                  size: titleSize,
                  color: headerColor,
                  shadow: shadowColor),
            ),
          ),
        ),
        if (onClose != null)
          Positioned(
            right: 8,
            top: kHeaderLift + 4,
            child: IconButton(
                icon: Icon(Icons.close, color: closeColor, size: 28),
                onPressed: onClose),
          ),
      ]);
}

class _HeaderTab extends StatelessWidget {
  final String title;
  final double size;
  final Color color, shadow;
  const _HeaderTab(
      {required this.title,
      required this.size,
      required this.color,
      required this.shadow});

  @override
  Widget build(BuildContext context) => Padding(
        padding:
            const EdgeInsets.only(right: 6, bottom: 6), // room for the shadow
        child: Stack(clipBehavior: Clip.none, children: [
          Positioned.fill(
            child: Transform.translate(
                offset: const Offset(6, 6),
                child: ClipPath(
                    clipper: const Para(14), child: ColoredBox(color: shadow))),
          ),
          ClipPath(
            clipper: const Para(14),
            child: Container(
              height: kHeaderHeight,
              color: color,
              padding: const EdgeInsets.fromLTRB(32, 0, 34, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                widthFactor: 1,
                child: Text(title,
                    style: pixel(size, cream, weight: FontWeight.w700)),
              ),
            ),
          ),
        ]),
      );
}
