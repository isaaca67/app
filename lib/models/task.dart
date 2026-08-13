import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.isCompleted,
    this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final String priority;
  final bool isCompleted;
  final DateTime? createdAt;

  factory Task.fromDocument(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data() ?? <String, dynamic>{};
    return Task(
      id: document.id,
      title: data['title'] as String? ?? data['titulo'] as String? ?? '',
      description: data['description'] as String? ?? '',
      priority: data['priority'] as String? ?? 'Media',
      isCompleted:
          data['isCompleted'] as bool? ?? data['completada'] as bool? ?? false,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ??
          (data['fecha'] as Timestamp?)?.toDate(),
    );
  }
}
