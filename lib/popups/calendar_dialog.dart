import 'package:flutter/material.dart';
import '../core/palette.dart';
import '../core/shapes.dart';
import '../models/history.dart';
import '../models/task.dart';
import '../widgets/calendar_parts.dart';
import '../widgets/slant_widgets.dart';

const _monthNames = ['JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE', 'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER'];
const _weekdays = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
const _weekdayShort = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su']; // indexed by DateTime.weekday - 1
const _sunRed = Color(0xFFC92F3F); // Sundays, like the red SUN column in the Persona calendar

/// Activity calendar styled after the Persona 3 calendar screen: big month number with the
/// neighbouring months beside it, weekday columns tinted, a gold stamp circle on every day with
/// at least one completed task. Tapping a day slides a details panel up over the grid.
/// Dates come from the device clock.
class CalendarDialog extends StatefulWidget {
  final List<HistoryEntry> history;
  const CalendarDialog({super.key, required this.history});

  @override
  State<CalendarDialog> createState() => _CalendarDialogState();
}

class _CalendarDialogState extends State<CalendarDialog> {
  late DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  String? selected; // tapped day; null = nothing selected, so the details panel stays hidden
  String _shown = todayKey(); // which day the panel shows (kept while it slides back down)
  int _dir = 1; // 1 = moving to a later month, -1 = earlier (sets the slide direction)

  Map<String, List<HistoryEntry>> get _byDate {
    final m = <String, List<HistoryEntry>>{};
    for (final h in widget.history) {
      m.putIfAbsent(h.date, () => []).add(h);
    }
    return m;
  }

  String get _monthKey => '${month.year}-${month.month}';

