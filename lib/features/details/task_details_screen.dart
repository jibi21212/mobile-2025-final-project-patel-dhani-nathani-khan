import 'package:flutter/material.dart';
import '../../data/task_repo.dart';
import '../../data/task.dart';
import '../edit/task_edit_sheet.dart';

class TaskDetailsScreen extends StatefulWidget {
  final int taskId;
  const TaskDetailsScreen({super.key, required this.taskId});
  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  final repo = TaskRepo();
  Task? t;

  Future<void> _load() async {
    final all = await repo.all();
    t = all.firstWhere((e) => e.id == widget.taskId);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Color _getPriorityColor(TaskPriority p) {
    switch (p) {
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.low:
        return Colors.green;
    }
  }

  IconData _getStatusIcon(TaskStatus s) {
    switch (s) {
      case TaskStatus.todo:
        return Icons.radio_button_unchecked;
      case TaskStatus.inProgress:
        return Icons.hourglass_empty;
      case TaskStatus.done:
        return Icons.check_circle;
    }
  }

  String _formatDueDate(DateTime dt) {
    final now = DateTime.now();
    final diff = dt.difference(now);

    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final timeStr = '$hour:$minute $period';

    if (diff.inDays == 0) return 'Today at $timeStr';
    if (diff.inDays == 1) return 'Tomorrow at $timeStr';
    if (diff.inDays < 0) return 'Overdue - $timeStr';

    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} at $timeStr';
  }

  @override
  Widget build(BuildContext context) {
    if (t == null)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDone = t!.status == TaskStatus.done;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t!.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final res = await showModalBottomSheet<Task>(
                context: context,
                isScrollControlled: true,
                builder: (_) => TaskEditSheet(existing: t),
              );
              if (res != null && mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Task updated')));
                _load();
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getPriorityColor(t!.priority).withOpacity(0.2),
                border: Border.all(
                  color: _getPriorityColor(t!.priority),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.flag,
                    size: 16,
                    color: _getPriorityColor(t!.priority),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${t!.priority.name[0].toUpperCase()}${t!.priority.name.substring(1)} Priority',
                    style: TextStyle(
                      color: _getPriorityColor(t!.priority),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (t!.description?.isNotEmpty == true) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.description,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        t!.description!,
                        style: const TextStyle(fontSize: 15, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getStatusIcon(t!.status),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Status',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          t!.status.name[0].toUpperCase() +
                              t!.status.name.substring(1),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (t!.due != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.event,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Due Date',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDueDate(t!.due!),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ] else
              const SizedBox(height: 24),

            if (!isDone)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    final updated = t!.copyWith(status: TaskStatus.done);
                    await repo.update(updated);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Task marked as complete!'),
                        ),
                      );
                      _load();
                    }
                  },
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Mark Complete'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  border: Border.all(color: Colors.green, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      'Task Completed',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
