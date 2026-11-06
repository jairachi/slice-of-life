import 'package:flutter/material.dart';
import '../character/character_art.dart';
import '../core/palette.dart';
import '../core/shapes.dart';
import '../popups/time_picker_dialog.dart';
import '../services/notification_service.dart';
import '../widgets/slant_widgets.dart';

/// Settings page: name, persona and reminders (moved here from the dock menu).
/// The screen holds no data of its own: it reads the current values through the getters and
/// asks the home screen to change them, then refreshes.
class SettingsScreen extends StatefulWidget {
  final String Function() getName;
  final String Function() getCharacter;
  final bool Function() getRemindersOn;
  final TimeOfDay Function() getRemindTime;
  final Future<void> Function() onChangeName;
  final Future<void> Function() onChangePersona;
  final Future<bool> Function(bool enabled, TimeOfDay time) onReminders;

  const SettingsScreen({
    super.key,
    required this.getName,
    required this.getCharacter,
    required this.getRemindersOn,
    required this.getRemindTime,
    required this.onChangeName,
    required this.onChangePersona,
    required this.onReminders,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? note;

  Future<void> _changeName() async {
    await widget.onChangeName();
    if (mounted) setState(() {});
  }

  Future<void> _changePersona() async {
    await widget.onChangePersona();
    if (mounted) setState(() {});
  }

  Future<void> _toggleReminders(bool on) async {
    final ok = await widget.onReminders(on, widget.getRemindTime());
    if (!mounted) return;
    setState(() => note = (!ok && on)
        ? 'Notifications are blocked. Allow them for this app in your phone settings, then try again.'
        : null);
  }

  Future<void> _pickTime() async {
    final picked = await pickTime(context,
        initial: widget.getRemindTime(), title: 'REMINDER TIME');
    if (picked == null) return;
    await widget.onReminders(widget.getRemindersOn(), picked);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final canRemind = NotificationService.supported; // false in the web version
    final on = canRemind && widget.getRemindersOn();
    final time = widget.getRemindTime();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFF1D6), sun, orange])),
        child: SafeArea(
          child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 22, 32),
              children: [
                Row(children: [
                  ArrowBtn(
                      icon: Icons.chevron_left,
                      onTap: () => Navigator.pop(context)),
                  const SizedBox(width: 14),
                  Text('SETTINGS',
                      style: pixel(26, ink, weight: FontWeight.w700)),
                ]),
                const SizedBox(height: 26),
                _SettingPanel(title: 'PROFILE', children: [
                  _Row(
                    label: 'NAME',
                    value: Text(widget.getName(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: cream,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            fontStyle: FontStyle.italic)),
                    action: SlantChip(
                        label: 'Change',
                        selected: true,
                        pad: 14,
                        onTap: _changeName),
                  ),
                  const SizedBox(height: 18),
                  _Row(
                    label: 'PERSONA',
                    value: SizedBox(
                        height: 92,
                        child: Align(
                            alignment: Alignment.centerLeft,
                            child: SizedBox(
                                width: 92,
                                child: CharacterArt(widget.getCharacter(),
                                    main: coral,
                                    shadow: lightOrange,
                                    outline: 4,
                                    contain: true)))),
                    action: SlantChip(
                        label: 'Change',
                        selected: true,
                        pad: 14,
                        onTap: _changePersona),
                  ),
                ]),
                const SizedBox(height: 30),
                _SettingPanel(title: 'REMINDERS', children: [
                  Row(children: [
                    const Expanded(
                        child: Text('Notifications',
                            style: TextStyle(
                                color: cream,
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                fontStyle: FontStyle.italic))),
                    Switch(
                        value: on,
                        onChanged: canRemind ? _toggleReminders : null,
                        activeColor: cream,
                        activeTrackColor: coral,
                        inactiveThumbColor: peach,
                        inactiveTrackColor: const Color(0xFF5A4446)),
                  ]),
                  const SizedBox(height: 12),
                  _Row(
                    label: 'REMIND ME AT',
                    value: Text(time.format(context),
                        style: pixel(20, cream, height: 1.3)),
                    action: SlantChip(
                        label: 'Change',
                        selected: true,
                        pad: 14,
                        onTap: canRemind ? _pickTime : () {}),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                      'A daily check-in at this time, plus a reminder on the target date of any unfinished task that has one.',
                      style:
                          TextStyle(color: peach, fontSize: 14, height: 1.4)),
                  if (!canRemind)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text(
                          'Reminders only work in the Android app. This web version cannot send notifications.',
                          style: TextStyle(
                              color: sun,
                              fontSize: 14,
                              fontWeight: FontWeight.w800)),
                    ),
                  if (note != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(note!,
                          style: const TextStyle(
                              color: sun,
                              fontSize: 14,
                              fontWeight: FontWeight.w800)),
                    ),
                ]),
              ]),
        ),
      ),
    );
  }
}

/// Label on top, current value below, action button on the right.
class _Row extends StatelessWidget {
  final String label;
  final Widget value;
  final Widget action;
  const _Row({required this.label, required this.value, required this.action});

  @override
  Widget build(BuildContext context) =>
      Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: pixel(11, peach, height: 1.5, weight: FontWeight.w700)),
            const SizedBox(height: 4),
            value,
          ]),
        ),
        const SizedBox(width: 10),
        action,
      ]);
}

/// Dark slanted panel with a coral header tab and an offset slab, like the task panels.
class _SettingPanel extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SettingPanel({required this.title, required this.children});

  @override
  Widget build(BuildContext context) =>
      Stack(clipBehavior: Clip.none, children: [
        Positioned.fill(
          child: Transform.translate(
              offset: const Offset(6, 6),
              child: ClipPath(
                  clipper: const Para(12),
                  child: const ColoredBox(color: peach))),
        ),
        ClipPath(
          clipper: const Para(12),
          child: Container(
            color: cocoa,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ClipPath(
                      clipper: const HeaderClip(),
                      child: Container(
                        color: coral,
                        padding: const EdgeInsets.fromLTRB(30, 10, 44, 10),
                        child: Text(title,
                            style: pixel(16, cream, weight: FontWeight.w700)),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(30, 18, 30, 22),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: children),
                  ),
                ]),
          ),
        ),
      ]);
}
