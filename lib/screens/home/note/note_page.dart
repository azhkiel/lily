import 'package:flutter/material.dart';
import 'package:mentaly/db/database.dart';
import 'package:mentaly/models/note.dart';

class NotepadListScreen extends StatefulWidget {
  final int userId;

  const NotepadListScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _NotepadListScreenState createState() => _NotepadListScreenState();
}

class _NotepadListScreenState extends State<NotepadListScreen> {
  late Future<List<Note>> _notesFuture;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  // Function to load notes from the database
  void _loadNotes() {
    _notesFuture = DatabaseHelper.instance
        .getNotesWithUser(widget.userId)
        .then((maps) => maps.map((map) {
              return Note(
                id: map['id'] as int?,
                userId: map['user_id'] as int,
                title: map['title'] as String,
                content: map['content'] as String,
                createdAt: DateTime.parse(map['created_at'] as String),
                updatedAt: DateTime.parse(map['updated_at'] as String),
              );
            }).toList());
  }

  // Function to refresh the list after add or delete action
  void _refreshNotes() {
    setState(() {
      _loadNotes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _navigateToAddEditNoteScreen();
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Note>>(
        future: _notesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No notes available.'));
          } else {
            final notes = snapshot.data!;
            return ListView.builder(
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                return _buildNoteListTile(note);
              },
            );
          }
        },
      ),
    );
  }

  // Function to navigate to Add or Edit Note screen
  void _navigateToAddEditNoteScreen({Note? note}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditNoteScreen(
          userId: widget.userId,
          note: note,
        ),
      ),
    ).then((_) => _refreshNotes());
  }

  // Function to build note list tile
  Widget _buildNoteListTile(Note note) {
    return ListTile(
      title: Text(note.title),
      subtitle: Text(
        note.content,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () {
        _navigateToAddEditNoteScreen(note: note);
      },
      trailing: IconButton(
        icon: const Icon(Icons.delete),
        onPressed: () async {
          await DatabaseHelper.instance.deleteNote(note.id!);
          _refreshNotes();
        },
      ),
    );
  }
}

class AddEditNoteScreen extends StatefulWidget {
  final int userId;
  final Note? note;

  const AddEditNoteScreen({
    Key? key,
    required this.userId,
    this.note,
  }) : super(key: key);

  @override
  _AddEditNoteScreenState createState() => _AddEditNoteScreenState();
}

class _AddEditNoteScreenState extends State<AddEditNoteScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // Function to save the note
  Future<void> _saveNote() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and content cannot be empty.')),
      );
      return;
    }

    final note = Note(
      id: widget.note?.id,
      userId: widget.userId,
      title: title,
      content: content,
      createdAt: widget.note?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (widget.note == null) {
      await DatabaseHelper.instance.insertNote(note);
    } else {
      await DatabaseHelper.instance.updateNote(note);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? 'Add Note' : 'Edit Note'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveNote,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _contentController,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
