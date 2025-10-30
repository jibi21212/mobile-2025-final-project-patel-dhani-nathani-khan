import 'local_db.dart';
import 'task.dart';

class TaskRepo {
  Future<List<Task>> all() async {
    final db = await LocalDb.instance();
    final rows = await db.query('tasks', orderBy: 'due IS NULL, due ASC, id DESC');
    return rows.map(Task.fromMap).toList();
  }

  Future<int> create(Task t) async {
    final db = await LocalDb.instance();
    return db.insert('tasks', t.toMap());
  }

  Future<int> update(Task t) async {
    final db = await LocalDb.instance();
    return db.update('tasks', t.toMap(), where: 'id = ?', whereArgs: [t.id]);
  }

  Future<int> delete(int id) async {
    final db = await LocalDb.instance();
    return db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  // Mid-check HTTP stub (no auth yet): PLACEHOLDER fake sync until we implement it
  Future<void> fakeSync() async {
    // make harmless GET just to satisfy HTTP requirement now
    // ignore: unused_local_variable
    // final res = await http.get(Uri.parse('https://jsonplaceholder.typicode.com/todos/1'));
    await Future.delayed(const Duration(milliseconds: 400));
  }
}
