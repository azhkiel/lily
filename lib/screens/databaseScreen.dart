import 'package:flutter/material.dart';
import 'package:mentaly/db/database.dart';
import '../models/note.dart';

class DatabaseManagementScreen extends StatefulWidget {
  @override
  _DatabaseManagementScreenState createState() => _DatabaseManagementScreenState();
}

class _DatabaseManagementScreenState extends State<DatabaseManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Controllers untuk form
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _aiResponseController = TextEditingController();
  final TextEditingController _noteTitleController = TextEditingController();
  final TextEditingController _noteContentController = TextEditingController();

  // Data lists
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _chats = [];
  List<Map<String, dynamic>> _notes = [];
  
  int? _selectedUserId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _messageController.dispose();
    _aiResponseController.dispose();
    _noteTitleController.dispose();
    _noteContentController.dispose();
    super.dispose();
  }

  // Load semua data dari database
  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    await _loadUsers();
    if (_selectedUserId != null) {
      await _loadChats();
      await _loadNotes();
    }
    setState(() => _isLoading = false);
  }

  // Load data users
  Future<void> _loadUsers() async {
    try {
      final db = await _dbHelper.database;
      final result = await db.query('users');
      setState(() {
        _users = result;
        if (_users.isNotEmpty && _selectedUserId == null) {
          _selectedUserId = _users.first['id'];
        }
      });
    } catch (e) {
      _showErrorDialog('Error loading users: $e');
    }
  }

  // Load data chats
  Future<void> _loadChats() async {
    if (_selectedUserId == null) return;
    try {
      final chats = await _dbHelper.getChatsByUserWithUsername(_selectedUserId!);
      setState(() => _chats = chats);
    } catch (e) {
      _showErrorDialog('Error loading chats: $e');
    }
  }

  // Load data notes
  Future<void> _loadNotes() async {
    if (_selectedUserId == null) return;
    try {
      final notes = await _dbHelper.getNotesWithUser(_selectedUserId!);
      setState(() => _notes = notes);
    } catch (e) {
      _showErrorDialog('Error loading notes: $e');
    }
  }

  // Show error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  // Clear form controllers
  void _clearControllers() {
    _usernameController.clear();
    _passwordController.clear();
    _messageController.clear();
    _aiResponseController.clear();
    _noteTitleController.clear();
    _noteContentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Database Management'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'Users', icon: Icon(Icons.people)),
            Tab(text: 'Chats', icon: Icon(Icons.chat)),
            Tab(text: 'Notes', icon: Icon(Icons.note)),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildUsersTab(),
                _buildChatsTab(),
                _buildNotesTab(),
              ],
            ),
    );
  }

  // Tab untuk mengelola Users
  Widget _buildUsersTab() {
    return Column(
      children: [
        // Form untuk menambah user
        Container(
          padding: EdgeInsets.all(16),
          color: Colors.grey[100],
          child: Column(
            children: [
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: _addUser,
                child: Text('Add User'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        // List users
        Expanded(
          child: ListView.builder(
            itemCount: _users.length,
            itemBuilder: (context, index) {
              final user = _users[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Text(user['username'][0].toUpperCase()),
                  ),
                  title: Text(user['username']),
                  subtitle: Text('ID: ${user['id']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.visibility, color: Colors.green),
                        onPressed: () => _selectUser(user['id']),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteUser(user['id']),
                      ),
                    ],
                  ),
                  selected: _selectedUserId == user['id'],
                  selectedTileColor: Colors.blue[50],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Tab untuk mengelola Chats
  Widget _buildChatsTab() {
    return Column(
      children: [
        // User selector dan form
        Container(
          padding: EdgeInsets.all(16),
          color: Colors.grey[100],
          child: Column(
            children: [
              DropdownButtonFormField<int>(
                value: _selectedUserId,
                decoration: InputDecoration(
                  labelText: 'Select User',
                  border: OutlineInputBorder(),
                ),
                items: _users.map((user) {
                  return DropdownMenuItem<int>(
                    value: user['id'],
                    child: Text(user['username']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedUserId = value);
                  _loadChats();
                },
              ),
              SizedBox(height: 8),
              TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  labelText: 'User Message',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              SizedBox(height: 8),
              TextField(
                controller: _aiResponseController,
                decoration: InputDecoration(
                  labelText: 'AI Response',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: _selectedUserId != null ? _addChat : null,
                child: Text('Add Chat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        // List chats
        Expanded(
          child: ListView.builder(
            itemCount: _chats.length,
            itemBuilder: (context, index) {
              final chat = _chats[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ExpansionTile(
                  title: Text('Chat #${chat['id']}'),
                  subtitle: Text('${chat['timestamp']}'),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteChat(chat['id']),
                  ),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('User: ${chat['message_user']}',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Text('AI: ${chat['message_ai'] ?? 'No response'}'),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Tab untuk mengelola Notes
  Widget _buildNotesTab() {
    return Column(
      children: [
        // Form untuk menambah note
        Container(
          padding: EdgeInsets.all(16),
          color: Colors.grey[100],
          child: Column(
            children: [
              DropdownButtonFormField<int>(
                value: _selectedUserId,
                decoration: InputDecoration(
                  labelText: 'Select User',
                  border: OutlineInputBorder(),
                ),
                items: _users.map((user) {
                  return DropdownMenuItem<int>(
                    value: user['id'],
                    child: Text(user['username']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedUserId = value);
                  _loadNotes();
                },
              ),
              SizedBox(height: 8),
              TextField(
                controller: _noteTitleController,
                decoration: InputDecoration(
                  labelText: 'Note Title',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _noteContentController,
                decoration: InputDecoration(
                  labelText: 'Note Content',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: _selectedUserId != null ? _addNote : null,
                child: Text('Add Note'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        // List notes
        Expanded(
          child: ListView.builder(
            itemCount: _notes.length,
            itemBuilder: (context, index) {
              final note = _notes[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ExpansionTile(
                  title: Text(note['title']),
                  subtitle: Text('Created: ${note['created_at']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editNote(note),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteNote(note['id']),
                      ),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Content:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(note['content']),
                          SizedBox(height: 8),
                          Text('Updated: ${note['updated_at']}',
                              style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // CRUD Operations

  // Add User
  Future<void> _addUser() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      _showErrorDialog('Please fill all fields');
      return;
    }

    try {
      await _dbHelper.createUser(_usernameController.text, _passwordController.text);
      _clearControllers();
      _loadUsers();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User added successfully')),
      );
    } catch (e) {
      _showErrorDialog('Error adding user: $e');
    }
  }

  // Select User
  void _selectUser(int userId) {
    setState(() => _selectedUserId = userId);
    _loadChats();
    _loadNotes();
  }

  // Delete User
  Future<void> _deleteUser(int userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Delete'),
        content: Text('Are you sure you want to delete this user? This will also delete all their chats and notes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final db = await _dbHelper.database;
        await db.delete('users', where: 'id = ?', whereArgs: [userId]);
        if (_selectedUserId == userId) {
          _selectedUserId = null;
        }
        _loadAllData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User deleted successfully')),
        );
      } catch (e) {
        _showErrorDialog('Error deleting user: $e');
      }
    }
  }

  // Add Chat
  Future<void> _addChat() async {
    if (_messageController.text.isEmpty) {
      _showErrorDialog('Please enter user message');
      return;
    }

    try {
      await _dbHelper.insertCompleteChat(
        _selectedUserId!,
        _messageController.text,
        _aiResponseController.text.isEmpty ? 'No response' : _aiResponseController.text,
      );
      _messageController.clear();
      _aiResponseController.clear();
      _loadChats();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chat added successfully')),
      );
    } catch (e) {
      _showErrorDialog('Error adding chat: $e');
    }
  }

  // Delete Chat
  Future<void> _deleteChat(int chatId) async {
    try {
      await _dbHelper.deleteChat(chatId, _selectedUserId!);
      _loadChats();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chat deleted successfully')),
      );
    } catch (e) {
      _showErrorDialog('Error deleting chat: $e');
    }
  }

  // Add Note
  Future<void> _addNote() async {
    if (_noteTitleController.text.isEmpty || _noteContentController.text.isEmpty) {
      _showErrorDialog('Please fill all fields');
      return;
    }

    try {
      final note = Note(
        userId: _selectedUserId!,
        title: _noteTitleController.text,
        content: _noteContentController.text,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _dbHelper.insertNote(note);
      _noteTitleController.clear();
      _noteContentController.clear();
      _loadNotes();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Note added successfully')),
      );
    } catch (e) {
      _showErrorDialog('Error adding note: $e');
    }
  }

  // Edit Note
  Future<void> _editNote(Map<String, dynamic> noteData) async {
    _noteTitleController.text = noteData['title'];
    _noteContentController.text = noteData['content'];

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _noteTitleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _noteContentController,
              decoration: InputDecoration(labelText: 'Content'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Update'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final note = Note(
          id: noteData['id'],
          userId: noteData['user_id'],
          title: _noteTitleController.text,
          content: _noteContentController.text,
          createdAt: DateTime.parse(noteData['created_at']),
          updatedAt: DateTime.now(),
        );
        await _dbHelper.updateNote(note);
        _loadNotes();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Note updated successfully')),
        );
      } catch (e) {
        _showErrorDialog('Error updating note: $e');
      }
    }
    _clearControllers();
  }

  // Delete Note
  Future<void> _deleteNote(int noteId) async {
    try {
      await _dbHelper.deleteNote(noteId);
      _loadNotes();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Note deleted successfully')),
      );
    } catch (e) {
      _showErrorDialog('Error deleting note: $e');
    }
  }
}