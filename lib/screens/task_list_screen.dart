import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';
import 'add_task_screen.dart';

// Priority colours pulled from the unified palette
const _kHighColor   = kCoral;
const _kMediumColor = kAmber;
const _kLowColor    = kMint;
const _kAccent      = kPrimary;

Color _priorityColor(TaskPriority p) {
  switch (p) {
    case TaskPriority.high:   return _kHighColor;
    case TaskPriority.medium: return _kMediumColor;
    case TaskPriority.low:    return _kLowColor;
  }
}

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
  TaskPriority? _filterPriority;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? kDarkBg : kLightBg;
    final cardBg = isDark ? kDarkCard : Colors.white;
    final headerGrad = isDark
        ? [const Color(0xFF3D3F8F), const Color(0xFF5558C8)]
        : [kPrimary, const Color(0xFFB3B7FF)];

    return Scaffold(
      backgroundColor: bg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddTaskScreen()),
        ),
        backgroundColor: _kAccent,
        elevation: 6,
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text('Add Task',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
      ),
      body: SafeArea(
        child: StreamBuilder<List<TaskModel>>(
          stream: _taskService.getTasksStream(subjectId: widget.subjectId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const Center(
                  child: CircularProgressIndicator(color: _kAccent));
            }
            if (snapshot.hasError) {
              return Center(
                child: Text('Error loading tasks:\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red)),
              );
            }

            final allTasks = snapshot.data ?? [];
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
                // ── Gradient header ────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: headerGrad,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: _kAccent.withOpacity(isDark ? 0.3 : 0.25),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'My Tasks',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('EEEE, MMM d').format(DateTime.now()),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.75),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        StreamBuilder<int>(
                          stream: _taskService.getPendingTasksCount(
                              subjectId: widget.subjectId),
                          builder: (context, countSnap) {
                            final count = countSnap.data ?? 0;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.35)),
                              ),
                              child: Text(
                                '$count pending',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Search bar ─────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: TextField(
                      onChanged: (v) =>
                          setState(() => _searchQuery = v.toLowerCase()),
                      style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.search_rounded,
                            size: 20,
                            color: isDark ? Colors.white54 : Colors.grey[500]),
                        hintText: 'Search tasks...',
                        hintStyle: TextStyle(
                            color: isDark ? Colors.white38 : Colors.grey[400]),
                        filled: true,
                        fillColor: cardBg,
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

                // ── Priority filter chips (always-visible dots) ────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _filterChip('All', null, isDark: isDark),
                          const SizedBox(width: 8),
                          _filterChip('High', TaskPriority.high,
                              color: _kHighColor, isDark: isDark),
                          const SizedBox(width: 8),
                          _filterChip('Medium', TaskPriority.medium,
                              color: _kMediumColor, isDark: isDark),
                          const SizedBox(width: 8),
                          _filterChip('Low', TaskPriority.low,
                              color: _kLowColor, isDark: isDark),
                        ],
                      ),
                    ),
                  ),
                ),

                if (tasks.isEmpty)
                  SliverFillRemaining(
                      child: _EmptyStateWidget(isDark: isDark)),

                if (dueToday.isNotEmpty) ...[
                  _buildSectionHeader('Due Today', Icons.today_rounded,
                      const Color(0xFFEF5350), isDark),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _TaskCard(
                        task: dueToday[index],
                        onToggle: _taskService.toggleTaskCompletion,
                        onDelete: _taskService.deleteTask,
                        cardBg: cardBg,
                        isDark: isDark,
                      ),
                      childCount: dueToday.length,
                    ),
                  ),
                ],

                if (upcoming.isNotEmpty) ...[
                  _buildSectionHeader('Upcoming', Icons.calendar_today_rounded,
                      const Color(0xFF5C6BC0), isDark),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _TaskCard(
                        task: upcoming[index],
                        onToggle: _taskService.toggleTaskCompletion,
                        onDelete: _taskService.deleteTask,
                        cardBg: cardBg,
                        isDark: isDark,
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
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _showCompleted
                                    ? Icons.expand_less_rounded
                                    : Icons.expand_more_rounded,
                                color: Colors.green[600],
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Completed (${completed.length})',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.green[300]
                                    : Colors.green[700],
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
                          cardBg: cardBg,
                          isDark: isDark,
                        ),
                        childCount: completed.length,
                      ),
                    ),
                ],

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Filter chip with an always-visible colored dot for priority chips
  Widget _filterChip(String label, TaskPriority? priority,
      {Color? color, required bool isDark}) {
    final isSelected = _filterPriority == priority;
    final chipColor = color ?? _kAccent;

    return GestureDetector(
      onTap: () => setState(() => _filterPriority = priority),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? chipColor.withOpacity(isDark ? 0.3 : 0.15)
              : (isDark ? const Color(0xFF1E2130) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? chipColor
                : (isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.2)),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: chipColor.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3))
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Always-visible colored dot for High/Medium/Low
            if (color != null) ...[
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: color.withOpacity(0.5),
                        blurRadius: 4,
                        spreadRadius: 1)
                  ],
                ),
              ),
              const SizedBox(width: 6),
            ] else ...[
              // "All" chip — tiny sparkle icon
              Icon(Icons.filter_list_rounded,
                  size: 13,
                  color: isSelected
                      ? _kAccent
                      : (isDark ? Colors.white54 : Colors.grey[500])),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? chipColor
                    : (isDark ? Colors.white70 : Colors.grey[700]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
      String title, IconData icon, Color accent, bool isDark) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: accent),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? accent.withOpacity(0.9) : accent,
                letterSpacing: 0.3,
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
  final Color cardBg;
  final bool isDark;

  const _TaskCard({
    required this.task,
    required this.onToggle,
    required this.onDelete,
    required this.cardBg,
    required this.isDark,
  });

  void _openEdit(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddTaskScreen(existingTask: task)),
    );
  }

  void _showDetail(BuildContext context) {
    final dateFormatter = DateFormat('MMM dd, yyyy – hh:mm a');
    final pColor = _priorityColor(task.priority);
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E2130) : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row with priority badge
            Row(
              children: [
                Expanded(
                  child: Text(task.title,
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: pColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: pColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    task.priority.name[0].toUpperCase() +
                        task.priority.name.substring(1),
                    style: TextStyle(
                        color: pColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ),
              ],
            ),
            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(task.description,
                  style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.grey[700])),
            ],
            const SizedBox(height: 12),
            _detailRow(Icons.event_rounded,
                'Due: ${dateFormatter.format(task.deadline.toDate())}'),
            if (task.recurrence != 'None')
              _detailRow(Icons.repeat_rounded, 'Repeats: ${task.recurrence}'),
            _detailRow(
                task.isCompleted
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                task.isCompleted ? 'Completed' : 'Pending'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _kAccent),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.grey[800]))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pColor = _priorityColor(task.priority);
    final dateFormatter = DateFormat('MMM dd, yyyy');
    final isOverdue = task.isOverdue();

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFFE53935), Color(0xFFEF9A9A)]),
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 24),
      ),
      onDismissed: (_) => onDelete(task.id),
      child: GestureDetector(
        onTap: () => _showDetail(context),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: pColor.withOpacity(isDark ? 0.1 : 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: isOverdue
                  ? Colors.red.withOpacity(0.4)
                  : (isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.grey.withOpacity(0.12)),
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // ── Colored left accent bar ──────────────────────────────
                Container(
                  width: 5,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: task.isCompleted
                        ? Colors.grey.withOpacity(0.3)
                        : pColor,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(4),
                      bottomRight: Radius.circular(4),
                    ),
                  ),
                ),
                // ── Main content ─────────────────────────────────────────
                Expanded(
                  child: ListTile(
                    contentPadding: const EdgeInsets.fromLTRB(10, 4, 12, 4),
                    leading: Transform.scale(
                      scale: 1.1,
                      child: Checkbox(
                        value: task.isCompleted,
                        activeColor: Colors.green[600],
                        checkColor: Colors.white,
                        side: BorderSide(
                            color: isDark ? Colors.white30 : Colors.grey[400]!,
                            width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5)),
                        onChanged: (_) =>
                            onToggle(task.id, task.isCompleted),
                      ),
                    ),
                    title: Text(
                      task.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        color: task.isCompleted
                            ? (isDark ? Colors.white30 : Colors.grey[400])
                            : (isDark ? Colors.white : Colors.black87),
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
                              style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.grey[500]),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Row(
                            children: [
                              Icon(
                                isOverdue
                                    ? Icons.warning_amber_rounded
                                    : Icons.event_rounded,
                                size: 13,
                                color: isOverdue
                                    ? Colors.red[600]
                                    : (isDark
                                        ? Colors.white38
                                        : Colors.grey[500]),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                dateFormatter
                                    .format(task.deadline.toDate()),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isOverdue
                                      ? Colors.red[600]
                                      : (isDark
                                          ? Colors.white54
                                          : Colors.grey[600]),
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
                                    color: Colors.red.withOpacity(0.12),
                                    borderRadius:
                                        BorderRadius.circular(4),
                                    border: Border.all(
                                        color: Colors.red.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    'OVERDUE',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.red[600],
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                              if (task.recurrence != 'None') ...[
                                const SizedBox(width: 6),
                                Icon(Icons.repeat_rounded,
                                    size: 12,
                                    color: isDark
                                        ? Colors.white38
                                        : Colors.grey[400]),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Priority dot with glow
                        Container(
                          width: 11,
                          height: 11,
                          decoration: BoxDecoration(
                            color: task.isCompleted
                                ? Colors.grey[400]
                                : pColor,
                            shape: BoxShape.circle,
                            boxShadow: task.isCompleted
                                ? []
                                : [
                                    BoxShadow(
                                        color: pColor.withOpacity(0.55),
                                        blurRadius: 5,
                                        spreadRadius: 1)
                                  ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _openEdit(context),
                          child: Icon(Icons.edit_rounded,
                              size: 17,
                              color: isDark
                                  ? Colors.white38
                                  : Colors.grey[400]),
                        ),
                      ],
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
}

class _EmptyStateWidget extends StatelessWidget {
  final bool isDark;
  const _EmptyStateWidget({required this.isDark});

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
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          const Color(0xFF5C6BC0).withOpacity(0.3),
                          const Color(0xFF7986CB).withOpacity(0.1)
                        ]
                      : [
                          const Color(0xFF5C6BC0).withOpacity(0.12),
                          const Color(0xFF7986CB).withOpacity(0.06)
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.task_alt_rounded,
                  size: 52, color: _kAccent),
            ),
            const SizedBox(height: 24),
            Text(
              'All clear!',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              'You have no tasks yet.\nTap + to add your first one.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white38 : Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}
