import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class LocalDb {
  static Database? _db;
  static Future<Database> instance() async {
    if (_db != null) return _db!;
    final path = p.join(await getDatabasesPath(), 'tasks.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, v) async {
        await db.execute('''
        CREATE TABLE tasks(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          description TEXT,
          due INTEGER,
          status INTEGER NOT NULL,
          priority INTEGER NOT NULL
        );
        ''');
      },
    );
    return _db!;
  }
}
