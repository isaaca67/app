import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/task.dart';

class TaskService {
  TaskService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _tasks(String userId) =>
      _firestore.collection('users').doc(userId).collection('tareas');

  Stream<List<Task>> watchTasks(String userId) =>
      _tasks(userId).snapshots().map((snapshot) {
        final tasks = snapshot.docs.map(Task.fromDocument).toList();
        tasks.sort(
          (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
            a.createdAt ?? DateTime(0),
          ),
        );
        return tasks;
      });

  Future<void> createTask({
    required String userId,
    required String title,
    required String description,
    required String priority,
  }) => _tasks(userId).add({
    'title': title.trim(),
    'description': description.trim(),
    'priority': priority,
    'isCompleted': false,
    'completada': false,
    'createdAt': FieldValue.serverTimestamp(),
    'fecha': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });

  Future<void> updateTask({
    required String userId,
    required Task task,
    required String title,
    required String description,
    required String priority,
  }) => _tasks(userId).doc(task.id).update({
    'title': title.trim(),
    'titulo': title.trim(),
    'description': description.trim(),
    'priority': priority,
    'updatedAt': FieldValue.serverTimestamp(),
  });

  Future<void> toggleTask(String userId, Task task) =>
      _tasks(userId).doc(task.id).update({
        'isCompleted': !task.isCompleted,
        'completada': !task.isCompleted,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> deleteTask(String userId, String taskId) =>
      _tasks(userId).doc(taskId).delete();
}
