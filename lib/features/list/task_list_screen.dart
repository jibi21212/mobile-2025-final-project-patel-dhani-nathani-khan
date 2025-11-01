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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sync (stub)',
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Synced')));
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (_, i) {
            final t = tasks[i];
            return Dismissible(
              key: ValueKey(t.id ?? '${t.title}-$i'),
              background: Container(color: Colors.redAccent),
              confirmDismiss: (_) async { await _delete(t); return false; },
              child: ListTile(
                title: Text(t.title),
                subtitle: Text([
                  if (t.due != null) 'Due: ${t.due!.toLocal().toString().split(".").first}',
                  'Priority: ${t.priority.name}',
                  'Status: ${t.status.name}',
                ].join(' · ')),
                onTap: () => context.go('/task/${t.id}'),
                onLongPress: () => _delete(t),
                trailing: IconButton(icon: const Icon(Icons.edit), onPressed: () => _edit(t)),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(onPressed: _add, child: const Icon(Icons.add)),
    );
  }
}
