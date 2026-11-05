import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/palette.dart';
import '../core/shapes.dart';
import '../core/transitions.dart';
import '../widgets/calendar_parts.dart';
import '../widgets/slant_widgets.dart';

/// Opens the app-styled clock time picker. Returns the chosen time, or null if cancelled.
Future<TimeOfDay?> pickTime(BuildContext context,
        {required TimeOfDay initial, String title = 'PICK A TIME'}) =>
    showFade<TimeOfDay>(context,
        builder: (_) => SlantTimePicker(initial: initial, title: title));

/// Circular clock picker in the app's style: tap or drag on the dial to set the hour, then the
/// minute (it switches automatically). Tap the big digits to go back to the hour or minute.
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
  late int minute = widget.initial.minute;
  late bool pm = widget.initial.period == DayPeriod.pm;
  bool hourMode = true; // true: dial sets the hour, false: the minute

  TimeOfDay get _value =>
      TimeOfDay(hour: (hour12 % 12) + (pm ? 12 : 0), minute: minute);

  /// Turns a touch position on the dial into an hour or minute.
  void _pick(Offset p, double d) {
    final c = d / 2;
    var angle = math.atan2(p.dy - c, p.dx - c) +
        math.pi / 2; // 0 at 12 o'clock, clockwise
    if (angle < 0) angle += 2 * math.pi;
    setState(() {
      if (hourMode) {
        final h = (angle / (math.pi / 6)).round() % 12;
        hour12 = h == 0 ? 12 : h;
      } else {
        minute = (angle / (math.pi / 30)).round() % 60;
      }
    });
  }

  void _finishPick() {
    if (hourMode)
      setState(() => hourMode = false); // after the hour, go on to the minutes
  }

  Widget _digits(String text, bool active, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child:
            Text(text, style: pixel(46, active ? coral : cocoa, height: 1.2)),
      );

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
                child: Stack(children: [
                  const Positioned.fill(child: CalendarBackdrop()),
                  Column(
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
                              icon: const Icon(Icons.close,
                                  color: cocoa, size: 28),
                              onPressed: () => Navigator.pop(context)),
                        ]),
                        Flexible(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(
                                slant + 14, 18, slant + 14, 0),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // big digits (tap to choose hour or minute) + AM / PM
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          _digits(
                                              hour12.toString().padLeft(2, '0'),
                                              hourMode,
                                              () => setState(
                                                  () => hourMode = true)),
                                          Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 4),
                                              child: Text(':',
                                                  style: pixel(46, cocoa,
                                                      height: 1.2))),
                                          _digits(
                                              minute.toString().padLeft(2, '0'),
                                              !hourMode,
                                              () => setState(
                                                  () => hourMode = false)),
                                          const SizedBox(width: 18),
                                          Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                SlantChip(
                                                    label: 'AM',
                                                    selected: !pm,
                                                    pad: 14,
                                                    onTap: () => setState(
                                                        () => pm = false)),
                                                const SizedBox(height: 8),
                                                SlantChip(
                                                    label: 'PM',
                                                    selected: pm,
                                                    pad: 14,
                                                    onTap: () => setState(
                                                        () => pm = true)),
                                              ]),
                                        ]),
                                  ),
                                  const SizedBox(height: 16),
                                  // the clock dial
                                  LayoutBuilder(builder: (_, box) {
                                    final d = math.min(box.maxWidth - 8, 250.0);
                                    return Center(
                                      child: SizedBox(
                                        width:
                                            d + 8, // room for the offset shadow
                                        height: d + 8,
                                        child: GestureDetector(
                                          behavior: HitTestBehavior.opaque,
                                          onTapDown: (t) =>
                                              _pick(t.localPosition, d),
                                          onTapUp: (_) => _finishPick(),
                                          onPanStart: (t) =>
                                              _pick(t.localPosition, d),
                                          onPanUpdate: (t) =>
                                              _pick(t.localPosition, d),
                                          onPanEnd: (_) => _finishPick(),
                                          child: CustomPaint(
                                              painter: _DialPainter(
                                                  hourMode: hourMode,
                                                  hour12: hour12,
                                                  minute: minute,
                                                  d: d)),
                                        ),
                                      ),
                                    );
                                  }),
                                  const SizedBox(height: 20),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
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
                                  const SizedBox(height: 24),
                                ]),
                          ),
                        ),
                      ]),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Clock face: cream disc with a dark outline and offset shadow (like the round buttons),
/// the numbers around it, and a coral hand + knob on the selected hour/minute.
class _DialPainter extends CustomPainter {
  final bool hourMode;
  final int hour12, minute;
  final double d; // diameter of the face
  const _DialPainter(
      {required this.hourMode,
      required this.hour12,
      required this.minute,
      required this.d});

  void _label(
      Canvas canvas, String text, Offset center, Color color, double size) {
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(
              color: color,
              fontSize: size,
              fontWeight: FontWeight.w800,
              fontStyle: FontStyle.italic)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(d / 2, d / 2);
    final r = d / 2;
    canvas.drawCircle(
        c + const Offset(6, 6), r, Paint()..color = cocoa); // shadow
    canvas.drawCircle(c, r, Paint()..color = cream);
    canvas.drawCircle(
      c,
      r - 1.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = cocoa,
    );

    final ring = r - 32; // radius of the number ring
    Offset at(double angle) =>
        c + Offset(math.cos(angle), math.sin(angle)) * ring;
    final selAngle = hourMode
        ? (hour12 % 12) * math.pi / 6 - math.pi / 2
        : minute * math.pi / 30 - math.pi / 2;
    final sel = at(selAngle);

    // hand
    canvas.drawLine(
      c,
      sel,
      Paint()
        ..color = coral
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
    // knob on the selected value
    canvas.drawCircle(sel, 23, Paint()..color = coral);
    canvas.drawCircle(
      sel,
      23,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = cocoa,
    );

    if (hourMode) {
      for (var n = 1; n <= 12; n++) {
        if (n == hour12) continue; // drawn inside the knob below
        _label(
            canvas, '$n', at((n % 12) * math.pi / 6 - math.pi / 2), cocoa, 20);
      }
      _label(canvas, '$hour12', sel, cream, 20);
    } else {
      for (var m = 0; m < 60; m++) {
        final a = m * math.pi / 30 - math.pi / 2;
        if (m % 5 == 0) {
          if (m == minute) continue;
          _label(canvas, m.toString().padLeft(2, '0'), at(a), cocoa, 17);
        } else if (m != minute) {
          canvas.drawCircle(at(a), 1.6,
              Paint()..color = cocoa.withOpacity(0.35)); // minute ticks
        }
      }
      _label(canvas, minute.toString().padLeft(2, '0'), sel, cream, 17);
    }

    // centre cap
    canvas.drawCircle(c, 7, Paint()..color = coral);
    canvas.drawCircle(
      c,
      7,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = cocoa,
    );
  }

  @override
  bool shouldRepaint(covariant _DialPainter o) =>
      o.hourMode != hourMode ||
      o.hour12 != hour12 ||
      o.minute != minute ||
      o.d != d;
}
