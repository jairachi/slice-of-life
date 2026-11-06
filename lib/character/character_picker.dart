import 'package:flutter/material.dart';
import '../widgets/popup_header.dart';
import '../core/palette.dart';
import '../core/shapes.dart';
import '../widgets/slant_widgets.dart';
import 'character_art.dart';

/// Stardew-style persona picker in the app's popup style: one option at a time, circular
/// arrows on each side that loop through all nine, slanted panel with a coral header tab.
class CharacterPicker extends StatefulWidget {
  final String current;
  const CharacterPicker({super.key, required this.current});
  @override
  State<CharacterPicker> createState() => _CharacterPickerState();
}

class _CharacterPickerState extends State<CharacterPicker> {
  static final List<String> _ids = [
    for (final g in characterGroups.values)
      for (var n = 1; n <= 3; n++) '${g}_$n',
  ];
  late int index = _ids.contains(widget.current) ? _ids.indexOf(widget.current) : 0;

  int _dir = 1; // 1 = moving right (new figure enters from the right), -1 = left

  void _move(int d) => setState(() {
        _dir = d;
        index = (index + d + _ids.length) % _ids.length; // loops around
      });

  @override
  Widget build(BuildContext context) {
    const slant = 12.0;
    final id = _ids[index];
    return Dialog(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.only(right: 8, bottom: 8),
        child: HeaderPanel(title: 'CHOOSE YOUR PERSONA', titleSize: 20, headerColor: coral, shadowColor: cocoa, onClose: () => Navigator.pop(context), panel: SizedBox(
          width: double.infinity,
          child: Stack(children: [
            Positioned.fill(
              child: Transform.translate(offset: const Offset(8, 8), child: ClipPath(clipper: const Para(slant), child: const ColoredBox(color: cocoa))),
            ),
            ClipPath(
              clipper: const Para(slant),
              child: Container(
                color: cream,
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    const SizedBox(height: kHeaderSpace),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(slant + 10, 20, slant + 10, 6),
                      child: Row(children: [
                        ArrowBtn(icon: Icons.chevron_left, onTap: () => _move(-1)),
                        Expanded(
                          child: SizedBox(
                            height: 260,
                            child: ClipRect(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 350),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeInCubic,
                                // new figure slides in from the arrow's side while the old one slides out the other way
                                transitionBuilder: (child, anim) {
                                  final incoming = child.key == ValueKey(id);
                                  final from = incoming ? _dir.toDouble() : -_dir.toDouble();
                                  return SlideTransition(
                                    position: Tween<Offset>(begin: Offset(from, 0), end: Offset.zero).animate(anim),
                                    child: FadeTransition(opacity: anim, child: child),
                                  );
                                },
                                child: CharacterArt(id, key: ValueKey(id), main: cocoa, contain: true),
                              ),
                            ),
                          ),
                        ),
                        ArrowBtn(icon: Icons.chevron_right, onTap: () => _move(1)),
                      ]),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Center(child: Text('Option ${index + 1} of ${_ids.length}', style: pixel(14, cocoa, height: 1.3))),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(slant + 22, 22, slant + 22, 24),
                      child: Row(children: [
                        Expanded(child: SlantButton(label: 'Cancel', color: cocoa, textColor: cream, shadow: coral, onTap: () => Navigator.pop(context))),
                        const SizedBox(width: 16),
                        Expanded(child: SlantButton(label: 'Select', color: coral, textColor: cream, shadow: cocoa, onTap: () => Navigator.pop(context, id))),
                      ]),
                    ),
                        ]),
                      ),
                    ),
                  ]),
              ),
            ),
          ]),
        )),
      ),
    );
  }
}
