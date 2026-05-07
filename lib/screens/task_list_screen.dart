import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';
import 'add_task_screen.dart';

class TaskListScreen extends StatefulWidget {
  final String? subjectId;

  const TaskListScreen({super.key, this.subjectId});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final TaskService _taskService = TaskService();
  bool _showCompleted = false;
  String _searchQuery = '';
  TaskPriority? _filterPriority; // null = show all

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddTaskScreen()),
        ),
        backgroundColor: const Color(0xFF5C6BC0),
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
      body: SafeArea(
        child: StreamBuilder<List<TaskModel>>(
          stream: _taskService.getTasksStream(subjectId: widget.subjectId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text('Error loading tasks:\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red)),
              );
            }

            final allTasks = snapshot.data ?? [];

            // Apply search + priority filter
            final tasks = allTasks.where((t) {
              final matchesSearch = _searchQuery.isEmpty ||
                  t.title.toLowerCase().contains(_searchQuery) ||
                  t.description.toLowerCase().contains(_searchQuery);
              final matchesPriority =
                  _filterPriority == null || t.priority == _filterPriority;
              return matchesSearch && matchesPriority;
            }).toList();

            final dueToday =
                tasks.where((t) => t.isDueToday() && !t.isCompleted).toList();
            final upcoming =
                tasks.where((t) => !t.isDueToday() && !t.isCompleted).toList();
            final completed = tasks.where((t) => t.isCompleted).toList();

            return CustomScrollView(
              slivers: [
                // Header row
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Row(
                      children: [
                        const Text(
                          'My Tasks',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        StreamBuilder<int>(
                          stream: _taskService.getPendingTasksCount(
                              subjectId: widget.subjectId),
                          builder: (context, countSnap) {
                            final count = countSnap.data ?? 0;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF5C6BC0).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '$count pending',
                                style: const TextStyle(
                                  color: Color(0xFF5C6BC0),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Search bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: TextField(
                      onChanged: (v) =>
                          setState(() => _searchQuery = v.toLowerCase()),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search, size: 20),
                        hintText: 'Search tasks...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),

                // Priority filter chips
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _filterChip('All', null),
                          const SizedBox(width: 8),
                          _filterChip('High', TaskPriority.high,
                              color: const Color(0xFFE53935)),
                          const SizedBox(width: 8),
                          _filterChip('Medium', TaskPriority.medium,
                              color: const Color(0xFFFB8C00)),
                          const SizedBox(width: 8),
                          _filterChip('Low', TaskPriority.low,
                              color: const Color(0xFF43A047)),
                        ],
                      ),
                    ),
                  ),
                ),

                if (tasks.isEmpty)
                  const SliverFillRemaining(child: _EmptyStateWidget()),

                if (dueToday.isNotEmpty) ...[
                  _buildSectionHeader('Due Today', Icons.today),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _TaskCard(
                        task: dueToday[index],
                        onToggle: _taskService.toggleTaskCompletion,
                        onDelete: _taskService.deleteTask,
                      ),
                      childCount: dueToday.length,
                    ),
                  ),
                ],

                if (upcoming.isNotEmpty) ...[
                  _buildSectionHeader('Upcoming', Icons.calendar_today),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _TaskCard(
                        task: upcoming[index],
                        onToggle: _taskService.toggleTaskCompletion,
                        onDelete: _taskService.deleteTask,
                      ),
                      childCount: upcoming.length,
                    ),
                  ),
                ],

                if (completed.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _showCompleted = !_showCompleted),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: Row(
                          children: [
                            Icon(
                              _showCompleted
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Completed (${completed.length})',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_showCompleted)
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _TaskCard(
                          task: completed[index],
                          onToggle: _taskService.toggleTaskCompletion,
                          onDelete: _taskService.deleteTask,
                        ),
                        childCount: completed.length,
                      ),
                    ),
                ],

                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _filterChip(String label, TaskPriority? priority, {Color? color}) {
    final isSelected = _filterPriority == priority;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _filterPriority = priority),
      selectedColor: (color ?? const Color(0xFF5C6BC0)).withOpacity(0.2),
      checkmarkColor: color ?? const Color(0xFF5C6BC0),
      labelStyle: TextStyle(
        color: isSelected ? (color ?? const Color(0xFF5C6BC0)) : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final TaskModel task;
  final Future<void> Function(String, bool) onToggle;
  final Future<void> Function(String) onDelete;

  const _TaskCard({
    required this.task,
    required this.onToggle,
    required this.onDelete,
  });

  void _openEdit(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddTaskScreen(existingTask: task)),
    );
  }

  void _showDetail(BuildContext context) {
    final dateFormatter = DateFormat('MMM dd, yyyy – hh:mm a');
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task.title,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(task.description, style: TextStyle(color: Colors.grey[700])),
            ],
            const SizedBox(height: 12),
            _detailRow(Icons.event, 'Due: ${dateFormatter.format(task.deadline.toDate())}'),
            _detailRow(Icons.flag_outlined,
                'Priority: ${task.priority.name[0].toUpperCase()}${task.priority.name.substring(1)}'),
            if (task.recurrence != 'None')
              _detailRow(Icons.repeat, 'Repeats: ${task.recurrence}'),
            _detailRow(
                task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                task.isCompleted ? 'Completed' : 'Pending'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: Colors.grey[800]))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final priorityColor = Color(TaskModel.getPriorityColor(task.priority));
    final dateFormatter = DateFormat('MMM dd, yyyy');
    final isOverdue = task.isOverdue();

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(task.id),
      child: GestureDetector(
        onTap: () => _showDetail(context),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: isOverdue
                  ? Colors.red.withOpacity(0.4)
                  : Colors.grey.withOpacity(0.15),
            ),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Checkbox(
              value: task.isCompleted,
              activeColor: Colors.green,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4)),
              onChanged: (_) => onToggle(task.id, task.isCompleted),
            ),
            title: Text(
              task.title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                decoration: task.isCompleted
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
                color: task.isCompleted ? Colors.grey[400] : Colors.black87,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (task.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      task.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Icon(
                        isOverdue ? Icons.warning_amber_rounded : Icons.event,
                        size: 14,
                        color: isOverdue ? Colors.red[700] : Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dateFormatter.format(task.deadline.toDate()),
                        style: TextStyle(
                          fontSize: 12,
                          color: isOverdue
                              ? Colors.red[700]
                              : Colors.grey[600],
                          fontWeight: isOverdue
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      if (isOverdue) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'OVERDUE',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.red[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      if (task.recurrence != 'None') ...[
                        const SizedBox(width: 6),
                        Icon(Icons.repeat, size: 12, color: Colors.grey[400]),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                      color: priorityColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => _openEdit(context),
                  child: const Icon(Icons.edit_outlined,
                      size: 18, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyStateWidget extends StatelessWidget {
  const _EmptyStateWidget();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: const Color(0xFF5C6BC0).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.task_alt,
                  size: 56, color: Color(0xFF5C6BC0)),
            ),
            const SizedBox(height: 24),
            const Text(
              'All clear!',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              'You have no tasks yet.\nTap + to add your first one.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}
