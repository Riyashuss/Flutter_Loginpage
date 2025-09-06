import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static const _databaseName = "MyDatabase.db";
  static const _databaseVersion = 1;

  static const table = 'users';

  static const columnId = '_id';
  static const columnUsername = 'username';
  static const columnPassword = 'password';

  // Make this a singleton class.
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // Only allow a single open connection to the database.
  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Open the database and create the table if it doesn't exist.
  _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(path,
        version: _databaseVersion,
        onCreate: _onCreate);
  }

  // SQL code to create the database table.
  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $table (
            $columnId INTEGER PRIMARY KEY,
            $columnUsername TEXT NOT NULL,
            $columnPassword TEXT NOT NULL
          )
          ''');
  }

  // Helper method to insert a row into the database.
  Future<int> insert(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(table, row);
  }

  // Helper method to retrieve the last user.
  Future<Map<String, dynamic>?> getLastUser() async {
    Database db = await instance.database;
    List<Map<String, dynamic>> results = await db.query(
      table,
      orderBy: '$columnId DESC',
      limit: 1,
    );
    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }
}
