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
  void initState() { super.initState(); _load(); }

  @override
  Widget build(BuildContext context) {
    if (t == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: Text(t!.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            if (t!.description?.isNotEmpty == true) Text(t!.description!),
            const SizedBox(height: 8),
            Text('Status: ${t!.status.name}'),
            Text('Priority: ${t!.priority.name}'),
            if (t!.due != null) Text('Due: ${t!.due}'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                final updated = t!.copyWith(status: TaskStatus.done);
                await repo.update(updated);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marked done')));
                _load();
              },
              child: const Text('Mark Complete'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final res = await showModalBottomSheet<Task>(
            context: context,
            isScrollControlled: true,
            builder: (_) => TaskEditSheet(existing: t),
          );
          if (res != null) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task updated')));
            _load();
          }
        },
        label: const Text('Edit'),
        icon: const Icon(Icons.edit),
      ),
    );
  }
}
