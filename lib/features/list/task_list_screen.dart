import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/task_repo.dart';
import '../../data/task.dart';
import '../edit/task_edit_sheet.dart';
import '../../widgets/confirm_dialog.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});
  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final repo = TaskRepo();
  List<Task> tasks = [];

  Future<void> _load() async {
    tasks = await repo.all();
    setState(() {});
  }

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _add() async {
    final created = await showModalBottomSheet<Task>(
      context: context,
      isScrollControlled: true,
      builder: (_) => TaskEditSheet(),
    );
    if (created != null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task created')));
      _load();
    }
  }

  Future<void> _edit(Task t) async {
    final updated = await showModalBottomSheet<Task>(
      context: context,
      isScrollControlled: true,
      builder: (_) => TaskEditSheet(existing: t),
    );
    if (updated != null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task updated')));
      _load();
    }
  }

  Future<void> _delete(Task t) async {
    final ok = await confirmDialog(context, 'Delete "${t.title}"?');
    if (ok) {
      await repo.delete(t.id!);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task deleted')));
      _load();
    }
  }

  Color _getPriorityColor(TaskPriority p) {
    switch (p) {
      case TaskPriority.high: return Colors.red.shade100;
      case TaskPriority.medium: return Colors.orange.shade100;
      case TaskPriority.low: return Colors.green.shade100;
    }
  }

  Color _getPriorityAccent(TaskPriority p) {
    switch (p) {
      case TaskPriority.high: return Colors.red.shade700;
      case TaskPriority.medium: return Colors.orange.shade700;
      case TaskPriority.low: return Colors.green.shade700;
    }
  }

  IconData _getStatusIcon(TaskStatus s) {
    switch (s) {
      case TaskStatus.todo: return Icons.radio_button_unchecked;
      case TaskStatus.inProgress: return Icons.hourglass_empty;
      case TaskStatus.done: return Icons.check_circle;
    }
  }

  String _formatDueDate(DateTime dt) {
    final now = DateTime.now();
    final diff = dt.difference(now);
    
    // Format time as 12-hour with AM/PM
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final timeStr = '$hour:$minute $period';
    
    if (diff.inDays == 0) return 'Today at $timeStr';
    if (diff.inDays == 1) return 'Tomorrow at $timeStr';
    if (diff.inDays < 0) return 'Overdue - $timeStr';
    return '${dt.month}/${dt.day}/${dt.year} at $timeStr';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
            color: isDark 
                ? Theme.of(context).colorScheme.surfaceContainerHighest
                : Colors.white.withOpacity(0.9),
          ),
          child: Text(
            'My Tasks',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 22,
              color: isDark 
                  ? Theme.of(context).colorScheme.onSurface
                  : Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? Theme.of(context).colorScheme.surfaceContainerHighest
                  : Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.sync,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          tooltip: 'Sync',
          onPressed: () async {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Synced'), duration: Duration(seconds: 1)),
            );
          },
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark
                    ? Theme.of(context).colorScheme.surfaceContainerHighest
                    : Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.dashboard,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            tooltip: 'Dashboard',
            onPressed: () => context.go('/dashboard'),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark
                    ? Theme.of(context).colorScheme.surfaceContainerHighest
                    : Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.settings,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            onPressed: () => context.go('/settings'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: tasks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.task_alt, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No tasks yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to create your first task',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: tasks.length,
                itemBuilder: (_, i) {
                  final t = tasks[i];
                  final isDone = t.status == TaskStatus.done;
                  return Dismissible(
                    key: ValueKey(t.id ?? '${t.title}-$i'),
                    background: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade400,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (_) async {
                      await _delete(t);
                      return false;
                    },
                    child: Card(
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: _getPriorityAccent(t.priority), width: 2),
                      ),
                      child: InkWell(
                        onTap: () => context.go('/task/${t.id}'),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              colors: [_getPriorityColor(t.priority), Colors.white],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () async {
                                    print('Status icon tapped! Current status: ${t.status}');
                                    final newStatus = t.status == TaskStatus.done 
                                        ? TaskStatus.todo 
                                        : TaskStatus.done;
                                    print('Changing to: $newStatus');
                                    final updated = t.copyWith(status: newStatus);
                                    await repo.update(updated);
                                    _load();
                                    print('Showing snackbar...');
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Row(
                                            children: [
                                              Icon(
                                                newStatus == TaskStatus.done 
                                                    ? Icons.celebration 
                                                    : Icons.radio_button_unchecked,
                                                color: Colors.white,
                                                size: 24,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      newStatus == TaskStatus.done 
                                                          ? '🎉 Task Completed!' 
                                                          : 'Task Incomplete',
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    if (newStatus == TaskStatus.done)
                                                      const Text(
                                                        'Great job! Keep it up!',
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          color: Colors.white70,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          backgroundColor: newStatus == TaskStatus.done 
                                              ? Colors.green.shade600
                                              : Colors.orange.shade700,
                                          behavior: SnackBarBehavior.floating,
                                          duration: const Duration(seconds: 3),
                                          margin: const EdgeInsets.all(16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      );
                                      print('Snackbar shown!');
                                    }
                                  },
                                  child: Icon(
                                    _getStatusIcon(t.status),
                                    color: isDone ? Colors.green : _getPriorityAccent(t.priority),
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t.title,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          decoration: isDone ? TextDecoration.lineThrough : null,
                                          color: isDone ? Colors.grey : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: _getPriorityAccent(t.priority),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              t.priority.name.toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          if (t.due != null) ...[
                                            Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                                            const SizedBox(width: 4),
                                            Text(
                                              _formatDueDate(t.due!),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  color: _getPriorityAccent(t.priority),
                                  onPressed: () => _edit(t),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
      ),
    );
  }
}
