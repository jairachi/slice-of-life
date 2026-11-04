import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../models/history.dart';
import '../models/task.dart';

/// SQLite storage for tasks and the completion history.
///
/// Every change touches only the affected row (instead of rewriting everything), so the app
/// stays fast with thousands of tasks. Small values (name, XP, settings) stay in
/// SharedPreferences.
class TaskDatabase {
  TaskDatabase._();
  static final TaskDatabase instance = TaskDatabase._();

  Database? _db;
  Future<Database> get _database async => _db ??= await _open();

  Future<Database> _open() async {
    final path = p.join(await getDatabasesPath(), 'sol.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE tasks (
            id TEXT PRIMARY KEY,
            position INTEGER NOT NULL,
            name TEXT NOT NULL,
            description TEXT NOT NULL DEFAULT '',
            category TEXT NOT NULL,
            xp INTEGER NOT NULL,
            repeat_type TEXT NOT NULL DEFAULT 'none',
            days TEXT NOT NULL DEFAULT '',
            done INTEGER NOT NULL DEFAULT 0,
            last_done TEXT,
            streak INTEGER NOT NULL DEFAULT 0,
            best INTEGER NOT NULL DEFAULT 0,
            streak_before INTEGER NOT NULL DEFAULT 0,
            best_before INTEGER NOT NULL DEFAULT 0,
            last_before TEXT,
            due_date TEXT
          )''');
        await db.execute('CREATE INDEX idx_tasks_position ON tasks(position)');
        await db.execute('''
          CREATE TABLE history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            task_id TEXT NOT NULL,
            name TEXT NOT NULL,
            category TEXT NOT NULL,
            xp INTEGER NOT NULL
          )''');
        await db.execute('CREATE INDEX idx_history_date ON history(date)');
        await db
            .execute('CREATE INDEX idx_history_task ON history(task_id, date)');
      },
    );
  }

  // ---------------- tasks ----------------

  Future<List<Task>> loadTasks() async {
    final db = await _database;
    final rows = await db.query('tasks', orderBy: 'position ASC');
    return rows.map(Task.fromDb).toList();
  }

  /// Inserts a new task (at the end of the list) or updates an existing one in place.
  Future<void> saveTask(Task t) async {
    final db = await _database;
    final updated =
        await db.update('tasks', t.toDb(), where: 'id = ?', whereArgs: [t.id]);
    if (updated == 0) {
      final next = Sqflite.firstIntValue(await db
              .rawQuery('SELECT COALESCE(MAX(position), -1) + 1 FROM tasks')) ??
          0;
      await db.insert('tasks', {...t.toDb(), 'position': next});
    }
  }

  Future<void> deleteTask(String id) async {
    final db = await _database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------- history ----------------

  Future<List<HistoryEntry>> loadHistory() async {
    final db = await _database;
    final rows = await db.query('history', orderBy: 'id ASC');
    return rows.map(HistoryEntry.fromDb).toList();
  }

  Future<void> addHistory(HistoryEntry e) async {
    final db = await _database;
    await db.insert('history', e.toDb());
  }

  /// Removes a task's completion entries for one day (used when a recurring task is un-ticked).
  Future<void> removeHistory(String taskId, String date) async {
    final db = await _database;
    await db.delete('history',
        where: 'task_id = ? AND date = ?', whereArgs: [taskId, date]);
  }

  // ---------------- one-time migration ----------------

  /// Moves tasks/history saved by earlier versions (SharedPreferences JSON) into SQLite.
  Future<void> migrateFromPrefs(SharedPreferences prefs) async {
    if (prefs.getBool('sqliteMigrated') == true) return;
    final db = await _database;
    final rawTasks = prefs.getString('tasks');
    final rawHistory = prefs.getString('history');
    try {
      await db.transaction((txn) async {
        if (rawTasks != null) {
          final list = (jsonDecode(rawTasks) as List)
              .map((e) => Task.fromJson(e))
              .toList();
          for (var i = 0; i < list.length; i++) {
            await txn.insert('tasks', {...list[i].toDb(), 'position': i},
                conflictAlgorithm: ConflictAlgorithm.ignore);
          }
        }
        if (rawHistory != null) {
          for (final e in (jsonDecode(rawHistory) as List)
              .map((e) => HistoryEntry.fromJson(e))) {
            await txn.insert('history', e.toDb());
          }
        }
      });
      await prefs.setBool('sqliteMigrated', true);
      await prefs.remove('tasks');
      await prefs.remove('history');
    } catch (e) {
      debugPrint('Migration to SQLite failed (old data kept): $e');
    }
  }
}
