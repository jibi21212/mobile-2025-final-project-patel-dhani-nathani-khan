import 'package:flutter/material.dart';
import '../../data/task.dart';
import '../../data/task_repo.dart';

class TaskEditSheet extends StatefulWidget {
  final Task? existing;
  TaskEditSheet({super.key, this.existing});
  @override
  State<TaskEditSheet> createState() => _TaskEditSheetState();
}

class _TaskEditSheetState extends State<TaskEditSheet> {
  final _form = GlobalKey<FormState>();
  final _repo = TaskRepo();

  late String _title;
  String? _desc;
  DateTime? _due;
  TaskStatus _status = TaskStatus.todo;
  TaskPriority _priority = TaskPriority.medium;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = e?.title ?? '';
    _desc  = e?.description;
    _due   = e?.due;
    _status= e?.status ?? TaskStatus.todo;
    _priority = e?.priority ?? TaskPriority.medium;
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    _form.currentState!.save();
    final t = Task(
      id: widget.existing?.id,
      title: _title.trim(),
      description: _desc?.trim(),
      due: _due,
      status: _status,
      priority: _priority,
    );
    if (widget.existing == null) {
      final id = await _repo.create(t);
      Navigator.pop(context, t.copyWith(id: id));
    } else {
      await _repo.update(t);
      Navigator.pop(context, t);
    }
  }

  // Helper Function to combine DateTime and TimeOfDay into a single DateTime object
  DateTime _combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  // Helper Function to help quickly display
  String _formatDue(DateTime d) {
    // Simple yyyy-mm-dd hh:mm (24h). Swap this later for intl if locale formats are desired
    final s = d.toLocal().toString();
    return s.substring(0, 16);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _due ?? now;
    final res = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (res != null) {
      setState(() {
        if (_due != null) {
          // keep previously chosen time if any
          final t = TimeOfDay(hour: _due!.hour, minute: _due!.minute);
          _due = _combineDateAndTime(res, t);
        } else {
          // no time picked yet → default to 09:00
          _due = _combineDateAndTime(res, const TimeOfDay(hour: 9, minute: 0));
        }
      });
    }
  }

  Future<void> _pickTime() async {
    final now = TimeOfDay.now();
    final initial = _due != null
        ? TimeOfDay(hour: _due!.hour, minute: _due!.minute)
        : now;
    final res = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (res != null) {
      setState(() {
        // If no date yet, default date to today when time is chosen first
        final baseDate = _due ?? DateTime.now();
        _due = _combineDateAndTime(baseDate, res);
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.existing == null ? 'New Task' : 'Edit Task', style: Theme.of(context).textTheme.titleLarge),
                TextFormField(
                  initialValue: _title,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  onSaved: (v) => _title = v ?? '',
                ),
                TextFormField(
                  initialValue: _desc,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  onSaved: (v) => _desc = v,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<TaskPriority>(
                        value: _priority,
                        items: TaskPriority.values.map((p) =>
                            DropdownMenuItem(value: p, child: Text('Priority: ${p.name}'))).toList(),
                        onChanged: (v) => setState(() => _priority = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<TaskStatus>(
                        value: _status,
                        items: TaskStatus.values.map((s) =>
                            DropdownMenuItem(value: s, child: Text('Status: ${s.name}'))).toList(),
                        onChanged: (v) => setState(() => _status = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _due == null ? 'No due date/time' : 'Due: ${_formatDue(_due!)}',
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.event),
                      label: const Text('Pick date'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: _pickTime,
                      icon: const Icon(Icons.access_time),
                      label: const Text('Pick time'),
                    ),
                    const SizedBox(width: 8),
                    if (_due != null)
                      IconButton(
                        tooltip: 'Clear',
                        onPressed: () => setState(() => _due = null),
                        icon: const Icon(Icons.clear),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    const Spacer(),
                    FilledButton(onPressed: _save, child: const Text('Save')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
