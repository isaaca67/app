import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/auth_service.dart';
import '../services/task_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _taskService = TaskService();
  final _authService = AuthService();
  var _selectedIndex = 0;
  var _filter = TaskFilter.all;
  bool _isSigningOut = false;

  User? get _user => FirebaseAuth.instance.currentUser;

  Future<void> _openTaskEditor({Task? task}) async {
    final draft = await showDialog<TaskDraft>(
      context: context,
      builder: (_) => TaskEditorDialog(task: task),
    );
    if (draft == null || _user == null) return;

    try {
      if (task == null) {
        await _taskService.createTask(
          userId: _user!.uid,
          title: draft.title,
          description: draft.description,
          priority: draft.priority,
        );
        _showMessage('Tarea creada correctamente.');
      } else {
        await _taskService.updateTask(
          userId: _user!.uid,
          task: task,
          title: draft.title,
          description: draft.description,
          priority: draft.priority,
        );
        _showMessage('Tarea actualizada.');
      }
    } catch (_) {
      _showMessage(
        'No se pudo guardar la tarea. Revisa tu conexión.',
        isError: true,
      );
    }
  }

  Future<void> _toggleTask(Task task) async {
    if (_user == null) return;
    try {
      await _taskService.toggleTask(_user!.uid, task);
    } catch (_) {
      _showMessage('No se pudo actualizar la tarea.', isError: true);
    }
  }

  Future<void> _confirmDelete(Task task) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar tarea'),
        content: Text(
          '¿Eliminar “${task.title}”? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              foregroundColor: const Color(0xFFC62828),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (shouldDelete != true || _user == null) return;
    try {
      await _taskService.deleteTask(_user!.uid, task.id);
      _showMessage('Tarea eliminada.');
    } catch (_) {
      _showMessage('No se pudo eliminar la tarea.', isError: true);
    }
  }

  Future<void> _signOut() async {
    setState(() => _isSigningOut = true);
    try {
      await _authService.signOut();
    } catch (_) {
      _showMessage('No se pudo cerrar la sesión.', isError: true);
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? const Color(0xFFC62828)
            : const Color(0xFF2E7D32),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final titles = ['Mis tareas', 'Mi perfil', 'Ajustes'];
    return Scaffold(
      appBar: AppBar(title: Text(titles[_selectedIndex])),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _TasksTab(
            userId: user.uid,
            filter: _filter,
            taskService: _taskService,
            onFilterChanged: (filter) => setState(() => _filter = filter),
            onToggle: _toggleTask,
            onEdit: (task) => _openTaskEditor(task: task),
            onDelete: _confirmDelete,
          ),
          _ProfileTab(user: user),
          _SettingsTab(isSigningOut: _isSigningOut, onSignOut: _signOut),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _openTaskEditor,
              icon: const Icon(Icons.add),
              label: const Text('Nueva tarea'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (value) =>
            setState(() => _selectedIndex = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: 'Tareas',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}

enum TaskFilter { all, pending, completed }

class _TasksTab extends StatelessWidget {
  const _TasksTab({
    required this.userId,
    required this.filter,
    required this.taskService,
    required this.onFilterChanged,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final String userId;
  final TaskFilter filter;
  final TaskService taskService;
  final ValueChanged<TaskFilter> onFilterChanged;
  final ValueChanged<Task> onToggle;
  final ValueChanged<Task> onEdit;
  final ValueChanged<Task> onDelete;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Task>>(
      stream: taskService.watchTasks(userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _LoadError(onRetry: () {});
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final tasks = snapshot.data!;
        final visibleTasks = switch (filter) {
          TaskFilter.all => tasks,
          TaskFilter.pending =>
            tasks.where((task) => !task.isCompleted).toList(),
          TaskFilter.completed =>
            tasks.where((task) => task.isCompleted).toList(),
        };
        final completed = tasks.where((task) => task.isCompleted).length;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      label: 'Total',
                      value: '${tasks.length}',
                      color: const Color(0xFF1565C0),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricCard(
                      label: 'Pendientes',
                      value: '${tasks.length - completed}',
                      color: const Color(0xFFEF6C00),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricCard(
                      label: 'Completadas',
                      value: '$completed',
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Todas',
                    selected: filter == TaskFilter.all,
                    onSelected: () => onFilterChanged(TaskFilter.all),
                  ),
                  _FilterChip(
                    label: 'Pendientes',
                    selected: filter == TaskFilter.pending,
                    onSelected: () => onFilterChanged(TaskFilter.pending),
                  ),
                  _FilterChip(
                    label: 'Completadas',
                    selected: filter == TaskFilter.completed,
                    onSelected: () => onFilterChanged(TaskFilter.completed),
                  ),
                ],
              ),
            ),
            Expanded(
              child: visibleTasks.isEmpty
                  ? _EmptyTasks(isFiltered: tasks.isNotEmpty)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: visibleTasks.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, index) => _TaskTile(
                        task: visibleTasks[index],
                        onToggle: onToggle,
                        onEdit: onEdit,
                        onDelete: onDelete,
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    ),
  );
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });
  final String label;
  final bool selected;
  final VoidCallback onSelected;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    ),
  );
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.task,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });
  final Task task;
  final ValueChanged<Task> onToggle;
  final ValueChanged<Task> onEdit;
  final ValueChanged<Task> onDelete;

  @override
  Widget build(BuildContext context) {
    final priorityColor = switch (task.priority) {
      'Alta' => const Color(0xFFC62828),
      'Baja' => const Color(0xFF2E7D32),
      _ => const Color(0xFFEF6C00),
    };
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: () => onEdit(task),
        contentPadding: const EdgeInsets.fromLTRB(8, 10, 6, 10),
        leading: Checkbox(
          value: task.isCompleted,
          onChanged: (_) => onToggle(task),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            color: task.isCompleted ? Colors.grey : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  task.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Chip(
                label: Text(
                  'Prioridad ${task.priority}',
                  style: TextStyle(fontSize: 11, color: priorityColor),
                ),
                visualDensity: VisualDensity.compact,
                side: BorderSide(color: priorityColor.withValues(alpha: .35)),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          tooltip: 'Opciones de tarea',
          onSelected: (value) =>
              value == 'edit' ? onEdit(task) : onDelete(task),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Editar')),
            PopupMenuItem(value: 'delete', child: Text('Eliminar')),
          ],
        ),
      ),
    );
  }
}