  /// Slides [child] out/in (direction follows [_dir]) whenever the month changes.
  Widget _monthSlide(Widget child) => ClipRect(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (c, anim) {
            final incoming = c.key == ValueKey(_monthKey);
            final from = incoming ? _dir.toDouble() : -_dir.toDouble();
            return SlideTransition(
              position: Tween<Offset>(begin: Offset(from, 0), end: Offset.zero).animate(anim),
              child: FadeTransition(opacity: anim, child: c),
            );
          },
          child: KeyedSubtree(key: ValueKey(_monthKey), child: child),
        ),
      );

  void _shift(int d) => setState(() {
        _dir = d;
        selected = null; // a different month: close the day panel
        month = DateTime(month.year, month.month + d);
      });

  void _select(String key) => setState(() {
        selected = key;
        _shown = key;
      });

  void _back() => setState(() => selected = null);

  bool get _canGoForward {
    final n = DateTime.now();
    return month.year < n.year || (month.year == n.year && month.month < n.month);
  }

  String _detailTitle(String key) {
    final d = DateTime.parse(key);
    return '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')} (${_weekdayShort[d.weekday - 1]})';
  }

  Widget _cell(int day, int col, int daysInMonth, Map<String, List<HistoryEntry>> byDate, String today) {
    if (day < 1 || day > daysInMonth) return const SizedBox(height: 52);
    final key = dateKey(DateTime(month.year, month.month, day));
    final stamped = (byDate[key] ?? const []).isNotEmpty;
    final isSelected = key == selected;
    final isToday = key == today;
    final tint = col == 0 ? _sunRed : (col == 6 ? orange : cocoa);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _select(key),
      child: SizedBox(
        height: 52,
        child: Stack(alignment: Alignment.center, children: [
          // coral triangle marks today (nod to the pink triangle in the Persona calendar)
          if (isToday) const Positioned(left: 3, bottom: 3, child: TodayTriangle()),
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: stamped ? sun : null, // the stamp
              border: isSelected ? Border.all(color: cocoa, width: 3) : null,
            ),
            child: Text('$day', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, fontStyle: FontStyle.italic, color: stamped ? cocoa : tint)),
          ),
        ]),
      ),
    );
  }

  Widget _monthArrow({required bool left, required int number, required bool enabled}) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? () => _shift(left ? -1 : 1) : null,
        child: Opacity(
          opacity: enabled ? 1 : 0.3,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (left) const Icon(Icons.chevron_left, color: coral, size: 34),
            Text('$number', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: cocoa)),
            if (!left) const Icon(Icons.chevron_right, color: coral, size: 34),
          ]),
        ),
      );

  /// Completed-tasks list for the tapped day; covers the calendar grid.
  Widget _detailPanel(double slant, List<HistoryEntry> entries, int xpTotal) => Container(
        color: cocoa,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: EdgeInsets.fromLTRB(slant + 14, 12, 6, 0),
            child: Row(children: [
              SlantChip(label: _detailTitle(_shown), selected: true, pad: 18, onTap: () {}),
              const Spacer(),
              IconButton(onPressed: _back, icon: const Icon(Icons.keyboard_arrow_down, color: cream, size: 36)),
            ]),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(slant + 22, 6, slant + 22, 22),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (entries.isEmpty)
                  Text('•  Nothing in particular', style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic, fontWeight: FontWeight.w600, color: cream.withOpacity(0.6)))
                else ...[
                  for (final e in entries)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('•  ', style: TextStyle(fontSize: 19, color: coral, fontWeight: FontWeight.w900)),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(e.name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, fontStyle: FontStyle.italic, color: cream)),
                            const SizedBox(height: 2),
                            Text(e.category.toUpperCase(), style: pixel(12, peach, height: 1.4)),
                          ]),
                        ),
                        const SizedBox(width: 8),
                        Text('+${e.xp} XP', style: pixel(14, sun, height: 1.3, weight: FontWeight.w700)),
                      ]),
                    ),
                  const SizedBox(height: 10),
                  Text('${entries.length} ${entries.length == 1 ? 'TASK' : 'TASKS'}  ·  $xpTotal XP', style: pixel(13, cream, height: 1.4)),
                ],
              ]),
            ),
          ),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    const slant = 12.0;
    final byDate = _byDate;
    final today = todayKey();
    final blanks = DateTime(month.year, month.month, 1).weekday % 7; // Sunday-first grid
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final rows = ((blanks + daysInMonth) / 7).ceil();
    final entries = byDate[_shown] ?? const <HistoryEntry>[];
    final xpTotal = entries.fold(0, (a, e) => a + e.xp);
    final prevMonth = month.month == 1 ? 12 : month.month - 1;
    final nextMonth = month.month == 12 ? 1 : month.month + 1;

    return PopScope(
      canPop: selected == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && selected != null) _back(); // back button or tap outside the popup: close the panel first
      },
      child: Dialog(
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
              child: Transform.translate(offset: const Offset(8, 8), child: ClipPath(clipper: const Para(slant), child: const ColoredBox(color: cocoa))),
            ),
            ClipPath(
              clipper: const Para(slant),
              child: Container(
                color: cream,
                // solid orange circle + ring behind everything, header tab included
                child: Stack(children: [
                  const Positioned.fill(child: CalendarBackdrop()),
                  GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: selected == null ? null : _back, // same as the panel's down arrow
                    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  // sticky header
                  Row(children: [
                    Expanded(
                      child: ClipPath(
                        clipper: const HeaderClip(),
                        child: Container(
                          color: cocoa,
                          padding: const EdgeInsets.fromLTRB(slant + 18, 14, 34, 14),
                          child: Text('CALENDAR', style: pixel(24, cream, weight: FontWeight.w700)),
                        ),
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.close, color: cocoa, size: 28), onPressed: () => Navigator.pop(context)),
                  ]),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Stack(clipBehavior: Clip.hardEdge, children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(slant + 8, 14, slant + 8, 16),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                            // month row (big month number, neighbours): stays visible when a day is selected
                            _monthSlide(
                              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.center, children: [
                                _monthArrow(left: true, number: prevMonth, enabled: true),
                                Column(mainAxisSize: MainAxisSize.min, children: [
                                  Text('${month.month}', style: const TextStyle(fontSize: 82, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: cocoa, height: 0.95)),
                                  Text('${_monthNames[month.month - 1]}  ${month.year}', style: pixel(11, cocoa, height: 1.4, weight: FontWeight.w700)),
                                ]),
                                _monthArrow(left: false, number: nextMonth, enabled: _canGoForward),
                              ]),
                            ),
                            const SizedBox(height: 14),
                            // weekday labels + days: the completed-tasks panel slides up over just this part
                            Stack(clipBehavior: Clip.hardEdge, children: [
                              AnimatedSize(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeInOutCubic,
                                alignment: Alignment.topCenter,
                                child: _monthSlide(
                                  Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                                    Row(children: [
                                      for (var i = 0; i < 7; i++)
                                        Expanded(
                                          child: Center(
                                            child: Text(_weekdays[i], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: i == 0 ? _sunRed : (i == 6 ? orange : cocoa))),
                                          ),
                                        ),
                                    ]),
                                    const SizedBox(height: 4),
                                    for (var r = 0; r < rows; r++)
                                      Row(children: [
                                        for (var c = 0; c < 7; c++) Expanded(child: _cell(r * 7 + c - blanks + 1, c, daysInMonth, byDate, today)),
                                      ]),
                                  ]),
                                ),
                              ),
                              Positioned.fill(
                                child: IgnorePointer(
                                  ignoring: selected == null,
                                  child: AnimatedSlide(
                                    offset: selected == null ? const Offset(0, 1) : Offset.zero,
                                    duration: const Duration(milliseconds: 380),
                                    curve: Curves.easeOutCubic,
                                    // the panel absorbs taps so only taps OUTSIDE it close it
                                    child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () {}, child: _detailPanel(slant, entries, xpTotal)),
                                  ),
                                ),
                              ),
                            ]),
                          ]),
                        ),
                      ]),
                    ),
                  ),
                ])),
                ]),
              ),
            ),
          ]),
        ),
      ),
    ));
  }
}