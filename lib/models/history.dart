/// One completed task, recorded with the device's local date at the moment it was ticked.
/// A snapshot (name/category/XP are copied) so the history stays correct even if the task
/// is edited or deleted later.
class HistoryEntry {
  final String date; // yyyy-MM-dd
  final String taskId, name, category;
  final int xp;

  const HistoryEntry(
      {required this.date,
      required this.taskId,
      required this.name,
      required this.category,
      required this.xp});

  Map<String, dynamic> toJson() => {
        'date': date,
        'taskId': taskId,
        'name': name,
        'category': category,
        'xp': xp
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> j) => HistoryEntry(
      date: j['date'],
      taskId: j['taskId'],
      name: j['name'],
      category: j['category'],
      xp: j['xp']);
}
