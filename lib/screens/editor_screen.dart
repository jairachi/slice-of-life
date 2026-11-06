import 'package:flutter/material.dart';
import '../widgets/popup_header.dart';
import '../core/palette.dart';
import '../core/shapes.dart';
import '../models/task.dart';
import '../popups/date_picker_dialog.dart';
import '../widgets/slant_widgets.dart';

const xpPresets = [10, 25, 50, 75];

/// "Assign Quest" screen
class EditorScreen extends StatefulWidget {
  final Task? task;
  const EditorScreen({super.key, this.task});
  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late final name = TextEditingController(text: widget.task?.name);
  late final desc = TextEditingController(text: widget.task?.desc);
  late final xp = TextEditingController(text: widget.task == null ? '' : '${widget.task!.xp}');
  // XP choice: a preset amount ('10', '25', '50', '75') or 'custom'
  late String xpChoice = widget.task == null ? '25' : (xpPresets.contains(widget.task!.xp) ? '${widget.task!.xp}' : 'custom');
  // recurring tasks keep their XP reward (it pays out every round)
  bool get xpLocked => widget.task?.recurring ?? false;
  late String category = widget.task?.category ?? categories.first;
  late String repeat = widget.task?.repeat ?? 'none';
  late String? dueDate = widget.task?.dueDate; // optional target date (one-time tasks only)
  late final Set<int> days = {...?widget.task?.days};
  String? error;

