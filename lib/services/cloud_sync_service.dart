import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/task.dart';
import '../data/task_repo.dart';
import 'auth_service.dart';

class CloudSyncService {
  CloudSyncService._(this._authService, this._repo);

  static final CloudSyncService instance = CloudSyncService._(
    AuthService.instance,
    TaskRepo(),
  );

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService;
  final TaskRepo _repo;

  Future<void> pushLocalToCloud() async {
    final uid = _authService.uid;
    if (uid == null) throw Exception('User not signed in');

    final tasks = await _repo.all();
    final batch = _firestore.batch();
    final collection = _firestore.collection('users').doc(uid).collection('tasks');

    for (final task in tasks) {
      if (task.id == null) continue;
      final doc = collection.doc(task.id.toString());
      batch.set(doc, _toRemote(task), SetOptions(merge: true));
    }

    await batch.commit();
  }

  Future<void> pullCloudToLocal() async {
    final uid = _authService.uid;
    if (uid == null) throw Exception('User not signed in');

    final snapshot = await _firestore.collection('users').doc(uid).collection('tasks').get();
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final parsedTask = _fromRemote(doc.id, data);
      await _repo.create(parsedTask);
    }
  }

  Future<void> fullSync() async {
    await pullCloudToLocal();
    await pushLocalToCloud();
  }

  Map<String, dynamic> _toRemote(Task task) {
    return {
      'title': task.title,
      'description': task.description,
      'due': task.due?.millisecondsSinceEpoch,
      'status': task.status.index,
      'priority': task.priority.index,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Task _fromRemote(String id, Map<String, dynamic> data) {
    final due = data['due'];
    int? dueMillis;
    if (due is int) {
      dueMillis = due;
    } else if (due is Timestamp) {
      dueMillis = due.millisecondsSinceEpoch;
    }

    return Task(
      id: int.tryParse(id),
      title: data['title'] as String? ?? 'Untitled Task',
      description: data['description'] as String?,
      due: dueMillis != null ? DateTime.fromMillisecondsSinceEpoch(dueMillis) : null,
      status: TaskStatus.values[(data['status'] as int?) ?? 0],
      priority: TaskPriority.values[(data['priority'] as int?) ?? 1],
    );
  }
}
