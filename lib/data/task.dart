enum TaskStatus { todo, inProgress, done }
enum TaskPriority { low, medium, high }

class Task {
  final int? id;
  final String title;
  final String? description;
  final DateTime? due;
  final TaskStatus status;
  final TaskPriority priority;
  // Will add the "assigned user" field later once we have collaborative work features implemented, until then, this feature is not needed
  Task({
    this.id,
    required this.title,
    this.description,
    this.due,
    this.status = TaskStatus.todo,
    this.priority = TaskPriority.medium,
  });

  Task copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? due,
    TaskStatus? status,
    TaskPriority? priority,
  }) => Task(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description ?? this.description,
    due: due ?? this.due,
    status: status ?? this.status,
    priority: priority ?? this.priority,
  );

  // SQLite mapping
  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'due': due?.millisecondsSinceEpoch,
    'status': status.index,
    'priority': priority.index,
  };

  static Task fromMap(Map<String, dynamic> m) => Task(
    id: m['id'] as int?,
    title: m['title'] as String,
    description: m['description'] as String?,
    due: (m['due'] as int?) != null ? DateTime.fromMillisecondsSinceEpoch(m['due'] as int) : null,
    status: TaskStatus.values[m['status'] as int],
    priority: TaskPriority.values[m['priority'] as int],
  );
}
