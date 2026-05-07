import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import '../models/note_model.dart';
import '../services/note_service.dart';
import '../models/subject_model.dart';
import '../services/subject_service.dart';

enum _NoteSort { newest, oldest, az }

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final NoteService _noteService = NoteService();
  final SubjectService _subjectService = SubjectService();

  String searchQuery = '';
  String? _selectedSubjectId;
  _NoteSort _sort = _NoteSort.newest;

  Future<void> addNote() async {
    if (_controller.text.trim().isEmpty) return;
    try {
      await _noteService.createNote(
        text: _controller.text.trim(),
        subjectId: _selectedSubjectId,
      );
      _controller.clear();
      setState(() => _selectedSubjectId = null);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error adding note: $e')));
      }
    }
  }

  Future<void> _deleteNote(String id) async {
    try {
      await _noteService.deleteNote(id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error deleting note: $e')));
      }
    }
  }

  Future<void> _showEditDialog(NoteModel note) async {
    final editController = TextEditingController(text: note.text);
    String? editSubjectId = note.subjectId;

    final subjects = await _subjectService.getSubjects().first;

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('Edit Note'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: editController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Note text...',
                    filled: true,
                    fillColor: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  value: editSubjectId,
                  decoration: const InputDecoration(labelText: 'Subject'),
                  items: [
                    const DropdownMenuItem<String?>(
                        value: null, child: Text('No subject')),
                    ...subjects.map((s) => DropdownMenuItem<String?>(
                        value: s.id, child: Text(s.name))),
                  ],
                  onChanged: (v) => setDlgState(() => editSubjectId = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5C6BC0),
                  foregroundColor: Colors.white),
              onPressed: () async {
                if (editController.text.trim().isEmpty) return;
                try {
                  await _noteService.updateNote(
                    note.id,
                    text: editController.text.trim(),
                    subjectId: editSubjectId,
                  );
                  if (ctx.mounted) Navigator.of(ctx).pop();
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text('Error updating note: $e')));
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    editController.dispose();
  }

  List<NoteModel> _applySort(List<NoteModel> notes) {
    final sorted = List<NoteModel>.from(notes);
    switch (_sort) {
      case _NoteSort.newest:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case _NoteSort.oldest:
        sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case _NoteSort.az:
        sorted.sort((a, b) =>
            a.text.toLowerCase().compareTo(b.text.toLowerCase()));
    }
    // Pinned notes always float to top
    sorted.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return 0;
    });
    return sorted;
  }

  Future<void> _togglePin(NoteModel note) async {
    try {
      await _noteService.updateNote(note.id, isPinned: !note.isPinned);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _copyToClipboard(NoteModel note) {
    Clipboard.setData(ClipboardData(text: note.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Note copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('My Notes', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          PopupMenuButton<_NoteSort>(
            icon: const Icon(Icons.sort),
            onSelected: (val) => setState(() => _sort = val),
            itemBuilder: (_) => const [
              PopupMenuItem(value: _NoteSort.newest, child: Text('Newest first')),
              PopupMenuItem(value: _NoteSort.oldest, child: Text('Oldest first')),
              PopupMenuItem(value: _NoteSort.az, child: Text('A → Z')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => searchQuery = val.toLowerCase()),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search notes...',
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Add note box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                StreamBuilder<List<SubjectModel>>(
                  stream: _subjectService.getSubjects(),
                  builder: (context, snapshot) {
                    final subjects = snapshot.data ?? [];
                    return DropdownButtonFormField<String?>(
                      value: _selectedSubjectId,
                      decoration: InputDecoration(
                        labelText: 'Link to Subject (Optional)',
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                            value: null, child: Text('No subject')),
                        ...subjects.map((s) => DropdownMenuItem<String?>(
                            value: s.id, child: Text(s.name))),
                      ],
                      onChanged: (v) => setState(() => _selectedSubjectId = v),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: 'Write a new note...',
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    FloatingActionButton(
                      onPressed: addNote,
                      backgroundColor: const Color(0xFF5C6BC0),
                      child: const Icon(Icons.add),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Notes list
          Expanded(
            child: StreamBuilder<List<NoteModel>>(
              stream: _noteService.getNotes(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final notes = snapshot.data ?? [];
                final filtered = _applySort(notes
                    .where((n) => n.text.toLowerCase().contains(searchQuery))
                    .toList());

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('No notes found ✍️', style: TextStyle(fontSize: 16)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final note = filtered[i];
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: ListTile(
                        leading: note.isPinned
                            ? const Icon(Icons.push_pin,
                                color: Color(0xFF5C6BC0), size: 18)
                            : null,
                        title: Text(
                          note.text,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        subtitle: note.subjectId != null
                            ? FutureBuilder<SubjectModel?>(
                                future: _subjectService
                                    .getSubject(note.subjectId!),
                                builder: (context, snap) {
                                  if (snap.hasData && snap.data != null) {
                                    return Text(
                                      'Subject: ${snap.data!.name}',
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              )
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                note.isPinned
                                    ? Icons.push_pin
                                    : Icons.push_pin_outlined,
                                color: note.isPinned
                                    ? const Color(0xFF5C6BC0)
                                    : Colors.grey,
                                size: 20,
                              ),
                              tooltip: note.isPinned ? 'Unpin' : 'Pin',
                              onPressed: () => _togglePin(note),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy_outlined,
                                  color: Colors.blueGrey, size: 20),
                              tooltip: 'Copy to clipboard',
                              onPressed: () => _copyToClipboard(note),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined,
                                  color: Colors.blueGrey, size: 20),
                              onPressed: () => _showEditDialog(note),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.red, size: 20),
                              onPressed: () => _deleteNote(note.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
