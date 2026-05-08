import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
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

  // 4-colour pastel rotation (matches app palette)
  static const _notePalette = [kPrimaryLight, kMintLight, kAmberLight, kCoralLight];
  static const _noteAccents = [kPrimary,      kMint,      kAmber,      kCoral     ];

  Future<void> addNote() async {
    if (_controller.text.trim().isEmpty) return;
    try {
      await _noteService.createNote(text: _controller.text.trim(), subjectId: _selectedSubjectId);
      _controller.clear();
      setState(() => _selectedSubjectId = null);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _deleteNote(String id) async {
    try { await _noteService.deleteNote(id); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
  }

  Future<void> _showEditDialog(NoteModel note) async {
    final editController = TextEditingController(text: note.text);
    String? editSubjectId = note.subjectId;
    final subjects = await _subjectService.getSubjects().first;
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('Edit Note'),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: editController, maxLines: 4,
                decoration: const InputDecoration(hintText: 'Note text...')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              value: editSubjectId,
              decoration: const InputDecoration(labelText: 'Subject'),
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('No subject')),
                ...subjects.map((s) => DropdownMenuItem<String?>(value: s.id, child: Text(s.name))),
              ],
              onChanged: (v) => setDlg(() => editSubjectId = v),
            ),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (editController.text.trim().isEmpty) return;
                await _noteService.updateNote(note.id, text: editController.text.trim(), subjectId: editSubjectId);
                if (ctx.mounted) Navigator.of(ctx).pop();
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
      case _NoteSort.newest: sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt)); break;
      case _NoteSort.oldest: sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt)); break;
      case _NoteSort.az:     sorted.sort((a, b) => a.text.toLowerCase().compareTo(b.text.toLowerCase())); break;
    }
    sorted.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return 0;
    });
    return sorted;
  }

  Future<void> _togglePin(NoteModel note) async {
    try { await _noteService.updateNote(note.id, isPinned: !note.isPinned); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
  }

  void _copyToClipboard(NoteModel note) {
    Clipboard.setData(ClipboardData(text: note.text));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
  }

  void _openNote(NoteModel note, Color accent, Color cardColor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7, minChildSize: 0.4, maxChildSize: 0.95,
        builder: (_, scrollCtrl) => Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: accent, width: 3)),
          ),
          child: Column(children: [
            Center(child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 36, height: 4,
              decoration: BoxDecoration(color: accent.withOpacity(0.4), borderRadius: BorderRadius.circular(2)),
            )),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 8, 4),
              child: Row(children: [
                if (note.isPinned) Icon(Icons.push_pin_rounded, size: 14, color: accent),
                if (note.isPinned) const SizedBox(width: 6),
                Expanded(child: Text(
                  DateFormat('dd MMM yyyy · h:mm a').format(note.createdAt.toDate()),
                  style: TextStyle(fontSize: 12, color: accent, fontWeight: FontWeight.w600),
                )),
                IconButton(icon: Icon(Icons.edit_outlined, color: accent, size: 20),
                    onPressed: () { Navigator.pop(context); _showEditDialog(note); }),
                IconButton(icon: Icon(Icons.copy_outlined, color: accent, size: 20),
                    onPressed: () { _copyToClipboard(note); Navigator.pop(context); }),
              ]),
            ),
            const Divider(height: 1),
            Expanded(child: SingleChildScrollView(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Text(note.text, style: const TextStyle(fontSize: 16, height: 1.6)),
            )),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Notes'),
        centerTitle: true,
        actions: [
          PopupMenuButton<_NoteSort>(
            icon: const Icon(Icons.sort_rounded),
            onSelected: (val) => setState(() => _sort = val),
            itemBuilder: (_) => const [
              PopupMenuItem(value: _NoteSort.newest, child: Text('Newest first')),
              PopupMenuItem(value: _NoteSort.oldest, child: Text('Oldest first')),
              PopupMenuItem(value: _NoteSort.az, child: Text('A → Z')),
            ],
          ),
        ],
      ),
      body: Column(children: [
        // ── Search ───────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => searchQuery = val.toLowerCase()),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded, color: kPrimary),
              hintText: 'Search notes...',
            ),
          ),
        ),
        const SizedBox(height: 10),

        // ── Add note input ───────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: [
            StreamBuilder<List<SubjectModel>>(
              stream: _subjectService.getSubjects(),
              builder: (_, snap) {
                final subjects = snap.data ?? [];
                return DropdownButtonFormField<String?>(
                  value: _selectedSubjectId,
                  decoration: const InputDecoration(labelText: 'Link to subject (optional)'),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('No subject')),
                    ...subjects.map((s) => DropdownMenuItem<String?>(value: s.id, child: Text(s.name))),
                  ],
                  onChanged: (v) => setState(() => _selectedSubjectId = v),
                );
              },
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(hintText: 'Write a new note...'),
                ),
              ),
              const SizedBox(width: 10),
              FloatingActionButton(
                onPressed: addNote,
                mini: true,
                child: const Icon(Icons.add_rounded),
              ),
            ]),
          ]),
        ),
        const SizedBox(height: 10),

        // ── Notes list ──────────────────────────────────────────
        Expanded(
          child: StreamBuilder<List<NoteModel>>(
            stream: _noteService.getNotes(),
            builder: (_, snap) {
              if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: kPrimary));
              }
              final notes = snap.data ?? [];
              final filtered = _applySort(
                  notes.where((n) => n.text.toLowerCase().contains(searchQuery)).toList());

              if (filtered.isEmpty) {
                return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: kPrimaryLight.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.sticky_note_2_rounded, size: 48, color: kPrimary),
                  ),
                  const SizedBox(height: 16),
                  const Text('No notes yet ✍️', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ]));
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final note = filtered[i];
                  final idx = note.id.hashCode.abs() % _notePalette.length;
                  final cardColor = isDark
                      ? _noteAccents[idx].withOpacity(0.1)
                      : _notePalette[idx];
                  final accent = _noteAccents[idx];
                  final textColor = isDark ? Colors.white.withOpacity(0.88) : const Color(0xFF2A2A3D);
                  final subColor  = isDark ? Colors.white38 : Colors.grey[500]!;

                  return GestureDetector(
                    onTap: () => _openNote(note, accent,
                        isDark ? kDarkCard : _notePalette[idx]),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: accent.withOpacity(0.25)),
                        boxShadow: [
                          BoxShadow(color: accent.withOpacity(0.08),
                              blurRadius: 10, offset: const Offset(0, 3))
                        ],
                      ),
                      child: IntrinsicHeight(
                        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          // Left accent bar
                          Container(
                            width: 4,
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(18),
                                bottomLeft: Radius.circular(18),
                              ),
                            ),
                          ),
                          Expanded(child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 12, 8, 10),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                if (note.isPinned) ...[
                                  Icon(Icons.push_pin_rounded, size: 13, color: accent),
                                  const SizedBox(width: 5),
                                ],
                                Expanded(child: Text(
                                  note.text,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                                      color: textColor, height: 1.45),
                                )),
                              ]),
                              const SizedBox(height: 10),
                              Row(children: [
                                if (note.subjectId != null)
                                  FutureBuilder<SubjectModel?>(
                                    future: _subjectService.getSubject(note.subjectId!),
                                    builder: (_, s) {
                                      if (s.data == null) return const SizedBox.shrink();
                                      return Container(
                                        margin: const EdgeInsets.only(right: 8),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                            color: accent.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(20)),
                                        child: Text(s.data!.name,
                                            style: TextStyle(fontSize: 10, color: accent,
                                                fontWeight: FontWeight.w600)),
                                      );
                                    },
                                  ),
                                Text(
                                  DateFormat('dd MMM · h:mm a').format(note.createdAt.toDate()),
                                  style: TextStyle(fontSize: 11, color: subColor),
                                ),
                                const Spacer(),
                                _NoteAction(icon: note.isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                                    color: note.isPinned ? accent : subColor,
                                    tooltip: note.isPinned ? 'Unpin' : 'Pin',
                                    onTap: () => _togglePin(note)),
                                _NoteAction(icon: Icons.copy_outlined, color: subColor, tooltip: 'Copy',
                                    onTap: () => _copyToClipboard(note)),
                                _NoteAction(icon: Icons.edit_outlined, color: subColor, tooltip: 'Edit',
                                    onTap: () => _showEditDialog(note)),
                                _NoteAction(icon: Icons.delete_outline_rounded,
                                    color: kCoral.withOpacity(0.7), tooltip: 'Delete',
                                    onTap: () => _deleteNote(note.id)),
                              ]),
                            ]),
                          )),
                        ]),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _NoteAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _NoteAction({required this.icon, required this.color, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(padding: const EdgeInsets.all(6), child: Icon(icon, size: 17, color: color)),
      ),
    );
  }
}
