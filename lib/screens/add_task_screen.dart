import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';
import '../models/subject_model.dart';
import '../services/subject_service.dart';

/// ➕ Add / Edit Task Screen
class AddTaskScreen extends StatefulWidget {
  /// Pass an existing task to enter edit mode; null = create mode.
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF5C6BC0),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a deadline')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final time = _selectedTime ?? const TimeOfDay(hour: 23, minute: 59);
      final deadline = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        time.hour,
        time.minute,
      );

      if (_isEditing) {
        final updated = widget.existingTask!.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          deadline: Timestamp.fromDate(deadline),
          priority: _selectedPriority,
          subjectId: _selectedSubjectId,
          recurrence: _recurrence,
        );
        await _taskService.updateTask(updated.id, updated);
      } else {
        final task = TaskModel(
          id: '',
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          deadline: Timestamp.fromDate(deadline),
          priority: _selectedPriority,
          isCompleted: false,
          createdAt: Timestamp.now(),
          subjectId: _selectedSubjectId,
          recurrence: _recurrence,
        );
        await _taskService.addTask(task);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditing ? 'Task updated!' : 'Task added!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Task' : 'New Task'),
        backgroundColor: const Color(0xFFF5F7FA),
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('Title *'),
                TextFormField(
                  controller: _titleController,
                  style: const TextStyle(color: Colors.black87),
                  decoration: _inputDecoration('e.g. Submit Math Assignment'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Title is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                _buildLabel('Description'),
                TextFormField(
                  controller: _descriptionController,
                  style: const TextStyle(color: Colors.black87),
                  decoration: _inputDecoration('e.g. Chapter 5 problems 1-10'),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),

                // Quick date presets
                _buildLabel('Deadline *'),
                Row(
                  children: [
                    _presetChip('Today', () {
                      setState(() => _selectedDate = DateTime.now());
                    }),
                    const SizedBox(width: 8),
                    _presetChip('Tomorrow', () {
                      setState(() => _selectedDate =
                          DateTime.now().add(const Duration(days: 1)));
                    }),
                    const SizedBox(width: 8),
                    _presetChip('Next Week', () {
                      setState(() => _selectedDate =
                          DateTime.now().add(const Duration(days: 7)));
                    }),
                  ],
                ),
                const SizedBox(height: 8),

                // Date + Time row
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _pickDate,
                        child: _pickerBox(
                          icon: Icons.calendar_today,
                          text: _selectedDate == null
                              ? 'Select date'
                              : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                          hasValue: _selectedDate != null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: _pickTime,
                        child: _pickerBox(
                          icon: Icons.access_time,
                          text: _selectedTime == null
                              ? 'Select time'
                              : _selectedTime!.format(context),
                          hasValue: _selectedTime != null,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                _buildLabel('Priority'),
                Row(
                  children: TaskPriority.values.map((priority) {
                    final color = Color(TaskModel.getPriorityColor(priority));
                    final isSelected = _selectedPriority == priority;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _selectedPriority = priority),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withOpacity(0.1)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? color
                                  : Colors.grey.withOpacity(0.25),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                priority.name[0].toUpperCase() +
                                    priority.name.substring(1),
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.black87
                                      : Colors.grey[600],
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                _buildLabel('Repeat'),
                DropdownButtonFormField<String>(
                  value: _recurrence,
                  decoration: _inputDecoration(''),
                  items: ['None', 'Daily', 'Weekly'].map((r) {
                    return DropdownMenuItem(value: r, child: Text(r));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _recurrence = val);
                  },
                ),
                const SizedBox(height: 20),

                _buildLabel('Link to Subject'),
                StreamBuilder<List<SubjectModel>>(
                  stream: _subjectService.getSubjects(),
                  builder: (context, snapshot) {
                    final subjects = snapshot.data ?? [];
                    return DropdownButtonFormField<String?>(
                      value: _selectedSubjectId,
                      decoration: _inputDecoration('Select a subject (optional)'),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('No subject'),
                        ),
                        ...subjects.map((subject) => DropdownMenuItem<String?>(
                              value: subject.id,
                              child: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: subject.getColor(),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(subject.name),
                                ],
                              ),
                            )),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedSubjectId = value);
                      },
                    );
                  },
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveTask,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5C6BC0),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 4,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _isEditing ? 'Save Changes' : 'Save Task',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _presetChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: onTap,
      backgroundColor: const Color(0xFF5C6BC0).withOpacity(0.1),
      side: const BorderSide(color: Color(0xFF5C6BC0), width: 0.5),
    );
  }

  Widget _pickerBox({
    required IconData icon,
    required String text,
    required bool hasValue,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: hasValue ? Colors.black87 : Colors.grey[500],
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black54,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400]),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.25)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Color(0xFF5C6BC0)),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Colors.redAccent),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
