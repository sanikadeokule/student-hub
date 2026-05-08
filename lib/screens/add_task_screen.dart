import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/app_theme.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';
import '../models/subject_model.dart';
import '../services/subject_service.dart';

class AddTaskScreen extends StatefulWidget {
  final TaskModel? existingTask;
  const AddTaskScreen({super.key, this.existingTask});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final TaskService _taskService = TaskService();
  final SubjectService _subjectService = SubjectService();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  TaskPriority _selectedPriority = TaskPriority.medium;
  String? _selectedSubjectId;
  String _recurrence = 'None';
  bool _isLoading = false;

  bool get _isEditing => widget.existingTask != null;

  // Priority colours from the palette
  Color _priorityColor(TaskPriority p) {
    switch (p) {
      case TaskPriority.high:   return kCoral;
      case TaskPriority.medium: return kAmber;
      case TaskPriority.low:    return kMint;
    }
  }

  @override
  void initState() {
    super.initState();
    final task = widget.existingTask;
    if (task != null) {
      _titleController.text = task.title;
      _descriptionController.text = task.description;
      final dt = task.deadline.toDate();
      _selectedDate = DateTime(dt.year, dt.month, dt.day);
      _selectedTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
      _selectedPriority = task.priority;
      _selectedSubjectId = task.subjectId;
      _recurrence = task.recurrence;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: _isEditing ? DateTime(2000) : now,
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
        context: context, initialTime: _selectedTime ?? TimeOfDay.now());
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a deadline')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final time = _selectedTime ?? const TimeOfDay(hour: 23, minute: 59);
      final deadline = DateTime(_selectedDate!.year, _selectedDate!.month,
          _selectedDate!.day, time.hour, time.minute);
      if (_isEditing) {
        await _taskService.updateTask(widget.existingTask!.id,
            widget.existingTask!.copyWith(
              title: _titleController.text.trim(),
              description: _descriptionController.text.trim(),
              deadline: Timestamp.fromDate(deadline),
              priority: _selectedPriority,
              subjectId: _selectedSubjectId,
              recurrence: _recurrence,
            ));
      } else {
        await _taskService.addTask(TaskModel(
          id: '',
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          deadline: Timestamp.fromDate(deadline),
          priority: _selectedPriority,
          isCompleted: false,
          createdAt: Timestamp.now(),
          subjectId: _selectedSubjectId,
          recurrence: _recurrence,
        ));
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_isEditing ? 'Task updated!' : 'Task added!')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Task' : 'New Task')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              _label('Title *'),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(hintText: 'e.g. Submit Math Assignment'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
              ),
              const SizedBox(height: 18),

              _label('Description'),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Optional details...'),
              ),
              const SizedBox(height: 18),

              _label('Deadline *'),
              Wrap(spacing: 8, children: [
                _presetChip('Today', () => setState(() => _selectedDate = DateTime.now()), isDark),
                _presetChip('Tomorrow', () => setState(() =>
                    _selectedDate = DateTime.now().add(const Duration(days: 1))), isDark),
                _presetChip('Next Week', () => setState(() =>
                    _selectedDate = DateTime.now().add(const Duration(days: 7))), isDark),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _pickDate,
                    child: _pickerBox(
                      icon: Icons.calendar_today_rounded,
                      text: _selectedDate == null
                          ? 'Select date'
                          : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                      hasValue: _selectedDate != null, isDark: isDark,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: _pickTime,
                    child: _pickerBox(
                      icon: Icons.access_time_rounded,
                      text: _selectedTime == null ? 'Select time' : _selectedTime!.format(context),
                      hasValue: _selectedTime != null, isDark: isDark,
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 18),

              _label('Priority'),
              Row(children: TaskPriority.values.map((p) {
                final col = _priorityColor(p);
                final selected = _selectedPriority == p;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedPriority = p),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: selected ? col.withOpacity(isDark ? 0.25 : 0.12) : (isDark ? kDarkSurface : Colors.white),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: selected ? col : (isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2)),
                            width: selected ? 2 : 1),
                        boxShadow: selected ? [BoxShadow(color: col.withOpacity(0.2), blurRadius: 8)] : [],
                      ),
                      child: Column(children: [
                        Container(
                          width: 12, height: 12,
                          decoration: BoxDecoration(color: col, shape: BoxShape.circle,
                              boxShadow: selected ? [BoxShadow(color: col.withOpacity(0.5), blurRadius: 5, spreadRadius: 1)] : []),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          p.name[0].toUpperCase() + p.name.substring(1),
                          style: TextStyle(
                            color: selected ? col : (isDark ? Colors.white54 : Colors.grey[600]),
                            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                      ]),
                    ),
                  ),
                );
              }).toList()),
              const SizedBox(height: 18),

              _label('Repeat'),
              DropdownButtonFormField<String>(
                value: _recurrence,
                decoration: const InputDecoration(),
                items: ['None', 'Daily', 'Weekly']
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) { if (v != null) setState(() => _recurrence = v); },
              ),
              const SizedBox(height: 18),

              _label('Link to Subject'),
              StreamBuilder<List<SubjectModel>>(
                stream: _subjectService.getSubjects(),
                builder: (_, snap) {
                  final subjects = snap.data ?? [];
                  return DropdownButtonFormField<String?>(
                    value: _selectedSubjectId,
                    decoration: const InputDecoration(hintText: 'Select a subject (optional)'),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('No subject')),
                      ...subjects.map((s) => DropdownMenuItem<String?>(
                        value: s.id,
                        child: Row(children: [
                          Container(width: 10, height: 10,
                              decoration: BoxDecoration(color: s.getColor(), shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Text(s.name),
                        ]),
                      )),
                    ],
                    onChanged: (v) => setState(() => _selectedSubjectId = v),
                  );
                },
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity, height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveTask,
                  child: _isLoading
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : Text(_isEditing ? 'Save Changes' : 'Save Task',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 20),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: TextStyle(
      fontWeight: FontWeight.w600, fontSize: 13,
      color: const Color(0xFF8B8FF8).withOpacity(0.85),
    )),
  );

  Widget _presetChip(String label, VoidCallback onTap, bool isDark) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: onTap,
      backgroundColor: kPrimaryLight.withOpacity(isDark ? 0.25 : 0.5),
      side: const BorderSide(color: kPrimary, width: 0.5),
    );
  }

  Widget _pickerBox({required IconData icon, required String text,
      required bool hasValue, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? kDarkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: hasValue ? kPrimary.withOpacity(0.5) : (isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2))),
      ),
      child: Row(children: [
        Icon(icon, color: hasValue ? kPrimary : (isDark ? Colors.white38 : Colors.grey[400]), size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(text,
            style: TextStyle(
              color: hasValue ? (isDark ? Colors.white : const Color(0xFF2A2A3D)) : (isDark ? Colors.white38 : Colors.grey[400]),
              fontSize: 13,
            ),
            overflow: TextOverflow.ellipsis)),
      ]),
    );
  }
}
