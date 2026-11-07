import 'package:flutter/material.dart';
import '../core/palette.dart';
import '../core/shapes.dart';
import '../core/transitions.dart';
import '../widgets/popup_header.dart';
import '../widgets/slant_widgets.dart';

/// Asks "really delete this task?". Returns true only if the user confirms.
Future<bool?> confirmDelete(BuildContext context, {required String taskName}) =>
    showFade<bool>(
      context,
      builder: (_) => ConfirmDialog(
        title: 'DELETE TASK?',
        message: 'Delete "$taskName"? This cannot be undone.',
        confirmLabel: 'Delete',
      ),
    );

/// App-styled confirmation popup: floating header tab, message, Cancel and a confirm button.
class ConfirmDialog extends StatelessWidget {
  final String title, message, confirmLabel;
  const ConfirmDialog(
      {super.key,
      required this.title,
      required this.message,
      required this.confirmLabel});

  @override
  Widget build(BuildContext context) {
    const slant = 12.0;
    return Dialog(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.only(right: 8, bottom: 8),
        child: HeaderPanel(
          title: title,
          titleSize: 20,
          headerColor: coral,
          shadowColor: cocoa,
          onClose: () => Navigator.pop(context, false),
          panel: SizedBox(
            width: double.infinity,
            child: Stack(children: [
              Positioned.fill(
                child: Transform.translate(
                    offset: const Offset(8, 8),
                    child: ClipPath(
                        clipper: const Para(slant),
                        child: const ColoredBox(color: cocoa))),
              ),
              ClipPath(
                clipper: const Para(slant),
                child: Container(
                  color: cream,
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: kHeaderSpace),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                              slant + 24, 6, slant + 24, 0),
                          child: Text(message,
                              style: const TextStyle(
                                  fontSize: 18,
                                  height: 1.4,
                                  fontWeight: FontWeight.w600,
                                  color: cocoa)),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                              slant + 22, 24, slant + 22, 26),
                          child: Row(children: [
                            Expanded(
                                child: SlantButton(
                                    label: 'Cancel',
                                    color: cocoa,
                                    textColor: cream,
                                    shadow: coral,
                                    onTap: () =>
                                        Navigator.pop(context, false))),
                            const SizedBox(width: 16),
                            Expanded(
                                child: SlantButton(
                                    label: confirmLabel,
                                    color: coral,
                                    textColor: cream,
                                    shadow: cocoa,
                                    onTap: () => Navigator.pop(context, true))),
                          ]),
                        ),
                      ]),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
