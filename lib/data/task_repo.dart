import 'package:sqflite/sqflite.dart';
import 'task.dart';
import '../services/notification_service.dart';

class TaskRepo {
  Database? _db;
  final _notificationService = NotificationService();

  Future<void> _open() async {
    _db ??= await openDatabase(
      'tasks.db',
      version: 3, // bumped version so onUpgrade runs
      onCreate: (db, v) async {
        await db.execute('''
          CREATE TABLE tasks(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT,
            due INTEGER,
            status INTEGER NOT NULL,
            priority INTEGER NOT NULL,
            recurrence INTEGER NOT NULL DEFAULT 0  -- new column
          )
        ''');

        // Optional: index for faster sorting by due date
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_tasks_due ON tasks(due)',
        );
      },
      onUpgrade: (db, oldV, newV) async {
        // If DB existed before, make sure it gets the new column and index

        // Old versions might not have the index
        if (oldV < 2) {
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_tasks_due ON tasks(due)',
          );
        }

        // Add recurrence column if upgrading from any version < 3
        if (oldV < 3) {
          await db.execute(
            'ALTER TABLE tasks ADD COLUMN recurrence INTEGER NOT NULL DEFAULT 0',
          );
        }
      },
    );
  }

  Future<int> create(Task t) async {
    await _open();
    final id = await _db!.insert(
      'tasks',
      t.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

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
    final rows = await _db!.query(
      'tasks',
      orderBy: 'due IS NULL, due', // nulls last
    );
    return rows.map(Task.fromMap).toList();
  }
}
