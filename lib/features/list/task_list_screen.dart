import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/task_repo.dart';
import '../../data/task.dart';
import '../edit/task_edit_sheet.dart';
import '../../widgets/confirm_dialog.dart';
import '../../services/auth_service.dart';
import '../../services/cloud_sync_service.dart';

enum TaskSortMode { none, byDueDate, byPriority, byStatus }

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});
  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen>
    with WidgetsBindingObserver {
  final repo = TaskRepo();
  final _authService = AuthService.instance;
  final _cloudSyncService = CloudSyncService.instance;
  List<Task> tasks = [];
  bool _syncing = false;
  String? _lastSyncedAt;

  String _searchQuery = '';
  TaskSortMode _sortMode = TaskSortMode.byDueDate;
  bool _hideCompleted = false;

  Future<void> _load() async {
    tasks = await repo.all();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load().then((_) => _maybeInitialSync());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _cloudSyncService.pushLocalToCloud().catchError((_) {});
    }
  }

  Future<void> _maybeInitialSync() async {
    if (!_authService.isSignedIn) return;
    await _syncCloud(initial: true);
  }

  Future<void> _syncCloud({bool initial = false}) async {
    if (!_authService.isSignedIn) {
      if (!initial && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign in to sync with the cloud')),
        );
      }
      return;
    }

    setState(() => _syncing = true);
    try {
      await _cloudSyncService.fullSync();
      await _load();
      _lastSyncedAt = TimeOfDay.now().format(context);
      if (!initial && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Cloud sync complete')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Cloud sync failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _add() async {
    final created = await showModalBottomSheet<Task>(
      context: context,
      isScrollControlled: true,
      builder: (_) => TaskEditSheet(),
    );
    if (created != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Task created')));
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Task updated')));
      _load();
    }
  }

  Future<void> _delete(Task t) async {
    final ok = await confirmDialog(context, 'Delete "${t.title}"?');
    if (!ok) return;

    // Keep a copy for UNDO
    final deletedTask = t;

    // Delete from DB
    await repo.delete(t.id!);
    await _load(); // refresh list

    if (!mounted) return;

    // Show snackbar with UNDO action
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Task deleted'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () async {
            // Re-create the task (new id, same content)
            await repo.create(deletedTask.copyWith(id: null));
            await _load();
          },
        ),
      ),
    );
  }

  Color _getPriorityColor(TaskPriority p) {
    switch (p) {
      case TaskPriority.high:
        return Colors.red.shade100;
      case TaskPriority.medium:
        return Colors.orange.shade100;
      case TaskPriority.low:
        return Colors.green.shade100;
    }
  }

  Color _getPriorityAccent(TaskPriority p) {
    switch (p) {
      case TaskPriority.high:
        return Colors.red.shade700;
      case TaskPriority.medium:
        return Colors.orange.shade700;
      case TaskPriority.low:
        return Colors.green.shade700;
    }
  }

  String _recurrenceLabel(TaskRecurrence r) {
    switch (r) {
      case TaskRecurrence.daily:
        return 'Daily';
      case TaskRecurrence.weekly:
        return 'Weekly';
      case TaskRecurrence.weekdays:
        return 'Weekdays';
      case TaskRecurrence.monthly:
        return 'Monthly';
      case TaskRecurrence.none:
      default:
        return '';
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

  // Helper to compute the next due date for recurring tasks
  DateTime _nextDueDate(DateTime from, TaskRecurrence recurrence) {
    switch (recurrence) {
      case TaskRecurrence.daily:
        return from.add(const Duration(days: 1));
      case TaskRecurrence.weekly:
        return from.add(const Duration(days: 7));
      case TaskRecurrence.weekdays:
        var next = from.add(const Duration(days: 1));
        while (next.weekday == DateTime.saturday ||
            next.weekday == DateTime.sunday) {
          next = next.add(const Duration(days: 1));
        }
        return next;
      case TaskRecurrence.monthly:
        return DateTime(
          from.year,
          from.month + 1,
          from.day,
          from.hour,
          from.minute,
        );
      case TaskRecurrence.none:
      default:
        return from;
    }
  }

  String _formatDueDate(DateTime dt) {
    final now = DateTime.now();
    final diff = dt.difference(now);

    // Format time as 12 hour with AM or PM
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final timeStr = '$hour:$minute $period';

    if (diff.inDays == 0) return 'Today at $timeStr';
    if (diff.inDays == 1) return 'Tomorrow at $timeStr';
    if (diff.inDays < 0) return 'Overdue - $timeStr';
    return '${dt.month}/${dt.day}/${dt.year} at $timeStr';
  }

  List<Task> _getVisibleTasks() {
    var list = List<Task>.from(tasks);

    // Search filter
    final q = _searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((t) {
        final title = t.title.toLowerCase();
        final desc = (t.description ?? '').toLowerCase();
        return title.contains(q) || desc.contains(q);
      }).toList();
    }

    // Hide completed filter
    if (_hideCompleted) {
      list = list.where((t) => t.status != TaskStatus.done).toList();
    }

    // Sorting
    switch (_sortMode) {
      case TaskSortMode.byDueDate:
        list.sort((a, b) {
          final aDue = a.due;
          final bDue = b.due;
          if (aDue == null && bDue == null) return 0;
          if (aDue == null) return 1; // nulls last
          if (bDue == null) return -1;
          return aDue.compareTo(bDue);
        });
        break;
      case TaskSortMode.byPriority:
        // high > medium > low
        list.sort((a, b) => b.priority.index.compareTo(a.priority.index));
        break;
      case TaskSortMode.byStatus:
        // todo < inProgress < done
        list.sort((a, b) => a.status.index.compareTo(b.status.index));
        break;
      case TaskSortMode.none:
        break;
    }

    return list;
  }

  Widget _buildTaskList(bool isDark) {
    final visibleTasks = _getVisibleTasks();

    if (tasks.isEmpty) {
      return Center(
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
      );
    }

    if (visibleTasks.isEmpty) {
      return Center(
        child: Text(
          'No tasks match your search',
          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: visibleTasks.length,
        itemBuilder: (_, i) {
          final t = visibleTasks[i];
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
                side: BorderSide(
                  color: _getPriorityAccent(t.priority),
                  width: 2,
                ),
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
                            final isCurrentlyDone = t.status == TaskStatus.done;

                            // Recurring task behaviour
                            if (!isCurrentlyDone &&
                                t.recurrence != TaskRecurrence.none &&
                                t.due != null) {
                              final nextDue = _nextDueDate(
                                t.due!,
                                t.recurrence,
                              );

                              final updated = t.copyWith(
                                status: TaskStatus.todo,
                                due: nextDue,
                              );

                              await repo.update(updated);
                              _load();

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Recurring task completed. Next occurrence: ${_formatDueDate(nextDue)}',
                                    ),
                                    backgroundColor: Colors.green.shade600,
                                    behavior: SnackBarBehavior.floating,
                                    duration: const Duration(seconds: 3),
                                    margin: const EdgeInsets.all(16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                              }
                              return;
                            }

                            // Normal toggle behaviour
                            final newStatus = isCurrentlyDone
                                ? TaskStatus.todo
                                : TaskStatus.done;
                            final updated = t.copyWith(status: newStatus);
                            await repo.update(updated);
                            _load();

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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                            }
                          },
                          child: Icon(
                            _getStatusIcon(t.status),
                            color: isDone
                                ? Colors.green
                                : _getPriorityAccent(t.priority),
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
                                  decoration: isDone
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: isDone ? Colors.grey : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  // Priority pill
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
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

                                  // Recurrence pill
                                  if (t.recurrence != TaskRecurrence.none)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blueGrey.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.blueGrey.shade200,
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.repeat, size: 12),
                                          const SizedBox(width: 4),
                                          Text(
                                            _recurrenceLabel(t.recurrence),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                  // Due date
                                  if (t.due != null)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          size: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatDueDate(t.due!),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
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
    );
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'My Tasks',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: isDark
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              if (_authService.email != null ||
                  _authService.guestId != null) ...[
                const SizedBox(height: 2),
                Text(
                  _authService.isGuest
                      ? 'Guest ${_authService.guestId}'
                      : (_authService.email ?? ''),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? Theme.of(context).colorScheme.onSurfaceVariant
                        : Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer.withOpacity(0.8),
                  ),
                ),
              ],
            ],
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
          onPressed: _syncing ? null : () => _syncCloud(),
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

          // Sort menu
          PopupMenuButton<TaskSortMode>(
            tooltip: 'Sort tasks',
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
                Icons.sort,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            onSelected: (mode) {
              setState(() => _sortMode = mode);
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(
                value: TaskSortMode.byDueDate,
                child: Text('Sort by due date'),
              ),
              PopupMenuItem(
                value: TaskSortMode.byPriority,
                child: Text('Sort by priority'),
              ),
              PopupMenuItem(
                value: TaskSortMode.byStatus,
                child: Text('Sort by status'),
              ),
              PopupMenuItem(
                value: TaskSortMode.none,
                child: Text('No sorting'),
              ),
            ],
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
      body: Column(
        children: [
          if (_syncing || _lastSyncedAt != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  if (_syncing)
                    const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    const Icon(Icons.cloud_done, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _syncing
                          ? 'Syncing with cloud...'
                          : 'Last synced at ${_lastSyncedAt ?? ''}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search tasks...',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),

          // Hide completed filter chip
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FilterChip(
                label: const Text('Hide completed'),
                avatar: const Icon(Icons.check_circle_outline, size: 18),
                selected: _hideCompleted,
                onSelected: (v) {
                  setState(() => _hideCompleted = v);
                },
              ),
            ),
          ),

          Expanded(child: _buildTaskList(isDark)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
      ),
    );
  }
}
