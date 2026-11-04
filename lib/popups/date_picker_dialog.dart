import 'package:flutter/material.dart';
import '../core/palette.dart';
import '../core/shapes.dart';
import '../core/transitions.dart';
import '../widgets/calendar_parts.dart';
import '../widgets/slant_widgets.dart';

const _monthNames = [
  'JANUARY',
  'FEBRUARY',
  'MARCH',
  'APRIL',
  'MAY',
  'JUNE',
  'JULY',
  'AUGUST',
  'SEPTEMBER',
  'OCTOBER',
  'NOVEMBER',
  'DECEMBER'
];
const _weekdays = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
const _sunRed = Color(0xFFC92F3F);

/// Opens the app-styled date picker. Returns the chosen day, or null if cancelled.
Future<DateTime?> pickDate(BuildContext context,
        {required DateTime initial,
        required DateTime first,
        required DateTime last,
        String title = 'PICK A DATE'}) =>
    showFade<DateTime>(context,
        builder: (_) => SlantDatePicker(
            initial: initial, first: first, last: last, title: title));

/// Date picker in the same style as the calendar popup: big month number, neighbouring months,
/// tinted weekday columns, orange circle backdrop. Tap a day, then Select.
class SlantDatePicker extends StatefulWidget {
  final DateTime initial, first, last;
  final String title;
  const SlantDatePicker(
      {super.key,
      required this.initial,
      required this.first,
      required this.last,
      required this.title});

  @override
  State<SlantDatePicker> createState() => _SlantDatePickerState();
}

class _SlantDatePickerState extends State<SlantDatePicker> {
  late DateTime month = DateTime(widget.initial.year, widget.initial.month);
  late DateTime selected =
      DateTime(widget.initial.year, widget.initial.month, widget.initial.day);
  int _dir = 1;

  DateTime get _first =>
      DateTime(widget.first.year, widget.first.month, widget.first.day);
  DateTime get _last =>
      DateTime(widget.last.year, widget.last.month, widget.last.day);
  bool get _canPrev => month.isAfter(DateTime(_first.year, _first.month));
  bool get _canNext => month.isBefore(DateTime(_last.year, _last.month));
  String get _monthKey => '${month.year}-${month.month}';

  void _shift(int d) => setState(() {
        _dir = d;
        month = DateTime(month.year, month.month + d);
      });

  Widget _monthSlide(Widget child) => ClipRect(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (c, anim) {
            final incoming = c.key == ValueKey(_monthKey);
            final from = incoming ? _dir.toDouble() : -_dir.toDouble();
            return SlideTransition(
              position: Tween<Offset>(begin: Offset(from, 0), end: Offset.zero)
                  .animate(anim),
              child: FadeTransition(opacity: anim, child: c),
            );
          },
          child: KeyedSubtree(key: ValueKey(_monthKey), child: child),
        ),
      );

  Widget _monthArrow(
          {required bool left, required int number, required bool enabled}) =>
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? () => _shift(left ? -1 : 1) : null,
        child: Opacity(
          opacity: enabled ? 1 : 0.3,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (left) const Icon(Icons.chevron_left, color: coral, size: 34),
            Text('$number',
                style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: cocoa)),
            if (!left) const Icon(Icons.chevron_right, color: coral, size: 34),
          ]),
        ),
      );

  Widget _cell(int day, int col, int daysInMonth) {
    if (day < 1 || day > daysInMonth) return const SizedBox(height: 52);
    final date = DateTime(month.year, month.month, day);
    final enabled = !date.isBefore(_first) && !date.isAfter(_last);
    final isSelected = date == selected;
    final now = DateTime.now();
    final isToday = date == DateTime(now.year, now.month, now.day);
    final tint = col == 0 ? _sunRed : (col == 6 ? orange : cocoa);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? () => setState(() => selected = date) : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.3,
        child: SizedBox(
          height: 52,
          child: Stack(alignment: Alignment.center, children: [
            if (isToday)
              const Positioned(left: 3, bottom: 3, child: TodayTriangle()),
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  shape: BoxShape.circle, color: isSelected ? coral : null),
              child: Text('$day',
                  style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      fontStyle: FontStyle.italic,
                      color: isSelected ? cream : tint)),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const slant = 12.0;
    final blanks =
        DateTime(month.year, month.month, 1).weekday % 7; // Sunday-first grid
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final rows = ((blanks + daysInMonth) / 7).ceil();
    final prevMonth = month.month == 1 ? 12 : month.month - 1;
    final nextMonth = month.month == 12 ? 1 : month.month + 1;

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
                                        slant + 8, 14, slant + 8, 16),
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          _monthSlide(
                                            Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  _monthArrow(
                                                      left: true,
                                                      number: prevMonth,
                                                      enabled: _canPrev),
                                                  Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Text('${month.month}',
                                                            style: const TextStyle(
                                                                fontSize: 82,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w900,
                                                                fontStyle:
                                                                    FontStyle
                                                                        .italic,
                                                                color: cocoa,
                                                                height: 0.95)),
                                                        Text(
                                                            '${_monthNames[month.month - 1]}  ${month.year}',
                                                            style: pixel(
                                                                11, cocoa,
                                                                height: 1.4,
                                                                weight:
                                                                    FontWeight
                                                                        .w700)),
                                                      ]),
                                                  _monthArrow(
                                                      left: false,
                                                      number: nextMonth,
                                                      enabled: _canNext),
                                                ]),
                                          ),
                                          const SizedBox(height: 14),
                                          AnimatedSize(
                                            duration: const Duration(
                                                milliseconds: 250),
                                            curve: Curves.easeInOutCubic,
                                            alignment: Alignment.topCenter,
                                            child: _monthSlide(
                                              Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .stretch,
                                                  children: [
                                                    Row(children: [
                                                      for (var i = 0;
                                                          i < 7;
                                                          i++)
                                                        Expanded(
                                                          child: Center(
                                                            child: Text(
                                                                _weekdays[i],
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w900,
                                                                    fontStyle:
                                                                        FontStyle
                                                                            .italic,
                                                                    color: i ==
                                                                            0
                                                                        ? _sunRed
                                                                        : (i == 6
                                                                            ? orange
                                                                            : cocoa))),
                                                          ),
                                                        ),
                                                    ]),
                                                    const SizedBox(height: 4),
                                                    for (var r = 0;
                                                        r < rows;
                                                        r++)
                                                      Row(children: [
                                                        for (var c = 0;
                                                            c < 7;
                                                            c++)
                                                          Expanded(
                                                              child: _cell(
                                                                  r * 7 +
                                                                      c -
                                                                      blanks +
                                                                      1,
                                                                  c,
                                                                  daysInMonth)),
                                                      ]),
                                                  ]),
                                            ),
                                          ),
                                        ]),
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
                                            label: 'Select',
                                            color: coral,
                                            textColor: cream,
                                            shadow: cocoa,
                                            onTap: () => Navigator.pop(
                                                context, selected))),
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
