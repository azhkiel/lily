import 'package:flutter/material.dart';
import 'home_page.dart';

class NotePage extends StatefulWidget {
  final String username;

  const NotePage({Key? key, this.username = 'User'}) : super(key: key);

  @override
  _NotePageState createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final List<Note> _notes = [
    Note(
      title: 'Surat Terakhir',
      content:
          'Hujan deras mengguyur jendela kamar malam itu. Aku duduk di pojok ranjang, memandangi secarik kertas yang kutemukan di laci tua Ayah. Tangan ini gemetar saat membukanya.',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  List<Note> _filteredNotes = [];

  @override
  void initState() {
    super.initState();
    _filteredNotes = List.from(_notes);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _addNote() {
    if (_noteController.text.trim().isNotEmpty) {
      setState(() {
        _notes.add(
          Note(
            title: 'Catatan Baru',
            content: _noteController.text,
            createdAt: DateTime.now(),
          ),
        );
        _noteController.clear();
        _filterNotes(_searchController.text);
      });
    }
  }

  void _deleteNote(int index) {
    // Find the actual index in the original list
    final originalNote = _filteredNotes[index];
    final originalIndex = _notes.indexOf(originalNote);

    setState(() {
      _notes.removeAt(originalIndex);
      _filterNotes(_searchController.text);
    });
  }

  void _filterNotes(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredNotes = List.from(_notes);
      } else {
        _filteredNotes =
            _notes
                .where(
                  (note) =>
                      note.title.toLowerCase().contains(query.toLowerCase()),
                )
                .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Mentaly',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF3978B8),
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Search bar for finding notes
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Apa yang Anda cari?',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                    onChanged: _filterNotes,
                  ),
                ),
              ],
            ),
          ),

          // List of notes
          Expanded(
            child:
                _filteredNotes.isEmpty
                    ? const Center(
                      child: Text(
                        'Tidak ada catatan ditemukan',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredNotes.length,
                      itemBuilder: (context, index) {
                        final note = _filteredNotes[index];
                        return _buildNoteCard(note, index);
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddNoteDialog();
        },
        backgroundColor: const Color(0xFF3978B8),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildNoteCard(Note note, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFB4DBFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            note.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF3978B8),
            ),
          ),
          const SizedBox(height: 8),
          Text(note.content, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Color(0xFF3978B8)),
                onPressed: () {
                  // Show edit dialog
                  _showEditNoteDialog(note, index);
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 20),
              IconButton(
                icon: const Icon(Icons.share, color: Color(0xFF3978B8)),
                onPressed: () {
                  // Share note functionality
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 20),
              IconButton(
                icon: const Icon(Icons.delete, color: Color(0xFF3978B8)),
                onPressed: () => _deleteNote(index),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddNoteDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController contentController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Tambah Catatan Baru'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Judul',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(
                    labelText: 'Isi',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (titleController.text.trim().isNotEmpty &&
                      contentController.text.trim().isNotEmpty) {
                    setState(() {
                      _notes.add(
                        Note(
                          title: titleController.text,
                          content: contentController.text,
                          createdAt: DateTime.now(),
                        ),
                      );
                      _filterNotes(_searchController.text);
                    });
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3978B8),
                ),
                child: const Text('Simpan'),
              ),
            ],
          ),
    );
  }

  void _showEditNoteDialog(Note note, int index) {
    final TextEditingController titleController = TextEditingController(
      text: note.title,
    );
    final TextEditingController contentController = TextEditingController(
      text: note.content,
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Catatan'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Judul',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(
                    labelText: 'Isi',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Find the actual index in the original list
                  final originalNote = _filteredNotes[index];
                  final originalIndex = _notes.indexOf(originalNote);

                  setState(() {
                    _notes[originalIndex] = Note(
                      title: titleController.text,
                      content: contentController.text,
                      createdAt: note.createdAt,
                      updatedAt: DateTime.now(),
                    );
                    _filterNotes(_searchController.text);
                  });
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3978B8),
                ),
                child: const Text('Simpan'),
              ),
            ],
          ),
    );
  }
}

class Note {
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Note({
    required this.title,
    required this.content,
    required this.createdAt,
    this.updatedAt,
  });
}
