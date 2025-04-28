import 'package:sqflite/sqflite.dart';
import 'package:sqflite/sqflite.dart' as sql;
import 'package:sqflite/sqlite_api.dart';
import 'package:path/path.dart';
import '../models/chat.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  final int _currentVersion = 2; // Versi database saat ini

  DatabaseHelper._init();
  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await instance.database;
    return await db.update(
      table,
      values,
      where: where,
      whereArgs: whereArgs,
    );
  }

  // Tambahkan method delete untuk melengkapi
  Future<int> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await instance.database;
    return await db.delete(
      table,
      where: where,
      whereArgs: whereArgs,
    );
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('chat_app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: _currentVersion,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    // Buat tabel users terlebih dahulu karena chats memiliki foreign key ke users
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL
      )
    ''');

    // Buat tabel chats
    await db.execute('''
      CREATE TABLE chats (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sender_id INTEGER NOT NULL,
        receiver_id INTEGER NOT NULL,
        message TEXT NOT NULL,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
        is_ai INTEGER DEFAULT 0,
        FOREIGN KEY (sender_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (receiver_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Migrasi dari versi 1 ke 2 - tambahkan kolom is_ai jika belum ada
      try {
        await db.execute('ALTER TABLE chats ADD COLUMN is_ai INTEGER DEFAULT 0');
      } catch (e) {
        // Kolom mungkin sudah ada, tidak perlu dilakukan apa-apa
        print('Column is_ai might already exist: $e');
      }
    }
    // Tambahkan migrasi versi lainnya di sini jika diperlukan
  }

  // User operations
  Future<int> createUser(String username, String password) async {
    final db = await instance.database;
    try {
      return await db.insert(
        'users',
        {
          'username': username,
          'password': password,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('Error creating user: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUser(String username) async {
    final db = await instance.database;
    try {
      final result = await db.query(
        'users',
        where: 'username = ?',
        whereArgs: [username],
        limit: 1,
      );
      return result.isNotEmpty ? result.first : null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  // Chat operations
  Future<int> insertChat(Chat chat) async {
    final db = await instance.database;
    try {
      return await db.insert(
        'chats',
        chat.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('Error inserting chat: $e');
      rethrow;
    }
  }

  Future<List<Chat>> getChats(int userId, int otherUserId) async {
    final db = await instance.database;
    try {
      final result = await db.query(
        'chats',
        where: '(sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)',
        whereArgs: [userId, otherUserId, otherUserId, userId],
        orderBy: 'timestamp ASC', // ASC untuk urutan dari yang terlama
      );
      return result.map((json) => Chat.fromMap(json)).toList();
    } catch (e) {
      print('Error getting chats: $e');
      return [];
    }
  }

  // Database inspection methods
  Future<List<String>> getTableNames() async {
    final db = await instance.database;
    try {
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
      );
      return result.map((e) => e['name'] as String).toList();
    } catch (e) {
      print('Error getting table names: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getTableData(String tableName) async {
    final db = await instance.database;
    try {
      return await db.query(tableName);
    } catch (e) {
      print('Error getting table data: $e');
      return [];
    }
  }

  Future<List<Map<String, String>>> getTableStructure(String tableName) async {
    final db = await instance.database;
    try {
      final result = await db.rawQuery('PRAGMA table_info($tableName)');
      return result.map((e) => {
        'name': e['name'] as String,
        'type': e['type'] as String,
        'notnull': (e['notnull'] as int).toString(),
        'dflt_value': e['dflt_value']?.toString() ?? 'NULL',
        'pk': (e['pk'] as int).toString(),
      }).toList();
    } catch (e) {
      print('Error getting table structure: $e');
      return [];
    }
  }

  Future<void> close() async {
    final db = await instance.database;
    try {
      await db.close();
      _database = null;
    } catch (e) {
      print('Error closing database: $e');
    }
  }

  // Method untuk development/debugging
  Future<void> deleteDatabase() async {
  final dbPath = await getDatabasesPath();
  final path = join(dbPath, 'chat_app.db');
  try {
    // Gunakan fungsi deleteDatabase dari package sqflite
    await databaseFactory.deleteDatabase(path);
    _database = null;
    print('Database deleted successfully');
  } catch (e) {
    print('Error deleting database: $e');
    rethrow;
  }
}
}