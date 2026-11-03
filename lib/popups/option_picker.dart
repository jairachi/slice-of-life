import 'package:flutter/material.dart';
import '../core/palette.dart';

/// Compact menu popup (same look as the original floating menu: dark cocoa, coral
/// outline, check + label rows). Pops the chosen option string.
class OptionPicker extends StatelessWidget {
  final String title, current;
  final List<String> options;
  const OptionPicker({super.key, required this.title, required this.options, required this.current});

  @override
  Widget build(BuildContext context) => SimpleDialog(
        backgroundColor: cocoa,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: coral, width: 2)),
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
        contentPadding: const EdgeInsets.only(bottom: 12),
        title: Text(title, textAlign: TextAlign.center, style: pixel(18, coral, weight: FontWeight.w700)),
        children: [
          for (final c in options)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, c),
              child: Row(children: [
                SizedBox(width: 24, child: c == current ? const Icon(Icons.check, color: sun, size: 22) : null),
                const SizedBox(width: 12),
                Text(c, style: TextStyle(color: c == current ? sun : cream, fontWeight: FontWeight.w700, fontSize: 16)),
              ]),
            ),
        ],
      );
}
