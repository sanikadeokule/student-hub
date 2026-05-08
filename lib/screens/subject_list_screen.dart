import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/subject_model.dart';
import '../services/subject_service.dart';
import '../services/task_service.dart';
import 'subject_detail_screen.dart';

class SubjectListScreen extends StatefulWidget {
  const SubjectListScreen({super.key});

  @override
  State<SubjectListScreen> createState() => _SubjectListScreenState();
}

class _SubjectListScreenState extends State<SubjectListScreen> {
  final SubjectService _subjectService = SubjectService();
  final TaskService _taskService = TaskService();

  // Pastel hex colours that match the app palette
  static const _colorOptions = [
    '#8B8FF8', // kPrimary  - lavender
    '#6ECFBF', // kMint     - mint
    '#FF9AA2', // kCoral    - coral
    '#FECF6A', // kAmber    - amber
    '#B3B7FF', // kPrimaryLight
    '#BEEde8', // kMintLight
    '#FFD5D8', // kCoralLight
    '#FFF0C2', // kAmberLight
  ];

  void _showSubjectDialog({SubjectModel? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    String selectedColor = existing?.color ?? '#8B8FF8';
    final isEditing = existing != null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: Text(isEditing ? 'Edit Subject' : 'New Subject'),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Subject Name', hintText: 'e.g., Mathematics')),
            const SizedBox(height: 12),
            TextField(controller: descCtrl, maxLines: 2,
                decoration: const InputDecoration(labelText: 'Description (optional)')),
            const SizedBox(height: 16),
            const Align(alignment: Alignment.centerLeft,
                child: Text('Colour:', style: TextStyle(fontWeight: FontWeight.w600))),
            const SizedBox(height: 10),
            Wrap(spacing: 10, runSpacing: 10,
              children: _colorOptions.map((hex) {
                final col = Color(int.parse(hex.replaceAll('#', ''), radix: 16) + 0xFF000000);
                final selected = selectedColor.toLowerCase() == hex.toLowerCase();
                return GestureDetector(
                  onTap: () => setDlg(() => selectedColor = hex),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: col,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? const Color(0xFF2A2A3D) : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: selected ? [BoxShadow(color: col.withOpacity(0.5), blurRadius: 8, spreadRadius: 1)] : [],
                    ),
                    child: selected ? const Icon(Icons.check_rounded, color: Colors.white, size: 18) : null,
                  ),
                );
              }).toList(),
            ),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                try {
                  if (isEditing) {
                    await _subjectService.updateSubject(existing.id,
                        name: name, description: descCtrl.text.trim(), color: selectedColor);
                  } else {
                    await _subjectService.createSubject(
                        name: name, description: descCtrl.text.trim(), color: selectedColor);
                  }
                  if (ctx.mounted) {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(isEditing ? 'Subject updated!' : 'Subject created!')));
                  }
                } catch (e) {
                  if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: Text(isEditing ? 'Save' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteSubject(SubjectModel subject) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Subject?'),
        content: Text('Delete "${subject.name}"? Notes and tasks won\'t be deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kCoral, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try { await _subjectService.deleteSubject(subject.id); }
      catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Subjects')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSubjectDialog(),
        child: const Icon(Icons.add_rounded),
      ),
      body: StreamBuilder<List<SubjectModel>>(
        stream: _subjectService.getSubjects(),
        builder: (_, snap) {
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
            return const Center(child: CircularProgressIndicator(color: kPrimary));
          }
          final subjects = snap.data ?? [];

          if (subjects.isEmpty) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(color: kPrimaryLight.withOpacity(0.5), shape: BoxShape.circle),
                child: const Icon(Icons.school_rounded, size: 52, color: kPrimary),
              ),
              const SizedBox(height: 18),
              const Text('No subjects yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Create your first subject to get organised!',
                  style: TextStyle(color: isDark ? Colors.white54 : Colors.grey[500]),
                  textAlign: TextAlign.center),
            ]));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 1.05,
            ),
            itemCount: subjects.length,
            itemBuilder: (_, i) {
              final subject = subjects[i];
              final subjectColor = subject.getColor();

              return Material(
                color: isDark ? kDarkCard : Colors.white,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => SubjectDetailScreen(subject: subject))),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: subjectColor.withOpacity(isDark ? 0.3 : 0.2)),
                      boxShadow: [BoxShadow(color: subjectColor.withOpacity(0.1),
                          blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: subjectColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12)),
                          child: Icon(Icons.book_rounded, color: subjectColor, size: 20),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => _showSubjectDialog(existing: subject),
                          child: Icon(Icons.edit_rounded, size: 17,
                              color: isDark ? Colors.white38 : Colors.grey[400]),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => _deleteSubject(subject),
                          child: Icon(Icons.delete_outline_rounded, size: 17, color: kCoral.withOpacity(0.7)),
                        ),
                      ]),
                      const SizedBox(height: 10),
                      Text(subject.name,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14,
                              color: isDark ? Colors.white : const Color(0xFF2A2A3D)),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (subject.description.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(subject.description,
                            style: TextStyle(fontSize: 11,
                                color: isDark ? Colors.white38 : Colors.grey[500]),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                      const Spacer(),
                      StreamBuilder<int>(
                        stream: _taskService.getPendingTasksCount(subjectId: subject.id),
                        builder: (_, countSnap) {
                          final count = countSnap.data ?? 0;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: count > 0
                                  ? subjectColor.withOpacity(0.15)
                                  : (isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.1)),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$count pending task${count == 1 ? '' : 's'}',
                              style: TextStyle(
                                fontSize: 10, fontWeight: FontWeight.w600,
                                color: count > 0 ? subjectColor : (isDark ? Colors.white38 : Colors.grey[500]),
                              ),
                            ),
                          );
                        },
                      ),
                    ]),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
