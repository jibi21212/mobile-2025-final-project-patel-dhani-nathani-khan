// lib/data/task_repo.dart
import 'package:sqflite/sqflite.dart';
import 'task.dart';
import '../services/notification_service.dart';

class TaskRepo {
  Database? _db;
  final _notificationService = NotificationService();

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
    final id = await _db!.insert('tasks', t.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    
    // Schedule notification for the new task
    final taskWithId = t.copyWith(id: id);
    await _notificationService.scheduleTaskReminder(taskWithId);
    
    return id;
  }

  Future<void> update(Task t) async {
    await _open();
    await _db!.update('tasks', t.toMap(), where: 'id=?', whereArgs: [t.id]);
    
    // Cancel old notification and schedule new one
    if (t.id != null) {
      await _notificationService.cancelTaskReminder(t.id!);
      await _notificationService.scheduleTaskReminder(t);
    }
  }

  Future<void> delete(int id) async {
    await _open();
    await _db!.delete('tasks', where: 'id=?', whereArgs: [id]);
    
    // Cancel notification for deleted task
    await _notificationService.cancelTaskReminder(id);
  }

  Future<List<Task>> all() async {
    await _open();
    final rows = await _db!.query('tasks', orderBy: 'due IS NULL, due'); // nulls last
    return rows.map(Task.fromMap).toList();
  }
}
