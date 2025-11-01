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
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      due: due ?? this.due,
      status: status ?? this.status,
      priority: priority ?? this.priority,
    );
  }

  // SQLite mapping
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'due': due?.millisecondsSinceEpoch,   // <— time-safe
      'status': status.index,
      'priority': priority.index,
    };
  }

  static Task fromMap(Map<String, dynamic> m) {
    DateTime? parseDue(dynamic v) {
      if (v == null) return null;
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      if (v is String && v.isNotEmpty) {
        return DateTime.parse(v).toLocal();
      }
      return null;
    }

    return Task(
      id: m['id'] as int?,
      title: m['title'] as String,
      description: m['description'] as String?,
      due: parseDue(m['due']),
      status: TaskStatus.values[(m['status'] as int?) ?? 0],
      priority: TaskPriority.values[(m['priority'] as int?) ?? 1],
    );
  }
}
