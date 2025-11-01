// lib/data/task_repo.dart
import 'package:sqflite/sqflite.dart';
import 'task.dart';

class TaskRepo {
  Database? _db;

  Future<void> _open() async {
    _db ??= await openDatabase(
      'tasks.db',
      version: 2, // bump version so onUpgrade runs
      onCreate: (db, v) async {
        await db.execute('''
          CREATE TABLE tasks(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT,
            due INTEGER,                -- store millis
            status INTEGER NOT NULL,
            priority INTEGER NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldV, newV) async {
        // If you previously had TEXT/DATE for due, no need to drop the table.
        // Just keep reading old rows via Task.fromMap (handles string/int).
        // Optionally add an index now:
        await db.execute('CREATE INDEX IF NOT EXISTS idx_tasks_due ON tasks(due)');
      },
    );
  }

  Future<int> create(Task t) async {
    await _open();
    return await _db!.insert('tasks', t.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> update(Task t) async {
    await _open();
    await _db!.update('tasks', t.toMap(), where: 'id=?', whereArgs: [t.id]);
  }

  Future<void> delete(int id) async {
    await _open();
    await _db!.delete('tasks', where: 'id=?', whereArgs: [id]);
  }

  Future<List<Task>> all() async {
    await _open();
    final rows = await _db!.query('tasks', orderBy: 'due IS NULL, due'); // nulls last
    return rows.map(Task.fromMap).toList();
  }
}
