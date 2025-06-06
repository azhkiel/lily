import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/chat.dart';
import '../models/note.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  final int _currentVersion = 3; // Dinaikkan karena ada perubahan struktur

  DatabaseHelper._init();

  // Inisialisasi database jika belum ada
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('chat_app.db');
    return _database!;
  }

  // Inisialisasi database baru atau membuka yang sudah ada
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

  // Membuat tabel di database
  Future _createDB(Database db, int version) async {
    await db.execute(''' 
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL
      )
    ''');

    // Struktur tabel chat yang sudah direvisi
    await db.execute(''' 
      CREATE TABLE chats (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        message_user TEXT NOT NULL,
        message_ai TEXT,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
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

  // Update database schema jika versi berubah
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      // Hapus tabel chat lama dan buat yang baru dengan struktur yang direvisi
      try {
        await db.execute('DROP TABLE IF EXISTS chats');
        await db.execute(''' 
          CREATE TABLE chats (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            message_user TEXT NOT NULL,
            message_ai TEXT,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
          )
        ''');
        print('Chat table structure updated successfully');
      } catch (e) {
        print('Error upgrading chat table: $e');
      }
    }
  }

  // Fungsi untuk membuat user baru
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

  // Fungsi untuk mendapatkan user berdasarkan username
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

  // Fungsi untuk memverifikasi password user
  Future<bool> verifyUserPassword(String username, String password) async {
    final user = await getUser(username);
    if (user == null) return false;
    return user['password'] == password;
  }

  // Fungsi untuk menambah chat baru (user mengirim pesan)
  Future<int> insertUserMessage(int userId, String userMessage) async {
    final db = await instance.database;
    try {
      return await db.insert(
        'chats',
        {
          'user_id': userId,
          'message_user': userMessage,
          'message_ai': null, // AI response akan diisi kemudian
          'timestamp': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('Error inserting user message: $e');
      rethrow;
    }
  }

  // Fungsi untuk update chat dengan balasan AI
  Future<int> updateWithAIResponse(int chatId, String aiMessage) async {
    final db = await instance.database;
    try {
      return await db.update(
        'chats',
        {'message_ai': aiMessage},
        where: 'id = ?',
        whereArgs: [chatId],
      );
    } catch (e) {
      print('Error updating AI response: $e');
      rethrow;
    }
  }

  // Fungsi untuk menambah chat lengkap (user + AI dalam satu transaksi)
  Future<int> insertCompleteChat(int userId, String userMessage, String aiMessage) async {
    final db = await instance.database;
    try {
      return await db.insert(
        'chats',
        {
          'user_id': userId,
          'message_user': userMessage,
          'message_ai': aiMessage,
          'timestamp': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('Error inserting complete chat: $e');
      rethrow;
    }
  }

  // Mengambil semua chat berdasarkan user_id (untuk isolasi chat per user)
  Future<List<Map<String, dynamic>>> getChatsByUser(int userId) async {
    final db = await instance.database;
    try {
      final result = await db.query(
        'chats',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'timestamp ASC', // Urut berdasarkan waktu
      );
      return result;
    } catch (e) {
      print('Error getting chats by user: $e');
      return [];
    }
  }

  // Mengambil chat dengan informasi username (untuk keperluan UI yang lebih lengkap)
  Future<List<Map<String, dynamic>>> getChatsByUserWithUsername(int userId) async {
    final db = await instance.database;
    try {
      final result = await db.rawQuery(''' 
        SELECT c.id, c.user_id, c.message_user, c.message_ai, c.timestamp, 
               u.username
        FROM chats c
        JOIN users u ON c.user_id = u.id
        WHERE c.user_id = ?
        ORDER BY c.timestamp ASC
      ''', [userId]);
      return result;
    } catch (e) {
      print('Error getting chats with username: $e');
      return [];
    }
  }

  // Fungsi untuk menghapus chat tertentu
  Future<int> deleteChat(int chatId, int userId) async {
    final db = await instance.database;
    try {
      return await db.delete(
        'chats',
        where: 'id = ? AND user_id = ?', // Pastikan hanya chat milik user yang bisa dihapus
        whereArgs: [chatId, userId],
      );
    } catch (e) {
      print('Error deleting chat: $e');
      rethrow;
    }
  }

  // Fungsi untuk menghapus semua chat user
  Future<int> deleteAllChatsByUser(int userId) async {
    final db = await instance.database;
    try {
      return await db.delete(
        'chats',
        where: 'user_id = ?',
        whereArgs: [userId],
      );
    } catch (e) {
      print('Error deleting all chats by user: $e');
      rethrow;
    }
  }

  // Fungsi untuk menambah note
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

  // Mengambil semua note berdasarkan userId
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

  // Fungsi untuk memperbarui note
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

  // Fungsi untuk menghapus note
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

  // Fungsi untuk menutup database
  Future<void> close() async {
    final db = await instance.database;
    try {
      await db.close();
      _database = null;
    } catch (e) {
      print('Error closing database: $e');
    }
  }

  // Menghapus database
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

  // Fungsi helper untuk mendapatkan jumlah chat user
  Future<int> getChatCountByUser(int userId) async {
    final db = await instance.database;
    try {
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM chats WHERE user_id = ?',
        [userId]
      );
      return result.first['count'] as int;
    } catch (e) {
      print('Error getting chat count: $e');
      return 0;
    }
  }
}