import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/goal.dart';
import '../models/task.dart';
import '../models/session.dart';

class DbService {
  static final DbService _singleton = DbService._();
  factory DbService() => _singleton;
  DbService._() {
    if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  Database? _db;

  Future<Database> _open() async {
    if (_db != null) return _db!;

    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'kira.sqlite');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE goals(
            goal_id TEXT PRIMARY KEY,
            type TEXT,
            description TEXT,
            deadline TEXT
          );
        ''');
        await db.execute('''
          CREATE TABLE tasks(
            task_id TEXT PRIMARY KEY,
            goal_id TEXT,
            description TEXT,
            rrule TEXT,
            estimated_minutes INTEGER
          );
        ''');
        await db.execute('''
          CREATE TABLE sessions(
            session_id TEXT PRIMARY KEY,
            task_id TEXT,
            start_time TEXT,
            end_time TEXT,
            status TEXT
          );
        ''');
      },
    );
    return _db!;
  }

  // ------- CRUD helpers (minimal set) -------
  Future<void> insertGoal(Goal g) async =>
      (await _open()).insert('goals', g.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

  Future<void> insertTasks(List<Task> tasks) async {
    final db = await _open();
    final batch = db.batch();
    for (final t in tasks) {
      batch.insert('tasks', t.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> insertSessions(List<Session> sessions) async {
    final db = await _open();
    final batch = db.batch();
    for (final s in sessions) {
      batch.insert('sessions', s.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Session>> upcomingSessions() async {
    final db = await _open();
    final maps = await db.query('sessions', where: 'status = ?', whereArgs: ['scheduled'], orderBy: 'start_time ASC');
    return maps.map(Session.fromMap).toList();
  }
}
