import 'package:flutter/material.dart';
import '../core/palette.dart';
import '../core/shapes.dart';
import '../core/transitions.dart';
import '../widgets/calendar_parts.dart';
import '../widgets/slant_widgets.dart';

/// Opens the app-styled time picker. Returns the chosen time, or null if cancelled.
Future<TimeOfDay?> pickTime(BuildContext context,
        {required TimeOfDay initial, String title = 'PICK A TIME'}) =>
    showFade<TimeOfDay>(context,
        builder: (_) => SlantTimePicker(initial: initial, title: title));

/// Time picker in the app's style: hour and minute steppers (minutes move in steps of 5)
/// and AM / PM tabs, on the same orange circle backdrop as the calendars.
class SlantTimePicker extends StatefulWidget {
  final TimeOfDay initial;
  final String title;
  const SlantTimePicker(
      {super.key, required this.initial, required this.title});

  @override
  State<SlantTimePicker> createState() => _SlantTimePickerState();
}

class _SlantTimePickerState extends State<SlantTimePicker> {
  late int hour12 =
      widget.initial.hourOfPeriod == 0 ? 12 : widget.initial.hourOfPeriod;
  late int minute = ((widget.initial.minute / 5).round() * 5) % 60;
  late bool pm = widget.initial.period == DayPeriod.pm;

  void _hour(int d) => setState(() => hour12 = (hour12 - 1 + d + 12) % 12 + 1);
  void _minute(int d) => setState(() => minute = (minute + d * 5 + 60) % 60);
  TimeOfDay get _value =>
      TimeOfDay(hour: (hour12 % 12) + (pm ? 12 : 0), minute: minute);

  Widget _stepper(String digits, VoidCallback up, VoidCallback down) =>
      Column(mainAxisSize: MainAxisSize.min, children: [
        ArrowBtn(icon: Icons.keyboard_arrow_up, onTap: up),
        const SizedBox(height: 6),
        Text(digits, style: pixel(54, cocoa, height: 1.2)),
        const SizedBox(height: 6),
        ArrowBtn(icon: Icons.keyboard_arrow_down, onTap: down),
      ]);

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
                              color: cocoa,
                              padding: const EdgeInsets.fromLTRB(
                                  slant + 18, 14, 34, 14),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(widget.title,
                                    style: pixel(22, cream,
                                        weight: FontWeight.w700)),
                              ),
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
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Stack(clipBehavior: Clip.hardEdge, children: [
                                  const Positioned.fill(
                                      child: CalendarBackdrop()),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        slant + 10, 22, slant + 10, 22),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            _stepper(
                                                hour12
                                                    .toString()
                                                    .padLeft(2, '0'),
                                                () => _hour(1),
                                                () => _hour(-1)),
                                            Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 6),
                                                child: Text(':',
                                                    style: pixel(54, cocoa,
                                                        height: 1.2))),
                                            _stepper(
                                                minute
                                                    .toString()
                                                    .padLeft(2, '0'),
                                                () => _minute(1),
                                                () => _minute(-1)),
                                            const SizedBox(width: 16),
                                            Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  SlantChip(
                                                      label: 'AM',
                                                      selected: !pm,
                                                      pad: 16,
                                                      onTap: () => setState(
                                                          () => pm = false)),
                                                  const SizedBox(height: 10),
                                                  SlantChip(
                                                      label: 'PM',
                                                      selected: pm,
                                                      pad: 16,
                                                      onTap: () => setState(
                                                          () => pm = true)),
                                                ]),
                                          ]),
                                    ),
                                  ),
                                ]),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      slant + 22, 6, slant + 22, 24),
                                  child: Row(children: [
                                    Expanded(
                                        child: SlantButton(
                                            label: 'Cancel',
                                            color: cocoa,
                                            textColor: cream,
                                            shadow: coral,
                                            onTap: () =>
                                                Navigator.pop(context))),
                                    const SizedBox(width: 16),
                                    Expanded(
                                        child: SlantButton(
                                            label: 'Set',
                                            color: coral,
                                            textColor: cream,
                                            shadow: cocoa,
                                            onTap: () => Navigator.pop(
                                                context, _value))),
                                  ]),
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
