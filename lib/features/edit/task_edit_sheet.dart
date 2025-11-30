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
    // Format as: Dec 1, 2025 at 3:45 PM
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = months[d.month - 1];
    final day = d.day;
    final year = d.year;
    
    final hour = d.hour == 0 ? 12 : (d.hour > 12 ? d.hour - 12 : d.hour);
    final minute = d.minute.toString().padLeft(2, '0');
    final period = d.hour >= 12 ? 'PM' : 'AM';
    
    return '$month $day, $year at $hour:$minute $period';
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
        // Ensure we keep the date portion and only update the time
        _due = DateTime(
          baseDate.year,
          baseDate.month,
          baseDate.day,
          res.hour,
          res.minute,
        );
        print('Updated time to: $_due'); // Debug print
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Theme.of(context).colorScheme.surface : Colors.white;
    final fieldColor = isDark ? Theme.of(context).colorScheme.surfaceContainerHighest : Colors.grey.shade50;
    
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    widget.existing == null ? 'New Task' : 'Edit Task',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    initialValue: _title,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      hintText: 'Enter task title',
                      filled: true,
                      fillColor: fieldColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Theme.of(context).dividerColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Theme.of(context).dividerColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    onSaved: (v) => _title = v ?? '',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _desc,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      hintText: 'Enter task description (optional)',
                      filled: true,
                      fillColor: fieldColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Theme.of(context).dividerColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Theme.of(context).dividerColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 3,
                    onSaved: (v) => _desc = v,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: fieldColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Theme.of(context).dividerColor),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: DropdownButtonFormField<TaskPriority>(
                            value: _priority,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              labelText: 'Priority',
                            ),
                            items: TaskPriority.values.map((p) => DropdownMenuItem(
                              value: p,
                              child: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      color: _getPriorityColor(p),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Text(p.name[0].toUpperCase() + p.name.substring(1)),
                                ],
                              ),
                            )).toList(),
                            onChanged: (v) => setState(() => _priority = v!),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: fieldColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Theme.of(context).dividerColor),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: DropdownButtonFormField<TaskStatus>(
                            value: _status,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              labelText: 'Status',
                            ),
                            items: TaskStatus.values.map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s.name[0].toUpperCase() + s.name.substring(1)),
                            )).toList(),
                            onChanged: (v) => setState(() => _status = v!),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 20, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Due Date',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _due == null ? 'No due date set' : _formatDue(_due!),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _pickDate,
                                icon: const Icon(Icons.event, size: 18),
                                label: const Text('Pick Date'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _pickTime,
                                icon: const Icon(Icons.access_time, size: 18),
                                label: const Text('Pick Time'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            if (_due != null) ...[
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: () => setState(() => _due = null),
                                icon: const Icon(Icons.clear, size: 18),
                                label: const Text('Clear'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red.shade400,
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: _save,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Save Task'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(TaskPriority p) {
    switch (p) {
      case TaskPriority.high: return Colors.red;
      case TaskPriority.medium: return Colors.orange;
      case TaskPriority.low: return Colors.green;
    }
  }
}