class _EmptyTasks extends StatelessWidget {
  const _EmptyTasks({required this.isFiltered});
  final bool isFiltered;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.task_alt, size: 72, color: Color(0xFF1565C0)),
          const SizedBox(height: 16),
          Text(
            isFiltered
                ? 'No hay tareas en este filtro.'
                : 'Aún no tienes tareas.',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            isFiltered
                ? 'Prueba con otro filtro.'
                : 'Usa “Nueva tarea” para crear tu primer pendiente.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 56),
          const SizedBox(height: 16),
          const Text('No pudimos cargar tus tareas.'),
          TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    ),
  );
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({required this.user});
  final User user;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      Center(
        child: CircleAvatar(
          radius: 48,
          backgroundImage: user.photoURL == null
              ? null
              : NetworkImage(user.photoURL!),
          child: user.photoURL == null
              ? const Icon(Icons.person, size: 48)
              : null,
        ),
      ),
      const SizedBox(height: 16),
      Text(
        user.displayName?.isNotEmpty == true
            ? user.displayName!
            : 'Usuario COV',
        style: Theme.of(context).textTheme.headlineSmall,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 4),
      Text(user.email ?? 'Sin correo registrado', textAlign: TextAlign.center),
      const SizedBox(height: 32),
      const ListTile(
        leading: Icon(Icons.verified_user_outlined),
        title: Text('Cuenta protegida'),
        subtitle: Text('Tus tareas solo son visibles para tu cuenta.'),
      ),
      const ListTile(
        leading: Icon(Icons.sync_outlined),
        title: Text('Sincronización en tiempo real'),
        subtitle: Text('Los cambios se guardan automáticamente.'),
      ),
    ],
  );
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab({required this.isSigningOut, required this.onSignOut});
  final bool isSigningOut;
  final VoidCallback onSignOut;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      const ListTile(
        leading: Icon(Icons.info_outline),
        title: Text('COV App'),
        subtitle: Text('Gestor personal de tareas'),
      ),
      const Divider(),
      ListTile(
        leading: const Icon(Icons.logout, color: Color(0xFFC62828)),
        title: const Text('Cerrar sesión'),
        enabled: !isSigningOut,
        onTap: onSignOut,
        trailing: isSigningOut
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : null,
      ),
    ],
  );
}

class TaskDraft {
  const TaskDraft({
    required this.title,
    required this.description,
    required this.priority,
  });
  final String title;
  final String description;
  final String priority;
}

class TaskEditorDialog extends StatefulWidget {
  const TaskEditorDialog({super.key, this.task});
  final Task? task;
  @override
  State<TaskEditorDialog> createState() => _TaskEditorDialogState();
}

class _TaskEditorDialogState extends State<TaskEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late String _priority;
  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.task?.description ?? '',
    );
    _priority = widget.task?.priority ?? 'Media';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.task == null ? 'Nueva tarea' : 'Editar tarea'),
    content: Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titleController,
              autofocus: true,
              maxLength: 80,
              decoration: const InputDecoration(labelText: 'Título'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Escribe un título.'
                  : null,
            ),
            TextFormField(
              controller: _descriptionController,
              maxLength: 250,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
              ),
            ),
            DropdownButtonFormField<String>(
              initialValue: _priority,
              decoration: const InputDecoration(labelText: 'Prioridad'),
              items: const ['Alta', 'Media', 'Baja']
                  .map(
                    (priority) => DropdownMenuItem(
                      value: priority,
                      child: Text(priority),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _priority = value!),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            Navigator.pop(
              context,
              TaskDraft(
                title: _titleController.text,
                description: _descriptionController.text,
                priority: _priority,
              ),
            );
          }
        },
        child: const Text('Guardar'),
      ),
    ],
  );
}
