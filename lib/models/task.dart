import 'package:flutter/material.dart';

const categories = ['Study', 'Fitness', 'Chores', 'Hobby', 'Other'];
const _shortMonths = [
  'JAN',
  'FEB',
  'MAR',
  'APR',
  'MAY',
  'JUN',
  'JUL',
  'AUG',
  'SEP',
  'OCT',
  'NOV',
  'DEC'
];
const dayNames = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
const dayInitials = ['M', 'T', 'W', 'Th', 'F', 'Sa', 'Su'];

String dateKey(DateTime n) =>
    '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';

/// "2026-11-20" -> "NOV 20, 2026"
String prettyDate(String key) {
  final d = DateTime.parse(key);
  return '${_shortMonths[d.month - 1]} ${d.day}, ${d.year}';
}

String todayKey() => dateKey(DateTime.now());

class Task {
  String id, name, desc, category;
  int xp;
  String repeat; // 'none' | 'daily' | 'weekly'
  List<int> days; // weekly: 1 = Mon ... 7 = Sun
  bool _doneFlag;
  String? lastDone; // recurring tasks: date it was last completed
  String? dueDate; // optional target date (yyyy-MM-dd) for one-time tasks
  int streak,
      best; // consecutive scheduled days completed (current run / best run)
  // snapshot taken at completion so un-ticking the same day restores the old streak
  int streakBefore, bestBefore;
  String? lastBefore;

  Task(
      {required this.id,
      required this.name,
      this.desc = '',
      required this.category,
      required this.xp,
      this.repeat = 'none',
      this.days = const [],
      bool done = false,
      this.lastDone,
      this.streak = 0,
      this.best = 0,
      this.streakBefore = 0,
      this.bestBefore = 0,
      this.lastBefore,
      this.dueDate})
      : _doneFlag = done;

  bool get recurring => repeat != 'none';

  /// One-time tasks stay done; recurring tasks are only "done" for the day they were completed.
  bool get done => recurring ? lastDone == todayKey() : _doneFlag;
  set done(bool v) {
    if (!recurring) {
      _doneFlag = v;
      return;
    }
    final today = todayKey();
    if (v) {
      if (lastDone == today) return;
      streakBefore = streak;
      bestBefore = best;
      lastBefore = lastDone;
      // the run continues only if the previous scheduled day was completed
      streak = (lastDone != null && lastDone == _prevDueKey) ? streak + 1 : 1;
      if (streak > best) best = streak;
      lastDone = today;
    } else if (lastDone == today) {
      streak = streakBefore;
      best = bestBefore;
      lastDone = lastBefore;
    }
  }

  /// Date key of the most recent scheduled day before today.
  String? get _prevDueKey {
    final n = DateTime.now();
    for (var k = 1; k <= 7; k++) {
      final d = DateTime(n.year, n.month, n.day - k);
      if (repeat == 'daily' || days.contains(d.weekday)) return dateKey(d);
    }
    return null;
  }

  /// Current run, or 0 if a scheduled day was missed.
  int get currentStreak {
    if (!recurring || lastDone == null) return 0;
    return (lastDone == todayKey() || lastDone == _prevDueKey) ? streak : 0;
  }

  /// Target date has passed and the task is not done.
  bool get overdue =>
      dueDate != null && !done && dueDate!.compareTo(todayKey()) < 0;

  /// Target date is today.
  bool get dueIsToday => dueDate == todayKey();

  /// e.g. "NOV 20, 2026"
  String get dueLabel => prettyDate(dueDate!);

  /// Row for the `tasks` table (column order/position is managed by the database layer).
  Map<String, Object?> toDb() => {
        'id': id,
        'name': name,
        'description': desc,
        'category': category,
        'xp': xp,
        'repeat_type': repeat,
        'days': days.join(','),
        'done': _doneFlag ? 1 : 0,
        'last_done': lastDone,
        'streak': streak,
        'best': best,
        'streak_before': streakBefore,
        'best_before': bestBefore,
        'last_before': lastBefore,
        'due_date': dueDate,
      };

  factory Task.fromDb(Map<String, Object?> m) {
    final rawDays = (m['days'] as String?) ?? '';
    return Task(
      id: m['id'] as String,
      name: m['name'] as String,
      desc: (m['description'] as String?) ?? '',
      category: m['category'] as String,
      xp: m['xp'] as int,
      repeat: (m['repeat_type'] as String?) ?? 'none',
      days: rawDays.isEmpty
          ? <int>[]
          : rawDays.split(',').map(int.parse).toList(),
      done: ((m['done'] as int?) ?? 0) == 1,
      lastDone: m['last_done'] as String?,
      streak: (m['streak'] as int?) ?? 0,
      best: (m['best'] as int?) ?? 0,
      streakBefore: (m['streak_before'] as int?) ?? 0,
      bestBefore: (m['best_before'] as int?) ?? 0,
      lastBefore: m['last_before'] as String?,
      dueDate: m['due_date'] as String?,
    );
  }

  /// Copies progress (done state + streak data) from an older version of this task.
  void copyProgressFrom(Task o) {
    _doneFlag = o._doneFlag;
    lastDone = o.lastDone;
    streak = o.streak;
    best = o.best;
    streakBefore = o.streakBefore;
    bestBefore = o.bestBefore;
    lastBefore = o.lastBefore;
  }

  bool get dueToday =>
      repeat != 'weekly' || days.contains(DateTime.now().weekday);

  /// "Completed" bucket: done today, or a recurring task whose last scheduled round was
  /// completed and which is now waiting for its next scheduled day.
  bool get inCompleted =>
      done ||
      (recurring && !dueToday && lastDone != null && lastDone == _prevDueKey);

  /// "Ongoing" bucket: available today and not done yet.
  bool get ongoing => !inCompleted && dueToday;

  String get repeatLabel => repeat == 'daily'
      ? 'EVERY DAY'
      : days.map((d) => dayNames[d - 1]).join(' ');

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'desc': desc,
        'category': category,
        'xp': xp,
        'done': _doneFlag,
        'repeat': repeat,
        'days': days,
        'lastDone': lastDone,
        'streak': streak,
        'best': best,
        'streakBefore': streakBefore,
        'bestBefore': bestBefore,
        'lastBefore': lastBefore,
        'dueDate': dueDate
      };
  factory Task.fromJson(Map<String, dynamic> j) => Task(
      id: j['id'],
      name: j['name'],
      desc: j['desc'] ?? '',
      category: j['category'] ?? categories.last,
      xp: j['xp'],
      repeat: j['repeat'] ?? 'none',
      days: List<int>.from(j['days'] ?? const []),
      done: j['done'] ?? false,
      lastDone: j['lastDone'],
      streak: j['streak'] ?? 0,
      best: j['best'] ?? 0,
      streakBefore: j['streakBefore'] ?? 0,
      bestBefore: j['bestBefore'] ?? 0,
      lastBefore: j['lastBefore'],
      dueDate: j['dueDate']);
}