  /// App-styled calendar to choose the task's target date (today or later).
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var initial = dueDate != null ? DateTime.parse(dueDate!) : today;
    if (initial.isBefore(today)) initial = today;
    final picked = await pickDate(context, initial: initial, first: today, last: DateTime(now.year + 5, 12, 31), title: 'TARGET DATE');
    if (picked != null) setState(() => dueDate = dateKey(picked));
  }

  void _save() {
    final x = xpLocked ? widget.task!.xp : (xpChoice == 'custom' ? int.tryParse(xp.text.trim()) : int.parse(xpChoice));
    if (name.text.trim().isEmpty) return setState(() => error = 'Enter a task name.');
    if (x == null || x < 1) return setState(() => error = 'Enter an XP reward of 1 or more.');
    if (repeat == 'weekly' && days.isEmpty) return setState(() => error = 'Pick at least one day of the week.');
    Navigator.pop(
      context,
      Task(
        id: widget.task?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        name: name.text.trim(),
        desc: desc.text.trim(),
        category: category,
        xp: x,
        repeat: repeat,
        dueDate: repeat == 'none' ? dueDate : null,
        days: repeat == 'weekly' ? (days.toList()..sort()) : [],
      ),
    );
  }

  Widget _label(String s) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 6),
        child: Text('▸ $s', style: const TextStyle(fontSize: 14.5, color: coral, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1)),
      );

  @override
  Widget build(BuildContext context) {
    const slant = 12.0;
    const border = OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: ink, width: 2));
    const fieldStyle = TextStyle(fontSize: 16.5, color: ink);
    const dec = InputDecoration(border: border, enabledBorder: border, isDense: true, contentPadding: EdgeInsets.all(12));
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 8),
      child: HeaderPanel(title: 'ASSIGN QUEST', titleSize: 24, headerColor: coral, shadowColor: cocoa, onClose: () => Navigator.pop(context), fit: StackFit.expand, panel: Stack(fit: StackFit.expand, clipBehavior: Clip.none, children: [
        // offset dark slab behind the panel
        Positioned.fill(
          child: Transform.translate(
            offset: const Offset(8, 8),
            child: ClipPath(clipper: const Para(slant), child: const ColoredBox(color: cocoa)),
          ),
        ),
        ClipPath(
          clipper: const Para(slant),
          child: Material(
            color: cream,
            child: Column(children: [
              // coral header tab with diagonal edge + close
              const SizedBox(height: kHeaderSpace),
              Expanded(
                child: ListView(padding: const EdgeInsets.fromLTRB(slant + 18, 0, slant + 18, 24), children: [
                  _label('TASK NAME'),
                  TextField(controller: name, style: fieldStyle, decoration: dec),
                  _label('TASK DESCRIPTION'),
                  TextField(controller: desc, style: fieldStyle, maxLines: 4, decoration: dec),
                  _label('CATEGORY'),
                  DropdownButtonFormField<String>(
                    value: category,
                    style: fieldStyle,
                    dropdownColor: cream,
                    decoration: dec,
                    items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setState(() => category = v!),
                  ),
                  _label('XP REWARD'),
                  IgnorePointer(
                    ignoring: xpLocked,
                    child: Opacity(
                      opacity: xpLocked ? 0.45 : 1,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          for (final v in [...xpPresets.map((e) => '$e'), 'custom'])
                            SlantChip(
                              label: v,
                              selected: xpChoice == v,
                              off: Colors.white,
                              pad: 11,
                              gap: 6,
                              onTap: () => setState(() => xpChoice = v),
                            ),
                        ]),
                      ),
                    ),
                  ),
                  if (xpChoice == 'custom')
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: TextField(controller: xp, enabled: !xpLocked, style: fieldStyle, keyboardType: TextInputType.number, decoration: dec.copyWith(hintText: 'Enter a custom XP amount')),
                    ),
                  if (xpLocked)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text("XP can't be changed on recurring tasks.", style: TextStyle(color: cocoa, fontSize: 13, fontStyle: FontStyle.italic, fontWeight: FontWeight.w600)),
                    ),
                  _label('REPEAT'),
                  DropdownButtonFormField<String>(
                    value: repeat,
                    style: fieldStyle,
                    dropdownColor: cream,
                    decoration: dec,
                    items: const [
                      DropdownMenuItem(value: 'none', child: Text('Does not repeat')),
                      DropdownMenuItem(value: 'daily', child: Text('Every day')),
                      DropdownMenuItem(value: 'weekly', child: Text('Specific days of the week')),
                    ],
                    onChanged: (v) => setState(() => repeat = v!),
                  ),
                  if (repeat == 'weekly')
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          for (var d = 1; d <= 7; d++)
                            SlantChip(
                              label: dayInitials[d - 1],
                              selected: days.contains(d),
                              off: Colors.white,
                              pad: 9,
                              gap: 5,
                              onTap: () => setState(() => days.contains(d) ? days.remove(d) : days.add(d)),
                            ),
                        ]),
                      ),
                    ),
                  if (repeat == 'none') ...[
                    _label('TARGET DATE'),
                    Wrap(runSpacing: 4, children: [
                      SlantChip(
                        label: dueDate == null ? 'Pick a date' : prettyDate(dueDate!),
                        selected: dueDate != null,
                        off: Colors.white,
                        pad: 14,
                        trailing: Icon(Icons.calendar_month, size: 18, color: dueDate != null ? cream : coral),
                        onTap: _pickDate,
                      ),
                      if (dueDate != null) SlantChip(label: 'Clear', selected: false, off: Colors.white, pad: 12, onTap: () => setState(() => dueDate = null)),
                    ]),
                  ],
                  if (error != null) Padding(padding: const EdgeInsets.only(top: 14), child: Text(error!, style: const TextStyle(color: coral, fontWeight: FontWeight.w800, fontSize: 15))),
                  const SizedBox(height: 28),
                  Row(children: [
                    Expanded(child: SlantButton(label: 'Save Task', color: coral, textColor: cream, shadow: cocoa, onTap: _save)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SlantButton(
                        label: widget.task == null ? 'Cancel' : 'Delete Task',
                        color: cocoa,
                        textColor: cream,
                        shadow: coral,
                        onTap: () => Navigator.pop(context, widget.task == null ? null : 'delete'),
                      ),
                    ),
                  ]),
                ]),
              ),
            ]),
          ),
        ),
      ])),
    );
  }
}
