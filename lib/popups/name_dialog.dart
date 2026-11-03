import 'package:flutter/material.dart';
import '../core/palette.dart';

/// First-time welcome dialog that asks for the player's name.
class NameDialog extends StatefulWidget {
  final String initial;
  final bool editing;
  const NameDialog({super.key, this.initial = '', this.editing = false});
  @override
  State<NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<NameDialog> {
  late final controller = TextEditingController(text: widget.initial);
  String? error;

  void _submit() {
    final v = controller.text.trim();
    if (v.isEmpty) return setState(() => error = 'Enter a name to continue.');
    Navigator.pop(context, v);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: widget.editing,
        child: AlertDialog(
          backgroundColor: cocoa,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: coral, width: 2)),
          title: Text(widget.editing ? 'CHANGE NAME' : 'WELCOME!', textAlign: TextAlign.center, style: pixel(22, coral, weight: FontWeight.w700)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(widget.editing ? 'Enter a new name for your character.' : 'What should we call your character?', textAlign: TextAlign.center, style: TextStyle(color: cream)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              maxLength: 16,
              textCapitalization: TextCapitalization.words,
              onSubmitted: (_) => _submit(),
              style: const TextStyle(color: ink),
              decoration: InputDecoration(hintText: 'Your name', errorText: error, counterStyle: const TextStyle(color: peach)),
            ),
          ]),
          actions: [
            if (widget.editing) TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: cream))),
            OutlinedButton(onPressed: _submit, child: Text(widget.editing ? 'Save' : 'Start')),
          ],
        ),
      );
}
