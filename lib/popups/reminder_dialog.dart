import 'package:flutter/material.dart';
import '../core/palette.dart';
import '../core/shapes.dart';
import '../widgets/slant_widgets.dart';

/// Reminder settings popup: on/off switch + reminder time.
/// [onChanged] is called for every change and returns whether it was accepted
/// (turning reminders on can fail if the notification permission is denied).
class ReminderDialog extends StatefulWidget {
  final bool enabled;
  final TimeOfDay time;
  final Future<bool> Function(bool enabled, TimeOfDay time) onChanged;
  const ReminderDialog(
      {super.key,
      required this.enabled,
      required this.time,
      required this.onChanged});

  @override
  State<ReminderDialog> createState() => _ReminderDialogState();
}

class _ReminderDialogState extends State<ReminderDialog> {
  late bool enabled = widget.enabled;
  late TimeOfDay time = widget.time;
  String? note;

  Future<void> _toggle(bool on) async {
    final ok = await widget.onChanged(on, time);
    if (!mounted) return;
    setState(() {
      enabled = ok ? on : false;
      note = (!ok && on)
          ? 'Notifications are blocked. Allow them for this app in your phone settings, then try again.'
          : null;
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: time,
      helpText: 'REMINDER TIME',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
                primary: coral,
                onPrimary: cream,
                surface: cream,
                onSurface: cocoa)),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() => time = picked);
    if (enabled) await widget.onChanged(true, picked);
  }

  @override
  Widget build(BuildContext context) {
    const slant = 12.0;
    return Dialog(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.only(right: 8, bottom: 8),
        child: SizedBox(
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
                      Row(children: [
                        Expanded(
                          child: ClipPath(
                            clipper: const HeaderClip(),
                            child: Container(
                              color: coral,
                              padding: const EdgeInsets.fromLTRB(
                                  slant + 18, 14, 34, 14),
                              child: Text('REMINDERS',
                                  style: pixel(22, cream,
                                      weight: FontWeight.w700)),
                            ),
                          ),
                        ),
                        IconButton(
                            icon:
                                const Icon(Icons.close, color: cocoa, size: 28),
                            onPressed: () => Navigator.pop(context)),
                      ]),
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(
                              slant + 22, 18, slant + 22, 24),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  const Expanded(
                                    child: Text('Notifications',
                                        style: TextStyle(
                                            fontSize: 19,
                                            fontWeight: FontWeight.w800,
                                            fontStyle: FontStyle.italic,
                                            color: cocoa)),
                                  ),
                                  Switch(
                                      value: enabled,
                                      onChanged: _toggle,
                                      activeColor: cream,
                                      activeTrackColor: coral,
                                      inactiveThumbColor: cocoa,
                                      inactiveTrackColor: peach),
                                ]),
                                const SizedBox(height: 6),
                                Text('REMIND ME AT',
                                    style: pixel(11, coral,
                                        height: 1.5, weight: FontWeight.w700)),
                                const SizedBox(height: 8),
                                SlantChip(
                                  label: time.format(context),
                                  selected: enabled,
                                  off: Colors.white,
                                  pad: 18,
                                  trailing: Icon(Icons.access_time,
                                      size: 18, color: enabled ? cream : coral),
                                  onTap: _pickTime,
                                ),
                                const SizedBox(height: 14),
                                const Text(
                                  'You get a daily check-in at this time, plus a reminder on the target date of any unfinished task that has one.',
                                  style: TextStyle(
                                      fontSize: 15, height: 1.4, color: cocoa),
                                ),
                                if (note != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: Text(note!,
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: coral)),
                                  ),
                              ]),
                        ),
                      ),
                    ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
