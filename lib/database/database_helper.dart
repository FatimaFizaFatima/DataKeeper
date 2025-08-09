import 'dart:developer';
import 'dart:io';
import 'package:data_keeper/models/user_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'package:permission_handler/permission_handler.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('recipes.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) {
        if (oldVersion < 1) {
          db.execute('''
        CREATE TABLE users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          phone TEXT NOT NULL,
          city TEXT NOT NULL,
          postalCode TEXT NOT NULL,
          street TEXT NOT NULL
        )
      ''');
        }
      },
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      phone TEXT NOT NULL,
      city TEXT NOT NULL,
      postalCode TEXT NOT NULL,
      street TEXT NOT NULL
    )
  ''');
    log("Users table created successfully");
  }

  Future<int> insertUser(User user) async {
    final db = await database;
    try {
      return await db.insert('users', user.toMap());
    } catch (e) {
      await printTables();
      rethrow;
    }
  }

  Future<List<User>> getUsers() async {
    final db = await instance.database;
    final maps = await db.query('users');
    return maps.map((map) => User.fromMap(map)).toList();
  }

  Future<List<String>> getTableNames() async {
    final db = await database;
    final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name");
    return tables.map((row) => row['name'] as String).toList();
  }

  Future<void> printTables() async {
    final tables = await getTableNames();
    log("Existing tables: $tables");
  }

  Future<int> updateUser(User user) async {
    final db = await instance.database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> deleteUser(int id) async {
    final db = await instance.database;
    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }

  Future<String?> exportDatabase() async {
    try {
      var status = await Permission.manageExternalStorage.request();
      if (!status.isGranted) {
        print("Storage permission denied");
        return null;
      }

      final dbPath = await getDatabasesPath();
      final sourceFile = File('$dbPath/recipes.db');

      if (!await sourceFile.exists()) {
        log("Database file not found");
        return null;
      }

      final directory = Directory('/storage/emulated/0/Download');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final destPath = '${directory.path}/data_keeper_$timestamp.db';

      final copiedFile = await sourceFile.copy(destPath);

      log("Database exported to: $destPath");
      return destPath;
    } catch (e) {
      log("Error exporting database: $e");
    }
    return null;
  }

  Future<void> replaceDatabase(String newDbPath) async {
    final dbPath = await getDatabasesPath();
    final targetPath = join(dbPath, 'recipes.db');

    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    final newDbFile = File(newDbPath);
    final targetFile = File(targetPath);

    if (await targetFile.exists()) {
      await targetFile.delete();
    }

    await newDbFile.copy(targetPath);

    _database = await _initDB('recipes.db');
    log("Database replaced with uploaded DB.");
  }
}
