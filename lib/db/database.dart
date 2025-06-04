import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/chat.dart';
import '../models/note.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  final int _currentVersion = 2;

  DatabaseHelper._init();

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

  // Membuat tabel users, chats, notes dengan foreign key dan constraints
  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL
      )
    ''');

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

    await db.execute('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
  }

  // Upgrade DB untuk menambahkan kolom is_ai di tabel chats versi 2
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE chats ADD COLUMN is_ai INTEGER DEFAULT 0');
      } catch (e) {
        print('Kolom is_ai mungkin sudah ada: $e');
      }
    }
    // Tambahkan migrasi versi berikutnya di sini jika diperlukan
  }

  // USER OPERATIONS
  Future<int> createUser(String username, String password) async {
    final db = await instance.database;
    try {
      return await db.insert(
        'users',
        {'username': username, 'password': password},
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

  // CHAT OPERATIONS
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

  /// Ambil chat antara dua user beserta username pengirim dan penerima
  Future<List<Map<String, dynamic>>> getChatsWithUsernames(int userId, int otherUserId) async {
    final db = await instance.database;
    try {
      final result = await db.rawQuery('''
        SELECT c.id, c.message, c.timestamp, c.is_ai,
               sender.id AS sender_id, sender.username AS sender_username,
               receiver.id AS receiver_id, receiver.username AS receiver_username
        FROM chats c
        JOIN users sender ON c.sender_id = sender.id
        JOIN users receiver ON c.receiver_id = receiver.id
        WHERE (c.sender_id = ? AND c.receiver_id = ?) OR (c.sender_id = ? AND c.receiver_id = ?)
        ORDER BY c.timestamp ASC
      ''', [userId, otherUserId, otherUserId, userId]);
      return result;
    } catch (e) {
      print('Error getting chats with usernames: $e');
      return [];
    }
  }

  // NOTES OPERATIONS
  Future<int> insertNote(Note note) async {
    final db = await instance.database;
    try {
      return await db.insert(
        'notes',
        note.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('Error inserting note: $e');
      rethrow;
    }
  }

  /// Ambil semua notes beserta username usernya berdasarkan userId
  Future<List<Map<String, dynamic>>> getNotesWithUser(int userId) async {
    final db = await instance.database;
    try {
      final result = await db.rawQuery('''
        SELECT n.id, n.title, n.content, n.created_at, n.updated_at,
               u.id AS user_id, u.username
        FROM notes n
        JOIN users u ON n.user_id = u.id
        WHERE n.user_id = ?
        ORDER BY n.created_at DESC
      ''', [userId]);
      return result;
    } catch (e) {
      print('Error getting notes with user: $e');
      return [];
    }
  }

  Future<int> updateNote(Note note) async {
    final db = await instance.database;
    try {
      return await db.update(
        'notes',
        note.toMap(),
        where: 'id = ?',
        whereArgs: [note.id],
      );
    } catch (e) {
      print('Error updating note: $e');
      rethrow;
    }
  }

  Future<int> deleteNote(int noteId) async {
    final db = await instance.database;
    try {
      return await db.delete(
        'notes',
        where: 'id = ?',
        whereArgs: [noteId],
      );
    } catch (e) {
      print('Error deleting note: $e');
      rethrow;
    }
  }

  // GENERIC UPDATE & DELETE
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

  // DB INSPECTION
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

  // Close & Delete DB
  Future<void> close() async {
    final db = await instance.database;
    try {
      await db.close();
      _database = null;
    } catch (e) {
      print('Error closing database: $e');
    }
  }

  Future<void> deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'chat_app.db');
    try {
      await databaseFactory.deleteDatabase(path);
      _database = null;
      print('Database deleted successfully');
    } catch (e) {
      print('Error deleting database: $e');
      rethrow;
    }
  }
}
