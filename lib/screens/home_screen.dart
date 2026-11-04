import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../character/character_art.dart';
import '../character/character_picker.dart';
import '../core/palette.dart';
import '../core/shapes.dart';
import '../core/transitions.dart';
import '../models/history.dart';
import '../models/leveling.dart';
import '../models/task.dart';
import '../popups/calendar_dialog.dart';
import '../popups/level_up_dialog.dart';
import '../popups/name_dialog.dart';
import '../popups/option_picker.dart';
import '../popups/stats_dialog.dart';
import '../widgets/slant_widgets.dart';
import '../widgets/xp_gain_pill.dart';
import 'editor_screen.dart';

const statusLabels = {
  'ongoing': 'Ongoing',
  'completed': 'Completed',
  'all': 'All'
};

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late final AnimationController _menuCtl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 380));
  late final AnimationController _gainCtl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1000));
  final GlobalKey _stackKey = GlobalKey();
  int _gainAmount = 0; // floating "+XP" badge
  Offset? _gainPos;
  List<HistoryEntry> history =
      []; // one entry per completed task (feeds the calendar)
  List<Task> tasks = [];
  int totalXp = 0;
  Map<String, int> catXp = {}, catCount = {}; // per-category stats
  String filter = 'All';
  String name = '';
  String character = defaultCharacter;
  bool loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _menuCtl.dispose();
    _gainCtl.dispose();
    super.dispose();
  }

  // Re-check dates when the app returns to the foreground so recurring tasks reset on a new day.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) setState(() {});
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString('tasks');
    final savedName = p.getString('name');
    setState(() {
      totalXp = p.getInt('xp') ?? 0;
      catXp = Map<String, int>.from(jsonDecode(p.getString('catXp') ?? '{}'));
      catCount =
          Map<String, int>.from(jsonDecode(p.getString('catCount') ?? '{}'));
      history = (jsonDecode(p.getString('history') ?? '[]') as List)
          .map((e) => HistoryEntry.fromJson(e))
          .toList();
      name = savedName ?? '';
      character = p.getString('character') ?? defaultCharacter;
      loaded = true;
      if (raw != null)
        tasks = (jsonDecode(raw) as List).map((e) => Task.fromJson(e)).toList();
    });
    if (savedName == null || savedName.isEmpty) _askName();
  }

  /// First launch: ask for the hero's name (cannot be dismissed until entered).
  /// Opens the character picker (plain for now) and saves the choice.
  Future<void> _pickCharacter() async {
    final id = await showFade<String>(context,
        builder: (_) => CharacterPicker(current: character));
    if (id == null) return;
    setState(() => character = id);
    final p = await SharedPreferences.getInstance();
    await p.setString('character', id);
  }

  Future<void> _askName({bool editing = false}) async {
    final result = await showFade<String>(
      context,
      dismissible: editing,
      builder: (_) =>
          NameDialog(initial: editing ? name : '', editing: editing),
    );
    if (result == null) return;
    setState(() => name = result);
    final p = await SharedPreferences.getInstance();
    await p.setString('name', result);
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
        'tasks', jsonEncode(tasks.map((t) => t.toJson()).toList()));
    await p.setInt('xp', totalXp);
    await p.setString('catXp', jsonEncode(catXp));
    await p.setString('catCount', jsonEncode(catCount));
    await p.setString(
        'history', jsonEncode(history.map((e) => e.toJson()).toList()));
  }

  int _clamp(int v) => v < 0 ? 0 : v;

  /// Adds (+1) or removes (-1) a task's XP from the total and its category stats.
  void _credit(Task t, int sign) {
    totalXp = _clamp(totalXp + sign * t.xp);
    catXp[t.category] = _clamp((catXp[t.category] ?? 0) + sign * t.xp);
    catCount[t.category] = _clamp((catCount[t.category] ?? 0) + sign);
  }

  /// App-styled message popup (slanted dark panel, coral offset slab, lock icon).
  void _snack(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      padding: EdgeInsets.zero,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      duration: const Duration(seconds: 2),
      content: Padding(
        padding: const EdgeInsets.only(right: 6, bottom: 6),
        child: Stack(children: [
          Positioned.fill(
            child: Transform.translate(
                offset: const Offset(6, 6),
                child: ClipPath(
                    clipper: const Para(12),
                    child: const ColoredBox(color: coral))),
          ),
          ClipPath(
            clipper: const Para(12),
            child: Container(
              color: cocoa,
              padding: const EdgeInsets.fromLTRB(28, 14, 26, 14),
              child: Row(children: [
                const Icon(Icons.lock_outline, color: sun, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(message,
                      style: const TextStyle(
                          color: cream,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          fontStyle: FontStyle.italic,
                          height: 1.3)),
                ),
              ]),
            ),
          ),
        ]),
      ),
    ));

  /// Floating "+XP" badge near [global] (the tap position), plus the rise/fade animation.
  void _showGain(int amount, Offset? global) {
    final box = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    final size = MediaQuery.of(context).size;
    final local = (global != null && box != null)
        ? box.globalToLocal(global)
        : Offset(size.width / 2, size.height * 0.3);
    setState(() {
      _gainAmount = amount;
      _gainPos = local;
    });
    _gainCtl.forward(from: 0);
  }

  void _toggle(Task t, [Offset? at]) {
    if (!t.dueToday) return; // recurring task not scheduled today
    // a completed one-time task is final: it cannot be un-ticked
    if (!t.recurring && t.done) {
      _snack("Completed tasks can't be undone.");
      return;
    }
    final before = levelFor(totalXp).level;
    setState(() {
      t.done = !t.done;
      _credit(t, t.done ? 1 : -1);
      if (t.done) {
        history.add(HistoryEntry(
            date: todayKey(),
            taskId: t.id,
            name: t.name,
            category: t.category,
            xp: t.xp));
      } else {
        history.removeWhere((e) =>
            e.taskId == t.id &&
            e.date == todayKey()); // undo today's completion
      }
    });
    _save();
    t.done ? HapticFeedback.mediumImpact() : HapticFeedback.lightImpact();
    _showGain(t.done ? t.xp : -t.xp, at);
    final after = levelFor(totalXp).level;
    if (after > before) {
      HapticFeedback.heavyImpact();
      showFade<void>(context,
          builder: (_) => LevelUpDialog(level: after, name: name));
    }
  }

  void _showCalendar() =>
      showFade<void>(context, builder: (_) => CalendarDialog(history: history));

  Future<void> _edit([Task? t]) async {
    // completed one-time tasks are read-only
    if (t != null && !t.recurring && t.done) {
      _snack("Completed tasks can't be edited.");
      return;
    }
    final res = await showFade<Object>(
      context,
      builder: (ctx) => Dialog(
        // 7.5% top + 7.5% bottom leaves the form 85% of the screen height.
        insetPadding: EdgeInsets.symmetric(
            horizontal: 20, vertical: MediaQuery.of(ctx).size.height * 0.075),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        child: SizedBox.expand(child: EditorScreen(task: t)),
      ),
    );
    if (res == null) return;
    setState(() {
      if (res == 'delete' && t != null) {
        if (t.done) _credit(t, -1);
        tasks.remove(t);
      } else if (res is Task) {
        final i = tasks.indexWhere((x) => x.id == res.id);
        if (i >= 0) {
          final old = tasks[i];
          if (old.done) _credit(old, -1);
          // keep completed state + streak unless the repeat type changed
          if (old.repeat == res.repeat) res.copyProgressFrom(old);
          if (res.done) _credit(res, 1);
          tasks[i] = res;
        } else {
          tasks.add(res);
        }
      }
    });
    _save();
  }

  void _showStats() {
    var cur = 0, best = 0;
    for (final t in tasks) {
      if (t.currentStreak > cur) cur = t.currentStreak;
      if (t.best > best) best = t.best;
    }
    showFade<void>(context,
        builder: (_) =>
            StatsDialog(xp: catXp, count: catCount, streak: cur, best: best));
  }

  String status = 'ongoing'; // 'ongoing' (default) | 'completed' | 'all'

  Future<void> _pickCategory() async {
    final c = await showFade<String>(context,
        builder: (_) => OptionPicker(
            title: 'CATEGORY',
            options: ['All', ...categories],
            current: filter));
    if (c != null) setState(() => filter = c);
  }

  Future<void> _pickStatus() async {
    final c = await showFade<String>(context,
        builder: (_) => OptionPicker(
            title: 'SHOW',
            options: statusLabels.values.toList(),
            current: statusLabels[status]!));
    if (c != null)
      setState(() =>
          status = statusLabels.entries.firstWhere((e) => e.value == c).key);
  }

  /// Category button (left) and status button (right); each opens a menu popup.
  /// If they do not fit on one line, the whole row scales down together.
  Widget _filterBar() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        child: LayoutBuilder(
          builder: (_, box) => FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: box.maxWidth),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SlantChip(
                        label: 'Category: $filter',
                        selected: true,
                        trailing: const Icon(Icons.arrow_drop_down,
                            color: cream, size: 22),
                        onTap: _pickCategory),
                    const SizedBox(width: 12),
                    SlantChip(
                        label: statusLabels[status]!,
                        selected: true,
                        trailing: const Icon(Icons.arrow_drop_down,
                            color: cream, size: 22),
                        onTap: _pickStatus),
                  ]),
            ),
          ),
        ),
      );

  bool menuOpen = false;

  void _setMenu(bool open) {
    setState(() => menuOpen = open);
    open ? _menuCtl.forward() : _menuCtl.reverse();
  }

  void _closeMenu() => _setMenu(false);

  /// Circle button with an offset drop-shadow slab (same effect as the panels).
  Widget _circleBtn(
          {required Widget icon,
          required Color color,
          required Color shadow,
          required Color border,
          required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 60,
          height: 60,
          child: Stack(children: [
            Positioned(
                left: 4,
                top: 4,
                child: Container(
                    width: 56,
                    height: 56,
                    decoration:
                        BoxDecoration(color: shadow, shape: BoxShape.circle))),
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: border, width: 2)),
              child: icon,
            ),
          ]),
        ),
      );

  /// One speed-dial option: inverted circle button + slanted label with offset shadow.
  Widget _dockItem(IconData icon, String label, VoidCallback onTap) {
    void go() {
      _closeMenu();
      onTap();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _circleBtn(
            icon: Icon(icon, color: coral, size: 26),
            color: cream,
            shadow: coral,
            border: coral,
            onTap: go),
        const SizedBox(width: 14),
        GestureDetector(
          onTap: go,
          child: Padding(
            padding: const EdgeInsets.only(right: 6, bottom: 6),
            child: Stack(children: [
              Positioned.fill(
                child: Transform.translate(
                    offset: const Offset(5, 5),
                    child: ClipPath(
                        clipper: const Para(10),
                        child: const ColoredBox(color: coral))),
              ),
              ClipPath(
                clipper: const Para(10),
                child: Container(
                  color: cream,
                  padding: const EdgeInsets.fromLTRB(24, 10, 22, 10),
                  child: Text(label.toUpperCase(),
                      style: const TextStyle(
                          color: coral,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 1)),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  /// Menu options stacked above the ☰ button. Each option travels between the button and
  /// its slot (with fade + scale) on the same controller, so open and close mirror each other.
  Widget _dock() {
    final List<(IconData, String, VoidCallback)> items = [
      (Icons.add, 'New task', () => _edit()),
      (Icons.edit, 'Change name', () => _askName(editing: true)),
      (Icons.face, 'Change persona', _pickCharacter),
      (Icons.calendar_month, 'Calendar', _showCalendar),
      (Icons.bar_chart, 'Stats', _showStats),
    ];
    return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < items.length; i++)
            AnimatedBuilder(
              animation: _menuCtl,
              child: _dockItem(items[i].$1, items[i].$2, items[i].$3),
              builder: (_, child) {
                final v = Curves.easeInOutCubic.transform(_menuCtl.value);
                final dist = (items.length - i) *
                    74.0; // distance back down to the ☰ button
                return Opacity(
                  opacity: v,
                  child: Transform.translate(
                    offset: Offset(0, (1 - v) * dist),
                    child: Transform.scale(
                        alignment: Alignment.centerLeft,
                        scale: 0.7 + 0.3 * v,
                        child: child),
                  ),
                );
              },
            ),
        ]);
  }

  @override
  Widget build(BuildContext context) {
    if (!loaded) return const Scaffold(body: SizedBox.shrink());
    final lv = levelFor(totalXp);
    final visible =
        tasks.where((t) => filter == 'All' || t.category == filter).toList();
    final ongoing = visible.where((t) => t.ongoing).toList();
    final completed = visible.where((t) => t.inCompleted).toList();
    // recurring tasks that are neither done nor available today (only listed under "All")
    final unavailable = status == 'all'
        ? visible.where((t) => !t.inCompleted && !t.dueToday).toList()
        : <Task>[];
    final shown = status == 'ongoing'
        ? ongoing
        : (status == 'completed' ? completed : [...ongoing, ...completed]);
    final emptyMsg = status == 'ongoing'
        ? 'No ongoing tasks.'
        : (status == 'completed'
            ? 'No completed tasks yet.'
            : 'No tasks in this category.');
    return Scaffold(
      body: Stack(key: _stackKey, children: [
        Container(
          decoration: const BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFF1D6), sun, orange])),
          child: SafeArea(
            // Whole page scrolls together: title, profile, then tasks.
            child: ListView(
              padding: const EdgeInsets.only(bottom: 100),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text.rich(TextSpan(
                        style: pixel(30, ink, weight: FontWeight.w700),
                        children: [
                          TextSpan(
                              text: 'SLICE ', style: TextStyle(color: coral)),
                          TextSpan(
                              text: 'OF LIFE', style: TextStyle(color: ink)),
                        ])),
                  ),
                ),
                _profile(lv),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                      child: Text('TASKS',
                          style: pixel(22, coral, weight: FontWeight.w700))),
                ),
                _filterBar(),
                const SizedBox(height: 12),
                if (tasks.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                        child: Text('No tasks yet. Open the menu to add one.',
                            style: TextStyle(color: ink))),
                  )
                else if (shown.isEmpty && unavailable.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                        child:
                            Text(emptyMsg, style: const TextStyle(color: ink))),
                  )
                else ...[
                  for (final t in shown)
                    Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 22, 20),
                        child: _row(t)),
                  if (unavailable.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                      child: Text('NOT TODAY',
                          style: pixel(16, ink, weight: FontWeight.w700)),
                    ),
                    for (final t in unavailable)
                      Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 22, 20),
                          child: _row(t)),
                  ],
                ],
              ],
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            ignoring: !menuOpen,
            child: GestureDetector(
              onTap: _closeMenu,
              child: AnimatedOpacity(
                opacity: menuOpen ? 1 : 0,
                duration: const Duration(milliseconds: 350),
                child: ColoredBox(color: Colors.black.withOpacity(0.6)),
              ),
            ),
          ),
        ),
        if (_gainPos != null)
          Positioned(
            left: (_gainPos!.dx - 60)
                .clamp(8.0, MediaQuery.of(context).size.width - 130)
                .toDouble(),
            top: _gainPos!.dy - 80,
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _gainCtl,
                builder: (_, __) {
                  final t = _gainCtl.value;
                  final rise = Curves.easeOutCubic.transform(t) * 56;
                  final opacity = t < 0.65
                      ? 1.0
                      : (1 - (t - 0.65) / 0.35).clamp(0.0, 1.0).toDouble();
                  final pop = 0.8 +
                      0.25 *
                          Curves.easeOutBack
                              .transform((t * 3).clamp(0.0, 1.0).toDouble());
                  return Opacity(
                    opacity: opacity,
                    child: Transform.translate(
                        offset: Offset(0, -rise),
                        child: Transform.scale(
                            scale: pop, child: XpGainPill(_gainAmount))),
                  );
                },
              ),
            ),
          ),
      ]),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IgnorePointer(ignoring: !menuOpen, child: _dock()),
          _circleBtn(
            color: coral,
            shadow: cocoa,
            border: cocoa,
            onTap: () => _setMenu(!menuOpen),
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Icon(menuOpen ? Icons.close : Icons.menu,
                  key: ValueKey(menuOpen), color: cream, size: 26),
            ),
          ),
        ],
      ),
    );
  }

  /// Profile band styled after the P3R "level up" screen: 65% light / 35% dark split
  /// with a slanted separator; stats on the left, title + art on the right.
  Widget _profile(({int level, int into, int need}) lv) {
    const italic = FontStyle.italic;
    const darkCoral = Color(0xFFC92F3F);
    final pct = (lv.into / lv.need).clamp(0.0, 1.0);
    return Container(
      width: double.infinity,
      color: cocoa, // dark strips above/below the band
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ClipRect(
        child: Container(
          color: coral,
          child: Stack(children: [
            // darker right section, cut by a slanted edge
            Positioned.fill(
                child: ClipPath(
                    clipper: const SplitClip(0.65, 18),
                    child: const ColoredBox(color: darkCoral))),
            // chosen silhouette: behind the text, not clipped, free to cross the slanted separator
            Positioned.fill(
              child: FractionallySizedBox(
                alignment: Alignment.centerRight,
                widthFactor: 0.5,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _pickCharacter,
                  child: CharacterArt(character,
                      main: darkCoral, shadow: coral, alignRight: true),
                ),
              ),
            ),
            IntrinsicHeight(
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                  // ---- left 65%: name, level, exp ----
                  Expanded(
                    flex: 65,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(32, 18, 30, 20),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () => _askName(editing: true),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                // name with a lighter offset "shadow" copy behind it (tap to rename)
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: Stack(children: [
                                    Transform.translate(
                                      offset: const Offset(3, 0),
                                      child: Text(name,
                                          style: const TextStyle(
                                              fontSize: 38,
                                              fontWeight: FontWeight.w800,
                                              fontStyle: italic,
                                              color: peach)),
                                    ),
                                    Text(name,
                                        style: const TextStyle(
                                            fontSize: 38,
                                            fontWeight: FontWeight.w800,
                                            fontStyle: italic,
                                            color: cocoa)),
                                  ]),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // each row scales down instead of overflowing on narrow screens / big numbers
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('LV',
                                        style: pixel(26, cream,
                                            height: 1.5,
                                            weight: FontWeight.w700)),
                                    const SizedBox(width: 6),
                                    Text('${lv.level}',
                                        style: pixel(66, cream, height: 1)),
                                  ]),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('NEXT EXP',
                                        style: pixel(16, cocoa,
                                            height: 1.4,
                                            weight: FontWeight.w700)),
                                    const SizedBox(width: 10),
                                    Text('${lv.need - lv.into}',
                                        style: pixel(24, cocoa,
                                            height: 1.2,
                                            weight: FontWeight.w700)),
                                  ]),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text('XP',
                                                  style: pixel(16, cocoa,
                                                      height: 1.4,
                                                      weight: FontWeight.w700)),
                                              const SizedBox(width: 12),
                                              Text('${lv.into}',
                                                  style: pixel(28, cream,
                                                      height: 1,
                                                      weight: FontWeight.w700)),
                                              Text(' / ${lv.need}',
                                                  style: pixel(18,
                                                      cream.withOpacity(0.85),
                                                      height: 1.2)),
                                            ])),
                                    const SizedBox(height: 5),
                                    // white-underline style progress line
                                    Stack(children: [
                                      Container(
                                          height: 5,
                                          color: cocoa.withOpacity(0.35)),
                                      // fills smoothly whenever XP changes
                                      TweenAnimationBuilder<double>(
                                        tween: Tween<double>(end: pct),
                                        duration:
                                            const Duration(milliseconds: 700),
                                        curve: Curves.easeOutCubic,
                                        builder: (_, v, __) =>
                                            FractionallySizedBox(
                                                widthFactor: v,
                                                child: Container(
                                                    height: 5, color: cream)),
                                      ),
                                    ]),
                                  ]),
                            ),
                          ]),
                    ),
                  ),
                  // ---- right 35%: (art is drawn in its own layer so it can cross the diagonal) ----
                  const Expanded(flex: 35, child: SizedBox.shrink()),
                ])),
          ]),
        ),
      ),
    );
  }

  /// Persona-style info panel: dark slanted body, coral header tab (task name),
  /// description as content, coral corner accent.
  Widget _row(Task t) {
    const slant = 12.0;
    final desc = t.desc.trim();
    return GestureDetector(
      onTap: () => _edit(t),
      child: Stack(clipBehavior: Clip.none, children: [
        // offset peach slab behind the panel
        Positioned.fill(
          child: Transform.translate(
            offset: const Offset(6, 6),
            child: ClipPath(
                clipper: const Para(slant),
                child: const ColoredBox(color: peach)),
          ),
        ),
        ClipPath(
          clipper: const Para(slant),
          child: Opacity(
            opacity: t.done ? 0.6 : (t.dueToday ? 1.0 : 0.45),
            child: Container(
              color: cocoa,
              child: Stack(children: [
                Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // header: coral tab with diagonal right edge + menu
                      Row(children: [
                        Expanded(
                          child: ClipPath(
                            clipper: const HeaderClip(),
                            child: Container(
                              color: coral,
                              padding: const EdgeInsets.fromLTRB(
                                  slant + 10, 8, 30, 8),
                              child: Row(children: [
                                GestureDetector(
                                  onTapUp: (d) => _toggle(t, d.globalPosition),
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                        color:
                                            t.done ? cream : Colors.transparent,
                                        border: Border.all(
                                            color: cream, width: 2.5)),
                                    child: t.done
                                        ? const Icon(Icons.check,
                                            size: 18, color: coral)
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    t.name.toUpperCase(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: cream,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                      fontStyle: FontStyle.italic,
                                      letterSpacing: 0.8,
                                      decoration: t.done
                                          ? TextDecoration.lineThrough
                                          : null,
                                      decorationColor: cream,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('+${t.xp} XP',
                                    style: pixel(14, sun,
                                        height: 1, weight: FontWeight.w700)),
                              ]),
                            ),
                          ),
                        ),
                        const SizedBox(width: 18),
                      ]),
                      // content: task description
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            slant + 18, 14, slant + 18, 16),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                desc.isEmpty ? 'No description.' : desc,
                                style: TextStyle(
                                    color: desc.isEmpty
                                        ? peach.withOpacity(0.6)
                                        : cream,
                                    fontSize: 13.5,
                                    height: 1.4,
                                    fontStyle: desc.isEmpty
                                        ? FontStyle.italic
                                        : FontStyle.normal),
                              ),
                              if (t.recurring) ...[
                                const SizedBox(height: 8),
                                Row(children: [
                                  Expanded(
                                      child: Text('↻ ${t.repeatLabel}',
                                          style: const TextStyle(
                                              color: peach,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 1))),
                                  if (t.currentStreak > 0) ...[
                                    // bright when today's task is done, dim when the streak still needs today
                                    Icon(Icons.local_fire_department,
                                        color: t.done ? sun : peach, size: 22),
                                    const SizedBox(width: 2),
                                    Text('${t.currentStreak}',
                                        style: pixel(18, t.done ? sun : peach,
                                            height: 1,
                                            weight: FontWeight.w700)),
                                  ],
                                ]),
                              ],
                            ]),
                      ),
                      // category tag in the lower-right corner
                      Align(
                        alignment: Alignment.centerRight,
                        child: ClipPath(
                          clipper: const TagClip(),
                          child: Container(
                            color: coral,
                            padding: const EdgeInsets.fromLTRB(34, 7, 26, 7),
                            child: Text(t.category.toUpperCase(),
                                style: pixel(14, cream,
                                    height: 1.2, weight: FontWeight.w700)),
                          ),
                        ),
                      ),
                    ]),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}
